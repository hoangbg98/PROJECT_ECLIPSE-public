# Bay Nguyên Tố — chế độ thứ ba của Event nguyên liệu (M11-5)

> **Tình trạng:** bản thiết kế lại ngày 2026-11-18 (Claude) từ đề xuất `JET_MODE.md` của owner (2026-11-17), số lấy từ
> bản thử `jet_prototype.html`. Mục 0 ghi những gì đã đổi. Khung: `MATERIAL_EVENT.md`; chữ và cốt truyện:
> `EVENT_STORY.md` mục 5; trang phục: `JET_COSTUME_BRIEF.md` (hoãn).

Mục tiêu: ải **bay ngang tự cuộn một nút**: giữ để bay, thả để rơi, kèm **năng lượng** và **biến hình**. Khác Nhịp
điệu (canh nhịp) và Chạy (phản xạ + đổi người). Rồng và Robo là ý tưởng của owner, hình vẽ riêng của dự án.

## 0. Thay đổi so với bản đề xuất

| # | Đề xuất | Bản này | Lý do |
|---|---|---|---|
| 1 | `physics_ticks_per_second = 120` | `FixedStep` 1/120 s trong `_process` | Không đổi cài đặt combat |
| 2 | 3 hình: Rồng, Robo, Đảo Chiều | v1: **Rồng, Robo**; Đảo Chiều để sau (OD-J11) | Giảm phạm vi; Đảo Chiều mượn sức của boss, chưa hợp truyện canon |
| 3 | 4 vùng ngay từ đầu | v1: 3 vùng (Ống Tro, Thung Gió Ngược, Hang Sét Câm); Lòng Lò Nứt (dung nham) ở J4 | Vùng dung nham buộc hình Rồng, cần hình mới nhất |
| 4 | Bộ đồ bảo hộ mới cho 6 nhân vật | **Không** trong v1: dùng frame sẵn có + Bộ Phụt vẽ riêng làm lớp VFX | 6 bộ × 5 animation là việc ảnh lớn nhất của chế độ; xem `JET_COSTUME_BRIEF.md` |
| 5 | Thế giới "Mạch / Hành Lang / Thợ Lõi / Quầng" | Vết Khuyết, Cặn, Tinh Lõi, NEO dẫn đường, boss Vầng Khuyết (`EVENT_STORY.md`) | Gộp với thế giới canon |
| 6 | Bot hoàn hảo bắt buộc | Bắt buộc **validator hành lang**; bot là mục tiêu J3, không chặn phát hành nếu validator đủ | Bot bay điều khiển liên tục khó hơn bot nhảy |
| 7 | Nhân vật dẫn đầu | Ô 1 của đội (Data ID), frame `run` / `jump_up` / `fall` / `hurt`; Yomigari thiếu 3 animation → placeholder | Manifest hiện tại |
| 8 | Tên cũ | Data ID + tên mới | AGENTS mục 3 |

## 1. Tổng quan

- 1920×1080, cuộn ngang, nhân vật ở `player_x` = 420.
- Chỉ **người ở ô 1** bay (một giáp hiện hình trong Vết Khuyết). Không đổi người. Chỉ số chiến đấu không ảnh hưởng;
  nguyên tố của người bay tô màu lửa phụt và vệt bay.
- Nhân vật tự chạy, đeo **Bộ Phụt**. **Giữ** = phụt lên (tốn năng lượng), **thả** = rơi.
- **Năng lượng 0–100**: giảm khi phụt, hồi chậm khi đứng đất, nạp bằng **Tinh Lõi**.
- **Hộp Ký Ức** biến thành **Rồng** hoặc **Robo**; mỗi hình đỡ **một** cú trúng.
- **Tim:** 3. Trúng mất 1 tim (đang biến hình thì vỡ hình thay vì mất tim). Hết tim = kết thúc.

## 2. Luồng

`JetStage` (kế thừa `MinigameStage`) → nạp level / bộ sinh → (lần đầu: hướng dẫn) → đếm ngược → bay → `MinigameResult`.

- **Ải (5):** level cố định có `length_m`; tới đích = qua. Hết tim trước đích = thất bại.
- **Vô tận:** không đích; kết thúc khi hết tim; `cleared = distance_m ≥ clear_m` (1500 m).
- Tạm dừng như Chạy (đếm ngược 1.5 s, xóa trạng thái giữ). Thoát = thất bại (`quit`).
- **Luyện vùng** (Vô tận, khóa một vùng): `ctx.practice = true`, không tốn lượt, không thưởng.

