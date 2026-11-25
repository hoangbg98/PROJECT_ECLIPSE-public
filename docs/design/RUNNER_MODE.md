# Chạy Nguyên Tố — chế độ thứ hai của Event nguyên liệu (M11-4)

> **Tình trạng:** bản thiết kế lại ngày 2026-11-18 (Claude) từ đề xuất `RUNNER_MODE.md` của owner (2026-11-17). Mục 0
> ghi những gì đã đổi. Khung chung: `MATERIAL_EVENT.md`; chữ và cốt truyện: `EVENT_STORY.md` mục 4.

Mục tiêu: một dạng ải **khác Nhịp điệu về kỹ năng**. Nhịp điệu đo thời điểm bấm theo nhạc; Chạy Nguyên Tố đo **phản xạ và
quyết định**: nhảy hay không, và **đổi đúng người** để qua cổng. Đây là chế độ gần chủ đề game nhất (STORY_PROPOSAL B2:
"Không ai chiến đấu một mình, kể cả khi chỉ một người đứng trên sân"): đổi người đúng lúc là nghề của người quản lý.

Lối chơi theo thể loại chạy ngang tự động (cơ chế chung của thể loại); hình, tên, nhạc, bố cục là của dự án.

## 0. Thay đổi so với bản đề xuất

| # | Đề xuất | Bản này | Lý do |
|---|---|---|---|
| 1 | Đặt `physics_ticks_per_second = 120` | Bước cố định 1/120 s bằng `FixedStep` trong `_process` | Không đổi cài đặt combat của game chính |
| 2 | Mặc định đội đủ 3 người | `party_min` theo ải: N-1 = 1, N-2 = 2, N-3…N-5 = 3; cổng chỉ dùng ô có người | Game mới chỉ có Enkiba; sau ải 1-1 mới có Kazeyumi, vé x10 ra Raikiba |
| 3 | Vật cản "Bóng Chắn / Vết Nứt / Dơi Bóng" | **Cặn** (canon): Cặn Thấp, Vết Thực (hố), Cặn Bay; v1 dùng lại ảnh Sên Nhịp / Dơi Nốt của Nhịp điệu, tô **tím trung tính** | Thế giới canon có Cặn; đỡ tốn ảnh mới |
| 4 | Cổng Nguyên Tố | **Cổng Cộng Hưởng**: cổng chỉ mở cho người đang được Neo phóng ra sân | Khớp luật Neo / kênh (STORY B3) |
| 5 | `build_levels.py` (Python) + `RunnerBot` (GDScript) | Bộ sinh, bộ kiểm tra, bot đều **GDScript** chạy `godot --headless` | Một bản vật lý duy nhất; Python mô phỏng lại dễ lệch |
| 6 | `ground_y` 830 "trùng Nhịp điệu" | 840 (mép đất thật của màn Nhịp điệu: `down_y` 760 + 80) | Số thật trong `rhythm_stage.gd` |
| 7 | Không nói Yomigari | Yomigari chưa có frame `jump_up`, `fall`, `land`, `hurt` (`frames: 0`) → dùng placeholder; ghi vào danh sách ảnh | Manifest hiện tại |
| 8 | Tên cũ (Aether…) | Data ID + tên mới | AGENTS mục 3 |

## 1. Tổng quan

- 1920×1080, cuộn ngang, nhân vật ở `player_x` = 480, thế giới chạy sang trái.
- Mang **đội hiện tại**; mỗi lúc một người chạy (một giáp hiện hình). Hai hành động: **Nhảy** và **Đổi người**.
- Chỉ số chiến đấu không ảnh hưởng; HP mini game cố định.
- Cổng gắn với **ô đội** (1, 2, 3), màu lấy từ nguyên tố người ở ô đó; đội nào cũng chơi được.
- **Trợ năng:** mỗi ô có ký hiệu hình (○ ô 1, △ ô 2, □ ô 3) trên cổng, biểu tượng đội, nốt khớp.

## 2. Luồng trong ải

Scene `RunnerStage` (kế thừa `MinigameStage`) → nạp level → (lần đầu: hướng dẫn) → đếm ngược 3-2-1 → chạy → về đích
hoặc HP = 0 → `MinigameResult`.

- Level dài cố định (`length_sec`), có vạch đích. Vô tận là các **tuyến** hữu hạn sinh từ seed cố định.
- Tạm dừng (P, Esc, Start, nút ‖): đóng băng; thoát tạm dừng đếm ngược 1.5 s, xóa bộ đệm nhảy / đổi.
- Thoát giữa chừng = thất bại (`quit`). HP = 0 = thất bại, không thưởng.

## 3. Điều khiển

