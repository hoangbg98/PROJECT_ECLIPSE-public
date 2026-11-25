# Phiếu 99 — Đưa frame Golem Đá Cổ vào game (sau khi đủ 8 animation)

> Claude viết 2026-11-19. Hiện boss vẽ bằng `Polygon2D` màu tạm trong `scenes/enemies/boss_golem.tscn`. Làm sau phiếu 99
> của Cặn tro (`../enemy_slime_01/99_TICH_HOP.md`) để dùng lại cách nạp frame quái.

## Prompt dán cho Codex

```text
Việc: cho boss_golem_01 (Golem Đá Cổ) dùng frame đã duyệt trong assets/enemies/boss_golem_01/.
Đọc trước: AGENTS.md (mục 3), docs/design/MONSTERS.md (mục 4, 6, 7.3), scripts/enemies/boss_controller.gd,
scripts/enemies/enemy_controller.gd, scenes/enemies/boss_golem.tscn, data/enemies/boss_golem_01.tres, và phần nạp frame quái đã làm
ở docs/prompts/codex_frames/enemy_slime_01/99_TICH_HOP.md.

Yêu cầu:
1. boss_golem.tscn có sprite khung 768×512, tâm x = 384, chân y = 464 trùng gốc node; giữ hộp va chạm / Hurtbox hiện tại
   (chỉnh nếu lệch thân mới, ghi vào nhật ký). Lật theo facing.
2. Ánh xạ: PATROL/CHASE → move (đứng yên → idle); ATTACK → animation = SkillDef.animation của đòn đang chạy (slam / charge /
   quake), bắt đầu đúng lúc SkillRunner bắt đầu đòn, speed_scale = thời lượng animation / (startup + active + recovery) của
   đòn đó (đòn pha 2 nhanh hơn dùng chung animation); chuyển pha → phase (12 frame @10 fps = 1.2 s = phase_transition_sec);
   STUNNED → stun; DEAD → death (giữ frame cuối khi mờ dần 1.2 s). Không có hurt: trúng đòn chỉ nháy trắng.
3. Giữ nguyên vạch báo hiệu đỏ, Hitbox, thanh máu boss + vạch pha, nháy trắng. Không đổi số trong data/.
4. Test GdUnit4 trong tests/unit/enemies/: golem có sprite; mỗi đòn chạy đúng animation; đòn pha 2 có speed_scale > 1;
   chuyển pha chạy phase. Chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0).
5. Ghi docs/DEVELOPMENT_LOG.md, cập nhật docs/design/MONSTERS.md (Ảnh hiện tại của boss_golem_01), commit
   "M6: Ancient Stone Golem uses approved sprite frames", push. Nhắc tôi mở ải 1-1 trong Godot để xem trận boss.
```
