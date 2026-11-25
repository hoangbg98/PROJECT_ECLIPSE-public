// Module máy chủ Nakama của PROJECT ECLIPSE (M9-1). Chạy trong JS runtime của Nakama (goja), không cần build.
// Đặt trong thư mục runtime.path của Nakama; Nakama gọi InitModule khi khởi động.
//
// Chức năng giai đoạn 1:
//  - Tài khoản: đăng ký tên + email + mật khẩu (endpoint authenticate/email), đăng nhập bằng tên hoặc email.
//  - Mỗi tài khoản có một "mã người chơi" 8 chữ số (duy nhất), người chơi ghi vào nội dung chuyển khoản.
//  - eclipse_profile (người chơi gọi): mã, tên, ví (wallet).
//  - gacha_pull (người chơi gọi): gacha chạy trên máy chủ, ghi thẳng vào save (M9-2c).
//  - save_get / save_put (người chơi gọi): cloud save, mỗi tài khoản một thế giới (M9-3); save_put kiểm chống gian lận (M9-2b).
//  - Chat (M9-6): phòng thế giới + nhắn riêng, lọc từ, cấm chat, báo cáo, tra cứu theo mã (xem mục Chat bên dưới).
//  - Nạp tiền (M9-2): bảng giá, thưởng nạp lần đầu, thẻ tháng (xem mục Nạp tiền bên dưới).
//  - admin_find / admin_grant (chỉ gọi bằng http_key từ tool của QTV): tra cứu theo mã, phát tiền vào ví.
//    Mỗi lần phát cần mã giao dịch ngân hàng (ref) duy nhất: cùng ref lần hai bị từ chối (chống phát trùng).
//
// Không đặt số cân bằng / giá gói ở đây: QTV nhập số lượng khi phát.

var CODE_COLLECTION = "player_code";      // key = mã 8 số, owner = hệ thống, value {user_id}
var GRANT_COLLECTION = "admin_grant";     // key = ref, owner = hệ thống, value = bản ghi phát quà
var SYSTEM_USER = "00000000-0000-0000-0000-000000000000";
var ALLOWED_CURRENCIES = ["gems", "gold", "moonlight"];
var MAX_GRANT = 10000000;                  // chặn gõ nhầm thừa số 0
var CODE_LENGTH = 8;

function newCode() {
  var s = "" + (1 + Math.floor(Math.random() * 9));   // không bắt đầu bằng 0
  while (s.length < CODE_LENGTH) {
    s += Math.floor(Math.random() * 10);
  }
  return s;
}

function cleanCode(raw) {
  return String(raw || "").replace(/[^0-9]/g, "");
}

// Mã của tài khoản; chưa có thì cấp mới (ghi với version "*" để hai tài khoản không lấy trùng mã).
function ensureCode(nk, logger, userId) {
  var account = nk.accountGetId(userId);
  var meta = account.user.metadata || {};
  if (meta.code) {
    return meta.code;
  }
  for (var i = 0; i < 20; i++) {
    var code = newCode();
    try {
      nk.storageWrite([{
        collection: CODE_COLLECTION, key: code, userId: SYSTEM_USER,
        value: { user_id: userId }, version: "*", permissionRead: 0, permissionWrite: 0
      }]);
    } catch (e) {
      continue;   // mã đã có người dùng
    }
    meta.code = code;
    nk.accountUpdateId(userId, null, null, null, null, null, null, meta);
    logger.info("Cấp mã người chơi %s cho %s", code, userId);
    return code;
  }
  throw new Error("không cấp được mã người chơi");
}

function userIdByCode(nk, code) {
  var rows = nk.storageRead([{ collection: CODE_COLLECTION, key: code, userId: SYSTEM_USER }]);
  if (!rows || rows.length === 0) {
    return null;
  }
  return rows[0].value.user_id;
}

function walletOf(account) {
  var w = account.wallet;
  if (typeof w === "string") {
    w = w ? JSON.parse(w) : {};
  }
  return w || {};
}

function profileOf(nk, userId, code) {
  var account = nk.accountGetId(userId);
  return {
    user_id: userId,
    code: code,
    username: account.user.username,
    display_name: account.user.displayName || "",
    wallet: walletOf(account),
    server_time: Math.floor(Date.now() / 1000)
  };
}

function requireAdmin(ctx) {
  // Gọi bằng http_key (server-to-server) thì không có userId; người chơi đăng nhập thì có.
  if (ctx.userId) {
    throw new Error("chỉ QTV được gọi");
  }
}

function afterAuthenticateDevice(ctx, logger, nk, session, request) {
  ensureCode(nk, logger, ctx.userId);
}

// Tên đăng nhập: 3–20 ký tự chữ không dấu, số, gạch dưới (giống kiểm tra phía game, NakamaApi.username_error).
var USERNAME_RE = /^[A-Za-z0-9_]{3,20}$/;

// Đăng ký tài khoản (create = true) phải có tên hợp lệ; đăng nhập (create = false) không kiểm.
function beforeAuthenticateEmail(ctx, logger, nk, data) {
  if (data.create && !USERNAME_RE.test(String(data.username || ""))) {
    throw new Error("tên đăng nhập 3–20 ký tự: chữ không dấu, số, gạch dưới");
  }
  return data;
}

function afterAuthenticateEmail(ctx, logger, nk, session, request) {
  ensureCode(nk, logger, ctx.userId);
}

function rpcProfile(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("cần đăng nhập");
  }
  return JSON.stringify(profileOf(nk, ctx.userId, ensureCode(nk, logger, ctx.userId)));
}

function rpcAdminFind(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var code = cleanCode(req.code);
  var userId = userIdByCode(nk, code);
  if (!userId) {
    throw new Error("không có người chơi mã " + code);
  }
  return JSON.stringify(profileOf(nk, userId, code));
}

// Kiểm tra yêu cầu phát quà; trả về chuỗi lỗi hoặc "" nếu hợp lệ.
function validateGrant(req) {
  if (cleanCode(req.code).length !== CODE_LENGTH) {
    return "mã người chơi phải có " + CODE_LENGTH + " chữ số";
  }
  var ref = String(req.ref || "").trim();
  if (ref.length < 4 || ref.length > 64 || !/^[A-Za-z0-9._-]+$/.test(ref)) {
    return "ref (mã giao dịch ngân hàng) 4–64 ký tự: chữ, số, . _ -";
  }
  if (!req.operator || String(req.operator).trim() === "") {
    return "thiếu tên QTV (operator)";
  }
  var changes = req.changes || {};
  var keys = Object.keys(changes);
  if (keys.length === 0) {
    return "không có gì để phát";
  }
  for (var i = 0; i < keys.length; i++) {
    var k = keys[i];
    var v = changes[k];
    if (ALLOWED_CURRENCIES.indexOf(k) < 0) {
      return "loại tiền không hợp lệ: " + k;
    }
    if (typeof v !== "number" || Math.floor(v) !== v || v === 0 || Math.abs(v) > MAX_GRANT) {
      return "số lượng " + k + " phải là số nguyên khác 0, tối đa " + MAX_GRANT;
    }
  }
  return "";
}

function rpcAdminGrant(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var err = validateGrant(req);
  if (err) {
    throw new Error(err);
  }
  var code = cleanCode(req.code);
  var userId = userIdByCode(nk, code);
  if (!userId) {
    throw new Error("không có người chơi mã " + code);
  }
  var ref = String(req.ref).trim();
  var record = {
    code: code, user_id: userId, changes: req.changes, ref: ref,
    note: String(req.note || ""), operator: String(req.operator).trim(),
    pack: String(req.pack || "").substring(0, 40), paid: Number(req.paid) || 0,
    time: Math.floor(Date.now() / 1000)
  };
  // Giữ chỗ ref trước khi cộng ví: ref đã dùng thì storageWrite với version "*" báo lỗi.
  try {
    nk.storageWrite([{
      collection: GRANT_COLLECTION, key: ref, userId: SYSTEM_USER,
      value: record, version: "*", permissionRead: 0, permissionWrite: 0
    }]);
  } catch (e) {
    throw new Error("ref " + ref + " đã được dùng (đã phát quà cho giao dịch này)");
  }
  try {
    nk.walletUpdate(userId, req.changes, { reason: "admin_grant", ref: ref, operator: record.operator, note: record.note }, true);
  } catch (e) {
    nk.storageDelete([{ collection: GRANT_COLLECTION, key: ref, userId: SYSTEM_USER }]);
    throw new Error("không cập nhật được ví: " + e.message);
  }
  logger.info("QTV %s phát %s cho %s (ref %s)", record.operator, JSON.stringify(req.changes), code, ref);
  return JSON.stringify(profileOf(nk, userId, code));
}

