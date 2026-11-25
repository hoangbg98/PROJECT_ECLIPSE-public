# Cốt truyện Chương 2 — "Xưởng Đá Ngủ" (Cao Nguyên Thủ Vệ)

> **Tình trạng:** Claude viết 2026-11-21, **đề xuất, chờ owner duyệt**. **Owner chốt 2026-11-21:** (1) **Zero là thủ lĩnh cấp trung, chỉ cao hơn Kẻ Đeo Mặt Nạ (Shokuhai)**, được thêm vài boss tay sai cấp thấp cùng kiểu; (2) **Iwagane là nhân vật gacha, trong cốt truyện chỉ cho chơi thử, không vĩnh viễn** (muốn có phải chiêu mộ). **Chốt thêm 2026-11-21:** (3) luật **gác đôi** giữ nguyên; (4) **Zero chỉ xuất hiện từ Chương 6 trở đi**, còn **Shokuhai xuất hiện cuối mỗi chương** để thu lõi sót lại của tay sai bại trận và cường hóa, gom đủ thì mở **dạng mới**; (5) **ô khách Iwagane** là slot bắt buộc, có chữ "Chơi thử" ở màn xuất kích. **Chốt lần 3 (2026-11-21):** (6) **Zero xuất hiện lần đầu ở Chương 6 và sau đó ở mỗi nút thắt quan trọng** của truyện; (7) **dạng mới của Shokuhai là boss cuối Chương 6, bị hạ hẳn, không chạy thoát**; (8) slot Iwagane **bắt buộc**; người đã có Iwagane được **chọn giáp thử hoặc giáp đã có** (như ảnh tham chiếu); **giáp thử hạng S, mặc đủ 4 món đề cử, cấp bằng cấp quản lý**; (9) **thứ tự làm: bản chơi thử được trước, rồi placeholder cho các đoạn truyện có video, ảnh vẽ sau cùng**. Bám `docs/design/STORY_PROPOSAL.md` (bảng C, hàng 18 / 21–24,
> B3–B7) và kết `ch01_end`. Ký hiệu như tài liệu đó: **[CANON]** đã có trong tài liệu / data, **[ĐỀ XUẤT]** mới viết, **[HỎI]** cần owner chọn.
> Xưng hô: bốn người trẻ "tớ – cậu"; với Iwagane (chị, lớn tuổi nhất) là "chị – em".
> Truyện không đổi luật gameplay; thủ vệ mới / ải mới chỉ là nội dung tương lai, số liệu nằm trong `data/` khi làm.

## 1. Tóm tắt một đoạn

Theo dấu ba vòng đá, đội lên **Cao Nguyên Thủ Vệ**, nơi chế tạo mọi thủ vệ. Xưởng đã bị đột nhập: những thủ vệ **đang nghỉ ca**
bị lấy mất lõi, số còn lại bị đánh thức hàng loạt. **Iwagane**, người giữ cửa xưởng, thấy đội cầm mảnh ấn gỡ từ ngực golem nên
tưởng đội là kẻ trộm và chặn lại. Sau trận đấu tập "thử người" và một đêm thủ cổng cùng nhau, hiểu lầm được gỡ: golem ở
Thung Lũng Tro Tàn **không đứng một mình vì tự nguyện**, mà vì **bạn gác đôi của nó bị lấy lõi** nên không ai thay ca. Đội ngăn
đợt đánh thức cuối cùng, nhưng lõi đã bị chở đi: đích đến là **Thành Tháp Sét**, nơi có sét để nạp. Iwagane cho đội **mượn sức tới hết chương** (chơi thử), rồi ở lại giữ xưởng.

