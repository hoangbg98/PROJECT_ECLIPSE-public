# Phiếu 02 — Cặn lớn / `move` (Bước nặng)

> Claude viết tay 2026-11-19 từ `docs/design/MONSTERS.md` mục 7.2 và bảng bộ phận owner đã điền. Số frame / fps khớp
> `tools/frames/jobs/enemy_slime_02.json`. Cần phiếu `../enemy_slime_01/00_CONG_CU.md` đã xong (công cụ hiểu khung của quái).

## Thông số

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/enemy_slime_02/move/` |
| Số frame | **8** (2 lần gọi: 000–003, 004–007) |
| fps / lặp | 10 fps, lặp liền mạch |
| Thời lượng | 800 ms |
| Frame trúng đòn | — |
| Khung | 320×320, tâm x = 160, chân y = 288, cao đứng ~130 px |
| Đứng đất | có: chân ở y = 288 mọi frame |

**Động tác:** Đi bộ nặng nề về phía phải như số 37: bước chân chậm, cả thân lắc theo, bụng rung khi đặt chân, tay vung ngược chân. Thân giữ ở tâm (code tự dời quái). Lặp liền.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p01_than_day_du.png` | Thân đầy đủ (số 01): hình khối, mai vảy, nanh, màu, nét viền |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p36_pose_dung.png` | Pose đứng (số 36): tỉ lệ thân / tay / chân |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p37_pose_buoc.png` | Pose bước đi (số 37) |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p02_gian_nanh.png` | Mặt mặc định (số 02) |

## Pose từng frame

| Frame | Giai đoạn | Pose |
|---|---|---|
| 000 | — | contact: front foot lands, body leans slightly forward |
| 001 | — | down: weight drops, belly jiggles, knees bend |
| 002 | — | passing: back foot swings forward, body rises |
| 003 | — | up: highest point, arms swing opposite to the legs |
| 004 | — | contact: the other foot lands |
| 005 | — | down: weight drops, belly jiggles |
| 006 | — | passing: other foot swings forward |
| 007 | — | up: highest point, flowing back into pose 1 |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `move` cho quái Cặn lớn (enemy_slime_02), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/enemy_slime_02/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/enemy_slime_02/02_move.md. Giữ đúng ngoại hình model gốc (ảnh 01, 36 trong ref/).
Điều kiện: docs/prompts/codex_frames/enemy_slime_01/00_CONG_CU.md đã xong (tools/frames hiểu kind = enemy). Chưa xong thì dừng và báo tôi.

1. Tạo ảnh bằng skill imagegen, 2 lần gọi (8 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/enemy_slime_02/move/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py enemy_slime_02 move <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 1.00× lúc đứng)
3. Ghi art_review/enemy_slime_02/move/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py enemy_slime_02 move — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo mục Tự kiểm tra của phiếu. Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/enemy_slime_02/move/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG commit. Chờ tôi trả lời "duyệt move".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py enemy_slime_02 move, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: enemy_slime_02 move frames (AI)", push. Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh, mỗi lần gọi)

```text
2D side-scrolling action game sprite strip of the SAME monster as the reference images: Big Ash Dreg, a heavy stocky cartoon ash-stone brute: a hunched, round, bear-like body with a huge smooth grey-brown round belly; the back, shoulders and top of the head are covered by thick overlapping stone-ash plates with glowing orange lava cracks; two angry glowing orange eyes under a heavy brow; a wide frowning mouth with two white tusks pointing up from the lower jaw; two thick stubby stone arms with blocky fists hanging at the sides; two short thick legs with clawed stone toes. Thick dark brown-black outline, 2-tone cel shading.
Keep the exact design, proportions, colors, dark outline thickness (2-3 px) and 2-tone cel shading of the references.
Do NOT redesign: same stone plates on the back and head, same glowing orange eyes, same two white tusks, same round belly, same stubby stone arms and clawed feet; no added or removed details, no weapon.
The monster is seen in the same three-quarter view turned toward the RIGHT as the reference poses, full body visible, same scale in every pose. Keep the body centred in place: it does not travel across the strip.
One single horizontal row of exactly {n} poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: fully transparent. No ground line, no cast shadow, no text, no numbers, no frame borders, no logo, no watermark.
No visual effects outside the body (no speed lines, dust clouds, flying rocks, sparks, stars, snot bubble, fire outside the mouth).

Animation: Heavy stomping walk loop heading right like reference 37 (the body stays centred, the game moves it): Poses in time order (counted from 1): 1) contact: front foot lands, body leans slightly forward; 2) down: weight drops, belly jiggles, knees bend; 3) passing: back foot swings forward, body rises; 4) up: highest point, arms swing opposite to the legs; 5) contact: the other foot lands; 6) down: weight drops, belly jiggles; 7) passing: other foot swings forward; 8) up: highest point, flowing back into pose 1.
This call draws ONLY poses {a} to {b} of the list above ({n} poses), continuing seamlessly from the previous strip.
Looping animation: the last pose must lead smoothly back into the first pose.
```

Thay theo từng lần gọi: lần 1: {n} = 4, {a} = 1, {b} = 4; lần 2: {n} = 4, {a} = 5, {b} = 8.

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống ảnh gốc (mai phiến đá, khe dung nham, mắt cam, hai nanh trắng, bụng tròn, tay chân đá, màu)?
2. Tỉ lệ thân / tay / chân giữ nguyên, không mọc thêm sừng, răng, ngón?
3. Nét viền, bảng màu, đổ bóng đồng nhất giữa các frame?
4. Đọc rõ ở cỡ nhỏ (~130 px); với attack: pha lấy đà dài, nhìn là biết sắp lao?
5. `check_frames.py` ĐẠT: chân ở 288, tâm 160, không bị cắt mép khung 320?
6. Thân không trôi ngang trong dải (code tự dời quái)?
7. Không vẽ bụi, đá bay, lửa ngoài thân, bong bóng, bóng đổ, chữ?
