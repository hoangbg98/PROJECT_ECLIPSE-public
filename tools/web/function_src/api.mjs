// Netlify Function: API tương thích Nakama (đủ phần game dùng) cho bản web tạm.
//   POST /v2/account/authenticate/google   {token: <Google ID token>}   -> {token, refresh_token, created}
//   POST /v2/account/authenticate/device   (chỉ khi ALLOW_DEVICE_LOGIN=1, để thử không cần Google)
//   POST /v2/account/session/refresh       {token: <refresh_token>}
//   POST /v2/rpc/<id>                      chạy RPC của server/modules/index.js (gacha, save, chống gian lận…)
//   GET  /v2/eclipse/config                {google_client_id, chat: false}
// Biến môi trường: GOOGLE_CLIENT_ID (bắt buộc cho đăng nhập Google), ALLOW_DEVICE_LOGIN, ADMIN_KEY (cho QTV gọi RPC admin_*),
// SERVER_KEY (mặc định eclipse-test-key), SESSION_SECRET (mặc định tự sinh, lưu trong Blobs).
import crypto from "node:crypto";
import { run, loadModule, seedKeys, accKey, objKey, SYSTEM_USER } from "./nk_engine.mjs";
import { blobsStore } from "./store.mjs";
import { makeToken, verifyToken, verifyGoogleIdToken, TOKEN_TTL, REFRESH_TTL } from "./auth.mjs";
import MODULE_SOURCE from "./module_source.mjs";
import RULES from "./rules.json" with { type: "json" };
import CATALOG from "./catalog.json" with { type: "json" };

const mod = loadModule(MODULE_SOURCE);
const SEED = seedKeys(RULES, CATALOG);
const MAX_BODY = 400_000;

