# Zterm
![Zterm icon](https://hitchhiker-linux.org/assets/zterm-256.png)
Zterm is a simple terminal emulator using Vte and Gtk+ writting using the
[Zig](https://ziglang.org/) programming language. Currently basic functionality
works including opening and closing terminals in tabs and panes, giving it a
program to run on the command line and setting the title from the command line.
In the future, Zterm will have a configuration framework that allows setting
things like colors, scrollback buffer lines and the terminal font.

## Building
You will need the Zig compiler, version 0.8 or above, available from
[ziglang.org](https://ziglang.org). You will also need the Gtk-3.x and vte
libraries plus development headers installed on your system. Building is
accomplished via the zig build system.
```Bash
zig build -Drelease-safe=true
```
At present there is no installation script, simply copy zig-out/bin/zterm to
somewhere in your path.
```Bash
install -sv zig-out/bin/zterm <directory in your path>
```

## Keyboard Shortcuts
| Shortcut | Action |
| -------- | ------ |
| Ctrl/Shift/T | New Tab |
| Ctrl/+ | New Pane |
| Alt/R | Change Pane Orientation |
| Alt/[1-9] | Goto [num] Tab |
| Alt/LeftArrow | Previous Tab |
| Ctrl/PageUp | Previous Tab |
| Alt/RightArrow | Next Tab |
| Ctrl/PageDown | Next Tab |
| Ctrl/Shift/Q | Quit |
