# Phiếu 04 — Golem Đá Cổ / `charge` (Húc)

> Claude viết tay 2026-11-19 từ `docs/design/MONSTERS.md` mục 7.3 và bảng bộ phận owner đã điền. Số frame / fps khớp
> `tools/frames/jobs/boss_golem_01.json`. Cần phiếu `../enemy_slime_01/00_CONG_CU.md` đã xong (công cụ hiểu khung của quái, đã làm ở commit 62dd87c).

## Thông số

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/boss_golem_01/charge/` |
| Số frame | **22** (4 lần gọi: 000–005, 006–011, 012–016, 017–021) |
| fps / lặp | 12 fps, không lặp |
| Thời lượng | 1800 ms — lấy đà / trúng / hồi 600/400/800 ms |
| Frame trúng đòn | 007, 008, 009, 010, 011 |
| Khung | 768×512, tâm x = 384, chân y = 464, cao đứng ~330 px |
| Đứng đất | có: chân ở y = 464 mọi frame |

**Động tác:** Húc (data pha 1: lấy đà 600 ms, lao 400 ms, hồi 800 ms; code dời boss 420 px khi lao). Lấy đà: hạ vai, khom người, cào chân sau, nghiến răng (11). Lao: chạy tại chỗ vai chĩa trước như số 35 (không bụi), giữ suốt 5 frame. Hồi: phanh, trượt dừng, đứng thẳng, về thế đứng.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p01_than_day_du.png` | Thân đầy đủ (số 01): hình khối, xích vai, lõi ấn trắng-đen, màu, nét viền |
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p33_pose_dung.png` | Pose đứng (số 33): tỉ lệ, góc 3/4 quay phải |
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p35_pose_lao_huc.png` | Lao húc (số 35): pose TRÚNG ĐÒN — bỏ bụi |
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p11_nghien_rang.png` | Nghiến răng gồng (số 11) |

## Pose từng frame

| Frame | Giai đoạn | Pose |
|---|---|---|
| 000 | Lấy đà | standing stance |
| 001 | Lấy đà | lowers the shoulder, gritting teeth (face 11) |
| 002 | Lấy đà | crouches forward, one foot back |
| 003 | Lấy đà | scrapes the ground with the back foot |
| 004 | Lấy đà | deeper crouch, shoulder forward like a battering ram |
| 005 | Lấy đà | coiled, chest seal glowing |
| 006 | Lấy đà | last wind-up pose |
| 007 | **Trúng đòn** | IMPACT: charging shoulder-first, low, like reference 35 (no dust) |
| 008 | **Trúng đòn** | charge, mid-stride |
| 009 | **Trúng đòn** | charge, other foot forward |
| 010 | **Trúng đòn** | charge, mid-stride |
| 011 | **Trúng đòn** | charge, final ram pose |
| 012 | Hồi | braking, front foot planted |
| 013 | Hồi | skidding to a stop, body leaning back |
| 014 | Hồi | regaining balance |
| 015 | Hồi | straightening up |
| 016 | Hồi | shaking the shoulders, chains swinging |
| 017 | Hồi | arms settle |
| 018 | Hồi | breathing heavily |
| 019 | Hồi | cracks dimming |
| 020 | Hồi | almost back to the stance |
| 021 | Hồi | standing stance, default face |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `charge` cho boss Golem Đá Cổ (boss_golem_01), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/boss_golem_01/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/boss_golem_01/04_charge.md. Giữ đúng ngoại hình model gốc (ảnh 01, 33 trong ref/).
Điều kiện: docs/prompts/codex_frames/enemy_slime_01/00_CONG_CU.md đã xong (tools/frames hiểu kind = enemy). Chưa xong thì dừng và báo tôi.

1. Tạo ảnh bằng skill imagegen, 4 lần gọi (22 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/boss_golem_01/charge/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py boss_golem_01 charge <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 1.00× lúc đứng)
3. Ghi art_review/boss_golem_01/charge/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py boss_golem_01 charge — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo mục Tự kiểm tra của phiếu. Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/boss_golem_01/charge/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG commit. Chờ tôi trả lời "duyệt charge".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py boss_golem_01 charge, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: boss_golem_01 charge frames (AI)", push. Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
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

Animation: Shoulder charge (the body stays centred: the game moves the boss 420 px during the charge, so the run is drawn in place). Poses in time order (counted from 1): 1) standing stance; 2) lowers the shoulder, gritting teeth (face 11); 3) crouches forward, one foot back; 4) scrapes the ground with the back foot; 5) deeper crouch, shoulder forward like a battering ram; 6) coiled, chest seal glowing; 7) last wind-up pose; 8) IMPACT: charging shoulder-first, low, like reference 35 (no dust); 9) charge, mid-stride; 10) charge, other foot forward; 11) charge, mid-stride; 12) charge, final ram pose; 13) braking, front foot planted; 14) skidding to a stop, body leaning back; 15) regaining balance; 16) straightening up; 17) shaking the shoulders, chains swinging; 18) arms settle; 19) breathing heavily; 20) cracks dimming; 21) almost back to the stance; 22) standing stance, default face.
Phase map: wind-up 1-7, impact 8-12 (clear readable pose, brief hold), recovery 13-22.
This call draws ONLY poses {a} to {b} of the list above ({n} poses), continuing seamlessly from the previous strip.
```

Thay theo từng lần gọi: lần 1: {n} = 6, {a} = 1, {b} = 6; lần 2: {n} = 6, {a} = 7, {b} = 12; lần 3: {n} = 5, {a} = 13, {b} = 17; lần 4: {n} = 5, {a} = 18, {b} = 22.

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống ảnh gốc (khối đá, khe dung nham, đầu nhỏ mắt khe, xích vai, ấn trắng-đen ở ngực, nắm đấm, màu)?
2. Tỉ lệ thân / vai / tay / chân giữ nguyên, ấn ngực luôn đúng vị trí và đúng nửa trắng – nửa đen?
3. Nét viền, bảng màu, đổ bóng đồng nhất giữa các frame?
4. Đọc rõ ở cỡ ~330 px; với đòn đánh: pha lấy đà dài, nhìn là biết sắp đánh?
5. `check_frames.py` ĐẠT: chân ở 464, tâm 384, không bị cắt mép khung 768×512?
6. Thân không trôi ngang trong dải (code tự dời boss khi húc)?
7. Không vẽ lửa, nổ, bụi, đá bay, sóng đất, bóng đổ, chữ bên ngoài thân?
