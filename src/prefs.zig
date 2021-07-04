const std = @import("std");
const config = @import("config.zig");
usingnamespace @import("vte");
const allocator = std.heap.page_allocator;
const fmt = std.fmt;
const mem = std.mem;
const meta = std.meta;
const stderr = std.io.getStdErr().writer();
const stdout = std.io.getStdOut().writer();

var widgets: PrefWidgets = undefined;
var conf = config.Config.default();

pub const ColorButtons = struct {
    text_color: gtk.ColorButton,
    background_color: gtk.ColorButton,
    black_color: gtk.ColorButton,
    red_color: gtk.ColorButton,
    green_color: gtk.ColorButton,
    brown_color: gtk.ColorButton,
    blue_color: gtk.ColorButton,
    magenta_color: gtk.ColorButton,
    cyan_color: gtk.ColorButton,
    light_grey_color: gtk.ColorButton,
    dark_grey_color: gtk.ColorButton,
    light_red_color: gtk.ColorButton,
    light_green_color: gtk.ColorButton,
    yellow_color: gtk.ColorButton,
    light_blue_color: gtk.ColorButton,
    light_magenta_color: gtk.ColorButton,
    light_cyan_color: gtk.ColorButton,
    white_color: gtk.ColorButton,

    fn init(builder: gtk.Builder) ?ColorButtons {
        //var buttons: ColorButtons = undefined;
        //inline for (meta.fields(ColorButtons)) |color| {
        //    const color_name = fmt.allocPrintZ(allocator, "{s}", .{color.name}) catch return null;
        //    defer allocator.free(color_name);
        //    if (builder.get_widget(color_name)) |widget| {
        //        if (widget.to_color_button()) |b| {
        //            @field(buttons, color.name) = b;
        //        } else return null;
        //    } else return null;
        //}
        //return buttons;
        return ColorButtons{
            .text_color = builder.get_widget("text_color").?.to_color_button().?,
            .background_color = builder.get_widget("background_color").?.to_color_button().?,
            .black_color = builder.get_widget("black_color").?.to_color_button().?,
            .red_color = builder.get_widget("red_color").?.to_color_button().?,
            .green_color = builder.get_widget("green_color").?.to_color_button().?,
            .brown_color = builder.get_widget("brown_color").?.to_color_button().?,
            .blue_color = builder.get_widget("blue_color").?.to_color_button().?,
            .magenta_color = builder.get_widget("magenta_color").?.to_color_button().?,
            .cyan_color = builder.get_widget("cyan_color").?.to_color_button().?,
            .light_grey_color = builder.get_widget("light_grey_color").?.to_color_button().?,
            .dark_grey_color = builder.get_widget("dark_grey_color").?.to_color_button().?,
            .light_red_color = builder.get_widget("light_red_color").?.to_color_button().?,
            .light_green_color = builder.get_widget("light_green_color").?.to_color_button().?,
            .yellow_color = builder.get_widget("yellow_color").?.to_color_button().?,
            .light_blue_color = builder.get_widget("light_blue_color").?.to_color_button().?,
            .light_magenta_color = builder.get_widget("light_magenta_color").?.to_color_button().?,
            .light_cyan_color = builder.get_widget("light_cyan_color").?.to_color_button().?,
            .white_color = builder.get_widget("white_color").?.to_color_button().?,
        };
    }

    fn get_colors(self: ColorButtons) config.Colors {
        var colors = config.Colors.default();
        inline for (meta.fields(config.Colors)) |color| {
            const button = @field(self, color.name);
            const value = config.RGBColor.from_widget(button);
            @field(colors, color.name) = value;
        }
        return colors;
    }

    fn set_colors(self: ColorButtons) void {
        const colors = conf.colors;
        inline for (meta.fields(config.Colors)) |color| {
            const button = @field(self, color.name);
            const rgb = @field(colors, color.name);
            const gdk_rgba = rgb.to_gdk();
            button.as_color_chooser().set_rgba(gdk_rgba);
        }
    }
};

