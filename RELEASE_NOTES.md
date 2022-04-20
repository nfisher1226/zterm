Contents
========
* [0.4.0](0.4.0-release)
* [0.3.1](0.3.0-release)
* [0.3.0](0.3.0-release)

## 0.4.0 release
* Update to 10.0 zig compiler
* update zig-clap to most recent

## 0.3.1 release
* Added `About` dialog with credits
* Removed `Makefile`
* Replaced functionality in `Makefile` in `build.zig`
* Added ability to create a package archive in `build.zig`
* Export png application icons in build.zig (requires inkscape)
* Cleaned up application menu by moving navigation items and copy/paste into
  currently not shown top level menus

## 0.3.0 release
* Significant refactor
* Almost full use of `zig-vte` interface in favor of `C` interface
* User editable keybindings
* Working image backgrounds
* Gradient backgrounds
* Solid color backgrounds set using css
* Binary renamed to `zt`
* Icon refresh
* Dependencies frozen until next release
* Remove `gyro` build option
