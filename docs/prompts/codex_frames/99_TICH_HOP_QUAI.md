# Phiếu 99 (chung) — Đưa frame của 4 quái Chương 1 vào game

> Claude viết 2026-11-19. Gộp 4 phiếu `99_TICH_HOP.md` riêng (`enemy_slime_01/`, `enemy_slime_02/`, `boss_golem_01/`,
> `boss_henchman_01/`) thành **một lượt việc cho Codex**. Các phiếu riêng vẫn giữ để tra chi tiết; làm theo phiếu này thì
> không cần gửi các phiếu riêng nữa.

## Hiện trạng (Claude đọc code 2026-11-19)

| Mục | Hiện tại |
|---|---|
| Frame đã duyệt | `assets/enemies/{enemy_slime_01, enemy_slime_02, boss_golem_01, boss_henchman_01}/frames/` + `frames_manifest.json` (tổng 300 frame) |
| Vẽ quái | node `Body` (`Polygon2D` màu tạm) trong `scenes/enemies/enemy_slime.tscn`, `boss_golem.tscn`, `boss_henchman.tscn` |
| Hướng / màu | `EnemyController._draw()` cuối file: `body.scale.x = facing`; `body.modulate` = trắng khi trúng đòn (`_flash`), xanh khi choáng, cam khi đang báo hiệu đòn, bình thường thì `Color.WHITE` |
| Nạp frame | `scripts/characters/animation_set_builder.gd`: `AnimationSetBuilder.build_from_dir(dir)` đọc manifest bất kỳ thư mục nào, trả `sprite_frames` + `sprite_offset` (pivot = chân) — **dùng lại, không viết loader mới** |
| Scene theo quái | `scripts/world/stage_controller.gd`: bảng `enemy_id → scene`; `enemy_slime_02` đang dùng chung `enemy_slime.tscn` (to bằng Cặn tro) |
| Tên animation đòn | `SkillDef.animation` trong `data/enemies/*.tres`: Cặn `attack`; Golem `slam` / `charge` / `quake`; Kẻ Đeo Mặt Nạ `sweep` / `dash` / `ash_wave` |

## Bảng animation cần nối

| Quái | Khung (tâm x, chân y) | Animation có | Không có |
|---|---|---|---|
| `enemy_slime_01` | 256×256 (128, 224) | idle, move, attack, hurt, stun, death | — |
| `enemy_slime_02` | 320×320 (160, 288) | idle, move, attack, hurt, stun, death | — |
| `boss_golem_01` | 768×512 (384, 464) | idle, move, slam, charge, quake, stun, phase, death | hurt (boss không khựng) |
| `boss_henchman_01` | 768×512 (384, 464) | idle, move, sweep, dash, ash_wave, stun, phase, death | hurt |

## Prompt dán cho Codex