## 3. Điều khiển

Một action: `jet_hold` (Space, W, ↑ / tay cầm A / chạm giữ **bất kỳ đâu** trừ nút ‖).

- Nhiều ngón / phím: còn một cái đang nhấn là đang giữ.
- Người thường và Rồng dùng **giữ**; Robo dùng **chạm** (nhấn xuống = nhảy).
- HUD luôn hiện biểu tượng hình + gợi ý ("Giữ để bay" / "Chạm để nhảy").

## 4. Vật lý — `data/jet/jet_rules.tres` (`JetRules`)

| Hằng | Giá trị | Ý nghĩa |
|---|---|---|
| `player_x` | 420 px | |
| `floor_y` / `ceiling_y` | 900 / 110 px | |
| `spawn_x` | 2070 px | |
| `px_per_meter` | 60 | |
| `gravity` / `thrust` | 2200 / 3600 px/s² | lên thực 1400 |
| `vy_up_max` / `vy_down_max` | 900 / 1100 px/s | |
| `scroll_base` / `scroll_ramp` / `scroll_cap` | 520 px/s / 0.15 px/s mỗi m / 1000 px/s | cap ở ~3200 m |
| `energy_max` / `energy_drain` / `energy_regen_ground` / `core_gain` | 100 / 24 /s / 10 /s / 30 | |
| `hurt_radius` | 32 px | hình tròn cố định (OD-J3) |
| `invuln_hit` / `invuln_form_break` | 1.5 / 1.2 s | |
| `lives` | 3 | |

Suy ra: thùng đầy bay liên tục 4.17 s; hồi đầy trên đất 10 s; lơ lửng bền vững (~61 % thời gian phụt) 6.8 s.
Hết năng lượng thì rơi, chạy đất và hồi (không kẹt). Trần chặn, không mất tim.

Khả năng cơ động từ nghỉ (dùng cho bộ sinh + validator): lên 44 / 175 / 610 px, xuống 69 / 275 / 825 px sau 0.25 /
0.5 / 1.0 s.

## 5. Biến hình (v1: 2 hình)

Hộp mỗi 10000–18000 px (≈ 167–300 m), seed. Chạm hộp +10 Hạt Tinh; đang biến hình thì làm mới thời gian.

| Hình | Điều khiển | Vật lý | Hurtbox | Thời gian | Đặc điểm |
|---|---|---|---|---|---|
| **Rồng** | giữ lên / thả xuống | lên −2600, xuống +1500 px/s², vy ∈ [−650, 800] | 60 px | 14 s | mượt, không tốn năng lượng |
| **Robo** | chạm = nhảy (đang đứng đất) | trọng lực 3400, nhảy vy −1300 (cao ≈ 248 px) | 58 px | 10 s | **nghiền** vật cản (+5 hạt), không bay |

Mỗi hình đỡ đúng một cú: vỡ hình, bất tử 1.2 s, không mất tim. Hết giờ trở lại người thường (giữ vận tốc dọc).
Hộp đầu tiên của người mới luôn là Rồng.

## 6. Vùng

`zone = floor(m / zone_length) mod số_vùng`, `zone_length` 600 m. Vào vùng mới: biểu ngữ 3.2 s, nghỉ sinh vật ≥ 1000 px.

| # | Vùng (id) | Luật | Trọng số sinh | Nối truyện |
|---|---|---|---|---|
| 1 | **Ống Tro** (`ash`) | cơ bản: hao năng lượng, nhặt Tinh Lõi | `beam` 5, `mis` 3, `orb` 4 | Chương 1 (lửa tắt thành tro) |
| 2 | **Thung Gió Ngược** (`wind`) | gió đổi chiều theo đợt | `beam` 2, `mis` 2, `orb` 4 | Chương 2 (gió đứng lại) |
| 3 | **Hang Sét Câm** (`thunder`) | tia quét + cổng có khe | `swp` 4, `gate` 4, `beam` 1, `mis` 1, `orb` 3 | Chương 3 ("Sét Câm") |
| 4 | **Lòng Lò Nứt** (`abyss`, J4) | sàn dung nham, nhiều lõi | `beam` 3, `mis` 3, `orb` 3 | Lò Mẹ (Chương 1) |

