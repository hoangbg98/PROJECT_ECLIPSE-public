# Phân tích model Kẻ Đeo Mặt Nạ (boss_henchman_01)

> Claude viết ngày 2026-11-19, dựa trên tấm sprite của owner (`ref/boss_henchman_01_parts_sheet.png`, 2048×2048) và bảng bộ
> phận owner đã điền (46 khung, owner đồng ý toàn bộ dự đoán). Màu ghi "ước lượng" là nhìn bằng mắt. Lore, chỉ số, đòn:
> `docs/design/MONSTERS.md` mục 5. Ảnh trong `ref/` chỉ để tham chiếu (nằm trong `docs/`, không vào bản build).
>
> **Góc phải dưới tấm gốc có logo mờ trong suốt đè lên giày và lưỡi móc của pose 46** (không che được vì đè lên hình).
> Không vẽ lại vệt sáng mờ đó.

## Khác với bản thiết kế cũ (`docs/prompts/characters/HENCHMAN_DESIGN.md`)

Tấm sprite của owner là **chuẩn**. Khác bản đề xuất cũ: tỉ lệ **chibi** (đầu to như nhân vật phe ta), mũ trùm giáp kín
đầu thay cho mũ + áo choàng, **bộ vest đen** (gi-lê, sơ mi, cà vạt) dưới áo khoác mở, huy hiệu trắng-đen ở **ve áo**,
lưỡi móc cong lớn. Giữ: mặt nạ đen trơn không mắt miệng, khe giáp cam xỉn, áo choàng than rách, lưỡi móc đen.

## So với các boss / quái khác

| Mục | Golem Đá Cổ | Kẻ Đeo Mặt Nạ |
|---|---|---|
| Khung | 768×512, chân 464 | **768×512, tâm x = 384, chân y = 464** (giơ lưỡi móc qua đầu cần chỗ trên) |
| Chiều cao đứng | ~330 px | **~300 px** (nhỉnh hơn nhân vật phe ta ~280 px) |
| Animation | idle, move, slam, charge, quake, stun, phase, death | **idle, move, sweep, dash, ash_wave, stun, phase, death** (tên đòn khớp `SkillDef.animation`) |
| Vũ khí | không | **lưỡi móc luôn cầm tay**, tay gần camera |
| Thư mục | `assets/enemies/boss_golem_01/` | **`assets/enemies/boss_henchman_01/`** |

Phần chung theo `../PROMPT_GOC.md` và quy tắc quái ở `../enemy_slime_01/00_PHAN_TICH.md` (không tự dời thân trong frame, không
vẽ hiệu ứng, không vẽ bóng đổ). Boss không bị khựng → **không có `hurt`**.

## Hình khối và nét vẽ

- **Chibi** khoảng 2.5 đầu: đầu to tròn, thân gọn, tay chân ngắn (giống tỉ lệ Enkiba).
- **Mũ trùm giáp** xám than ghép tấm, có khe nứt cam mảnh, trùm kín đầu; **mặt nạ đen bóng** không mắt không miệng. Mắt
  chỉ hiện (sáng cam) khi giận / đánh (mặt 03–06); mặc định trơn (02).
- **Khăn quàng** tối quanh cổ; **vest đen** (gi-lê, sơ mi, cà vạt) dưới **áo khoác mở** tối; **huy hiệu tròn nửa trắng nửa
  đen** ở ve áo.
- **Một giáp vai lớn** ở vai gần camera, có khe cam; găng giáp tối; quần đen; **ống chân + ủng giáp** có khe cam.
- **Áo choàng than dài, rách** ở gấu, bay theo động tác.
- **Lưỡi móc**: cán dài đen, lưỡi cong lớn tối có khe cam (số 30, 31). Luôn cầm ở tay gần camera.
- Nét viền đen dày đều; cel shading 2–3 tầng; không gradient mềm, không 3D. Quay mặt **phải** như pose 42–46.

## Bảng màu (ước lượng)

| Vùng | Màu |
|---|---|
| Giáp, mũ trùm (sáng) | xám than ~#5A5452 |
| Giáp (bóng) | ~#3A3534 |
| Vest, quần, mặt nạ | đen ~#16141A |
| Khe giáp, mắt | cam ~#F08A2C, lõi vàng ~#FFC34A |
| Áo choàng | than ~#2E2A2C |
| Huy hiệu | trắng ~#F2F0EC / đen ~#141214 |

## Bộ phận và animation (số theo bảng owner đã điền)

| Số | Bộ phận | Dùng ở animation |
|---|---|---|
| 01 | Thân đầy đủ | mọi animation — **ảnh gốc chính** |
| 41 | Pose đứng cầm lưỡi móc | idle |
| 42 | Pose bước đi | move |
| 43 | Lao tới, áo choàng bay | dash |
| 44 | Chém quét (vệt lửa = VFX, không vẽ) | sweep |
| 45, 46 | Giơ lưỡi móc qua đầu / cắm lưỡi móc (lửa = VFX, không vẽ) | ash_wave |
| 02 | Mặt nạ trơn | idle, move |
| 03 / 04 | Mắt khe / mắt giận | sweep / dash |
| 05 | Mắt tròn sáng | stun |
| 06 | Mắt giận rực, mặt nạ nứt | phase |
| 07, 12 | Mặt nạ nứt tối / mặt nạ vỡ | death |
| 08–31, 33–40 | Mũ, mặt nạ, áo, tay, chân, giáp, lưỡi móc, đầu nghiêng | tham chiếu khi đổi tư thế |
| 32 | Vệt chém lửa | **VFX riêng** |

## Quy tắc riêng

1. **Đòn pha 2 dùng chung animation pha 1** (`sweep`, `dash` nhanh hơn): code phát nhanh hơn, không vẽ bản riêng.
2. **Sóng tro của ash_wave là VFX riêng** (hai sóng chạy hai phía 640 px): frame chỉ vẽ cú cắm lưỡi móc.
3. **Dash: thân giữ tại chỗ** (code dời boss 460 px); vẽ lao tại chỗ, lưỡi móc chĩa trước, áo choàng bay ra sau.
4. **Death** khớp truyện (ô `ch01_end_01`): hắn **quỳ một gối, giáp nứt, lưỡi móc rơi**, mặt nạ nứt tối. Không vỡ vụn,
   không biến mất trong frame (code mờ dần; truyện kể hắn bị rút về kênh lạ).
5. Không vẽ lửa, tro, vệt chém, khói bên ngoài thân. Khe giáp và mắt sáng là một phần thân, được vẽ.
