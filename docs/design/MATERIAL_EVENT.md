# Event nguyên liệu — khung mini game dùng chung (M11)

> **Tình trạng:** bản thiết kế lại ngày 2026-11-18 (Claude) từ đề xuất `MINIGAME_EVENTS.md` của owner (2026-11-17),
> đối chiếu với code, dữ liệu và cốt truyện canon hiện có. Mục 0 ghi những gì đã đổi và lý do. Mọi số là giá trị khởi
> đầu, nằm trong dữ liệu.
>
> Tài liệu liên quan: `RHYTHM_MODE.md` (chế độ 1, đã chạy), `RUNNER_MODE.md` (chế độ 2), `JET_MODE.md` (chế độ 3),
> `EVENT_STORY.md` (cốt truyện + chữ của event), `JET_COSTUME_BRIEF.md` (trang phục, hoãn).

Mục tiêu (owner 2026-11-17): **Event nguyên liệu** là tính năng thường niên, có **nhiều dạng ải** để người chơi không
nhàm. Nhịp điệu (M10) là dạng đầu tiên; các dạng sau dùng chung khung này.

## 0. Thay đổi so với bản đề xuất

| # | Bản đề xuất | Bản này | Lý do |
|---|---|---|---|
| 1 | Tên nhân vật Aether / Lyra / Kael / Seraphine / Noctis / Terra | Enkiba / Kazeyumi / Raikiba / Hikarine / Yomigari / Iwagane; code dùng Data ID | Tên mới đã chốt (AGENTS mục 3); tên cũ không dùng cho chữ hiển thị |
| 2 | Item `mat_exp_s`, `gem`; thưởng tung ngẫu nhiên `min`–`max` | Id thật (`mat_exp_small`…, tiền `gold` / `gems`); **số cố định** như ải cốt truyện và Nhịp điệu hiện tại; `min`/`max` để dành | Khớp `data/items/`, `PlayerProfile.grant`; thưởng cố định dễ cân bằng, dễ hiển thị "Có thể rơi" |
| 3 | `rank_mult` S 1.5 · A 1.25 · B 1.0 · C 0.75 · D 0.5 | Giữ như Nhịp điệu đang chạy: S 1.5 · A 1.25 · B / C / D 1.0 | Không giảm thưởng của người chơi đã quen; đổi bằng dữ liệu nếu owner muốn |
| 4 | Vô tận không giới hạn | Vô tận **chơi không giới hạn**, nhưng **thưởng** chỉ tính trong hạn mức tuần của chế độ (mục 7) | Thưởng Vô tận hiện không giới hạn = cày vô hạn nguyên liệu |
| 5 | Scene chơi đặt `physics_ticks_per_second = 120` | Mỗi chế độ tự chạy **bước cố định 1/120 s bằng bộ tích lũy** trong `_process` | Đổi cài đặt dự án ảnh hưởng toàn bộ combat của game chính |
| 6 | Va chạm hình học tự viết | Giữ, ghi thành quyết định: luật Hitbox / Hurtbox (AGENTS mục 3) áp cho **combat**; mini game không có đòn đánh nên dùng hình học đơn giản trong dữ liệu (Nhịp điệu đã làm vậy) | Tránh mâu thuẫn với AGENTS |
| 7 | Scene ở `res://scenes/rhythm/…`, chữ ở `translations/` | Scene ở `scenes/main/minigame/…`, chữ ở `localization/vi.po` + `en.po` (thêm bằng `tools/add_locale_keys.py`) | Cấu trúc repo thật |
| 8 | Rhythm "bọc, không viết lại" nhưng `RhythmStage` tự ghi save, tự phát thưởng | Adapter chạy `RhythmStage` với `record_key = ""` (không ghi save, không thưởng), lấy `result` rồi chuyển cho khung | Hợp đồng khung: scene chơi không ghi save |
| 9 | Hướng dẫn: cờ chung chưa có chỗ lưu | `data["minigames"]["tutorials"]` chốt ở mục 9 cho cả ba chế độ; Nhịp điệu bỏ cách cũ "chưa qua N-1 thì hiện" | Một cơ chế cho mọi chế độ |
| 10 | Cốt truyện riêng từng chế độ (Mạch Nguyên Tố, Thợ Lõi, Quầng…) | Gộp về thế giới canon: Mặt Trời Khuyết, Vùng Thực, Cặn, Neo / NEO; event diễn ra ở các **Vết Khuyết** (`EVENT_STORY.md`) | `STORY_PROPOSAL.md` đã có thế giới quan canon; README không còn là nguồn duy nhất |
| 11 | Boss ba chế độ tên "Nhật Thực" | Đề xuất đổi thành **Vầng Khuyết** (mảnh bóng của Mặt Trời Khuyết) | "Nhật Thực" là tên Chương 7 và tên phản ứng Quang + Ám (canon) |
| 12 | Ba chế độ làm song song | Thứ tự: **khung → Chạy Nguyên Tố → Bay Nguyên Tố** (mục 14) | Chạy dùng frame sẵn có + đúng chủ đề "trao lượt"; Bay cần nhiều hình mới nhất |
| 13 | Đội 3 người coi như luôn có | Ải đòi đổi nhân vật ghi `party_min`; đội chưa đủ thì nút Chơi mờ, ghi lý do | Game mới chỉ có Enkiba (`STARTER_CHARACTERS`) |