| | Bàn phím | Tay cầm | Cảm ứng |
|---|---|---|---|
| Nhảy | Space, W, ↑ | A | chạm **nửa trái** |
| Đổi người kế tiếp | E, Shift, → | RB | chạm **nửa phải** |
| Chọn thẳng ô 1 / 2 / 3 | 1 / 2 / 3 | X / Y / B | chạm **biểu tượng đội** góc trên phải (≥ 140 px) |
| Tạm dừng | P, Esc | Start | nút ‖ |

- Action mới trong `InputRouter`: `runner_jump`, `runner_swap`, `runner_slot_1..3`.
- Đổi kế tiếp quay vòng các ô **có người**. Chạm biểu tượng đội xử lý trước vùng nửa phải.
- Level phải qua được 100 % chỉ bằng nhảy + đổi kế tiếp. Giữ nhảy không nhảy lại.

## 4. Vật lý

Bước cố định 1/120 s (`FixedStep`), hiển thị nội suy. `data/runner/runner_rules.tres` (`RunnerRules`):

| Hằng | Giá trị | Ghi chú |
|---|---|---|
| `player_x` / `ground_y` | 480 / 840 px | |
| `jump_velocity` / `gravity` | 1300 px/s / 4000 px/s² | đỉnh 211 px, trên không 0.65 s |
| `coyote_time` / `jump_buffer` | 0.08 / 0.12 s | |
| `swap_cooldown` | 0.12 s | |
| `hurtbox` | 110 × 230 px, đáy ở chân | hình chữ nhật cố định (OD-R3) |
| `hp_max` / `hit_damage` / `gate_damage` | 100 / 20 / 25 | |
| `invuln_time` | 1.2 s (rơi hố 1.5 s) | |
| `spawn_x` | 2000 px | |

- Frame dùng lại: `run`, `jump_up`, `fall`, `land`, `hurt`, `idle` (đếm ngược). Thiếu thì placeholder. **Không** phát
  `switch_in` / `switch_out` (gắn kỹ năng, dài); đổi người là tức thời + vòng sáng Neo 0.12 s.

## 5. Vật cản và vật phẩm

| Loại | Tên hiển thị | Phải làm | Ghi chú |
|---|---|---|---|
| `hurdle` | Cặn Thấp | nhảy | cao 110 / 140 px; rộng ≤ 0.25 / 0.20 s |
| `pit` | Vết Thực | nhảy | hố trên đường; rộng ≤ 0.35 s |
| `flyer` | Cặn Bay | **không** nhảy | đáy 250 px, cao 90 px; đứng dưới thì lọt |
| `gate` | Cổng Cộng Hưởng | **đúng người** | vách sáng cao hết màn, màu + ký hiệu ô; từ N-2 |
| `orbs` | Hạt Tinh | nhặt | trung tính 10 điểm; khớp ô ×2 nếu đúng người nhặt |

- Cổng xét tại `t_cross + 0.05 s`: người đang chạy thuộc ô cổng = qua; sai = `gate_damage`, mất combo.
- Màu: vật cản luôn **tím trung tính**; màu nguyên tố chỉ cho cổng, Hạt Tinh khớp, biểu tượng đội.
- Cửa sổ nhảy (suy từ mục 4): Cặn Thấp 110 → bắt đầu nhảy trong 0.20 s; 140 → 0.178 s; Vết Thực → 0.30 s + coyote.

## 6. Điểm, hạng

| Sự kiện | Điểm |
|---|---|
| Vượt vật cản an toàn | 50 |
| Cổng **Perfect** (đổi xong trong 0.30 s trước lúc xét) | 200 |
| Cổng thường (đã đúng người từ trước) | 100 |
| Hạt Tinh trung tính / khớp | 10 / 20 |

- Combo, Fever (Perfect +4, vượt +1, hạt +0.25, trúng −20; đầy thì 8 s ×1.5 + hút hạt 300 px), cùng thông số kiểu Nhịp điệu.
- `accuracy = (Perfect × 1 + Cổng thường × 0.8 + Vượt an toàn × 1) / (tổng cổng + tổng vật cản)`; hạng như khung.
- `stats`: `accuracy`, `max_combo`, `hits_taken`, `collect_ratio`, `perfect_swaps`, `perfect_swap_ratio`,
  `distance_ratio`, `hp_left_ratio`.

## 7. Các ải

| Ải | Tốc độ | Độ dài | `party_min` | Có gì |
|---|---|---|---|---|
| N-1 | 600 | 60 s | 1 | Cặn Thấp, Vết Thực, Hạt Tinh trung tính |
| N-2 | 700 | 75 s | 2 | + Cặn Bay, cổng 2 ô (cách ≥ 1.2 s), hạt khớp |
| N-3 | 800 | 90 s | 3 | cổng 3 ô (≥ 0.9 s) |
| N-4 | 900 | 90 s | 3 | cổng chồng với Cặn Thấp (đổi + nhảy cùng lúc), ≥ 0.7 s |
| N-5 boss | 1000 | 120 s | 3 | level cố định, **Vầng Khuyết** ném vật (≥ 0.6 s) |

