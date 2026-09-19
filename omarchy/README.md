# Sidebar-only illogical-impulse, for machines that already have a shell

This directory is the only thing this fork adds to end-4/dots-hyprland. Everything
else in the repository is upstream, untouched, so merging upstream stays cheap.

It exists because upstream `ii` is one quickshell config holding about twenty
panels, and its installer replaces `~/.config/hypr`, pulls in a pinned
`quickshell-git` that conflicts with the distribution package, and runs a
`ConflictKiller` service that kills other shells. On a system that already has a
shell it likes (Omarchy, for example) none of that is acceptable.

What this directory does instead: run the left sidebar, and nothing else, as a
second quickshell instance beside the existing one.

## Layout

    omarchy/shell.qml          sidebar-only entry point, replaces shell.qml at deploy time
    omarchy/install.sh         deploys into ~/.config/quickshell/ii-sidebar
    omarchy/check-compat.sh    asserts the upstream symbols the entry point needs still exist
    omarchy/bin/               ii-sidebar-toggle, ii-ai-bridge
    omarchy/systemd/           user units for the bridge and an optional ssh tunnel
    omarchy/examples/          backends, extra models, keybinds

Nothing here contains personal paths, hosts or accounts. Those live in
`~/.config/ii-ai-bridge/backends.json` and `~/.config/illogical-impulse/config.json`
on the machine.

## Install

    git clone --recurse-submodules https://github.com/ENEmyr/dots-hyprland
    cd dots-hyprland
    ./omarchy/install.sh

Arch packages needed beyond a normal quickshell setup: `syntax-highlighting` and
`ttf-material-symbols-variable`. The distribution `quickshell` package is enough;
upstream's pinned `quickshell-git` is not required and conflicts with it.

## Update

    git pull                      # this fork's omarchy branch
    ./omarchy/install.sh

`install.sh` runs `check-compat.sh` first and refuses to deploy when upstream has
moved something the sidebar-only entry point depends on.

Upstream changes arrive as a pull request opened by
`.github/workflows/upstream-sync.yml`, which merges `upstream/main` weekly and
asks Claude to reconcile the merge when it conflicts.

## The AI bridge

`ii-ai-bridge` is optional and independent of the panel. The sidebar can only talk
to HTTP endpoints in OpenAI, Gemini or Mistral format, while Claude Code, Codex and
the Antigravity CLI authenticate with their own subscriptions and have no HTTP
server. The bridge listens on `127.0.0.1:8765`, accepts `POST /v1/chat/completions`,
runs the matching CLI once in headless mode, and streams the reply back as SSE.

Every backend runs with its tools disabled or read-only and with an empty scratch
directory as its working directory, because a sidebar chat has no business touching
files:

    claude   --tools ""                          (init event reports "tools":[])
    codex    --sandbox read-only
    agy      --sandbox                           (tool actions come back denied)

Backends are declared in `~/.config/ii-ai-bridge/backends.json`; see
`examples/backends.example.json`. Ollama needs no bridge at all, it already speaks
the OpenAI format, so point an `extraModels` entry straight at it.

Licence: this fork inherits GPL-3.0 from upstream.
