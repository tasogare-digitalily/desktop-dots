-- This is an example Hyprland Lua config file.
-- Refer to the wiki for more information.
-- https://wiki.hypr.land/Configuring/Start/

-- Please note not all available settings / options are set here.
-- For a full list, see the wiki

-- You can (and should!!) split this configuration into multiple files
-- Create your files separately and then require them like this:
-- require("myColors")

-----------------------
---- NVIDIA CONFIG ----
-----------------------

hl.env("IBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")


---------------------
---- COLOR SETUP ----
---------------------

-- Load colors from wal cache
local function parse_hyprland_colors(path)
    local file = io.open(path, "r")
    if not file then
        return {}
    end

    local vars = {}

    for line in file:lines() do
        local key, value = line:match("^%s*%$([%w_]+)%s*=%s*(.-)%s*$")
        if key and value then
            value = value:gsub("^%s*(.-)%s*$", "%1")

            if value:match('^".*"$') or value:match("^'.*'$") then
                value = value:sub(2, -2)
            elseif value:match("^%d+%.%d+$") then
                value = tonumber(value)
            elseif value:match("^%d+$") then
                value = tonumber(value)
            end

            vars[key] = value
            _G[key] = value
        end
    end

    file:close()
    return vars
end

local colors_path = os.getenv("HYPR_COLORS_CONF") or (os.getenv("HOME") .. "/.cache/wal/colors-hyprland.conf")
local colors = parse_hyprland_colors(colors_path)

------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

hl.monitor({
  output = "DP-1",
  mode = "3840x2160@60",
  position = "0x0",
  scale = 2,
})

hl.monitor({
  output = "DP-2",
  mode = "3840x2160@60",
  position = "1920x0",
  scale = 2,
})

-- setup for my wacom tablet
hl.device({
    name = "wacom-one-pen-display-13-pen",
    transform = 0,
    output = "HDMI-A-1"
})

-- set wacom tablet to mirror second monitor
hl.monitor({
    output = "HDMI-A-1",
    mode = "1920x1080@60",
    position = "auto",
    scale = 1,
    mirror = "DP-2",

})

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})

-- unscale XWayland; this fixes apps like steam
-- from appearing pixelated, though their resolution is thusly out
-- of whack
hl.config({
  xwayland = {
    force_zero_scaling = true
  }
})

-- toolkit-specific scale
hl.env("GDK_SCALE", "2")
hl.env("XCURSOR_SIZE", "32")

-- QT app scaling
hl.env("QT_SCALE_FACTOR", "1.5")


