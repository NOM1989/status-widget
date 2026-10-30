# status-widget

A MacBook-style notch at the top of the screen for Hyprland, built with [Quickshell](https://quickshell.org).

![Status Widget](./status-widget-example.png "Status Widget Image")

Hover over the gauges to see the percentage, plus the battery time estimate. Hover over the time to see the date. Click anywhere on the notch to hide it.

## Requirements (Arch)

```sh
sudo pacman -S quickshell upower ttf-jetbrains-mono-nerd
sudo systemctl enable --now upower
```

## Install

Clone the repo anywhere; these examples use `~/repos/status-widget`.

Add to your Hyprland config to start it at login and toggle it with a key:

```lua
-- hyprland.lua (inside hl.on("hyprland.start", ...))
hl.exec_cmd("qs -p ~/repos/status-widget")
-- top level
hl.bind("SUPER + I", hl.dsp.exec_cmd("qs -p ~/repos/status-widget ipc call widget toggle"))
```

To run it now without logging out: `qs -p ~/repos/status-widget -d`

## IPC

```sh
qs -p ~/repos/status-widget ipc call widget toggle   # also: open, close
```

While hidden, the widget's windows are destroyed and its timers stop, so it costs no CPU.
