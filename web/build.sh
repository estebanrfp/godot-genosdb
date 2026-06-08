#!/usr/bin/env bash
# Build the Web export into docs/ (served live by GitHub Pages). The
# godot_genosdb addon auto-injects the GenosDB bridge — no manual steps.
#
#   GODOT=/path/to/Godot ./web/build.sh
set -e
HERE="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-godot}"

cd "$HERE"
mkdir -p docs
echo "==> Exporting Web build to docs/ with $GODOT ..."
"$GODOT" --headless --path "$HERE" --export-release "Web" "$HERE/docs/index.html"
cp "$HERE/web/serve.py" "$HERE/docs/serve.py" 2>/dev/null || true
touch "$HERE/docs/.nojekyll"   # let GitHub Pages serve files as-is
echo "==> Done."
echo "    Local : python3 docs/serve.py 8088   (open http://127.0.0.1:8088 in two tabs)"
echo "    Live  : GitHub Pages from /docs"
