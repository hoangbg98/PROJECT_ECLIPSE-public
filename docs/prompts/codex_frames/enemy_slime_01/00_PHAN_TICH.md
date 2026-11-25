# Phân tích model Cặn tro (enemy_slime_01)

> Claude viết ngày 2026-11-19, dựa trên tấm sprite của owner (`ref/enemy_slime_01_parts_sheet.png`) và bảng bộ phận owner đã
> điền (41 khung). Owner chốt: **cả tấm dành cho Cặn thường** (`enemy_slime_01`); Cặn lớn (`enemy_slime_02`) sẽ có tấm riêng.
> Màu ghi "ước lượng" là nhìn bằng mắt, không đo pixel. Lore và chỉ số: `docs/design/MONSTERS.md` mục 2.
>
> Góc phải dưới tấm gốc có một logo nhỏ; Claude đã che trắng ở mọi ảnh trong `ref/`. **Không vẽ lại logo hay ký hiệu nào.**
> Ảnh trong `ref/` chỉ để tham chiếu (nằm trong `docs/`, không vào bản build).

## Khác với frame nhân vật

| Mục | Nhân vật | Cặn tro |
|---|---|---|
| Khung | 384×384, tâm x = 192, chân y = 336 | **256×256, tâm x = 128, chân y = 224** |
| Chiều cao đứng | ~280 px | **~100 px** (thân trong game cao ~90 px, rộng ~120 px) |
| Thư mục | `assets/characters/{id}/` | **`assets/enemies/enemy_slime_01/`** |
| Thời gian đòn | `data/skills/` | `data/enemies/enemy_slime_01.tres` (đã chép vào `tools/frames/jobs/enemy_slime_01.json`) |
| Vũ khí | có | **không** |

Phần còn lại của `../PROMPT_GOC.md` vẫn áp dụng: giữ đúng ngoại hình, có lấy đà – đánh – thu về, không vẽ hiệu ứng vào frame,
mỗi lần một animation, owner duyệt rồi mới chép vào `assets/`.

## Hình khối và nét vẽ

- Một **ụ / nón thấp** làm từ các phiến tro – đá xếp chồng như ngói (vảy chĩa xuống), đáy rộng, đỉnh tròn hơi nhọn.
  Không có cổ, không có tay rõ ràng (vài phiến bên hông có thể hất ra như tay khi vồ — xem số 16, 18).
- **Hai chân đá ngắn, mập** ló dưới đáy (thấy rõ ở số 36, 37, 39).
- Mặt nằm ở **mặt trước của ụ**, khoảng 1/3 trên: hai **mắt tròn phát sáng cam** (lõi vàng cam, viền cam đậm) và **một miệng
  nhỏ sẫm** đơn giản. Không mũi, không tai.
- **Khe nứt và đốm than** cam nhỏ rải giữa các phiến vảy, sáng nhẹ.
- Nét viền nâu đen dày, đều (khoảng 2–3 px ở cỡ 256); cel shading 2 tầng; không gradient mềm, không 3D.
- Quay mặt sang **phải** (giống số 37, 39). Hình gần đối xứng nên lật trái ít rủi ro; giữ hướng vảy chĩa xuống / ra sau.

## Bảng màu (ước lượng)

| Vùng | Màu |
|---|---|
| Phiến vảy (sáng) | nâu xám ấm ~#8A7B72 |
| Phiến vảy (bóng) | nâu xám sẫm ~#5E524C |
| Nét viền | nâu đen ~#2A2220 |
| Mắt | lõi vàng cam ~#FFC34A, viền cam ~#F07A1E |
| Khe nứt, đốm than | cam ~#F08A2C |
| Miệng | nâu đỏ sẫm ~#4A2A24 |

## Bộ phận (số theo bảng owner đã điền)

| Số | Bộ phận | Dùng ở animation |
|---|---|---|
| 01 | Thân đầy đủ (vảy, mắt cam, miệng) | mọi animation — **ảnh gốc chính** |
| 14, 15, 16, 17, 18, 19 | Thân nón trơn, đỉnh/đầu, tay trái, lõi thân, tay phải, đế/chân | tham chiếu hình khối khi thân biến dạng |
| 08, 09, 11, 12, 31–35 | Lớp vảy, nắp đá, vảy rời, vảy cong | tham chiếu hình phiến vảy |
| 02 | Mặt thường (mắt cam sáng) | idle, move, mặc định |
| 03, 04 | Mắt nhắm cười, mắt nhắm buồn/ngủ | chớp mắt trong idle |
| 27 | Buồn ngủ | idle (owner gán) |
| 06, 25 | Giận, nhíu mày / giận dữ | attack (owner gán) |
| 05, 07, 29 | Ngạc nhiên há miệng / đau nhắm chặt / hoảng mắt trắng | hurt (owner gán) |
| 28 | Choáng (mắt xoáy) | stun (owner gán) |
| 26, 30 | Nheo mắt liếc / cuồng nộ mắt lửa | chưa gán (dự phòng) |
| 36 | Pose đứng rung | idle |
| 37 | Pose nghiêng người lao tới | move |
| 38 | Pose cuộn tròn | stun |
| 39 | Pose nhảy vồ | attack |
| 40 | Pose khạc / ném đá | owner gán attack, nhưng game **chưa có đòn tầm xa** (data chỉ có "cắn lao") → chưa dùng |
| 41 | Pose phun trào lửa | death |
| 10, 13 | Mảnh đá nhỏ, mảnh vụn mỏng | death (vỡ vụn) |
| 20, 21, 22, 23, 24 | Phiến đá văng, hạt tro, nổ lửa, ngọn lửa | **VFX riêng**, không vẽ vào frame |

## Quy tắc riêng

1. **Không tự di chuyển thân trong frame.** Code dời quái theo `move_px` của đòn (cắn lao 60 px) và tốc độ chạy; frame giữ
   thân quanh tâm x = 128. Chỉ nghiêng / vươn thân về phía trước.
2. **Không vẽ hiệu ứng**: không vệt tốc độ, không bụi, không đá văng, không vòng sao choáng, không quầng sáng ngoài thân.
   Riêng **death** được giữ ngọn lửa nhỏ phun trên đỉnh như số 41 (là một phần thân đang vỡ); vụ nổ lửa lớn (số 22) là VFX riêng.
3. Squash & stretch được phép **nhiều hơn nhân vật** (đây là slime), nhưng mọi phiến vảy, mắt, miệng vẫn đúng hình; pose
   đứng phải trở về đúng hình số 01 / 36.
4. Bóng đổ dưới chân (vệt xám ở số 36–39) **không vẽ**: game tự vẽ.
