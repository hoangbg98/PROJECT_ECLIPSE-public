// Kiểm tra bộ chống gian lận (kiểm save) trên máy chủ THẬT, không cần Godot. Cần Node >= 22 và luật đã đẩy (audit.ps1 -SyncRules;
// script tự đẩy lại luật từ data/config/anti_cheat.json + server/rules/game_rules.json).
// Chạy: node server/tests/audit_smoke.mjs [--server http://127.0.0.1:7350]
// Save dựng bằng JS theo đúng định dạng SaveStore.encode (data = chuỗi JSON, checksum = sha256 của chuỗi đó).
import fs from "node:fs";
import path from "node:path";
import crypto from "node:crypto";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const SERVER = args.includes("--server") ? args[args.indexOf("--server") + 1] : "http://127.0.0.1:7350";
const KEY = "eclipse-test-key";
const secrets = JSON.parse(fs.readFileSync(path.join(here, "..", ".runtime", "secrets.json"), "utf8"));
const root = path.join(here, "..", "..");
const rules = JSON.parse(fs.readFileSync(path.join(root, "data", "config", "anti_cheat.json"), "utf8"));
const game = JSON.parse(fs.readFileSync(path.join(root, "server", "rules", "game_rules.json"), "utf8"));
for (const k of Object.keys(game)) if (k !== "_comment") rules[k] = game[k];
// Bộ này thử các luật kiểm save với lượt gacha do game tự thêm (trước M9-2c): tắt gacha-trên-máy-chủ; gacha_smoke.mjs thử khi bật.
const realRules = JSON.parse(JSON.stringify(rules));
rules.server_gacha = false;
const basic = "Basic " + Buffer.from(KEY + ":").toString("base64");

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
async function rpc(user, id, payload = {}) {
  const r = await json(`${SERVER}/v2/rpc/${id}`, {
    method: "POST", headers: { Authorization: "Bearer " + user.token, "Content-Type": "application/json" },
    body: JSON.stringify(JSON.stringify(payload)) });
  return r.status === 200 ? { ok: true, data: JSON.parse(r.body.payload) } : { ok: false, error: String(r.body.message || r.body) };
}
async function account() {
  const name = "ac" + Math.floor(Math.random() * 1e8);
  const r = await json(`${SERVER}/v2/account/authenticate/email?create=true&username=${name}`, {
    method: "POST", headers: { Authorization: basic, "Content-Type": "application/json" },
    body: JSON.stringify({ email: name + "@example.com", password: "matkhau123" }) });
  const u = { name, token: r.body.token, version: "" };
  u.code = (await rpc(u, "eclipse_profile")).data.code;
  return u;
}
function baseData() {
  return {
    characters: { char_fire_01: { level: 1, exp: 0, equipment: {}, skills: {}, fragments: 0, promotion: 0 } },
    currencies: { gold: 0, gems: 0 }, account: { level: 1, exp: 0, name: "" },
    gacha: { pity: {}, guarantee: {}, history: [], starter_used: [] }, online: { applied: { gems: 0 } },
  };
}
function envelope(data, forgeChecksum = false) {
  const body = JSON.stringify(data);
  return { schema_version: 6, saved_at: "2026-11-21T00:00:00",
    checksum: forgeChecksum ? "0".repeat(64) : crypto.createHash("sha256").update(body, "utf8").digest("hex"), data: body };
}
async function put(u, data, forge = false) {
  const r = await rpc(u, "save_put", { envelope: envelope(data, forge), base_version: u.version });
  if (r.ok) u.version = r.data.version;
  return r;
}
const clone = (d) => JSON.parse(JSON.stringify(d));
const pull = (banner, item, i) => ({ banner, item, rarity: 3, tier: "B", featured: false, duplicate: false, pity: 1, forced: false, time: "t" + i });
const stamp = Date.now() % 1e8;
let refN = 0;
const ref = () => `AC-${stamp}-${++refN}`;

console.log("Máy chủ:", SERVER);
check((await admin("admin_set_rules", { rules })).ok, "đẩy luật chống gian lận");

