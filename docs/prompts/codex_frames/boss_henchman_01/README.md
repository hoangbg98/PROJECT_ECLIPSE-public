# Frame Kẻ Đeo Mặt Nạ (boss_henchman_01) — gửi Codex từng phiếu

> Claude soạn 2026-11-19 từ `docs/design/MONSTERS.md` (mục 5, 6, 7.4) và bảng 46 bộ phận owner đã điền (đồng ý toàn bộ dự
> đoán). Cách làm giống Golem (`../boss_golem_01/README.md`). Idle là chuẩn dáng cho mọi animation sau: làm và duyệt idle trước.

## Thứ tự gửi

Mỗi phiếu có mục **"Prompt dán cho Codex"**. Khi Claude điều khiển Codex từ Claude Code: Codex chỉ vẽ dải (sandbox không
chạy Python), Claude cắt / kiểm tra / duyệt.

| Bước | Phiếu | Việc | Frame / fps | Trạng thái |
|---|---|---|---|---|
| 1 | [01_idle.md](01_idle.md) | Đứng chờ — **làm trước** | 6 / 8, lặp | ✅ |
| 2 | [02_move.md](02_move.md) | Bước đi | 8 / 10, lặp | ✅ |
| 3 | [03_sweep.md](03_sweep.md) | Chém quét (lấy đà 000–006, trúng 007–009) | 17 / 12 | ✅ |
| 4 | [04_dash.md](04_dash.md) | Lao móc (lấy đà 000–005, lao 006–010) | 19 / 12 | ✅ |
| 5 | [05_ash_wave.md](05_ash_wave.md) | Sóng tro, pha 2 (lấy đà 000–008, cắm 009–011) | 20 / 12 | ✅ |
| 6 | [06_stun.md](06_stun.md) | Choáng | 6 / 8, lặp | ✅ |
| 7 | [07_phase.md](07_phase.md) | Chuyển pha 1.2 s | 12 / 10 | ✅ |
| 8 | [08_death.md](08_death.md) | Quỳ gục (khớp ô `ch01_end_01`) | 12 / 10 | ✅ |
| 9 | [99_TICH_HOP.md](99_TICH_HOP.md) | Code: boss dùng frame trong game | — | ⬜ |

Tổng 100 frame, khớp `MONSTERS.md` mục 7.4. Không có `hurt`: boss không bị khựng.

## File liên quan

- [00_PHAN_TICH.md](00_PHAN_TICH.md) — hình khối (chibi, vest đen, mặt nạ trơn), bảng màu, bảng bộ phận, quy tắc riêng.
- `ref/` — tấm sprite gốc (có logo mờ đè lên pose 46, không che được) và ảnh cắt từng bộ phận / pose. Nằm trong `docs/`.
- `tools/frames/jobs/boss_henchman_01.json` — số frame / fps / khung 768×512 cho công cụ cắt và kiểm tra.

## Chưa làm trong lô này

- VFX: vệt chém lửa khi quét (số 32), sóng tro hai phía khi ash_wave, tro rỉ ra từ khe giáp, hiệu ứng bị rút về kênh khi chết.
