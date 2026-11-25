# Phân tích model Cặn lớn (enemy_slime_02)

> Claude viết ngày 2026-11-19, dựa trên tấm sprite của owner (`ref/enemy_slime_02_parts_sheet.png`) và bảng bộ phận owner đã
> điền (41 khung, owner đồng ý toàn bộ dự đoán của Claude). Màu ghi "ước lượng" là nhìn bằng mắt. Lore và chỉ số:
> `docs/design/MONSTERS.md` mục 3. Ảnh trong `ref/` chỉ để tham chiếu (nằm trong `docs/`, không vào bản build).

## Khác với Cặn tro thường

| Mục | Cặn tro (`enemy_slime_01`) | Cặn lớn (`enemy_slime_02`) |
|---|---|---|
| Dáng | Ụ vảy nhỏ, không tay | **Khối thú đá to, lưng gù, bụng tròn, có tay và chân** |
| Mặt | Mắt tròn, miệng nhỏ | **Mắt cam giận dưới mày nặng, miệng rộng, hai nanh trắng chìa lên** |
| Khung | 256×256, tâm 128, chân 224 | **320×320, tâm x = 160, chân y = 288** |
| Chiều cao đứng | ~100 px | **~130 px** (to hơn Cặn tro ~1.3–1.4 lần) |
| Đòn (data) | Cắn lao 500/150/600 ms | **Cắn lao nặng 700/180/800 ms**, lao 80 px, đẩy lùi 220 px |
| Thư mục | `assets/enemies/enemy_slime_01/` | **`assets/enemies/enemy_slime_02/`** |

Phần chung vẫn theo `../PROMPT_GOC.md` và quy tắc riêng của quái ở `../enemy_slime_01/00_PHAN_TICH.md` (không tự dời thân
trong frame, không vẽ hiệu ứng, không vẽ bóng đổ).

## Hình khối và nét vẽ

- Thân **gù, tròn như gấu**: bụng tròn to, trơn, màu sáng hơn; lưng, vai và đỉnh đầu phủ **mai phiến đá – tro dày** xếp lớp,
  có **khe dung nham cam** sáng (số 14, 15, 16, 17).
- Đầu liền thân, không cổ. Mày đá nặng, **hai mắt cam phát sáng** hình giận, **miệng rộng** với **hai nanh trắng** chìa lên từ
  hàm dưới (số 25, 33 là hàm rời).
- **Hai tay đá ngắn, mập**, nắm đấm khối, buông hai bên (số 20, 24). **Hai chân ngắn mập**, ngón đá có vuốt (số 22, 23).
- Nét viền nâu đen dày đều (khoảng 2–3 px ở cỡ 320); cel shading 2 tầng; không gradient mềm, không 3D.
- Góc nhìn: các pose mẫu là **3/4 quay về bên phải**; giữ góc này cho mọi frame (mặt và bụng thấy được, thân hướng phải).
  Lật trái do engine.

## Bảng màu (ước lượng)

| Vùng | Màu |
|---|---|
| Da đá, bụng (sáng) | nâu xám ấm ~#7E716B |
| Mai phiến (bóng) | nâu xám sẫm ~#564B46 |
| Nét viền | nâu đen ~#2A2220 |
| Mắt, khe dung nham | cam ~#F0801E, lõi vàng ~#FFC34A |
| Nanh | trắng ngà ~#F2EDE4 |
| Trong miệng | đỏ sẫm ~#7A2A26; khi gầm / cuồng nộ: lõi cam lửa ~#F28A2A (số 29, 39) |

## Bộ phận (số theo bảng owner đã điền)

| Số | Bộ phận | Dùng ở animation |
|---|---|---|
| 01 | Thân đầy đủ | mọi animation — **ảnh gốc chính** (owner gán idle) |
| 14–17, 20–24, 25, 33 | Mào đầu, vảy vai, mai lưng, tay, thân, chân, hàm nanh | tham chiếu hình khối khi đổi tư thế; 25 dùng khi cắn |
| 02 | Giận, nanh chìa | idle (mặt mặc định) |
| 31 | Ngủ (bong bóng mũi) | idle (owner gán) — chỉ mượn mắt lim dim, **không vẽ bong bóng** |
| 07, 08, 09, 11, 29 | Gầm há miệng, nheo mắt giận, gầm dữ dội, gồng nhăn mặt, cuồng nộ miệng lửa | attack (owner gán) |
| 05, 12 | Ngạc nhiên há miệng tròn, đau nhắm chặt | hurt (owner gán) |
| 28 | Choáng (mắt xoáy) | stun (owner gán) |
| 03, 04, 06, 10, 13, 30, 32 | Cười nhe răng, nhắm mắt, cau có, trừng mắt, cười nham hiểm, liếc khinh, cười lớn | chưa gán (06 dùng lúc nguôi ở cuối attack) |
| 36 | Pose đứng thủ thế | idle |
| 37 | Pose bước đi | move |
| 38, 39 | Khom lấy đà, gầm miệng rực lửa | attack — pha **lấy đà** |
| 41 | Lao chồm tới (miệng lửa) | attack — pha **trúng đòn**; đá bay phía sau là VFX, **không vẽ** |
| 40 | Nhảy giậm đất | attack — tham chiếu lúc **đáp đất nặng**; bụi là VFX, **không vẽ** |
| 18, 19, 26, 27, 34, 35 | Đá cháy, phiến đá bay, lửa tóe, cột lửa, nổ lửa, dung nham tóe | **VFX riêng** (34 dùng khi chết) |

## Quyết định Claude chọn

- Owner gán cả 38, 39, 40, 41 cho attack nhưng data chỉ có **một** đòn (cắn lao nặng). Claude ghép bốn pose thành một đòn:
  khom (38) → gầm lửa (39) → lao chồm cắn (41) → đáp nặng (40). Không thêm đòn mới (đòn mới cần số liệu trong `data/` và là
  quyết định của owner).
- Owner không gán pose chết. Death vẽ theo hướng: nứt dung nham rực – khuỵu gối – mai bong – sụp thành đống phiến đá; vụ nổ
  lửa (số 34) là VFX riêng.
- Lửa trong miệng khi gầm (39, 41, mặt 29) là **một phần mặt**, được vẽ; lửa / đá / bụi bên ngoài thân thì không.