const json = (status, obj) =>
  new Response(JSON.stringify(obj), { status, headers: { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" } });
const fail = (status, message) => json(status, { code: status === 401 ? 16 : status === 400 ? 3 : 13, message });

export function createHandler({ store, env = process.env, verifyGoogle = verifyGoogleIdToken } = {}) {
  const getStoreOnce = (() => {
    let s = store;
    return () => (s ??= blobsStore());
  })();

  async function secret(st) {
    if (env.SESSION_SECRET) return env.SESSION_SECRET;
    const key = "sys/secret";
    let r = await st.get(key);
    if (!r) {
      await st.set(key, { v: crypto.randomBytes(32).toString("hex") }, { onlyIfNew: true });
      r = await st.get(key);
    }
    return r.data.v;
  }

  const serverKeyOk = (req) => {
    const h = req.headers.get("authorization") || "";
    if (!h.startsWith("Basic ")) return false;
    const given = Buffer.from(h.slice(6), "base64").toString("utf8").replace(/:$/, "");
    return given === (env.SERVER_KEY || "eclipse-test-key");
  };

  const sessionFor = async (st, userId, username, created) => {
    const sec = await secret(st);
    return {
      token: makeToken(sec, { uid: userId, usn: username }, TOKEN_TTL),
      refresh_token: makeToken(sec, { uid: userId, usn: username, rt: 1 }, REFRESH_TTL),
      created,
    };
  };

  const cleanName = (s) => String(s || "").replace(/[^A-Za-z0-9_]/g, "").slice(0, 16);

  // Tìm / tạo tài khoản theo khóa ngoài (google:<sub> hoặc device:<id>). Trả về {userId, username, created}.
  async function findOrCreate(st, link, hint) {
    const lk = `link/${link}`;
    const found = await st.get(lk);
    if (found) {
      const acc = await st.get(accKey(found.data.user_id));
      return { userId: found.data.user_id, username: acc.data.user.username, created: false };
    }
    const userId = crypto.randomUUID();
    let base = cleanName(hint.username) || "player";
    if (base.length < 3) base = (base + "player").slice(0, 8);
    let username = "";
    for (let i = 0; i < 30; i++) {
      const cand = i === 0 ? base : base.slice(0, 20 - 4) + String(Math.floor(1000 + Math.random() * 9000));
      const r = await st.set(`uname/${cand.toLowerCase()}`, { user_id: userId }, { onlyIfNew: true });
      if (r.ok) {
        username = cand;
        break;
      }
    }
    if (!username) throw new Error("không đặt được tên đăng nhập");
    const now = Math.floor(Date.now() / 1000);
    await st.set(accKey(userId), {
      user: { username, displayName: hint.displayName || "", metadata: {}, createTime: now },
      wallet: {},
      email: hint.email || "",
    });
    const claimed = await st.set(lk, { user_id: userId }, { onlyIfNew: true });
    if (!claimed.ok) {
      // hai yêu cầu đăng nhập cùng lúc: dùng tài khoản của yêu cầu thắng
      await st.del(accKey(userId));
      await st.del(`uname/${username.toLowerCase()}`);
      return findOrCreate(st, link, hint);
    }
    // cấp mã người chơi (hook sau đăng nhập của module)
    await run(st, (nk) => mod.hooks.registerAfterAuthenticateDevice({ userId, username }, console, nk, {}, {}), { seed: SEED });
    return { userId, username, created: true };
  }

  async function authContext(req, st) {
    const h = req.headers.get("authorization") || "";
    if (!h.startsWith("Bearer ")) return null;
    const c = verifyToken(await secret(st), h.slice(7));
    return c ? { userId: c.uid, username: c.usn } : null;
  }

  return async function handler(req) {
    const url = new URL(req.url);
    const path = url.pathname.replace(/^\/\.netlify\/functions\/api/, "");
    const st = getStoreOnce();
    try {
      if (req.method === "GET" && path === "/v2/eclipse/config") {
        return json(200, { google_client_id: env.GOOGLE_CLIENT_ID || "", chat: false, device_login: env.ALLOW_DEVICE_LOGIN === "1" });
      }
      if (req.method !== "POST" && req.method !== "GET" && req.method !== "DELETE") return fail(405, "method not allowed");

      let body = "";
      if (req.method === "POST") {
        body = await req.text();
        if (body.length > MAX_BODY) return fail(400, "payload quá lớn");
      }

      if (req.method === "POST" && path === "/v2/account/authenticate/google") {
        if (!serverKeyOk(req)) return fail(401, "Server key invalid");
        let b;
        try {
          b = JSON.parse(body);
        } catch {
          return fail(400, "JSON lỗi");
        }
        const g = await verifyGoogle(b.token, env.GOOGLE_CLIENT_ID);
        const who = await findOrCreate(st, `google:${g.sub}`, {
          username: (g.email.split("@")[0] || g.name),
          displayName: g.name,
          email: g.email,
        });
        return json(200, await sessionFor(st, who.userId, who.username, who.created));
      }

      if (req.method === "POST" && path === "/v2/account/authenticate/device") {
        if (env.ALLOW_DEVICE_LOGIN !== "1") return fail(401, "Đăng nhập thiết bị đã tắt");
        if (!serverKeyOk(req)) return fail(401, "Server key invalid");
        const id = String(JSON.parse(body || "{}").id || "");
        if (id.length < 10 || id.length > 128) return fail(400, "device id không hợp lệ");
        const who = await findOrCreate(st, `device:${id}`, { username: "dev" + id.replace(/[^A-Za-z0-9]/g, "").slice(0, 8) });
        return json(200, await sessionFor(st, who.userId, who.username, who.created));
      }

      if (req.method === "POST" && path === "/v2/account/session/refresh") {
        if (!serverKeyOk(req)) return fail(401, "Server key invalid");
        const c = verifyToken(await secret(st), JSON.parse(body || "{}").token, true);
        if (!c) return fail(401, "Refresh token invalid or expired");
        return json(200, await sessionFor(st, c.uid, c.usn, false));
      }

      const rpcMatch = path.match(/^\/v2\/rpc\/([A-Za-z0-9_]+)$/);
      if (rpcMatch) {
        const id = rpcMatch[1];
        const fn = mod.rpcs[id];
        if (!fn) return fail(404, "RPC không tồn tại");
        let ctx;
        const httpKey = url.searchParams.get("http_key");
        if (httpKey) {
          if (!env.ADMIN_KEY || httpKey !== env.ADMIN_KEY) return fail(401, "http_key sai");
          ctx = { userId: "", username: "" };
        } else {
          ctx = await authContext(req, st);
          if (!ctx) return fail(401, "Auth token invalid or expired");
        }
        let payload = "";
        if (req.method === "POST") {
          payload = body ? JSON.parse(body) : "";
          if (typeof payload !== "string") return fail(400, "payload phải là chuỗi JSON");
        }
        const out = await run(
          st,
          (nk) => fn({ ...ctx, vars: {}, executionMode: "RPC" }, console, nk, payload),
          { seed: SEED, prime: ctx.userId ? [accKey(ctx.userId)] : [] },
        );
        return json(200, { payload: out || "" });
      }

      // Bạn bè / thông báo / lịch sử chat: bản web không có chat → trả rỗng cho khỏi lỗi.
      if (path === "/v2/friend") return json(200, { friends: [] });
      if (path === "/v2/notification") return json(200, { notifications: [] });
      if (path.startsWith("/v2/channel/")) return json(200, { messages: [] });
      return fail(404, "Không có đường dẫn " + path);
    } catch (e) {
      const msg = e && e.message ? e.message : String(e);
      console.error("api lỗi", path, msg);
      // lỗi từ module (throw Error) là lỗi nghiệp vụ → 500 theo kiểu Nakama, game đọc "message"
      return json(500, { code: 13, message: msg });
    }
  };
}

export default async (req) => createHandler()(req);
export const config = { path: ["/v2/*"] };
