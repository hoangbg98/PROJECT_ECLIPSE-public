# Frame Cặn tro (enemy_slime_01) — gửi Codex từng phiếu, owner duyệt từng cái

> Claude soạn 2026-11-19 từ `docs/design/MONSTERS.md` (mục 2, 6, 7.1) và bảng 41 bộ phận owner đã điền trên tấm sprite.
> Owner chốt: tấm sprite này dành cho **Cặn thường**; Cặn lớn (`enemy_slime_02`) làm tấm riêng sau.

## Thứ tự gửi

Mỗi phiếu có mục **"Prompt dán cho Codex"**: chép nguyên khối đó gửi Codex. Chờ Codex gửi `sheet.png` + `anim.gif`, xem xong
trả lời `duyệt <animation>` (hoặc chỉ frame cần sửa) rồi mới gửi phiếu kế tiếp.

| Bước | Phiếu | Việc | Frame / fps | Trạng thái |
|---|---|---|---|---|
| 0 | [00_CONG_CU.md](00_CONG_CU.md) | Code: công cụ `tools/frames/` hiểu quái (khung 256, `assets/enemies/`) | — | ✅ |
| 1 | [01_idle.md](01_idle.md) | Đứng thở — **làm trước**, các animation sau canh tỉ lệ theo idle | 6 / 8, lặp | ✅ |
| 2 | [02_move.md](02_move.md) | Nhảy lết tới | 8 / 12, lặp | ✅ |
| 3 | [03_attack.md](03_attack.md) | Cắn lao (lấy đà 000–005, trúng 006–007) | 15 / 12 | ✅ |
| 4 | [04_hurt.md](04_hurt.md) | Trúng đòn | 3 / 12 | ✅ |
| 5 | [05_stun.md](05_stun.md) | Choáng | 6 / 8, lặp | ✅ |
| 6 | [06_death.md](06_death.md) | Vỡ thành tro | 6 / 10 | ✅ |
| 7 | [99_TICH_HOP.md](99_TICH_HOP.md) | Code: quái dùng frame trong game | — | ⬜ |

Tổng 44 frame, khớp `MONSTERS.md` mục 7.1.

## File liên quan

- [00_PHAN_TICH.md](00_PHAN_TICH.md) — hình khối, bảng màu, bảng bộ phận theo số owner đã điền, quy tắc riêng của quái.
- `ref/` — tấm sprite gốc (đã che logo góc phải dưới) và các ảnh cắt từng bộ phận để đính kèm khi tạo ảnh. Nằm trong
  `docs/` nên không vào bản build.
- `tools/frames/jobs/enemy_slime_01.json` — số frame / fps / khung cho công cụ cắt và kiểm tra.

## Chưa làm trong lô này

- VFX đi kèm (MONSTERS.md mục 8: tro tung khi chết, phiến đá văng số 20, nổ lửa số 22): phiếu riêng, có thể dùng pixelfx.
- Pose khạc / ném đá (số 40): game chưa có đòn tầm xa cho Cặn tro, để dành.
- Cặn lớn, Golem Đá Cổ, Kẻ Đeo Mặt Nạ: chờ tấm sprite / bảng thiết kế riêng.
