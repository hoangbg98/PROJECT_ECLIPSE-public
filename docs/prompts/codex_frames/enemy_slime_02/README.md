# Frame Cặn lớn (enemy_slime_02) — gửi Codex từng phiếu, owner duyệt từng cái

> Claude soạn 2026-11-19 từ `docs/design/MONSTERS.md` (mục 3, 6, 7.2) và bảng 41 bộ phận owner đã điền trên tấm sprite
> Cặn lớn. Cách làm giống Cặn tro thường (`../enemy_slime_01/README.md`).

## Thứ tự gửi

Mỗi phiếu có mục **"Prompt dán cho Codex"**: chép nguyên khối đó gửi Codex. Chờ Codex gửi `sheet.png` + `anim.gif`, xem xong
trả lời `duyệt <animation>` (hoặc chỉ frame cần sửa) rồi mới gửi phiếu kế tiếp.

| Bước | Phiếu | Việc | Frame / fps | Trạng thái |
|---|---|---|---|---|
| 0 | [../enemy_slime_01/00_CONG_CU.md](../enemy_slime_01/00_CONG_CU.md) | Code: công cụ `tools/frames/` hiểu quái — **dùng chung**, làm một lần cho cả hai loại Cặn | — | ✅ |
| 1 | [01_idle.md](01_idle.md) | Đứng thở nặng — **làm trước**, các animation sau canh tỉ lệ theo idle | 6 / 8, lặp | ✅ |
| 2 | [02_move.md](02_move.md) | Bước nặng | 8 / 10, lặp | ✅ |
| 3 | [03_attack.md](03_attack.md) | Cắn lao nặng (lấy đà 000–007, trúng 008–010) | 20 / 12 | ✅ |
| 4 | [04_hurt.md](04_hurt.md) | Trúng đòn | 3 / 12 | ✅ |
| 5 | [05_stun.md](05_stun.md) | Choáng | 6 / 8, lặp | ✅ |
| 6 | [06_death.md](06_death.md) | Sụp thành đống đá | 8 / 10 | ✅ |
| 7 | [99_TICH_HOP.md](99_TICH_HOP.md) | Code: Cặn lớn có scene riêng, dùng frame trong game | — | ⬜ |

Tổng 51 frame, khớp `MONSTERS.md` mục 7.2.

## File liên quan

- [00_PHAN_TICH.md](00_PHAN_TICH.md) — hình khối, bảng màu, bảng bộ phận theo số owner đã điền, cách ghép bốn pose đòn đánh.
- `ref/` — tấm sprite gốc và các ảnh cắt từng bộ phận để đính kèm khi tạo ảnh. Nằm trong `docs/` nên không vào bản build.
- `tools/frames/jobs/enemy_slime_02.json` — số frame / fps / khung cho công cụ cắt và kiểm tra.

## Chưa làm trong lô này

- VFX đi kèm: đá cháy bay (18, 19), lửa tóe / cột lửa (26, 27, 35), nổ lửa khi chết (34), bụi khi đáp (vẽ trong pose 40):
  phiếu riêng, có thể dùng pixelfx.
- Đòn mới (nhảy giậm đất, phun đá cháy): data hiện chỉ có cắn lao nặng. Muốn thêm thì owner quyết, rồi thêm số liệu vào
  `data/enemies/enemy_slime_02.tres` trước khi làm frame.
