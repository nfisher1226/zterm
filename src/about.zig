const VTE = @import("vte");
const c = VTE.c;
const gtk = VTE.gtk;
const AboutDialog = gtk.AboutDialog;
const std = @import("std");
const version = @import("version.zig").version;
const allocator = std.heap.page_allocator;
const fmt = std.fmt;
const fs = std.fs;
const mem = std.mem;
const os = std.os;
const gettext = @import("gettext.zig").gettext;

pub fn init() AboutDialog {
    const dlg = AboutDialog.new();
    setup(dlg);
    return dlg;
}

pub fn setup(dlg: AboutDialog) void {
    dlg.set_program_name("Zterm");
    dlg.set_version(version);
    dlg.set_copyright("Copyright © 2021 Nathan Fisher");
    dlg.set_license(license);
    dlg.set_wrap_license(true);
    dlg.set_website("https://jeang3nie.codeberg.page/zterm/");
    dlg.set_website_label("Website");
    var authors = [_:0][*c]const u8{"Nathan Fisher"};
    dlg.set_authors(&authors);
    var artists = [_:0][*c]const u8{"Nathan Fisher"};
    dlg.set_artists(&artists);
    if (gettext(allocator, "Programmed in Zig by")) |txt| {
        authors = [_:0][*c]const u8{"Andrew Kelley and contributors"};
        defer allocator.free(txt);
        dlg.add_credit_section(txt, &authors);
    }
    if (gettext(allocator, "Using Zigmod by")) |txt| {
        authors = [_:0][*c]const u8{"Nektro and contributors"};
        defer allocator.free(txt);
        dlg.add_credit_section(txt, &authors);
    }
    if (gettext(allocator, "Using Zig-clap by")) |txt| {
        authors = [_:0][*c]const u8{"Komari Spaghetti and contributors"};
        defer allocator.free(txt);
        dlg.add_credit_section(txt, &authors);
    }
    if (gettext(allocator, "Using Zig-nestedtext by")) |txt| {
        authors = [_:0][*c]const u8{"Lewis Gaul and contributors"};
        defer allocator.free(txt);
        dlg.add_credit_section(txt, &authors);
    }
    if (gettext(allocator, "Using known-folders by")) |txt| {
        authors = [_:0][*c]const u8{"the Ziglibs organization"};
        defer allocator.free(txt);
        dlg.add_credit_section(txt, &authors);
    }
    if (gettext(allocator, "Using Zig-vte by")) |txt| {
        authors = [_:0][*c]const u8{"Nathan Fisher"};
        defer allocator.free(txt);
        dlg.add_credit_section(txt, &authors);
    }
    dlg.set_logo_icon_name("zterm");
}

const license =
    \\The MIT License (MIT)
    \\Copyright © 2021 Nathan Fisher <jeang3nie@hitchhiker-linux.org>
    \\
    \\Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    \\
    \\The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    \\
    \\THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
;
