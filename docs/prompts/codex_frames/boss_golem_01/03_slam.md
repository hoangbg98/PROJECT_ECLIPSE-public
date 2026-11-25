# Phiếu 03 — Golem Đá Cổ / `slam` (Đập đất)

> Claude viết tay 2026-11-19 từ `docs/design/MONSTERS.md` mục 7.3 và bảng bộ phận owner đã điền. Số frame / fps khớp
> `tools/frames/jobs/boss_golem_01.json`. Cần phiếu `../enemy_slime_01/00_CONG_CU.md` đã xong (công cụ hiểu khung của quái, đã làm ở commit 62dd87c).

## Thông số

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/boss_golem_01/slam/` |
| Số frame | **19** (4 lần gọi: 000–004, 005–009, 010–014, 015–018) |
| fps / lặp | 12 fps, không lặp |
| Thời lượng | 1550 ms — lấy đà / trúng / hồi 700/150/700 ms |
| Frame trúng đòn | 008, 009, 010 |
| Khung | 768×512, tâm x = 384, chân y = 464, cao đứng ~330 px |
| Đứng đất | có: chân ở y = 464 mọi frame |

**Động tác:** Đập đất (data pha 1: lấy đà 700 ms, trúng 150 ms, hồi 700 ms; pha 2 code phát nhanh hơn). Lấy đà dài và rõ — **người chơi né theo pha này**: giơ hai nắm đấm lên cao quá đầu, ngả người ra sau, mặt giận (03), ấn ngực sáng dần. Trúng đòn: đập mạnh hai nắm đấm xuống đất phía trước như số 36 (không lửa), giữ rõ. Hồi: rút tay, đứng dậy, về thế đứng.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p01_than_day_du.png` | Thân đầy đủ (số 01): hình khối, xích vai, lõi ấn trắng-đen, màu, nét viền |
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p33_pose_dung.png` | Pose đứng (số 33): tỉ lệ, góc 3/4 quay phải |
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p36_pose_dap_dat.png` | Đập tay xuống đất (số 36): pose TRÚNG ĐÒN — bỏ lửa |
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p03_gian.png` | Giận (số 03) |
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p37_pose_gam_chuyen_pha.png` | Giơ tay (số 37): tham chiếu lúc giơ hai nắm đấm |

## Pose từng frame

| Frame | Giai đoạn | Pose |
|---|---|---|
| 000 | Lấy đà | standing stance, default face (face 02) |
| 001 | Lấy đà | starts raising both fists, angry face (face 03) |
| 002 | Lấy đà | fists rising above the shoulders |
| 003 | Lấy đà | both fists high overhead, body leaning back |
| 004 | Lấy đà | fists overhead, chest seal glowing brighter |
| 005 | Lấy đà | maximum wind-up, body arched back |
| 006 | Lấy đà | brief hold at the top (telegraph) |
| 007 | Lấy đà | swinging both fists down fast |
| 008 | **Trúng đòn** | IMPACT: both fists smash the ground in front like reference 36 (no fire) |
| 009 | **Trúng đòn** | IMPACT hold: fists on the ground, body bent low forward |
| 010 | **Trúng đòn** | IMPACT end: fists still pressed on the ground |
| 011 | Hồi | lifting the fists off the ground |
| 012 | Hồi | pulling the arms back |
| 013 | Hồi | straightening the back |
| 014 | Hồi | standing up halfway |
| 015 | Hồi | arms lowering to the sides |
| 016 | Hồi | shoulders and chains settle |
| 017 | Hồi | almost back to the stance |
| 018 | Hồi | standing stance, default face |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `slam` cho boss Golem Đá Cổ (boss_golem_01), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/boss_golem_01/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/boss_golem_01/03_slam.md. Giữ đúng ngoại hình model gốc (ảnh 01, 33 trong ref/).
Điều kiện: docs/prompts/codex_frames/enemy_slime_01/00_CONG_CU.md đã xong (tools/frames hiểu kind = enemy). Chưa xong thì dừng và báo tôi.

