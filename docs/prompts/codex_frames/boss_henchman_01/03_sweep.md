# Phiếu 03 — Kẻ Đeo Mặt Nạ / `sweep` (Chém quét)

> Claude viết tay 2026-11-19 từ `docs/design/MONSTERS.md` mục 7.4 và bảng bộ phận owner đã điền. Số frame / fps khớp
> `tools/frames/jobs/boss_henchman_01.json`. Cần phiếu `../enemy_slime_01/00_CONG_CU.md` đã xong (công cụ hiểu khung của quái, đã làm ở commit 62dd87c).

## Thông số

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/boss_henchman_01/sweep/` |
| Số frame | **17** (3 lần gọi: 000–005, 006–011, 012–016) |
| fps / lặp | 12 fps, không lặp |
| Thời lượng | 1410 ms — lấy đà / trúng / hồi 600/160/650 ms |
| Frame trúng đòn | 007, 008, 009 |
| Khung | 768×512, tâm x = 384, chân y = 464, cao đứng ~300 px |
| Đứng đất | có: chân ở y = 464 mọi frame |

**Động tác:** Chém quét lưỡi móc (data pha 1: lấy đà 600 ms, trúng 160 ms, hồi 650 ms; pha 2 code phát nhanh hơn). Lấy đà rõ — **người chơi né theo pha này**: dồn trọng tâm ra sau, vung lưỡi móc ra sau vai, mắt khe sáng (03). Trúng đòn: quét ngang mạnh về phía trước như số 44 (không vệt lửa), lưỡi duỗi hết. Hồi: lưỡi đi tiếp, áo choàng rủ, lùi nửa bước, về thế đứng.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `docs/prompts/codex_frames/boss_henchman_01/ref/boss_henchman_01_ref_p01_than_day_du.png` | Thân đầy đủ (số 01): trang phục, giáp, mặt nạ, lưỡi móc, màu, nét viền |
| `docs/prompts/codex_frames/boss_henchman_01/ref/boss_henchman_01_ref_p41_pose_dung.png` | Pose đứng (số 41): tỉ lệ chibi, góc nhìn, cách cầm lưỡi móc |
| `docs/prompts/codex_frames/boss_henchman_01/ref/boss_henchman_01_ref_p44_pose_chem_quet.png` | Chém quét (số 44): pose TRÚNG ĐÒN — bỏ vệt lửa |
| `docs/prompts/codex_frames/boss_henchman_01/ref/boss_henchman_01_ref_p03_mat_khe.png` | Mắt khe (số 03) |
| `docs/prompts/codex_frames/boss_henchman_01/ref/boss_henchman_01_ref_p30_luoi_moc.png` | Lưỡi móc (số 30) |

## Pose từng frame

| Frame | Giai đoạn | Pose |
|---|---|---|
| 000 | Lấy đà | standing stance, glaive held low |
| 001 | Lấy đà | shifts weight back, eyes narrow and glow (face 03) |
| 002 | Lấy đà | swings the glaive back over the shoulder |
| 003 | Lấy đà | glaive behind, body twisted, cloak flaring |
| 004 | Lấy đà | coiled, ready to strike |
| 005 | Lấy đà | last wind-up: small step forward |
| 006 | Lấy đà | starting the swing |
| 007 | **Trúng đòn** | IMPACT: horizontal sweep, blade fully extended in front like reference 44 (no fire trail) |
| 008 | **Trúng đòn** | IMPACT follow-through: blade passing in front |
| 009 | **Trúng đòn** | IMPACT end: blade reaches the far side |
| 010 | Hồi | the blade continues around |
| 011 | Hồi | cloak settling |
| 012 | Hồi | half step back |
| 013 | Hồi | glaive lowering |
| 014 | Hồi | straightening up |
| 015 | Hồi | almost back to the stance |
| 016 | Hồi | standing stance, smooth visor |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `sweep` cho boss Kẻ Đeo Mặt Nạ (boss_henchman_01), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/boss_henchman_01/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/boss_henchman_01/03_sweep.md. Giữ đúng ngoại hình model gốc (ảnh 01, 41 trong ref/).
Điều kiện: docs/prompts/codex_frames/enemy_slime_01/00_CONG_CU.md đã xong (tools/frames hiểu kind = enemy). Chưa xong thì dừng và báo tôi.

1. Tạo ảnh bằng skill imagegen, 3 lần gọi (17 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/boss_henchman_01/sweep/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py boss_henchman_01 sweep <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 1.00× lúc đứng)
3. Ghi art_review/boss_henchman_01/sweep/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py boss_henchman_01 sweep — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo mục Tự kiểm tra của phiếu. Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/boss_henchman_01/sweep/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG commit. Chờ tôi trả lời "duyệt sweep".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py boss_henchman_01 sweep, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: boss_henchman_01 sweep frames (AI)", push. Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh, mỗi lần gọi)

```text
2D side-scrolling action game sprite strip of the SAME boss as the reference images: The masked henchman, a chibi anime boss (big head, compact body, about 2.5 heads tall): a smooth rounded dark charcoal-grey helmet-hood made of armored plates with thin glowing orange cracks, covering the whole head; a faceless glossy black visor (no eyes, no mouth) whose eye glow appears only when angry; a dark scarf around the neck; a black three-piece suit (vest, shirt and tie) under an open dark coat; ONE large dark armored pauldron on the shoulder nearest the viewer, with orange cracks; a small round emblem half white and half black on the lapel; armored dark gauntlets; black trousers; dark armored greaves and boots with orange cracks; a long tattered charcoal cloak. Weapon: a long black hooked glaive (a pole with a large curved dark blade with glowing orange cracks), always held in the hand.
Keep the exact design, chibi proportions (big head, short limbs), colors, dark outline thickness (2-3 px) and cel shading of the references.
Do NOT redesign: same armored hood-helmet with orange cracks, same faceless black visor, same black suit vest and tie under the open coat, same single large pauldron on the near shoulder, same white-black lapel emblem, same tattered cloak, same hooked glaive; no added or removed details.
The boss faces RIGHT in every pose (side / three-quarter view like reference poses 42-46), full body visible, same scale in every pose. Keep the body centred in place: it does not travel across the strip.
One single horizontal row of exactly {n} poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching; leave room for the glaive).
Background: fully transparent. No ground line, no cast shadow, no text, no numbers, no frame borders, no logo, no watermark.
No visual effects outside the body (no fire, slash trails, ash waves, smoke, sparks, speed lines, stars).

