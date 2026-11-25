// Kiểm tra module nạp tiền trên máy chủ THẬT (Nakama đang chạy), không cần Godot. Cần Node >= 22.
// Chạy: node server/tests/topup_smoke.mjs [--server http://127.0.0.1:7350]
// Dùng bảng giá thật data/shop/topup_packs.json (đẩy lên máy chủ bằng admin_set_packs) và tài khoản tạm tp<số>.
// Lưu ý: kiểm "mở lại thưởng nạp lần đầu" TĂNG KỲ toàn máy chủ (người chơi thật sẽ được thưởng lần đầu lại một lần).
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const args = process.argv.slice(2);
const SERVER = args.includes("--server") ? args[args.indexOf("--server") + 1] : "http://127.0.0.1:7350";
const KEY = "eclipse-test-key";
const secrets = JSON.parse(fs.readFileSync(path.join(here, "..", ".runtime", "secrets.json"), "utf8"));
const catalog = JSON.parse(fs.readFileSync(path.join(here, "..", "..", "data", "shop", "topup_packs.json"), "utf8"));
// Thông tin nhận tiền không nằm trong topup_packs.json: lấy bản thật (server/private) nếu có, không thì bản mẫu.
const privPay = path.join(here, "..", "private", "payment.json");
const examplePay = path.join(here, "..", "..", "data", "shop", "payment.example.json");
catalog.payment = JSON.parse(fs.readFileSync(fs.existsSync(privPay) ? privPay : examplePay, "utf8"));
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
  try { body = JSON.parse(t); } catch { /* giữ chuỗi */ }
  return { status: r.status, body };
}
async function admin(id, payload) {
  const r = await json(`${SERVER}/v2/rpc/${id}?http_key=${secrets.http_key}&unwrap`, {
    method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload),
  });
  return r.status === 200 ? { ok: true, data: r.body } : { ok: false, error: String(r.body.message || r.body) };
}
async function rpc(user, id, payload = {}) {
  const r = await json(`${SERVER}/v2/rpc/${id}`, {
    method: "POST", headers: { Authorization: "Bearer " + user.token, "Content-Type": "application/json" },
    body: JSON.stringify(JSON.stringify(payload)),
  });
  return r.status === 200 ? { ok: true, data: JSON.parse(r.body.payload) } : { ok: false, error: String(r.body.message || r.body) };
}
async function account() {
  const name = "tp" + Math.floor(Math.random() * 1e8);
  const r = await json(`${SERVER}/v2/account/authenticate/email?create=true&username=${name}`, {
    method: "POST", headers: { Authorization: basic, "Content-Type": "application/json" },
    body: JSON.stringify({ email: name + "@example.com", password: "matkhau123" }),
  });
  const user = { name, token: r.body.token };
  user.code = (await rpc(user, "eclipse_profile")).data.code;
  return user;
}
const stamp = Date.now() % 100000000;
let n = 0;
const ref = () => `TP-${stamp}-${++n}`;
const wallet = async (u) => (await rpc(u, "eclipse_profile")).data.wallet;

console.log("Máy chủ:", SERVER);
const sync = await admin("admin_set_packs", { catalog });
check(sync.ok && sync.data.packs === catalog.packs.length, "đẩy bảng giá lên máy chủ", JSON.stringify(sync));
const bad = await admin("admin_set_packs", { catalog: { packs: [{ id: "x", kind: "currency", currency: "gems", amount: 5, price: -1 }] } });
check(!bad.ok, "bảng giá sai bị từ chối", JSON.stringify(bad));

const u = await account();
let info = await rpc(u, "topup_info");
check(info.ok && info.data.catalog.packs.length === catalog.packs.length, "người chơi thấy bảng giá", JSON.stringify(info).slice(0, 150));
check(info.data.eligible.gems_660 === true && info.data.eligible.moonlight_330 === undefined, "gói Ngọc còn thưởng lần đầu, gói Nguyệt Quang không có thưởng");
check(info.data.catalog.payment.account_number === catalog.payment.account_number, "có thông tin nhận tiền");

