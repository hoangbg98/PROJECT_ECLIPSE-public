# Quái vật trong cốt truyện — PROJECT ECLIPSE

> Tổng hợp ngày 2026-11-16 từ data hiện có. Nguồn: `data/enemies/*.tres`, `data/stages/stage_01*.json`,
> `docs/design/STORY_PROPOSAL.md` (B1, hàng 21–24), `docs/prompts/ART_MASTER.md` (mục 2, 4, 5),
> `tools/story/gen_story_clips.py`, `localization/vi.po`.
>
> **Phạm vi:** quái của chế độ cốt truyện (Chương 1). Quái của chế độ nhịp điệu (M10: `rh_serpent`, `rh_drum`,
> `rh_twin`, `rh_boss_eclipse`) không nằm trong tài liệu này — xem `docs/design/RHYTHM_ART_BRIEF.md`.
>
> **Số liệu chiến đấu** dưới đây chép từ data để tiện đọc; khi lệch nhau thì **data là đúng**.
> Phần "Ảnh cần để chạy" (kích thước khung, số frame, fps) là **đề xuất của Claude**, chưa có code dùng.

## 0. Tóm tắt

| Data ID | Tên hiển thị | Loại | Xuất hiện | Lore | Ảnh hiện tại |
|---|---|---|---|---|---|
| `enemy_slime_01` | Slime (Cặn tro) | Quái thường | 1-1 → 1-10 | Nguyên tố thừa vón lại | Đa giác màu tạm |
| `enemy_slime_02` | Slime tro lớn (Cặn lớn) | Quái thường (nặng) | 1-2 → 1-10 | Cặn to, đặc | Đa giác màu tạm (chung scene, cùng cỡ với slime thường) |
| `boss_golem_01` | Golem Đá Cổ | Boss 2 pha | Cuối 1-1 | Thủ vệ cổ bị sai tới chắn cửa Lò Mẹ | Đa giác màu tạm |
| `boss_henchman_01` | Shokuhai (Kẻ Đeo Mặt Nạ) | Boss 2 pha | Cuối 1-10 | Tay sai của một Quản lý dưới trướng thủ lĩnh mã 00 | Đa giác màu tạm |

Số lượng quái thường mỗi ải (đếm từ `data/stages/`):

| Ải | Slime | Slime tro lớn | Boss |
|---|---|---|---|
| 1-1 | 12 | 0 | Golem Đá Cổ |
| 1-2 | 7 | 3 | — |
| 1-3 | 6 | 6 | — |
| 1-4 | 7 | 5 | — |
| 1-5 | 7 | 5 | — |
| 1-6 | 9 | 5 | — |
| 1-7 | 5 | 6 | — |
| 1-8 | 9 | 6 | — |
| 1-9 | 8 | 6 | — |
| 1-10 | 3 | 3 | Shokuhai |

**Hiện trạng code:** mọi quái đang vẽ bằng `Polygon2D` màu tạm (`placeholder_color` trong data) trong
`scenes/enemies/*.tscn`; chưa có sprite, chưa có AnimationPlayer cho quái. Báo hiệu đòn (vùng đỏ), thanh HP và
thanh SC do `EnemyController._draw()` vẽ bằng code — **không cần ảnh**. Muốn dùng ảnh phải thêm việc code:
thay `Body` bằng `AnimatedSprite2D` và chọn animation theo `State` (PATROL/CHASE → `move`, ATTACK → tên đòn,
STAGGER → `hurt`, STUNNED → `stun`, DEAD → `death`).

---

## 1. Bối cảnh chung (lore)

Mặt Trời Khuyết đổ bóng lâu ngày tạo thành **Vùng Thực**, nơi nguyên tố cạn dần: lửa tắt thành tro, gió đứng lại.

- **Cặn** — phần nguyên tố thừa vón thành khối nhầy, nhảy lung tung. Ở Thung Lũng Tro Tàn, Cặn là tro của lửa
  đã tắt, bị kéo về phía Lò Mẹ và chắn hết đường.
- **Thủ vệ** — tượng đá cổ canh giữ từng vùng, do một xưởng trên cao nguyên đá làm ra (dấu khắc **ba vòng đá
  chồng nhau** ở lưng). Bình thường không nhúc nhích; nổi điên khi bị can thiệp.
- **Phe mã 00** — thủ lĩnh mã 00 → các Quản lý → tay sai mặc giáp. Dấu hiệu nhận biết: **vòng nửa trắng nửa đen**
  (mảnh ấn kênh 00).

