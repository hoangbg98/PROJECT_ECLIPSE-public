# Phiếu 03 — Cặn lớn / `attack` (Cắn lao nặng)

> Claude viết tay 2026-11-19 từ `docs/design/MONSTERS.md` mục 7.2 và bảng bộ phận owner đã điền. Số frame / fps khớp
> `tools/frames/jobs/enemy_slime_02.json`. Cần phiếu `../enemy_slime_01/00_CONG_CU.md` đã xong (công cụ hiểu khung của quái).

## Thông số

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/enemy_slime_02/attack/` |
| Số frame | **20** (4 lần gọi: 000–004, 005–009, 010–014, 015–019) |
| fps / lặp | 12 fps, không lặp |
| Thời lượng | 1680 ms — lấy đà / trúng / hồi 700/180/800 ms |
| Frame trúng đòn | 008, 009, 010 |
| Khung | 320×320, tâm x = 160, chân y = 288, cao đứng ~130 px |
| Đứng đất | không: frame thấp nhất chạm 288, các frame khác giữ độ cao tương đối |

**Động tác:** Cắn lao nặng (data: lấy đà 700 ms, trúng 180 ms, hồi 800 ms; code dời quái 80 px khi trúng). Lấy đà dài và rõ — **người chơi né theo pha này**: khom người như số 38, gồng (mặt 11), ngẩng đầu gầm, lửa rực trong miệng như số 39 / mặt 29. Trúng đòn: lao chồm tới như số 41, miệng há rộng cắn (mặt 09), giữ rõ ba frame. Hồi: đáp nặng như số 40 (không bụi), lắc người, nguôi dần (mặt 06), về dáng đứng.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p01_than_day_du.png` | Thân đầy đủ (số 01): hình khối, mai vảy, nanh, màu, nét viền |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p36_pose_dung.png` | Pose đứng (số 36): tỉ lệ thân / tay / chân |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p38_pose_khom.png` | Khom lấy đà (số 38) |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p39_pose_gam_lua.png` | Gầm miệng rực lửa (số 39): cuối pha lấy đà |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p41_pose_phun_da.png` | Lao chồm tới (số 41): pose TRÚNG ĐÒN — bỏ các viên đá bay phía sau |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p40_pose_nhay_giam.png` | Nhảy giậm (số 40): lúc đáp nặng — bỏ bụi |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p11_gong.png` | Gồng nhăn mặt (số 11) |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p29_mieng_lua.png` | Cuồng nộ miệng lửa (số 29) |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p09_gam_du.png` | Gầm dữ dội (số 09) |

## Pose từng frame

| Frame | Giai đoạn | Pose |
|---|---|---|
| 000 | Lấy đà | anticipation start: standing stance, eyes narrowing (face 08) |
| 001 | Lấy đà | starts to crouch like reference 38, arms pulled back |
| 002 | Lấy đà | deeper crouch, shoulders hunched, back plates raised |
| 003 | Lấy đà | crouched, gritting teeth and straining (face 11) |
| 004 | Lấy đà | rears the head up, mouth opening, orange glow inside the mouth |
| 005 | Lấy đà | roaring with a fiery glowing mouth like reference 39 (face 29) |
| 006 | Lấy đà | roar peak, body trembling, lava cracks blazing |
| 007 | Lấy đà | last wind-up pose: coiled low, about to leap |
| 008 | **Trúng đòn** | IMPACT: lunges forward low and heavy like reference 41, mouth wide open biting (face 09) |
| 009 | **Trúng đòn** | IMPACT hold: same lunge, jaws clamping down |
| 010 | **Trúng đòn** | IMPACT end: jaws shut, body fully stretched forward |
| 011 | Hồi | heavy landing like reference 40, knees bent, feet planted (no dust) |
| 012 | Hồi | body sways forward from the momentum |
| 013 | Hồi | recoils back upright |
| 014 | Hồi | shakes the head |
| 015 | Hồi | straightening up |
| 016 | Hồi | shoulders and plates settle |
| 017 | Hồi | face calming (face 06) |
| 018 | Hồi | almost back to the standing stance |
| 019 | Hồi | standing stance, default face (face 02) |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `attack` cho quái Cặn lớn (enemy_slime_02), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/enemy_slime_02/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/enemy_slime_02/03_attack.md. Giữ đúng ngoại hình model gốc (ảnh 01, 36 trong ref/).
Điều kiện: docs/prompts/codex_frames/enemy_slime_01/00_CONG_CU.md đã xong (tools/frames hiểu kind = enemy). Chưa xong thì dừng và báo tôi.

