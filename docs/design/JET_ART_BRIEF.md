# Bay Nguyên Tố — mô tả hình và prompt tạo ảnh (M11-5, J5)

Dùng cho owner / họa sĩ / Codex imagegen. Theo `JET_MODE.md` mục 12 và `EVENT_STORY.md` mục 6. Hiện màn chơi vẽ tạm
mọi thứ bằng code (`scripts/ui/jet/jet_stage.gd`). Khi owner duyệt một lô ảnh, Claude nối ảnh đó vào màn chơi: chỉ
cần đặt đúng tên file ở mục 3. Thiết kế là của dự án: **không** bắt chước nhân vật, quái, giao diện hay phong cách
nhận diện của game khác, kể cả game bay ngang dùng làm tham khảo cơ chế.

## 1. Bối cảnh

**Vết Rỗng** là một khe trống trong Vết Khuyết, nơi Tinh trôi lơ lửng. Chỉ một giáp hiện hình được, nên người ở ô 1
của đội bay một mình, hai người còn lại nói qua kênh. NEO lắp vội cho họ một **Bộ Phụt**: đốt Tinh Lõi để phụt lên,
cạn thì rơi, đứng đất thì hút chút Tinh từ đá để nạp lại.

Trong Vết Rỗng còn sót **ký ức** của những thứ từng canh giữ nơi này. Chạm **Hộp Ký Ức** thì ký ức đó hiện ra và
chở người bay một lúc:
- **Rồng:** ký ức con rồng gió từng bay qua Thung Gió.
- **Robo (Thủ vệ):** ký ức một thủ vệ đá-máy chuyên nghiền Cặn, cùng xưởng với Golem Đá Cổ ở màn 1-1 (dấu ba vòng đá).

Vật cản là **Cặn**, nguyên tố thừa vón lại, luôn **tím trung tính**. Màu nguyên tố chỉ dành cho lửa Bộ Phụt và vệt bay.

## 2. Phong cách

- Giống sprite trong game hiện tại: anime 2D, nét viền sạch, cel shading 2–3 tông, hơi giảm bão hòa.
  - Nhân vật trong màn cao khoảng 135 px; Rồng và Robo to hơn khoảng 1.5 lần.
  - Ảnh tham chiếu phong cách:
    - Quái Nhịp điệu: `assets/rhythm/rh_slime/run/rh_slime_run_000.png`, `assets/rhythm/rh_bat/fly/rh_bat_fly_000.png`
    - Frame nhân vật: `assets/characters/char_wind_01/frames/`
- Màu khóa (game đang dùng; ảnh nên khớp để còn tô màu bằng code):

| Thứ | Màu |
|---|---|
| Cặn (Thanh Cặn, Cặn Phóng, Van Sét) | tím `#B48CFF`, quầng `#7C5CFF`, thân tối `#2A1B4A` |
| Tia Quét | vàng trắng `#FFF6C8`, quầng `#FFE066` |
| Tinh Lõi | cyan `#6FD3FF` |
| Hạt Tinh | trắng xanh `#BFF3FF` |
| Hộp Ký Ức | hồng `#FF9BD8` |
| Cảnh báo Cặn Phóng | đỏ `#FF6A6A` |
| Vùng Ống Tro / Thung Gió Ngược / Hang Sét Câm | nhấn `#FF8A4D` / `#5FE3C0` / `#FFE066` |

- **Hướng:**
  - Người bay, Rồng, Robo đi sang phải, nên **vẽ quay mặt sang PHẢI**.
  - Cặn Phóng lao sang trái, nên **vẽ quay mặt sang TRÁI**.
- Thứ game tự tô màu theo nguyên tố (lửa Bộ Phụt, vệt bay): vẽ **trắng / xám sáng**, để code nhân màu.
- Không chữ, không logo, không watermark. PNG nền trong suốt (trừ ảnh nền).

## 3. Danh sách ảnh

