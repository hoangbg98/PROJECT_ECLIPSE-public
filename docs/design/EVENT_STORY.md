# Event nguyên liệu — cốt truyện và chữ (Nhịp điệu, Chạy, Bay)

> **Tình trạng:** bản thiết kế lại ngày 2026-11-18 (Claude) từ đề xuất `JET_STORY.md` của owner (2026-11-17). Bản đề
> xuất viết khi tưởng "README không có cốt truyện" và tự đặt thế giới riêng (Mạch Nguyên Tố, Hành Lang, Thợ Lõi,
> Quầng). Dự án đã có thế giới **canon** (`STORY_PROPOSAL.md`, owner xác nhận 2026-11-14), nên bản này đặt cả ba chế độ
> vào thế giới đó. Mục cuối liệt kê điều mình tự đặt, cần owner duyệt.
>
> Mọi chữ qua `tr()`, dữ liệu chỉ giữ khóa. Mỗi thẻ ≤ 2 dòng, mỗi dòng ≤ 60 ký tự, đọc kịp trong lúc đếm ngược.
> Xưng hô theo canon: bạn cùng lứa "tớ – cậu"; với Yomigari "anh – em", với Iwagane "chị – em".

## 1. Dữ kiện canon dùng lại

| Canon (`STORY_PROPOSAL.md`) | Dùng trong event |
|---|---|
| **Mặt Trời Khuyết**, **Vùng Thực**: nguyên tố cạn dần | Bối cảnh mọi ải |
| **Cặn**: nguyên tố thừa vón thành khối nhầy | Quái / vật cản của cả ba chế độ |
| **Thủ vệ** cổ | Có thể xuất hiện ở ải sau (không dùng ở v1) |
| **Neo** / **NEO**: trợ lý AI của người quản lý, dẫn đường, giọng thân thiện | Người dẫn truyện, nói lúc đếm ngược, dạy hướng dẫn |
| Vùng Thực chỉ nuôi **một** giáp hiện hình; hai người còn lại ở **kênh** | Nhịp điệu và Bay: một người; Chạy: đổi người qua Neo |
| Chương 7 kết mở: vành nhật thực còn những **"vết khuyết" nhỏ** ở vùng xa | Nơi diễn ra event, lý do event quay lại mỗi năm |
| **Nhật Thực** = tên Chương 7 và phản ứng Quang + Ám | **Không** dùng làm tên boss event |

## 2. Tiền đề của event

> NEO bắt được những **Vết Khuyết**: chỗ bóng của Mặt Trời Khuyết gợn lên như mặt nước, ngắn ngủi rồi khép. Trong
> đó nguyên tố bị ép đặc lại thành **Tinh** (nguyên liệu tiến hóa), trước khi Thực kịp ăn mất. Người quản lý gửi đội vào
> gom Tinh. Mỗi Vết Khuyết mỗi khác, nên mỗi lần vào là một cách đi.

- **Vì sao là ải nguyên liệu:** thứ gom được chính là Tinh (sách EXP, quặng / tinh thể cường hóa trong game).
- **Vì sao thường niên:** Vết Khuyết gợn mạnh nhất vào mùa bóng mặt trời dài nhất; NEO gọi là **Mùa Khuyết**
  (tên event, OD-S2).
- **Ba dạng Vết Khuyết = ba chế độ:**

| Chế độ | Vết Khuyết | Cách gom Tinh |
|---|---|---|
| Nhịp điệu | **Vết Vang**: Thực ăn âm thanh, Cặn bắt chước nhịp nhạc | Đánh Cặn đúng nhịp |
| Chạy | **Vết Trôi**: mặt đất trôi về phía bóng, chỉ đứng được nếu cộng hưởng đúng giáp | Chạy, nhảy, đổi người qua Cổng Cộng Hưởng |
| Bay | **Vết Rỗng**: khoảng trống giữa các tầng đá, không có đường đi | NEO lắp **Bộ Phụt** đốt Tinh Lõi để bay |

## 3. Boss chung: Vầng Khuyết