## 1. Nguyên tắc kiến trúc

1. **Hub và màn chọn ải không biết luật chơi.** Chỉ đọc dữ liệu, gọi scene chơi, nhận `MinigameResult`.
2. **Dữ liệu, không cứng trong code.** Ải, vị trí nút, thưởng, sao, hạn mức nằm trong JSON / `.tres`.
3. **Mỗi chế độ tự định nghĩa `params` và `stats`.** Hub không đọc `params`; bộ chấm sao chỉ đọc `stats`.
4. **Bọc, không viết lại** Nhịp điệu (`RhythmJudge`, `RhythmRules`, `RhythmChart` giữ nguyên).
5. **Offline-first.** Chạy từ dữ liệu trong game; máy chủ chỉ tải nhạc (đã có) và sau này danh mục event.
6. **Số trong dữ liệu**, mọi chữ qua `tr()`, dữ liệu chỉ giữ khóa `*_key`.
7. **Không phụ thuộc chỉ số chiến đấu**: mini game đo kỹ năng; cấp, ATK, trang bị không ảnh hưởng.

## 2. Luồng

```
Xuất kích → thẻ "Ải nguyên liệu" (đổi tên "Event nguyên liệu") → EventHubScreen (thẻ các chế độ)
          → StageSelectScreen (đồ thị ải; hoặc danh sách nếu layout "list")
          → kiểm tra mở khóa, đội đủ người, hạn mức → (tải tài nguyên nếu cần) → scene chơi của chế độ
          → MinigameResult → MinigameProgress.submit → RewardService → MinigameResultScreen
          → Chơi lại / Về chọn ải / Thoát
```

- Thẻ chế độ bị khóa / hết lượt / hết hạn vẫn hiện, làm mờ, ghi lý do (mở khi nào, reset sau bao lâu).
- Nhịp điệu giữ 2 kiểu: N-1…N-5 dạng đồ thị và **Vô tận** dạng danh sách bài (`RhythmSongListScreen` hiện có làm provider).
- Hướng dẫn trong ải do từng chế độ tự làm; khung chỉ truyền `is_first_play`.

## 3. Thư mục và lớp

```text
data/events/material_events.json          dữ liệu event (mục 4)
scripts/minigame/
  minigame_stage.gd        lớp cơ sở scene chơi (mục 5)
  minigame_context.gd      tham số đưa vào scene
  minigame_result.gd       kết quả trả ra
  minigame_registry.gd     mode id → scene, provider, danh sách khóa stats hợp lệ
  minigame_progress.gd     bản ghi, sao, hạn mức, cờ hướng dẫn (thay RhythmProgress)
  star_evaluator.gd        chấm sao (mục 6)
  limit_tracker.gd         hạn mức, chu kỳ reset (mục 7)
  reward_service.gd        tính và phát thưởng (mục 8)
  fixed_step.gd            bộ tích lũy bước cố định dùng chung (Chạy, Bay)
  event_validator.gd       kiểm tra JSON lúc nạp (mục 12)
scripts/ui/events/          event_hub_screen.gd, stage_select_screen.gd, minigame_result_screen.gd
scripts/ui/rhythm/rhythm_minigame_adapter.gd
scenes/main/minigame/       *.tscn của các màn trên và scene chơi
```