- **Vùng:** Cao Nguyên Thủ Vệ (12 ải, một phần; `gen_chapters.py`: "Cao Nguyên Thủ Vệ", 12). **[CANON]**
- **Nguyên tố bị ăn:** Địa. Đá "ngủ" ở đây chỉ ngủ khi có ca gác kề bên; mất ca, đá thức dậy cáu. **[ĐỀ XUẤT]**
- **Nhân vật trọng tâm:** Iwagane (khách mời, **chơi thử trong chương**, không vào kho nhân vật). Kazeyumi đọc ra bí ẩn "gác đôi"; Enkiba day dứt vì đã đập một thủ vệ vô tội.
- **Mảnh sự thật của chương (đúng một mảnh, theo B7):** lõi thủ vệ **cộng hưởng với Neo** (cùng một chất liệu cổ). Thủ vệ và Neo
  từ cùng một nguồn; thủ vệ là **van giữ nguyên tố**, không phải vũ khí. (Mảnh này chuẩn bị cho Trụ Thứ Bảy ở Chương 5.) **[ĐỀ XUẤT]**
- **Chủ đề giữ mạch:** "không ai chiến đấu một mình". Gương soi ngược với Neo 00: thủ vệ **bị bắt trực một mình**.

## 2. Bối cảnh vùng và luật của xưởng [ĐỀ XUẤT]

| Mục | Nội dung |
|---|---|
| Cao Nguyên Thủ Vệ | Cao nguyên đá, vách xẻ thành xưởng, cầu đá, mỏ đá, lò rèn nguội, hành lang tượng. Mặt Trời Khuyết lệch hẳn về một phía nên bóng đá đổ dài lạ |
| **Gác đôi** | Mỗi thủ vệ có một **bạn gác**: một canh, một nghỉ, đổi ca mỗi chu kỳ. Ca nghỉ "ngủ" trong xưởng (đá ngủ). Đó là lý do xưởng tên **Đá Ngủ** |
| Dòng họ **Gác Đá** | Họ của Iwagane, cha truyền con nối làm **người coi ca**: sống cùng thủ vệ, quyết định khi nào đổi ca. Danh dự là "không để thủ vệ nào gác một mình" |
| Lõi thủ vệ | Một viên đá sáng bên trong ngực; lấy ra thì thủ vệ thành đá chết, cắm vào thủ vệ khác thì nó thức dậy mạnh hơn nhưng cáu |
| Thợ Cả **Ishiro** | Người đứng đầu xưởng, già, bị thương khi đột nhập. Mở đầu truyền cho Iwagane quyền giữ cửa. Tên **[ĐỀ XUẤT]** |
| Người ngoài | Dân cao nguyên ngờ người từ Vùng Thực xuống, vì đúng lúc đó lõi bị mất |

**Vì sao golem ở Chương 1 đứng một mình:** bạn gác đôi của nó đang nghỉ trong xưởng; lõi bạn bị lấy nên **không còn ai thay ca**.
Nó bị sai tới chắn cửa Lò Mẹ và canh mãi không được nghỉ (khớp thoại Kazeyumi Ch.1: *"không ai thay ca"*). **[ĐỀ XUẤT, nối canon]**

## 3. Phe và kẻ địch

| Ai | Vai | Ghi chú |
|---|---|---|
| **Đội** | Enkiba, Kazeyumi, Raikiba (bộ ba truyện); Iwagane **chơi thử** từ 2-7 tới hết chương rồi trở lại giữ xưởng | Chương 3 chuyển trọng tâm sang Raikiba |
| **Iwagane** | Tank, kiệm lời, nghiêm; từng thấy thủ vệ tỉnh lúc nửa đêm. **Nhân vật gacha**, trong truyện chỉ là bạn đồng hành tạm | Mốc tính cách: giữ cửa là danh dự (B4). Việc phải ở lại giữ xưởng chính là lý do chị không đi cùng lâu dài |
| **Thợ Cả Ishiro** | Chỉ xuất hiện ở clip (bị thương) | Cho Iwagane lý do nghi đội và lý do tin đội |
| **Phe mã 00** | **Tay sai cấp thấp** (mặt nạ, vòng nửa trắng nửa đen) cùng thủ vệ bị cắm lõi lạ | Cùng cấp với Shokuhai, mỗi tên một kiểu (mục 3b). Thoại "???" |
| **Zero** | **Thủ lĩnh cấp trung**, đứng ngay trên các tay sai (chỉ cao hơn Kẻ Đeo Mặt Nạ), dưới thủ lĩnh 00 **[CANON, owner 2026-11-21]** | **Không xuất hiện ở Chương 2.** Chỉ từ **Chương 6** trở đi (hiện cuối chương cùng Shokuhai). Trước đó người ra lệnh chỉ là một "Quản lý" không tên (giọng ở cuối Ch.1) |
| **Shokuhai** (Kẻ Đeo Mặt Nạ) | Tay sai **đặc biệt**: thu **lõi sót lại** của tay sai cấp thấp bại trận để cường hóa **[CANON, owner 2026-11-21]** | Quay lại **cuối Chương 2** (cảnh nhá), giáp vá lại sau trận 1-10, không đánh trong chương. Xem 3c |
| Quái thường | Cặn tro / Cặn lớn (đã có) + **Cặn đá** và **Tượng gác nhỏ** (mới) | Tượng gác nhỏ: thủ vệ non bị đánh thức, khoảng bằng người, chỉ cận chiến |