Một mảnh bóng của Mặt Trời Khuyết rơi vào Vết Khuyết: đĩa đen, vành sáng cháy quanh, mắt đỏ. Nó không nghĩ, chỉ
**hút**: hút âm thanh (Nhịp điệu), hút mặt đất (Chạy), hút Tinh (Bay). Đánh tan thì Vết Khuyết khép và Tinh rơi ra.

- Dùng chung sprite `rh_boss_eclipse`; vành **cam** ở Nhịp điệu, **tím** ở Chạy, **cyan** ở Bay (tô bằng code).
- Đề xuất đổi tên ải N-5 Nhịp điệu đang chạy "Boss: Nhật thực" → **"Boss: Vầng Khuyết"** (OD-M8). Khóa:
  `RHYTHM_STAGE_05_NAME`.
- Lời boss (một dòng, không chặn), theo phần trăm đường / bài còn lại:

| Mốc | Câu | Khóa |
|---|---|---|
| bắt đầu | "…đói…" | `EVT_BOSS_START` |
| 50 % | "Trả… lại… đây…" | `EVT_BOSS_P50` |
| 80 % | "Không… khép…" | `EVT_BOSS_P80` |
| vỡ | (không chữ; NEO: "Vết Khuyết đã khép. Tinh rơi khắp nơi!") | `EVT_BOSS_DEFEAT` |

Vầng Khuyết **không** có động cơ hay bi kịch riêng (khác đề xuất cũ "một đêm yên"), để không giẫm lên bí ẩn chính
(Neo 00, Lõi Thực ở Chương 7).

## 4. Nhịp điệu (đã chạy) — chỉnh tên cho khớp

| Hiện tại (`RHYTHM_ART_BRIEF.md`) | Đề xuất | Ghi chú |
|---|---|---|
| "Nhật Thực làm méo âm nhạc, sinh ra Âm Ảnh" | "Trong Vết Vang, **Cặn** nuốt âm thanh và bắt chước nhịp" | Quái vẫn là Dơi Nốt, Sên Nhịp, Song Âm, Rắn Ngân, Trống Đá (gọi chung **Cặn Âm**) |
| Boss Nhật Thực | Vầng Khuyết | mục 3 |
| Dòng giới thiệu N-2 (Rắn Ngân, quái trống) | giữ, đổi người nói thành NEO | `RHYTHM_INTRO_HOLD` |

Chỉ đổi chữ hiển thị và tài liệu; hình, Data ID (`rh_*`) giữ nguyên.

## 5. Chạy Nguyên Tố — Vết Trôi

Thẻ chế độ: **"Chạy Nguyên Tố"** (`MODE_RUNNER_TITLE`) · phụ đề "Giữ đường bằng cộng hưởng" (`MODE_RUNNER_SUB`).

| Thuật ngữ | Khóa | Mô tả (≤ 60 ký tự) |
|---|---|---|
| Cặn Thấp | `RUNNER_TERM_HURDLE` | "Cặn bò trên đường. Nhảy qua." |
| Vết Thực | `RUNNER_TERM_PIT` | "Chỗ đất đã bị ăn mất. Nhảy qua." |
| Cặn Bay | `RUNNER_TERM_FLYER` | "Cặn lơ lửng ngang đầu. Đừng nhảy!" |
| Cổng Cộng Hưởng | `RUNNER_TERM_GATE` | "Chỉ mở cho đúng giáp. Đổi người trước khi chạm." |
| Hạt Tinh | `RUNNER_TERM_ORB` | "Tinh vụn. Đúng màu người chạy thì nhân đôi." |

Thẻ ải (NEO nói, lúc đếm ngược lần đầu):

| Ải | Tên (`RUNNER_N?_TITLE`) | Giới thiệu (`RUNNER_N?_INTRO`) |
|---|---|---|
| N-1 | Đường Trôi | "Đất đang trôi về phía bóng. Cứ chạy, gặp Cặn thì nhảy." |
| N-2 | Cổng Đầu Tiên | "Cổng chỉ mở cho đúng giáp. Tớ đổi người khi cậu bảo!" |
| N-3 | Ba Màu | "Ba cổng, ba người. Nhìn ký hiệu, đừng chỉ nhìn màu." |
| N-4 | Nhảy Và Đổi | "Cổng sát Cặn rồi: nhảy và đổi người cùng lúc nhé." |
| N-5 | Vầng Khuyết | "Nó đang hút cả mặt đất. Chạy tới tâm Vết Khuyết!" |