// ---------- Chống gian lận: kiểm save (M9-2b) ----------
// Mỗi lần game gửi save (save_put), máy chủ đối chiếu save mới với save đã nhận trước đó.
//  - Lỗi CỨNG (từ chối, giữ save cũ, đánh dấu): checksum sai, tiền âm / vượt trần, Ngọc đã nạp khai khống (online.applied.gems
//    lớn hơn ví máy chủ), cấp nhân vật / cấp người chơi / cấp kỹ năng vượt trần, lịch sử gacha bị sửa / xóa (chỉ được thêm vào cuối).
//  - Lỗi MỀM (nhận save, đánh dấu cho QTV): Ngọc / Vàng kiếm được nhiều hơn mức nghi ngờ theo giờ, nhân vật mới không rõ nguồn,
//    lượt gacha ở banner lạ.
// Luật (server_rules/main) do QTV đẩy lên: data/config/anti_cheat.json + server/rules/game_rules.json (audit.ps1 -SyncRules).
// Chưa có luật thì chỉ kiểm các lỗi không cần số (checksum, tiền âm, Ngọc nạp, lịch sử gacha).

var RULES_COLLECTION = "server_rules";
var FLAG_COLLECTION = "cheat_flag";      // key = user_id, chủ = hệ thống: {code, username, count, hard, last, entries[]}
var FLAG_KEEP = 30;

function readRules(nk) {
  var row = readOne(nk, RULES_COLLECTION, "main");
  return row ? row.value : {};
}

function isNonNegInt(v) {
  return typeof v === "number" && v >= 0 && Math.floor(v) === v;
}

// Chuỗi chuẩn (khóa sắp xếp) để so sánh dữ liệu do game (Godot sắp khóa) và máy chủ (giữ thứ tự) ghi.
function canon(v) {
  if (Array.isArray(v)) {
    return "[" + v.map(canon).join(",") + "]";
  }
  if (v && typeof v === "object") {
    return "{" + Object.keys(v).sort().map(function (k) { return JSON.stringify(k) + ":" + canon(v[k]); }).join(",") + "}";
  }
  return JSON.stringify(v);
}

function historyKey(e) {
  return canon(e);
}

// Lịch sử mới phải = (lịch sử cũ bỏ bớt phần đầu do giới hạn 200) + các lượt mới ở cuối. Trả về số lượt mới, -1 nếu bị sửa.
function newHistoryCount(oldH, newH, limit) {
  oldH = oldH || [];
  newH = newH || [];
  for (var t = 0; t <= oldH.length; t++) {
    // Phần đầu chỉ bị cắt khi lịch sử mới đã đầy giới hạn (SaveSchema.HISTORY_LIMIT).
    if (t > 0 && newH.length < limit) {
      break;
    }
    var keep = oldH.length - t;
    if (keep > newH.length) {
      continue;
    }
    var same = true;
    for (var i = 0; i < keep; i++) {
      if (historyKey(oldH[t + i]) !== historyKey(newH[i])) {
        same = false;
        break;
      }
    }
    if (same) {
      return newH.length - keep;
    }
  }
  return -1;
}

// Ngọc chi cho các lượt gacha mới (theo giá banner; banner miễn phí = 0). Trả {cost, unknown: [banner lạ]}.
function gachaCost(rules, entries) {
  var byBanner = {};
  for (var i = 0; i < entries.length; i++) {
    var b = String(entries[i].banner || "");
    byBanner[b] = (byBanner[b] || 0) + 1;
  }
  var cost = 0;
  var unknown = [];
  var banners = rules.banners || {};
  for (var id in byBanner) {
    var def = banners[id];
    if (!def) {
      unknown.push(id);
      continue;
    }
    if (def.free || def.currency !== "gems") {
      continue;
    }
    var n = byBanner[id];
    var m = def.multi_count || 10;
    // Tính theo cách RẺ nhất (gói x10 trước) để không đánh dấu oan.
    cost += Math.floor(n / m) * def.cost_multi + (n % m) * def.cost_single;
  }
  return { cost: cost, unknown: unknown };
}

// Kiểm một save. Trả {hard: [lý do], soft: [lý do]}. prev = dữ liệu save trước (null nếu lần đầu), wallet = ví máy chủ.
function auditSave(nk, rules, env, data, prev, prevTime, wallet) {
  var hard = [];
  var soft = [];
  if (nk.sha256Hash(env.data) !== env.checksum) {
    hard.push("checksum");
    return { hard: hard, soft: soft };
  }
  var cur = data.currencies || {};
  var caps = rules.max_currency || {};
  for (var c in cur) {
    if (!isNonNegInt(cur[c])) {
      hard.push("currency_invalid:" + c);
    } else if (caps[c] && cur[c] > caps[c]) {
      hard.push("currency_over_cap:" + c);
    }
  }
  var applied = data.online && data.online.applied ? Number(data.online.applied.gems || 0) : 0;
  if (applied > (wallet.gems || 0)) {
    hard.push("purchased_gems_forged");
  }
  if (rules.max_level) {
    var chars = data.characters || {};
    for (var id in chars) {
      var ch = chars[id] || {};
      if (!(ch.level >= 1 && ch.level <= rules.max_level)) {
        hard.push("char_level:" + id);
      }
      var sk = ch.skills || {};
      for (var k in sk) {
        if (rules.skill_max_level && !(sk[k] >= 1 && sk[k] <= rules.skill_max_level)) {
          hard.push("skill_level:" + id + "." + k);
        }
      }
    }
    var acc = data.account || {};
    if (rules.captain_max_level && !(acc.level >= 1 && acc.level <= rules.captain_max_level)) {
      hard.push("captain_level");
    }
  }
  if (!prev) {
    return { hard: hard, soft: soft };
  }
  var oldH = (prev.gacha || {}).history || [];
  var newH = (data.gacha || {}).history || [];
  var added = newHistoryCount(oldH, newH, rules.history_limit || 200);
  if (added < 0) {
    hard.push("gacha_history_edited");
    return { hard: hard, soft: soft };
  }
  var entries = newH.slice(newH.length - added);
  // Gacha chạy trên máy chủ (M9-2c): save do game gửi không được tự thêm lượt quay hay sửa pity / bảo hiểm / lượt miễn phí.
  if (rules.server_gacha) {
    var pg = prev.gacha || {};
    var ng = data.gacha || {};
    if (added > 0) {
      hard.push("gacha_client_pull:" + added);
    }
    if (canon(pg.pity || {}) !== canon(ng.pity || {}) || canon(pg.guarantee || {}) !== canon(ng.guarantee || {})
        || canon(pg.starter_used || []) !== canon(ng.starter_used || [])) {
      hard.push("gacha_state_edited");
    }
    if (hard.length > 0) {
      return { hard: hard, soft: soft };
    }
  }
  var gc = gachaCost(rules, entries);
  if (gc.unknown.length > 0) {
    soft.push("gacha_unknown_banner:" + gc.unknown.join(","));
  }
  // Mức kiếm được: (đổi + đã chi cho gacha − phần Ngọc nạp mới cộng) so với mức nghi ngờ theo giờ.
  var sr = rules.soft || {};
  var hours = Math.min(Math.max((Date.now() - prevTime) / 3600000, 0), sr.max_hours_counted || 48);
  var prevCur = prev.currencies || {};
  var prevApplied = prev.online && prev.online.applied ? Number(prev.online.applied.gems || 0) : 0;
  var earnedGems = (Number(cur.gems || 0) - Number(prevCur.gems || 0)) + gc.cost - (applied - prevApplied);
  if (sr.gems_per_hour && earnedGems > sr.gems_per_hour * hours + (sr.gems_burst || 0)) {
    soft.push("gems_earned:" + earnedGems + "/" + Math.round(hours * 10) / 10 + "h");
  }
  var earnedGold = Number(cur.gold || 0) - Number(prevCur.gold || 0);
  if (sr.gold_per_hour && earnedGold > sr.gold_per_hour * hours + (sr.gold_burst || 0)) {
    soft.push("gold_earned:" + earnedGold + "/" + Math.round(hours * 10) / 10 + "h");
  }
  // Nhân vật mới phải đến từ lượt gacha mới hoặc phần thưởng có trong dữ liệu.
  var fromGacha = {};
  for (var j = 0; j < entries.length; j++) {
    var item = String(entries[j].item || "");
    if (item.indexOf("char:") === 0) {
      fromGacha[item.substring(5)] = true;
    }
  }
  var rewardChars = rules.reward_characters || [];
  var prevChars = prev.characters || {};
  for (var cid in (data.characters || {})) {
    if (!prevChars[cid] && !fromGacha[cid] && rewardChars.indexOf(cid) < 0) {
      soft.push("character_unknown_source:" + cid);
    }
  }
  return { hard: hard, soft: soft };
}