- **Gió:** chu kỳ 5 s: 0–1.5 s im (mũi tên mờ báo trước từ 0.2 s), 1.5–3.5 s gió `wind_accel` 1300 px/s² lên / xuống
  (đổi chiều xen kẽ), 3.5–5 s im. Gió không tác động Robo.
- **Dung nham:** chạm sàn = trúng + nảy vy −900 + bất tử ≥ 0.8 s; vùng này chỉ ra hộp Rồng.
- Chớp sáng vùng 3 là trang trí, tắt được trong Cài đặt.

## 7. Vật cản, vật phẩm, điểm

| Loại | Tên hiển thị | Mô tả | Va chạm |
|---|---|---|---|
| `beam` | Thanh Cặn | thanh 2 nút, cố định theo thế giới; góc 0° / 90° / ±45°, nửa dài 110–210, tâm y 260–740 | đoạn thẳng + 13 px |
| `mis` | Cặn Phóng | báo trước 1.0 s ở mép phải, lao ngang (cuộn + 650 px/s), y 200–800 | tròn 28 px |
| `swp` | Tia Quét | thanh dọc dao động, nửa dài 130, biên độ 150–250 | đoạn dọc + 13 px |
| `gate` | Van Sét | hai khối trên / dưới, khe 300 px, rộng 70, tâm khe 300–700 | chữ nhật |
| `orb` | Hạt Tinh | +1, hàng 6 hạt cách 70 px (thẳng / gợn sóng biên độ 80) | |
| `core` | Tinh Lõi | +30 năng lượng; xác suất sau mỗi cụm 0.30, +0.30 nếu năng lượng < 40, +0.20 ở vùng 4 | |
| `box` | Hộp Ký Ức | +10 hạt, biến hình | |

- Bán kính va chạm hiệu dụng = 0.8 × hurtbox. Vật cản **tím trung tính**; Tinh Lõi cyan `#6FD3FF`; Hộp hồng `#FF9BD8`.
- **Điểm** = m + 5 × hạt. `accuracy = 0.6 × orb_ratio + 0.4 × hp_left_ratio`; hạng như khung.
- **Vô tận:** hạng theo `distance_m / clear_m`: S ≥ 2.0, A ≥ 1.5, B ≥ 1.2, C ≥ 1.0. Kỷ lục = mét.
- `stats`: `accuracy`, `distance_m`, `distance_ratio`, `hits_taken`, `hp_left_ratio`, `orb_ratio`, `cores_collected`,
  `forms_used`, `zones_passed`.

## 8. Các ải

| Ải | Dài | `scroll_base` | Vùng | Có gì |
|---|---|---|---|---|
| N-1 | 800 m | 500 | 1 | Thanh Cặn, hạt, lõi; không Cặn Phóng, không hộp |
| N-2 | 1200 m | 560 | 1 → 2 | + Cặn Phóng, hộp (Rồng); gió từ 600 m |
| N-3 | 1600 m | 620 | 1 → 2 → 3 | + Tia Quét, Van Sét; Robo mở |
| N-4 | 2000 m | 680 | 2 → 3 (→ 4 khi có J4) | trộn đủ |
| N-5 boss | 2400 m | 740 | 1 → 3 (→ 4) | cố định, **Vầng Khuyết** ném Cặn Phóng / Van Sét |

- Phản ứng `1650 / tốc độ cuộn`: 3.17 s ở 520, 1.65 s ở 1000; Cặn Phóng thêm 1.0 s báo trước.
- Boss: sprite `rh_boss_eclipse`, vành tô **cyan** bằng code (phân biệt với bản Nhịp điệu); vật ném có `from_boss`
  (hiệu ứng ném 0.25 s); thanh HP boss = quãng đường còn lại.
- Sao mẫu: N-1 `["clear", "stat:orb_ratio>=0.80", "stat:hits_taken==0"]`; N-2…N-4 `["clear", "rank>=A", "stat:forms_used>=1"]`;
  N-5 `["clear", "rank>=B", "stat:hits_taken<=2"]`.
