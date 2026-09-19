-- Example bindings for the sidebar. On Omarchy put these in
-- ~/.config/hypr/personal.lua, which "omarchy refresh hyprland" never overwrites.
-- On plain Hyprland with the classic config format the equivalent lines are:
--   bind = SUPER, A, exec, ~/.local/bin/ii-sidebar-toggle
--   exec-once = /usr/bin/qs -d -n -c ii-sidebar

o.bind("SUPER + A", "AI sidebar", os.getenv("HOME") .. "/.local/bin/ii-sidebar-toggle")

-- -n (--no-duplicate) matters: without it, pressing the key while the autostart
-- instance is still coming up leaves two instances and two stacked panels.
o.exec_on_start("/usr/bin/qs -d -n -c ii-sidebar")
