// Chạy module Nakama (server/modules/index.js, viết cho runtime JS ĐỒNG BỘ của Nakama) trên kho dữ liệu BẤT ĐỒNG BỘ.
// Cách làm: mỗi lần gọi chạy hàm module với một "nk" giả đọc từ bộ đệm; thiếu dữ liệu thì ném NeedData, engine nạp
// dữ liệu đó rồi chạy lại từ đầu. Ghi chỉ được gom lại (overlay) và chỉ đẩy lên kho sau khi hàm chạy xong không lỗi
// (có điều kiện etag nên hai yêu cầu đồng thời không ghi đè nhau). Hàm module phải không có tác dụng phụ ngoài nk.
import crypto from "node:crypto";

export const SYSTEM_USER = "00000000-0000-0000-0000-000000000000";

// PRNG có hạt giống: mỗi lần chạy lại hàm module phải sinh lại đúng các khóa ngẫu nhiên đó (vd mã người chơi),
// nếu không việc "nạp dữ liệu rồi chạy lại" không bao giờ hội tụ.
function mulberry32(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}
let currentRng = Math.random;
const sandboxMath = Object.create(Math, { random: { value: () => currentRng() } });

export const objKey = (collection, userId, key) => `s/${collection}/${userId}/${encodeURIComponent(key)}`;
export const accKey = (userId) => `a/${userId}`;

function md5(v) {
  return crypto.createHash("md5").update(JSON.stringify(v)).digest("hex");
}

function fmt(msg, args) {
  let i = 0;
  return String(msg).replace(/%[sdv]/g, () => (i < args.length ? String(args[i++]) : ""));
}

export const consoleLogger = {
  info: (m, ...a) => console.log("[info]", fmt(m, a)),
  warn: (m, ...a) => console.warn("[warn]", fmt(m, a)),
  error: (m, ...a) => console.error("[error]", fmt(m, a)),
  debug: () => {},
};

/** Tải module: trả về {rpcs, hooks}. */
export function loadModule(source) {
  const init = new Function("Math", source + "\n;return InitModule;")(sandboxMath);
  const rpcs = {};
  const hooks = {};
  const initializer = new Proxy(
    {},
    {
      get(_t, name) {
        if (name === "registerRpc") return (id, fn) => void (rpcs[id] = fn);
        return (fn) => void (hooks[String(name)] = fn);
      },
    },
  );
  init({}, consoleLogger, makeNk(new Tx(null)), initializer);
  return { rpcs, hooks };
}

class Tx {
  constructor(store, onNeed) {
    this.store = store;
    this.needs = new Map(); // "get:key" | "list:prefix" -> {kind, key}: dữ liệu còn thiếu ở lần chạy này
    this.cache = new Map(); // key -> {data, etag} | null
    this.lists = new Map(); // prefix -> [key]
    this.overlay = new Map(); // key -> {data} | {del:true}
    this.ops = []; // thứ tự ghi
    this.seed = {}; // key -> data mặc định cho khóa chưa có (luật, bảng giá)
  }

  read(key) {
    if (this.overlay.has(key)) {
      const o = this.overlay.get(key);
      return o.del ? null : { data: o.data, etag: this.cache.get(key)?.etag };
    }
    if (!this.cache.has(key)) {
      if (this.store) this.needs.set("get:" + key, { kind: "get", key });
      return null; // trả tạm; lần chạy này sẽ bị bỏ và chạy lại sau khi nạp
    }
    const c = this.cache.get(key);
    if (!c && this.seed[key] !== undefined) return { data: this.seed[key], etag: undefined, seeded: true };
    return c;
  }

  write(key, data) {
    this.overlay.set(key, { data });
    this.ops.push({ key, data });
  }

  remove(key) {
    this.overlay.set(key, { del: true });
    this.ops.push({ key, del: true });
  }

  list(prefix) {
    if (!this.lists.has(prefix)) {
      if (this.store) this.needs.set("list:" + prefix, { kind: "list", key: prefix });
      return [];
    }
    const keys = new Set(this.lists.get(prefix));
    for (const [k, o] of this.overlay) if (k.startsWith(prefix)) o.del ? keys.delete(k) : keys.add(k);
    return [...keys].sort();
  }

  async loadAll() {
    const needs = [...this.needs.values()];
    this.needs = new Map();
    for (const n of needs.filter((x) => x.kind === "get")) await this.load(n);
    for (const n of needs.filter((x) => x.kind === "list")) await this.load(n);
  }

  async load(need) {
    if (need.kind === "get") {
      if (this.cache.has(need.key)) return;
      this.cache.set(need.key, await this.store.get(need.key));
    } else {
      const keys = await this.store.list(need.key);
      this.lists.set(need.key, keys);
      await Promise.all(keys.filter((k) => !this.cache.has(k)).map(async (k) => this.cache.set(k, await this.store.get(k))));
    }
  }

  async commit() {
    const done = new Set();
    for (const op of this.ops) {
      if (done.has(op.key)) continue;
      done.add(op.key);
      const last = this.overlay.get(op.key);
      if (last.del) {
        await this.store.del(op.key);
        continue;
      }
      const base = this.cache.get(op.key);
      const cond = base ? { onlyIfMatch: base.etag } : { onlyIfNew: true };
      const r = await this.store.set(op.key, last.data, cond);
      if (!r.ok) throw new Error("save_conflict");
    }
  }
}