### 3b. Tay sai cấp thấp của Zero [ĐỀ XUẤT, owner cho thêm 2026-11-21]

Cùng khuôn với Shokuhai (người mặc giáp, mặt nạ đen trơn, vòng 00; thua thì bị "rút về kênh khác"), nhưng **mỗi tên một lối đánh**
để người chơi không gặp lại cùng một boss. Chỉ là **boss tay sai**, không cần cốt truyện riêng; số liệu nằm trong `data/enemies/`.

| Tên tạm | Giáp / vũ khí | Vai trong chương | Gợi ý lối đánh (dùng cơ chế có sẵn) |
|---|---|---|---|
| **Kẻ Gánh Lõi** | Giáp xám đá, ba lô lõi trên lưng | Người chở lõi (2-11), boss nhỏ, thua thì bỏ chạy | Chạy vòng, thả tượng non chặn đường |
| **Kẻ Cắt Dây** | Giáp mỏng, dao cong, mặt nạ nứt | Phá cầu / bục (2-2, mini-boss) | Nhanh, tới lui, chém dây cầu |
| **Kẻ Gõ Đá** | Giáp nặng, búa to | Canh mỏ (2-3, mini-boss) | Chậm, đập đất tạo vùng nguy hiểm |
| **Kẻ Mài Mặt Nạ** | Giáp trắng bụi, cánh tay móc | Chặn đêm đổi ca (2-9, mini-boss) | Ra nhiều đòn mồi, báo hiệu ngắn |

Chúng là quân cờ của phe 00: *"Một tay sai thì thay được. Lõi thì không."* (nghe qua loa ở 2-11, giọng một Quản lý không tên;
người chơi chỉ biết đó là Zero từ Chương 6). Mỗi tay sai bại trận **để lại một lõi** (mảnh vòng 00), xem 3c.

### 3c. Shokuhai thu lõi và dạng mới [ĐỀ XUẤT theo ý owner 2026-11-21]

- **Luật:** sau mỗi chương, Shokuhai (từ Chương 2) xuất hiện ở cảnh nhá cuối chương, **nhặt lõi tay sai bại trận** bỏ lại rồi hấp thụ vào giáp.
  Mỗi lõi mang một **lối đánh** của tay sai đó. Zero **lần đầu hiện ở Chương 6**, rồi xuất hiện ở **mỗi nút thắt quan trọng** của truyện (không nhất thiết mọi cuối chương), đứng như người nhận hàng: *"Thu cho xong. Ta cần ngươi đủ lõi."*
- **Mốc cường hóa:** gom đủ một bộ lõi thì Shokuhai mở **dạng mới** (kiểu "gom đủ lõi thì thức tỉnh"). **Dạng mới là boss cuối Chương 6 [CANON, owner 2026-11-21]:
  bị hạ hẳn, không chạy thoát**, và dùng lại đòn của các tay sai người chơi đã hạ ở các chương trước (người chơi gặp lại từng lối đánh cũ).
- **Gieo từ Chương 2:** 4 tay sai bại trận (Cắt Dây, Gõ Đá, Mài Mặt Nạ, Gánh Lõi) → **4 lõi**. Các chương sau thêm tay sai cấp thấp mới, mỗi chương một vài lõi.
  Số lõi cần để mở dạng mới là con số cân bằng, nằm trong `data/` khi làm, không viết cứng trong truyện.