---

## 2. Slime — Cặn tro (`enemy_slime_01`)

### Mô tả
Khối tro xám nhỏ như slime, lấm tấm đốm than li ti sắp tắt. Trồi lên từ lớp tro, nảy về phía cuối thung lũng.
Là quái cơ bản nhất, đi theo đàn, dùng để dạy combo, né và Liên kết.

- Thoại: Kazeyumi — *"Cặn. Nguyên tố thừa vón lại. Chúng bị kéo về phía lò, chắn hết đường."*
- Ô truyện: `ch01_open_12` (khối tro xám trồi lên, nảy về phía cuối thung lũng).
- **Tấm sprite đã có** (owner 2026-11-19): ụ phiến tro – đá xếp ngói, mắt cam tròn, chân đá ngắn. Bảng bộ phận và phiếu
  tạo animation cho Codex: `docs/prompts/codex_frames/enemy_slime_01/` (bắt đầu ở `README.md`).

### Hành vi (EnemyController)
Tuần tra ±200 px quanh chỗ xuất hiện (nghỉ 0.8 s ở mỗi đầu) → thấy người chơi trong 700 px thì đuổi → mất dấu
khi xa quá 1000 px → vào tầm 170 px thì **cắn lao**. Trúng đòn thì khựng 0.25 s (ngắt được lúc gồng).

### Chỉ số
| HP | ATK | DEF | SC | Tốc chạy | Hồi đòn |
|---|---|---|---|---|---|
| 6 000 | 400 | 300 | 300 (giảm 40/s sau 2 s) | 160 px/s | 1.5 s |

### Đòn
| Đòn | Gồng (báo hiệu) | Ra đòn | Hồi | Sát thương | Ghi chú |
|---|---|---|---|---|---|
| Cắn lao (`attack`) | 500 ms | 150 ms | 600 ms | 100% ATK | Lao 60 px, vùng 140×100, đẩy lùi 120 px |

---

## 3. Slime tro lớn — Cặn lớn (`enemy_slime_02`)

### Mô tả
Cặn to, nâu xám, đặc và nặng nề; di chuyển chậm nhưng cắn đau, gồng lâu. Từ ải 1-2 trở đi trộn vào đàn slime
thường để người chơi học **né theo báo hiệu** và dùng thanh SC (Choáng).

### Hành vi
Như slime thường, nhưng tuần tra ±160 px, nghỉ 1 s; tầm đánh 200 px; khựng ngắn 0.2 s, bị đẩy ít (10 px).

### Chỉ số
| HP | ATK | DEF | SC | Tốc chạy | Hồi đòn |
|---|---|---|---|---|---|
| 15 000 | 520 | 360 | 600 (giảm 50/s sau 2.5 s) | 110 px/s | 2.2 s |

### Đòn
| Đòn | Gồng | Ra đòn | Hồi | Sát thương | Ghi chú |
|---|---|---|---|---|---|
| Cắn lao nặng (`attack`) | 700 ms | 180 ms | 800 ms | 140% ATK | Lao 80 px, vùng 180×120, đẩy lùi 220 px |

**Tấm sprite đã có** (owner 2026-11-19): khối thú đá lưng gù phủ mai phiến dung nham, bụng tròn, hai nanh trắng, tay chân
đá mập. Bảng bộ phận và phiếu tạo animation cho Codex: `docs/prompts/codex_frames/enemy_slime_02/` (bắt đầu ở `README.md`).

> Lưu ý: hiện dùng chung `enemy_slime.tscn` với slime thường nên **to bằng nhau**. Khi có ảnh nên cho nó khung
> lớn hơn (mục 7) và tăng hộp va chạm tương ứng.

---

## 4. Golem Đá Cổ (`boss_golem_01`) — boss ải 1-1

### Mô tả
Khối đá khổng lồ hình người, khe nứt sáng nhẹ, hai mắt cam đỏ. Đã canh Lò Mẹ cả trăm năm, chưa từng nhúc nhích.
Lưng khắc **dấu ba vòng đá** của xưởng thủ vệ.

