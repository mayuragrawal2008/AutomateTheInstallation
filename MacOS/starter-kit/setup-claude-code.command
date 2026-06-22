#!/bin/bash
# Double-click launcher (macOS). Runs the starter-kit installer in Terminal.
DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$DIR/install-claude-code-kit.sh"
echo
echo "Done. You can close this window."