- **Chủ đề:** Shokuhai là gương xấu của "gác đôi" và của Neo: **hắn nuốt người khác để đứng một mình**, đúng điều Neo 00 tin.
- **Giới hạn:** thu lõi chỉ là truyện (cảnh nhá, thẻ ghi chú). Không đổi luật gameplay, trừ trận Shokuhai dạng mới khi được duyệt riêng.

Boss chính của chương (đề xuất, số liệu sẽ nằm trong `data/enemies/`):
- **2-6 Đấu tập với Iwagane**: boss là **bản giáp của Iwagane** (Thần Kiếm Nham Thạch), chỉ dùng kỹ năng có trong `CHARACTER_SKILLS.md`
  (đại kiếm, khiêu khích, kĩ năng vũ khí). Không có đòn nào ngoài bộ kỹ năng. Đây là lần đầu người chơi **thấy** giáp Iwagane.
- **2-12 Thủ Vệ Cổng** (mới): thủ vệ lớn nhất cao nguyên, đang bị cắm lõi lạ, 2 pha như golem: pha 2 lộ vòng ấn 00 trắng đen trên ngực.

## 4. Tuyến 12 ải [ĐỀ XUẤT]

Mỗi ải: một dòng truyện hiện ở thông tin màn, một mục tiêu HUD. Địa hình gợi ý chỉ để làm màn sau; không ràng buộc gameplay.

| Ải | Tên tạm | Truyện | Điểm nhấn |
|---|---|---|---|
| 2-1 | Chân Dốc Thủ Vệ | Đội lên dốc, thấy dấu bánh chở đá và tro lạ. Tượng gác nhỏ đầu tiên lảo đảo trên đường, mắt đục | Dạy Tượng gác nhỏ, Cặn đá |
| 2-2 | Cầu Đá Gãy | Cầu bị đánh sập một nửa. Raikiba trinh sát, Kazeyumi đọc vết đục: **đục từ trong ra**, không phải bị phá từ ngoài. Đội gặp **Kẻ Cắt Dây** đang cắt nốt dây cầu | Hố, bục; mini-boss Kẻ Cắt Dây |
| 2-3 | Mỏ Đá Câm | Mỏ ngừng làm. Công nhân mỏ bỏ chạy, nói "đá thức dậy trong đêm". **Kẻ Gõ Đá** canh cửa hầm | Đợt đông; mini-boss Kẻ Gõ Đá |
| 2-4 | Nhà Đá Của Dân | Giữ làng nhỏ trước tượng non. Dân ngờ đội ("mới có người lạ lên là đá nổi điên") | Mục tiêu "không ai gục" |
| 2-5 | Hành Lang Tượng | Hàng tượng ngủ im; Kazeyumi nhận ra mỗi tượng có **hốc ngực trống** | Gieo mảnh "lõi bị lấy" |
| **2-6** | **Cửa Xưởng** | **Iwagane chặn cổng, đòi đội trả lõi.** Đấu tập "thử người" (boss: giáp Iwagane) | Boss 2-6 |
| 2-7 | Sân Rèn Nguội | Sau trận, Iwagane cho vào xem lò. Thợ Cả bị thương. Lò nguội vì lõi bị lấy. **Từ ải này Iwagane đi cùng (chơi thử)** | Truyện nhiều, chiến đấu nhẹ |
| 2-8 | Kho Lõi | Vào kho: **hơn chục hốc lõi trống**. Mảnh ấn 00 của Raikiba **rung theo** lõi còn lại: cùng nguồn | Mảnh sự thật |
| 2-9 | Đêm Đổi Ca | Đêm đầu đội giữ ca cùng Iwagane; tượng thức giấc từng đợt, **Kẻ Mài Mặt Nạ** chặn lúc đổi ca. Đội hiểu **ca gác đôi** | Đợt kéo dài; mini-boss Kẻ Mài Mặt Nạ |
| 2-10 | Đường Mật Chở Lõi | Lần theo vết kẻ trộm: kênh xe chở đá bí mật dưới vách | Chạy dài, bẫy |
| 2-11 | Dốc Đổ Sét | Gặp **Kẻ Gánh Lõi** cùng 2 lõi đang chở. Đánh hắn tới khi hắn bỏ chạy, để lại một lõi | Boss nhỏ Kẻ Gánh Lõi |
| **2-12** | **Cổng Thủ Vệ** | Thủ vệ lớn nhất bị cắm lõi lạ nổi điên. **Iwagane đứng ra giữ cửa**, đội chia ca với chị. Hạ nó, lõi lạ vỡ | Boss 2-12 |

