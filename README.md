# Zterm
![Zterm icon](data/zterm.svg)
<br />
Contents
========
* [Introduction](#introduction)
* [Building](#building)
* [Keyboard Shortcuts](#keyboard-shortcuts)
* [Command Line Options](#command-line-options)
* [Configuration](#configuration)
* [Roadmap](#roadmap)

## Introduction
Zterm is a simple terminal emulator using Vte and Gtk+ writting using the
[Zig](https://ziglang.org/) programming language. Currently basic functionality
works including opening and closing terminals in tabs and panes, giving it a
program to run on the command line and setting the title from the command line.

## Building
You will need the Zig compiler, version 0.9.0, available from
[ziglang.org](https://ziglang.org). You will also need the Gtk-3.x and vte
libraries plus development headers installed on your system.

Zterm can be built using either the [Gyro](https://github.com/mattnite/gyro) or
[Zigmod](https://github.com/nektro/zigmod) package managers for Zig.
### Gyro
> NOTE: Gyro build is out of date and currently broken
```Bash
gyro build -Drelease-safe=true
```
### Zigmod
```Bash
zigmod fetch
zig build -Drelease-safe=true
```
Alternatively, build and install with the included `Makefile`.

## Keyboard Shortcuts
The following table gives the default keybindings. If any customization is
desired, see [configuration](#configuration)
| Shortcut | Action |
| -------- | ------ |
| Ctrl/Shift/T | New Tab |
| Ctrl/Shift/Enter | New Pane |
| Alt/R | Change Pane Orientation |
| Alt/[1-9] | Goto [num] Tab |
| Alt/UpArrow | Previous Tab |
| Ctrl/PageUp | Previous Tab |
| Alt/DownArrow | Next Tab |
| Ctrl/PageDown | Next Tab |
| Alt/RightArrow | Next Pane |
| Alt/LeftArrow | Previous Pane |
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
## Configuration
Zterm uses the [nestedtext](https://nestedtext.org/en/latest/) human readable
data format to store it's configuration. The main program options may be edited
with the `preferences` dialog without editing any files. However, at this time the
only way to change the default keybindings is by editing the file
`~/.config/zterm/keys.nt`. The file will be auto-generated if it does not exist.
All configuration options set via the `preferences` dialog will take effect
immediately. Any changes to the `keys.nt` file will require a restart to take
effect.
## Roadmap
- [x] Preferences dialog
- [ ] Remove most color handling code and replace with `zig-color` color library
- [ ] Finish implementing all preferences
  - [x] Background image - status can set image, cannot set style
  - [ ] Expose charset settings
- [x] User editable keybindings
- [ ] Dialog to set keybindings
- [ ] Set tab title based on running program / current directory
- [ ] change from GtkBox widget to more flexible GtkPaned
