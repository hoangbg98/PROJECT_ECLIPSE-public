// Tự kiểm backend web (không cần mạng, không cần Netlify): kho bộ nhớ + Google giả.
// Chạy: cd tools/web && node function_src/selftest.mjs
import crypto from "node:crypto";
import { createHandler } from "./api.mjs";
import { memoryStore } from "./store.mjs";
import { verifyGoogleIdToken, resetGoogleKeyCache } from "./auth.mjs";

let fails = 0;
const check = (ok, what, extra = "") => {
  console.log((ok ? "  ĐẠT  " : "  LỖI  ") + what + (ok ? "" : "   " + extra));
  if (!ok) fails++;
};
const env = { GOOGLE_CLIENT_ID: "test-client.apps.googleusercontent.com", ADMIN_KEY: "adm" };
const handler = createHandler({
  store: memoryStore(),
  env,
  verifyGoogle: async (tok) => {
    if (!tok.startsWith("good:")) throw new Error("token Google không hợp lệ");
    return { sub: tok.slice(5), email: tok.slice(5) + "@gmail.com", name: "Người Chơi", picture: "" };
  },
});
const basic = "Basic " + Buffer.from("eclipse-test-key:").toString("base64");
async function call(method, path, { auth, body } = {}) {
  const r = await handler(new Request("https://x.test" + path, { method, headers: { authorization: auth || "", "content-type": "application/json" }, body }));
  const t = await r.text();
  return { status: r.status, body: JSON.parse(t) };
}
const rpc = async (u, id, payload = {}) => {
  const r = await call("POST", "/v2/rpc/" + id, { auth: "Bearer " + u.token, body: JSON.stringify(JSON.stringify(payload)) });
  return r.status === 200 ? { ok: true, data: JSON.parse(r.body.payload) } : { ok: false, error: r.body.message, status: r.status };
};
const login = async (sub) => {
  const r = await call("POST", "/v2/account/authenticate/google", { auth: basic, body: JSON.stringify({ token: "good:" + sub }) });
  return { ...r.body, status: r.status };
};

const cfg = await call("GET", "/v2/eclipse/config");
check(cfg.body.google_client_id === env.GOOGLE_CLIENT_ID, "config trả google_client_id");

check((await call("POST", "/v2/account/authenticate/google", { auth: basic, body: JSON.stringify({ token: "bad" }) })).status === 500, "token Google sai bị từ chối");
check((await call("POST", "/v2/account/authenticate/google", { auth: "Basic eHg6", body: "{}" })).status === 401, "sai server key bị từ chối");
check((await call("POST", "/v2/account/authenticate/device?create=true", { auth: basic, body: JSON.stringify({ id: "abcdefghij1234" }) })).status === 401, "đăng nhập thiết bị tắt mặc định");

const a = await login("alice");
check(a.status === 200 && a.created === true && a.token, "đăng nhập Google lần đầu tạo tài khoản");
const a2 = await login("alice");
check(a2.created === false, "đăng nhập lần hai dùng lại tài khoản");
const refreshed = await call("POST", "/v2/account/session/refresh", { auth: basic, body: JSON.stringify({ token: a.refresh_token }) });
check(refreshed.status === 200 && refreshed.body.token, "refresh token đổi được phiên");
check((await call("POST", "/v2/account/session/refresh", { auth: basic, body: JSON.stringify({ token: a.token }) })).status === 401, "access token không dùng làm refresh được");
check((await call("POST", "/v2/rpc/eclipse_profile", { auth: "Bearer " + a.token + "x", body: '""' })).status === 401, "token giả bị từ chối");

const ua = { token: a.token, version: "" };
const prof = await rpc(ua, "eclipse_profile");
check(prof.ok && /^\d{8}$/.test(prof.data.code), "có mã người chơi 8 số", JSON.stringify(prof));
const bob = { token: (await login("bob")).token, version: "" };
const profB = await rpc(bob, "eclipse_profile");
check(profB.ok && profB.data.code !== prof.data.code && profB.data.username !== prof.data.username, "hai tài khoản có mã và tên khác nhau");