- Thời gian phản ứng `(spawn_x − player_x) / tốc độ`: 2.53 / 2.17 / 1.90 / 1.69 s; N-5 ném từ x = 1750 → 1.27 s.
- Boss: dùng lại sprite `rh_boss_eclipse` (đổi tên hiển thị Vầng Khuyết, OD-M8), thanh HP boss = quãng đường còn lại.
- Sao mẫu: N-1 `["clear", "stat:collect_ratio>=0.80", "stat:hits_taken==0"]`; N-2…N-4
  `["clear", "rank>=A", "stat:perfect_swap_ratio>=0.50"]`; N-5 `["clear", "rank>=B", "stat:hits_taken<=2"]`.
- Thưởng: cùng cỡ với ải Nhịp điệu cùng số (owner chỉnh trong `material_events.json`).
- **Vô tận (tuyến):** Dễ / Thường / Khó = 700 / 850 / 1000 px/s, 120 / 150 / 180 s, cổng cách ≥ 1.0 / 0.8 / 0.6 s;
  cần đội 3 người; khóa bản ghi `endless:<tuyến>:<độ khó>`; dùng chung hạn mức với `runner`.

## 8. Hướng dẫn (lần đầu, `data/runner/tutorial.json`)

Như Nhịp điệu: trong ải, chậm, không mất HP, đủ thì sang bước, có "Bỏ qua", xong thì đếm ngược.
N-1: nhảy Cặn Thấp → nhảy Vết Thực → nhảy nhặt hàng hạt vòng cung. N-2: dòng giới thiệu lúc đếm ngược + luyện ngắn:
đứng yên dưới Cặn Bay → cổng đúng người → cổng phải đổi → hai cổng liền. Không vật nào trước giây 2.0. Cờ lưu ở
`data["minigames"]["tutorials"]["runner"]`.

## 9. Dữ liệu

```text
data/runner/runner_rules.tres           RunnerRules
data/runner/chunks.json                 thư viện đoạn
data/runner/levels/<level_id>.json      level đã sinh (trong git, sửa tay được; boss cố định)
data/runner/routes.json                 tuyến Vô tận (seed cố định)
data/runner/tutorial.json
scripts/minigame/runner/                runner_stage.gd, runner_generator.gd, runner_validator.gd, runner_bot.gd
tools/runner/build_levels.gd            godot --headless -s, ghi level (gọi bộ sinh + validator + bot)
```

Level mẫu:

```json
{
  "format": 1, "level_id": "runner_mat_02", "speed": 700, "length_sec": 75.0, "slots_used": [0, 1],
  "theme": "n2", "bpm": 126, "bgm": "song_gale_runner", "boss": null,
  "events": [
    { "t": 2.4,  "type": "hurdle", "h": 110, "w": 120 },
    { "t": 3.0,  "type": "orbs", "pattern": "arc", "n": 5, "y": "air", "slot": null },
    { "t": 9.0,  "type": "flyer" },
    { "t": 12.5, "type": "gate", "slot": 1 }
  ]
}
```

- `t`: lúc vật chạm vị trí nhân vật. `slots_used` ⊆ {0,1,2}, số phần tử ≤ `party_min` của ải.
- `bgm` lấy từ thư viện nhạc Nhịp điệu (tải như Nhịp điệu); gameplay **không** đồng bộ nhạc. Không có mạng và chưa tải
  bài: chạy không nhạc, không chặn.

## 10. Bộ sinh và ràng buộc

Tất định (xorshift32 tự viết). Thuật toán: chọn đoạn theo `weight` / `min_level` (không lặp quá 2 lần liền) → gán ô
cổng (mỗi ô ≥ 20 % tổng cổng, không quá 3 cổng liền cùng ô) → chèn nghỉ nếu vi phạm → validator + bot → ghi JSON. Level
boss không bị ghi đè (cờ `--force-boss`).

| Ràng buộc | Giá trị |
|---|---|
| Rộng tối đa | Cặn Thấp 110: 0.25 s · 140: 0.20 s · Vết Thực: 0.35 s |
| `JUMP_GAP` / `LAND_GAP` / `FLYER_JUMP_GAP` | 0.75 / 0.45 / 0.15 s |
| Cổng – nhảy | cách ≥ 0.3 s ở N-2, N-3; được chồng ở N-4, N-5, Vô tận Thường / Khó |
| Không vật trước | 2.0 s |
| Hạt Tinh đồng thời | ≤ 24 |

