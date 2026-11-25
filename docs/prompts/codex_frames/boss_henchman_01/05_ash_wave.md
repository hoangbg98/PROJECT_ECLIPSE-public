# Phiếu 05 — Kẻ Đeo Mặt Nạ / `ash_wave` (Sóng tro)

> Claude viết tay 2026-11-19 từ `docs/design/MONSTERS.md` mục 7.4 và bảng bộ phận owner đã điền. Số frame / fps khớp
> `tools/frames/jobs/boss_henchman_01.json`. Cần phiếu `../enemy_slime_01/00_CONG_CU.md` đã xong (công cụ hiểu khung của quái, đã làm ở commit 62dd87c).

## Thông số

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/boss_henchman_01/ash_wave/` |
| Số frame | **20** (4 lần gọi: 000–004, 005–009, 010–014, 015–019) |
| fps / lặp | 12 fps, không lặp |
| Thời lượng | 1700 ms — lấy đà / trúng / hồi 800/200/700 ms |
| Frame trúng đòn | 009, 010, 011 |
| Khung | 768×512, tâm x = 384, chân y = 464, cao đứng ~300 px |
| Đứng đất | có: chân ở y = 464 mọi frame |

**Động tác:** Sóng tro (chỉ pha 2; data: lấy đà 800 ms, cắm 200 ms, hồi 700 ms). Lấy đà: giơ lưỡi móc hai tay qua đầu như số 45, khe giáp rực cam, mắt giận rực (06). Trúng đòn: cắm mạnh lưỡi móc xuống đất như số 46, khuỵu thấp. Hai sóng tro chạy hai phía là VFX riêng, **không vẽ**. Hồi: rút lưỡi móc lên, đứng dậy, về thế đứng.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `docs/prompts/codex_frames/boss_henchman_01/ref/boss_henchman_01_ref_p01_than_day_du.png` | Thân đầy đủ (số 01): trang phục, giáp, mặt nạ, lưỡi móc, màu, nét viền |
| `docs/prompts/codex_frames/boss_henchman_01/ref/boss_henchman_01_ref_p41_pose_dung.png` | Pose đứng (số 41): tỉ lệ chibi, góc nhìn, cách cầm lưỡi móc |
| `docs/prompts/codex_frames/boss_henchman_01/ref/boss_henchman_01_ref_p45_pose_gio_luoi.png` | Giơ lưỡi móc qua đầu (số 45) |
| `docs/prompts/codex_frames/boss_henchman_01/ref/boss_henchman_01_ref_p46_pose_cam_luoi.png` | Cắm lưỡi móc (số 46): pose TRÚNG ĐÒN — bỏ lửa và vệt logo mờ |
| `docs/prompts/codex_frames/boss_henchman_01/ref/boss_henchman_01_ref_p06_gian_nut.png` | Giận rực (số 06) |

## Pose từng frame

| Frame | Giai đoạn | Pose |
|---|---|---|
| 000 | Lấy đà | standing stance |
| 001 | Lấy đà | raises the glaive overhead like reference 45 |
| 002 | Lấy đà | glaive higher |
| 003 | Lấy đà | both hands overhead, eyes glowing |
| 004 | Lấy đà | armor cracks flaring orange, raging face (face 06) |
| 005 | Lấy đà | crouching slightly |
| 006 | Lấy đà | hold at the top |
| 007 | Lấy đà | hold (telegraph) |
| 008 | Lấy đà | starting to plunge the glaive down |
| 009 | **Trúng đòn** | IMPACT: plants the glaive blade into the ground like reference 46 (no fire) |
| 010 | **Trúng đòn** | IMPACT hold: kneeling low, both hands on the glaive |
| 011 | **Trúng đòn** | IMPACT end |
| 012 | Hồi | pulling the glaive out of the ground |
| 013 | Hồi | rising |
| 014 | Hồi | glaive freed |
| 015 | Hồi | step back |
| 016 | Hồi | armor cracks dimming |
| 017 | Hồi | cloak settling |
| 018 | Hồi | almost back to the stance |
| 019 | Hồi | standing stance, smooth visor |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `ash_wave` cho boss Kẻ Đeo Mặt Nạ (boss_henchman_01), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/boss_henchman_01/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/boss_henchman_01/05_ash_wave.md. Giữ đúng ngoại hình model gốc (ảnh 01, 41 trong ref/).
Điều kiện: docs/prompts/codex_frames/enemy_slime_01/00_CONG_CU.md đã xong (tools/frames hiểu kind = enemy). Chưa xong thì dừng và báo tôi.

1. Tạo ảnh bằng skill imagegen, 4 lần gọi (20 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/boss_henchman_01/ash_wave/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py boss_henchman_01 ash_wave <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 1.00× lúc đứng)
3. Ghi art_review/boss_henchman_01/ash_wave/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py boss_henchman_01 ash_wave — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo mục Tự kiểm tra của phiếu. Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/boss_henchman_01/ash_wave/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG commit. Chờ tôi trả lời "duyệt ash_wave".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py boss_henchman_01 ash_wave, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: boss_henchman_01 ash_wave frames (AI)", push. Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh, mỗi lần gọi)

```text
2D side-scrolling action game sprite strip of the SAME boss as the reference images: The masked henchman, a chibi anime boss (big head, compact body, about 2.5 heads tall): a smooth rounded dark charcoal-grey helmet-hood made of armored plates with thin glowing orange cracks, covering the whole head; a faceless glossy black visor (no eyes, no mouth) whose eye glow appears only when angry; a dark scarf around the neck; a black three-piece suit (vest, shirt and tie) under an open dark coat; ONE large dark armored pauldron on the shoulder nearest the viewer, with orange cracks; a small round emblem half white and half black on the lapel; armored dark gauntlets; black trousers; dark armored greaves and boots with orange cracks; a long tattered charcoal cloak. Weapon: a long black hooked glaive (a pole with a large curved dark blade with glowing orange cracks), always held in the hand.
Keep the exact design, chibi proportions (big head, short limbs), colors, dark outline thickness (2-3 px) and cel shading of the references.
Do NOT redesign: same armored hood-helmet with orange cracks, same faceless black visor, same black suit vest and tie under the open coat, same single large pauldron on the near shoulder, same white-black lapel emblem, same tattered cloak, same hooked glaive; no added or removed details.
The boss faces RIGHT in every pose (side / three-quarter view like reference poses 42-46), full body visible, same scale in every pose. Keep the body centred in place: it does not travel across the strip.
One single horizontal row of exactly {n} poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching; leave room for the glaive).
Background: fully transparent. No ground line, no cast shadow, no text, no numbers, no frame borders, no logo, no watermark.
No visual effects outside the body (no fire, slash trails, ash waves, smoke, sparks, speed lines, stars), except the glow of the armor cracks and eyes, which are part of the body.