pub const PrefWidgets = struct {
    window: gtk.Window,
    initial_title_entry: gtk.Entry,
    dynamic_title_combobox: *c.GtkWidget,
    custom_command_checkbutton: *c.GtkWidget,
    custom_command_label: *c.GtkWidget,
    custom_command_entry: *c.GtkWidget,
    cursor_style_combobox: *c.GtkWidget,
    cursor_blinks_checkbutton: *c.GtkWidget,
    infinite_scrollback_checkbutton: *c.GtkWidget,
    scrollback_lines_label: *c.GtkWidget,
    scrollback_lines_spinbox: *c.GtkWidget,
    scrollback_lines_adjustment: *c.GtkAdjustment,
    system_font_checkbutton: *c.GtkWidget,
    font_chooser_button: *c.GtkWidget,
    background_style_combobox: *c.GtkWidget,
    background_image_grid: *c.GtkWidget,
    background_image_file_button: *c.GtkWidget,
    background_image_style_combobox: *c.GtkWidget,
    background_style_opacity_box: *c.GtkWidget,
    background_style_opacity_scale: *c.GtkWidget,
    background_opacity_adjustment: *c.GtkAdjustment,
    close_button: gtk.Button,
    color_buttons: ColorButtons,

    fn init(builder: gtk.Builder) PrefWidgets {
        return PrefWidgets{
            .window = builder.get_widget("window").?.to_window().?,
            .initial_title_entry = builder.get_widget("initial_title_entry").?.to_entry().?,
            .dynamic_title_combobox = builder.get_widget("dynamic_title_combobox").?.ptr,
            .custom_command_checkbutton = builder.get_widget("custom_command_checkbutton").?.ptr,
            .custom_command_label = builder.get_widget("custom_command_label").?.ptr,
            .custom_command_entry = builder.get_widget("custom_command_entry").?.ptr,
            .cursor_style_combobox = builder.get_widget("cursor_style_combobox").?.ptr,
            .cursor_blinks_checkbutton = builder.get_widget("cursor_blinks_checkbutton").?.ptr,
            .infinite_scrollback_checkbutton = builder.get_widget("infinite_scrollback_checkbutton").?.ptr,
            .scrollback_lines_label = builder.get_widget("scrollback_lines_label").?.ptr,
            .scrollback_lines_spinbox = builder.get_widget("scrollback_lines_spinbox").?.ptr,
            .scrollback_lines_adjustment = builder.get_adjustment("scollback_lines_adjustment").?.ptr,
            .system_font_checkbutton = builder.get_widget("system_font_checkbutton").?.ptr,
            .font_chooser_button = builder.get_widget("font_chooser_button").?.ptr,
            .background_style_combobox = builder.get_widget("background_style_combobox").?.ptr,
            .background_image_grid = builder.get_widget("background_image_grid").?.ptr,
            .background_image_file_button = builder.get_widget("background_image_file_button").?.ptr,
            .background_image_style_combobox = builder.get_widget("background_image_style_combobox").?.ptr,
            .background_style_opacity_box = builder.get_widget("background_style_opacity_box").?.ptr,
            .background_style_opacity_scale = builder.get_widget("background_style_opacity_scale").?.ptr,
            .background_opacity_adjustment = builder.get_adjustment("background_opacity_adjustment").?.ptr,
            .close_button = builder.get_widget("close_button").?.to_button().?,
            .color_buttons = ColorButtons.init(builder).?,
        };
    }

    fn set_initial_title(self: PrefWidgets) void {
        const buf = self.initial_title_entry.get_buffer();
        const title = fmt.allocPrintZ(allocator, "{s}", .{conf.initial_title}) catch return;
        defer allocator.free(title);
        buf.set_text(title, -1);
    }

    fn get_title_style(self: PrefWidgets) config.DynamicTitleStyle {
        const id = c.gtk_combo_box_get_active_id(@ptrCast(*c.GtkComboBox, self.dynamic_title_combobox));
        const style = config.parse_enum(config.DynamicTitleStyle, id).?;
        return style;
    }

    fn set_title_style(self: PrefWidgets) void {
        const box = @ptrCast(*c.GtkComboBox, self.dynamic_title_combobox);
        switch (conf.dynamic_title_style) {
            .replaces_title => _ = c.gtk_combo_box_set_active_id(box, "replaces_title"),
            .before_title => _ = c.gtk_combo_box_set_active_id(box, "before_title"),
            .after_title => _ = c.gtk_combo_box_set_active_id(box, "after_title"),
            .not_displayed => _ = c.gtk_combo_box_set_active_id(box, "not_displayed"),
        }
    }

    fn get_custom_command(self: PrefWidgets) config.CustomCommand {
        const is_custom = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, self.custom_command_checkbutton));
        if (is_custom) {
            const val = c.gtk_entry_get_text(@ptrCast(*c.GtkEntry, self.custom_command_entry));
            const cmd = fmt.allocPrint(allocator, "{s}", .{val}) catch |e| {
                stderr.print("{s}\n", .{e}) catch {};
                return .none;
            };
            return config.CustomCommand{ .command = cmd };
        } else {
            return .none;
        }
    }

    fn set_custom_command(self: PrefWidgets) void {
        const command = conf.custom_command;
        const toggle = @ptrCast(*c.GtkToggleButton, self.custom_command_checkbutton);
        const entry = @ptrCast(*c.GtkEntry, self.custom_command_entry);
        const buf = c.gtk_entry_get_buffer(entry);
        switch (command) {
            .command => |val| {
                c.gtk_toggle_button_set_active(toggle, 1);
                c.gtk_widget_set_sensitive(self.custom_command_entry, 1);
                c.gtk_widget_set_sensitive(self.custom_command_label, 1);
                const cmd = fmt.allocPrintZ(allocator, "{s}", .{val}) catch |e| {
                    stderr.print("{s}\n", .{e}) catch {};
                    return;
                };
                defer allocator.free(cmd);
                c.gtk_entry_buffer_set_text(buf, cmd, -1);
            },
            .none => {
                c.gtk_toggle_button_set_active(toggle, 0);
                c.gtk_widget_set_sensitive(self.custom_command_entry, 0);
                c.gtk_widget_set_sensitive(self.custom_command_label, 0);
            },
        }
    }

    fn get_scrollback(self: PrefWidgets) config.Scrollback {
        const toggle = @ptrCast(*c.GtkToggleButton, self.infinite_scrollback_checkbutton);
        const spin = @ptrCast(*c.GtkSpinButton, self.scrollback_lines_spinbox);
        const is_infinite = gtk.toggle_button_get_active(toggle);
        if (is_infinite) {
            return config.Scrollback.infinite;
        } else {
            const val = c.gtk_spin_button_get_value(spin);
            return config.Scrollback{ .finite = val };
        }
    }

    fn set_scrollback(self: PrefWidgets) void {
        const scrollback = conf.scrollback;
        const toggle = @ptrCast(*c.GtkToggleButton, self.infinite_scrollback_checkbutton);
        switch (scrollback) {
            .infinite => {
                c.gtk_toggle_button_set_active(toggle, 1);
                c.gtk_widget_set_sensitive(self.scrollback_lines_spinbox, 0);
            },
            .finite => |value| {
                c.gtk_toggle_button_set_active(toggle, 0);
                c.gtk_widget_set_sensitive(self.scrollback_lines_spinbox, 1);
                c.gtk_adjustment_set_value(self.scrollback_lines_adjustment, value);
            },
        }
    }

    fn get_font(self: PrefWidgets) config.Font {
        const toggle = @ptrCast(*c.GtkToggleButton, self.system_font_checkbutton);
        const chooser = @ptrCast(*c.GtkFontChooser, self.font_chooser_button);
        if (gtk.toggle_button_get_active(toggle)) {
            return .system;
        } else {
            const val = c.gtk_font_chooser_get_font(chooser);
            const font = fmt.allocPrintZ(allocator, "{s}", .{val}) catch |e| {
                stderr.print("{s}\n", .{e}) catch {};
                return .system;
            };
            return config.Font{ .custom = font };
        }
    }

    fn set_font(self: PrefWidgets) void {
        const toggle = @ptrCast(*c.GtkToggleButton, self.system_font_checkbutton);
        const chooser = @ptrCast(*c.GtkFontChooser, self.font_chooser_button);
        const font = conf.font;
        switch (font) {
            .system => {
                c.gtk_toggle_button_set_active(toggle, 1);
                c.gtk_widget_set_sensitive(self.font_chooser_button, 0);
            },
            .custom => |val| {
                const fontname = fmt.allocPrintZ(allocator, "{s}", .{val}) catch |e| {
                    stderr.print("{s}\n", .{e}) catch {};
                    c.gtk_toggle_button_set_active(toggle, 1);
                    c.gtk_widget_set_sensitive(self.font_chooser_button, 0);
                    return;
                };
                defer allocator.free(fontname);
                c.gtk_toggle_button_set_active(toggle, 0);
                c.gtk_widget_set_sensitive(self.font_chooser_button, 1);
                c.gtk_font_chooser_set_font(chooser, fontname);
            },
        }
    }

    fn get_background_style(self: PrefWidgets) config.BackgroundStyle {
        const box = @ptrCast(*c.GtkComboBox, self.background_style_combobox);
        const id = c.gtk_combo_box_get_active_id(box);
        const style = config.parse_enum(config.BackgroundStyle, id).?;
        return style;
    }

    fn get_image_style(self: PrefWidgets) config.ImageStyle {
        const box = @ptrCast(*c.GtkComboBox, self.background_image_style_combobox);
        const id = c.gtk_combo_box_get_active_id(box);
        const style = config.parse_enum(config.ImageStyle, id).?;
        return style;
    }

    fn set_image_style(self: PrefWidgets, image: config.BackgroundImage) void {
        const style = image.style;
        const box = @ptrCast(*c.GtkComboBox, self.background_image_style_combobox);
        switch (style) {
            .tiled => _ = c.gtk_combo_box_set_active_id(box, "tiled"),
            .centered => _ = c.gtk_combo_box_set_active_id(box, "centered"),
            .scaled => _ = c.gtk_combo_box_set_active_id(box, "scaled"),
            .stretched => _ = c.gtk_combo_box_set_active_id(box, "stretched"),
        }
    }

    fn get_background_image(self: PrefWidgets) ?config.BackgroundImage {
        const button = @ptrCast(*c.GtkFileChooser, self.background_image_file_button);
        const val = c.gtk_file_chooser_get_filename(button);
        if (val == null) {
            return null;
        }
        const len = mem.len(val);
        const style = self.get_image_style();
        return config.BackgroundImage{
            .file = val[0..len],
            .style = style,
        };
    }

    fn set_background_image(self: PrefWidgets, image: config.BackgroundImage) void {
        // stub
        const button = @ptrCast(*c.GtkFileChooser, self.background_image_file_button);
        const file = fmt.allocPrintZ(allocator, "{s}", .{image.file}) catch |e| {
            stderr.print("{s}\n", .{e}) catch {};
            return;
        };
        defer allocator.free(file);
        _ = c.gtk_file_chooser_set_filename(button, file);
        self.set_image_style(image);
    }

    fn get_background(self: PrefWidgets) config.Background {
        const style = self.get_background_style();
        switch (style) {
            .solid_color => {
                return config.Background.solid_color;
            },
            .image => {
                if (self.get_background_image()) |img| {
                    return config.Background{ .image = img };
                } else {
                    return config.Background.default();
                }
            },
            .transparent => {
                const val = c.gtk_range_get_value(@ptrCast(*c.GtkRange, self.background_style_opacity_scale));
                return config.Background{ .transparent = val };
            },
        }
    }

    fn set_transparency(self: PrefWidgets, percent: f64) void {
        c.gtk_adjustment_set_value(self.background_opacity_adjustment, percent);
    }

    fn set_background(self: PrefWidgets) void {
        const bg = conf.background;
        switch (bg) {
            .solid_color => {
                c.gtk_widget_hide(self.background_image_grid);
                c.gtk_widget_hide(self.background_style_opacity_box);
                _ = c.gtk_combo_box_set_active_id(
                    @ptrCast(*c.GtkComboBox, self.background_style_combobox),
                    "solid_color",
                );
            },
            .image => |img| {
                c.gtk_widget_show_all(self.background_image_grid);
                c.gtk_widget_hide(self.background_style_opacity_box);
                _ = c.gtk_combo_box_set_active_id(
                    @ptrCast(*c.GtkComboBox, self.background_style_combobox),
                    "image",
                );
                self.set_background_image(img);
            },
            .transparent => |percent| {
                c.gtk_widget_hide(self.background_image_grid);
                c.gtk_widget_show_all(self.background_style_opacity_box);
                _ = c.gtk_combo_box_set_active_id(
                    @ptrCast(*c.GtkComboBox, self.background_style_combobox),
                    "transparent",
                );
                self.set_transparency(percent);
            },
        }
    }

    fn get_cursor_style(self: PrefWidgets) config.CursorStyle {
        const id = c.gtk_combo_box_get_active_id(@ptrCast(*c.GtkComboBox, self.cursor_style_combobox));
        const style = config.parse_enum(config.CursorStyle, id).?;
        return style;
    }

    fn get_cursor(self: PrefWidgets) config.Cursor {
        const style = self.get_cursor_style();
        const blinks = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, self.cursor_blinks_checkbutton));
        return config.Cursor{
            .cursor_style = style,
            .cursor_blinks = blinks,
        };
    }

    fn set_cursor(self: PrefWidgets) void {
        if (conf.cursor.cursor_blinks) {
            c.gtk_toggle_button_set_active(@ptrCast(*c.GtkToggleButton, self.cursor_blinks_checkbutton), 1);
        } else {
            c.gtk_toggle_button_set_active(@ptrCast(*c.GtkToggleButton, self.cursor_blinks_checkbutton), 0);
        }
        const box = @ptrCast(*c.GtkComboBox, self.cursor_style_combobox);
        switch (conf.cursor.cursor_style) {
            .block => _ = c.gtk_combo_box_set_active_id(box, "block"),
            .ibeam => _ = c.gtk_combo_box_set_active_id(box, "ibeam"),
            .underline => _ = c.gtk_combo_box_set_active_id(box, "underline"),
        }
    }

    fn get_config(self: PrefWidgets) config.Config {
        return config.Config{
            .initial_title = if (self.initial_title_entry.get_text(allocator)) |t| t else "Zterm",
            .dynamic_title_style = self.get_title_style(),
            .custom_command = self.get_custom_command(),
            .scrollback = self.get_scrollback(),
            .font = self.get_font(),
            .background = self.get_background(),
            .colors = self.color_buttons.get_colors(),
            .cursor = self.get_cursor(),
        };
    }

    fn set_values(self: PrefWidgets) void {
        self.set_initial_title();
        self.set_title_style();
        self.set_custom_command();
        self.set_scrollback();
        self.set_background();
        self.color_buttons.set_colors();
        self.set_font();
        self.set_cursor();
    }
};