function flagAccount(nk, logger, userId, username, kind, reasons) {
  var row = readOne(nk, FLAG_COLLECTION, userId);
  var v = row ? row.value : { count: 0, hard: 0, entries: [] };
  v.count += 1;
  if (kind === "hard") {
    v.hard += 1;
  }
  v.username = username;
  v.last = Date.now();
  v.entries.unshift({ t: Date.now(), kind: kind, reasons: reasons });
  v.entries = v.entries.slice(0, FLAG_KEEP);
  var acc = nk.accountGetId(userId);
  v.code = (acc.user.metadata || {}).code || "";
  writeSystem(nk, FLAG_COLLECTION, userId, v);
  logger.warn("Gian lận? %s (%s) %s: %s", username, v.code, kind, reasons.join(", "));
}

// QTV: danh sách tài khoản bị đánh dấu (nhiều lỗi cứng trước).
function rpcAdminCheatFlags(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var out = [];
  var cursor = "";
  for (var page = 0; page < 20; page++) {
    var res = nk.storageList(SYSTEM_USER, FLAG_COLLECTION, 100, cursor);
    var objs = res.objects || [];
    for (var i = 0; i < objs.length; i++) {
      var v = objs[i].value;
      if (req.code && v.code !== cleanCode(req.code)) {
        continue;
      }
      out.push({ user_id: objs[i].key, code: v.code, username: v.username, count: v.count, hard: v.hard, last: v.last,
        entries: req.code ? v.entries : v.entries.slice(0, 3) });
    }
    cursor = res.cursor;
    if (!cursor) {
      break;
    }
  }
  out.sort(function (a, b) { return (b.hard - a.hard) || (b.last - a.last); });
  return JSON.stringify({ flags: out.slice(0, Number(req.limit) || 50) });
}

function rpcAdminCheatClear(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var userId = userIdByCode(nk, cleanCode(req.code));
  if (!userId) {
    throw new Error("không có người chơi mã " + req.code);
  }
  nk.storageDelete([{ collection: FLAG_COLLECTION, key: userId, userId: SYSTEM_USER }]);
  logger.info("QTV %s xóa đánh dấu gian lận của %s", req.operator, req.code);
  return JSON.stringify({ cleared: true });
}

// QTV: khôi phục save từ bản trước (save_backup/prev) — dùng khi save bị phá / bị sửa mà máy chủ đã lỡ nhận.
function rpcAdminSaveRestore(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var userId = userIdByCode(nk, cleanCode(req.code));
  if (!userId) {
    throw new Error("không có người chơi mã " + req.code);
  }
  if (!req.operator) {
    throw new Error("thiếu tên QTV (operator)");
  }
  var rows = nk.storageRead([{ collection: SAVE_BACKUP_COLLECTION, key: "prev", userId: userId }]);
  if (!rows || rows.length === 0) {
    throw new Error("không có bản save trước để khôi phục");
  }
  var acks = nk.storageWrite([{ collection: SAVE_COLLECTION, key: SAVE_KEY, userId: userId, value: rows[0].value,
    permissionRead: 1, permissionWrite: 0 }]);
  logger.info("QTV %s khôi phục save trước của %s", req.operator, req.code);
  return JSON.stringify({ restored: true, version: acks[0].version });
}

function rpcAdminSetRules(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  if (!req.rules || typeof req.rules !== "object") {
    throw new Error("thiếu rules");
  }
  req.rules.updated = Date.now();
  writeSystem(nk, RULES_COLLECTION, "main", req.rules);
  return JSON.stringify({ updated: req.rules.updated, banners: Object.keys(req.rules.banners || {}).length });
}

// ---------- Gacha chạy trên máy chủ (M9-2c) ----------
// Máy chủ tự quay và ghi thẳng vào save trên máy chủ (trừ tiền, pity, bảo hiểm, trao thưởng, lịch sử), rồi trả save mới cho game.
// Logic là bản chép 1-1 của scripts/gacha/gacha_service.gd (đổi một bên phải đổi bên kia; tests/unit/gacha + server/tests/gacha_smoke.mjs).
// Cấu hình banner: server_rules.gacha_banners (tools/export_server_rules.gd → audit.ps1 -SyncRules).
// Khác bản trong game: trang bị mới chưa có phụ tố (game gieo khi nạp save: Inventory.ensure_affixes); nhân vật mới từ lượt miễn
// phí tự vào đội do game làm sau khi nhận save (auto_join_party).

var DEFAULT_CHARACTER = { level: 1, exp: 0, equipment: {}, skills: {}, fragments: 0, promotion: 0 };

function gRandInt(from, to) {
  return from + Math.floor(Math.random() * (to - from + 1));
}

function gTier(b, key) {
  for (var i = 0; i < b.tiers.length; i++) {
    if (b.tiers[i].key === key) {
      return b.tiers[i];
    }
  }
  return null;
}

function gCostOf(b, count) {
  if (count === 1) {
    return b.cost_single;
  }
  if (count === b.multi_count) {
    return b.cost_multi;
  }
  return -1;
}

function gOwnsDef(data, defId) {
  var eq = ((data.inventory || {}).equipment) || {};
  for (var uid in eq) {
    if (String(eq[uid].def_id) === defId) {
      return true;
    }
  }
  return false;
}

function gEligiblePool(data, t) {
  if (!t.exclude_owned_until_complete) {
    return t.pool;
  }
  var out = [];
  for (var i = 0; i < t.pool.length; i++) {
    var p = t.pool[i];
    if (!(p.indexOf("equip:") === 0 && gOwnsDef(data, p.substring(6)))) {
      out.push(p);
    }
  }
  return out.length > 0 ? out : t.pool;
}

function gBaseRateOf(data, t) {
  return t.rate_per_item ? t.base_rate * gEligiblePool(data, t).length : t.base_rate;
}

function gTierRate(t, pullsSince, base) {
  if (t.hard_pity > 0 && pullsSince >= t.hard_pity) {
    return 1.0;
  }
  var r = base < 0 ? t.base_rate : base;
  if (t.soft_pity_start > 0 && pullsSince >= t.soft_pity_start) {
    if (t.soft_pity_mode === "flat") {
      r += t.soft_pity_step;
    } else {
      r += t.soft_pity_step * (pullsSince - t.soft_pity_start + 1);
    }
  }
  return Math.min(Math.max(r, 0), 1);
}

function gTable(data, name, group) {
  var all = data.gacha[name];
  if (!all || typeof all !== "object" || Array.isArray(all)) {
    all = {};
    data.gacha[name] = all;
  }
  if (!all[group] || typeof all[group] !== "object") {
    all[group] = {};
  }
  return all[group];
}

function gRollTier(data, b, pity) {
  var last = b.tiers.length - 1;
  for (var i = 0; i < last; i++) {
    var t = b.tiers[i];
    if (t.hard_pity > 0 && Number(pity[t.key]) >= t.hard_pity) {
      return t;
    }
  }
  var roll = Math.random();
  var acc = 0;
  for (var j = 0; j < last; j++) {
    var tj = b.tiers[j];
    acc += gTierRate(tj, Number(pity[tj.key]), gBaseRateOf(data, tj));
    if (roll < acc) {
      return tj;
    }
  }
  return b.tiers[last];
}

function gPickReward(data, t, group) {
  if (t.exclude_owned_until_complete) {
    var pool = gEligiblePool(data, t);
    var item = pool[gRandInt(0, pool.length - 1)];
    return { item: item, featured: t.featured.indexOf(item) >= 0 };
  }
  if (t.featured.length === 0) {
    return { item: t.pool[gRandInt(0, t.pool.length - 1)], featured: false };
  }
  var g = gTable(data, "guarantee", group);
  var others = [];
  for (var i = 0; i < t.pool.length; i++) {
    if (t.featured.indexOf(t.pool[i]) < 0) {
      others.push(t.pool[i]);
    }
  }
  var want = g[t.key] === true || others.length === 0 || Math.random() < t.featured_rate;
  if (want) {
    g[t.key] = false;
    return { item: t.featured[gRandInt(0, t.featured.length - 1)], featured: true };
  }
  if (t.guarantee_after_miss) {
    g[t.key] = true;
  }
  return { item: others[gRandInt(0, others.length - 1)], featured: false };
}

