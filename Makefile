include config.mk
PROGNAME       = zterm
INSTALLDIRS    = $(BINDIR)
VPATH         += src
VPATH         += zig-out/bin
VPATH         += data
SRCS          += build.zig
SRCS          += config.zig
SRCS          += gui.zig
SRCS          += main.zig
SRCS          += prefs.zig
SRCS          += version.zig
SRCS          += gui.glade
SRCS          += prefs.glade
INSTALLDIRS   += $(XDGDIR)
INSTALLDIRS   += $(ICONDIR)
INSTALL_OBJS  += $(BINDIR)/$(PROGNAME)
INSTALL_OBJS  += $(XDGDIR)/$(PROGNAME).desktop
INSTALL_OBJS  += $(ICONDIR)/$(PROGNAME).svg

all: $(PROGNAME)

$(PROGNAME): $(SRCS)
	$(BUILD_CMD) build -Drelease-safe=true

install: $(INSTALL_OBJS)

install-strip: $(INSTALL_OBJS)
	strip -s $<
	du -hc $(INSTALL_OBJS)

$(BINDIR)/$(PROGNAME): $(PROGNAME) | $(BINDIR)
	install -m0755 $< $@

$(XDGDIR)/$(PROGNAME).desktop: $(PROGNAME).desktop | $(XDGDIR)
	install -m644 $< $@

$(ICONDIR)/$(PROGNAME).svg: $(PROGNAME).svg | $(ICONDIR)
	install -m644 $< $@

$(INSTALLDIRS):
	install -d $@

clean:
	rm -rf zig-out/ zig-cache/

uninstall:
	rm -rf $(BINDIR)/$(PROGNAME)

.PHONY: all clean install install-strip
