# Phiếu 00 — Mở rộng `tools/frames/` cho quái (làm MỘT lần, trước phiếu 01)

> Claude viết 2026-11-19. Bộ công cụ `tools/frames/` hiện cứng cho nhân vật: khung 384, tâm 192, chân 336, đường dẫn
> `assets/characters/`. Quái cần khung 256 và thư mục `assets/enemies/`. Phiếu này là việc code, không tạo ảnh.

## Prompt dán cho Codex

```text
Việc: mở rộng bộ công cụ tools/frames/ để dùng được cho quái (kind = "enemy"), chưa tạo ảnh.
Đọc trước: AGENTS.md, docs/prompts/codex_frames/PROMPT_GOC.md, docs/prompts/codex_frames/enemy_slime_01/00_PHAN_TICH.md,
tools/frames/jobs/enemy_slime_01.json (phiếu việc mẫu cho quái, đã có sẵn).

Yêu cầu:
1. frame_jobs.py: đọc từ phiếu việc các khóa tùy chọn "kind" ("character" mặc định | "enemy"), "canvas", "pivot_x",
   "baseline_y" (mặc định 384 / 192 / 336 như hiện tại). Mọi chỗ dùng CANVAS / PIVOT_X / BASELINE_Y lấy theo phiếu.
   Đường dẫn: kind = enemy → assets/enemies/{id}/ (frames/{anim}/, frames_manifest.json); character giữ nguyên.
   plan() không bắt buộc manifest phải có sẵn: loop lấy từ phiếu nếu manifest chưa có.
2. slice_strip.py, check_frames.py, approve_frames.py: dùng khung / tâm / chân / thư mục theo phiếu (sheet.png vẽ đường chân
   và tâm đúng giá trị mới; ngưỡng lệch tâm và cắt mép tính theo cỡ khung).
3. approve_frames.py với quái: nếu chưa có assets/enemies/{id}/frames_manifest.json thì tạo mới, cùng định dạng manifest
   nhân vật (character_id, working_name, canvas {width, height, pivot_x, baseline_y}, facing "right", file_pattern,
   animations {frames, fps, loop, skill_key: null}); ghi docs/ASSET_LICENSES.md mục 2.1 như nhân vật.
4. gen_prompts.py: KHÔNG chạy cho enemy_slime_01 (phiếu Markdown của quái viết tay). Nếu gen_prompts.py bị gọi với phiếu có
   kind = enemy thì dừng, in thông báo, không ghi đè file.
5. Không đổi kết quả cho nhân vật: chạy python -I tools/frames/check_frames.py char_fire_01 idle --approved trước và sau khi
   sửa, kết quả phải giống nhau. Chạy python -I tools/frames/gen_prompts.py char_fire_01 rồi git diff docs/prompts/codex_frames/char_fire_01
   phải trống.
6. Chạy powershell -ExecutionPolicy Bypass -File tools\run_tests.ps1 (mã thoát 0).
7. Ghi docs/DEVELOPMENT_LOG.md (mục "Art tools: frame tools support enemies"), commit "Art tools: frame pipeline supports enemies
   (256 canvas, assets/enemies)", push. Báo tôi kết quả lệnh ở bước 5–6.
```