Thư mục `assets/jet/`; tên file `{id}_{anim}_{NNN}.png`, NNN bắt đầu từ 000.
- Ảnh tĩnh: `{id}.png`.
- Tâm khung là tâm va chạm, trừ Robo: chân Robo ở đáy khung, cách đáy 10 %.
- Ảnh AI: ghi **từng file** vào `docs/ASSET_LICENSES.md` mục 2.1.

### Ưu tiên 1 — người bay và vật phẩm (đủ để thay hình tạm quanh nhân vật)

| # | id | Khung | Animation (frame, fps) | Hiển thị | Ghi chú |
|---|---|---|---|---|---|
| 1 | `jet_pack` | 128×128 | 1 ảnh | ~56 px | Bộ Phụt đeo lưng: bình đôi + ống phụt dưới đáy, có **khe đo mức** dọc để game vẽ mức nạp |
| 2 | `jet_flame` | 64×160 | `burn` 4 f, 24 fps lặp | ~40×90 px | lửa phụt **trắng xám** (game tô màu nguyên tố), gốc ở mép trên khung |
| 3 | `jet_core` | 128×128 | `idle` 6 f, 10 fps lặp | ~70 px | Tinh Lõi: tinh thể cyan hình thoi, lõi sáng, vài mảnh vụn xoay quanh |
| 4 | `jet_orb` | 64×64 | `idle` 4 f, 8 fps lặp | ~32 px | Hạt Tinh: hạt tròn trắng xanh lấp lánh |
| 5 | `jet_box` | 128×128 | `idle` 6 f, 10 fps lặp; `open` 6 f, 20 fps | ~70 px | Hộp Ký Ức: hộp đá nhỏ khắc vân, khe hở phát sáng hồng, không vẽ dấu "?" |
| 6 | `jet_dragon` | 512×384 | `fly` 6 f, 12 fps lặp; `break` 6 f, 18 fps | ~210×160 px | Rồng, chừa yên trên lưng cho nhân vật ngồi (game đặt sprite người lên trên) |
| 7 | `jet_robo` | 384×384 | `walk` 6 f, 14 fps lặp; `jump` 3 f; `crush` 4 f, 20 fps; `break` 6 f | ~190 px | Robo (Thủ vệ), chừa chỗ ngồi / buồng lái trên vai |
| 8 | `jet_icon_dragon`, `jet_icon_robo` | 128×128 | 1 ảnh mỗi cái | ~48 px | biểu tượng hình ở HUD (đầu Rồng / đầu Robo) |

### Ưu tiên 2 — vật cản

| # | id | Khung | Animation | Ghi chú |
|---|---|---|---|---|
| 9 | `jet_beam_body` | 128×40 | 1 ảnh, **lặp ngang liền mạch** | thân Thanh Cặn: thanh nhầy tím, game kéo dài và xoay theo góc |
| 10 | `jet_beam_node` | 96×96 | `pulse` 4 f, 10 fps lặp | nút hai đầu Thanh Cặn: cục Cặn tròn có mắt cam nhỏ |
| 11 | `jet_missile` | 192×128 | `fly` 4 f, 16 fps lặp | Cặn Phóng: cục Cặn thuôn có đuôi khói tím, **quay trái** |
| 12 | `jet_missile_warn` | 128×128 | `blink` 2 f, 8 fps | biểu tượng cảnh báo ở mép phải: tam giác đỏ có vệt Cặn, không chữ |
| 13 | `jet_sweep` | 48×288 | `hum` 3 f, 18 fps lặp | Tia Quét: thanh sét dọc vàng trắng, hai đầu có cực đá nhỏ |
| 14 | `jet_gate_block` | 96×256 | 1 ảnh, **lặp dọc liền mạch** | thân Van Sét: cột đá-kim loại tím có vân sét |
| 15 | `jet_gate_lip` | 128×48 | `spark` 3 f, 18 fps lặp | mép khe Van Sét: viền kim loại có tia lửa vàng (dùng cho mép trên lẫn mép dưới, game lật dọc) |
| 16 | `jet_wind_arrow` | 96×160 | 1 ảnh | mũi tên gió mờ xanh ngọc, **chỉ lên**; game xoay khi gió xuống |