// --- kiểm số tiền / gói
let r = await admin("admin_topup", { code: u.code, pack: "gems_660", paid: 100000, ref: ref(), operator: "t" });
check(!r.ok && r.error.includes("so_tien_khong_khop"), "sai số tiền bị từ chối", JSON.stringify(r));
r = await admin("admin_topup", { code: u.code, pack: "gems_999", paid: 1, ref: ref(), operator: "t" });
check(!r.ok && r.error.includes("không có gói"), "gói lạ bị từ chối");
r = await admin("admin_topup", { code: u.code, pack: "card_30", paid: 1, ref: ref(), operator: "t" });
check(!r.ok && r.error.includes("không có gói"), "thẻ tháng không còn bán bằng tiền mặt", JSON.stringify(r));
const asPlayer = await rpc(u, "admin_topup", { code: u.code, pack: "gems_330", paid: 70000, ref: ref(), operator: "t" });
check(!asPlayer.ok, "người chơi không gọi được RPC của QTV");
check((await wallet(u)).gems === undefined, "ví chưa đổi sau các lần bị từ chối");

// --- thưởng nạp lần đầu
const r1 = ref();
r = await admin("admin_topup", { code: u.code, pack: "gems_660", paid: 140000, ref: r1, operator: "t" });
check(r.ok && r.data.granted.base === 660 && r.data.granted.bonus === 660 && r.data.wallet.gems === 1320, "nạp lần đầu 660 → +660 thưởng (ví 1320)", JSON.stringify(r));
r = await admin("admin_topup", { code: u.code, pack: "gems_660", paid: 140000, ref: r1, operator: "t" });
check(!r.ok && r.error.includes("đã được dùng"), "trùng mã giao dịch bị từ chối");
r = await admin("admin_topup", { code: u.code, pack: "gems_660", paid: 140000, ref: ref(), operator: "t" });
check(r.ok && r.data.granted.bonus === 0 && r.data.wallet.gems === 1980, "nạp lần hai không có thưởng (ví 1980)", JSON.stringify(r));
r = await admin("admin_topup", { code: u.code, pack: "gems_330", paid: 70000, ref: ref(), operator: "t" });
check(r.ok && r.data.granted.bonus === 330 && r.data.wallet.gems === 2640, "gói khác vẫn có thưởng lần đầu (ví 2640)", JSON.stringify(r));
r = await admin("admin_topup", { code: u.code, pack: "moonlight_330", paid: 70000, ref: ref(), operator: "t" });
check(r.ok && r.data.granted.bonus === 0 && r.data.wallet.moonlight === 330, "gói Nguyệt Quang: cộng đúng, không thưởng", JSON.stringify(r));
r = await admin("admin_topup", { code: u.code, pack: "gems_1320", paid: 100, ref: ref(), operator: "t", force: true });
check(r.ok && r.data.granted.base === 1320, "-Force bỏ qua kiểm số tiền", JSON.stringify(r));
info = await rpc(u, "topup_info");
check(info.data.eligible.gems_660 === false && info.data.eligible.gems_330 === false && info.data.eligible.gems_3300 === true, "topup_info phản ánh gói đã dùng thưởng");
check(info.data.log.length >= 5 && info.data.log[0].pack === "gems_1320", "lịch sử nạp gần nhất trước");

// --- mở lại thưởng (kỳ mới)
const rs = await admin("admin_topup_reset", { operator: "t" });
check(rs.ok && rs.data.epoch >= 2, "mở lại thưởng nạp lần đầu (kỳ mới)", JSON.stringify(rs));
info = await rpc(u, "topup_info");
check(info.data.eligible.gems_660 === true, "sau khi mở lại: gói 660 lại có thưởng");
r = await admin("admin_topup", { code: u.code, pack: "gems_660", paid: 140000, ref: ref(), operator: "t" });
check(r.ok && r.data.granted.bonus === 660, "nạp gói 660 được thưởng lại ở kỳ mới", JSON.stringify(r));