## 5. Clip mở chương — "Lên Cao Nguyên" (≈ 14 ô, 5 trang) [ĐỀ XUẤT]

Dạng truyện tranh (D2/hàng 13). Bộ ba truyện + Neo. Nền: dốc cao nguyên lúc xế chiều, Mặt Trời Khuyết lệch.

**Trang 1 — Dấu ba vòng đá (3 ô)**
1. Cao nguyên từ xa, vách đá khoét thành xưởng. NEO: *"Tọa độ khớp. Cao Nguyên Thủ Vệ. Mật độ nguyên tố Địa: 18%, đang giảm."*
2. Ba người trên dốc. Raikiba: *"Yên quá. Xưởng làm thủ vệ mà không có tiếng búa nào."*
3. Kazeyumi cúi nhìn vệt bánh chở trên đá: *"Có người chở đồ nặng đi. Mới thôi."*

**Trang 2 — Tượng non (3 ô)**
4. Một **Tượng gác nhỏ** loạng choạng, mắt đục, chặn đường. Enkiba rút kiếm.
5. Kazeyumi chặn tay Enkiba: *"Chờ đã. Mắt nó… không đứng được. Nó đang bị ép thức."*
6. Enkiba nghiến răng: *"Tớ vừa đập một con như vậy ở nhà tớ."* (day dứt Ch.1)

**Trang 3 — Người giữ cửa (4 ô)**
7. Cổng xưởng. Bóng một người **cao lớn** đứng chắn, đại kiếm cắm xuống đất. Iwagane (ngược sáng).
8. Iwagane, lạnh: *"Dừng ở đó. Các cậu mang mảnh ấn gỡ từ ngực một thủ vệ."* (nhìn mảnh ấn trong túi Raikiba)
9. Raikiba giơ tay: *"Khoan! Tụi tớ nhặt nó dưới chân golem, không phải…"*
10. Iwagane: *"Xưởng mất mười bốn lõi trong một đêm. Rồi các cậu tới, cầm đúng loại ấn đó."*

**Trang 4 — Thử người (2 ô)**
11. Enkiba bước lên, thu kiếm: *"Chị không tin lời tụi em thì tin trận đánh."*
12. Iwagane nhấc đại kiếm: *"Một ca thử người. Qua được thì vào."* (kết trang, vào ải **2-6**)

**Trang 5 — NEO (2 ô, hiện trước ải 2-1)**
13. NEO phóng bản đồ: vệt chở lõi kéo dài về **phía bắc**. NEO: *"Ghi nhận ba vệt chở. Chưa thấy điểm đến."*
14. Ba người nhìn vách xưởng tối, đội khởi hành. Thẻ: **Chương 2 — Xưởng Đá Ngủ**.

> Dựng: các ô 1–6 phát lần đầu bấm Chương 2; ô 7–12 là clip giữa ải **2-5 → 2-6** (`ch02_gate`, 6 ô); ô 13–14 phát trước 2-1.
> Gợi ý tách thành `ch02_open` (ô 1–6 + 13–14) và `ch02_gate` (ô 7–12), cùng định dạng `data/story/ch01_*.json`.

## 6. Truyện giữa các ải (thông tin màn) [ĐỀ XUẤT]

- **2-6 sau trận:** Iwagane hạ đại kiếm. *"Các cậu đánh như người chưa từng bỏ ai lại phía sau."* Chị cho vào xưởng nhưng chưa tin hẳn.
- **2-7:** Thợ Cả Ishiro: *"Một thủ vệ gác một mình lâu quá thì không phải thủ vệ nữa. Là một con thú bị nhốt."* Kazeyumi hỏi về golem
  Thung Lũng: Ishiro nhận ra **bạn gác đôi** của nó nằm trong kho, hốc ngực trống.
