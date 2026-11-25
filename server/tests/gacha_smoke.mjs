// Kiểm tra gacha chạy trên máy chủ (M9-2c) trên Nakama THẬT, không cần Godot. Cần Node >= 22.
// Chạy: node server/tests/gacha_smoke.mjs [--server http://127.0.0.1:7350]
// Đẩy luật thật (data/config/anti_cheat.json + server/rules/game_rules.json), dựng save theo định dạng SaveStore.encode.
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const SERVER = args.includes("--server") ? args[args.indexOf("--server") + 1] : "http://127.0.0.1:7350";
const secrets = JSON.parse(fs.readFileSync(path.join(here, "..", ".runtime", "secrets.json"), "utf8"));
const root = path.join(here, "..", "..");
const rules = JSON.parse(fs.readFileSync(path.join(root, "data", "config", "anti_cheat.json"), "utf8"));
const game = JSON.parse(fs.readFileSync(path.join(root, "server", "rules", "game_rules.json"), "utf8"));
for (const k of Object.keys(game)) if (k !== "_comment") rules[k] = game[k];
const basic = "Basic " + Buffer.from("eclipse-test-key:").toString("base64");

let fails = 0;
function check(ok, what, extra = "") {
  console.log((ok ? "  ĐẠT  " : "  LỖI  ") + what + (ok ? "" : "   " + extra));
  if (!ok) fails++;
}
async function json(url, opts = {}) {
  const r = await fetch(url, opts);
  const t = await r.text();
  let body = t;
  try { body = JSON.parse(t); } catch { /* chuỗi */ }
  return { status: r.status, body };
}
async function admin(id, payload) {
  const r = await json(`${SERVER}/v2/rpc/${id}?http_key=${secrets.http_key}&unwrap`, {
    method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload) });
  return r.status === 200 ? { ok: true, data: r.body } : { ok: false, error: String(r.body.message || r.body) };
}
async function rpc(u, id, payload = {}) {
  const r = await json(`${SERVER}/v2/rpc/${id}`, {
    method: "POST", headers: { Authorization: "Bearer " + u.token, "Content-Type": "application/json" },
    body: JSON.stringify(JSON.stringify(payload)) });
  return r.status === 200 ? { ok: true, data: JSON.parse(r.body.payload) } : { ok: false, error: String(r.body.message || r.body) };
}
async function account() {
  const name = "gc" + Math.floor(Math.random() * 1e8);
  const r = await json(`${SERVER}/v2/account/authenticate/email?create=true&username=${name}`, {
    method: "POST", headers: { Authorization: basic, "Content-Type": "application/json" },
    body: JSON.stringify({ email: name + "@example.com", password: "matkhau123" }) });
  return { name, token: r.body.token, version: "" };
}
function baseData(gems, extra = {}) {
  return Object.assign({
    characters: { char_fire_01: { level: 1, exp: 0, equipment: {}, skills: {}, fragments: 0, promotion: 0 } },
    party: ["char_fire_01"], currencies: { gold: 0, gems }, account: { level: 1, exp: 0, name: "" },
    inventory: { next_uid: 1, equipment: {}, materials: {} },
    gacha: { pity: {}, guarantee: {}, history: [], starter_used: [] }, online: { applied: { gems: 0 } },
  }, extra);
}
// Giống Godot: khóa sắp xếp khi ghi.
function sortedStringify(v) {
  if (Array.isArray(v)) return "[" + v.map(sortedStringify).join(",") + "]";
  if (v && typeof v === "object") return "{" + Object.keys(v).sort().map((k) => JSON.stringify(k) + ":" + sortedStringify(v[k])).join(",") + "}";
  return JSON.stringify(v);
}
function envelope(data) {
  const body = sortedStringify(data);
  return { schema_version: 6, saved_at: "x", checksum: crypto.createHash("sha256").update(body, "utf8").digest("hex"), data: body };
}
async function put(u, data) {
  const r = await rpc(u, "save_put", { envelope: envelope(data), base_version: u.version });
  if (r.ok) u.version = r.data.version;
  return r;
}
async function pull(u, banner, count, starter = false) {
  const r = await rpc(u, "gacha_pull", { banner, count, starter, base_version: u.version });
  if (r.ok) {
    u.version = r.data.version;
    u.data = JSON.parse(r.data.envelope.data);
  }
  return r;
}