function gAddMaterial(data, id, n) {
  var m = data.inventory.materials;
  m[id] = Number(m[id] || 0) + n;
}

// Trao thưởng; trả về true nếu là nhân vật trùng.
function gGrant(data, item, t) {
  var kind = item.split(":")[0];
  var id = item.substring(kind.length + 1);
  if (kind === "char") {
    if (!data.characters[id]) {
      data.characters[id] = JSON.parse(JSON.stringify(DEFAULT_CHARACTER));
      return false;
    }
    if (t.duplicate_fragments > 0) {
      data.characters[id].fragments = Number(data.characters[id].fragments || 0) + t.duplicate_fragments;
    }
    if (t.duplicate_item && t.duplicate_count > 0) {
      gAddMaterial(data, t.duplicate_item, t.duplicate_count);
    }
    return true;
  }
  if (kind === "gold") {
    data.currencies.gold = Number(data.currencies.gold || 0) + Number(id);
  } else if (kind === "equip") {
    var uid = String(Math.floor(Number(data.inventory.next_uid || 1)));
    data.inventory.next_uid = Number(uid) + 1;
    data.inventory.equipment[uid] = { def_id: id, level: 0 };
  } else if (kind === "item") {
    gAddMaterial(data, id, 1);
  }
  return false;
}

function gPullOne(data, b, force, limit) {
  var group = b.group;
  var pity = gTable(data, "pity", group);
  for (var i = 0; i < b.tiers.length; i++) {
    pity[b.tiers[i].key] = Number(pity[b.tiers[i].key] || 0) + 1;
  }
  var tier = force ? gTier(b, force) : null;
  if (!tier) {
    tier = gRollTier(data, b, pity);
  }
  var pityAt = Number(pity[tier.key]);
  pity[tier.key] = 0;
  var picked = gPickReward(data, tier, group);
  var dup = gGrant(data, picked.item, tier);
  var entry = { banner: b.id, item: picked.item, rarity: tier.rarity, tier: tier.key, featured: picked.featured,
    duplicate: dup, pity: pityAt, forced: !!force, time: new Date().toISOString().substring(0, 19) };
  var hist = data.gacha.history;
  hist.push(entry);
  while (hist.length > limit) {
    hist.shift();
  }
  return entry;
}

function gEnsure(data) {
  data.gacha = data.gacha || {};
  data.gacha.history = data.gacha.history || [];
  data.gacha.starter_used = data.gacha.starter_used || [];
  data.inventory = data.inventory || {};
  data.inventory.materials = data.inventory.materials || {};
  data.inventory.equipment = data.inventory.equipment || {};
  data.currencies = data.currencies || {};
  data.characters = data.characters || {};
}

// Quay (như GachaService.pull / pull_starter). Trả {reason: "" | mã lỗi, results: []}; mã lỗi giống GachaService.REASON_*.
function gachaPull(data, b, count, starter, limit) {
  gEnsure(data);
  if (!b || !b.valid || !b.tiers || b.tiers.length === 0) {
    return { reason: "invalid_banner", results: [] };
  }
  var results = [];
  if (starter) {
    if (!b.starter_free_multi || b.tiers.length < 2) {
      return { reason: "invalid_banner", results: [] };
    }
    if (data.gacha.starter_used.indexOf(b.id) >= 0) {
      return { reason: "starter_used", results: [] };
    }
    if (b.ticket_item && !(Number(data.inventory.materials[b.ticket_item] || 0) > 0)) {
      return { reason: "no_ticket", results: [] };
    }
    if (b.ticket_item) {
      var left = Number(data.inventory.materials[b.ticket_item]) - 1;
      if (left > 0) {
        data.inventory.materials[b.ticket_item] = left;
      } else {
        delete data.inventory.materials[b.ticket_item];
      }
    }
    data.gacha.starter_used.push(b.id);
    var first = b.tiers[0].key;
    var rest = b.tiers[b.tiers.length - 1].key;
    var at = gRandInt(0, b.multi_count - 1);
    for (var i = 0; i < b.multi_count; i++) {
      results.push(gPullOne(data, b, i === at ? first : rest, limit));
    }
    return { reason: "", results: results };
  }
  var cost = gCostOf(b, count);
  if (cost < 0) {
    return { reason: "bad_count", results: [] };
  }
  var have = Number(data.currencies[b.cost_currency] || 0);
  if (data.currencies[b.cost_currency] === undefined || have < cost) {
    return { reason: "not_enough_currency", results: [] };
  }
  data.currencies[b.cost_currency] = have - cost;
  var satisfied = false;
  var guarantee = count === b.multi_count && count > 1 && b.multi_guarantee_tiers.length > 0;
  for (var j = 0; j < count; j++) {
    var force = "";
    if (guarantee && j === count - 1 && !satisfied) {
      force = b.multi_guarantee_pick[0];
    }
    var r = gPullOne(data, b, force, limit);
    if (b.multi_guarantee_tiers.indexOf(r.tier) >= 0) {
      satisfied = true;
    }
    results.push(r);
  }
  return { reason: "", results: results };
}

// Người chơi: quay gacha. {banner, count, starter, base_version} → {results, version, envelope}.
// Lỗi: "save_conflict" (save trên máy chủ mới hơn base_version: game gửi save rồi thử lại), "gacha_reason:<mã>", "gacha_no_save".
function rpcGachaPull(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("cần đăng nhập");
  }
  var req = JSON.parse(payload || "{}");
  var rules = readRules(nk);
  var b = (rules.gacha_banners || {})[String(req.banner || "")];
  if (!b) {
    throw new Error("gacha_reason:invalid_banner");
  }
  var row = readSave(nk, ctx.userId);
  if (!row) {
    throw new Error("gacha_no_save");
  }
  if (row.version !== String(req.base_version || "")) {
    throw new Error("save_conflict");
  }
  if (nk.sha256Hash(row.value.data) !== row.value.checksum) {
    throw new Error("gacha_no_save");
  }
  var data = JSON.parse(row.value.data);
  var res = gachaPull(data, b, Number(req.count), !!req.starter, rules.history_limit || 200);
  if (res.reason) {
    throw new Error("gacha_reason:" + res.reason);
  }
  var body = JSON.stringify(data);
  var env = { schema_version: row.value.schema_version, checksum: nk.sha256Hash(body),
    saved_at: new Date().toISOString().substring(0, 19), data: body };
  var acks;
  try {
    acks = nk.storageWrite([{ collection: SAVE_COLLECTION, key: SAVE_KEY, userId: ctx.userId, value: env,
      version: row.version, permissionRead: 1, permissionWrite: 0 }]);
  } catch (e) {
    throw new Error("save_conflict");
  }
  nk.storageWrite([{ collection: SAVE_BACKUP_COLLECTION, key: "prev", userId: ctx.userId, value: row.value,
    permissionRead: 0, permissionWrite: 0 }]);
  var best = 0;
  for (var i = 0; i < res.results.length; i++) {
    best = Math.max(best, res.results[i].rarity);
  }
  logger.info("Gacha %s: %s x%d (cao nhất %d sao)", ctx.username, b.id, res.results.length, best);
  return JSON.stringify({ results: res.results, version: acks[0].version, envelope: env });
}

// ---------- Cloud save (M9-3) ----------
// Mỗi tài khoản một "thế giới": collection "save", key "main", chủ = người chơi; chỉ ghi qua RPC (permissionWrite 0).
// Giá trị = phong bì file save của game: {schema_version, checksum, saved_at, data: "<chuỗi JSON>"} (SaveStore.encode).
// Ghi có kiểm tra version (base_version): bản trên máy chủ đã đổi từ thiết bị khác thì báo "save_conflict".
// Bản trước mỗi lần ghi giữ ở "save_backup"/"prev" để QTV khôi phục khi cần.

var SAVE_COLLECTION = "save";
var SAVE_KEY = "main";
var SAVE_BACKUP_COLLECTION = "save_backup";
var SAVE_MAX_DATA = 200000;   // ký tự của chuỗi data (save thật ~20 KB)

function readSave(nk, userId) {
  var rows = nk.storageRead([{ collection: SAVE_COLLECTION, key: SAVE_KEY, userId: userId }]);
  return rows && rows.length > 0 ? rows[0] : null;
}

