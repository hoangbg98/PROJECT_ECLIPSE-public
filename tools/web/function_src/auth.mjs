// Phiên đăng nhập (JWT HS256, cùng dạng token Nakama: có uid, usn, exp) và xác minh Google ID token.
import crypto from "node:crypto";

const b64u = (b) => Buffer.from(b).toString("base64url");
const sign = (secret, data) => crypto.createHmac("sha256", secret).update(data).digest("base64url");

export const TOKEN_TTL = 2 * 3600;
export const REFRESH_TTL = 30 * 24 * 3600;

export function makeToken(secret, claims, ttl) {
  const now = Math.floor(Date.now() / 1000);
  const head = b64u(JSON.stringify({ alg: "HS256", typ: "JWT" }));
  const body = b64u(JSON.stringify({ ...claims, iat: now, exp: now + ttl }));
  return `${head}.${body}.${sign(secret, head + "." + body)}`;
}

/** Trả về claims nếu token hợp lệ và chưa hết hạn, ngược lại null. */
export function verifyToken(secret, token, wantRefresh = false) {
  const parts = String(token || "").split(".");
  if (parts.length !== 3) return null;
  const expect = sign(secret, parts[0] + "." + parts[1]);
  const a = Buffer.from(parts[2]);
  const b = Buffer.from(expect);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return null;
  let c;
  try {
    c = JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8"));
  } catch {
    return null;
  }
  if (!c.uid || !(c.exp > Date.now() / 1000)) return null;
  if (!!c.rt !== wantRefresh) return null;
  return c;
}

let jwksCache = { at: 0, keys: [] };

async function googleKeys(fetchFn) {
  if (Date.now() - jwksCache.at < 3600e3 && jwksCache.keys.length) return jwksCache.keys;
  const r = await fetchFn("https://www.googleapis.com/oauth2/v3/certs");
  if (!r.ok) throw new Error("không tải được khóa Google");
  jwksCache = { at: Date.now(), keys: (await r.json()).keys || [] };
  return jwksCache.keys;
}

/** Xác minh Google ID token (RS256). Trả về {sub, email, name, picture}. Ném Error nếu sai. */
export async function verifyGoogleIdToken(idToken, clientId, fetchFn = fetch) {
  if (!clientId) throw new Error("máy chủ chưa cấu hình GOOGLE_CLIENT_ID");
  const parts = String(idToken || "").split(".");
  if (parts.length !== 3) throw new Error("token Google không hợp lệ");
  let head, claims;
  try {
    head = JSON.parse(Buffer.from(parts[0], "base64url").toString("utf8"));
    claims = JSON.parse(Buffer.from(parts[1], "base64url").toString("utf8"));
  } catch {
    throw new Error("token Google không hợp lệ");
  }
  if (head.alg !== "RS256") throw new Error("token Google không hợp lệ");
  const keys = await googleKeys(fetchFn);
  const jwk = keys.find((k) => k.kid === head.kid);
  if (!jwk) throw new Error("token Google không hợp lệ (kid)");
  const ok = crypto.verify(
    "RSA-SHA256",
    Buffer.from(parts[0] + "." + parts[1]),
    crypto.createPublicKey({ key: jwk, format: "jwk" }),
    Buffer.from(parts[2], "base64url"),
  );
  if (!ok) throw new Error("chữ ký token Google sai");
  if (claims.iss !== "accounts.google.com" && claims.iss !== "https://accounts.google.com") throw new Error("token Google sai nơi cấp");
  if (claims.aud !== clientId) throw new Error("token Google không dành cho game này");
  if (!(claims.exp > Date.now() / 1000)) throw new Error("token Google đã hết hạn");
  if (!claims.sub) throw new Error("token Google thiếu sub");
  return { sub: String(claims.sub), email: String(claims.email || ""), name: String(claims.name || ""), picture: String(claims.picture || "") };
}

export function resetGoogleKeyCache() {
  jwksCache = { at: 0, keys: [] };
}
