# Phiếu 05 — Golem Đá Cổ / `quake` (Địa chấn)

> Claude viết tay 2026-11-19 từ `docs/design/MONSTERS.md` mục 7.3 và bảng bộ phận owner đã điền. Số frame / fps khớp
> `tools/frames/jobs/boss_golem_01.json`. Cần phiếu `../enemy_slime_01/00_CONG_CU.md` đã xong (công cụ hiểu khung của quái, đã làm ở commit 62dd87c).

## Thông số

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/boss_golem_01/quake/` |
| Số frame | **20** (4 lần gọi: 000–004, 005–009, 010–014, 015–019) |
| fps / lặp | 12 fps, không lặp |
| Thời lượng | 1700 ms — lấy đà / trúng / hồi 800/200/700 ms |
| Frame trúng đòn | 009, 010, 011 |
| Khung | 768×512, tâm x = 384, chân y = 464, cao đứng ~330 px |
| Đứng đất | có: chân ở y = 464 mọi frame |

**Động tác:** Địa chấn (chỉ pha 2; data: lấy đà 800 ms, giậm 200 ms, hồi 700 ms). Lấy đà: nhấc gối cao, giơ hai tay như số 38, hét (12) rồi gầm (15), khe dung nham rực dần. Trúng đòn: giậm mạnh xuống đất cả thân hạ thấp. Hai sóng đất chạy hai phía là VFX riêng, **không vẽ**. Hồi: đứng dậy, về thế đứng.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p01_than_day_du.png` | Thân đầy đủ (số 01): hình khối, xích vai, lõi ấn trắng-đen, màu, nét viền |
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p33_pose_dung.png` | Pose đứng (số 33): tỉ lệ, góc 3/4 quay phải |
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p38_pose_dia_chan.png` | Bùng nổ (số 38): dáng giơ tay giậm — bỏ lửa, đá, nổ |
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p12_het.png` | Hét (số 12) |
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p15_nut_gam_lua_2.png` | Nứt gầm lửa (số 15) |

## Pose từng frame

| Frame | Giai đoạn | Pose |
|---|---|---|
| 000 | Lấy đà | standing stance |
| 001 | Lấy đà | shouting (face 12), lifting one knee |
| 002 | Lấy đà | knee higher |
| 003 | Lấy đà | raising both arms |
| 004 | Lấy đà | knee high, arms high, lava cracks glowing |
| 005 | Lấy đà | cracks blazing, raging cracked face (face 15) |
| 006 | Lấy đà | chest seal glowing bright |
| 007 | Lấy đà | maximum wind-up hold like reference 38 (no fire) |
| 008 | Lấy đà | starting to stomp down |
| 009 | **Trúng đòn** | IMPACT: stomps the ground with full weight, arms swinging down |
| 010 | **Trúng đòn** | IMPACT hold: body low, both feet planted |
| 011 | **Trúng đòn** | IMPACT end |
| 012 | Hồi | rising |
| 013 | Hồi | straightening up |
| 014 | Hồi | arms lowering |
| 015 | Hồi | cracks dimming |
| 016 | Hồi | shoulders settle |
| 017 | Hồi | face calming |
| 018 | Hồi | almost back to the stance |
| 019 | Hồi | standing stance, default face |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `quake` cho boss Golem Đá Cổ (boss_golem_01), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/boss_golem_01/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/boss_golem_01/05_quake.md. Giữ đúng ngoại hình model gốc (ảnh 01, 33 trong ref/).
Điều kiện: docs/prompts/codex_frames/enemy_slime_01/00_CONG_CU.md đã xong (tools/frames hiểu kind = enemy). Chưa xong thì dừng và báo tôi.

1. Tạo ảnh bằng skill imagegen, 4 lần gọi (20 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/boss_golem_01/quake/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py boss_golem_01 quake <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 1.00× lúc đứng)
3. Ghi art_review/boss_golem_01/quake/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py boss_golem_01 quake — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo mục Tự kiểm tra của phiếu. Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/boss_golem_01/quake/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG commit. Chờ tôi trả lời "duyệt quake".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py boss_golem_01 quake, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: boss_golem_01 quake frames (AI)", push. Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
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

Animation: Quake stomp (the two ground waves are a separate effect, do not draw them). Poses in time order (counted from 1): 1) standing stance; 2) shouting (face 12), lifting one knee; 3) knee higher; 4) raising both arms; 5) knee high, arms high, lava cracks glowing; 6) cracks blazing, raging cracked face (face 15); 7) chest seal glowing bright; 8) maximum wind-up hold like reference 38 (no fire); 9) starting to stomp down; 10) IMPACT: stomps the ground with full weight, arms swinging down; 11) IMPACT hold: body low, both feet planted; 12) IMPACT end; 13) rising; 14) straightening up; 15) arms lowering; 16) cracks dimming; 17) shoulders settle; 18) face calming; 19) almost back to the stance; 20) standing stance, default face.
Phase map: wind-up 1-9, impact 10-12 (clear readable pose, brief hold), recovery 13-20.
This call draws ONLY poses {a} to {b} of the list above ({n} poses), continuing seamlessly from the previous strip.
```

Thay theo từng lần gọi: lần 1: {n} = 5, {a} = 1, {b} = 5; lần 2: {n} = 5, {a} = 6, {b} = 10; lần 3: {n} = 5, {a} = 11, {b} = 15; lần 4: {n} = 5, {a} = 16, {b} = 20.

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống ảnh gốc (khối đá, khe dung nham, đầu nhỏ mắt khe, xích vai, ấn trắng-đen ở ngực, nắm đấm, màu)?
2. Tỉ lệ thân / vai / tay / chân giữ nguyên, ấn ngực luôn đúng vị trí và đúng nửa trắng – nửa đen?
3. Nét viền, bảng màu, đổ bóng đồng nhất giữa các frame?
4. Đọc rõ ở cỡ ~330 px; với đòn đánh: pha lấy đà dài, nhìn là biết sắp đánh?
5. `check_frames.py` ĐẠT: chân ở 464, tâm 384, không bị cắt mép khung 768×512?
6. Thân không trôi ngang trong dải (code tự dời boss khi húc)?
7. Không vẽ lửa, nổ, bụi, đá bay, sóng đất, bóng đổ, chữ bên ngoài thân?
