# Phân tích model Yomigari (char_dark_01)

> Do Claude quan sát từ tờ sprite art gốc của owner (2026-11-18): `rig_parts/source/char_dark_01_parts_sheet.png`
> và ảnh toàn thân cắt từ tờ đó `portrait/char_dark_01_portrait_full.png`. Màu ước lượng bằng mắt.
> Phần 1 của `../PROMPT_GOC.md` yêu cầu đọc file này. Chưa có idle đã duyệt: **làm `idle` trước**,
> các animation sau canh chiều cao theo nó.

## Tỉ lệ và nét vẽ

- Yomigari là nhân vật Ám, Control, vũ khí lưỡi hái (CHARACTER_SKILLS.md mục 5, tên cũ Noctis): khống chế, kéo kẻ địch lại gần,
  nguyền rủa, rút máu. Tính cách lạnh lùng, ít biểu cảm.
- Chibi khoảng **2.5 đầu**: đầu to, tay chân ngắn. 6 pose mẫu hàng dưới của tờ khóa tỉ lệ chibi nhỏ; ảnh toàn thân cao hơn,
  chỉ dùng để khóa chi tiết và màu.
- Nét viền đen, dày khoảng 2–3 px ở canvas 384; cel shading 2–3 tầng, highlight xám bạc trên viền áo và cán hái.
- Mục tiêu chiều cao đứng **~280 px** trong canvas 384×384, chân ở y = 336, tâm x = 192. Lưỡi hái cao hơn người: được vượt khung
  người nhưng không ra khỏi canvas; khi vung rộng thì thu nhỏ biên độ chứ không cắt lưỡi.

## Bảng màu chính (ước lượng)

| Vùng | Màu |
|---|---|
| Tóc | đen ~#1E1B24, ngọn chuyển tím ~#6B3FA0 → #8E5CC8 |
| Da | hồng nhạt ~#F4D9C6 |
| Mắt | tím ~#8A5CC2 |
| Áo khoác, quần, găng, ủng | đen ~#25222B, bóng xám than ~#3A3642 |
| Viền áo, khóa, xích | xám bạc ~#A9A6B0 |
| Lót áo choàng, lót vạt áo, đế ủng | tím ~#6E3FB0, bóng ~#4B2A80 |
| Ngọc (ngực, đầu hái, đáy cán) | tím sáng ~#9D6BE0 |
| Lưỡi hái | thân lưỡi đen, mép trong tím ~#8E5CC8; đầu hái đen chạm bạc có gai |

## Các bộ phận và thứ tự lớp (từ xa → gần camera, khi quay phải)

1. Áo choàng phần sau lưng, vạt áo khoác sau (lót tím)
2. Tay xa, chân + ủng xa
3. Thân: áo khoác đen cổ đứng hai hàng khuy, xích bạc, ngọc tím trên ngực, thắt lưng, quần có đai đùi
4. Chân + ủng gần
5. Tay gần + **lưỡi hái** (vung hai tay thì tay xa cũng nắm cán, nằm sau cán)
6. Đầu: mặt, tóc, tóc mái dài che một mắt

Tờ có 11 mặt (đầu chưa có tóc, chỉ lấy nét mặt). Hàng trên trái → phải: 1 thường, 2 lạnh / lườm, 3 nghiêm, **4 ngạc nhiên**
(bị hất), 5 lo đổ mồ hôi, **6 cười nhếch** (bắt hái). Hàng dưới: 7 bình thản, 8 cười, 9 nhắm mắt, **10 mệt** (bị hạ gục),
**11 nghiến răng** (bị đánh, gồng). Mặc định: mặt lạnh vô cảm (1–2). Tên mặt là Claude đoán; owner sửa ở trang
"Bảng bộ phận Yomigari" thì cập nhật phiếu.

6 pose mẫu hàng dưới (trái → phải): đứng cầm hái, thủ thế cầm hái thấp, chạy lướt, chém quét thấp, chém bổ trên cao, tuyệt kỹ
(có lửa tím: **không vẽ lửa**).

## Lưỡi hái

- Yomigari **luôn cầm lưỡi hái**: tay gần nắm cán, vung mạnh dùng **hai tay**. Không buông, không chuyển hẳn sang tay xa.
- Lúc đứng: hái dựng đứng cạnh người, đáy cán chạm đất, lưỡi cong ở trên đầu chĩa về trước (pose mẫu 1).
  Lúc chạy: hái kéo ngang ra sau, lưỡi chĩa xuống sau lưng (pose mẫu 3).
- Ngoại lệ: `skill_2` ném hái — từ frame buông tay trở đi **tay không**; `weapon_catch` frame đầu tay không, sau đó cầm lại.
- Vệt chém tím, khói, lửa tím trên tờ là hiệu ứng: **không vẽ** vào frame; game thêm VFX riêng.

## Góc nhìn và pivot

- Ảnh toàn thân và pose mẫu nhìn 3/4 chính diện; **animation vẽ nhìn ngang quay phải**. Pose mẫu 3 (chạy) và 4 (chém quét)
  gần góc ngang nhất, dùng làm mẫu góc nhìn.
- Pivot = giữa hai bàn chân, đường chân y = 336. Animation trên không giữ độ cao tương đối giữa các frame, không kéo chân về 336.
- Điểm dễ sai khi lật: **tóc mái che cùng một mắt**, **áo choàng vắt cùng một vai**, ngọc trên ngực cùng một bên, hái không
  nhảy tay. Soát bằng `anim_flip.gif`.

## Ghi chú theo kỹ năng

- Số frame / fps / frame trúng đòn tính từ `data/skills/char_dark_01/` (đã có đủ SkillDef).
- Chuỗi đòn thường 4 đòn (Ảnh Liêm): chém ngang, chém hất, xoay vòng, bổ xuống rồi giật kéo về.
- `hold_charge` lặp 6 frame (SkillDef `hold_1`: khởi động 180 / 6 nhịp tối đa 1 800 ms): phiếu không gắn SkillDef vì hình là
  vòng lặp. Nhả nút / hết nhịp thì chạy `hold_release` (SkillDef `hold_finish`: nhát bổ 100 ms + hồi phục 320 ms).
- `air_1`, `air_2` là hai đòn riêng (hai SkillDef, hai animation).
- `skill_1` (Vực Bóng Nguyền Rủa): SkillDef có vùng sát thương 4 s tách khỏi người; phiếu ghi `hits_ms` = lúc cắm hái.
- `skill_2` (Liêm Phá Hồn Trảm): hái bay đi 500 ms rồi bay về; phiếu ghi `hits_ms` = lúc buông tay. Thiết kế có
  "8 frame ném + 4 frame bắt hái": phần bắt là phiếu `weapon_catch`, game phát theo `catch_animation` / `catch_at_ms`
  của `weapon.tres` (như Raikiba).
- `ultimate` 300 / 1 900 / 450 ms (cut-in 500 ms tách riêng). Nhân vật giữ kích thước thường; vầng trăng đen, bóng khổng lồ,
  màn tối là VFX / ảnh riêng.
- `switch_in` (Ảnh Liêm Tập Hậu, mục 8.9) trồi lên từ bóng dưới đất: vẽ như đứng dậy từ thế cúi thấp, mọi frame chạm đất.