Animation: Horizontal glaive sweep. Poses in time order (counted from 1): 1) standing stance, glaive held low; 2) shifts weight back, eyes narrow and glow (face 03); 3) swings the glaive back over the shoulder; 4) glaive behind, body twisted, cloak flaring; 5) coiled, ready to strike; 6) last wind-up: small step forward; 7) starting the swing; 8) IMPACT: horizontal sweep, blade fully extended in front like reference 44 (no fire trail); 9) IMPACT follow-through: blade passing in front; 10) IMPACT end: blade reaches the far side; 11) the blade continues around; 12) cloak settling; 13) half step back; 14) glaive lowering; 15) straightening up; 16) almost back to the stance; 17) standing stance, smooth visor.
Phase map: wind-up 1-7, impact 8-10 (clear readable pose, brief hold), recovery 11-17.
This call draws ONLY poses {a} to {b} of the list above ({n} poses), continuing seamlessly from the previous strip.
```

Thay theo từng lần gọi: lần 1: {n} = 6, {a} = 1, {b} = 6; lần 2: {n} = 6, {a} = 7, {b} = 12; lần 3: {n} = 5, {a} = 13, {b} = 17.

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống ảnh gốc (mũ trùm giáp, mặt nạ đen trơn, vest đen, giáp vai một bên, huy hiệu trắng-đen, áo choàng rách, lưỡi móc, màu)?
2. Tỉ lệ chibi giữ nguyên; lưỡi móc luôn ở tay gần camera, không đổi tay, không bị cắt mép?
3. Nét viền, bảng màu, đổ bóng đồng nhất giữa các frame?
4. Đọc rõ ở cỡ ~300 px; với đòn đánh: pha lấy đà nhìn là biết sắp đánh?
5. `check_frames.py` ĐẠT: chân ở 464, tâm 384, không bị cắt mép khung 768×512?
6. Thân không trôi ngang trong dải (code tự dời boss khi lao)?
7. Không vẽ lửa, vệt chém, sóng tro, khói, bóng đổ, chữ bên ngoài thân?