## 6. Bay Nguyên Tố — Vết Rỗng

Thẻ chế độ: **"Bay Nguyên Tố"** (`MODE_JET_TITLE`) · phụ đề "Bay gom Tinh trong Vết Rỗng" (`MODE_JET_SUB`).

- **Bộ Phụt** (`JET_TERM_PACK`): "NEO lắp vội: đốt Tinh Lõi để phụt lên. Cạn là rơi."
- **Tinh Lõi** (`JET_TERM_CORE`): "Tinh đặc. Nạp Bộ Phụt, cũng là nguyên liệu tiến hóa."
- **Hạt Tinh** (`JET_TERM_ORB`): "Tinh vụn trôi trong khoảng rỗng."
- **Hộp Ký Ức** (`JET_TERM_BOX`): "Tinh còn nhớ hình của thứ từng canh vùng này."
- Vật cản: Thanh Cặn, Cặn Phóng, Tia Quét, Van Sét (`JET_TERM_*`).
- Vì sao chỉ một người bay: Vết Rỗng chỉ nuôi một giáp hiện hình (canon), hai người còn lại nói qua kênh.
- Vì sao hồi năng lượng khi đứng đất: Bộ Phụt hút chút Tinh từ đá dưới chân.

Hình biến hình (ký ức của thứ từng canh vùng):

| Hình | Nguồn gốc | Nhặt hộp (`JET_FORM_*_PICK`) | Vỡ (`_BREAK`) |
|---|---|---|---|
| Rồng | Ký ức con rồng gió từng bay qua Thung Gió | "Có tiếng gầm trong hộp!" | "Rồng tan thành gió." |
| Robo | Ký ức một **thủ vệ** đá-máy nghiền Cặn | "Thủ vệ… thức dậy một lát." | "Thủ vệ về lại giấc ngủ." |

Vùng (`JET_ZONE_<ID>_NAME` / `_RULE`):

| Vùng | Dòng luật (biểu ngữ) |
|---|---|
| Ống Tro | "Bay tốn Tinh: nhặt Tinh Lõi xanh để nạp." |
| Thung Gió Ngược | "Gió đổi chiều theo đợt: nhìn mũi tên mà nghiêng." |
| Hang Sét Câm | "Tia quét và van sét: chui qua khe hở." |
| Lòng Lò Nứt | "Sàn là dung nham: chỉ Rồng bay qua nổi." |

Thẻ ải:

| Ải | Tên (`JET_N?_TITLE`) | Giới thiệu (`JET_N?_INTRO`) |
|---|---|---|
| N-1 | Lần Bay Đầu | "Giữ để bay, thả để rơi. Nhớ nhặt Tinh Lõi nhé!" |
| N-2 | Gió Ngược | "Gió đổi chiều liên tục. Thấy hộp sáng thì chạm vào." |
| N-3 | Van Sét | "Khe van vừa đủ cho cậu, nếu cậu không hoảng." |
| N-4 | Đáy Rỗng | "Càng xuống sâu càng nóng. Giữ Rồng càng lâu càng tốt." |
| N-5 | Vầng Khuyết | "Nó hút cả Tinh lẫn gió. Đừng nhìn tay nó, nhìn mũi tên!" |

## 7. Câu nhân vật (bay và chạy)

Theo tính cách canon (`STORY_PROPOSAL.md` B4). Một câu mỗi sự kiện, tối đa một câu mỗi 8 s, chỉ người đang trên sân nói.
Khóa `EVT_BARK_<ELEMENT>_<EVENT>`, chọn theo Data ID; ID không có trong bảng thì im lặng.

