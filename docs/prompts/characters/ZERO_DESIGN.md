# Thiết kế Zero — Quản lý (`npc_zero_01`)

> Owner chốt 2026-11-20: **Option A "Áo choàng trùm kín"**. Bảng thiết kế chuẩn:
> `assets/characters/npc_zero_01/design/npc_zero_01_sheet.png` (1536×1024, trước / nghiêng / sau, cận mũ trùm, cận huy hiệu và vòng sáng).
> Hai phương án còn lại (B vest bất đối xứng, C hình chiếu nhiễu) giữ ở `art_review/characters/zero_manager/` (không vào git).

## Vai trò trong truyện

- **Zero** là **Quản lý**, cấp trên của tay sai Shokuhai (`boss_henchman_01`), dưới trướng thủ lĩnh mã 00. Ba tầng: Shokuhai → Zero (Quản lý) → mã 00.
- Chỉ lộ diện ở ô `ch01_end_14` (đêm, đứng trên đỉnh vách nhìn xuống Lò Mẹ vừa cháy lại). Trong thoại hiện vẫn là `unknown` ("???"); tên Zero chỉ dùng nội bộ cho tới khi truyện mở bí mật.
- Câu thoại: "Tay sai thua rồi à. Không sao. Báo với 00: thủ vệ trên cao nguyên còn nhiều."

## Khóa thiết kế (mọi ảnh có Zero phải giữ)

- Áo choàng dài xám trùm đầu, lớp lót trắng; bên trong bộ đồ công sở đen, găng tay đen, giày da đen.
- Mặt luôn là khoảng tối trong mũ trùm, chỉ lờ mờ một vạch sáng mảnh; **không bao giờ lộ mặt**.
- Huy hiệu vòng nửa trắng nửa đen cài ở cổ áo choàng; một **vòng sáng nửa trắng nửa đen** lơ lửng trên lòng bàn tay (giống NEO nhưng màu trắng đen, không phải cyan).
- Dáng cao gầy, tỉ lệ anime chuẩn ~8 đầu, không chibi, tuổi và giới tính mơ hồ (nghiêng về nam). Khác Shokuhai: không giáp, không vũ khí.

## Prompt rút gọn để tạo lại

```text
Anime 2D character design sheet on flat grey #C8C8C8: front / side / back full body, hood close-up, emblem and floating ring close-ups, no text.
Tall slim figure in a long hooded grey cloak with white lining, black office suit, black gloves and shoes, face a pure dark void with one thin
light slit, small half-white half-black ring clasp at the collar, a glowing half-white half-black ring floating above the left palm. Standard
anime proportions, not chibi, no weapon, no armor.
```