1. Tạo ảnh bằng skill imagegen, 4 lần gọi (19 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/boss_golem_01/slam/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py boss_golem_01 slam <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 1.00× lúc đứng)
3. Ghi art_review/boss_golem_01/slam/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py boss_golem_01 slam — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo mục Tự kiểm tra của phiếu. Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/boss_golem_01/slam/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG commit. Chờ tôi trả lời "duyệt slam".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py boss_golem_01 slam, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: boss_golem_01 slam frames (AI)", push. Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh, mỗi lần gọi)

```text
2D side-scrolling action game sprite strip of the SAME boss as the reference images: Ancient Stone Golem, a huge hulking cartoon stone guardian boss: massive body built from big angular grey-brown boulders with thin glowing orange lava cracks; a small blocky head sunk between huge boulder shoulders, with narrow glowing yellow-orange eye slits; enormous boulder shoulders with short iron chains holding small hanging stones; a broad chest with a round seal in the middle that is half white and half black inside a dark ring; giant blocky stone forearms ending in huge fists; short thick boulder legs with blocky feet. Thick dark brown-black outline, 2-tone cel shading.
Keep the exact design, proportions, colors, dark outline thickness (3-4 px) and 2-tone cel shading of the references.
Do NOT redesign: same boulder shoulders with hanging chains, same small blocky head with glowing eye slits, same half-white half-black round seal on the chest, same huge fists and short legs; no added or removed details, no weapon.
The boss is seen in the same three-quarter view turned toward the RIGHT as the reference poses, full body visible, same scale in every pose. Keep the body centred in place: it does not travel across the strip.
One single horizontal row of exactly {n} poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: fully transparent. No ground line, no cast shadow, no text, no numbers, no frame borders, no logo, no watermark.
No visual effects outside the body (no fire, explosions, flying rocks, dust clouds, shockwaves, speed lines, stars).

Animation: Ground slam. Poses in time order (counted from 1): 1) standing stance, default face (face 02); 2) starts raising both fists, angry face (face 03); 3) fists rising above the shoulders; 4) both fists high overhead, body leaning back; 5) fists overhead, chest seal glowing brighter; 6) maximum wind-up, body arched back; 7) brief hold at the top (telegraph); 8) swinging both fists down fast; 9) IMPACT: both fists smash the ground in front like reference 36 (no fire); 10) IMPACT hold: fists on the ground, body bent low forward; 11) IMPACT end: fists still pressed on the ground; 12) lifting the fists off the ground; 13) pulling the arms back; 14) straightening the back; 15) standing up halfway; 16) arms lowering to the sides; 17) shoulders and chains settle; 18) almost back to the stance; 19) standing stance, default face.
Phase map: wind-up 1-8, impact 9-11 (clear readable pose, brief hold), recovery 12-19.
This call draws ONLY poses {a} to {b} of the list above ({n} poses), continuing seamlessly from the previous strip.
```

Thay theo từng lần gọi: lần 1: {n} = 5, {a} = 1, {b} = 5; lần 2: {n} = 5, {a} = 6, {b} = 10; lần 3: {n} = 5, {a} = 11, {b} = 15; lần 4: {n} = 4, {a} = 16, {b} = 19.

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống ảnh gốc (khối đá, khe dung nham, đầu nhỏ mắt khe, xích vai, ấn trắng-đen ở ngực, nắm đấm, màu)?
2. Tỉ lệ thân / vai / tay / chân giữ nguyên, ấn ngực luôn đúng vị trí và đúng nửa trắng – nửa đen?
3. Nét viền, bảng màu, đổ bóng đồng nhất giữa các frame?
4. Đọc rõ ở cỡ ~330 px; với đòn đánh: pha lấy đà dài, nhìn là biết sắp đánh?
5. `check_frames.py` ĐẠT: chân ở 464, tâm 384, không bị cắt mép khung 768×512?
6. Thân không trôi ngang trong dải (code tự dời boss khi húc)?
7. Không vẽ lửa, nổ, bụi, đá bay, sóng đất, bóng đổ, chữ bên ngoài thân?