function validateEnvelope(env) {
  if (!env || typeof env !== "object") {
    return "thiếu dữ liệu save";
  }
  if (typeof env.schema_version !== "number" || env.schema_version < 1) {
    return "schema_version không hợp lệ";
  }
  if (typeof env.checksum !== "string" || env.checksum.length !== 64) {
    return "checksum không hợp lệ";
  }
  if (typeof env.data !== "string" || env.data.length < 2) {
    return "data không hợp lệ";
  }
  if (env.data.length > SAVE_MAX_DATA) {
    return "save quá lớn (" + env.data.length + " ký tự)";
  }
  return "";
}

function rpcSaveGet(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("cần đăng nhập");
  }
  var row = readSave(nk, ctx.userId);
  if (!row) {
    return JSON.stringify({ exists: false });
  }
  return JSON.stringify({ exists: true, version: row.version, envelope: row.value, update_time: row.updateTime });
}

function rpcSavePut(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("cần đăng nhập");
  }
  var req = JSON.parse(payload || "{}");
  var err = validateEnvelope(req.envelope);
  if (err) {
    throw new Error(err);
  }
  var base = String(req.base_version || "");
  var current = readSave(nk, ctx.userId);
  if ((current ? current.version : "") !== base) {
    throw new Error("save_conflict");
  }
  // Chống gian lận (M9-2b): kiểm save mới so với save đã nhận.
  var data;
  try {
    data = JSON.parse(req.envelope.data);
  } catch (e) {
    throw new Error("save_rejected:data");
  }
  var prev = null;
  var prevTime = Date.now();
  if (current) {
    try {
      prev = JSON.parse(current.value.data);
      prevTime = current.updateTime ? Number(current.updateTime) * 1000 : Date.now();
    } catch (e) {
      prev = null;
    }
  }
  var rules = readRules(nk);
  var account = nk.accountGetId(ctx.userId);
  var audit = auditSave(nk, rules, req.envelope, data, prev, prevTime, walletOf(account));
  if (audit.hard.length > 0) {
    flagAccount(nk, logger, ctx.userId, ctx.username, "hard", audit.hard);
    if (rules.hard_reject !== false) {
      throw new Error("save_rejected:" + audit.hard.join(","));
    }
  }
  if (audit.soft.length > 0) {
    flagAccount(nk, logger, ctx.userId, ctx.username, "soft", audit.soft);
  }
  var acks;
  try {
    acks = nk.storageWrite([{
      collection: SAVE_COLLECTION, key: SAVE_KEY, userId: ctx.userId, value: req.envelope,
      version: base === "" ? "*" : base, permissionRead: 1, permissionWrite: 0
    }]);
  } catch (e) {
    throw new Error("save_conflict");   // thiết bị khác vừa ghi chen vào
  }
  if (current) {
    nk.storageWrite([{
      collection: SAVE_BACKUP_COLLECTION, key: "prev", userId: ctx.userId, value: current.value,
      permissionRead: 0, permissionWrite: 0
    }]);
  }
  return JSON.stringify({ version: acks[0].version });
}

// ---------- Nạp tiền (M9-2) ----------
// Bảng giá (shop_catalog/main) do QTV đẩy lên từ data/shop/topup_packs.json (admin_set_packs): gói tiền tệ, thẻ tháng, thông tin
// nhận tiền. Người chơi chuyển khoản theo mã người chơi; QTV phát bằng admin_topup (kiểm số tiền đúng giá gói, thưởng nạp lần đầu
// tính ở máy chủ). Ví máy chủ (wallet) chỉ TĂNG khi nạp / nhận thẻ; game cộng phần chênh vào save (PurchasedCurrency).
//  - Thưởng nạp lần đầu: mỗi tài khoản, mỗi gói (first_bonus), mỗi "kỳ" (epoch); QTV tăng kỳ bằng admin_topup_reset để mở lại.
//  - Thẻ tháng: người chơi MUA bằng tiền nạp riêng (card_buy, giá ở catalog.card.cost); mỗi thẻ +30 lượt nhận; mỗi ngày (giờ Việt Nam) nhận 1 lượt; cứ `milestone_every` lượt nhận được thêm quà; tối đa max_days lượt.

var CATALOG_COLLECTION = "shop_catalog";
var TOPUP_CONFIG_COLLECTION = "topup_config";   // key "main": {epoch}
var TOPUP_STATE_COLLECTION = "topup_state";     // key = user_id: {bought:{pack:epoch}, log:[...], card:{...}}
var TOPUP_LOG_KEEP = 20;
var WALLET_CURRENCIES = ["gems", "moonlight"];

function readCatalog(nk) {
  var row = readOne(nk, CATALOG_COLLECTION, "main");
  return row ? row.value : null;
}

function findPack(catalog, id) {
  var packs = (catalog && catalog.packs) || [];
  for (var i = 0; i < packs.length; i++) {
    if (packs[i].id === id) {
      return packs[i];
    }
  }
  return null;
}

function topupEpoch(nk) {
  var row = readOne(nk, TOPUP_CONFIG_COLLECTION, "main");
  return row ? row.value.epoch : 1;
}

// Trạng thái nạp của một người chơi + version (để ghi có điều kiện).
function readTopupState(nk, userId) {
  var row = readOne(nk, TOPUP_STATE_COLLECTION, userId);
  var v = row ? row.value : {};
  return {
    version: row ? row.version : "*",
    value: { bought: v.bought || {}, log: v.log || [], card: v.card || { claims_left: 0, claims_total: 0, last_claim_day: "" } }
  };
}

function writeTopupState(nk, userId, st) {
  nk.storageWrite([{ collection: TOPUP_STATE_COLLECTION, key: userId, userId: SYSTEM_USER, value: st.value,
    version: st.version, permissionRead: 0, permissionWrite: 0 }]);
}

// Ngày theo giờ Việt Nam (mặc định UTC+7) dạng yyyy-mm-dd, dùng để giới hạn nhận thẻ 1 lần / ngày.
function dayKey(catalog) {
  var off = (catalog && catalog.card && catalog.card.reset_utc_offset_hours) || 7;
  return new Date(Date.now() + off * 3600000).toISOString().substring(0, 10);
}

function validateCatalog(c) {
  if (!c || !Array.isArray(c.packs) || c.packs.length === 0) {
    throw new Error("bảng giá thiếu packs");
  }
  var seen = {};
  for (var i = 0; i < c.packs.length; i++) {
    var k = c.packs[i];
    if (!/^[a-z0-9_]{2,32}$/.test(String(k.id || "")) || seen[k.id]) {
      throw new Error("id gói không hợp lệ hoặc trùng: " + k.id);
    }
    seen[k.id] = true;
    if (k.price !== null && !(typeof k.price === "number" && k.price > 0 && Math.floor(k.price) === k.price)) {
      throw new Error("giá gói " + k.id + " phải là số nguyên dương hoặc null (chưa bán)");
    }
    if (k.kind === "currency") {
      if (WALLET_CURRENCIES.indexOf(k.currency) < 0 || !(k.amount > 0) || Math.floor(k.amount) !== k.amount) {
        throw new Error("gói " + k.id + ": loại tiền hoặc số lượng không hợp lệ");
      }
    } else if (k.kind !== "card") {
      throw new Error("gói " + k.id + ": kind phải là currency hoặc card");
    }
  }
  var cd = c.card;
  if (cd && !(cd.days > 0 && cd.daily > 0 && cd.max_days >= cd.days && cd.milestone_every > 0 && cd.milestone_bonus >= 0)) {
    throw new Error("cấu hình thẻ tháng không hợp lệ");
  }
  if (cd && cd.cost !== undefined && !(WALLET_CURRENCIES.indexOf(cd.cost_currency) >= 0 && cd.cost > 0 && Math.floor(cd.cost) === cd.cost)) {
    throw new Error("giá thẻ tháng (cost / cost_currency) không hợp lệ");
  }
}

function rpcAdminSetPacks(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  validateCatalog(req.catalog);
  req.catalog.updated = Date.now();
  writeSystem(nk, CATALOG_COLLECTION, "main", req.catalog);
  return JSON.stringify({ packs: req.catalog.packs.length, updated: req.catalog.updated });
}

function rpcAdminTopupReset(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  if (!req.operator || String(req.operator).trim() === "") {
    throw new Error("thiếu tên QTV (operator)");
  }
  var epoch = topupEpoch(nk) + 1;
  writeSystem(nk, TOPUP_CONFIG_COLLECTION, "main", { epoch: epoch, reset_by: String(req.operator).trim(), reset_at: Date.now(), note: String(req.note || "") });
  logger.info("QTV %s mở lại thưởng nạp lần đầu: kỳ %d", req.operator, epoch);
  return JSON.stringify({ epoch: epoch });
}

