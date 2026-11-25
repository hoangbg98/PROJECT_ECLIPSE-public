# Phân tích model Golem Đá Cổ (boss_golem_01)

> Claude viết ngày 2026-11-19, dựa trên tấm sprite của owner (`ref/boss_golem_01_parts_sheet.png`) và bảng bộ phận owner đã
> điền (38 khung, owner đồng ý toàn bộ dự đoán của Claude). Màu ghi "ước lượng" là nhìn bằng mắt. Lore, chỉ số, đòn:
> `docs/design/MONSTERS.md` mục 4. Góc phải dưới tấm gốc có logo mờ đè lên lửa của pose 38: Claude đã che trắng trong mọi
> ảnh `ref/`. **Không vẽ lại logo.** Ảnh trong `ref/` chỉ để tham chiếu (nằm trong `docs/`, không vào bản build).

## Khác với Cặn

| Mục | Cặn lớn | Golem Đá Cổ |
|---|---|---|
| Loại | Quái thường | **Boss 2 pha** (pha 2 khi HP ≤ 50%), không bị khựng → **không có `hurt`** |
| Khung | 320×320 | **768×512, tâm x = 384, chân y = 464** (ngang rộng cho tầm đập / húc ~320 px) |
| Chiều cao đứng | ~130 px | **~330 px** (to hơn nhân vật ~280 px) |
| Animation | idle, move, attack, hurt, stun, death | **idle, move, slam, charge, quake, stun, phase, death** (tên đòn khớp `SkillDef.animation` trong data) |
| Thư mục | `assets/enemies/enemy_slime_02/` | **`assets/enemies/boss_golem_01/`** |

Phần chung theo `../PROMPT_GOC.md` và quy tắc quái ở `../enemy_slime_01/00_PHAN_TICH.md` (không tự dời thân trong frame, không
vẽ hiệu ứng, không vẽ bóng đổ).

## Hình khối và nét vẽ

- Thân **ghép từ các khối đá góc cạnh** nâu xám, có **khe dung nham cam mảnh** chạy giữa các khối.
- **Đầu nhỏ, khối vuông**, lún giữa hai vai; **mắt khe hẹp** phát sáng vàng cam (số 02).
- **Vai đá khổng lồ**, mỗi vai có **xích sắt ngắn treo một viên đá nhỏ** (số 07, 08, 09).
- **Ngực rộng**, giữa ngực có **ấn tròn nửa trắng nửa đen trong vòng tối** (mảnh ấn kênh 00 của truyện, số 16, 23). Ấn
  luôn thấy được; lúc chuyển pha thì sáng rực.
- **Cẳng tay đá to, nắm đấm khổng lồ** (số 25–28); **chân ngắn mập**, bàn chân khối (số 29, 30).
- Lưng có tấm đá khắc **dấu ba vòng đá chồng nhau** (số 10, dấu xưởng thủ vệ): góc 3/4 quay phải thường không thấy lưng,
  chỉ vẽ nếu pose quay lưng.
- Nét viền nâu đen dày đều (khoảng 3–4 px ở cỡ 512); cel shading 2 tầng; không gradient mềm, không 3D.
- Góc nhìn **3/4 quay về bên phải** như pose 33–38. Lật trái do engine.

## Bảng màu (ước lượng)

| Vùng | Màu |
|---|---|
| Khối đá (sáng) | nâu xám ~#857669 |
| Khối đá (bóng) | nâu xám sẫm ~#5A4D45 |
| Nét viền | nâu đen ~#2A2220 |
| Mắt, khe dung nham | cam ~#F0801E, lõi vàng ~#FFC34A |
| Ấn ngực | trắng ~#F4F0EA / đen ~#1C1818 trong vòng tối, viền sáng cam khi rực |
| Xích | sắt xám sẫm ~#4A4444 |

## Bộ phận và animation (số theo bảng owner đã điền)

| Số | Bộ phận | Dùng ở animation |
|---|---|---|
| 01 | Thân đầy đủ | mọi animation — **ảnh gốc chính** |
| 33 | Pose đứng thủ thế | idle |
| 34 | Pose bước đi | move |
| 35 | Lao húc (bụi = VFX, không vẽ) | charge |
| 36 | Đập tay xuống đất (lửa = VFX, không vẽ) | slam |
| 38 | Bùng nổ lửa (lửa, đá bay = VFX, không vẽ) | quake |
| 37 | Gầm, giơ tay, lõi sáng | phase (chuyển pha 1.2 s) |
| 02 | Mặt thường | idle, move |
| 03 / 26 | Giận / nắm đấm | slam |
| 11 | Nghiến răng gồng | charge |
| 12, 15 | Hét / nứt gầm lửa | quake |
| 06, 13, 16 | Nứt gầm lửa / nóng chảy / ngực lõi ấn bản lớn | phase |
| 04 | Ngạc nhiên | stun |
| 05, 14 | Mặt tắt | death |
| 07–10, 17, 22–30 | Giáp vai, xích, tấm lưng, vai, thân, tay, chân | tham chiếu hình khối khi đổi tư thế |
| 18–21, 31, 32 | Đá lửa bay, đá lửa rơi, mảnh vụn, lửa nổ sát đất, nổ lửa lớn | **VFX riêng** (slam: 31; quake: 20, 32; death: 21) |

## Quy tắc riêng

1. **Đòn pha 2 dùng chung animation pha 1** (`slam`, `charge` nhanh hơn): code phát nhanh hơn, không vẽ bản riêng.
   Thời gian trong phiếu lấy theo đòn pha 1.
2. **Sóng đất của quake là VFX riêng** (hai sóng chạy hai phía 600 px): frame chỉ vẽ cú giậm.
3. **Charge: thân giữ tại chỗ** dù trong game golem lao 420 px (code dời); vẽ như chạy tại chỗ, vai chĩa trước.
4. **Death** khớp truyện: golem **gục sấp nguyên khối** (không vỡ vụn), ấn ngực tắt; xác nằm lại trước cửa Lò Mẹ tới
   hết chương (owner 2026-11-19 sửa truyện theo animation đã duyệt).
5. Không vẽ lửa, bụi, đá bay bên ngoài thân. Khe dung nham và ấn ngực sáng lên là một phần thân, được vẽ.
