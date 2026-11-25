# Bản web trên Netlify (chơi thử tạm)

Game chạy trong trình duyệt (Godot Web, không luồng), backend là **Netlify Function** tương thích Nakama
(`tools/web/function_src/`): chạy lại nguyên `server/modules/index.js` (cloud save, gacha, chống gian lận) trên Netlify Blobs.
Đăng nhập **Google** (ID token được máy chủ xác minh chữ ký / audience / hạn). Không có chat (không websocket) — Hub tự ẩn biểu tượng Chat.

## Trạng thái hiện tại
Đã deploy (2026-11-25): **https://project-eclipse-game.netlify.app** (site `project-eclipse-game`, team của owner). Biến `GOOGLE_CLIENT_ID` đã đặt;
`ADMIN_KEY` và `ALLOW_DEVICE_LOGIN` **chưa** đặt (RPC admin tắt, đăng nhập thiết bị tắt). Owner đã tự đăng nhập Google và vào được Hub.

## Làm một lần: tạo Google Client ID
1. https://console.cloud.google.com → APIs & Services → Credentials → Create credentials → **OAuth client ID** → loại **Web application**.
2. **Authorized JavaScript origins**: thêm `https://<tên-site>.netlify.app` (và `http://localhost:8888` nếu thử bằng `netlify dev`).
3. Copy Client ID (dạng `xxxx.apps.googleusercontent.com`).

## Cài đặt Netlify bắt buộc (bài học lần deploy đầu)
Site mới tạo có **Production visibility = Private**: mọi đường (trang, file game, `/v2/*`) trả **401** và chuyển sang đăng nhập Netlify.
Phải vào Netlify → project → **Project configuration → Access & security → Visitor access → Edit visibility** → **Production = Public**
(Deploy Preview có thể để Private). Việc ai đăng nhập được do danh sách **Test users** bên Google quyết định.

Màn hình đồng ý Google: app ở chế độ **Testing** → chỉ email trong *Google Auth Platform → Audience → Test users* đăng nhập được (tối đa 100);
người thử sẽ thấy cảnh báo "Google hasn't verified this app" → Advanced → tiếp tục. Muốn bỏ giới hạn thì chuyển **In production**
(với phạm vi openid / email / profile thường không cần Google duyệt, nhưng kiểm tra lại khi chuyển).

Gặp `netlify login` báo `TypeError: Cannot set property name…` hoặc `Timed out waiting for authorization`: đóng các tab Authorize cũ, chạy lại và
bấm **Authorize** trong tab mới ngay; nếu vẫn lỗi dùng token cá nhân (`$env:NETLIFY_AUTH_TOKEN`, xóa token sau khi deploy).

## Deploy
```
cd netlify_site
npx netlify-cli login
npx netlify-cli sites:create --name <tên-site>           # lần đầu
npx netlify-cli env:set GOOGLE_CLIENT_ID <client id>
npx netlify-cli env:set ADMIN_KEY <chuỗi bí mật dài>     # để QTV gọi RPC admin_* (tùy chọn)
npx netlify-cli deploy --prod --dir=. --functions=netlify/functions
```
**Không kéo-thả được**: `index.pck` ~94 MB (đã nén ảnh lossy WebP q0.9 bằng `tools/web/lossy_copy.py`, bản gốc desktop không đổi), vượt mức khuyến nghị của kéo-thả; phải dùng CLI. Function bó (`netlify/functions/api.mjs`, một file) và các file sinh ra của nó **không nằm trong git** (chứa thông tin nhận tiền):
máy mới chạy `cd tools/web && npm install && node build_function.mjs` (cần `server/private/payment.json`), file game dựng bằng `tools/web/build_web.sh`. Dựng lại: `GODOT=<godot> tools/web/build_web.sh`.

## Biến môi trường
| Biến | Việc |
|---|---|
| `GOOGLE_CLIENT_ID` | Bắt buộc; thiếu thì màn đăng nhập báo "chưa cấu hình Google". |
| `ADMIN_KEY` | RPC `admin_*` (xem cờ gian lận…) gọi bằng `POST /v2/rpc/<id>?http_key=<ADMIN_KEY>`. Không đặt = tắt. |
| `ALLOW_DEVICE_LOGIN=1` | Cho đăng nhập bằng mã thiết bị (chỉ để dev thử; sản phẩm thật đừng bật: tạo nick vô hạn). |
| `SERVER_KEY` | Mặc định `eclipse-test-key` (khớp `data/config/online_config.json`). |
| `SESSION_SECRET` | Khóa ký phiên; mặc định tự sinh và lưu trong Blobs. |

## Chống gian lận (đã có hiệu lực trên bản web)
Mỗi lần lưu, function kiểm save (checksum, tiền âm / vượt trần, cấp vượt trần, sửa lịch sử gacha → **từ chối**; tăng tiền bất thường,
nhân vật không rõ nguồn → **đánh dấu**), gacha chạy phía máy chủ. Luật: `data/config/anti_cheat.json` + `server/rules/game_rules.json`
(bó vào function khi build). Đổi luật / banner → chạy lại `tools/web/build_web.sh` và deploy.
Xem tài khoản bị đánh dấu: `POST /v2/rpc/admin_cheat_flags?http_key=<ADMIN_KEY>` body `"{}"`.

## Hạn chế
- Không chat / bạn bè; không nạp tiền thật (bảng giá có nhưng QTV phải phát tay qua `admin_grant`).
- Dữ liệu Netlify Blobs của bản thử; không sao lưu tự động.
- Tải lần đầu ~130 MB (pck ~94 MB + wasm ~38 MB; Netlify tự nén) (trình duyệt cache các lần sau). Chế độ nhịp điệu cần nhạc ở `/music/` (chưa đưa lên).
- Đã thử: owner đăng nhập Google thật, vào Hub. **Chưa thử**: chơi qua màn, F5 còn save, gacha trên bản web, âm thanh, chất lượng ảnh lossy.
- Chữ "Bấm nút Đăng nhập Google bên dưới" ở màn đăng nhập sai nghĩa (nút nằm phía trên dòng này); cần sửa khóa dịch rồi build + deploy lại.
