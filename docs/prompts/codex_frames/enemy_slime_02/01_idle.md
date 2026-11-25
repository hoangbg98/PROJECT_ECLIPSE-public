# Phiếu 01 — Cặn lớn / `idle` (Đứng thở)

> Claude viết tay 2026-11-19 từ `docs/design/MONSTERS.md` mục 7.2 và bảng bộ phận owner đã điền. Số frame / fps khớp
> `tools/frames/jobs/enemy_slime_02.json`. Cần phiếu `../enemy_slime_01/00_CONG_CU.md` đã xong (công cụ hiểu khung của quái).

## Thông số

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/enemy_slime_02/idle/` |
| Số frame | **6** (1 lần gọi: 000–005) |
| fps / lặp | 8 fps, lặp liền mạch |
| Thời lượng | 750 ms |
| Frame trúng đòn | — |
| Khung | 320×320, tâm x = 160, chân y = 288, cao đứng ~130 px |
| Đứng đất | có: chân ở y = 288 mọi frame |

**Động tác:** Đứng thủ thế như số 36, thở nặng: bụng phồng xẹp, vai và mai lưng nhô lên hạ xuống, khe dung nham sáng mờ theo nhịp, tay đung đưa nhẹ. Mặt giận (02) hầu hết các frame, một frame lim dim như mắt số 31 (không có bong bóng). Lặp liền.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p01_than_day_du.png` | Thân đầy đủ (số 01): hình khối, mai vảy, nanh, màu, nét viền |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p36_pose_dung.png` | Pose đứng (số 36): tỉ lệ thân / tay / chân |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p02_gian_nanh.png` | Giận, nanh chìa (số 02): mặt mặc định |
| `docs/prompts/codex_frames/enemy_slime_02/ref/enemy_slime_02_ref_p31_ngu.png` | Ngủ (số 31): mượn mắt lim dim, KHÔNG vẽ bong bóng mũi |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `idle` cho quái Cặn lớn (enemy_slime_02), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/enemy_slime_02/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/enemy_slime_02/01_idle.md. Giữ đúng ngoại hình model gốc (ảnh 01, 36 trong ref/).
Điều kiện: docs/prompts/codex_frames/enemy_slime_01/00_CONG_CU.md đã xong (tools/frames hiểu kind = enemy). Chưa xong thì dừng và báo tôi.

1. Tạo ảnh bằng skill imagegen, 1 lần gọi (6 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới. Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/enemy_slime_02/idle/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py enemy_slime_02 idle <dải 1> [<dải 2> ...] [--chroma FF00FF]
   (idle: chiều cao đứng 130 px)
3. Ghi art_review/enemy_slime_02/idle/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py enemy_slime_02 idle — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo mục Tự kiểm tra của phiếu. Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/enemy_slime_02/idle/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG commit. Chờ tôi trả lời "duyệt idle".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py enemy_slime_02 idle, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: enemy_slime_02 idle frames (AI)", push. Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh)

```text
2D side-scrolling action game sprite strip of the SAME monster as the reference images: Big Ash Dreg, a heavy stocky cartoon ash-stone brute: a hunched, round, bear-like body with a huge smooth grey-brown round belly; the back, shoulders and top of the head are covered by thick overlapping stone-ash plates with glowing orange lava cracks; two angry glowing orange eyes under a heavy brow; a wide frowning mouth with two white tusks pointing up from the lower jaw; two thick stubby stone arms with blocky fists hanging at the sides; two short thick legs with clawed stone toes. Thick dark brown-black outline, 2-tone cel shading.
Keep the exact design, proportions, colors, dark outline thickness (2-3 px) and 2-tone cel shading of the references.
Do NOT redesign: same stone plates on the back and head, same glowing orange eyes, same two white tusks, same round belly, same stubby stone arms and clawed feet; no added or removed details, no weapon.
The monster is seen in the same three-quarter view turned toward the RIGHT as the reference poses, full body visible, same scale in every pose. Keep the body centred in place: it does not travel across the strip.
One single horizontal row of exactly 6 poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: fully transparent. No ground line, no cast shadow, no text, no numbers, no frame borders, no logo, no watermark.
No visual effects outside the body (no speed lines, dust clouds, flying rocks, sparks, stars, snot bubble, fire outside the mouth).

Animation: Idle heavy breathing loop in the standing pose of reference 36: the round belly swells and shrinks, shoulders and back plates rise and fall, lava cracks pulse softly, the arms sway slightly. Angry face like face 02 in most poses; one pose with heavy half-closed sleepy eyes like face 31 (no bubble). The last pose flows smoothly back into the first.
Looping animation: the last pose must lead smoothly back into the first pose.
```

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống ảnh gốc (mai phiến đá, khe dung nham, mắt cam, hai nanh trắng, bụng tròn, tay chân đá, màu)?
2. Tỉ lệ thân / tay / chân giữ nguyên, không mọc thêm sừng, răng, ngón?
3. Nét viền, bảng màu, đổ bóng đồng nhất giữa các frame?
4. Đọc rõ ở cỡ nhỏ (~130 px); với attack: pha lấy đà dài, nhìn là biết sắp lao?
5. `check_frames.py` ĐẠT: chân ở 288, tâm 160, không bị cắt mép khung 320?
6. Thân không trôi ngang trong dải (code tự dời quái)?
7. Không vẽ bụi, đá bay, lửa ngoài thân, bong bóng, bóng đổ, chữ?