console.log("Máy chủ:", SERVER);
check((await admin("admin_set_rules", { rules })).ok, "đẩy luật (gacha trên máy chủ bật)");
check(rules.server_gacha === true, "luật thật có server_gacha = true");
const char = rules.gacha_banners.banner_char_terra;

// ---- quay cơ bản
const u = await account();
let r = await pull(u, "banner_char_terra", 1);
check(!r.ok && r.error.includes("gacha_no_save"), "chưa có save thì không quay được", r.error);
check((await put(u, baseData(2700))).ok, "save đầu (2700 Ngọc)");
r = await pull(u, "banner_char_terra", 1);
check(r.ok && r.data.results.length === 1, "quay đơn: 1 kết quả", JSON.stringify(r).slice(0, 200));
const env = r.data.envelope;
check(crypto.createHash("sha256").update(env.data, "utf8").digest("hex") === env.checksum, "save máy chủ trả về có checksum đúng");
check(u.data.currencies.gems === 2700 - char.cost_single, "trừ đúng giá đơn (" + char.cost_single + ")", String(u.data.currencies.gems));
check(u.data.gacha.history.length === 1 && u.data.gacha.history[0].banner === "banner_char_terra", "ghi lịch sử");
const res0 = r.data.results[0];
check(["S", "A", "B", "MAT"].includes(res0.tier) && typeof res0.pity === "number" && res0.time.length === 19, "kết quả đúng định dạng", JSON.stringify(res0));
const saved = JSON.parse((await rpc(u, "save_get")).data.envelope.data);
check(saved.currencies.gems === u.data.currencies.gems, "save trên máy chủ = save trả về");
r = await pull(u, "banner_char_terra", 3);
check(!r.ok && r.error.includes("gacha_reason:bad_count"), "3 lượt: sai số lượt", r.error);
r = await pull(u, "banner_char_terra", 10);
check(!r.ok && r.error.includes("gacha_reason:not_enough_currency"), "thiếu Ngọc: từ chối, không trừ", r.error);
r = await pull(u, "banner_khong_co", 1);
check(!r.ok && r.error.includes("gacha_reason:invalid_banner"), "banner lạ: từ chối");
const stale = await rpc(u, "gacha_pull", { banner: "banner_char_terra", count: 1, base_version: "cu" });
check(!stale.ok && stale.error.includes("save_conflict"), "base_version cũ: save_conflict", stale.error);

// ---- game gửi save sau khi quay (khóa sắp xếp lại như Godot): hợp lệ
const after = JSON.parse(JSON.stringify(u.data));
after.currencies.gold += 10;
r = await put(u, after);
check(r.ok, "save do game gửi lại sau khi quay (khóa sắp xếp khác) được nhận", JSON.stringify(r));
// ---- game tự thêm lượt quay / sửa pity: từ chối
const forged = JSON.parse(JSON.stringify(after));
forged.gacha.history.push({ banner: "banner_char_terra", item: "char:char_earth_01", rarity: 5, tier: "S", featured: true, duplicate: false, pity: 1, forced: false, time: "2026-11-21T00:00:00" });
forged.characters.char_earth_01 = { level: 1, exp: 0, equipment: {}, skills: {}, fragments: 0, promotion: 0 };
r = await put(u, forged);
check(!r.ok && r.error.includes("gacha_client_pull"), "game tự thêm lượt 5★: từ chối", r.error);
const pityEdit = JSON.parse(JSON.stringify(after));
pityEdit.gacha.pity.char = { S: 99, A: 9, B: 1, MAT: 1 };
r = await put(u, pityEdit);
check(!r.ok && r.error.includes("gacha_state_edited"), "game sửa pity lên 99: từ chối", r.error);
const starterEdit = JSON.parse(JSON.stringify(after));
starterEdit.gacha.starter_used = [];
r = await put(u, JSON.parse(JSON.stringify(after)));
check(r.ok, "save không đổi gacha vẫn được nhận");