## 4. Dữ liệu — `data/events/material_events.json`

```json
{
  "format": 1,
  "events": [
    {
      "id": "evt_material",
      "title_key": "EVENT_MATERIAL_TITLE",
      "category": "material",
      "schedule": { "kind": "always" },
      "modes": [
        {
          "id": "rhythm",
          "title_key": "MODE_RHYTHM_TITLE",
          "scene": "res://scenes/main/minigame/rhythm_minigame_adapter.tscn",
          "layout": "graph",
          "limit": { "period": "weekly", "max": 50, "reset_hour": 4 },
          "stages": [
            {
              "id": "rhythm_mat_01",
              "title_key": "RHYTHM_STAGE_01_NAME",
              "pos": [0.12, 0.55],
              "requires": [],
              "party_min": 1,
              "stars": ["clear", "stat:accuracy>=0.90", "stat:miss==0"],
              "rewards": {
                "base":        { "gold": 1500, "captain_exp": 300, "materials": { "mat_exp_small": 8, "mat_exp_medium": 1 } },
                "first_clear": { "gems": 50, "materials": { "mat_exp_medium": 3 } },
                "star_bonus":  { "2": { "materials": { "mat_exp_small": 2 } }, "3": { "materials": { "mat_exp_medium": 1 } } },
                "rank_mult":   { "S": 1.5, "A": 1.25, "B": 1.0, "C": 1.0, "D": 1.0 }
              },
              "params": { "song": "song_ember_steps", "chart": "easy", "note_speed": 550, "kinds": ["tap"], "tutorial": true }
            }
          ]
        },
        {
          "id": "rhythm_endless",
          "title_key": "RHYTHM_ENDLESS_TITLE",
          "scene": "res://scenes/main/minigame/rhythm_minigame_adapter.tscn",
          "layout": "list",
          "unlock": { "requires_stage_cleared": "rhythm/rhythm_mat_05" },
          "limit": { "share_with": "rhythm" },
          "stages_provider": "rhythm_library"
        }
      ]
    }
  ]
}
```

- Thưởng dùng **đúng dạng** `PlayerProfile.grant` (`gold`, `gems`, `captain_exp`, `materials`, `exp`), nên không cần đổi
  kho đồ. `params` của Nhịp điệu lấy từ `data/rhythm/material_stages.json` hiện tại (chuyển sang, mục 9.2).
- `party_min`: số nhân vật tối thiểu trong đội để vào ải (mặc định 1).
- `limit.share_with`: chế độ dùng chung hạn mức của chế độ khác (Vô tận dùng chung với ải của chính nó).

| Cấp | Trường | Ý nghĩa |
|---|---|---|
| event | `schedule` | `{"kind":"always"}` hoặc `{"kind":"range","start":"2026-11-16","end":"2027-11-16","repeat":"yearly"}` |
| mode | `layout` | `graph` (đồ thị nút) hoặc `list` (provider cấp danh sách) |
| mode | `unlock` | `requires_stage_cleared` (`<mode>/<stage>`) hoặc rỗng |
| mode | `limit` | mục 7 |
| stage | `pos` | vị trí nút, tỉ lệ 0..1 trong vùng đồ thị; đường nối vẽ từ `requires` |
| stage | `stars` | đúng 3 điều kiện (mục 6) |
| stage | `params` | chỉ scene chơi đọc |

Thiếu `schedule` / `limit` / `unlock` = luôn mở, không giới hạn, không điều kiện. Đồng bộ danh mục qua máy chủ (giống
`/music/catalog.json`, cache + sha256) để sau; bản trong game là mặc định.

## 5. Hợp đồng khung ↔ scene chơi

