# Thiết kế Thợ Cả Ishiro — người đứng đầu xưởng thủ vệ (`npc_ishiro_01`)

> Owner chốt 2026-11-21: **phương án A "Thợ rèn già vững chãi"**. Bảng thiết kế chuẩn:
> `assets/characters/npc_ishiro_01/design/npc_ishiro_01_sheet.png` (1536×1024, trước / nghiêng / sau, cận mặt, cận vòng đá, cận tay bó băng).
> Hai phương án còn lại (B ông lão gầy kính một mắt, C thợ cả đầu trọc) giữ ở `art_review/characters/ishiro/` (không vào git).

## Vai trò trong truyện (`docs/design/CH02_STORY.md`)

- Thợ Cả của xưởng làm thủ vệ trên Cao Nguyên Thủ Vệ (Chương 2). Bị thương khi xưởng bị đột nhập (tay trái bó băng treo trước ngực).
- Cuối Chương 2 ông trao cho Iwagane **vòng đá ba vòng chồng nhau** (dấu của xưởng): *"Ca gác này chuyển cho con. Không phải một mình."*
- Xuất hiện ở clip `ch02_end` (ô 9). Người nói trong clip: `ishiro` (tên hiển thị `NPC_ISHIRO`).
- Tên Ishiro và dòng họ Gác Đá là tên đề xuất của Claude (owner chưa phản đối).

## Khóa thiết kế (mọi ảnh có Ishiro phải giữ)

- Ông già, tóc xám bồng, râu bạc ngắn, nét mặt nghiêm có vết sẹo nhỏ bên mắt; vai rộng, dáng vững, hơi gù nhẹ; tỉ lệ anime chuẩn, không chibi.
- Vai giáp đồng và xanh rêu có họa tiết đá, áo chùng nâu, tạp dề da dày thêu hoa văn đá, thắt lưng nhiều túi nhỏ, búa nhỏ ở thắt lưng, găng da, ủng da có mũi sắt.
- Tay trái bó băng trắng ngà treo trước ngực; vòng đá ba vòng chồng nhau (rêu bám) trên dây da trước ngực.
- Bảng màu: nâu đồng, xám đá, xanh rêu, tro (cùng bảng với Iwagane).

## Prompt rút gọn để tạo lại

```text
Anime 2D character design sheet on flat grey #C8C8C8: front / side / back full body, face close-up, close-up of a small stone pendant of three stacked
rings, close-up of a bandaged arm in a sling, no text. Elderly master smith: messy grey hair, short grey beard, stern scarred face, broad shoulders,
slightly stooped, bronze-and-moss-green shoulder plates with stone patterns, brown smock and thick leather apron embroidered with a stone motif,
belt pouches and a small hammer, leather gloves, iron-toed boots, left arm bandaged in a white sling. Standard anime proportions, not chibi.
```