// QTV: phát gói đã mua. Kiểm số tiền, ref không trùng, thưởng lần đầu, hạn thẻ tháng.
function rpcAdminTopup(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var catalog = readCatalog(nk);
  if (!catalog) {
    throw new Error("máy chủ chưa có bảng giá (đẩy bảng giá: grant.ps1 tự đồng bộ khi dùng -Pack)");
  }
  var code = cleanCode(req.code);
  var ref = String(req.ref || "").trim();
  if (code.length !== CODE_LENGTH) {
    throw new Error("mã người chơi phải có " + CODE_LENGTH + " chữ số");
  }
  if (ref.length < 4 || ref.length > 64 || !/^[A-Za-z0-9._-]+$/.test(ref)) {
    throw new Error("ref (mã giao dịch ngân hàng) 4–64 ký tự: chữ, số, . _ -");
  }
  if (!req.operator || String(req.operator).trim() === "") {
    throw new Error("thiếu tên QTV (operator)");
  }
  var pack = findPack(catalog, String(req.pack || ""));
  if (!pack) {
    throw new Error("không có gói " + req.pack + " trong bảng giá");
  }
  if (pack.price === null) {
    throw new Error("gói " + pack.id + " chưa có giá (chưa mở bán)");
  }
  if (Number(req.paid) !== pack.price && !req.force) {
    throw new Error("so_tien_khong_khop: nhận " + Number(req.paid) + ", gói " + pack.id + " giá " + pack.price);
  }
  var userId = userIdByCode(nk, code);
  if (!userId) {
    throw new Error("không có người chơi mã " + code);
  }
  var epoch = topupEpoch(nk);
  var st = readTopupState(nk, userId);
  var changes = {};
  var base = 0;
  var bonus = 0;
  var cardDays = 0;
  if (pack.kind === "currency") {
    base = pack.amount;
    var last = st.value.bought[pack.id];
    bonus = pack.first_bonus && !(last >= epoch) ? pack.amount : 0;
    changes[pack.currency] = base + bonus;
    st.value.bought[pack.id] = epoch;
  } else {
    cardDays = catalog.card.days;
    if (st.value.card.claims_left + cardDays > catalog.card.max_days) {
      throw new Error("thẻ tháng tối đa " + catalog.card.max_days + " ngày (đang còn " + st.value.card.claims_left + ")");
    }
    st.value.card.claims_left += cardDays;
  }
  var record = {
    code: code, user_id: userId, changes: changes, ref: ref, note: String(req.note || ""), operator: String(req.operator).trim(),
    pack: pack.id, paid: Number(req.paid) || 0, base: base, bonus: bonus, card_days: cardDays, forced: !!req.force,
    time: Math.floor(Date.now() / 1000)
  };
  try {
    nk.storageWrite([{ collection: GRANT_COLLECTION, key: ref, userId: SYSTEM_USER, value: record, version: "*", permissionRead: 0, permissionWrite: 0 }]);
  } catch (e) {
    throw new Error("ref " + ref + " đã được dùng (đã phát quà cho giao dịch này)");
  }
  st.value.log.unshift({ t: record.time, pack: pack.id, base: base, bonus: bonus, card_days: cardDays, paid: record.paid, ref: ref });
  st.value.log = st.value.log.slice(0, TOPUP_LOG_KEEP);
  try {
    writeTopupState(nk, userId, st);
    if (Object.keys(changes).length > 0) {
      nk.walletUpdate(userId, changes, { reason: "topup", pack: pack.id, ref: ref, operator: record.operator, bonus: bonus }, true);
    }
  } catch (e) {
    nk.storageDelete([{ collection: GRANT_COLLECTION, key: ref, userId: SYSTEM_USER }]);
    throw new Error("không phát được (thử lại): " + e.message);
  }
  logger.info("QTV %s phát gói %s cho %s (ref %s, nhận %d, thưởng %d)", record.operator, pack.id, code, ref, record.paid, bonus);
  var out = profileOf(nk, userId, code);
  out.granted = { pack: pack.id, base: base, bonus: bonus, card_days: cardDays };
  return JSON.stringify(out);
}

// QTV: xem trạng thái nạp của một người chơi (thưởng lần đầu đã dùng, thẻ tháng, lịch sử).
function rpcAdminTopupState(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var code = cleanCode(req.code);
  var userId = userIdByCode(nk, code);
  if (!userId) {
    throw new Error("không có người chơi mã " + code);
  }
  var st = readTopupState(nk, userId).value;
  return JSON.stringify({ code: code, epoch: topupEpoch(nk), bought: st.bought, card: st.card, log: st.log });
}

// QTV: sửa thẻ tháng khi có sự cố (vd bù ngày). Chỉ các trường được truyền mới đổi.
function rpcAdminCardSet(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var catalog = readCatalog(nk);
  var userId = userIdByCode(nk, cleanCode(req.code));
  if (!userId || !catalog) {
    throw new Error("không có người chơi hoặc bảng giá");
  }
  if (!req.operator || String(req.operator).trim() === "") {
    throw new Error("thiếu tên QTV (operator)");
  }
  var st = readTopupState(nk, userId);
  var card = st.value.card;
  if (req.claims_left !== undefined) {
    if (!(req.claims_left >= 0 && req.claims_left <= catalog.card.max_days)) {
      throw new Error("claims_left 0.." + catalog.card.max_days);
    }
    card.claims_left = req.claims_left;
  }
  if (req.claims_total !== undefined) {
    card.claims_total = Math.max(0, Math.floor(req.claims_total));
  }
  if (req.last_claim_day !== undefined) {
    card.last_claim_day = String(req.last_claim_day);
  }
  writeTopupState(nk, userId, st);
  logger.info("QTV %s sửa thẻ tháng của %s: %s", req.operator, req.code, JSON.stringify(card));
  return JSON.stringify({ card: card });
}

function cardView(catalog, st) {
  var c = st.card;
  var cd = (catalog && catalog.card) || { daily: 0, milestone_every: 1, milestone_bonus: 0 };
  var nextTotal = c.claims_total + 1;
  return {
    claims_left: c.claims_left, claims_total: c.claims_total,
    can_claim: c.claims_left > 0 && c.last_claim_day !== dayKey(catalog),
    next_gems: cd.daily + (nextTotal % cd.milestone_every === 0 ? cd.milestone_bonus : 0),
    until_milestone: cd.milestone_every - (c.claims_total % cd.milestone_every)
  };
}

// Người chơi: bảng giá hiện hành, gói nào còn thưởng lần đầu, thẻ tháng, lịch sử nạp gần đây, thông tin nhận tiền.
function rpcTopupInfo(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("cần đăng nhập");
  }
  var catalog = readCatalog(nk);
  var st = readTopupState(nk, ctx.userId).value;
  var epoch = topupEpoch(nk);
  var eligible = {};
  var packs = (catalog && catalog.packs) || [];
  for (var i = 0; i < packs.length; i++) {
    if (packs[i].first_bonus) {
      eligible[packs[i].id] = !(st.bought[packs[i].id] >= epoch);
    }
  }
  return JSON.stringify({
    catalog: catalog, eligible: eligible, card: cardView(catalog, st), log: st.log.slice(0, 10),
    code: ensureCode(nk, logger, ctx.userId)
  });
}

// Người chơi: mua thẻ tháng bằng tiền nạp riêng (owner 2026-11-21: 330 Nguyệt Quang). +days lượt nhận, tối đa max_days.
function rpcCardBuy(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("cần đăng nhập");
  }
  var catalog = readCatalog(nk);
  var cd = catalog && catalog.card;
  if (!cd || !cd.cost) {
    throw new Error("card_not_for_sale");
  }
  var st = readTopupState(nk, ctx.userId);
  if (st.value.card.claims_left + cd.days > cd.max_days) {
    throw new Error("card_max");
  }
  var account = nk.accountGetId(ctx.userId);
  if ((walletOf(account)[cd.cost_currency] || 0) < cd.cost) {
    throw new Error("card_not_enough");
  }
  st.value.card.claims_left += cd.days;
  var t = Math.floor(Date.now() / 1000);
  st.value.log.unshift({ t: t, pack: "card", base: 0, bonus: 0, card_days: cd.days, paid: 0, cost: cd.cost, cost_currency: cd.cost_currency, ref: "" });
  st.value.log = st.value.log.slice(0, TOPUP_LOG_KEEP);
  try {
    writeTopupState(nk, ctx.userId, st);   // ghi có điều kiện: bấm hai lần cùng lúc chỉ một lần qua
  } catch (e) {
    throw new Error("card_busy");
  }
  var changes = {};
  changes[cd.cost_currency] = -cd.cost;
  try {
    nk.walletUpdate(ctx.userId, changes, { reason: "card_buy", days: cd.days }, true);
  } catch (e) {
    // ví không đủ (vừa tiêu ở nơi khác): trả lại lượt thẻ
    var back = readTopupState(nk, ctx.userId);
    back.value.card.claims_left = Math.max(0, back.value.card.claims_left - cd.days);
    back.value.log.shift();
    writeTopupState(nk, ctx.userId, back);
    throw new Error("card_not_enough");
  }
  logger.info("%s mua thẻ tháng (%d %s)", ctx.username, cd.cost, cd.cost_currency);
  return JSON.stringify({ card: cardView(catalog, st.value), wallet: walletOf(nk.accountGetId(ctx.userId)) });
}

