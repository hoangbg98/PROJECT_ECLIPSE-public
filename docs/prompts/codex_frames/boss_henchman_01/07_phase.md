# Phiếu 07 — Kẻ Đeo Mặt Nạ / `phase` (Chuyển pha)

> Claude viết tay 2026-11-19 từ `docs/design/MONSTERS.md` mục 7.4 và bảng bộ phận owner đã điền. Số frame / fps khớp
> `tools/frames/jobs/boss_henchman_01.json`. Cần phiếu `../enemy_slime_01/00_CONG_CU.md` đã xong (công cụ hiểu khung của quái, đã làm ở commit 62dd87c).

## Thông số

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/boss_henchman_01/phase/` |
| Số frame | **12** (2 lần gọi: 000–005, 006–011) |
| fps / lặp | 10 fps, không lặp |
| Thời lượng | 1200 ms |
| Frame trúng đòn | — |
| Khung | 768×512, tâm x = 384, chân y = 464, cao đứng ~300 px |
| Đứng đất | có: chân ở y = 464 mọi frame |

**Động tác:** Chuyển pha 1.2 s (HP ≤ 50%, boss đứng yên, bất tử): lảo đảo ôm mặt nạ – mặt nạ nứt, mắt giận rực (06) – khe giáp bừng cam – dang tay, giơ lưỡi móc – áo choàng quất – hạ lưỡi móc về thế thủ pha 2, khe giáp sáng hơn idle.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `docs/prompts/codex_frames/boss_henchman_01/ref/boss_henchman_01_ref_p01_than_day_du.png` | Thân đầy đủ (số 01): trang phục, giáp, mặt nạ, lưỡi móc, màu, nét viền |
| `docs/prompts/codex_frames/boss_henchman_01/ref/boss_henchman_01_ref_p41_pose_dung.png` | Pose đứng (số 41): tỉ lệ chibi, góc nhìn, cách cầm lưỡi móc |
| `docs/prompts/codex_frames/boss_henchman_01/ref/boss_henchman_01_ref_p06_gian_nut.png` | Giận rực, mặt nạ nứt (số 06) |
| `docs/prompts/codex_frames/boss_henchman_01/ref/boss_henchman_01_ref_p45_pose_gio_luoi.png` | Giơ lưỡi móc (số 45) |

## Pose từng frame

| Frame | Giai đoạn | Pose |
|---|---|---|
| 000 | — | standing stance, staggered |
| 001 | — | clutches the mask with the free hand |
| 002 | — | the mask cracks, raging glowing eyes (face 06) |
| 003 | — | armor cracks flare orange |
| 004 | — | throws the arms wide |
| 005 | — | raises the glaive high |
| 006 | — | hold, cloak lifting |
| 007 | — | cloak whips around |
| 008 | — | swings the glaive down |
| 009 | — | lands in a combat stance |
| 010 | — | armor cracks glowing brighter |
| 011 | — | phase-2 combat stance, cracks brighter than idle |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `phase` cho boss Kẻ Đeo Mặt Nạ (boss_henchman_01), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/boss_henchman_01/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/boss_henchman_01/07_phase.md. Giữ đúng ngoại hình model gốc (ảnh 01, 41 trong ref/).
Điều kiện: docs/prompts/codex_frames/enemy_slime_01/00_CONG_CU.md đã xong (tools/frames hiểu kind = enemy). Chưa xong thì dừng và báo tôi.

1. Tạo ảnh bằng skill imagegen, 2 lần gọi (12 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/boss_henchman_01/phase/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py boss_henchman_01 phase <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 1.00× lúc đứng)
3. Ghi art_review/boss_henchman_01/phase/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py boss_henchman_01 phase — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo mục Tự kiểm tra của phiếu. Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/boss_henchman_01/phase/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG commit. Chờ tôi trả lời "duyệt phase".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py boss_henchman_01 phase, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: boss_henchman_01 phase frames (AI)", push. Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
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

Animation: Phase transition (the boss stands still). Poses in time order (counted from 1): 1) standing stance, staggered; 2) clutches the mask with the free hand; 3) the mask cracks, raging glowing eyes (face 06); 4) armor cracks flare orange; 5) throws the arms wide; 6) raises the glaive high; 7) hold, cloak lifting; 8) cloak whips around; 9) swings the glaive down; 10) lands in a combat stance; 11) armor cracks glowing brighter; 12) phase-2 combat stance, cracks brighter than idle.
This call draws ONLY poses {a} to {b} of the list above ({n} poses), continuing seamlessly from the previous strip.
```

Thay theo từng lần gọi: lần 1: {n} = 6, {a} = 1, {b} = 6; lần 2: {n} = 6, {a} = 7, {b} = 12.

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống ảnh gốc (mũ trùm giáp, mặt nạ đen trơn, vest đen, giáp vai một bên, huy hiệu trắng-đen, áo choàng rách, lưỡi móc, màu)?
2. Tỉ lệ chibi giữ nguyên; lưỡi móc luôn ở tay gần camera, không đổi tay, không bị cắt mép?
3. Nét viền, bảng màu, đổ bóng đồng nhất giữa các frame?
4. Đọc rõ ở cỡ ~300 px; với đòn đánh: pha lấy đà nhìn là biết sắp đánh?
5. `check_frames.py` ĐẠT: chân ở 464, tâm 384, không bị cắt mép khung 768×512?
6. Thân không trôi ngang trong dải (code tự dời boss khi lao)?
7. Không vẽ lửa, vệt chém, sóng tro, khói, bóng đổ, chữ bên ngoài thân?