pub fn run(data: config.Config) ?config.Config {
    const builder = gtk.Builder.new();
    conf = data;
    builder.add_from_string(@embedFile("prefs.glade")) catch |e| {
        stderr.print("{s}\n", .{e}) catch {};
        return null;
    };
    widgets = PrefWidgets.init(builder);
    widgets.set_values();

    _ = gtk.signal_connect(
        widgets.custom_command_checkbutton,
        "toggled",
        @ptrCast(c.GCallback, toggle_custom_command),
        null,
    );

    _ = gtk.signal_connect(
        widgets.infinite_scrollback_checkbutton,
        "toggled",
        @ptrCast(c.GCallback, toggle_scrollback),
        null,
    );

    _ = gtk.signal_connect(
        widgets.system_font_checkbutton,
        "toggled",
        @ptrCast(c.GCallback, toggle_font),
        null,
    );

    _ = gtk.signal_connect(
        widgets.background_style_combobox,
        "changed",
        @ptrCast(c.GCallback, toggle_background),
        null,
    );

    widgets.close_button.connect_clicked(@ptrCast(c.GCallback, save_and_close), null);

    const res = c.gtk_dialog_run(@ptrCast(*c.GtkDialog, widgets.window.ptr));
    if (res == -1) {
        return conf;
    } else {
        widgets.window.close();
        widgets.window.as_widget().destroy();
        return null;
    }
}

