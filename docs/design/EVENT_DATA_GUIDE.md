# Hướng dẫn sửa dữ liệu ải nguyên liệu — `data/events/material_events.json`

Một file chứa **toàn bộ** ải Event nguyên liệu: danh sách chế độ, từng ải, cách chơi, sao, phần thưởng, lượt có thưởng.
Owner sửa trực tiếp, không cần sửa code. Khung đọc file này: `docs/design/MATERIAL_EVENT.md`.

## 1. Sửa xong thì làm gì

1. Lưu file (UTF-8). Chạy game từ Godot (F5), vào **Xuất kích → Ải nguyên liệu**. Game đọc lại file **mỗi lần mở màn**
   Ải nguyên liệu / chọn ải / danh sách bài, nên đang chạy cũng được: thoát ra sảnh rồi vào lại.
2. Ghi sai (thiếu dấu phẩy, số ngoài khoảng, vật phẩm không có…) thì màn Ải nguyên liệu hiện dòng **cam** ở trên:
   "File material_events.json có N lỗi, lỗi đầu: …". Đủ danh sách lỗi trong cửa sổ Output của Godot.
3. Kiểm tra toàn bộ: `powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1` (test `test_shipped_event_data_is_valid`
   báo mọi lỗi của file).
4. Bản phát hành đóng gói file này; muốn đổi mà không phát hành bản mới thì sau này đồng bộ qua máy chủ (chưa làm).

## 2. Cấu trúc

```
events[]                     một event (hiện có "evt_material")
  modes[]                    chế độ: "rhythm" (5 ải), "rhythm_endless" (Vô tận)
    limit                    lượt có thưởng (mục 6)
    stages[]                 các ải (chỉ chế độ dạng đồ thị)
      thông tin              id, code, title_key, pos, requires, party_min
      params                 CÁCH CHƠI: music, speed, spawn, guide, boss (mục 3)
      stars                  3 điều kiện sao (mục 4)
      rewards                phần thưởng (mục 5)
    endless.by_difficulty    Vô tận: params + rewards cho từng độ khó (mục 7)
```

## 3. Cách chơi — `params` (Nhịp điệu)

| Trường | Ý nghĩa | Khoảng an toàn | Hiện tại |
|---|---|---|---|
| `music.song` | id bài trong `server/music/songs.json` | bài có trong danh mục | N-1 `song_ember_steps` … N-5 `song_eclipse_boss` |
| `music.chart` | bản nốt gốc | `easy` / `normal` / `hard` / `boss` | easy, normal, hard, hard, boss |
| `speed.note_speed` | **tốc độ quái chạy tới** (px / giây). Nhanh hơn = ít thời gian nhìn; vòng chấm tự to theo nên Perfect vẫn ±21 ms | 300 – 2000 | 550, 750, 850, 950, 1050 |
| `speed.song_speed` | **tốc độ vượt ải** = tốc độ cả bài. 1.2 = bài nhanh hơn 20 %: qua ải nhanh hơn, quái tới dày hơn theo thời gian; nhạc cao giọng hơn | 0.5 – 2.0 | 1.0 |
| `spawn.density` | **mật độ sinh quái**: tỉ lệ nốt của bản nốt được giữ (rải đều). 0.5 = còn một nửa số quái | 0.1 – 1.0 | 1.0 |
| `spawn.min_gap_sec` | khoảng cách tối thiểu giữa hai quái liên tiếp (giây). 0 = theo bản nốt | 0 – 2 | 0 |
| `spawn.kinds` | loại quái cho phép: `tap` (ấn), `hold` (Rắn Ngân), `mash` (quái trống); loại khác đổi thành quái ấn. `[]` = tất cả | | N-1 `["tap"]`, còn lại `[]` |
| `guide.tutorial` | hướng dẫn trong ải lần đầu chơi | true / false | chỉ N-1 |
| `guide.intro_key` | dòng giới thiệu lúc đếm ngược lần đầu chơi (khóa dịch) | khóa có trong `localization/*.po` | N-2 `RHYTHM_INTRO_HOLD` |
| `boss` | hiện boss Vầng Khuyết | true / false | chỉ N-5 |