---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "kitty"
local fileManager = "thunar"
local menu        = "wofi --show drun -n"
local lockScreen = "hyprlock"


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function () 
  hl.exec_cmd("sleep 2 && hyprctl reload &")
  hl.exec_cmd("wal -R")
  hl.exec_cmd("waybar")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("xwaylandvideobridge")
  hl.exec_cmd("sleep .5 && awww restore")
  hl.exec_cmd("swaync")
  hl.exec_cmd("pypr")
  hl.exec_cmd("swaync-client -default")
  hl.exec_cmd("pactl set-sink-mute @DEFAULT_SINK@ 0")
  hl.env("ELECTRON_OZONE_PlATFORM_HINT", "wayland")
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("sleep 2 && discord", { workspace = "special:discord silent" })
  hl.exec_cmd("sleep 3 && spotify", { workspace = "special:spotify silent" })
  hl.exec_cmd("sleep 3 && steam", { workspace = "special:steam silent" })
  hl.exec_cmd("sleep 5 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") 
  hl.exec_cmd("sleep 6 && hypridle")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in  = 2,
        gaps_out = 10,

        border_size = 1,

        col = {
            active_border   = colors.color9, -- { colors = {"rgba(33ccffee)", "rgba(00ff99ee)"}, angle = 45 },
            inactive_border = colors.color5,
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = true,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 0.78,
        inactive_opacity = 0.7,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled   = true,
            size      = 3,
            passes    = 5,
            vibrancy  = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

-- Default springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

-- Ref https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/ for more
hl.config({
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Master-Layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/ for more
-- TODO: needed?
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = -1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = false, -- If true disables the random hyprland logo / anime girl background. :(
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = -.1, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
            scroll_factor = 0.3
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

hl.device({
    name = "tpps/2-elan-trackpoint",
    sensitivity = -.7,
})

---------------------
---- MOUSE BINDS ----
---------------------
-- TODO: HOW DO?
-- binds {
--     drag_threshold = 10  # Fire a drag event only after dragging for more than 10px
-- }
-- bindm = ALT, mouse:272, movewindow      # ALT + LMB: Move a window by dragging more than 10px.
-- bindc = ALT, mouse:272, togglefloating  # ALT + LMB: Floats a window by clicking


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- Example binds, see https://wiki.hypr.land/Configuring/Basics/Binds/ for more
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(lockScreen))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("sh ~/.config/hypr/wallpaper.sh"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("wlogout -b 2"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + V", hl.dsp.window.float({action = "toggle"}))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("pavucontrol"))
hl.bind(mainMod .. " + J", hl.dsp.exec_cmd("togglesplit")) -- dwindle only
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + SHIFT + I", hl.dsp.exec_cmd("firefox -private-window"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

--  Special workspace
hl.bind(mainMod .. " + mouse:274",         hl.dsp.workspace.toggle_special("spotify"))
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("discord"))
hl.bind(mainMod .. " + mouse:275",         hl.dsp.workspace.toggle_special("steam"))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


---------------------
---- LAYER RULES ----
---------------------

hl.layer_rule({
  match        = { namespace = "swaync-control-center" },
  blur         = true,
  ignore_alpha = 0.5,
})

hl.layer_rule({
  match        = { namespace = "swaync-notification-window" },
  blur         = true,
  ignore_alpha = 0.5,
})

hl.layer_rule({
  match        = { namespace = "wofi" },
  blur         = true,
  ignore_alpha = 0.5,
})

hl.layer_rule({
  match        = { namespace = "wlogout" },
  blur         = true,
  dim_around = true,
  ignore_alpha = 0.5,
})

hl.layer_rule({
  match        = { namespace = "logout_dialog" },
  blur         = true,
  dim_around = true,
  ignore_alpha = 0.5,
})

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- and https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-- Example window rules that are useful

-- local suppressMaximizeRule = hl.window_rule({
--     -- Ignore maximize requests from all apps. You'll probably like this.
--     name  = "suppress-maximize-events",
--     match = { class = ".*" },

--     suppress_event = "maximize",
-- })
-- -- suppressMaximizeRule:set_enabled(false)

-- hl.window_rule({
--     -- Fix some dragging issues with XWayland
--     name  = "fix-xwayland-drags",
--     match = {
--         class      = "^$",
--         title      = "^$",
--         xwayland   = true,
--         float      = true,
--         fullscreen = false,
--         pin        = false,
--     },

--     no_focus = true,
-- })

-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

hl.window_rule({
    name = "windowrule-1",
    workspace = "special:spotify silent",
    match = { 
        class = "^([Ss][Pp][Oo][Tt][Ii][Ff][Yy])([ ][Pp][Rr][Ee][Mm][Ii][Uu][Mm])?$",
        initial_title="^([Ss][Pp][Oo][Tt][Ii][Ff][Yy])([ ][Pp][Rr][Ee][Mm][Ii][Uu][Mm])?$",
    }
})

hl.window_rule({
    name = "windowrule-2",
    workspace = "special:discord silent",
    match = { 
        class = "^(discord)$",
        initial_title="Discord",
    }
})

hl.window_rule({
    name = "windowrule-3",
    no_focus = true,
    match = { 
        class = "^(net-runelite-client-RuneLite)$",
        title="^(win0)$",
    }
})

hl.window_rule({
    name = "windowrule-4",
    opacity = "1.0 override",
    match = { 
        class = "^(net-runelite-client-RuneLite)$",
    }
})

hl.window_rule({
    name = "windowrule-5",
    float = true,
    match = {
        title="^(.*Network Manager.*)$",
    }
})

hl.window_rule({
    name = "windowrule-6",
    float = true,
    match = {
        title="^(.*Bluetooth Devices.*)$",
    }
})

hl.window_rule({
    name = "windowrule-7",
    stay_focused = true, -- TODO false?
    workspace = "special:steam silent",
    match = {
        class="^(steam)$",
        initial_title="Steam",
    }
})

hl.window_rule({
    name = "windowrule-8",
    float = true,
    match = {
        title="^(.*Volume Control.*)$",
    }
})

hl.window_rule({
    name = "xwayland-video-bridge-fixes",
    match = {
        class="xwaylandvideobridge",
    },
    no_initial_focus = true,
    no_focus = true,
    no_anim = true,
    no_blur = true,
    max_size = { 1, 1 },
    opacity = "0.0"
})

hl.window_rule({
    name ="repo pointer",
    match = {
        class = steam_app_3241660
    },
    confine_pointer = true,
})

hl.window_rule({
    name ="blue prince pointer",
    match = {
        class = steam_app_1569580aw
    },
    confine_pointer = true,
})