### Ưu tiên 3 — nền 3 vùng (mỗi vùng 4 file)

| # | id | Khung | Ghi chú |
|---|---|---|---|
| 17 | `jet_bg_{zone}_far` | 1920×1080 | trời xa, **lặp ngang liền mạch**, tương phản thấp |
| 18 | `jet_bg_{zone}_mid` | 1920×1080 | cột đá / vách trôi lơ lửng, **giữ alpha**, lặp ngang |
| 19 | `jet_floor_{zone}` | 1920×200 | sàn đá ở dưới (mép trên = mặt sàn), lặp ngang |
| 20 | `jet_ceiling_{zone}` | 1920×120 | trần đá rủ xuống (mép dưới = trần), lặp ngang |

`{zone}`:
- `ash`, Ống Tro: lò tro tắt, ống khói đá, bụi than, cam xỉn.
- `wind`, Thung Gió Ngược: vách đá tạc gió, dải mây xoáy, xanh ngọc.
- `thunder`, Hang Sét Câm: hang tinh thể, sét im lìm trong đá, tím than với vàng.

### Ưu tiên 4 — thẻ chế độ

| # | id | Khung | Ghi chú |
|---|---|---|---|
| 21 | `jet_card` | 824×976 | ảnh thẻ "Bay Nguyên Tố" ở màn Ải nguyên liệu: Kazeyumi đeo Bộ Phụt bay giữa Vết Rỗng, Tinh Lõi quanh. Game vẽ ảnh vào vùng 412×488 px ở trên thẻ (gấp đôi = 824×976, tỉ lệ 0.844); dải tên trắng cao 168 px nằm RIÊNG bên dưới, không đè lên ảnh nên không cần chừa đáy. Góc trên phải có nhãn lượt "50/50" (136×46 px, cách mép 14 px): đừng đặt mặt hay chi tiết chính ở đó. |

### Âm thanh (kèm theo, không phải ảnh)

- Tiếng phụt lặp, cao độ tăng khi năng lượng thấp.
- Tiếng nhặt hạt, nhặt lõi.
- Tiếng biến hình, vỡ hình.
- Tiếng trúng, cảnh báo, đổi vùng.

## 4. Quy trình (giống frame nhân vật, AGENTS.md mục 4)

1. Mỗi lần **một** mục (một id), owner duyệt từng cái. Làm theo thứ tự mục 3; Rồng và Robo làm ảnh tĩnh trước (một
   frame chuẩn), duyệt xong mới làm animation.
2. Ảnh gốc vào `art_review/jet/{id}/raw/` (không vào git). Cắt / co đúng khung mục 3; ảnh lặp kiểm liền mạch bằng
   cách ghép 2 bản cạnh nhau.
3. Ghép xem trước vào `art_review/jet/{id}/_preview/`. Với vật phẩm / vật cản: đặt lên nền tối `#12102A` cạnh frame
   `run_000` của Kazeyumi đúng tỉ lệ hiển thị ở mục 3. **Dừng**, gửi owner đường dẫn preview.
4. Owner trả lời "duyệt {id}" thì:
   - Chép vào `assets/jet/{id}/` (ảnh tĩnh: `assets/jet/{id}.png`).
   - Chạy `--import`, ghi `docs/ASSET_LICENSES.md` mục 2.1.
   - Chạy test, ghi `docs/DEVELOPMENT_LOG.md`, commit, push.
   - Báo Claude để nối ảnh vào `JetStage`.

## 5. Prompt chính gửi Codex

