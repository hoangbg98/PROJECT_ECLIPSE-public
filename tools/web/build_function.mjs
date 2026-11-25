// Dựng backend Netlify: gom module Nakama + luật + bảng giá, bó bằng esbuild thành MỘT file tự đủ
// -> netlify_site/netlify/functions/api.mjs (không cần npm install khi deploy). File này và function_src/{catalog,rules}.json, module_source.mjs là
// bản SINH RA (chứa thông tin nhận tiền + luật chống gian lận): không vào git, dựng lại bằng script này.
// Chạy: cd tools/web && npm install && node build_function.mjs
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { build } from "esbuild";

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(here, "..", "..");
const src = path.join(here, "function_src");
const out = path.join(root, "netlify_site", "netlify", "functions");
fs.mkdirSync(out, { recursive: true });

// Luật chống gian lận = anti_cheat.json + game_rules.json (giống audit.ps1 -SyncRules).
const rules = JSON.parse(fs.readFileSync(path.join(root, "data/config/anti_cheat.json"), "utf8"));
const game = JSON.parse(fs.readFileSync(path.join(root, "server/rules/game_rules.json"), "utf8"));
for (const k of Object.keys(game)) if (k !== "_comment") rules[k] = game[k];
fs.writeFileSync(path.join(src, "rules.json"), JSON.stringify(rules));
// Bảng giá + thông tin nhận tiền (server/private/payment.json, KHÔNG vào git). Thiếu file thì dừng, không bó bản thiếu thông tin.
const payFile = path.join(root, "server/private/payment.json");
if (!fs.existsSync(payFile)) {
  console.error("THIẾU server/private/payment.json (thông tin nhận tiền, không nằm trong git). Chép data/shop/payment.example.json sang đó rồi điền thật.");
  process.exit(2);
}
const catalog = JSON.parse(fs.readFileSync(path.join(root, "data/shop/topup_packs.json"), "utf8"));
catalog.payment = JSON.parse(fs.readFileSync(payFile, "utf8"));
fs.writeFileSync(path.join(src, "catalog.json"), JSON.stringify(catalog, null, 2));
fs.writeFileSync(
  path.join(src, "module_source.mjs"),
  "export default " + JSON.stringify(fs.readFileSync(path.join(root, "server/modules/index.js"), "utf8")) + ";\n",
);

await build({
  entryPoints: [path.join(src, "api.mjs")],
  outfile: path.join(out, "api.mjs"),
  bundle: true,
  platform: "node",
  format: "esm",
  target: "node20",
  banner: { js: "import { createRequire as __cr } from 'node:module'; const require = __cr(import.meta.url);" },
  logLevel: "info",
});
console.log("OK ->", path.relative(root, path.join(out, "api.mjs")));