// --- thẻ tháng: người chơi mua bằng 330 Nguyệt Quang (owner 2026-11-21)
const c = await account();
let cb = await rpc(c, "card_buy");
check(!cb.ok && cb.error.includes("card_not_enough"), "không đủ Nguyệt Quang thì không mua được thẻ", JSON.stringify(cb));
let cr = await rpc(c, "card_claim");
check(!cr.ok && cr.error.includes("card_none"), "chưa mua thẻ thì không nhận được");
r = await admin("admin_topup", { code: c.code, pack: "moonlight_990", paid: 210000, ref: ref(), operator: "t" });
check(r.ok && r.data.wallet.moonlight === 990, "nạp 990 Nguyệt Quang", JSON.stringify(r));
cb = await rpc(c, "card_buy");
check(cb.ok && cb.data.card.claims_left === 30 && cb.data.wallet.moonlight === 660, "mua thẻ: -330 Nguyệt Quang, +30 lượt", JSON.stringify(cb));
info = await rpc(c, "topup_info");
check(info.data.card.claims_left === 30 && info.data.card.can_claim === true && info.data.card.next_gems === 30, "thẻ: còn 30 lượt, nhận được, hôm nay +30");
check(info.data.log[0].pack === "card" && info.data.log[0].cost === 330, "lịch sử ghi lần mua thẻ");
cr = await rpc(c, "card_claim");
check(cr.ok && cr.data.gems === 30 && cr.data.bonus === 0 && cr.data.card.claims_left === 29 && cr.data.card.can_claim === false, "nhận thẻ ngày đầu +30", JSON.stringify(cr));
cr = await rpc(c, "card_claim");
check(!cr.ok && cr.error.includes("card_claimed_today"), "một ngày chỉ nhận một lần");
check((await wallet(c)).gems === 30, "ví +30 Ngọc sau khi nhận");
await admin("admin_card_set", { code: c.code, claims_total: 14, last_claim_day: "2000-01-01", operator: "t" });
cr = await rpc(c, "card_claim");
check(cr.ok && cr.data.gems === 530 && cr.data.bonus === 500, "lượt nhận thứ 15: +30 +500", JSON.stringify(cr));
await admin("admin_card_set", { code: c.code, claims_total: 29, last_claim_day: "2000-01-01", operator: "t" });
cr = await rpc(c, "card_claim");
check(cr.ok && cr.data.gems === 530, "lượt nhận thứ 30: +30 +500", JSON.stringify(cr));
check(1900 === 30 * 30 + 2 * 500, "tổng một thẻ 30 ngày = 1900 Ngọc");
cb = await rpc(c, "card_buy");
check(cb.ok && cb.data.card.claims_left === 27 + 30 && cb.data.wallet.moonlight === 330, "mua cộng dồn thẻ thứ hai", JSON.stringify(cb));
await admin("admin_card_set", { code: c.code, claims_left: 160, operator: "t" });
await admin("admin_grant", { code: c.code, changes: { moonlight: 330 }, ref: ref(), operator: "t" });
cb = await rpc(c, "card_buy");
check(!cb.ok && cb.error.includes("card_max"), "thẻ tháng tối đa 180 lượt", JSON.stringify(cb));
check((await wallet(c)).moonlight === 660, "mua bị từ chối không trừ Nguyệt Quang");
const stt = await admin("admin_topup_state", { code: c.code });
check(stt.ok && stt.data.card.claims_left === 160, "QTV xem được trạng thái thẻ", JSON.stringify(stt).slice(0, 160));

// trả lại bảng giá thật (không có giá thẻ)
check((await admin("admin_set_packs", { catalog })).ok, "bảng giá thật vẫn trên máy chủ");
console.log(fails === 0 ? "ĐẠT" : `CÓ ${fails} BƯỚC LỖI`);
process.exit(fails === 0 ? 0 : 1);
