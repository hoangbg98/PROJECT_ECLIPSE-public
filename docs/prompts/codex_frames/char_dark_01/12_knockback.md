# Phiếu 12 — Yomigari / `knockback`

> Sinh tự động bởi `tools/frames/gen_prompts.py` từ `tools/frames/jobs/char_dark_01.json` và `data/skills/`.
> Sửa phiếu ở file JSON rồi chạy lại, không sửa tay file này.

## Thông số (khớp thời gian trong game)

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/char_dark_01/knockback/` |
| Số frame | **3** (tạo trong 1 lần, mỗi lần frame 000–002) |
| fps / lặp | 12 fps, không lặp |
| Thời lượng | 250 ms |
| Frame trúng đòn | — |
| Lưỡi hái | **cầm lưỡi hái**: tay gần nắm cán, vung mạnh thì hai tay; hái luôn trong tay, không buông, không đổi hẳn sang tay xa |
| Đứng đất | có: chân ở y = 336 mọi frame |

**Động tác:** Bị hất lùi: bị đẩy lùi, trượt trên hai chân, mặt ngạc nhiên (mặt thứ 4 hàng mặt trên của tờ), hái kéo lê sau, đứng vững lại.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `assets/characters/char_dark_01/portrait/char_dark_01_portrait_full.png` | Ảnh đứng toàn thân của owner: khóa thiết kế, màu, tóc che một mắt, áo khoác, áo choàng, lưỡi hái |
| `assets/characters/char_dark_01/rig_parts/source/char_dark_01_parts_sheet.png` | Tờ sprite art gốc của owner: mặt (11 biểu cảm), lưỡi hái tách rời, 6 pose mẫu hàng dưới (đứng, thủ thế, chạy, chém quét, chém bổ, tuyệt kỹ) chuẩn tỉ lệ chibi nhỏ |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `knockback` cho Yomigari (char_dark_01), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/char_dark_01/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/char_dark_01/12_knockback.md. Giữ đúng ngoại hình model gốc, lưỡi hái theo mục Lưỡi hái của phiếu.

1. Tạo ảnh bằng skill imagegen, 1 lần gọi (3 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (nhiều lần gọi: thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/char_dark_01/knockback/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py char_dark_01 knockback <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame -1, cao 1.00× lúc đứng; sai thì thêm --ref-frame / --ref-ratio)
3. Ghi art_review/char_dark_01/knockback/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py char_dark_01 knockback — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo danh sách trong phiếu (mục Tự kiểm tra). Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/char_dark_01/knockback/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG sửa frames_manifest.json, KHÔNG commit. Chờ tôi trả lời "duyệt knockback".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py char_dark_01 knockback, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: Yomigari knockback frames (AI)". Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh, mỗi lần gọi)

```text
2D side-scrolling action game sprite strip of the SAME character as the reference images: Yomigari, chibi anime dark-element reaper boy (about 2.5 heads tall, big head, short limbs): messy shaggy black hair with violet-purple gradient tips, long side-swept bangs covering one eye, the visible eye violet-purple, calm cold expressionless face; a black high-collared double-breasted long military coat with silver trim lines, silver buckles and small silver studs, a thin silver chain draped across the chest and a small violet diamond gem brooch on the chest, a wide black belt with a silver buckle, the coat tails hang long behind like a frock coat with violet-purple inner lining; a long black cape with violet-purple lining draped over one shoulder and falling behind him to the calves; black gloves; black trousers with buckled straps around the thighs; black knee-high buckled boots with violet soles. Weapon: a huge war scythe taller than he is: a long black shaft with silver segment rings and a small violet diamond gem at the bottom spike; an ornate spiky black-and-silver head with a violet diamond gem at the joint; a long curved black blade whose inner cutting edge is violet-purple.
Keep the exact design, proportions (chibi, big head, short limbs), colors, dark outline thickness and colour (2-3 px), and 2-3 tone cel shading of the references.
The small sample poses in the bottom row of the sprite sheet are the ground truth for the chibi proportions and the scythe size; the full-body reference is the ground truth for design and colors. The sheet also shows a purple slash trail, purple flames and motion blur: do NOT copy them, draw the character and the scythe only.
The violet gems on the chest, scythe head and scythe foot are small solid gems with at most a tiny highlight, no glow.
Asymmetric details must stay on the same body side in every frame: the bangs always cover the same eye, the cape always hangs from the same shoulder, the scythe stays in the near hand.
The long coat tails and the cape trail behind him and follow every motion with a slight delay (secondary motion); keep their length in every frame.
Do NOT redesign: same hair, face, eyes, outfit, armor, accessories and war scythe; no added or removed details.
The character faces RIGHT in every frame, full body visible, same scale in every frame.
One single horizontal row of exactly 3 poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: fully transparent. No ground line, no shadow, no text, no numbers, no frame borders.
No visual effects (no purple slash arcs, dark smoke, shadow tendrils, purple flames, black crescent moon, glow, particles, afterimages, speed lines): character and war scythe only.

Animation: Knocked back: pushed backward, sliding on both feet with a surprised face (the surprised face, fourth head of the upper face row on the sprite sheet), the scythe trailing low, regaining footing, still holding the scythe.
War scythe: the war scythe is always held: gripped in the near hand (both hands on the shaft for big swings); never dropped, never switched to the far hand only; keep the exact scythe design and its huge size (taller than his body).
```

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống hoàn toàn ảnh gốc (tóc đen ngọn tím che một mắt, mắt tím, áo khoác đen cổ đứng viền bạc, dây xích bạc, ngọc tím trên ngực, thắt lưng, áo choàng lót tím, găng đen, quần có đai, ủng đen đế tím, lưỡi hái (cán đen vòng bạc, ngọc tím, lưỡi cong viền tím), màu)?
2. Tỉ lệ chibi giữ nguyên, không bộ phận nào phình / co / biến dạng?
3. Nét viền, bảng màu, kiểu đổ bóng đồng nhất giữa các frame?
4. Động tác đọc rõ ở cỡ nhỏ, có lấy đà – đánh – thu về; bóng đen từng pose phân biệt được?
5. `check_frames.py` ĐẠT: chân ở 336, tâm 192, không bị cắt mép?
6. `anim_flip.gif` (lật trái) vẫn đúng: hái không nhảy tay, tóc mái luôn che cùng một mắt, áo choàng luôn ở cùng một vai, chi tiết lệch một bên nhất quán?
7. Không xuyên vật thể, tay / chân gần – xa camera đúng lớp?
8. Không vẽ hiệu ứng (vệt chém tím, khói đen, xúc tu bóng, lửa tím, trăng đen, ánh sáng, hạt, bóng mờ) vào frame nhân vật?