```text
Việc: tạo ảnh cho chế độ Bay Nguyên Tố theo docs/design/JET_ART_BRIEF.md, mỗi lần MỘT mục ở mục 3, đúng thứ tự
(bắt đầu từ mục chưa có file trong assets/jet/).
Đọc trước: AGENTS.md (mục 4 "Ảnh do AI tạo"), mục 1, 2 của JET_ART_BRIEF.md (bối cảnh, phong cách, màu khóa, hướng
quay mặt). Prompt từng ảnh ở mục 6; dán kèm khối "Phong cách chung" ở đầu mục 6.
Với mỗi mục:
1. Tạo ảnh bằng image_gen, đính kèm ảnh tham chiếu ghi ở prompt của mục đó (luôn kèm
   assets/rhythm/rh_slime/run/rh_slime_run_000.png và assets/characters/char_wind_01/frames/run/char_wind_01_run_000.png
   để khớp nét). Animation: tạo dải frame ngang trên một ảnh rồi cắt đều, giữ tâm / chân cố định giữa các frame.
2. Làm theo mục 4 bước 2–3 (art_review, cắt đúng khung, preview). DỪNG, gửi tôi đường dẫn preview, chờ "duyệt {id}".
3. Khi tôi duyệt: làm mục 4 bước 4 (chép vào assets/jet/, --import, ghi ASSET_LICENSES 2.1 từng file, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 phải mã thoát 0, ghi DEVELOPMENT_LOG, commit + push).
   Không ghi đè file đã có: tạo -v2 và hỏi.
Không vẽ chữ, logo, watermark. Không bắt chước nhân vật / thương hiệu bên thứ ba. Trả lời tôi bằng tiếng Việt.
```

## 6. Prompt từng ảnh (tiếng Anh, dán cho image_gen)

**Phong cách chung (dán ở đầu mọi prompt):**
"Original 2D game sprite for a side-scrolling flying mini game. Clean anime line art with thick tidy outline, 2–3 tone
cel shading, slightly desaturated palette, consistent with the attached reference sprites. Transparent background,
subject centered, no text, no logo, no watermark."

1. **`jet_pack`** — "A compact jet pack worn on the back: twin rounded fuel canisters of dark grey metal joined by a
   brass frame, one short nozzle pointing down at the bottom, a vertical glass gauge slot between the canisters (empty,
   the game draws the fill), small straps. Side view facing right, 128x128."
2. **`jet_flame`** — "Rocket exhaust flame pointing straight down, the flame base touching the top edge of the frame,
   pure white to light grey (the game tints it), soft outer glow, 4-frame flicker animation strip, each frame 64x160."
3. **`jet_core`** — "A floating energy crystal called Tinh Core: diamond-shaped cyan crystal #6FD3FF with a bright
   white core, three tiny shards orbiting it, gentle glow. 6-frame idle loop (shards orbit, glow pulses), each frame
   128x128."
4. **`jet_orb`** — "A tiny floating shard of light, round, pale cyan-white #BFF3FF with a white highlight and a soft
   sparkle. 4-frame twinkle loop, each frame 64x64."
5. **`jet_box`** — "A small floating memory box carved from pale stone, engraved swirl patterns, light leaking from its
   seams in pink #FF9BD8, faint pink aura. 6-frame idle loop (bobbing glow), then 6-frame open animation where the lid
   bursts into pink light motes. Each frame 128x128. No question mark, no text."
6. **`jet_dragon`** — "A spectral wind dragon made of pale teal mist and light, slender serpentine body, two broad
   feathered wings, long flowing whiskers, calm glowing eyes, a smooth saddle area on its back for a rider (leave it
   empty). Flying to the right, side view. Translucent edges like a memory. First a single key frame 512x384; after
   approval a 6-frame wing-flap loop and a 6-frame break animation where it dissolves into wind streaks." Tham chiếu
   thêm: `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png` (bảng màu gió).
7. **`jet_robo`** — "A sturdy stone-and-metal guardian golem, small for a golem (about 1.4x a person), blocky granite
   body with brass joints, two short thick legs, big fists for crushing, a carved emblem of three overlapping stone
   rings on its chest, an open cockpit seat on its shoulders for a rider (leave it empty). Walking to the right, side
   view, feet at the bottom of the frame with 10% margin. First a single key frame 384x384; after approval: 6-frame walk
   loop, 3-frame jump, 4-frame crush (fist slam), 6-frame break (crumbles into stone pieces)." Tham chiếu thêm:
   `assets/enemies/boss_golem_01/design/boss_golem_01_sheet.png` (cùng xưởng thủ vệ, dấu ba vòng đá).