// ---- lỗi cứng
const u = await account();
let d = baseData();
check((await put(u, d)).ok, "save hợp lệ đầu tiên được nhận");
let r = await put(u, d, true);
check(!r.ok && r.error.includes("save_rejected:checksum"), "checksum giả bị từ chối", r.error);
d = baseData(); d.currencies.gems = -5;
r = await put(u, d);
check(!r.ok && r.error.includes("currency_invalid:gems"), "Ngọc âm bị từ chối", r.error);
d = baseData(); d.currencies.gems = rules.max_currency.gems + 1;
r = await put(u, d);
check(!r.ok && r.error.includes("currency_over_cap:gems"), "Ngọc vượt trần bị từ chối", r.error);
d = baseData(); d.online.applied.gems = 6600; d.currencies.gems = 6600;
r = await put(u, d);
check(!r.ok && r.error.includes("purchased_gems_forged"), "khai khống Ngọc đã nạp bị từ chối", r.error);
d = baseData(); d.characters.char_fire_01.level = rules.max_level + 1;
r = await put(u, d);
check(!r.ok && r.error.includes("char_level:char_fire_01"), "cấp nhân vật vượt trần bị từ chối", r.error);
d = baseData(); d.account.level = 999;
r = await put(u, d);
check(!r.ok && r.error.includes("captain_level"), "cấp người chơi vượt trần bị từ chối", r.error);
d = baseData(); d.characters.char_fire_01.skills = { skill: 99 };
r = await put(u, d);
check(!r.ok && r.error.includes("skill_level"), "cấp kỹ năng vượt trần bị từ chối", r.error);
const saved = await rpc(u, "save_get");
check(JSON.parse(saved.data.envelope.data).currencies.gems === 0, "save trên máy chủ vẫn là bản hợp lệ cũ");

// ---- Ngọc đã nạp thật thì hợp lệ
const g = await admin("admin_topup", { code: u.code, pack: "gems_330", paid: 70000, ref: ref(), operator: "t" });
check(g.ok, "QTV phát gói 330 (+330 thưởng)", JSON.stringify(g).slice(0, 100));
d = baseData(); d.online.applied.gems = 660; d.currencies.gems = 660;
check((await put(u, d)).ok, "Ngọc đã nạp thật (660 ≤ ví 660) được nhận");

// ---- lịch sử gacha
d.gacha.history = [pull("banner_char_terra", "gold:1000", 1), pull("banner_char_terra", "item:mat_exp_small", 2)];
d.currencies.gems = 660 - 2 * 280;
check((await put(u, d)).ok, "thêm 2 lượt gacha + trừ đúng Ngọc: nhận");
const d2 = clone(d); d2.gacha.history[0].item = "char:char_earth_01";
r = await put(u, d2);
check(!r.ok && r.error.includes("gacha_history_edited"), "sửa lượt gacha cũ bị từ chối", r.error);
const d3 = clone(d); d3.gacha.history = [d.gacha.history[1]];
d3.gacha.history.push(pull("banner_char_terra", "gold:500", 3));
r = await put(u, d3);
check(!r.ok && r.error.includes("gacha_history_edited"), "xóa lượt gacha giữa chừng bị từ chối", r.error);

// lịch sử đầy 200: lượt cũ nhất bị cắt khi thêm lượt mới (hợp lệ)
const w = await account();
const dw = baseData(); dw.currencies.gems = 0;
dw.gacha.history = Array.from({ length: 200 }, (_, i) => pull("starter_pull", "gold:1", 1000 + i));
check((await put(w, dw)).ok, "lịch sử 200 lượt (banner miễn phí) được nhận");
const dw2 = clone(dw); dw2.gacha.history = dw.gacha.history.slice(1).concat([pull("starter_pull", "gold:1", 5000)]);
r = await put(w, dw2);
check(r.ok, "đầy 200: cắt lượt cũ nhất + thêm lượt mới được nhận", JSON.stringify(r));
const dw3 = clone(dw2); dw3.gacha.history = dw2.gacha.history.slice(5);
r = await put(w, dw3);
check(!r.ok && r.error.includes("gacha_history_edited"), "xóa bớt lượt khi chưa đầy bị từ chối", r.error);
await admin("admin_cheat_clear", { code: w.code, operator: "t" });