- **2-8:** Mảnh ấn 00 sáng lên khi tới gần lõi còn lại. NEO: *"Tần số trùng. Lõi thủ vệ và Neo có cùng cấu trúc vật liệu."*
  Iwagane: *"Vậy Neo của các cậu và lõi của xưởng là họ hàng."* Enkiba: *"Họ hàng, hay cùng một thứ bị chia nhỏ?"* (không trả lời, gieo Trụ Thứ Bảy)
- **2-9 (đêm):** Iwagane, bên lửa: *"Họ Gác bọn chị không đánh thức thủ vệ. Bọn chị đổi ca cho chúng."* Enkiba hỏi chị đã bao giờ gác một mình. Chị im.
  Câu trả lời cho **Neo 00** (B2): kẻ nghĩ có một người gánh tất cả đang làm thủ vệ *gánh một mình*.
- **2-11:** Giọng một **Quản lý không tên** (hiện "???") qua loa của Kẻ Gánh Lõi: *"Đừng đuổi theo. Lõi đi tới nơi cần sét. Ở đó nó sẽ có ích hơn là nằm im trong đá."*

## 7. Clip kết chương — "Ca Gác Mới" (≈ 14 ô, 5 trang) [ĐỀ XUẤT]

Nền: cổng xưởng lúc bình minh, thủ vệ lớn đã đổ, lõi lạ vỡ vụn trong tay Kazeyumi. Mặt Trời Khuyết nhô lên.

**Trang 1 — Sau trận (3 ô)**
1. Thủ vệ Cổng gục. Vòng ấn 00 trắng đen trên ngực nứt vỡ. Iwagane chống đại kiếm thở dốc.
2. Raikiba xoa vai: *"Chị giữ cửa kiểu gì mà nó không đẩy chị đi được vậy?"* Iwagane: *"Chị đứng đủ lâu thì đất tự biết."*
3. Kazeyumi nâng mảnh lõi lạ: *"Lõi này không phải của xưởng. Có thứ khác bị ép vào trong."*

**Trang 2 — Gỡ hiểu lầm (3 ô)**
4. Iwagane quay sang đội, cúi đầu thật sâu. *"Chị đã nghi nhầm các em."*
5. Enkiba vẫy tay, cười: *"Không sao. Em cũng suýt đập nhầm mấy con tượng non."*
6. Iwagane: *"Golem ở thung lũng… bạn gác của nó nằm trong kho. Nó đã chờ ca thay hơn một mùa."* Im lặng. Enkiba nhìn xuống, nắm chặt tay.

**Trang 3 — Cảnh nhá (2 ô)**
7. Neo của đội nhấp nháy, vệt chở lõi hiện lên bản đồ: kéo dài về **thành có những cột sét cao** (hình tháp). NEO: *"Điểm đến khả dĩ: Thành Tháp Sét Câm."*
8. Raikiba **ngẩng lên, mặt tái**: *"Nhà tớ ở đó."* (khớp B4: Raikiba từng làm người đưa tin ở thành tháp sét)

**Trang 4 — Giao ca và chia tay (3 ô)**
9. Thợ Cả Ishiro, được dìu ra. Trao cho Iwagane một **vòng đá nhỏ có khắc ba vòng chồng nhau**: *"Ca gác này chuyển cho con. Không phải một mình."*
10. Iwagane nhìn Neo, rồi nhìn xưởng. *"Chị phải ở lại giữ cổng. Nhưng nếu kênh của em còn chỗ trống thì cứ gọi chị."* NEO: *"Ghi nhận. Kênh Iwagane: đóng, mở khi được gọi."*
11. Enkiba, Kazeyumi, Raikiba cười. Kazeyumi: *"Hẹn gặp lại chị. Bọn em đi trước."* (Iwagane rời đội; vòng đá ba vòng ở tay chị phát sáng khi đội đi xa)