```gdscript
class_name MinigameContext extends RefCounted
var event_id: String
var mode_id: String
var stage_id: String
var params: Dictionary        # chỉ scene chơi hiểu
var seed: int                 # cho chế độ có sinh tất định
var is_first_play: bool       # chưa xem hướng dẫn của chế độ này
var party: PackedStringArray  # Data ID đội hiện tại (Chạy dùng; Bay dùng ô 1)
var practice := false         # luyện: không tốn lượt, không thưởng

class_name MinigameResult extends RefCounted
var cleared: bool
var score: int
var rank: String              # "S" | "A" | "B" | "C" | "D"
var stats: Dictionary         # khóa theo mục 13
var duration_sec: float
var fail_reason := ""         # "hp_zero", "quit"

class_name MinigameStage extends Control
signal finished(result: MinigameResult)
func setup(ctx: MinigameContext) -> void
func start() -> void
func pause_game() -> void
func resume_game() -> void
```

- Scene chơi tự lo tạm dừng, đếm ngược, hướng dẫn, tải tài nguyên; phát `finished` **đúng một lần**; thoát giữa chừng =
  `cleared = false`, `fail_reason = "quit"`.
- Scene chơi **không** ghi save, không phát thưởng, không đọc hạn mức.
- Hạng do chế độ tính (cùng ngưỡng S ≥ 95 %, A ≥ 90 %, B ≥ 80 %, C ≥ 70 % cho mọi chế độ).
- `MinigameStage` kế thừa `Control` (như `RhythmStage`), để dùng cùng `SceneRouter` và lớp phủ tạm dừng.

## 6. Sao (3 sao / ải)

Cú pháp: `clear` | `rank>=<S|A|B|C|D>` | `score>=<số>` | `stat:<khóa><toán tử><giá trị>`, toán tử `>=`, `<=`, `==`.
`StarEvaluator` tự phân tích chuỗi (không dùng `Expression`).

- Ải thất bại: không sao nào được tính. Khóa `stat:` không có trong `stats` = không đạt (validator cảnh báo lúc nạp).
- Sao đã đạt không mất; `star_bonus[n]` phát **một lần** khi sao n lần đầu đạt.

## 7. Hạn mức lượt

| Trường | Giá trị | Ghi chú |
|---|---|---|
| `period` | `daily`, `weekly`, `none` | tuần bắt đầu thứ Hai |
| `max` | số lượt **có thưởng** mỗi chu kỳ | |
| `reset_hour` | 0–23, mặc định 4 | giờ máy |
| `share_with` | id chế độ | dùng chung bộ đếm |

- **Hết lượt vẫn chơi được** (luyện), chỉ không có thưởng và không ghi sao; nút Chơi đổi chữ "Chơi (không thưởng)".
  Nhờ vậy người chơi không bị chặn chơi mà vẫn không cày vô hạn.
- Tiêu 1 lượt khi chơi thật bắt đầu (sau đếm ngược, sau hướng dẫn); thua / thoát **không hoàn**; thoát lúc tải / đếm
  ngược / hướng dẫn không tốn.
- Chống lùi giờ: lưu `last_seen_unix`; giờ nhỏ hơn mốc đã lưu thì không reset. Đã có cloud save (M9-3) nên save gắn
  tài khoản; hiệu chỉnh bằng giờ máy chủ để sau (OD-M5).
- Số 50 / tuần là **đề xuất**, chờ owner (OD-M2).

## 8. Thưởng

```
phần thưởng = base × rank_mult[rank]     (làm tròn xuống, giữ tối thiểu 1 nếu gốc > 0; captain_exp không nhân)
            + first_clear                lần qua ải đầu tiên (một lần)
            + star_bonus[n]              mỗi sao n mới đạt lần này
```

- Đúng công thức `RhythmProgress.scaled_rewards` đang chạy (chuyển sang `RewardService`).
- "Có thể rơi" trên màn chọn ải sinh từ chính `rewards.base`. Thua hoặc hết lượt: không thưởng.

## 9. Save

```
data["minigames"] = {
  "records":   { "<mode_id>": { "<stage_id>": { "cleared", "stars": [b, b, b], "best_score", "best_rank",
                                                 "best_combo", "best_accuracy", "plays", "first_clear_claimed" } } },
  "limits":    { "<event_id>:<mode_id>": { "used", "period_key", "last_seen_unix" } },
  "favorites": { "<mode_id>": [ "<id>" ] },
  "tutorials": { "<mode_id>": { "<step_id>": true } }      // "<step_id>" vd "n1", "n2_intro"
}
```

