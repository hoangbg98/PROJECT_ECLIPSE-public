# Áo Khoác Vết Khuyết — trang phục event cho chế độ Bay (hoãn, M11-6)

> **Tình trạng:** bản thiết kế lại ngày 2026-11-18 (Claude) từ đề xuất `JET_COSTUME_BRIEF.md` của owner (2026-11-17).
> **Không làm trong v1** của chế độ Bay (`JET_MODE.md` OD-J12): v1 dùng frame sẵn có + Bộ Phụt vẽ riêng. Tài liệu giữ
> sẵn brief để làm khi owner duyệt.

## 0. Thay đổi so với bản đề xuất

| # | Đề xuất | Bản này | Lý do |
|---|---|---|---|
| 1 | "Bộ Bảo Hộ Hành Lang" thay hẳn quần áo | **Áo Khoác Vết Khuyết**: lớp phủ bảo hộ **mặc ngoài giáp**, NEO may cho người vào Vết Khuyết | Canon: mỗi Data ID là **một giáp** (bộ chiến phục khắc ấn); đổi hẳn trang phục dễ bị hiểu là giáp mới |
| 2 | Khái niệm mới "skin `jet`" | **Trang phục** là món mỹ phẩm (`data["cosmetics"]["outfits"]`, cạnh nền sảnh đã có), chỉ hiện trong chế độ event | Dự án đã có mục `cosmetics`; tránh thêm hệ riêng cho một chế độ |
| 3 | 6 nhân vật cùng lúc | Làm **Enkiba trước** (có đủ frame, splash), owner duyệt cách làm rồi mới làm 5 người còn lại | Mỗi người = 1 splash + 5 animation; rủi ro lệch thiết kế cao |
| 4 | Tên cũ, ghi chú "Aether / Noctis phải đổi tên" | Data ID + tên mới (đã đổi) | AGENTS mục 3 |
| 5 | "Đọc từ 6 ảnh splash" | Yomigari **chưa có** thư mục `splash/`; đặc điểm Yomigari lấy từ chân dung, cần owner xác nhận | Kiểm tra `assets/characters/*/` |

## 1. Nguyên tắc

1. **Mặc ngoài giáp, không thay giáp:** áo khoác / tấm che / dây đai trên nền giáp cũ; hình dáng đổi rõ (góc cạnh, nhiều
   tấm, cổ áo kín) nhưng giáp bên dưới vẫn lộ ở vài chỗ (tay áo, viền).
2. **Nền xám than chì `#3A3D46`, viền màu của giáp gốc** (lấy mẫu màu thật từ splash): nhìn xa vẫn biết ai.
3. **Giữ nguyên mặt, tóc, màu mắt, dấu nhận dạng, vũ khí.** Không mũ kín, không mũ trùm, không mặt nạ che mặt; mặt
   nạ lọc hạ xuống cổ.
4. **Chừa chỗ cho Bộ Phụt**: dây đai chéo ngực + tấm đế lưng trống; **không** vẽ thùng (lớp VFX riêng).
5. **Đọc được khi nhỏ**: viền màu dày, liên tục (≥ 6 px ở ảnh rộng 1024, ≥ 4 px ở frame 384).
6. Thiết kế riêng của dự án; không bắt chước đồ bảo hộ / nhận diện của game khác.

## 2. Đặc điểm phải giữ (đối chiếu lại với ảnh gốc trước khi vẽ)

| Data ID | Giữ | Vũ khí |
|---|---|---|
| `char_fire_01` Enkiba (nam) | tóc đỏ thẫm dựng gai, vệt tóc cam ở mái; mắt hổ phách | kiếm lưỡi họa tiết lửa |
| `char_wind_01` Kazeyumi (nữ) | tóc xanh bạc hà dài, đuôi ngựa cao; kẹp tóc lông vũ ngọc xanh; mắt xanh lục lam | cung gỗ ruy băng xanh, ống tên |
| `char_lightning_01` Raikiba (nam) | tóc bạc ngắn rối xen vệt vàng; mắt xanh lam; khuyên tai vàng | hai dao cong phát sáng vàng |
| `char_light_01` Hikarine (nữ) | tóc vàng nhạt rất dài xõa; vương miện vàng mảnh có ngọc; mắt nâu hổ phách | trượng vàng đầu mặt trời |
| `char_dark_01` Yomigari (nam, 20+) | tóc đen đuôi ánh tím, mái che một bên mắt, mắt tím (**chưa có splash**, owner xác nhận) | lưỡi hái đen, tinh thể tím |
| `char_earth_01` Iwagane (nữ, lớn tuổi nhất, dáng cao, chắc khỏe) | tóc nâu gợn sóng, một bím dài buộc dây đồng; sẹo chữ X trên má; da rám nắng; không được làm thanh mảnh | đại kiếm đá phủ rêu, rune vàng lục |

