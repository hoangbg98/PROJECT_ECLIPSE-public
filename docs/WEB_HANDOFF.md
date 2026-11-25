# WEB_HANDOFF — bàn giao tiếp tục bản web Netlify (dành cho phiên Claude khác)

Đọc file này TRƯỚC, rồi `AGENTS.md`, rồi mục cuối `docs/DEVELOPMENT_LOG.md`. Trả lời owner bằng tiếng Việt.
Nhánh làm việc: `claude/vigilant-curie-w1qj4n` (repo `<owner>/PROJECT_ECLIPSE`). Chưa tạo PR (owner chưa yêu cầu). Commit mới nhất: "Web build: lossy texture copy…".

**Cập nhật 2026-11-25:** đã gộp nhánh này vào `main` và **đã deploy**: https://project-eclipse-game.netlify.app (Production = Public,
`GOOGLE_CLIENT_ID` đã đặt, Test users của Google có email owner). Owner đăng nhập Google và vào Hub thành công. Mục 3.1 (deploy) xong;
còn 3.2 (chơi qua màn, F5, gacha), 3.3 (chất lượng ảnh lossy), 3.4 (âm thanh). Dựng lại file game trên Windows không cần `npm install`
(trên máy owner file `netlify/functions/api.mjs` còn sẵn; máy mới phải `cd tools/web && npm install && node build_function.mjs`, cần `server/private/payment.json`; bó lại khi đổi `server/modules/index.js`, luật chống gian lận hoặc bảng giá): chạy
`lossy_copy.py` → Godot `--import` → `--export-release "Web"` trên bản sao → chép `index.*` vào `netlify_site/` → `npx netlify-cli deploy --prod --dir=. --functions=netlify/functions`.
Xem `docs/WEB_DEPLOY.md` mục "Cài đặt Netlify bắt buộc" (Visibility phải Public).

## 1. Mục tiêu của owner
Chơi thử tạm game trên trình duyệt: host bằng **Netlify**, đăng nhập **Google**, chống cheat đơn giản. Chỉ là bản thử, không phải phát hành.

## 2. Đã xong (đã commit + push)
| Phần | Ở đâu | Trạng thái |
|---|---|---|
| Backend Netlify Function tương thích Nakama (chạy nguyên `server/modules/index.js` qua shim `nk`, lưu Netlify Blobs) | `tools/web/function_src/` (`api.mjs`, `nk_engine.mjs`, `store.mjs`, `auth.mjs`); bản bó 1 file: `netlify_site/netlify/functions/api.mjs` | TESTED: `selftest.mjs` 31/31 |
| Đăng nhập Google (server xác minh ID token RS256: chữ ký, iss, aud, exp) | `auth.mjs`, `api.mjs` (`/v2/account/authenticate/google`) | TESTED bằng khóa RSA giả; **chưa thử Google thật** |
| Client: `GoogleSignIn` (JavaScriptBridge), `OnlineService.login_google`, `fetch_server_config`, `NakamaApi.authenticate_google/server_config`, `LoginScreen.google_mode`, `OnlineConfig.web_origin` | `scripts/online/`, `scripts/ui/login_screen.gd`, `hub_home_panel.gd` (ẩn Chat khi `chat_enabled=false`) | GdUnit online+ui 251/251 |
| Nút Google = DOM overlay (GIS), bootstrap engine | `tools/web/shell.html` (đặt ở 62% chiều cao trang) | **chưa xem bằng mắt** |
| Chống cheat | module có sẵn M9-2b + gacha server (`server/modules/index.js`), luật `data/config/anti_cheat.json` + `server/rules/game_rules.json` bó vào function | TESTED trong selftest |
| Export Web + giảm dung lượng | preset `Web` trong `export_presets.cfg`; `tools/web/lossy_copy.py`, `tools/web/build_web.sh`; `netlify_site/index.pck` 94 MB | TESTED export; chất lượng ảnh lossy chưa xem |
| Tài liệu | `docs/WEB_DEPLOY.md` (deploy + biến môi trường), mục cuối `DEVELOPMENT_LOG.md` | xong |

## 3. Việc còn lại (theo thứ tự)
1. **Deploy thật** (cần owner cấp Google Client ID + đăng nhập Netlify — agent không có):
   - Owner tạo OAuth Client ID loại Web, Authorized JavaScript origins = `https://<site>.netlify.app` (xem `docs/WEB_DEPLOY.md`).
   - Trong `netlify_site/`: `npx netlify-cli env:set GOOGLE_CLIENT_ID <id>` rồi `npx netlify-cli deploy --prod --dir=. --functions=netlify/functions`. **Không kéo-thả** (pck 94 MB, wasm 38 MB; khuyến nghị Netlify ≤10 MB/file). Nếu CLI từ chối file lớn: thử `--no-build`/chia nhỏ không khả thi với .pck → báo owner, cân nhắc host file tĩnh nơi khác (R2/GitHub Releases) và đặt `executable`/`mainPack` URL trong `shell.html`.
2. **Thử bằng trình duyệt thật** sau deploy (hoặc Playwright có sẵn ở `/opt/pw-browsers`, `chromium.launch()` không cần tùy chọn, dùng swiftshader/WebGL):
   - Màn Đăng nhập hiện chữ hướng dẫn, nút Google hiện **không đè lên chữ** (chỉnh `top: 62%` trong `shell.html#google-slot` và khoảng trống `space` trong `LoginScreen._apply_google_mode` nếu lệch).
   - Bấm Google → vào Title → Hub (không có biểu tượng Chat) → chơi 1-1 → F5 vẫn còn save (`user://` = IndexedDB; refresh token lưu ở `user://online_session.cfg`).
   - Nhận gacha, kiểm tra `POST /v2/rpc/admin_cheat_flags?http_key=<ADMIN_KEY>` body `"{}"` trả danh sách rỗng với người chơi sạch.