**Vai trong truyện (owner 2026-11-15):** golem **không phải kẻ dập lửa** — nó chỉ là thủ vệ bị sai tới chặn
cửa lò. Đánh xong, golem **gục sấp nguyên khối** (không vỡ vụn — owner 2026-11-19, theo animation `death` đã duyệt); Lò Mẹ
vẫn lạnh; ấn trên ngực nó là **mảnh ấn kênh mã 00** (Raikiba gỡ ra), và kẻ đeo mặt nạ đứng nhìn từ trên vách rồi
bỏ đi (clip `ch01_golem`). Xác golem nằm trước cửa lò tới hết chương (thấy lại ở 1-10, lưng có dấu ba vòng đá).

- **Tấm sprite đã có** (owner 2026-11-19): khối đá góc cạnh, vai có xích treo đá, ấn trắng-đen giữa ngực. Bảng bộ phận và
  phiếu tạo animation cho Codex: `docs/prompts/codex_frames/boss_golem_01/` (bắt đầu ở `README.md`).
- Thoại: *"Golem Đá Cổ! Nó không còn nghe lệnh của vùng nữa."* / *"Đòn đập đất của nó gồng lâu, thấy là né ngay."*

### Chỉ số
| HP | ATK | DEF | SC | Tốc chạy | Kháng khựng |
|---|---|---|---|---|---|
| 60 000 | 600 | 400 | 1 000 (giảm 60/s sau 3 s) | 130 px/s | Có (không khựng, mọi đòn có giáp cứng) |

Pha 2 khi HP ≤ 50%; chuyển pha 1.2 s (đứng yên, bất tử). Hạ thì mờ dần 1.2 s.

### Đòn
| Pha | Đòn (`animation`) | Gồng | Ra đòn | Hồi | Sát thương | Ghi chú |
|---|---|---|---|---|---|---|
| 1 | Đập đất (`slam`) | 700 ms | 150 ms | 700 ms | 150% | Vùng 300×180 trước mặt, đẩy lùi 220 |
| 1 | Húc (`charge`) | 600 ms | 400 ms | 800 ms | 120% | Lao 420 px, đẩy lùi 260 |
| 2 | Địa chấn (`quake`) | 800 ms | 200 ms | 700 ms | 130% × 2 | Hai sóng đất chạy hai phía 600 px |
| 2 | Đập đất nhanh (`slam`) | 450 ms | 150 ms | 550 ms | 160% | Vùng 320×190 |
| 2 | Húc nhanh (`charge`) | 500 ms | 400 ms | 650 ms | 130% | Lao 480 px |

Pha 1 nghỉ 1.8 s giữa hai đòn, tầm 280 px; pha 2 nghỉ 1.1 s, tầm 300 px, chạy nhanh ×1.35.

---

## 5. Shokuhai — Kẻ Đeo Mặt Nạ (`boss_henchman_01`) — boss ải 1-10

### Mô tả
Kẻ chủ mưu thật của Chương 1: **tay sai mặc giáp** của một Quản lý dưới trướng thủ lĩnh mã 00. **Tên: Shokuhai** (蝕灰, nhật thực + tro; owner chốt 2026-11-20); "Kẻ Đeo Mặt Nạ" là biệt danh. Trước trận (clip cuối 1-1) thoại hắn vẫn hiện "???"; từ clip kết chương (`ch01_end_03`) hiện tên Shokuhai.
Người Quản lý không trực tiếp đánh, nên boss là tay sai trong bộ giáp của hắn. **Quản lý tên Zero** (owner 2026-11-20): thoại tạm vẫn hiện "???" (`speaker: unknown`) cho tới khi truyện mở bí mật.

Hình (đề xuất, `docs/prompts/characters/HENCHMAN_DESIGN.md`):
- Cao, gầy, vai rộng nhờ giáp; đứng hơi khom, bình thản, không bao giờ vội.
- Giáp xám tro mờ, đường nối **cam xỉn** như than sắp tắt; giáp vai bất đối xứng (vai trái to hơn).
- **Mặt nạ đen trơn**, không mắt không miệng; áo choàng than rách tới bắp chân; huy hiệu **vòng trắng-đen** trên ngực.
- Vũ khí: **lưỡi móc** cán dài đen, lưỡi cong như móc câu.
- Hiệu ứng: tro xám rỉ ra từ khe giáp khi ra đòn; pha 2 khe giáp sáng cam mạnh hơn, tro cuộn quanh lưỡi móc.

Truyện: nhìn từ vách ở cuối 1-1 → trại của hắn ở 1-8 (cột kênh trắng-đen, lưỡi móc đen) → đấu ở cửa Lò Mẹ đêm
nhật thực (1-10). Thua thì bị rút về một kênh lạ; Lò Mẹ cháy lại (clip `ch01_end`).