Kiểm tra: che từ cổ xuống, mặt + tóc vẫn nhận ra ngay.

## 3. Thiết kế từng người (viền = màu giáp gốc)

| Người | Kiểu áo khoác | Viền chính / phụ / phát sáng |
|---|---|---|
| Enkiba | tấm gốm xẻ đoạn ở vai, cẳng tay, đùi; ống mềm ngắn ở hông | đỏ thẫm / vàng / cam ở khe tấm; đế ủng giữ cam |
| Kazeyumi | khí động: vây nhỏ ở vai, cẳng tay, cổ chân | bạc hà / xanh lục đậm / kem ở khóa |
| Raikiba | đệm cách điện ở vai, khuỷu, gối; dải túi pin chéo | vàng zigzag / bạc |
| Hikarine | tạp dề tấm xếp tới gối khắc tia nắng; tấm vai tròn | vàng tỏa từ ngực / dải xanh nhạt ở thắt lưng |
| Yomigari | tấm tối bóng ở vai, ngực chéo, ống chân; đai kim loại | tím (phát sáng) / bạc |
| Iwagane | tấm khối vuông như đá ở vai, cẳng tay, đùi, ống chân (khác giáp đồng bo tròn) | đồng / xanh rêu ở khe / rune vàng lục |

## 4. Prompt (Codex imagegen, quy trình như `RHYTHM_ART_BRIEF.md` mục 4)

Đưa ảnh splash / chân dung gốc làm tham chiếu, mỗi lần một người, 1024×1536, nền trắng trơn:

```text
Using the attached reference as the exact same character, draw the full-body standing character wearing a protective
field coat OVER their original battle suit: matte charcoal-gray (#3A3D46) angular layered coat with hard plates on
shoulders, forearms, outer thighs and shins, sealed high collar ring, a filter mask lowered around the neck (face fully
visible), sealed gloves and boots, a cross chest harness and a flat empty round mounting plate on the back (no backpack).
A little of the original suit shows at the sleeves and edges. Thick, continuous trim lines and glowing seams in the
original suit's colors. Same art style, line weight, shading and proportions as the reference. Plain white background.
No helmet, hood, hat or full face mask. KEEP EXACTLY the same face, expression, hairstyle, hair color, eye color,
identifying marks and the same weapon.
```

Thêm phần riêng từng người theo mục 3 (tiếng Anh). Câu cấm: `no helmet, no hood, no hat, no full face mask, no change of
face shape or hair color, no extra marks, no backpack, no text, no watermark`.

## 5. Từ splash tới frame

| Việc | Quy cách |
|---|---|
| Frame | 384×384, chân y = 336, tâm x = 192, hướng phải (README 2.2) |
| Animation cần | `idle`, `run`, `jump_up`, `fall`, `hurt` |
| Tên / thư mục | `assets/characters/{id}/outfits/fieldcoat/frames/{anim}/{id}_fieldcoat_{anim}_{NNN}.png` + `frames_manifest.json` (`frames: 0` = dùng frame thường) |
| Quy trình | như frame nhân vật (AGENTS mục 4): mỗi lần một animation, owner duyệt từng cái |
| Bộ Phụt, lửa phụt, vệt bay | VFX riêng, không vẽ vào frame |
| Ghi giấy phép | `docs/ASSET_LICENSES.md` mục 2.1 từng file |

Code: `AnimationSetBuilder` thêm tham số thư mục trang phục; thiếu animation nào thì lấy của bộ thường.

## 6. Quyết định mở

| Mã | Câu hỏi | Mặc định |
|---|---|---|
| OD-C1 | Làm trang phục event không | Hoãn tới sau J5; làm Enkiba thử trước |
| OD-C2 | Nhận trang phục thế nào | Thưởng lần đầu qua N-5 của chế độ Bay (mỗi người dùng được sau khi mở) |
| OD-C3 | Dùng ở chế độ nào | Chỉ event (Chạy và Bay); combat và sảnh dùng giáp thường |
| OD-C4 | Kính / tai nghe trên đầu | Không; đeo ở cổ |