1. Tạo ảnh bằng skill imagegen, 4 lần gọi (20 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/enemy_slime_02/attack/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py enemy_slime_02 attack <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 1.00× lúc đứng)
3. Ghi art_review/enemy_slime_02/attack/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py enemy_slime_02 attack — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo mục Tự kiểm tra của phiếu. Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/enemy_slime_02/attack/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG commit. Chờ tôi trả lời "duyệt attack".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py enemy_slime_02 attack, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: enemy_slime_02 attack frames (AI)", push. Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh, mỗi lần gọi)

```text
2D side-scrolling action game sprite strip of the SAME monster as the reference images: Big Ash Dreg, a heavy stocky cartoon ash-stone brute: a hunched, round, bear-like body with a huge smooth grey-brown round belly; the back, shoulders and top of the head are covered by thick overlapping stone-ash plates with glowing orange lava cracks; two angry glowing orange eyes under a heavy brow; a wide frowning mouth with two white tusks pointing up from the lower jaw; two thick stubby stone arms with blocky fists hanging at the sides; two short thick legs with clawed stone toes. Thick dark brown-black outline, 2-tone cel shading.
Keep the exact design, proportions, colors, dark outline thickness (2-3 px) and 2-tone cel shading of the references.
Do NOT redesign: same stone plates on the back and head, same glowing orange eyes, same two white tusks, same round belly, same stubby stone arms and clawed feet; no added or removed details, no weapon.
The monster is seen in the same three-quarter view turned toward the RIGHT as the reference poses, full body visible, same scale in every pose. Keep the body centred in place: it does not travel across the strip.
One single horizontal row of exactly {n} poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: fully transparent. No ground line, no cast shadow, no text, no numbers, no frame borders, no logo, no watermark.
No visual effects outside the body (no speed lines, dust clouds, flying rocks, sparks, stars, snot bubble, fire outside the mouth), except the orange fire glow INSIDE the open mouth in the roar and bite poses.

Animation: Heavy lunging bite. Poses in time order (counted from 1): 1) anticipation start: standing stance, eyes narrowing (face 08); 2) starts to crouch like reference 38, arms pulled back; 3) deeper crouch, shoulders hunched, back plates raised; 4) crouched, gritting teeth and straining (face 11); 5) rears the head up, mouth opening, orange glow inside the mouth; 6) roaring with a fiery glowing mouth like reference 39 (face 29); 7) roar peak, body trembling, lava cracks blazing; 8) last wind-up pose: coiled low, about to leap; 9) IMPACT: lunges forward low and heavy like reference 41, mouth wide open biting (face 09); 10) IMPACT hold: same lunge, jaws clamping down; 11) IMPACT end: jaws shut, body fully stretched forward; 12) heavy landing like reference 40, knees bent, feet planted (no dust); 13) body sways forward from the momentum; 14) recoils back upright; 15) shakes the head; 16) straightening up; 17) shoulders and plates settle; 18) face calming (face 06); 19) almost back to the standing stance; 20) standing stance, default face (face 02).
Phase map: wind-up 1-8, impact 9-11 (clear readable pose, brief hold), recovery 12-20.
This call draws ONLY poses {a} to {b} of the list above ({n} poses), continuing seamlessly from the previous strip.
```

Thay theo từng lần gọi: lần 1: {n} = 5, {a} = 1, {b} = 5; lần 2: {n} = 5, {a} = 6, {b} = 10; lần 3: {n} = 5, {a} = 11, {b} = 15; lần 4: {n} = 5, {a} = 16, {b} = 20.

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống ảnh gốc (mai phiến đá, khe dung nham, mắt cam, hai nanh trắng, bụng tròn, tay chân đá, màu)?
2. Tỉ lệ thân / tay / chân giữ nguyên, không mọc thêm sừng, răng, ngón?
3. Nét viền, bảng màu, đổ bóng đồng nhất giữa các frame?
4. Đọc rõ ở cỡ nhỏ (~130 px); với attack: pha lấy đà dài, nhìn là biết sắp lao?
5. `check_frames.py` ĐẠT: chân ở 288, tâm 160, không bị cắt mép khung 320?
6. Thân không trôi ngang trong dải (code tự dời quái)?
7. Không vẽ bụi, đá bay, lửa ngoài thân, bong bóng, bóng đổ, chữ (lửa trong miệng thì được)?
