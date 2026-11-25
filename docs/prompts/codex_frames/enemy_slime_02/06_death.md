# Phiếu 06 — Cặn lớn / `death` (Sụp thành đống đá)

> Claude viết tay 2026-11-19 từ `docs/design/MONSTERS.md` mục 7.2 và bảng bộ phận owner đã điền. Số frame / fps khớp
> `tools/frames/jobs/enemy_slime_02.json`. Cần phiếu `../enemy_slime_01/00_CONG_CU.md` đã xong (công cụ hiểu khung của quái).

## Thông số

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/enemy_slime_02/death/` |
| Số frame | **8** (2 lần gọi: 000–003, 004–007) |
| fps / lặp | 10 fps, không lặp |
| Thời lượng | 800 ms |
| Frame trúng đòn | — |
| Khung | 320×320, tâm x = 160, chân y = 288, cao đứng ~130 px |
| Đứng đất | có: chân ở y = 288 mọi frame |

**Động tác:** Bị hạ: giật nảy (mặt 12) – lảo đảo lùi, há miệng (05) – khe dung nham rực sáng – khuỵu gối – mai lưng nứt, phiến đá bong – đổ sập về trước – vỡ thành đống phiến đá – đống đá thấp, khe cam tắt dần, không còn mặt. Frame cuối đứng yên (code mờ dần 0.8 s). Nổ lửa (số 34) là VFX riêng.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p01_than_day_du.png` | Thân đầy đủ (số 01): hình khối, mai vảy, nanh, màu, nét viền |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p36_pose_dung.png` | Pose đứng (số 36): tỉ lệ thân / tay / chân |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p12_dau.png` | Đau (số 12) |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p05_ngac_nhien.png` | Ngạc nhiên (số 05) |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p17_mai_lung.png` | Mai lưng (số 17): hình phiến đá khi bong ra |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p15_vay_vai.png` | Vảy vai (số 15) |

## Pose từng frame

| Frame | Giai đoạn | Pose |
|---|---|---|
| 000 | — | jolt: eyes shut tight in pain like face 12 |
| 001 | — | staggers back, mouth open in shock like face 05 |
| 002 | — | lava cracks blaze bright all over the body |
| 003 | — | drops to its knees, arms hanging |
| 004 | — | back plates crack and start sliding off |
| 005 | — | collapses forward onto the ground |
| 006 | — | breaks apart into a heap of stone plates |
| 007 | — | a low rubble heap of stone plates with fading orange cracks, no face |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `death` cho quái Cặn lớn (enemy_slime_02), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/enemy_slime_02/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/enemy_slime_02/06_death.md. Giữ đúng ngoại hình model gốc (ảnh 01, 36 trong ref/).
Điều kiện: docs/prompts/codex_frames/enemy_slime_01/00_CONG_CU.md đã xong (tools/frames hiểu kind = enemy). Chưa xong thì dừng và báo tôi.

1. Tạo ảnh bằng skill imagegen, 2 lần gọi (8 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/enemy_slime_02/death/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py enemy_slime_02 death <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 1.00× lúc đứng)
3. Ghi art_review/enemy_slime_02/death/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py enemy_slime_02 death — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo mục Tự kiểm tra của phiếu. Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/enemy_slime_02/death/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG commit. Chờ tôi trả lời "duyệt death".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py enemy_slime_02 death, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: enemy_slime_02 death frames (AI)", push. Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh, mỗi lần gọi)

```text
2D side-scrolling action game sprite strip of the SAME monster as the reference images: Big Ash Dreg, a heavy stocky cartoon ash-stone brute: a hunched, round, bear-like body with a huge smooth grey-brown round belly; the back, shoulders and top of the head are covered by thick overlapping stone-ash plates with glowing orange lava cracks; two angry glowing orange eyes under a heavy brow; a wide frowning mouth with two white tusks pointing up from the lower jaw; two thick stubby stone arms with blocky fists hanging at the sides; two short thick legs with clawed stone toes. Thick dark brown-black outline, 2-tone cel shading.
Keep the exact design, proportions, colors, dark outline thickness (2-3 px) and 2-tone cel shading of the references.
Do NOT redesign: same stone plates on the back and head, same glowing orange eyes, same two white tusks, same round belly, same stubby stone arms and clawed feet; no added or removed details, no weapon.
The monster is seen in the same three-quarter view turned toward the RIGHT as the reference poses, full body visible, same scale in every pose. Keep the body centred in place: it does not travel across the strip.
One single horizontal row of exactly {n} poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: fully transparent. No ground line, no cast shadow, no text, no numbers, no frame borders, no logo, no watermark.
No visual effects outside the body (no speed lines, dust clouds, flying rocks, sparks, stars, snot bubble, fire outside the mouth), except the brighter lava glow inside the body cracks.

Animation: Death (not looping). Poses in time order (counted from 1): 1) jolt: eyes shut tight in pain like face 12; 2) staggers back, mouth open in shock like face 05; 3) lava cracks blaze bright all over the body; 4) drops to its knees, arms hanging; 5) back plates crack and start sliding off; 6) collapses forward onto the ground; 7) breaks apart into a heap of stone plates; 8) a low rubble heap of stone plates with fading orange cracks, no face.
This call draws ONLY poses {a} to {b} of the list above ({n} poses), continuing seamlessly from the previous strip.
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