// Người chơi: nhận quà thẻ tháng hôm nay.
function rpcCardClaim(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("cần đăng nhập");
  }
  var catalog = readCatalog(nk);
  if (!catalog || !catalog.card) {
    throw new Error("card_none");
  }
  var st = readTopupState(nk, ctx.userId);
  var card = st.value.card;
  if (card.claims_left <= 0) {
    throw new Error("card_none");
  }
  var today = dayKey(catalog);
  if (card.last_claim_day === today) {
    throw new Error("card_claimed_today");
  }
  card.claims_left -= 1;
  card.claims_total += 1;
  card.last_claim_day = today;
  var bonus = card.claims_total % catalog.card.milestone_every === 0 ? catalog.card.milestone_bonus : 0;
  var gems = catalog.card.daily + bonus;
  try {
    writeTopupState(nk, ctx.userId, st);   // ghi có điều kiện: hai lần bấm cùng lúc chỉ một lần thành công
  } catch (e) {
    throw new Error("card_claimed_today");
  }
  nk.walletUpdate(ctx.userId, { gems: gems }, { reason: "card_claim", day: today, claims_total: card.claims_total, bonus: bonus }, true);
  return JSON.stringify({ gems: gems, daily: catalog.card.daily, bonus: bonus, card: cardView(catalog, st.value) });
}

// ---------- Chat (M9-6) ----------
// Chat thời gian thực dùng kênh có sẵn của Nakama: phòng "world" (type 1) và nhắn riêng (type 2). Game KHÔNG được tạo
// phòng khác. Mọi tin đi qua hook trước khi gửi: kiểm tra cấm chat, tần suất, độ dài, người nhận có chặn không, lọc từ.
// Bạn bè / chặn dùng API bạn bè của Nakama (/v2/friend) trực tiếp từ game; ở đây chỉ có tra cứu theo mã, báo cáo,
// cấm chat (QTV), và thông báo "có tin nhắn riêng" cho người nhận chưa mở kênh (Nakama không đẩy tin riêng cho họ).
// Lỗi gửi cho game bằng message dạng "chat_<lý do>" (game dịch sang chữ hiển thị).

var MUTE_COLLECTION = "chat_mute";        // key = user_id, value {until (ms), reason, operator}
var RATE_COLLECTION = "chat_rate";        // key = user_id, value {t: ms tin gần nhất}
var NOTIFY_COLLECTION = "chat_notify";    // key = người nhận, value {<sender_id>: ms thông báo gần nhất}
var REPORT_COLLECTION = "chat_report";    // key = id báo cáo, value bản ghi báo cáo
var WORLD_ROOM = "world";
var CHAT_MAX_LEN = 200;                   // ký tự mỗi tin
var CHAT_MIN_INTERVAL_MS = 800;           // giãn cách giữa hai tin của một người
var NOTIFY_INTERVAL_MS = 30000;           // tối đa 1 thông báo / người gửi / 30 giây
var NOTIFY_CODE_DM = 100;
var REPORT_REASONS = ["spam", "abuse", "inappropriate", "cheat", "other"];
var MAX_MUTE_MIN = 60 * 24 * 365;

// Từ cấm. Khớp theo từ (có ranh giới chữ), không phân biệt hoa thường; che bằng dấu *.
//  - BAD_WORDS_ACCENT: so khớp đúng dấu tiếng Việt (tránh bắt nhầm "lớn" khi bỏ dấu thành "lon").
//  - BAD_WORDS_FOLDED: dạng viết tắt không dấu hay dùng để né lọc. QTV sửa danh sách ở đây rồi khởi động lại Nakama.
var BAD_WORDS_ACCENT = ["địt", "đụ", "lồn", "cặc", "đĩ", "đm", "đmm", "đcm", "đkm", "đéo", "súc vật", "óc chó"];
var BAD_WORDS_FOLDED = ["dm", "dmm", "dcm", "dkm", "dcmm", "vcl", "vkl", "clm", "cmm", "cmn", "dit me", "dit con me"];

function isWordChar(ch) {
  return !!ch && /[0-9A-Za-z_\u00C0-\u1EF9]/.test(ch);
}

// Che mọi lần xuất hiện của `words` trong `text` (khớp trên `hay` cùng độ dài với text).
function maskWords(text, hay, words) {
  var out = text.split("");
  for (var w = 0; w < words.length; w++) {
    var word = words[w];
    var from = 0;
    while (true) {
      var i = hay.indexOf(word, from);
      if (i < 0) {
        break;
      }
      var end = i + word.length;
      if (!isWordChar(hay.charAt(i - 1)) && !isWordChar(hay.charAt(end))) {
        for (var k = i; k < end; k++) {
          if (out[k] !== " ") {
            out[k] = "*";
          }
        }
      }
      from = i + 1;
    }
  }
  return out.join("");
}

// Bỏ dấu 1-1 (giữ nguyên độ dài chuỗi) để so khớp dạng viết tắt không dấu.
var FOLD_FROM = "àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ";
var FOLD_TO   = "aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd";
function foldChar(ch) {
  var i = FOLD_FROM.indexOf(ch);
  return i >= 0 ? FOLD_TO.charAt(i) : ch;
}

function filterText(text) {
  var lower = text.toLowerCase();
  var out = maskWords(text, lower, BAD_WORDS_ACCENT);
  var folded = "";
  for (var i = 0; i < lower.length; i++) {
    folded += foldChar(lower.charAt(i));
  }
  return maskWords(out, folded, BAD_WORDS_FOLDED);
}

function cleanChatText(raw) {
  var s = String(raw || "").replace(/[\u0000-\u001F\u007F]/g, " ").replace(/\s+/g, " ").trim();
  return s;
}

function readOne(nk, collection, key) {
  var rows = nk.storageRead([{ collection: collection, key: key, userId: SYSTEM_USER }]);
  return rows && rows.length > 0 ? rows[0] : null;
}

function writeSystem(nk, collection, key, value) {
  nk.storageWrite([{ collection: collection, key: key, userId: SYSTEM_USER, value: value, permissionRead: 0, permissionWrite: 0 }]);
}

// Throw nếu người chơi đang bị cấm chat.
function assertNotMuted(nk, userId) {
  var row = readOne(nk, MUTE_COLLECTION, userId);
  if (row && row.value.until > Date.now()) {
    throw new Error("chat_muted:" + row.value.until);
  }
}

function assertRate(nk, userId) {
  var row = readOne(nk, RATE_COLLECTION, userId);
  var now = Date.now();
  if (row && now - row.value.t < CHAT_MIN_INTERVAL_MS) {
    throw new Error("chat_rate");
  }
  writeSystem(nk, RATE_COLLECTION, userId, { t: now });
}

// Kênh nhắn riêng có id "4.<user_id_1>.<user_id_2>." → id người còn lại.
function dmPeer(channelId, me) {
  var parts = String(channelId).split(".");
  if (parts.length < 3 || parts[0] !== "4") {
    return null;
  }
  return parts[1] === me ? parts[2] : (parts[2] === me ? parts[1] : "");
}

function hasBlocked(nk, ownerId, otherId) {
  var cursor = "";
  for (var page = 0; page < 10; page++) {
    var res = nk.friendsList(ownerId, 100, 3, cursor);
    var list = res.friends || [];
    for (var i = 0; i < list.length; i++) {
      if (list[i].user.userId === otherId) {
        return true;
      }
    }
    cursor = res.cursor;
    if (!cursor) {
      break;
    }
  }
  return false;
}