**Trang 5 — Thẻ + nhá Shokuhai thu lõi (3 ô)**
12. Cả đội đi xuống bậc đá, hướng bắc. Thẻ: **Chương 2 — Hoàn thành**, **Chương 3 — Thành Tháp Sét Câm: đã mở**.
13. *(sau thẻ, 5 s)* Dưới chân cổng, bình minh. **Shokuhai** (giáp vá lại, mặt nạ nứt, vòng 00 ở cổ tay) bước qua thân Thủ Vệ Cổng đã đổ,
    nhặt **bốn lõi nhỏ** tay sai bại trận bỏ lại và mảnh lõi lạ vỡ. Giọng "???" từ vòng 00: *"Thu đủ chưa? Sét sẽ lo phần sau."* (giọng Quản lý không tên)
14. Shokuhai hấp thụ lõi vào giáp: vòng 00 lóe, một vết nứt trên mặt nạ liền lại một phần. Hắn quay về phía bắc. (Mặt hắn vẫn **không lộ**.)

## 8. Continuity sau Chương 2

| Ai / cái gì | Trạng thái | Biết | Chưa biết |
|---|---|---|---|
| Enkiba | Nhẹ nhõm vì hiểu golem; nặng lòng với "ca gác" | Thủ vệ bị cố ý cô lập | Ai điều khiển lõi |
| Kazeyumi | Đã ghép được "gác đôi" và lõi lạ | Lõi thủ vệ ≈ cấu trúc của Neo | Nguồn gốc chung |
| Raikiba | Về quê (Chương 3) là việc cá nhân | Lõi chở về thành tháp sét | Họ dùng sét làm gì |
| **Iwagane** | **Ở lại giữ xưởng**; chỉ chơi thử 2-7 → 2-12, rồi trả lại (không vĩnh viễn). Có thể gọi lại sau này nếu người chơi **chiêu mộ** được | Đội không phải kẻ trộm | Kẻ cầm Neo 00 |
| Neo | Ghi Thành Tháp Sét; kênh Iwagane "đóng, mở khi được gọi" | — | — |
| **Shokuhai** | Hồi phục một phần, đã thu **4 lõi** tay sai + 1 lõi lạ vỡ; đang tiến về thành tháp sét | Đội chưa biết hắn còn sống | Dạng mới của hắn |
| **Zero** | Chưa xuất hiện (chỉ từ Ch.6); người ra lệnh vẫn là "Quản lý" không tên | — | Tên, mặt, quan hệ với 00 |
| Thế giới | Cổng xưởng giữ được; còn **13 lõi** ngoài xưởng | — | Mục đích của 00 |
| Phe 00 | Mất thủ vệ Cổng, mất 1 lõi lạ và 4 tay sai bị đánh bại; Shokuhai gom 4 lõi tay sai | — | — |

## 8b. Cơ chế "chơi thử Iwagane" [CANON phần chốt 2026-11-21; chi tiết là đề xuất]

Iwagane (`char_earth_01`) là nhân vật **gacha**; truyện không cho người chơi sở hữu miễn phí.
- Từ **2-7 tới 2-12**, Iwagane chiếm **một slot bắt buộc** trong đội 3 người (không gỡ được; 2 slot còn lại tự chọn, đội trưởng là người đầu tiên).
- **Chọn giáp cho slot** (theo ảnh tham chiếu, thẻ có nhãn đỏ "Chơi thử"):
  - **Giáp thử** (mọi người đều có): **hạng S**, mặc **đủ 4 món đề cử** của Iwagane (1 vũ khí + 3 vết thánh của banner 5★ Địa), **cấp = cấp quản lý** (giới hạn cấp nhân vật hiện tại). Dựng riêng trong bộ nhớ, **không ghi vào save**, không tiêu / không đổi kho đồ thật.
  - **Giáp đã có** (nếu đã chiêu mộ): người chơi chọn dùng giáp thật với cấp, trang bị, vết thánh của mình. Đội không có hai giáp cùng nhân vật nên chỉ một trong hai ra trận.