Animation: Ash wave (the two ash waves are a separate effect, do not draw them). Poses in time order (counted from 1): 1) standing stance; 2) raises the glaive overhead like reference 45; 3) glaive higher; 4) both hands overhead, eyes glowing; 5) armor cracks flaring orange, raging face (face 06); 6) crouching slightly; 7) hold at the top; 8) hold (telegraph); 9) starting to plunge the glaive down; 10) IMPACT: plants the glaive blade into the ground like reference 46 (no fire); 11) IMPACT hold: kneeling low, both hands on the glaive; 12) IMPACT end; 13) pulling the glaive out of the ground; 14) rising; 15) glaive freed; 16) step back; 17) armor cracks dimming; 18) cloak settling; 19) almost back to the stance; 20) standing stance, smooth visor.
Phase map: wind-up 1-9, impact 10-12 (clear readable pose, brief hold), recovery 13-20.
This call draws ONLY poses {a} to {b} of the list above ({n} poses), continuing seamlessly from the previous strip.
```

Thay theo từng lần gọi: lần 1: {n} = 5, {a} = 1, {b} = 5; lần 2: {n} = 5, {a} = 6, {b} = 10; lần 3: {n} = 5, {a} = 11, {b} = 15; lần 4: {n} = 5, {a} = 16, {b} = 20.

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống ảnh gốc (mũ trùm giáp, mặt nạ đen trơn, vest đen, giáp vai một bên, huy hiệu trắng-đen, áo choàng rách, lưỡi móc, màu)?
2. Tỉ lệ chibi giữ nguyên; lưỡi móc luôn ở tay gần camera, không đổi tay, không bị cắt mép?
3. Nét viền, bảng màu, đổ bóng đồng nhất giữa các frame?
4. Đọc rõ ở cỡ ~300 px; với đòn đánh: pha lấy đà nhìn là biết sắp đánh?
5. `check_frames.py` ĐẠT: chân ở 464, tâm 384, không bị cắt mép khung 768×512?
6. Thân không trôi ngang trong dải (code tự dời boss khi lao)?
7. Không vẽ lửa, vệt chém, sóng tro, khói, bóng đổ, chữ bên ngoài thân?