- **Tấm sprite đã có** (owner 2026-11-19): chibi, mũ trùm giáp kín đầu, mặt nạ đen trơn, vest đen dưới áo khoác mở, một
  giáp vai lớn, huy hiệu trắng-đen ở ve áo, áo choàng rách, lưỡi móc cong lớn. Bảng bộ phận và phiếu tạo animation cho
  Codex: `docs/prompts/codex_frames/boss_henchman_01/` (bắt đầu ở `README.md`). Tấm sprite là chuẩn, thay cho đề xuất cũ ở trên.
- Thoại: *"Mục tiêu: kẻ đeo mặt nạ. Hắn mặc giáp, đánh rất nặng."* / *"Giáp của hắn nhận lệnh qua kênh 00. Đánh
  vỡ giáp là cắt được kênh."*

### Chỉ số
| HP | ATK | DEF | SC | Tốc chạy | Kháng khựng |
|---|---|---|---|---|---|
| 80 000 | 650 | 420 | 1 200 (giảm 70/s sau 3 s) | 170 px/s | Có |

Pha 2 khi HP ≤ 50%; chuyển pha 1.2 s.

### Đòn
| Pha | Đòn (`animation`) | Gồng | Ra đòn | Hồi | Sát thương | Ghi chú |
|---|---|---|---|---|---|---|
| 1 | Chém quét lưỡi móc (`sweep`) | 600 ms | 160 ms | 650 ms | 140% | Vùng 360×150, bước tới 40 px |
| 1 | Lao móc (`dash`) | 550 ms | 350 ms | 700 ms | 120% | Lao 460 px, đẩy lùi 240 |
| 2 | Sóng tro (`ash_wave`) | 800 ms | 200 ms | 700 ms | 130% × 2 | Cắm lưỡi móc, hai sóng chạy hai phía 640 px |
| 2 | Chém quét nhanh (`sweep`) | 450 ms | 160 ms | 500 ms | 150% | Vùng 380×160 |
| 2 | Lao móc nhanh (`dash`) | 450 ms | 350 ms | 600 ms | 130% | Lao 520 px |

Pha 1 nghỉ 1.5 s, tầm 300 px; pha 2 nghỉ 1.0 s, tầm 320 px, chạy nhanh ×1.3.

---

## 6. Ảnh cần để chạy — quy cách chung (đề xuất)

- Thư mục: `assets/enemies/{id}/frames/`, tên `{id}_{animation}_{NNN}.png` (giống nhân vật, README 2.2 / 17.4).
- **Vẽ hướng phải**, nền trong suốt, PNG. Code tự lật khi quay trái.
- Mỗi quái một `assets/enemies/{id}/frames_manifest.json` (cùng định dạng với nhân vật: `canvas`, `animations`
  → `frames`, `fps`, `loop`).
- Đòn đánh vẽ theo nhịp **gồng → ra đòn → hồi** đúng mili-giây trong data (bảng mục 7); phần gồng phải đọc rõ
  (người chơi né theo nó). fps đòn = 12 (1 frame ≈ 83 ms).
- Đòn pha 2 dùng **cùng animation** với pha 1 (`slam`, `charge`, `sweep`, `dash`) nhưng ngắn hơn → code phát
  nhanh hơn (speed_scale ≈ 1.15–1.35). Không cần vẽ bản riêng.
- Boss không khựng → **không cần** `hurt`; trúng đòn chỉ nháy trắng bằng code.
- Ảnh do AI tạo: ghi từng file vào `docs/ASSET_LICENSES.md` mục 2.1; frame làm theo quy trình duyệt từng
  animation như nhân vật (AGENTS.md mục 4).

### Kích thước khung (đề xuất)

| Data ID | Khung (px) | Tâm x | Chân y | Thân cao (theo hộp va chạm hiện tại) |
|---|---|---|---|---|
| `enemy_slime_01` | 256×256 | 128 | 224 | ~90 px (rộng ~120) |
| `enemy_slime_02` | 320×320 | 160 | 288 | ~130 px (to hơn slime thường ~1.4 lần) |
| `boss_golem_01` | 768×512 | 384 | 464 | ~330 px (rộng ~270); khung ngang rộng vì đập / húc với tới ~320 px trước mặt |
| `boss_henchman_01` | 768×512 | 384 | 464 | ~300 px (chibi như nhân vật); khung rộng cho đường quét lưỡi móc ~340 px, cao cho lưỡi móc giơ qua đầu |

