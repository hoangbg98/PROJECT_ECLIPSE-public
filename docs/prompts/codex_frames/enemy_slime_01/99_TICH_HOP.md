# Phiếu 99 — Đưa frame Cặn tro vào game (làm sau khi owner duyệt đủ 6 animation)

> Claude viết 2026-11-19. Hiện quái vẽ bằng `Polygon2D` màu tạm (`scenes/enemies/enemy_slime.tscn`, node `Body`).
> Phiếu này là việc code: thay bằng sprite có animation. Cặn lớn (`enemy_slime_02`) dùng chung scene nhưng **chưa có tấm
> sprite riêng** nên vẫn giữ đa giác.

## Prompt dán cho Codex

```text
Việc: cho quái enemy_slime_01 dùng frame đã duyệt trong assets/enemies/enemy_slime_01/ thay cho đa giác màu tạm.
Đọc trước: AGENTS.md (mục 3 Quy tắc code), docs/design/MONSTERS.md (mục 2, 6, 7.1), scripts/enemies/enemy_controller.gd,
scenes/enemies/enemy_slime.tscn, assets/enemies/enemy_slime_01/frames_manifest.json, và cách nhân vật nạp frame từ
frames_manifest.json (tìm nơi code nhân vật đọc manifest, dùng lại cách đó, không viết loader thứ hai).

Yêu cầu:
1. Scene quái có AnimatedSprite2D (hoặc cách nhân vật đang dùng), offset sao cho tâm x = 128, chân y = 224 của khung 256
   trùng gốc node (chân quái đứng đúng mặt đất như đa giác cũ). Frame vẽ quay phải: lật theo `facing`.
2. Nạp frame + fps + loop từ frames_manifest.json của enemy_id. Không có manifest (vd enemy_slime_02) → giữ Polygon2D cũ.
3. Ánh xạ trạng thái EnemyController → animation: PATROL/CHASE → move (đứng yên lâu thì idle), ATTACK → attack (bắt đầu đúng lúc
   SkillRunner bắt đầu đòn; 15 frame @12 fps = 1250 ms khớp 500/150/600 ms của data), STAGGER → hurt, STUNNED → stun,
   DEAD → death (frame cuối giữ nguyên trong lúc mờ dần death_fade_sec).
4. Giữ nguyên: hộp va chạm, Hurtbox, Hitbox, vạch báo hiệu đỏ, thanh HP / SC, nháy trắng khi trúng đòn (áp lên sprite).
5. Script gameplay không gọi thẳng tên autoload (AGENTS.md mục 3). Không đổi số trong data/.
6. Test GdUnit4 mới trong tests/unit/enemies/: enemy_slime_01 có sprite, đổi state thì đổi đúng animation, enemy_slime_02 vẫn
   dùng đa giác. Chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0).
7. Ghi docs/DEVELOPMENT_LOG.md, cập nhật docs/design/MONSTERS.md (Ảnh hiện tại của enemy_slime_01), commit
   "M6: Ash Dreg (enemy_slime_01) uses approved sprite frames", push. Nhắc tôi mở ải 1-1 trong Godot để xem bằng mắt.
```
