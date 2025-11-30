#!/bin/bash
# Background test watcher - runs tests on file changes
# Usage: ./scripts/watch-tests.sh

set -e

cd "$(dirname "$0")/../gleam"

echo "Watching for changes in gleam/src and gleam/test..."
echo "Press Ctrl+C to stop"

# Use inotifywait if available, otherwise fall back to polling
if command -v inotifywait &> /dev/null; then
    while true; do
        inotifywait -r -e modify,create,delete src test 2>/dev/null
        echo ""
        echo "=== Running tests at $(date) ==="
        gleam test || echo "Tests failed!"
        echo ""
    done
else
    # Polling fallback for systems without inotify
    LAST_HASH=""
    while true; do
        CURRENT_HASH=$(find src test -name "*.gleam" -exec md5sum {} \; 2>/dev/null | md5sum)
        if [ "$CURRENT_HASH" != "$LAST_HASH" ] && [ -n "$LAST_HASH" ]; then
            echo ""
            echo "=== Running tests at $(date) ==="
            gleam test || echo "Tests failed!"
            echo ""
        fi
        LAST_HASH="$CURRENT_HASH"
        sleep 2
    done
fi
