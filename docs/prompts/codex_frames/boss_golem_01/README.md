# Frame Golem Đá Cổ (boss_golem_01) — gửi Codex từng phiếu

> Claude soạn 2026-11-19 từ `docs/design/MONSTERS.md` (mục 4, 6, 7.3) và bảng 38 bộ phận owner đã điền (đồng ý toàn bộ dự
> đoán). Cách làm giống Cặn tro (`../enemy_slime_01/README.md`). Idle là chuẩn dáng cho mọi animation sau: làm và duyệt idle trước.

## Thứ tự gửi

Mỗi phiếu có mục **"Prompt dán cho Codex"**. Khi Claude điều khiển Codex từ Claude Code: Codex chỉ vẽ dải (sandbox không
chạy Python), Claude cắt / kiểm tra / duyệt.

| Bước | Phiếu | Việc | Frame / fps | Trạng thái |
|---|---|---|---|---|
| 1 | [01_idle.md](01_idle.md) | Đứng thở — **làm trước** | 6 / 8, lặp | ✅ |
| 2 | [02_move.md](02_move.md) | Bước nặng | 8 / 8, lặp | ✅ |
| 3 | [03_slam.md](03_slam.md) | Đập đất (lấy đà 000–007, trúng 008–010) | 19 / 12 | ✅ |
| 4 | [04_charge.md](04_charge.md) | Húc (lấy đà 000–006, lao 007–011) | 22 / 12 | ✅ |
| 5 | [05_quake.md](05_quake.md) | Địa chấn, pha 2 (lấy đà 000–008, giậm 009–011) | 20 / 12 | ✅ |
| 6 | [06_stun.md](06_stun.md) | Choáng | 6 / 8, lặp | ✅ |
| 7 | [07_phase.md](07_phase.md) | Chuyển pha 1.2 s | 12 / 10 | ✅ |
| 8 | [08_death.md](08_death.md) | Gục ngã nguyên khối, ấn tắt | 12 / 10 | ✅ |
| 9 | [99_TICH_HOP.md](99_TICH_HOP.md) | Code: boss dùng frame trong game | — | ⬜ |

Tổng 105 frame, khớp `MONSTERS.md` mục 7.3. Không có `hurt`: boss không bị khựng (trúng đòn chỉ nháy trắng bằng code).

## File liên quan

- [00_PHAN_TICH.md](00_PHAN_TICH.md) — hình khối, bảng màu, bảng bộ phận theo số owner đã điền, quy tắc riêng của boss.
- `ref/` — tấm sprite gốc (đã che logo góc phải dưới) và ảnh cắt từng bộ phận / pose. Nằm trong `docs/`, không vào bản build.
- `tools/frames/jobs/boss_golem_01.json` — số frame / fps / khung 768×512 cho công cụ cắt và kiểm tra.

## Chưa làm trong lô này

- VFX: lửa nổ sát đất khi đập (số 31), sóng đất + đá lửa rơi khi địa chấn (20, 32), bụi khi húc, mảnh đá khi chết (21),
  đá lửa bay (18, 19): phiếu riêng, có thể dùng pixelfx.