- `SaveSchema.sanitize` thêm mục nếu thiếu, **không đổi version** (như M10 thêm `rhythm`); `records`, `limits`,
  `favorites`, `tutorials` là từ điển động.
- Chỉ `MinigameProgress` ghi `data["minigames"]`.

### 9.1 Di trú từ `data["rhythm"]` (idempotent, trong `sanitize`)

1. `minigames` chưa có **và** `rhythm` có: `records["rhythm_mat_0X"]` → `minigames.records.rhythm`;
   `records["endless:…"]` → `minigames.records.rhythm_endless` (giữ khóa); `favorites` → `favorites.rhythm_endless`.
2. Sao: `cleared` ⇒ sao 1; sao 2 / 3 suy được từ `best_accuracy` thì bật; còn lại `false`.
3. `first_clear_claimed = cleared`. Đã qua N-1 ⇒ `tutorials.rhythm.n1 = true`; đã qua N-2 ⇒ `tutorials.rhythm.n2_intro = true`.
4. **Giữ** `data["rhythm"]` ít nhất một bản phát hành rồi mới dọn (ghi `DEVELOPMENT_LOG.md`).

### 9.2 Adapter Nhịp điệu

`RhythmMinigameAdapter` (kế thừa `MinigameStage`) tạo `RhythmStage`, đặt `chart` / `song` / `note_speed` / `kinds` /
`tutorial` / `intro_key` từ `ctx.params`, đặt `record_key = ""` (không ghi save, không thưởng), ẩn lớp kết quả cũ, rồi
đổi `RhythmStage.result` thành `MinigameResult`:

| `RhythmStage.result` | `MinigameResult` |
|---|---|
| `cleared` | `cleared` |
| `score`, `rank` | `score`, `rank` |
| `accuracy`, `max_combo`, `counts` | `stats` (mục 13) |

`RhythmMaterialScreen` thay bằng `StageSelectScreen`; `material_stages.json` chuyển thưởng sang `material_events.json`
(công cụ chuyển một lần), phần bài / tốc độ thành `params`. Test hồi quy: cùng chuỗi phím + bản nốt cho cùng điểm, hạng,
độ chính xác trước và sau khi bọc.

## 10. Màn hình

- **`EventHubScreen`:** thẻ chế độ xếp ngang (ảnh thẻ theo `RHYTHM_ART_BRIEF.md` mục 3 ưu tiên 2, thiếu thì vẽ tạm),
  trạng thái Sẵn sàng / Khóa / Hết lượt (vẫn chơi được) / Hết hạn; ô lượt còn + đếm ngược reset.
- **`StageSelectScreen`:** `graph` vẽ nút theo `pos`, đường nối theo `requires`, nút đã qua hiện 3 sao; `list` dùng
  provider. Bảng thông tin bên phải: mô tả, Có thể rơi, lượt còn, `party_min`, nút **Chơi** (vùng chạm ≥ 128 px).
- **`MinigameResultScreen`:** hạng, điểm, 3 sao (sao mới sáng), thưởng thực nhận, kỷ lục mới; thống kê riêng qua nhãn
  `STAT_<KHÓA>`; nút Chơi lại / Về chọn ải / Thoát. Dùng chung mọi chế độ (kể cả Nhịp điệu qua adapter).

## 11. Tiêu chí cho chế độ mới

Thêm một chế độ chỉ được là: (a) thêm mục `modes[]` trong JSON, (b) một scene kế thừa `MinigameStage`, (c) khai báo
khóa `stats` trong `MinigameRegistry`. Phải sửa hub / màn chọn ải / `MinigameProgress` thì sửa khung trước.

## 12. Kiểm tra dữ liệu và test (GdUnit4)

`EventValidator` lúc nạp: id trùng, `scene` không có / không kế thừa `MinigameStage`, `requires` trỏ sai hoặc vòng,
ải không tới được, `stars` ≠ 3 hoặc sai cú pháp, `pos` ngoài [0,1], item / tiền không có trong `data/items/` (lỗi);
khóa `stat:` lạ, khóa dịch thiếu trong `vi.po` / `en.po` (cảnh báo).