// --- Cloud save + chống gian lận ---
const baseData = () => ({
  characters: { char_fire_01: { level: 1, exp: 0, equipment: {}, skills: {}, fragments: 0, promotion: 0 } },
  currencies: { gold: 0, gems: 0 }, account: { level: 1, exp: 0, name: "" },
  gacha: { pity: {}, guarantee: {}, history: [], starter_used: [] }, online: { applied: { gems: 0 } },
});
const envelope = (data, forge = false) => {
  const body = JSON.stringify(data);
  return { schema_version: 6, saved_at: "2026-11-21T00:00:00", checksum: forge ? "0".repeat(64) : crypto.createHash("sha256").update(body, "utf8").digest("hex"), data: body };
};
const put = async (u, data, forge = false) => {
  const r = await rpc(u, "save_put", { envelope: envelope(data, forge), base_version: u.version });
  if (r.ok) u.version = r.data.version;
  return r;
};
check((await rpc(ua, "save_get")).data.exists === false, "tài khoản mới chưa có save");
check((await put(ua, baseData())).ok, "save hợp lệ được nhận");
const got = await rpc(ua, "save_get");
check(got.data.exists && got.data.version === ua.version, "save_get trả đúng bản vừa ghi");
const forged = await put(ua, baseData(), true);
check(!forged.ok && /save_rejected/.test(forged.error), "checksum giả bị từ chối", JSON.stringify(forged));
const rich = baseData();
rich.currencies.gems = 99999999999;
const r1 = await put(ua, rich);
check(!r1.ok && /save_rejected/.test(r1.error), "tiền vượt trần bị từ chối", JSON.stringify(r1));
const hacked = baseData();
hacked.characters.char_fire_01.level = 9999;
const r2 = await put(ua, hacked);
check(!r2.ok && /save_rejected/.test(r2.error), "cấp nhân vật vượt trần bị từ chối", JSON.stringify(r2));
const stale = { token: a.token, version: "" };
const r3 = await put(stale, baseData());
check(!r3.ok && /save_conflict/.test(r3.error), "ghi bằng version cũ báo save_conflict", JSON.stringify(r3));
check((await call("POST", "/v2/rpc/admin_cheat_flags", { auth: "Bearer " + a.token, body: '"{}"' })).status === 500, "người chơi không gọi được RPC QTV");
const flags = await call("POST", "/v2/rpc/admin_cheat_flags?http_key=adm", { body: '"{}"' });
const flagList = JSON.parse(flags.body.payload || "{}").flags || [];
check(flags.status === 200 && flagList.length >= 1, "QTV (http_key) thấy tài khoản bị đánh dấu", JSON.stringify(flags.body));
check((await call("POST", "/v2/rpc/admin_cheat_flags?http_key=sai", { body: '"{}"' })).status === 401, "http_key sai bị từ chối");

// --- Gacha chạy trên máy chủ ---
const gacha = await rpc(ua, "gacha_pull", { banner: "banner_nope", count: 1, base_version: ua.version });
check(!gacha.ok && /invalid_banner/.test(gacha.error), "banner lạ bị từ chối", JSON.stringify(gacha));
const rules = (await import("./rules.json", { with: { type: "json" } })).default;
const banner = Object.keys(rules.gacha_banners || {}).find((k) => !rules.gacha_banners[k].ticket_item && rules.gacha_banners[k].cost_single > 0);
if (banner) {
  const b = rules.gacha_banners[banner];
  const d = baseData();
  d.currencies[b.cost_currency] = b.cost_single * 3;
  const u2 = { token: (await login("carol")).token, version: "" };
  await rpc(u2, "eclipse_profile");
  check((await put(u2, d)).ok, "carol: save có tiền gacha (trong trần)", "");
  const pull = await rpc(u2, "gacha_pull", { banner, count: 1, base_version: u2.version });
  check(pull.ok && pull.data.results.length === 1, "quay gacha trên máy chủ ra 1 kết quả", JSON.stringify(pull));
  if (pull.ok) {
    const after = JSON.parse(pull.data.envelope.data);
    check(after.currencies[b.cost_currency] === b.cost_single * 2, "máy chủ trừ đúng tiền gacha");
  }
}

// --- Xác minh chữ ký Google thật (khóa RSA tự sinh, JWKS giả) ---
const { publicKey, privateKey } = crypto.generateKeyPairSync("rsa", { modulusLength: 2048 });
const jwk = { ...publicKey.export({ format: "jwk" }), kid: "k1", alg: "RS256", use: "sig" };
const fakeFetch = async () => ({ ok: true, json: async () => ({ keys: [jwk] }) });
const mkJwt = (claims, key = privateKey) => {
  const h = Buffer.from(JSON.stringify({ alg: "RS256", kid: "k1" })).toString("base64url");
  const p = Buffer.from(JSON.stringify(claims)).toString("base64url");
  const s = crypto.sign("RSA-SHA256", Buffer.from(h + "." + p), key).toString("base64url");
  return `${h}.${p}.${s}`;
};
const okClaims = { iss: "https://accounts.google.com", aud: "cid", sub: "123", email: "a@b.c", exp: Math.floor(Date.now() / 1000) + 600 };
resetGoogleKeyCache();
check((await verifyGoogleIdToken(mkJwt(okClaims), "cid", fakeFetch)).sub === "123", "ID token Google hợp lệ được chấp nhận");
const bad = async (claims, key, cid = "cid") => verifyGoogleIdToken(mkJwt(claims, key), cid, fakeFetch).then(() => false, () => true);
check(await bad({ ...okClaims, aud: "khac" }), "sai audience bị từ chối");
check(await bad({ ...okClaims, iss: "evil.com" }), "sai issuer bị từ chối");
check(await bad({ ...okClaims, exp: 1 }), "token hết hạn bị từ chối");
check(await bad(okClaims, crypto.generateKeyPairSync("rsa", { modulusLength: 2048 }).privateKey), "chữ ký sai bị từ chối");

console.log(fails === 0 ? "\nTẤT CẢ ĐẠT" : `\n${fails} LỖI`);
process.exit(fails === 0 ? 0 : 1);