function makeNk(tx, rng = Math.random) {
  const now = () => Math.floor(Date.now() / 1000);
  const rowOf = (collection, userId, key, rec) => ({
    collection,
    key,
    userId,
    value: rec.value,
    version: rec.version,
    permissionRead: rec.pr,
    permissionWrite: rec.pw,
    createTime: rec.createTime,
    updateTime: rec.updateTime,
  });
  const account = (userId) => {
    const r = tx.read(accKey(userId));
    if (!r) throw new Error("user account not found");
    return r;
  };
  return {
    sha256Hash: (s) => crypto.createHash("sha256").update(String(s)).digest("hex"),
    uuidv4: () => {
      const h = Array.from({ length: 32 }, () => Math.floor(rng() * 16).toString(16)).join("");
      return `${h.slice(0, 8)}-${h.slice(8, 12)}-4${h.slice(13, 16)}-a${h.slice(17, 20)}-${h.slice(20)}`;
    },
    storageRead(reqs) {
      const out = [];
      for (const q of reqs) {
        const r = tx.read(objKey(q.collection, q.userId || SYSTEM_USER, q.key));
        if (r) out.push(rowOf(q.collection, q.userId || SYSTEM_USER, q.key, r.data));
      }
      return out;
    },
    storageWrite(writes) {
      const acks = [];
      for (const w of writes) {
        const uid = w.userId || SYSTEM_USER;
        const key = objKey(w.collection, uid, w.key);
        const cur = tx.read(key);
        if (w.version === "*" && cur) throw new Error("storage write rejected - version check failed");
        if (w.version && w.version !== "*" && (!cur || cur.data.version !== w.version)) {
          throw new Error("storage write rejected - version check failed");
        }
        const rec = {
          value: w.value,
          version: md5(w.value),
          pr: w.permissionRead ?? 1,
          pw: w.permissionWrite ?? 1,
          createTime: cur && !cur.seeded ? cur.data.createTime : now(),
          updateTime: now(),
        };
        tx.write(key, rec);
        acks.push({ collection: w.collection, key: w.key, userId: uid, version: rec.version });
      }
      return acks;
    },
    storageDelete(dels) {
      for (const d of dels) tx.remove(objKey(d.collection, d.userId || SYSTEM_USER, d.key));
    },
    storageList(userId, collection, limit, cursor) {
      const prefix = `s/${collection}/${userId || SYSTEM_USER}/`;
      const keys = tx.list(prefix);
      const from = Number(cursor) || 0;
      const slice = keys.slice(from, from + (limit || 100));
      const objects = slice.map((k) => {
        const rec = tx.read(k).data;
        return rowOf(collection, userId || SYSTEM_USER, decodeURIComponent(k.slice(prefix.length)), rec);
      });
      return { objects, cursor: from + slice.length < keys.length ? String(from + slice.length) : "" };
    },
    accountGetId(userId) {
      const a = account(userId).data;
      return { user: { ...a.user, userId: userId, id: userId }, wallet: JSON.stringify(a.wallet || {}), email: a.email || "" };
    },
    accountsGetId(ids) {
      return ids.map((id) => this.accountGetId(id));
    },
    accountUpdateId(userId, username, displayName, _tz, _loc, _lang, _avatar, metadata) {
      const a = account(userId).data;
      if (username) a.user.username = username;
      if (displayName) a.user.displayName = displayName;
      if (metadata) a.user.metadata = metadata;
      tx.write(accKey(userId), a);
    },
    walletUpdate(userId, changes) {
      const a = account(userId).data;
      const before = { ...(a.wallet || {}) };
      const after = { ...before };
      for (const [k, v] of Object.entries(changes)) {
        after[k] = (after[k] || 0) + v;
        if (after[k] < 0) throw new Error("wallet update rejected - wallet would go negative");
      }
      a.wallet = after;
      tx.write(accKey(userId), a);
      return { updated: after, previous: before };
    },
    // Chat / bạn bè không có trên bản web (không có websocket): trả rỗng.
    friendsList: () => ({ friends: [], cursor: "" }),
    notificationSend: () => {},
  };
}

/**
 * Chạy fn(nk) với kho `store`. `seed`: giá trị mặc định cho khóa chưa có {key: data}.
 * `ensure`: hàm async chạy trước (tạo tài khoản…) trả về dữ liệu tùy ý — truyền qua `prepare` thay vì dùng ở đây.
 */
export async function run(store, fn, { seed = {}, prime = [] } = {}) {
  const tx = new Tx(store);
  tx.seed = seed;
  for (const k of prime) tx.cache.set(k, await store.get(k));
  const rngSeed = crypto.randomBytes(4).readUInt32LE(0);
  for (let attempt = 0; attempt < 40; attempt++) {
    tx.ops = [];
    tx.overlay = new Map();
    tx.needs = new Map();
    currentRng = mulberry32(rngSeed);
    let result;
    let error = null;
    try {
      result = fn(makeNk(tx, currentRng));
    } catch (e) {
      error = e;
    }
    if (tx.needs.size > 0) {
      await tx.loadAll(); // thiếu dữ liệu: bỏ kết quả / lỗi của lần này (có thể do dữ liệu tạm), chạy lại
      continue;
    }
    await tx.commit(); // như Nakama: ghi trước khi ném lỗi vẫn được giữ (vd đánh dấu gian lận trước khi từ chối save)
    if (error) throw error;
    return result;
  }
  throw new Error("quá nhiều lần nạp dữ liệu");
}

export function seedKeys(rules, catalog) {
  const row = (v) => ({ value: v, version: md5(v), pr: 0, pw: 0, createTime: Math.floor(Date.now() / 1000), updateTime: Math.floor(Date.now() / 1000) });
  const out = {};
  if (rules) out[objKey("server_rules", SYSTEM_USER, "main")] = row(rules);
  if (catalog) out[objKey("shop_catalog", SYSTEM_USER, "main")] = row(catalog);
  return out;
}