- **Vô tận:** mục "Vô tận (đổi vùng)" + "Luyện vùng 1 / 2 / 3"; seed theo ngày; khóa `endless:all`, `endless:zone_<n>`;
  dùng chung hạn mức với `jet`.

## 9. Hướng dẫn (lần đầu, `data/jet/tutorial.json`)

Như Nhịp điệu / Chạy. N-1: giữ bay chạm hàng hạt cao → thả rơi nhặt hàng thấp → né Thanh Cặn → (năng lượng ~40 %)
một Tinh Lõi + dòng giải thích. N-2: Cặn Phóng (mũi tên báo), hộp luôn Rồng, gió. N-3: hộp đầu tiên là Robo. Không vật
trước giây 2.0. Cờ ở `data["minigames"]["tutorials"]["jet"]`.

## 10. Dữ liệu

```text
data/jet/jet_rules.tres            JetRules
data/jet/zones.json                vùng: trọng số, bảng màu, khóa biểu ngữ, hình cho phép
data/jet/levels/<level_id>.json    level ải (bake sẵn, trong git, sửa tay được)
data/jet/tutorial.json
scripts/minigame/jet/              jet_stage.gd, jet_generator.gd, jet_validator.gd, (jet_bot.gd)
tools/jet/bake_levels.gd           godot --headless -s
```

Một bộ sinh (`JetGenerator`, xorshift32) dùng cho cả Vô tận lúc chạy và bake level. Level:
`{"format":1, "level_id", "length_m", "scroll_base", "scroll_ramp", "zones":[{"from_m","id"}], "bpm", "bgm", "boss",
"events":[{"d", "type", ...}]}`; `d` = mét lúc vật tới nhân vật (Cặn Phóng: lúc hiện cảnh báo).

## 11. Ràng buộc công bằng (`JetValidator`)

| Ràng buộc | Giá trị |
|---|---|
| Hành lang trống mỗi cụm | ≥ 91 px (2 × 38.6 + 40) |
| Bước chuyển giữa hai hành lang | ≤ 0.7 × quãng đi được trong Δt (bảng mục 4) |
| Van Sét | khe 300, tâm 300–700, hai van cách ≥ 1.2 s |
| Cặn Phóng | không phóng khi còn van trong 1.0 s; ≤ 2 mũi tên cùng lúc |
| Tinh Lõi | cách nhau ≤ 900 m (N-1, N-2), ≤ 1200 m sau đó |
| Không vật trước | 2.0 s |
| Vật hoạt động | ≤ 30 |

## 12. Giao diện, hình, âm thanh

- HUD: tim, mét, hạt; tên vùng + tiến độ tới vùng kế (Vô tận); thanh năng lượng (đỏ < 25 %); thanh thời gian hình +
  tên hình; gợi ý thao tác.
- Bộ Phụt hiển thị mức nạp trực tiếp trên lưng (lớp vẽ riêng, không vẽ vào frame nhân vật).
- **Ảnh cần (v1):** Bộ Phụt + lửa phụt (tô theo nguyên tố), vệt bay, Tinh Lõi, Hộp Ký Ức, **Rồng** (cưỡi), **Robo**,
  Thanh Cặn, Cặn Phóng + cảnh báo, Tia Quét, Van Sét, mũi tên gió, biểu tượng 2 hình, nền 3 vùng × 3 lớp. Viết
  `JET_ART_BRIEF.md` theo mẫu `RHYTHM_ART_BRIEF.md` khi bắt đầu J2.
- Âm: phụt (cao độ tăng khi năng lượng thấp), nhặt hạt / lõi, biến hình, vỡ hình, trúng, cảnh báo, đổi vùng.

## 13. Kiểm thử

Vật lý (lên thực 1400, kẹp 900 / 1100, lơ lửng 6.8 ± 0.1 s, chỉ hồi khi đứng đất không giữ không biến hình); biến hình
(điều khiển, thời gian, đỡ một cú, Robo nghiền không sát thương, hộp làm mới); vùng (chu kỳ gió, Robo không bị gió, nghỉ
≥ 1000 px); vật cản (hình học, báo trước 1.0 s, không trúng hai lần khi bất tử); điểm / hạng; validator chứng minh hành
lang cho mọi level trong git + 1000 seed Vô tận; bộ sinh cùng seed cùng chuỗi; level JSON sai bị từ chối; khung.