8. **`jet_icon_dragon`, `jet_icon_robo`** — "Round HUD icon, head of the teal mist dragon from the reference, facing
   right, simple bold shapes, readable at 48 px, 128x128." / "Round HUD icon, head of the stone guardian golem from the
   reference with the three-ring emblem, readable at 48 px, 128x128." (đính kèm ảnh Rồng / Robo đã duyệt).
9. **`jet_beam_body`** — "Horizontal tileable segment of a slimy violet sludge bar #B48CFF with darker core #2A1B4A
   and a purple glow #7C5CFF, seamless left and right edges, 128x40."
10. **`jet_beam_node`** — "Round blob of violet sludge with one small orange eye, glowing purple rim, used as the end
    cap of a sludge bar. 4-frame pulse loop, each frame 96x96."
11. **`jet_missile`** — "A dart-shaped blob of violet sludge flying to the LEFT, angry small orange eyes, a smoky
    purple trail streaming to the right. 4-frame loop, each frame 192x128."
12. **`jet_missile_warn`** — "Warning icon: red #FF6A6A triangle with a splash of violet sludge inside, no text, bold
    outline, readable at small size. 2 frames (bright / dim), each 128x128."
13. **`jet_sweep`** — "Vertical bar of silent lightning, white-yellow core #FFF6C8 with golden glow #FFE066, a small
    dark stone pole cap at each end. 3-frame humming loop, each frame 48x288."
14. **`jet_gate_block`** — "Vertical tileable column of violet stone fused with dark metal, faint yellow lightning
    veins, seamless top and bottom edges, 96x256."
15. **`jet_gate_lip`** — "Metal edge cap of a thunder valve, horizontal, with crackling yellow sparks along the bottom
    edge, 3-frame spark loop, each frame 128x48."
16. **`jet_wind_arrow`** — "Soft translucent wind arrow pointing UP made of teal #5FE3C0 air streaks, no outline,
    96x160."
17. **`jet_bg_{zone}_far`** — Ống Tro: "Wide side-view background of an abandoned ash furnace valley inside a dark rift,
    distant stone chimneys, drifting embers, muted orange and charcoal, low contrast, horizon around 60%, seamless
    horizontal tiling, 1920x1080." Thung Gió: "...a canyon carved by wind, swirling cloud bands, teal and slate...".
    Hang Sét: "...a crystal cave with frozen lightning trapped inside the rock, deep violet and gold...". Tham chiếu:
    `assets/backgrounds/stages/stage_01/bg_stage_01_far.png` (bảng màu, nét nền của game).
18. **`jet_bg_{zone}_mid`** — "Floating rock pillars and broken ledges for the {zone} background, transparent
    background, seamless horizontal tiling, slightly higher contrast than the far layer, 1920x1080."
19. **`jet_floor_{zone}`** — "Seamless horizontal strip of rocky ground seen from the side, top edge is the walking
    surface, matching the {zone} palette, 1920x200."
20. **`jet_ceiling_{zone}`** — "Seamless horizontal strip of rocky ceiling with short hanging stalactites, bottom edge
    is the ceiling line, matching the {zone} palette, 1920x120."
21. **`jet_card`** — "Vertical card illustration: the archer girl from the reference (teal hair with white feather,
    cream outfit, dark teal cape) flying upward with a jet pack, cyan Tinh Cores floating around her, a dark violet rift
    with drifting light shards behind, dynamic diagonal composition, 824x976 (the whole image is visible, the title strip is a separate
    panel below it; keep the top-right 272x92 px area calm because a small badge sits there)." Tham chiếu: `assets/characters/char_wind_01/portrait/char_wind_01_portrait_full.png`.