## 11. Giao diện, hình, âm thanh

- HUD: thanh quãng đường (boss: thanh HP boss), điểm + combo, biểu tượng đội (ô đang chạy sáng viền + ký hiệu), HP +
  Fever (khung như Nhịp điệu), chữ "PERFECT" khi cổng Perfect.
- Nền: dùng lại nền Nhịp điệu khi có (`far`, `mid`, `ground`).
- **Ảnh cần (v1, tối thiểu):** Cổng Cộng Hưởng (vách sáng, tô màu bằng code), 3 ký hiệu ○ △ □, Hạt Tinh (tô màu bằng
  code), vòng sáng đổi người, Vết Thực (tile mép hố). Vật cản dùng ảnh Nhịp điệu tô tím. Frame Yomigari `jump_up`,
  `fall`, `land`, `hurt` (đang thiếu).
- Âm: nhảy, tiếp đất, trúng, cổng Perfect, đổi người, nhặt hạt, Fever.

## 12. Hiệu năng

Object pool; ≤ 40 vật, ≤ 24 hạt; vật ngoài màn thu hồi; va chạm hình chữ nhật, không dùng `PhysicsServer`.

## 13. Kiểm thử (GdUnit4)

Vật lý (đỉnh 211 ± 1 px, 0.65 ± 0.01 s, coyote, buffer); cổng (đúng / sai ô, biên Perfect 0.30 s, grace 0.05 s,
cooldown); vật cản (nhảy vào Cặn Bay = trúng, rơi hố + bất tử); điểm / Fever / hạng; **bot** qua 100 % level trong
git + 200 seed với 0 lần trúng, theo cả "chỉ đổi kế tiếp" và "chọn thẳng"; bộ sinh cùng seed ⇒ JSON giống byte; mỗi
ràng buộc một test sai + một test đúng; `party_min` chặn đúng; khung (stats đủ khóa, không sửa hub).

## 14. Lộ trình (M11-4)

Đã xong R0–R2 (2026-11-20): `RunnerRules`, `RunnerLevel`, `RunnerSim`, `RunnerBot` (`scripts/minigame/runner/`),
`RunnerStage` (`scripts/ui/runner/`), level N-1…N-3 trong `data/runner/levels/`. Bề rộng `w` của vật cản trong level là
bề rộng **va chạm** đã gộp thân người chạy (hình vẽ to hơn), nên cửa sổ nhảy khớp mục 5.

R3 + một phần R4 (2026-11-20): `RunnerGenerator` (khối có trọng số thay cho `chunks.json`: cấu hình trong
`data/runner/generated_levels.json` cho N-4 / N-5, trong `material_events.json` cho Vô tận), `tools/runner/build_levels.gd`
(sinh + bot kiểm, đổi seed tới khi bot qua 0 lần trúng), N-4, N-5 boss (Vầng Khuyết ném vật từ x = 1750), 3 tuyến Vô tận
× 3 độ khó (`RunnerRouteListScreen`). Kiểm bằng bot thay cho validator riêng. Chưa làm: hướng dẫn trong ải
(`data/runner/tutorial.json`), nhạc nền.

| Mốc | Nội dung | Xong khi |
|---|---|---|
| R0 | `RunnerRules`, `FixedStep`, chạy + nhảy, input | test vật lý xanh |
| R1 | Cặn Thấp, Vết Thực, Cặn Bay, HP, bất tử, Hạt Tinh, HUD | N-1 viết tay chơi được |
| R2 | Cổng, đội, đổi người, Perfect, điểm / combo / Fever / hạng | N-2, N-3 viết tay chơi được → **owner thử** |
| R3 | validator, bot, bộ sinh, `chunks.json` | N-1…N-4 sinh ra, test xanh |
| R4 | Hướng dẫn, boss N-5, tuyến Vô tận, nối khung | chơi qua hub |
| R5 | Hình thật, âm thanh, cân bằng | owner duyệt |

## 15. Quyết định mở

| Mã | Câu hỏi | Mặc định |
|---|---|---|
| OD-R1 | Vô tận tuyến hữu hạn hay chạy tới chết | Tuyến hữu hạn |
| OD-R2 | Checkpoint / thưởng một phần khi thua | Không |
| OD-R3 | Hurtbox chữ nhật cố định | Dùng (combat mới dùng AnimationPlayer) |
| OD-R4 | Chỉ số nhân vật ảnh hưởng | Không |
| OD-R5 | Chọn thẳng qua biểu tượng đội | Có; level không phụ thuộc |
| OD-R6 | `party_min` N-2 = 2, N-3+ = 3 | Như vậy |
| OD-R7 | Đồng bộ phách nhạc | Sau, tùy chọn |