- **Giao diện xuất kích:** thẻ slot Iwagane hiện chữ **"Chơi thử"** bên dưới khi dùng giáp thử (khóa chữ `SORTIE_GUEST_TRIAL` ở `vi.po` + `en.po`); chạm thẻ để đổi giữa giáp thử / giáp đã có (nếu có). Không có nút gỡ.
- **Người chơi không phải sở hữu Iwagane** để qua ải: giáp thử luôn có sẵn, nên không bị kẹt (D9). Kết quả ải không cho kinh nghiệm hay đồ cho giáp thử.
- Trên màn kết quả 2-12 (chỉ khi chưa sở hữu): gợi ý "Chiêu mộ để giữ Iwagane" dẫn tới banner (không tự đặt tỉ lệ, theo `OWNER_ASSET_CHECKLIST` A2).
- **Triển khai:** ải khai báo `"guest": {"char": "char_earth_01"}` trong `data/stages/*.json`; danh sách 4 món đề cử ở `data/config/guest_trials.json`.
  Mã: `scripts/party/guest_slot.gd` (`GuestSlot`).

## 8c. Thứ tự làm [CANON, owner 2026-11-21]

1. **Bản chơi thử được** (không cần ảnh mới): ô khách, 12 ải 2-1 → 2-12 dùng quái / nền / đất đang có, boss và tay sai dùng khung của golem / Shokuhai kèm số liệu riêng trong `data/`.
2. **Placeholder cho đoạn ải có video** (clip `ch02_*`: dữ liệu + chữ + ô xám có diễn biến, theo hàng 16 của STORY_PROPOSAL).
3. **Ảnh vẽ sau cùng** (ô truyện, nền, quái mới, map / thẻ chương).

## 9. Cần làm để đưa vào game (khi owner duyệt)

| Việc | Loại |
|---|---|
| Sinh `data/story/ch02_open.json`, `ch02_gate.json`, `ch02_end.json` + khóa chữ `STORY_CH02_*` vi / en | Data + bản địa hóa (mở rộng `gen_story_clips.py`) |
| Truyện từng ải 2-1 → 2-12, chữ mục tiêu HUD | Data (`data/stages/`) |
| Quái mới: Tượng gác nhỏ, Cặn đá; boss giáp Iwagane (2-6), Thủ Vệ Cổng (2-12); 4 tay sai cấp thấp của Zero (3b) | Art + `data/enemies/` |
| Cơ chế khách chơi thử Iwagane (mục 8b) | Code + data (đang làm, owner đã chốt 2026-11-21) |
| Nhân vật truyện: Thợ Cả Ishiro; tay sai theo mục 3b; Shokuhai giáp vá (đã có thiết kế); Iwagane đã có giáp `char_earth_01` | Art |
| Mục 3c: dữ liệu lõi tay sai và dạng mới Shokuhai (chờ chương sau) | Data + Art, owner duyệt riêng |
| Nền: dốc cao nguyên, mỏ đá, xưởng, cổng, bình minh; mặt đất `stone_floor` / `cliff_stone` đã có | Art |
| Map + thẻ Chương 2 (prompt có ở `CHAPTER_ART.md`), 5–6 trang ô truyện (khoảng 28 ô) | Art |
| Mở các ải 2-x trên map: thêm `stage_id` vào bảng `built` của `gen_chapters.py` | Code nhỏ |

## 10. Cần owner xác nhận

**Đã chốt (2026-11-21):** Zero cấp trung, chỉ trên Shokuhai, lần đầu ở Chương 6 rồi ở mỗi nút thắt; Shokuhai thu lõi cuối mỗi chương, dạng mới là boss cuối Chương 6 và bị hạ hẳn;
Iwagane là gacha, slot bắt buộc, chọn giáp thử (S, 4 món đề cử, cấp quản lý) hoặc giáp đã có; luật gác đôi; 4 tay sai và thủ vệ chương; thứ tự làm 8c.
Còn mở (đều nhỏ, mình tự chọn nếu bạn không nói gì):
1. Số lõi cần để mở dạng mới của Shokuhai và từng chương rơi mấy lõi (số cân bằng, làm lúc viết data).
2. Số ô clip (khoảng 28) và nhịp chiến đấu / truyện của 12 ải.
3. Tên **Ishiro** / dòng họ **Gác Đá**: giữ hay đổi?