// ---- x10 có bảo đảm + nhiều lượt: kiểm pity cứng và phân bố
const v = await account();
check((await put(v, baseData(2000000))).ok, "save 2 000 000 Ngọc");
let all = [];
let tenOk = true;
for (let i = 0; i < 100; i++) {
  r = await pull(v, "banner_char_terra", 10);
  if (!r.ok) { check(false, "quay x10 lần " + i, r.error); break; }
  if (!r.data.results.some((x) => char.multi_guarantee_tiers.includes(x.tier))) tenOk = false;
  all = all.concat(r.data.results);
}
check(all.length === 1000, "1000 lượt (100 lần x10)");
check(tenOk, "mỗi gói x10 có ít nhất 1 bậc S / A (bảo đảm)");
check(v.data.currencies.gems === 2000000 - 100 * char.cost_multi, "trừ đúng 100 × giá x10");
const sTier = char.tiers[0];
let gap = 0, maxGap = 0, sCount = 0;
for (const x of all) { gap++; if (x.tier === "S") { sCount++; maxGap = Math.max(maxGap, gap); gap = 0; } }
check(sCount >= Math.floor(1000 / sTier.hard_pity), "số lần ra S ≥ 1000 / pity cứng (" + sCount + ")");
check(maxGap <= sTier.hard_pity, "không lần nào quá " + sTier.hard_pity + " lượt mới ra S (dài nhất " + maxGap + ")");
const sPityOk = all.filter((x) => x.tier === "S").every((x) => x.pity <= sTier.hard_pity);
check(sPityOk, "pity ghi trong kết quả S ≤ pity cứng");
check(v.data.characters.char_earth_01 && v.data.characters.char_earth_01.fragments > 0, "ra S lần hai: nhân vật trùng → mảnh");
check(v.data.gacha.history.length === rules.history_limit, "lịch sử giữ đúng " + rules.history_limit + " lượt");
check(Object.keys(v.data.inventory.materials).length > 0 && v.data.currencies.gold >= 0, "trao nguyên liệu / vàng");

// ---- banner trang bị 5★: món đã có không ra lại cho tới khi đủ bộ
const star = rules.gacha_banners.banner_star5_earth;
const x5 = star.tiers.find((t) => t.exclude_owned_until_complete);
const w = await account();
check((await put(w, baseData(5000000))).ok, "save 5 000 000 Ngọc (banner 5★)");
const got = [];
for (let i = 0; i < 40 && got.length < x5.pool.length + 1; i++) {
  r = await pull(w, "banner_star5_earth", 10);
  if (!r.ok) { check(false, "quay banner 5★", r.error); break; }
  for (const x of r.data.results) if (x.tier === x5.key) got.push(x.item);
}
const firstSet = got.slice(0, x5.pool.length);
check(new Set(firstSet).size === firstSet.length, "món 5★ không trùng cho tới khi đủ bộ (" + firstSet.length + "/" + x5.pool.length + ")", JSON.stringify(got));
const eq = Object.values(w.data.inventory.equipment);
check(eq.length > 0 && eq.every((e) => e.level === 0 && !e.affixes), "trang bị mới: cấp 0, chưa có phụ tố (game gieo khi nạp)");

// ---- lượt miễn phí người mới (cần vé)
const st = rules.gacha_banners.starter_pull;
const z = await account();
check((await put(z, baseData(0))).ok, "save 0 Ngọc");
r = await pull(z, "starter_pull", 10, true);
check(!r.ok && r.error.includes("no_ticket"), "chưa có vé: từ chối", r.error);
const withTicket = baseData(0); withTicket.inventory.materials[st.ticket_item] = 1;
check((await put(z, withTicket)).ok, "nhận vé (save có 1 vé)");
r = await pull(z, "starter_pull", 10, true);
check(r.ok && r.data.results.length === st.multi_count, "lượt miễn phí: 10 kết quả", JSON.stringify(r).slice(0, 150));
check(r.ok && r.data.results.filter((x) => x.tier === st.tiers[0].key).length === 1, "đúng 1 lượt ra bậc đầu");
check(z.data.currencies.gems === 0 && !z.data.inventory.materials[st.ticket_item] && z.data.gacha.starter_used.includes("starter_pull"), "không tốn Ngọc, trừ vé, ghi đã dùng");
r = await pull(z, "starter_pull", 10, true);
check(!r.ok && r.error.includes("starter_used"), "dùng lần hai: từ chối");
const reopen = JSON.parse(JSON.stringify(z.data)); reopen.gacha.starter_used = []; reopen.inventory.materials[st.ticket_item] = 1;
r = await put(z, reopen);
check(!r.ok && r.error.includes("gacha_state_edited"), "game xóa 'đã dùng' để quay lại: từ chối", r.error);

console.log(fails === 0 ? "ĐẠT" : `CÓ ${fails} BƯỚC LỖI`);
process.exit(fails === 0 ? 0 : 1);
