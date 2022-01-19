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
Zterm (pronounced `Zed-Term`) is a simple terminal emulator using Vte and Gtk+
written using the [Zig](https://ziglang.org/) programming language. Some useful
features of Zterm are:
* Multiple terminals can be open in tabs and panes within a single tab
* Configurable keybindings
* Comprehensive theming options
  * Control over colors used
  * Choice of backgrounds - solid color, transparent, image or gradient
* Simple and small graphical interface taking up less screen space than other
  similarly functional terminals

## Building
You will need the Zig compiler, version 0.9.0, available from
[ziglang.org](https://ziglang.org). You will also need the Gtk-3.x and vte
libraries plus development headers installed on your system.

Zterm can be built using either the [Zigmod](https://github.com/nektro/zigmod)
package manager for Zig.
### Zigmod
```sh
zigmod ci
zig build -Drelease-safe=true
```
Alternatively, build and install with the included `Makefile` (still requires
zigmod).
```sh
make all
make install-strip
```

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
```sh
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
  - [x] Background image
  - [x] Background gradient
  - [ ] Expose charset settings
- [x] User editable keybindings
- [ ] Dialog to set keybindings
- [ ] Set tab title based on running program / current directory
- [ ] change from GtkBox widget to more flexible GtkPaned
- [ ] change build to utilize only zig build system