## 14. Lộ trình (M11-5)

Đã làm (2026-11-20): `JetRules`, `JetLevel`, `JetSim`, `JetGenerator`, `JetValidator`, `JetBot` (`scripts/minigame/jet/`),
`JetStage`, `JetEndlessScreen` (`scripts/ui/jet/`), 5 ải bake bằng `tools/jet/bake_levels.gd` từ
`data/jet/baked_levels.json`, vùng ở `data/jet/zones.json`, Vô tận đổi vùng + luyện 3 vùng (seed theo ngày). Khác bản
trên: chu kỳ gió và dao động Tia Quét tính theo **quãng đường** (không theo giờ) để bộ sinh biết trước chỗ gió / vị trí
thanh; level lưu thêm `path` (đường giữa hành lang) cho validator và bot; bot bắt buộc (qua 5 ải + 20 seed Vô tận
6000 m, 0 lần trúng). Rồng / Robo / Bộ Phụt vẽ tạm bằng code. Chưa làm: hướng dẫn trong ải (`data/jet/tutorial.json`),
vùng 4 dung nham, nhạc, hình thật (J5).

Hình thật đã ghép (2026-11-22): `scripts/ui/jet/jet_art.gd` (`JetArt`: nạp ảnh `assets/jet/`, cột Van Sét co về 70 px, lửa phụt đổi
thang xám để tô màu nguyên tố) + `JetStage` (nền 4 lớp theo vùng cuộn 0.2 / 0.4 / 1.0, lớp mid làm tối 22%, chuyển vùng mờ dần 1.2 s;
Bộ Phụt + khe đo năng lượng + lửa; sprite Rồng / Robo, người ngồi đúng yên đo từ ảnh; hiệu ứng vỡ, hộp mở; Thanh Cặn, Tia Quét,
Van Sét, Cặn Phóng + cảnh báo, mũi tên gió, Hạt Tinh, Tinh Lõi, Hộp Ký Ức; biểu tượng hình ở HUD). Ảnh thẻ chế độ:
`material_events.json` `jet.card.art` → `assets/jet/jet_card.png`. Còn: nền mid Hang Sét Câm có quầng đen ngả xanh lá (xem nhật ký).

| Mốc | Nội dung | Xong khi |
|---|---|---|
| J0 | `JetRules`, `FixedStep`, chạy + phụt + năng lượng, `jet_hold` | test vật lý xanh |
| J1 | Thanh Cặn, Hạt Tinh, Tinh Lõi, tim, HUD | N-1 viết tay chơi được → **owner thử cảm giác bay** |
| J2 | Rồng, Robo, Cặn Phóng, hộp | N-2 viết tay chơi được |
| J3 | Vùng 2–3, biểu ngữ, `JetGenerator`, `JetValidator` (+ bot nếu kịp) | N-1…N-4 bake ra, validator xanh |
| J4 | Hướng dẫn, boss N-5, Vô tận + luyện vùng, vùng 4 dung nham, nối khung | chơi qua hub |
| J5 | Hình thật, âm thanh, trợ năng, cân bằng | owner duyệt |

## 15. Quyết định mở

| Mã | Câu hỏi | Mặc định |
|---|---|---|
| OD-J1 | Vô tận `cleared` | `distance_m ≥ 1500` |
| OD-J2 | Giữ năng lượng | Giữ |
| OD-J3 | Hurtbox tròn cố định | Dùng |
| OD-J4 | Chỉ số nhân vật | Không ảnh hưởng |
| OD-J5 | Level ải bake sẵn | Có |
| OD-J6 | Số vùng | 3 ở v1, vùng 4 ở J4 |
| OD-J7 | Biến hình đỡ mấy cú | 1 |
| OD-J8 | Một nút, nghĩa đổi theo hình | Giữ, bù bằng biểu tượng + gợi ý |
| OD-J9 | Checkpoint | Không |
| OD-J10 | Bay và Chạy có trùng không | Khác: bay một nút + năng lượng + biến hình, không đổi người |
| OD-J11 | Đảo Chiều | Để sau; nếu làm, gắn truyện với Yomigari (cảm được "mép" của Thực) thay vì sức của boss |
| OD-J12 | Bộ đồ bảo hộ | Hoãn sau J5 (`JET_COSTUME_BRIEF.md`) |