```text
Việc: cho 4 quái Chương 1 dùng frame đã duyệt thay cho đa giác màu tạm. Làm hết trong một lượt, một commit.
Đọc trước: AGENTS.md (mục 3 Quy tắc code, mục 5 Nhật ký), docs/design/MONSTERS.md (mục 2–5, 6, 7),
docs/prompts/codex_frames/99_TICH_HOP_QUAI.md (bảng hiện trạng + bảng animation), scripts/enemies/enemy_controller.gd,
scripts/enemies/boss_controller.gd, scripts/characters/animation_set_builder.gd, scripts/world/stage_controller.gd,
scenes/enemies/*.tscn, tests/unit/enemies/*.gd, assets/enemies/*/frames_manifest.json.

1. Nạp frame: thêm vào AnimationSetBuilder hàm build_for_enemy(enemy_id) = build_from_dir("res://assets/enemies/" + enemy_id)
   (hằng ENEMIES_DIR). Không viết loader thứ hai, không đổi hành vi build_for_character.
2. EnemyController:
   - Node con tùy chọn `Sprite` (AnimatedSprite2D, centered = true). Lúc _ready: nếu assets/enemies/<enemy_id>/frames_manifest.json
     có và build không lỗi → gán sprite_frames + offset, hiện Sprite, ẩn Body. Không có manifest → giữ Body như cũ (không crash).
   - Hướng và màu: áp đúng logic hiện tại của Body (scale.x = facing; modulate trắng / xanh / cam / WHITE) lên node đang hiện
     (Sprite hoặc Body). Frame vẽ quay phải.
   - Chọn animation theo trạng thái, chỉ đổi khi khác animation đang chạy:
     PATROL/CHASE: đang di chuyển (|velocity.x| > ngưỡng nhỏ) → move, đứng yên (vd nghỉ ở đầu đường tuần tra) → idle;
     ATTACK → animation = SkillDef.animation của đòn SkillRunner đang chạy, play từ frame 0 đúng lúc đòn bắt đầu,
       speed_scale = (frames / fps) / ((startup_ms + active_ms + recovery_ms) / 1000) của đòn đó → đòn pha 2 nhanh hơn tự khớp;
     STAGGER → hurt (nếu có, không có thì giữ animation hiện tại); STUNNED → stun; DEAD → death (không lặp, giữ frame cuối
       trong lúc mờ dần death_fade_sec).
     Animation thiếu trong manifest → dùng idle (giống PlayerController.animation_or_fallback), không crash.
   - Không đổi AI, va chạm, Hitbox / Hurtbox, vạch báo hiệu đỏ, thanh HP / SC hay số trong data/.
3. BossController: trong thời gian chuyển pha (is_transitioning()) chạy phase (12 frame @10 fps = 1.2 s = phase_transition_sec),
   xong thì về idle / move. Boss không có hurt.
4. Scene:
   - enemy_slime.tscn: thêm Sprite. Hộp va chạm giữ ~110×90 nếu khớp thân Cặn tro mới (cao ~100 px), lệch thì chỉnh và ghi nhật ký.
   - Tạo scenes/enemies/enemy_slime_big.tscn cho enemy_slime_02 (dựa trên enemy_slime.tscn): hộp va chạm + Hurtbox ~150×130
     (đáy ở gốc node), Sprite. stage_controller.gd: "enemy_slime_02" → scene mới.
   - boss_golem.tscn, boss_henchman.tscn: thêm Sprite; hộp va chạm theo thân mới (Golem cao ~330 px, Kẻ Đeo Mặt Nạ ~300 px),
     ghi số cũ → mới vào nhật ký. Thanh HP vẽ trên đầu không đè thân to hơn.
   Script gameplay không gọi thẳng tên autoload (AGENTS.md mục 3).
5. Test GdUnit4 (tests/unit/enemies/test_enemy_sprites.gd, mới): với mỗi enemy_id → có Sprite đang hiện, Body ẩn, đủ animation
   theo bảng; đổi state → đúng animation (move / attack / hurt / stun / death); boss: đòn pha 2 có speed_scale > 1, chuyển pha
   chạy phase; enemy_slime_02 dùng scene mới và hộp va chạm to hơn enemy_slime_01; quái không có manifest vẫn dùng Body.
   Chạy <godot> --headless --path . --import, rồi powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0).
6. Chụp kiểm tra (nếu có script chụp màn chơi trong tools/, vd tools/screenshot_*.gd): một ảnh ải 1-1 có Cặn tro + Golem,
   một ảnh ải 1-10 có Kẻ Đeo Mặt Nạ; để trong build/screenshots/ (không commit), gửi tôi.
7. Ghi docs/DEVELOPMENT_LOG.md (mục mới, ghi cả quyết định chọn ngưỡng / kích thước va chạm), cập nhật docs/design/MONSTERS.md
   (cột "Ảnh hiện tại" ở mục 0 → sprite) và trạng thái phiếu 99 trong 4 README ở docs/prompts/codex_frames/<id>/.
   Commit "M6: enemies and bosses of chapter 1 use approved sprite frames", push. Nhắc tôi mở ải 1-1, 1-2 và 1-10 trong Godot
   để xem bằng mắt.
```

## Tự kiểm tra trước khi báo xong

1. Quái đứng đúng mặt đất (chân sprite trùng chân đa giác cũ), không lơ lửng, không lún.
2. Quay trái / phải đúng hướng đang đi và hướng đánh; lưỡi móc / mặt không bị lật ngược khi đứng yên.
3. Pha báo hiệu (lấy đà) của animation khớp vạch đỏ báo hiệu; frame trúng đòn khớp lúc Hitbox bật.
4. Nháy trắng khi trúng đòn, ánh xanh khi choáng, ánh cam khi báo hiệu vẫn thấy trên sprite.
5. Chết: animation chạy hết rồi mờ dần, không giật về idle.
6. `run_tests.ps1` mã thoát 0.