Muốn **nhiều quái hơn** bản nốt hiện có: đổi `music.chart` sang bản khó hơn (`normal` → `hard`). `density` chỉ bớt quái.
Hai quái cùng làn luôn cách nhau đủ để hitbox không đè (game tự bỏ nốt quá sát).

## 3b. Cách chơi — `params` (Chạy Nguyên Tố)

| Trường | Ý nghĩa | Khoảng an toàn | Hiện tại |
|---|---|---|---|
| `level.id` | file level `data/runner/levels/<id>.json` (vật cản, cổng, Hạt Tinh, tốc độ gốc, độ dài) | file có thật, hợp lệ | `runner_mat_01` … `03` |
| `speed.multiplier` | **tốc độ vượt ải**: nhân tốc độ chạy của level (1.2 = nhanh hơn 20 %, ít thời gian nhìn vật hơn) | 0.5 – 2.0 | 1.0 |
| `guide.intro_key` | dòng giới thiệu lúc đếm ngược lần đầu chơi (khóa dịch) | khóa có trong `localization/*.po` | `RUNNER_N1_INTRO` … |

Sửa **vật cản** (thêm / bớt Cặn, hố, cổng, hạt): sửa file level. Mỗi dòng trong `events` là một vật:
`{"t": giây vật chạm người chạy, "type": "hurdle" | "pit" | "flyer" | "gate" | "orbs", ...}` (chi tiết:
`docs/design/RUNNER_MODE.md` mục 9). Không đặt vật trước giây 2.0; cổng chỉ dùng ô trong `slots_used`. Sai thì hub
hiện dòng lỗi. Luật chung (độ cao nhảy, HP, sát thương, điểm, Fever, mốc hạng) ở `data/runner/runner_rules.tres`
(mở bằng Godot, bảng Inspector).

## 4. Sao — `stars` (đúng 3 điều kiện)

| Viết | Nghĩa |
|---|---|
| `clear` | qua ải |
| `rank>=A` | hạng A hoặc S (S > A > B > C > D) |
| `score>=30000` | điểm ≥ 30 000 |
| `stat:accuracy>=0.90` | chính xác ≥ 90 % (tỉ lệ ghi 0..1) |
| `stat:miss==0` | không Miss / Sai |
| `stat:max_combo>=150` | combo cao nhất ≥ 150 |
| `stat:perfect_ratio>=0.8` | ≥ 80 % Perfect |
| `stat:hp_left_ratio>=0.5` | HP còn ≥ 50 % |
| `stat:holds_broken==0` | không gãy Rắn Ngân |
| `stat:hits_taken==0` | (Chạy) không bị trúng lần nào |
| `stat:collect_ratio>=0.80` | (Chạy) nhặt ≥ 80 % Hạt Tinh |
| `stat:perfect_swap_ratio>=0.50` | (Chạy) ≥ 50 % cổng là Perfect (đổi người trong 0.3 s trước cổng) |
| `stat:perfect_swaps>=5` | (Chạy) ≥ 5 cổng Perfect |

Toán tử: `>=`, `<=`, `==`. Đổi điều kiện không làm mất sao người chơi đã có.

## 5. Phần thưởng — `rewards`

| Trường | Khi nào nhận |
|---|---|
| `base` | mỗi lần qua ải (lượt có thưởng), nhân `rank_mult` theo hạng (`captain_exp` không nhân) |
| `first_clear` | lần qua đầu tiên |
| `star_bonus."2"`, `star_bonus."3"` | lần đầu đạt sao 2 / sao 3 |
| `rank_mult` | hệ số theo hạng, phải có đủ S, A, B, C, D |

Mỗi gói thưởng: `gold`, `gems`, `captain_exp` (EXP người quản lý), `materials` {id: số}. Id vật phẩm: `mat_exp_small`,
`mat_exp_medium`, `mat_exp_large` (sách EXP), `mat_enhance_ore`, `mat_enhance_crystal` (cường hóa), `mat_weapon_ascend`,
`mat_affix_reroll`. Danh sách đầy đủ: `powershell -ExecutionPolicy Bypass -File tools\give_gift.ps1 --list`.

