# Zterm
![Zterm icon](https://hitchhiker-linux.org/assets/zterm-256.png)

Zterm is a simple terminal emulator using Vte and Gtk+ writting using the
[Zig](https://ziglang.org/) programming language. Currently basic functionality
works including opening and closing terminals in tabs and panes, giving it a
program to run on the command line and setting the title from the command line.

Zterm is under heavy development and currently no settings are saved to disk.
However, it is possible to set many aspects of the program's behavior at runtime
such as font, colors, scrollback lines etc.

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

## Command line options
```Bash
Usage: zterm [-h] [-e <COMMAND>] [-t <TITLE>] [-w <DIR>]
Flags:
	-h, --help                   	Display this help and exit.
	-e, --command <COMMAND>      	Command and args to execute.
	-t, --title <TITLE>          	Defines the window title.
	-w, --working-directory <DIR>	Set the terminal's working directory.
```
