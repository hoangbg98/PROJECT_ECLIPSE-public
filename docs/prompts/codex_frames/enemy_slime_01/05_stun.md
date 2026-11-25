# Phiếu 05 — Cặn tro / `stun` (Choáng)

> Claude viết tay 2026-11-19 từ `docs/design/MONSTERS.md` mục 7.1 và bảng bộ phận owner đã điền. Số frame / fps khớp
> `tools/frames/jobs/enemy_slime_01.json`. Cần làm phiếu `00_CONG_CU.md` trước (công cụ hiểu khung 256 của quái).

## Thông số

| Mục | Giá trị |
|---|---|
| Thư mục chờ duyệt | `art_review/enemy_slime_01/stun/` |
| Số frame | **6** (1 lần gọi: 000–005) |
| fps / lặp | 8 fps, lặp liền mạch |
| Thời lượng | 750 ms |
| Frame trúng đòn | — |
| Khung | 256×256, tâm x = 128, chân y = 224, cao đứng ~100 px |
| Đứng đất | có: chân ở y = 224 mọi frame |

**Động tác:** Choáng 2 s: thu thấp cuộn tròn như số 38, mặt mắt xoáy (28), lảo đảo chậm trái – phải, phiến vảy rủ xuống. Không vẽ sao / vòng choáng (game tự hiện chữ). Lặp liền.

## Ảnh đính kèm cho Codex

| File | Dùng để |
|---|---|
| `docs/prompts/codex_frames/enemy_slime_01/ref/enemy_slime_01_ref_p01_than_day_du.png` | Thân đầy đủ (số 01): hình khối, lớp vảy, màu, nét viền |
| `docs/prompts/codex_frames/enemy_slime_01/ref/enemy_slime_01_ref_p36_pose_dung_rung.png` | Pose đứng (số 36): tỉ lệ thân / chân, góc nhìn ngang |
| `docs/prompts/codex_frames/enemy_slime_01/ref/enemy_slime_01_ref_p38_pose_cuon_tron.png` | Cuộn tròn (số 38): dáng choáng |
| `docs/prompts/codex_frames/enemy_slime_01/ref/enemy_slime_01_ref_p28_choang.png` | Choáng mắt xoáy (số 28) |

## Prompt dán cho Codex

```text
Việc: tạo frame animation `stun` cho quái Cặn tro (enemy_slime_01), MỘT animation này thôi. Đọc theo thứ tự: AGENTS.md (mục Ảnh do AI tạo),
docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/enemy_slime_01/00_PHAN_TICH.md rồi phiếu
docs/prompts/codex_frames/enemy_slime_01/05_stun.md. Giữ đúng ngoại hình model gốc (ảnh 01, 36 trong ref/).
Điều kiện: phiếu 00_CONG_CU.md đã xong (tools/frames hiểu kind = enemy). Chưa xong thì dừng và báo tôi.

1. Tạo ảnh bằng skill imagegen, 1 lần gọi (6 pose). Mỗi lần: một hàng ngang đúng số pose của lần đó,
   dùng prompt ảnh tiếng Anh bên dưới. Đính kèm các ảnh tham chiếu trong phiếu;
   từ lần gọi thứ 2, đính kèm thêm dải vừa tạo để giữ liền mạch. Nếu không ra nền trong suốt: nền #FF00FF.
2. Chép các dải đã chọn vào art_review/enemy_slime_01/stun/_strips/ rồi cắt:
   python -I tools/frames/slice_strip.py enemy_slime_01 stun <dải 1> [<dải 2> ...] --like idle [--chroma FF00FF]
   (--like idle: cùng tỉ lệ với idle đã duyệt; canh theo frame 0, cao 0.80× lúc đứng)
3. Ghi art_review/enemy_slime_01/stun/meta.json: {"tool": "Codex imagegen", "model": "<model>",
   "prompt": "<prompt rút gọn>", "refs": [<ảnh tham chiếu đã đính kèm>], "date": "YYYY-MM-DD"}
   (giữ các khóa scale/strips mà slice_strip.py đã ghi).
4. Kiểm tra: python -I tools/frames/check_frames.py enemy_slime_01 stun — phải ĐẠT; lỗi thì tạo lại đúng frame lỗi.
5. Tự soát theo mục Tự kiểm tra của phiếu. Sửa frame sai lệch ngoại hình dựa trên ảnh gốc.
6. DỪNG: gửi tôi art_review/enemy_slime_01/stun/_preview/sheet.png và anim.gif, liệt kê frame còn nghi ngờ.
   KHÔNG chép vào assets/, KHÔNG commit. Chờ tôi trả lời "duyệt stun".
7. Khi tôi duyệt: python -I tools/frames/approve_frames.py enemy_slime_01 stun, chạy
   powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0), ghi docs/DEVELOPMENT_LOG.md,
   commit "Art: enemy_slime_01 stun frames (AI)", push. Khi tôi yêu cầu sửa: chỉ tạo lại các frame tôi chỉ ra.
```

## Prompt ảnh (tiếng Anh)

```text
2D side-scrolling action game sprite strip of the SAME monster as the reference images: Ash Dreg, a small cartoon rock-ash blob monster: a squat mound / cone-shaped body built from overlapping grey-brown stone-ash flakes layered like roof shingles, thick dark brown-black outline, 2-tone cel shading, tiny glowing orange ember specks and thin orange cracks between the flakes; two round glowing orange eyes with bright yellow-orange centres and a simple small dark mouth on the front of the mound (no nose, no ears, no arms); two short stubby stone feet under the mound.
Keep the exact design, proportions, colors, dark outline thickness (2-3 px) and 2-tone cel shading of the references.
Do NOT redesign: same flake shapes, same round glowing orange eyes, same small mouth, same stubby stone feet; no added or removed details, no arms, no weapon.
The monster faces RIGHT in every pose, full body visible, same scale in every pose. Keep the body centred in place: it does not travel across the strip.
One single horizontal row of exactly 6 poses, left to right in time order, with wide empty gaps between poses (no overlap, no touching).
Background: fully transparent. No ground line, no cast shadow, no text, no numbers, no frame borders, no logo, no watermark.
No visual effects (no speed lines, dust, flying rocks, sparks, stars, glow outside the body).

Animation: Stunned loop: the body sags low and curls up like reference 38, dizzy swirl eyes like face 28, slowly wobbling left and right, flakes drooping. No stars, no dizzy rings. The last pose flows smoothly back into the first.
Looping animation: the last pose must lead smoothly back into the first pose.
```

## Tự kiểm tra trước khi gửi owner

1. Mọi frame còn giống ảnh gốc (phiến vảy xếp ngói, mắt cam tròn, miệng nhỏ, chân đá ngắn, màu)?
2. Nén / giãn xong có trở về đúng hình đứng (số 01, 36)? Không mọc thêm tay, sừng, răng?
3. Nét viền, bảng màu, đổ bóng đồng nhất giữa các frame?
4. Đọc rõ ở cỡ nhỏ (~100 px); với attack: pha lấy đà nhìn là biết sắp vồ?
5. `check_frames.py` ĐẠT: chân ở 224, tâm 128, không bị cắt mép khung 256?
6. Thân không trôi ngang trong dải (code tự dời quái)?
7. Không vẽ hiệu ứng, bóng đổ, chữ, logo?
