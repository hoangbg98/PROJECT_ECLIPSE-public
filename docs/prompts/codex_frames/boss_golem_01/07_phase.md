# Phiếu 07 — Golem Đá Cổ / `phase` (Chuyển pha)

> Claude viết tay 2026-11-19 từ `docs/design/MONSTERS.md` mục 7.3 và bảng bộ phận owner đã điền. Số frame / fps khớp
> `tools/frames/jobs/boss_golem_01.json`. Cần phiếu `../enemy_slime_01/00_CONG_CU.md` đã xong (công cụ hiểu khung của quái, đã làm ở commit 62dd87c).

## Thông số

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/boss_golem_01/phase/` |
| Số frame | **12** (2 lần gọi: 000–005, 006–011) |
| fps / lặp | 10 fps, không lặp |
| Thời lượng | 1200 ms |
| Frame trúng đòn | — |
| Khung | 768×512, tâm x = 384, chân y = 464, cao đứng ~330 px |
| Đứng đất | có: chân ở y = 464 mọi frame |

**Động tác:** Chuyển pha 1.2 s (HP ≤ 50%, boss đứng yên, bất tử): giật lùi ôm ngực – ngực nứt, ấn trắng-đen sáng dần – ngửa đầu – giơ hai nắm đấm gầm như số 37, ấn rực – mặt nứt gầm lửa (06 / 13) – khe dung nham rực khắp thân – hạ tay về thế thủ pha 2.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p01_than_day_du.png` | Thân đầy đủ (số 01): hình khối, xích vai, lõi ấn trắng-đen, màu, nét viền |
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p33_pose_dung.png` | Pose đứng (số 33): tỉ lệ, góc 3/4 quay phải |
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p37_pose_gam_chuyen_pha.png` | Gầm giơ tay, lõi sáng (số 37) |
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p06_nut_gam_lua.png` | Nứt gầm lửa (số 06) |
| `docs/prompts/codex_frames/boss_golem_01/ref/boss_golem_01_ref_p13_nong_chay.png` | Mặt nóng chảy (số 13) |

## Pose từng frame

| Frame | Giai đoạn | Pose |
|---|---|---|
| 000 | — | standing stance, staggered |
| 001 | — | recoils, clutching the chest |
| 002 | — | the chest cracks and the white-black seal starts glowing |
| 003 | — | throws the head back |
| 004 | — | arms rising |
| 005 | — | roaring with both fists up like reference 37, seal blazing bright |
| 006 | — | roar hold |
| 007 | — | cracked burning face like face 06 / 13 |
| 008 | — | lava cracks blaze across the whole body |
| 009 | — | arms coming down to a fighting stance |
| 010 | — | heavy breathing, cracks still glowing |
| 011 | — | phase-2 fighting stance, cracks brighter than idle |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `phase` cho boss Golem Đá Cổ (boss_golem_01), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/boss_golem_01/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/boss_golem_01/07_phase.md. Giữ đúng ngoại hình model gốc (ảnh 01, 33 trong ref/).
Điều kiện: docs/prompts/codex_frames/enemy_slime_01/00_CONG_CU.md đã xong (tools/frames hiểu kind = enemy). Chưa xong thì dừng và báo tôi.

1. Tạo ảnh bằng skill imagegen, 2 lần gọi (12 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới (thay {n}, {a}, {b} theo từng lần). Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/boss_golem_01/phase/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py boss_golem_01 phase <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 1.00× lúc đứng)
3. Ghi art_review/boss_golem_01/phase/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py boss_golem_01 phase — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo mục Tự kiểm tra của phiếu. Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/boss_golem_01/phase/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG commit. Chờ tôi trả lời "duyệt phase".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py boss_golem_01 phase, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: boss_golem_01 phase frames (AI)", push. Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh, mỗi lần gọi)

```text
2D side-scrolling action game sprite strip of the SAME boss as the reference images: Ancient Stone Golem, a huge hulking cartoon stone guardian boss: massive body built from big angular grey-brown boulders with thin glowing orange lava cracks; a small blocky head sunk between huge boulder shoulders, with narrow glowing yellow-orange eye slits; enormous boulder shoulders with short iron chains holding small hanging stones; a broad chest with a round seal in the middle that is half white and half black inside a dark ring; giant blocky stone forearms ending in huge fists; short thick boulder legs with blocky feet. Thick dark brown-black outline, 2-tone cel shading.
Keep the exact design, proportions, colors, dark outline thickness (3-4 px) and 2-tone cel shading of the references.
Do NOT redesign: same boulder shoulders with hanging chains, same small blocky head with glowing eye slits, same half-white half-black round seal on the chest, same huge fists and short legs; no added or removed details, no weapon.
The boss is seen in the same three-quarter view turned toward the RIGHT as the reference poses, full body visible, same scale in every pose. Keep the body centred in place: it does not travel across the strip.
One single horizontal row of exactly {n} poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: fully transparent. No ground line, no cast shadow, no text, no numbers, no frame borders, no logo, no watermark.
No visual effects outside the body (no fire, explosions, flying rocks, dust clouds, shockwaves, speed lines, stars), except the glow of the lava cracks and the chest seal, which are part of the body.

Animation: Phase transition (the boss stands still). Poses in time order (counted from 1): 1) standing stance, staggered; 2) recoils, clutching the chest; 3) the chest cracks and the white-black seal starts glowing; 4) throws the head back; 5) arms rising; 6) roaring with both fists up like reference 37, seal blazing bright; 7) roar hold; 8) cracked burning face like face 06 / 13; 9) lava cracks blaze across the whole body; 10) arms coming down to a fighting stance; 11) heavy breathing, cracks still glowing; 12) phase-2 fighting stance, cracks brighter than idle.
This call draws ONLY poses {a} to {b} of the list above ({n} poses), continuing seamlessly from the previous strip.
```

Thay theo từng lần gọi: lần 1: {n} = 6, {a} = 1, {b} = 6; lần 2: {n} = 6, {a} = 7, {b} = 12.

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống ảnh gốc (khối đá, khe dung nham, đầu nhỏ mắt khe, xích vai, ấn trắng-đen ở ngực, nắm đấm, màu)?
2. Tỉ lệ thân / vai / tay / chân giữ nguyên, ấn ngực luôn đúng vị trí và đúng nửa trắng – nửa đen?
3. Nét viền, bảng màu, đổ bóng đồng nhất giữa các frame?
4. Đọc rõ ở cỡ ~330 px; với đòn đánh: pha lấy đà dài, nhìn là biết sắp đánh?
5. `check_frames.py` ĐẠT: chân ở 464, tâm 384, không bị cắt mép khung 768×512?
6. Thân không trôi ngang trong dải (code tự dời boss khi húc)?
7. Không vẽ lửa, nổ, bụi, đá bay, sóng đất, bóng đổ, chữ bên ngoài thân?
