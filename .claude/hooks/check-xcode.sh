#!/bin/sh
# SessionStart hook: Xcode MCP (xcrun mcpbridge) talks to a running Xcode.
# Warn the user and tell the model when Xcode is not running, so failures
# are attributed correctly instead of silently falling back to CLI.
if pgrep -xq Xcode; then
  exit 0
fi
cat <<'EOF'
{"systemMessage":"Xcode is not running: Xcode MCP tools will fail. Open drinkpulse.xcodeproj in Xcode, then run /mcp to reconnect.","hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"Xcode is not running at session start, so Xcode MCP (mcpbridge) is unavailable. Ask the owner to open drinkpulse.xcodeproj in Xcode before any build/test step. Do not silently fall back to xcodebuild."}}
EOF
