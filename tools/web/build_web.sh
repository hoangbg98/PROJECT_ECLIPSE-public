#!/usr/bin/env bash
# Dựng bản web để deploy Netlify: bó backend + export Godot Web (bản sao ảnh lossy cho nhẹ) vào netlify_site/.
# Cần: Godot 4.6.3 + export templates 4.6.3 (Web), Node >= 20, Python 3.   Dùng: GODOT=/đường/dẫn/godot tools/web/build_web.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
ROOT="$PWD"
GODOT="${GODOT:-godot}"
COPY="${COPY:-${TMPDIR:-/tmp}/eclipse_webcopy}"
(cd tools/web && npm install --no-audit --no-fund && node build_function.mjs && node function_src/selftest.mjs >/dev/null)
python3 -X utf8 -I tools/web/lossy_copy.py "$COPY" 0.9
cd "$COPY"
"$GODOT" --headless --path . --import
mkdir -p netlify_site
"$GODOT" --headless --path . --export-release "Web" netlify_site/index.html
cp netlify_site/index.* "$ROOT/netlify_site/"
ls -la "$ROOT/netlify_site"