3. **Xem chất lượng ảnh lossy** (WebP q0.9): kiểm mép trong suốt sprite nhân vật/kẻ địch, nền, ảnh truyện. Nhòe → bỏ `assets/characters/` (và/hoặc `enemies`) khỏi `LOSSY_DIRS` trong `tools/web/lossy_copy.py`, chạy lại build (pck sẽ ~+40 MB), hoặc tăng chất lượng (đối số thứ 2).
4. Âm thanh Web: kiểm nhạc/SFX chạy (trình duyệt chặn audio tới khi có cú bấm — đăng nhập Google đã là cú bấm).
5. (Tùy chọn) Chế độ nhịp điệu cần `/music/` — chưa đưa `server/music/` lên `netlify_site/music/`; bản web hiện không dùng được chế độ này.
6. Khi owner hài lòng: cập nhật `DEVELOPMENT_LOG.md` (TESTED → VERIFIED chỉ khi owner/bằng chứng thật), commit, push. Tạo PR **chỉ khi owner yêu cầu**.

## 4. Lệnh
Godot Linux có thể đã mất giữa các phiên container. Tải lại nếu cần:
```
curl -sL -o godot.zip https://github.com/godotengine/godot-builds/releases/download/4.6.3-stable/Godot_v4.6.3-stable_linux.x86_64.zip && unzip godot.zip
# export templates (chỉ cần web_*): tải Godot_v4.6.3-stable_export_templates.tpz cùng thư mục releases,
# giải 'templates/web_*' + 'templates/version.txt' vào ~/.local/share/godot/export_templates/4.6.3.stable/
```
| Việc | Lệnh |
|---|---|
| Test backend | `cd tools/web && npm install && node function_src/selftest.mjs` (mã thoát 0, "TẤT CẢ ĐẠT") |
| Dựng lại function bó | `cd tools/web && node build_function.mjs` (đổi `server/modules/index.js`, `anti_cheat.json`, `game_rules.json`, `data/shop/topup_packs.json` thì phải chạy lại + deploy lại) |
| Dựng lại toàn bộ bản web | `GODOT=<đường dẫn godot> tools/web/build_web.sh` |
| GdUnit (Linux) | `<godot> --headless --path . -s -d --remote-debug tcp://127.0.0.1:0 res://addons/gdUnit4/bin/GdUnitCmdTool.gd -a res://tests/unit/online -a res://tests/unit/ui --ignoreHeadlessMode -rd /tmp/reports` (lần đầu cần `--import`, ~80 s) |
| Thử tại máy | `cd netlify_site && npx netlify-cli dev` (cần `GOOGLE_CLIENT_ID`; origin `http://localhost:8888` phải có trong Google Console) |

## 5. Quy tắc / bẫy cần nhớ
- **Không sửa** `addons/gdUnit4/`, `tools/pixelfx/`. Chữ hiển thị: khóa `UPPER_SNAKE` qua `tr()`, thêm vào **cả** `localization/vi.po` và `en.po`. Mọi số cân bằng ở `data/`.
- Sửa file có tiếng Việt: ghi script Python ra file rồi `python -X utf8 file.py`, không dán heredoc stdin cho file game.
- Shim `nk` (`nk_engine.mjs`): module Nakama gọi `nk.*` ĐỒNG BỘ; engine chạy hàm, gom dữ liệu thiếu, nạp rồi **chạy lại từ đầu** (kết quả/lỗi của lần thiếu dữ liệu bị bỏ). Hàm module phải không có tác dụng phụ ngoài `nk`; `Math.random`/`uuidv4` đã được gieo hạt cố định mỗi yêu cầu để chạy lại ra cùng khóa (ví dụ mã người chơi). Ghi trước khi ném lỗi vẫn được giữ (đánh dấu gian lận). Ghi dùng etag (`onlyIfMatch`/`onlyIfNew`) → xung đột = `save_conflict`.
- Logic gacha có HAI bản (game + `server/modules/index.js`); đổi luật phải sửa cả hai, sinh lại `server/rules/game_rules.json`, build lại function (xem `AGENTS.md` mục 3).
- `netlify_site/.gitignore` loại `index.pck/wasm/js/html/png` (đầu ra export) — **các file này không có trong git**; phiên mới phải chạy `build_web.sh` để có lại trước khi deploy. Function đã bó (`netlify/functions/api.mjs`) và `tools/web/function_src/{catalog,rules}.json`, `module_source.mjs` cũng KHÔNG có trong git (chứa thông tin nhận tiền + luật chống gian lận): dựng bằng `node build_function.mjs` (cần `npm install` và `server/private/payment.json`).
- `tools/web/node_modules/` không commit. `.godot/` không commit.
- Không commit khóa / `ADMIN_KEY` / `server/.runtime/`. `SERVER_KEY` mặc định `eclipse-test-key` không phải bí mật.
- Bản web: chỉ đăng nhập Google; `ALLOW_DEVICE_LOGIN=1` chỉ để dev, đừng bật trên site công khai (tạo nick vô hạn).
- Không có chat (không websocket trên Netlify Functions); `fetch_server_config` đặt `chat_enabled=false` và `chat_auto_start=false`.
- Giới hạn Netlify: kéo-thả không phù hợp file lớn; mỗi function ≤ 250 MB (bản bó ~130 KB, ổn).