---

## 7. Danh sách animation cần vẽ

### 7.1 `enemy_slime_01` — 44 ảnh

| Animation | Frame | fps | Lặp | Nội dung | Dùng khi |
|---|---|---|---|---|---|
| `idle` | 6 | 8 | có | Phập phồng, đốm than nhấp nháy | Đứng nghỉ đầu đường tuần tra |
| `move` | 8 | 12 | có | Nảy tới (nén – bật – đáp) | Tuần tra, đuổi |
| `attack` | 15 | 12 | không | 6 gồng (nén sâu, đốm than sáng đỏ) · 2 cắn lao · 7 hồi | Cắn lao |
| `hurt` | 3 | 12 | không | Méo dẹt lại | Khựng 0.25 s |
| `stun` | 6 | 8 | có | Chảy xệ, sao/tro xoay trên đầu | Choáng 2 s |
| `death` | 6 | 10 | không | Vỡ thành tro, sụp xuống | Hạ gục (mờ 0.6 s) |

### 7.2 `enemy_slime_02` — 51 ảnh

| Animation | Frame | fps | Lặp | Nội dung |
|---|---|---|---|---|
| `idle` | 6 | 8 | có | Phập phồng chậm, nặng |
| `move` | 8 | 10 | có | Lết / nảy thấp, nặng nề |
| `attack` | 20 | 12 | không | 8 gồng (phồng to, mở miệng rộng) · 2 cắn lao · 10 hồi |
| `hurt` | 3 | 12 | không | Rung nhẹ |
| `stun` | 6 | 8 | có | Xẹp xuống, tro bốc lên |
| `death` | 8 | 10 | không | Vỡ thành đống tro lớn (mờ 0.8 s) |

### 7.3 `boss_golem_01` — 105 ảnh

| Animation | Frame | fps | Lặp | Nội dung |
|---|---|---|---|---|
| `idle` | 6 | 8 | có | Thở nặng, khe nứt sáng mờ, mắt cam đỏ |
| `move` | 8 | 8 | có | Bước đá nặng nề |
| `slam` | 19 | 12 | không | 8 gồng (giơ hai tay đá lên cao) · 3 đập xuống · 8 rút tay |
| `charge` | 22 | 12 | không | 7 gồng (cúi vai, cào chân) · 5 lao húc · 10 trượt dừng, đứng dậy |
| `quake` | 20 | 12 | không | 10 gồng (giẫm lên cao, khe nứt sáng mạnh) · 2 giậm · 8 hồi |
| `stun` | 6 | 8 | có | Quỳ một gối, mắt chập chờn |
| `phase` | 12 | 10 | không | Chuyển pha 1.2 s: lõi ngực nứt ra, lộ ấn trắng-đen, khe nứt sáng cam đỏ |
| `death` | 12 | 10 | không | Gục sấp nguyên khối, ấn ngực tắt (khớp ô `ch01_golem_01`) |

### 7.4 `boss_henchman_01` — 100 ảnh

| Animation | Frame | fps | Lặp | Nội dung |
|---|---|---|---|---|
| `idle` | 6 | 8 | có | Đứng hơi khom, áo choàng lay nhẹ, lưỡi móc chúi xuống |
| `move` | 8 | 10 | có | Bước bình thản, kéo lưỡi móc |
| `sweep` | 17 | 12 | không | 7 gồng (vung lưỡi móc ra sau, tro rỉ từ khe giáp) · 2 quét ngang · 8 hồi |
| `dash` | 19 | 12 | không | 7 gồng (hạ thấp người, lưỡi móc chĩa tới) · 4 lao móc · 8 phanh, quay lại |
| `ash_wave` | 20 | 12 | không | 10 gồng (giơ lưỡi móc, khe giáp sáng cam) · 2 cắm xuống đất · 8 rút lên |
| `stun` | 6 | 8 | có | Chống lưỡi móc, quỳ, giáp nhiễu |
| `phase` | 12 | 10 | không | Chuyển pha 1.2 s: khe giáp bừng cam, tro cuộn quanh lưỡi móc |
| `death` | 12 | 10 | không | Quỳ gối, giáp nứt vỡ (khớp ô `ch01_end_01`), tan vào kênh |

**Tổng frame:** 44 + 51 + 105 + 100 = **300 ảnh**.

---

## 8. Hiệu ứng (VFX) đi kèm

