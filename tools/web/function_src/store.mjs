// Kho dữ liệu cho backend web: Netlify Blobs (chạy thật) hoặc bộ nhớ (test / chạy thử máy).
// Giao diện: get(key) -> {data, etag}|null, set(key, data, cond) -> {ok, etag}, del(key), list(prefix) -> [key].
import { getStore } from "@netlify/blobs";

export function memoryStore() {
  const m = new Map();
  let n = 0;
  return {
    kind: "memory",
    async get(key) {
      const r = m.get(key);
      return r ? { data: JSON.parse(r.json), etag: r.etag } : null;
    },
    async set(key, data, cond = {}) {
      const cur = m.get(key);
      if (cond.onlyIfNew && cur) return { ok: false };
      if (cond.onlyIfMatch !== undefined && (!cur || cur.etag !== cond.onlyIfMatch)) return { ok: false };
      const etag = "e" + ++n;
      m.set(key, { json: JSON.stringify(data), etag });
      return { ok: true, etag };
    },
    async del(key) {
      m.delete(key);
    },
    async list(prefix) {
      return [...m.keys()].filter((k) => k.startsWith(prefix)).sort();
    },
  };
}

export function blobsStore(name = "eclipse") {
  const s = getStore({ name, consistency: "strong" });
  return {
    kind: "blobs",
    async get(key) {
      const r = await s.getWithMetadata(key, { type: "json", consistency: "strong" });
      return r ? { data: r.data, etag: r.etag } : null;
    },
    async set(key, data, cond = {}) {
      const opts = {};
      if (cond.onlyIfNew) opts.onlyIfNew = true;
      else if (cond.onlyIfMatch !== undefined) opts.onlyIfMatch = cond.onlyIfMatch;
      const r = await s.setJSON(key, data, opts);
      return { ok: r.modified !== false, etag: r.etag };
    },
    async del(key) {
      await s.delete(key);
    },
    async list(prefix) {
      const out = [];
      for await (const page of s.list({ prefix, paginate: true })) {
        for (const b of page.blobs) out.push(b.key);
      }
      return out.sort();
    },
  };
}
