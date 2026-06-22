#!/bin/bash
# Double-click launcher (macOS). Runs the full-stack installer in Terminal.
DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$DIR/install-everything.sh"
echo
echo "Done. Review the messages above; you can close this window."
