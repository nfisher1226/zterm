include config.mk
PROGNAME       = zt
INSTALLDIRS    = $(BINDIR)
VPATH         += src
VPATH         += zig-out/bin
VPATH         += data
SRCS          += build.zig
SRCS          += config.zig
SRCS          += deps.zig
SRCS          += gui.zig
SRCS          += keys.zig
SRCS          += main.zig
SRCS          += menus.zig
SRCS          += prefs.zig
SRCS          += version.zig
SRCS          += gui.glade
SRCS          += prefs.glade
INSTALLDIRS   += $(XDGDIR)
INSTALLDIRS   += $(ICONDIR)
INSTALL_OBJS  += $(BINDIR)/$(PROGNAME)
INSTALL_OBJS  += $(XDGDIR)/zterm.desktop
INSTALL_OBJS  += $(ICONDIR)/zterm.svg

all: $(PROGNAME)

deps.zig:
	zigmod ci

$(PROGNAME): $(SRCS)
	zig build -Drelease-safe=true

install: $(INSTALL_OBJS)

install-strip: $(INSTALL_OBJS)
	strip -s $<
	du -hc $(INSTALL_OBJS)

$(BINDIR)/$(PROGNAME): $(PROGNAME) | $(BINDIR)
	install -m0755 $< $@

$(XDGDIR)/zterm.desktop: zterm.desktop | $(XDGDIR)
	install -m644 $< $@

$(ICONDIR)/zterm.svg: zterm.svg | $(ICONDIR)
	install -m644 $< $@

$(INSTALLDIRS):
	install -d $@

clean:
	rm -rf zig-out/ zig-cache/

distclean: clean
	rm -rf .zigmod deps.zig

uninstall:
	rm -rf $(BINDIR)/$(PROGNAME)

.PHONY: all clean distclean install install-strip