## 6. Lượt có thưởng — `limit` (mỗi chế độ)

`{"period": "weekly", "max": 50, "reset_hour": 4}`: 50 lượt có thưởng mỗi tuần, làm mới 4 giờ sáng thứ Hai. `"daily"` =
mỗi ngày; `{"period": "none"}` hoặc bỏ trường = không giới hạn. Hết lượt vẫn chơi được, không thưởng, không ghi sao.
`{"share_with": "rhythm"}` = dùng chung bộ đếm với chế độ khác (Vô tận dùng chung với 5 ải).

## 7. Vô tận — `endless`

`difficulties`: các tab độ khó; `stars`: 3 sao chung mọi bài; `by_difficulty.<độ khó>`: `params` (`speed`, `spawn` như
mục 3; bài và bản nốt lấy theo bài người chơi chọn) và `rewards`.

**Vô tận Chạy Nguyên Tố** (`runner_endless`): `endless.routes` là danh sách tuyến (`id`, `title_key`, `seed`; thêm tuyến =
thêm dòng với seed mới), `endless.party_min` (3). `by_difficulty.<độ khó>.params.gen`:

| Trường | Ý nghĩa | Khoảng an toàn | Dễ / Thường / Khó |
|---|---|---|---|
| `speed` | tốc độ chạy (px / giây) | 300 – 1500 | 700 / 850 / 1000 |
| `length_sec` | độ dài tuyến (giây) | 30 – 300 | 120 / 150 / 180 |
| `gate_gap` | khoảng cách tối thiểu giữa hai cổng (giây) | 0.5 – 3 | 1.0 / 0.8 / 0.6 |
| `overlap` | cổng được trùng Cặn Thấp (đổi + nhảy cùng lúc) | true / false | false / true / true |

Level của tuyến sinh lúc chơi từ seed (cùng tuyến + độ khó luôn ra cùng level). Level N-4, N-5 sinh bằng máy từ
`data/runner/generated_levels.json` rồi ghi file (lệnh trong dòng `_huong_dan` của file đó).

**Bay Nguyên Tố** (`jet`): `params.level.id` = file `data/jet/levels/<id>.json` (sinh bằng
`tools/jet/bake_levels.gd` từ `data/jet/baked_levels.json`: độ dài, tốc độ cuộn, vùng, loại vật, hình hộp), `params.guide.intro_key`.
Luật chung (bay, năng lượng, tim, Rồng, Robo, gió) ở `data/jet/jet_rules.tres`; vùng (màu, trọng số vật, hình) ở
`data/jet/zones.json`. Khóa sao: `stat:orb_ratio`, `stat:hits_taken`, `stat:forms_used`, `stat:distance_m`,
`stat:cores_collected`, `stat:zones_passed`, `stat:hp_left_ratio`, `stat:accuracy`.

**Vô tận Bay** (`jet_endless`): `endless.entries` (mục "all" + luyện vùng, `practice: true` = không tốn lượt, không
thưởng), `endless.params.endless`: `scroll_base` (300–1000), `scroll_ramp` (0–1), `zone_length_m` (100–3000);
`endless.rewards` (một bộ, hạng theo mét bay: S ≥ 3000, A ≥ 2250, B ≥ 1800, C ≥ 1500).

## 8. Thông tin ải

| Trường | Ý nghĩa |
|---|---|
| `id` | không đổi sau khi phát hành (save lưu theo id) |
| `code` | chữ trên nút (N-1…) |
| `title_key` | khóa dịch tên ải |
| `pos` | vị trí nút trên đồ thị, `[x, y]` từ 0 tới 1 |
| `requires` | ải phải qua trước (id) |
| `party_min` | số người tối thiểu trong đội để vào |

## 9. Thử nhanh

Gói quà thử nghiệm (bảng "Quà thử nghiệm" ở tab Cài đặt của sảnh, bản debug; xem `docs/DEBUG_GIFT.md`):
`event_open` mở mọi ải + Vô tận, `event_open_to_boss` mở tới N-5, `event_plays` đặt lại lượt có thưởng.