| Data ID | `start` | `core` (nhặt lõi) | `form` / `swap` | `hurt` | `clear` |
|---|---|---|---|---|---|
| `char_fire_01` Enkiba | "Xông lên thôi!" | "Còn ấm, tốt!" | "Tới lượt tớ!" | "Nóng thật…" | "Xong! Về Lò Than ăn mừng." |
| `char_wind_01` Kazeyumi | "Tớ đọc kỹ đường rồi." | "Đủ dùng thêm một đoạn." | "Theo gió nhé." | "Lệch nhịp rồi." | "Đúng như tớ tính." |
| `char_lightning_01` Raikiba | "Khỏi hướng dẫn, đi luôn!" | "Nạp đầy!" | "Tăng tốc!" | "Ối, chậm một nhịp." | "Nhanh hơn Enkiba chưa?" |
| `char_light_01` Hikarine | "Đừng ai liều mạng nhé." | "Còn ấm áp lắm." | "Để tớ lo." | "Không sao, đi tiếp." | "Không ai bị bỏ lại." |
| `char_dark_01` Yomigari | "Anh thấy mép của Thực." | "Một chút sáng." | "Anh vào." | "…Không đáng kể." | "Khép rồi." |
| `char_earth_01` Iwagane | "Cứ để chị giữ cửa." | "Chắc tay rồi." | "Chị đây." | "Chưa sao đâu." | "Giữ được. Nghỉ chút nhé." |

## 8. Hướng dẫn và gợi ý

NEO nói mọi dòng hướng dẫn (khóa riêng từng chế độ: `RHYTHM_TUT_*` đã có, `RUNNER_TUT_*`, `JET_TUT_*`, cùng nút
`*_TUT_SKIP`). Gợi ý khi tải (`EVT_TIP_01..10`), ví dụ: "Đứng đất vài giây, Bộ Phụt hút lại chút Tinh." · "Biến hình
đỡ một cú trúng, đừng tiếc." · "Cổng Cộng Hưởng có ký hiệu ○ △ □, nhìn ký hiệu nếu khó phân màu." · "Ấn khi hitbox chưa
chạm vòng thì không sao."

## 9. Màn kết quả (dùng chung)

| Hạng | Câu (`EVT_RESULT_<HẠNG>`) |
|---|---|
| S | "Hoàn hảo! Vết Khuyết khép lại, Tinh rơi đầy tay." |
| A | "Rất tốt. Gần như không sót chút Tinh nào." |
| B | "Ổn rồi, vẫn còn vài chỗ tối." |
| C | "Qua được, nhưng suýt nữa." |
| D | "Qua rồi… lần sau gom kỹ hơn nhé." |
| Thất bại | "NEO rút cả đội ra. Thử lại nhé." (`EVT_RESULT_FAIL`) |

## 10. Dữ liệu

`data/events/story.json`: theo chế độ, mỗi ải `{title_key, intro_key, outro_key?}`, `zones`, `forms`, `barks`,
`boss`. Chữ ở `localization/vi.po` + `en.po` (thêm bằng `tools/add_locale_keys.py`). `EventValidator` cảnh báo khóa
thiếu. Thẻ giới thiệu hiện lần đầu, đánh dấu ở `data["minigames"]["tutorials"]`, xem lại được từ bảng thông tin ải.

## 11. Điều mình tự đặt, cần owner duyệt

| Mã | Điều mình đặt | Nếu không đồng ý |
|---|---|---|
| OD-S1 | Event diễn ra ở **Vết Khuyết** (từ kết mở Chương 7) | Đặt event ngoài truyện, chỉ là "huấn luyện" ở Trạm Bình Minh |
| OD-S2 | Tên event **Mùa Khuyết**; ba dạng Vết Vang / Vết Trôi / Vết Rỗng | Đặt tên khác |
| OD-S3 | Boss chung **Vầng Khuyết**, đổi tên cả boss N-5 Nhịp điệu | Giữ "Nhật Thực" (trùng tên Chương 7 / phản ứng) |
| OD-S4 | NEO dẫn truyện (bỏ Thợ Lõi) | Thêm nhân vật phụ chỉ có giọng |
| OD-S5 | Robo là ký ức một thủ vệ | Máy móc trung tính |
| OD-S6 | Câu nhân vật mục 7 | Owner viết lại |
| OD-S7 | Quái Nhịp điệu gọi chung **Cặn Âm** | Giữ "Âm Ảnh" |