// ---- lỗi mềm: nhận save nhưng đánh dấu
await admin("admin_cheat_clear", { code: u.code, operator: "t" });
const d4 = clone(d); d4.currencies.gems += 50000;
r = await put(u, d4);
check(r.ok, "Ngọc tăng bất thường: save vẫn được nhận (lỗi mềm)", JSON.stringify(r));
let fl = await admin("admin_cheat_flags", { code: u.code });
check(fl.ok && fl.data.flags[0] && fl.data.flags[0].entries[0].kind === "soft" && fl.data.flags[0].entries[0].reasons[0].startsWith("gems_earned:"),
  "…nhưng bị đánh dấu gems_earned", JSON.stringify(fl).slice(0, 200));
const d5 = clone(d4); d5.characters.char_earth_01 = { level: 1, exp: 0, equipment: {}, skills: {}, fragments: 0, promotion: 0 };
r = await put(u, d5);
check(r.ok, "nhân vật mới không rõ nguồn: vẫn nhận", JSON.stringify(r));
fl = await admin("admin_cheat_flags", { code: u.code });
check(fl.data.flags[0].entries[0].reasons.includes("character_unknown_source:char_earth_01"), "…và bị đánh dấu nguồn nhân vật");
const d6 = clone(d5); d6.characters.char_wind_01 = { level: 1, exp: 0, equipment: {}, skills: {}, fragments: 0, promotion: 0 };
const before = fl.data.flags[0].count;
r = await put(u, d6);
fl = await admin("admin_cheat_flags", { code: u.code });
check(r.ok && fl.data.flags[0].count === before, "nhân vật nhận từ phần thưởng màn (char_wind_01): không đánh dấu");
const d7 = clone(d6); d7.gacha.history.push(pull("banner_char_terra", "char:char_light_01", 9));
d7.characters.char_light_01 = { level: 1, exp: 0, equipment: {}, skills: {}, fragments: 0, promotion: 0 };
d7.currencies.gems -= 280;
r = await put(u, d7);
fl = await admin("admin_cheat_flags", { code: u.code });
check(r.ok && fl.data.flags[0].count === before, "nhân vật từ lượt gacha mới: không đánh dấu");
const d8 = clone(d7); d8.gacha.history.push(pull("banner_khong_co", "gold:1", 10));
r = await put(u, d8);
fl = await admin("admin_cheat_flags", { code: u.code });
check(r.ok && fl.data.flags[0].entries[0].reasons.some((x) => x.startsWith("gacha_unknown_banner")), "banner lạ: đánh dấu");

// ---- QTV
const list = await admin("admin_cheat_flags", {});
check(list.ok && list.data.flags.some((f) => f.code === u.code), "QTV thấy tài khoản trong danh sách đánh dấu");
check(!(await rpc(u, "admin_cheat_flags", {})).ok, "người chơi không gọi được RPC của QTV");
const rs = await admin("admin_save_restore", { code: u.code, operator: "t" });
check(rs.ok, "QTV khôi phục save trước");
const after = JSON.parse((await rpc(u, "save_get")).data.envelope.data);
check(after.gacha.history.length === d7.gacha.history.length, "save sau khôi phục là bản trước đó");
check((await admin("admin_cheat_clear", { code: u.code, operator: "t" })).ok, "QTV xóa đánh dấu");
fl = await admin("admin_cheat_flags", { code: u.code });
check(fl.data.flags.length === 0, "hết đánh dấu");

// ---- chế độ chỉ đánh dấu (hard_reject = false)
await admin("admin_set_rules", { rules: Object.assign({}, rules, { hard_reject: false }) });
const v = await account();
d = baseData();
await put(v, d);
d.currencies.gems = -1;
r = await put(v, d);
fl = await admin("admin_cheat_flags", { code: v.code });
check(r.ok && fl.data.flags[0].hard === 1, "hard_reject=false: không từ chối, chỉ đánh dấu cứng");
await admin("admin_cheat_clear", { code: v.code, operator: "t" });
check((await admin("admin_set_rules", { rules: realRules })).ok, "trả lại luật thật");
console.log(fails === 0 ? "ĐẠT" : `CÓ ${fails} BƯỚC LỖI`);
process.exit(fails === 0 ? 0 : 1);