fn toggle_custom_command(custom_command_checkbutton: *c.GtkCheckButton) void {
    const state = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, custom_command_checkbutton));
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, widgets.custom_command_entry), state);
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, widgets.custom_command_label), state);
}

fn toggle_scrollback(infinite_scrollback_checkbutton: *c.GtkCheckButton) void {
    const state = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, infinite_scrollback_checkbutton));
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, widgets.scrollback_lines_label), !state);
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, widgets.scrollback_lines_spinbox), !state);
}

fn toggle_font(system_font_checkbutton: *c.GtkCheckButton) void {
    const state = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, system_font_checkbutton));
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, widgets.font_chooser_button), !state);
}

fn toggle_background(background_combobox: *c.GtkComboBox) void {
    const id = c.gtk_combo_box_get_active_id(@ptrCast(*c.GtkComboBox, background_combobox));
    const style = config.parse_enum(config.BackgroundStyle, id).?;
    switch (style) {
        .solid_color => {
            gtk.widget_set_visible(widgets.background_image_grid, false);
            gtk.widget_set_visible(widgets.background_style_opacity_box, false);
        },
        .image => {
            gtk.widget_set_visible(widgets.background_image_grid, true);
            gtk.widget_set_visible(widgets.background_style_opacity_box, false);
        },
        .transparent => {
            gtk.widget_set_visible(widgets.background_image_grid, false);
            gtk.widget_set_visible(widgets.background_style_opacity_box, true);
        },
    }
}

fn save_and_close() void {
    conf = widgets.get_config();
    widgets.window.close();
    widgets.window.as_widget().destroy();
}
