#!/usr/bin/env bash
# Assert that everything omarchy/shell.qml and ii-ai-bridge depend on still
# exists upstream. Run it after merging upstream and before deploying.
# Exit 0 means the sidebar-only entry point should still load.
set -uo pipefail

cd "$(dirname "$0")/.." >/dev/null || exit 2
II="dots/.config/quickshell/ii"
fail=0

check() {
    local label=$1 result=$2
    if [ "$result" = "ok" ]; then
        printf 'ok    %s\n' "$label"
    else
        printf 'FAIL  %s\n' "$label"
        fail=$((fail + 1))
    fi
}

file_has() { # file, pattern, label
    if [ -f "$II/$1" ] && grep -qF "$2" "$II/$1"; then check "$3" ok; else check "$3" bad; fi
}

exists() { # path, label
    if [ -e "$II/$1" ]; then check "$2" ok; else check "$2" bad; fi
}

# Entry point dependencies
exists "modules/ii/sidebarLeft/SidebarLeft.qml" "SidebarLeft.qml exists"
exists "modules/common/Config.qml" "modules/common/Config.qml exists"
exists "services/MaterialThemeLoader.qml" "services/MaterialThemeLoader.qml exists"
exists "modules/common/widgets/shapes" "widgets/shapes submodule checked out"
file_has "modules/common/Config.qml" 'property bool ready' "Config.ready still exists"
file_has "services/MaterialThemeLoader.qml" 'function reapplyTheme' "MaterialThemeLoader.reapplyTheme exists"
file_has "modules/ii/sidebarLeft/SidebarLeft.qml" 'target: "sidebarLeft"' "sidebarLeft IPC target intact"
file_has "modules/ii/sidebarLeft/SidebarLeft.qml" 'GlobalStates.sidebarLeftOpen' "sidebarLeftOpen state intact"

# Bridge contract
file_has "services/Ai.qml" 'extraModels' "Ai.qml still reads ai.extraModels"
file_has "services/Ai.qml" 'requires_key' "Ai.qml still honours requires_key"
file_has "services/ai/OpenAiApiStrategy.qml" 'parseResponseLine' "OpenAI strategy still parses SSE lines"
file_has "services/ai/OpenAiApiStrategy.qml" 'delta?.content' "OpenAI strategy still reads delta.content"

# Submodule health: a leading '-' means not initialised
if git submodule status --recursive 2>/dev/null | grep -q '^-'; then
    check "no uninitialised submodules" bad
else
    check "no uninitialised submodules" ok
fi

if [ "$fail" -gt 0 ]; then
    printf '\n%d check(s) failed. omarchy/shell.qml or ii-ai-bridge needs updating before deploying.\n' "$fail"
    exit 1
fi
printf '\nAll checks passed.\n'
