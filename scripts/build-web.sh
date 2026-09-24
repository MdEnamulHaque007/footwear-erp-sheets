#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION=3.19.6
FLUTTER_DIR="${TMPDIR:-/tmp}/footwear-flutter-sdk"

if [[ ! -x "$FLUTTER_DIR/bin/flutter" ]]; then
  git clone --depth 1 --branch "$FLUTTER_VERSION" \
    https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

"$FLUTTER_DIR/bin/flutter" config --enable-web
"$FLUTTER_DIR/bin/flutter" pub get
"$FLUTTER_DIR/bin/flutter" build web --release
