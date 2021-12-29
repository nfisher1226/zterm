PREFIX      ?= /usr/local
BINDIR      ?= $(DESTDIR)$(PREFIX)/bin
DATADIR     ?= $(DESTDIR)$(PREFIX)/share
XDGDIR      ?= $(DATADIR)/applications
ICONDIR     ?= $(DATADIR)/icons/hicolor/scalable/apps
MANDIR      ?= $(DATADIR)/share/man
# Set this to `gyro` if using gyro instead of zigmod
BUILD_CMD   ?= zig