function beforeChannelJoin(ctx, logger, nk, envelope) {
  var j = envelope.channelJoin;
  var type = Number(j.type);
  if (type === 1 && j.target === WORLD_ROOM) {
    return envelope;
  }
  if (type === 2 && j.target && j.target !== ctx.userId) {
    return envelope;
  }
  throw new Error("chat_channel_not_allowed");
}

function beforeChannelMessageSend(ctx, logger, nk, envelope) {
  var m = envelope.channelMessageSend;
  var userId = ctx.userId;
  var body;
  try {
    body = JSON.parse(m.content);
  } catch (e) {
    throw new Error("chat_empty");
  }
  var text = cleanChatText(body && body.text);
  if (!text) {
    throw new Error("chat_empty");
  }
  if (text.length > CHAT_MAX_LEN) {
    throw new Error("chat_too_long");
  }
  assertNotMuted(nk, userId);
  assertRate(nk, userId);
  var peer = dmPeer(m.channelId, userId);
  if (peer === "") {
    throw new Error("chat_channel_not_allowed");
  }
  if (peer && hasBlocked(nk, peer, userId)) {
    throw new Error("chat_blocked");
  }
  text = filterText(text);
  m.content = JSON.stringify({ text: text });
  if (peer) {
    notifyDirectMessage(nk, logger, userId, ctx.username, peer, text);
  }
  return envelope;
}

// Báo cho người nhận (đang mở game thì thấy ngay, đang tắt thì thấy khi đăng nhập). Tối đa 1 lần / người gửi / 30 giây.
function notifyDirectMessage(nk, logger, senderId, senderName, peerId, text) {
  var row = readOne(nk, NOTIFY_COLLECTION, peerId);
  var map = row ? row.value : {};
  var now = Date.now();
  if (map[senderId] && now - map[senderId] < NOTIFY_INTERVAL_MS) {
    return;
  }
  map[senderId] = now;
  writeSystem(nk, NOTIFY_COLLECTION, peerId, map);
  try {
    nk.notificationSend(peerId, senderName, { from_id: senderId, from_name: senderName, text: text.substring(0, 60) },
      NOTIFY_CODE_DM, senderId, true);
  } catch (e) {
    logger.warn("không gửi được thông báo tin nhắn riêng: %s", e.message);
  }
}

// Người chơi tra cứu người khác theo mã người chơi (để kết bạn / nhắn riêng). Trả về id + tên, không lộ gì thêm.
function rpcChatFind(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("cần đăng nhập");
  }
  var req = JSON.parse(payload || "{}");
  var code = cleanCode(req.code);
  var userId = code.length === CODE_LENGTH ? userIdByCode(nk, code) : null;
  if (!userId) {
    throw new Error("chat_not_found");
  }
  var account = nk.accountGetId(userId);
  return JSON.stringify({ user_id: userId, username: account.user.username, code: code });
}

function rpcChatReport(ctx, logger, nk, payload) {
  if (!ctx.userId) {
    throw new Error("cần đăng nhập");
  }
  var req = JSON.parse(payload || "{}");
  var target = String(req.target_id || "");
  if (!target || target === ctx.userId) {
    throw new Error("chat_report_invalid");
  }
  var reason = REPORT_REASONS.indexOf(req.reason) >= 0 ? req.reason : "other";
  var accounts = nk.accountsGetId([target]);
  if (!accounts || accounts.length === 0) {
    throw new Error("chat_not_found");
  }
  var id = nk.uuidv4();
  writeSystem(nk, REPORT_COLLECTION, id, {
    id: id, time: Date.now(), reporter_id: ctx.userId, reporter_name: ctx.username,
    target_id: target, target_name: accounts[0].user.username, reason: reason,
    channel_id: String(req.channel_id || "").substring(0, 120),
    message_id: String(req.message_id || "").substring(0, 64),
    text: String(req.text || "").substring(0, CHAT_MAX_LEN), resolved: false
  });
  return JSON.stringify({ id: id });
}

// ---- QTV ----

// Danh sách báo cáo chưa xử lý (mới nhất trước).
function rpcAdminChatReports(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var all = [];
  var cursor = "";
  for (var page = 0; page < 20; page++) {
    var res = nk.storageList(SYSTEM_USER, REPORT_COLLECTION, 100, cursor);
    var objs = res.objects || [];
    for (var i = 0; i < objs.length; i++) {
      if (req.all || !objs[i].value.resolved) {
        all.push(objs[i].value);
      }
    }
    cursor = res.cursor;
    if (!cursor) {
      break;
    }
  }
  all.sort(function (a, b) { return b.time - a.time; });
  return JSON.stringify({ reports: all.slice(0, Number(req.limit) || 50) });
}

function rpcAdminChatResolve(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var row = readOne(nk, REPORT_COLLECTION, String(req.id || ""));
  if (!row) {
    throw new Error("không có báo cáo " + req.id);
  }
  row.value.resolved = true;
  row.value.resolved_by = String(req.operator || "");
  writeSystem(nk, REPORT_COLLECTION, row.key, row.value);
  return JSON.stringify({ id: row.key, resolved: true });
}

// Cấm chat `minutes` phút (0 = gỡ cấm).
function rpcAdminChatMute(ctx, logger, nk, payload) {
  requireAdmin(ctx);
  var req = JSON.parse(payload || "{}");
  var code = cleanCode(req.code);
  var userId = userIdByCode(nk, code);
  if (!userId) {
    throw new Error("không có người chơi mã " + code);
  }
  var minutes = Number(req.minutes);
  if (!(minutes >= 0) || minutes > MAX_MUTE_MIN || Math.floor(minutes) !== minutes) {
    throw new Error("minutes phải là số nguyên 0.." + MAX_MUTE_MIN);
  }
  if (!req.operator || String(req.operator).trim() === "") {
    throw new Error("thiếu tên QTV (operator)");
  }
  var until = minutes === 0 ? 0 : Date.now() + minutes * 60000;
  writeSystem(nk, MUTE_COLLECTION, userId, { until: until, reason: String(req.reason || ""), operator: String(req.operator).trim(), time: Date.now() });
  logger.info("QTV %s %s chat của %s (%s phút)", req.operator, minutes === 0 ? "gỡ cấm" : "cấm", code, minutes);
  return JSON.stringify({ code: code, user_id: userId, muted_until: until });
}

function InitModule(ctx, logger, nk, initializer) {
  initializer.registerRpc("save_get", rpcSaveGet);
  initializer.registerRpc("save_put", rpcSavePut);
  initializer.registerRpc("gacha_pull", rpcGachaPull);
  initializer.registerRpc("admin_set_rules", rpcAdminSetRules);
  initializer.registerRpc("admin_cheat_flags", rpcAdminCheatFlags);
  initializer.registerRpc("admin_cheat_clear", rpcAdminCheatClear);
  initializer.registerRpc("admin_save_restore", rpcAdminSaveRestore);
  initializer.registerAfterAuthenticateDevice(afterAuthenticateDevice);
  initializer.registerBeforeAuthenticateEmail(beforeAuthenticateEmail);
  initializer.registerAfterAuthenticateEmail(afterAuthenticateEmail);
  initializer.registerRpc("eclipse_profile", rpcProfile);
  initializer.registerRpc("admin_find", rpcAdminFind);
  initializer.registerRpc("admin_grant", rpcAdminGrant);
  initializer.registerRpc("admin_set_packs", rpcAdminSetPacks);
  initializer.registerRpc("admin_topup", rpcAdminTopup);
  initializer.registerRpc("admin_topup_reset", rpcAdminTopupReset);
  initializer.registerRpc("admin_topup_state", rpcAdminTopupState);
  initializer.registerRpc("admin_card_set", rpcAdminCardSet);
  initializer.registerRpc("topup_info", rpcTopupInfo);
  initializer.registerRpc("card_claim", rpcCardClaim);
  initializer.registerRpc("card_buy", rpcCardBuy);
  initializer.registerRtBefore("ChannelJoin", beforeChannelJoin);
  initializer.registerRtBefore("ChannelMessageSend", beforeChannelMessageSend);
  initializer.registerRpc("chat_find", rpcChatFind);
  initializer.registerRpc("chat_report", rpcChatReport);
  initializer.registerRpc("admin_chat_reports", rpcAdminChatReports);
  initializer.registerRpc("admin_chat_resolve", rpcAdminChatResolve);
  initializer.registerRpc("admin_chat_mute", rpcAdminChatMute);
  logger.info("PROJECT ECLIPSE module đã nạp");
}

// Nakama tìm InitModule ở phạm vi toàn cục; dòng dưới để trình đóng gói không xóa hàm.
!InitModule && InitModule.bind(null);