Đặt ở `assets/vfx/enemies/` (hoặc `assets/vfx/pixelfx/<category>/` nếu lấy từ pixelfx — xem AGENTS.md mục 4).

| File (đề xuất) | Khung | Frame / fps | Dùng cho |
|---|---|---|---|
| `vfx_slime_ash_puff` | 128×128 | 6 / 12 | Slime chết, tro tung |
| `vfx_golem_slam_impact` | 384×192 | 6 / 12 | Đập đất: bụi đá, vết nứt |
| `vfx_golem_quake_wave` | 192×128 | 4 / 12, lặp | Sóng đất chạy 600 px (hitbox tách rời 160×90) |
| `vfx_golem_charge_dust` | 256×128 | 4 / 12, lặp | Bụi sau lưng khi húc |
| `vfx_henchman_sweep_arc` | 448×224 | 4 / 15 | Vệt chém lưỡi móc |
| `vfx_henchman_ash_wave` | 192×128 | 4 / 12, lặp | Sóng tro chạy 640 px (hitbox 150×90) |
| `vfx_henchman_dash_trail` | 256×128 | 4 / 12 | Vệt tro khi lao |
| `vfx_boss_phase_burst` | 384×384 | 8 / 12 | Bùng sáng chuyển pha (dùng chung, đổi màu) |

Hiệu ứng pixelfx nhỏ thì phóng to bằng lọc nearest. Âm thanh còn nợ: `sfx_enemy_stunned`, `sfx_enemy_down`
(`docs/OWNER_ASSET_CHECKLIST.md`).

---

## 9. Ảnh tham chiếu / truyện liên quan đến quái

Đã có prompt trong `docs/prompts/ART_MASTER.md`, chưa có ảnh:

| Ảnh | File | Quái |
|---|---|---|
| Bảng thiết kế tay sai | `assets/characters/boss_henchman_01/design/boss_henchman_01_sheet.png` (1536×1024) | Shokuhai — ✅ chuẩn cho ảnh truyện (owner chọn lại v1, 2026-11-19); `…_sheet-v2.png` giữ nhưng không dùng |
| Chân dung tay sai | `assets/characters/boss_henchman_01/portrait/boss_henchman_01_portrait.png` (1024×1024) | Shokuhai — ✅ khớp bảng v1 |
| `ch01_open_10` | `assets/story/ch01/` | Golem: mắt cam đỏ sáng trong bóng tối |
| `ch01_open_12` | `assets/story/ch01/` | Cặn tro trồi lên |
| `ch01_golem_01`, `_04`, `_05`, `_06` | `assets/story/ch01/` | Golem đổ, đầu đá, mảnh ấn trắng-đen |
| `ch01_golem_08` | `assets/story/ch01/` | Tay sai trên vách |
| `ch01_end_01` → `_04`, `_08`, `_11` | `assets/story/ch01/` | Tay sai quỳ, giáp vỡ; đĩa trắng-đen; lưng golem |

Bảng thiết kế owner gửi 2026-11-19 (1536×1024, trước / nghiêng / sau + cận chi tiết) — tham chiếu cho ô truyện và tranh minh họa:

| Ảnh | File |
|---|---|
| Bảng thiết kế Cặn tro | `assets/enemies/enemy_slime_01/design/enemy_slime_01_sheet.png` ✅ |
| Bảng thiết kế Cặn lớn | `assets/enemies/enemy_slime_02/design/enemy_slime_02_sheet.png` ✅ |
| Bảng thiết kế Golem Đá Cổ | `assets/enemies/boss_golem_01/design/boss_golem_01_sheet.png` ✅ (có cận lưng dấu ba vòng đá và ấn ngực) |

---

## 10. Việc cần làm để quái dùng ảnh

1. Vẽ bảng thiết kế (mục 9) → owner duyệt.
2. Vẽ frame theo mục 7, mỗi lần một animation, owner duyệt (giống quy trình frame nhân vật).
3. Code: thêm `AnimatedSprite2D` vào 3 scene `scenes/enemies/`, nạp frame từ manifest, ánh xạ `State` → animation,
   đặt speed_scale cho đòn pha 2; tách `enemy_slime_02` ra scene riêng (to hơn).
4. Thêm VFX mục 8 vào đòn có sóng / va chạm.
5. Ghi `docs/ASSET_LICENSES.md`, chạy `tools\run_tests.ps1`, ghi nhật ký.
