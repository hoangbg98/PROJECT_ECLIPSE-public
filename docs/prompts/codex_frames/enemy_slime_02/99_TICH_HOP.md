# Phiếu 99 — Đưa frame Cặn lớn vào game (sau khi owner duyệt đủ 6 animation)

> Claude viết 2026-11-19. Hiện `enemy_slime_02` dùng chung `scenes/enemies/enemy_slime.tscn` với Cặn tro nên to bằng nhau
> (`MONSTERS.md` mục 3). Phiếu này tách scene riêng, to hơn, và dùng frame. Làm sau phiếu 99 của Cặn tro
> (`../enemy_slime_01/99_TICH_HOP.md`) để dùng lại cách nạp frame đã có.

## Prompt dán cho Codex

```text
Việc: cho quái enemy_slime_02 (Cặn lớn) có scene riêng và dùng frame đã duyệt trong assets/enemies/enemy_slime_02/.
Đọc trước: AGENTS.md (mục 3), docs/design/MONSTERS.md (mục 3, 6, 7.2), scripts/world/stage_controller.gd (bảng enemy_id → scene),
scenes/enemies/enemy_slime.tscn, và phần nạp frame quái đã làm ở docs/prompts/codex_frames/enemy_slime_01/99_TICH_HOP.md.

Yêu cầu:
1. Tạo scenes/enemies/enemy_slime_big.tscn (dựa trên enemy_slime.tscn, enemy_id = "enemy_slime_02"): hộp va chạm và Hurtbox
   to hơn theo hình mới (khoảng 150×130, đáy ở gốc node), sprite khung 320 với tâm x = 160, chân y = 288 trùng gốc node.
2. stage_controller.gd: "enemy_slime_02" trỏ tới scene mới. Không đổi data/stages hay số trong data/enemies.
3. Ánh xạ trạng thái → animation như Cặn tro: PATROL/CHASE → move (đứng yên lâu thì idle), ATTACK → attack (20 frame @12 fps =
   1680 ms khớp 700/180/800 ms), STAGGER → hurt, STUNNED → stun, DEAD → death (giữ frame cuối khi mờ dần 0.8 s).
4. Giữ nguyên Hitbox / vạch báo hiệu đỏ / thanh HP, SC / nháy trắng. Kiểm tra thanh HP vẽ trên đầu quái to hơn (không đè thân).
5. Test GdUnit4 trong tests/unit/enemies/: enemy_slime_02 dùng scene mới, có sprite, đổi state đúng animation, hộp va chạm to
   hơn enemy_slime_01. Chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0).
6. Ghi docs/DEVELOPMENT_LOG.md, cập nhật docs/design/MONSTERS.md (Ảnh hiện tại của enemy_slime_02), commit
   "M6: Big Ash Dreg (enemy_slime_02) own scene with approved sprite frames", push. Nhắc tôi mở ải 1-2 trong Godot để xem.
```