Test: `StarEvaluator` (từng toán tử, thứ tự hạng, khóa thiếu, ải thua), `LimitTracker` (biên `reset_hour`, qua tuần,
lùi giờ, `share_with`, hết lượt vẫn chơi không thưởng), `MinigameProgress` (sao chỉ tăng, thưởng sao một lần,
`first_clear_claimed`), di trú (chạy 2 lần cùng kết quả, không mất `rhythm`, save không có `rhythm`), `RewardService`
(nhân hạng, làm tròn), hồi quy Nhịp điệu qua adapter, `EventValidator` (mỗi lỗi một JSON mẫu).

## 13. Khóa `stats` theo chế độ

| Chế độ | Khóa |
|---|---|
| `rhythm`, `rhythm_endless` | `accuracy`, `max_combo`, `perfect_ratio`, `miss` (Miss + Sai), `hp_left_ratio`, `holds_broken` |
| `runner`, `runner_endless` | `accuracy`, `max_combo`, `hits_taken`, `collect_ratio`, `perfect_swaps`, `perfect_swap_ratio`, `distance_ratio`, `hp_left_ratio` |
| `jet`, `jet_endless` | `accuracy`, `distance_m`, `distance_ratio`, `hits_taken`, `hp_left_ratio`, `orb_ratio`, `cores_collected`, `forms_used`, `zones_passed` |

`holds_broken` cần thêm một bộ đếm nhỏ trong `RhythmJudge` (phần cuối nốt giữ Miss); việc duy nhất chạm vào luật Nhịp điệu.

## 14. Lộ trình

| Mốc | Nội dung | Xong khi |
|---|---|---|
| M11-0 | `MinigameContext/Result/Stage`, `StarEvaluator`, `LimitTracker`, `FixedStep` + test | test xanh |
| M11-1 | `MinigameProgress`, di trú save, `RewardService` | test di trú, thưởng xanh |
| M11-2 | `RhythmMinigameAdapter`, chuyển `material_stages.json` → `material_events.json` | hồi quy Nhịp điệu xanh, N-1…N-5 + Vô tận chạy qua khung |
| M11-3 | `EventHubScreen`, `StageSelectScreen`, `MinigameResultScreen`, `EventValidator`; thẻ Xuất kích trỏ vào hub | owner duyệt luồng |
| M11-4 | Chạy Nguyên Tố (`RUNNER_MODE.md`) | thêm chế độ không sửa khung |
| M11-5 | Bay Nguyên Tố (`JET_MODE.md`) | như trên |
| M11-6 | Ảnh thẻ, âm thanh, bật hạn mức thật, đồng bộ danh mục máy chủ, trang phục event (nếu owner duyệt) | owner duyệt |

Không làm sẵn tính năng cho chế độ chưa tồn tại; mỗi chế độ mới là phép thử của khung.

## 15. Quyết định mở

| Mã | Câu hỏi | Mặc định đề xuất |
|---|---|---|
| OD-M1 | Khi nào tiêu lượt, có hoàn khi thua | Tiêu khi bắt đầu chơi thật; không hoàn |
| OD-M2 | Hạn mức mỗi chế độ | 50 lượt có thưởng / tuần / chế độ (Vô tận dùng chung với ải); hết lượt vẫn chơi không thưởng |
| OD-M3 | Thêm tài nguyên thể lực | Chưa; `cost` không dùng |
| OD-M4 | Số sao mỗi ải | 3 |
| OD-M5 | Hiệu chỉnh giờ bằng máy chủ | Để sau; chỉ chặn lùi giờ |
| OD-M6 | Event thường niên đổi nội dung theo năm | Cố định; `repeat: "yearly"` để dành |
| OD-M7 | `rank_mult` | Giữ S 1.5 / A 1.25 / còn lại 1.0 như hiện tại |
| OD-M8 | Đổi tên boss chung thành **Vầng Khuyết** (cả ải N-5 Nhịp điệu đang chạy) | Đổi (`EVENT_STORY.md` mục 3) |
| OD-M9 | Thứ tự làm | Khung → Chạy → Bay |

## 16. Giấy phép và tài nguyên

Ảnh thẻ, icon, nền đồ thị là thiết kế riêng; ảnh AI ghi `docs/ASSET_LICENSES.md` mục 2.1. Chưa có ảnh dùng
`placeholder_*` / vẽ bằng code. Không thêm plugin / thư viện ngoài.
