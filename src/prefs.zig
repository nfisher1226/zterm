const std = @import("std");
const config = @import("config.zig");
const gradient = @import("gradient.zig");
const version = @import("version.zig").version;
const VTE = @import("vte");
const c = VTE.c;
const gtk = VTE.gtk;
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

    const Self = @This();

    fn init(builder: gtk.Builder) ?Self {
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
        return Self{
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

    fn getColors(self: Self) config.Colors {
        var colors = config.Colors.default();
        inline for (meta.fields(config.Colors)) |color| {
            const button = @field(self, color.name);
            const value = config.RGB.fromButton(button);
            @field(colors, color.name) = value;
        }
        return colors;
    }

    fn setColors(self: Self) void {
        const colors = conf.colors;
        inline for (meta.fields(config.Colors)) |color| {
            const button = @field(self, color.name);
            const rgb = @field(colors, color.name);
            const gdk_rgba = rgb.toGdk();
            button.as_color_chooser().set_rgba(gdk_rgba);
        }
    }
};

pub const PrefWidgets = struct {
    window: gtk.Window,
    initial_title_entry: gtk.Entry,
    dynamic_title_combobox: gtk.ComboBox,
    custom_command_checkbutton: gtk.CheckButton,
    custom_command_label: gtk.Widget,
    custom_command_entry: gtk.Entry,
    cursor_style_combobox: gtk.ComboBox,
    cursor_blinks_checkbutton: gtk.CheckButton,
    infinite_scrollback_checkbutton: gtk.CheckButton,
    scrollback_lines_label: gtk.Widget,
    scrollback_lines_spinbox: gtk.SpinButton,
    system_font_checkbutton: gtk.CheckButton,
    font_chooser_button: *c.GtkWidget,
    background_style_combobox: gtk.ComboBox,
    background_image_grid: gtk.Widget,
    background_image_file_button: *c.GtkWidget,
    background_image_style_combobox: gtk.ComboBox,
    background_style_opacity_box: gtk.Widget,
    background_style_opacity_scale: gtk.Scale,
    close_button: gtk.Button,
    color_buttons: ColorButtons,
    gradient_editor: gradient.GradientEditor,

    const Self = @This();

    fn init(builder: gtk.Builder) Self {
        return Self{
            .window = builder.get_widget("window").?.to_window().?,
            .initial_title_entry = builder
                .get_widget("initial_title_entry").?.to_entry().?,
            .dynamic_title_combobox = builder
                .get_widget("dynamic_title_combobox").?.to_combo_box().?,
            .custom_command_checkbutton = builder
                .get_widget("custom_command_checkbutton").?.to_check_button().?,
            .custom_command_label = builder.get_widget("custom_command_label").?,
            .custom_command_entry = builder
                .get_widget("custom_command_entry").?.to_entry().?,
            .cursor_style_combobox = builder
                .get_widget("cursor_style_combobox").?.to_combo_box().?,
            .cursor_blinks_checkbutton = builder
                .get_widget("cursor_blinks_checkbutton").?.to_check_button().?,
            .infinite_scrollback_checkbutton = builder
                .get_widget("infinite_scrollback_checkbutton").?.to_check_button().?,
            .scrollback_lines_label = builder
                .get_widget("scrollback_lines_label").?,
            .scrollback_lines_spinbox = builder
                .get_widget("scrollback_lines_spinbox").?.to_spin_button().?,
            .system_font_checkbutton = builder
                .get_widget("system_font_checkbutton").?.to_check_button().?,
            .font_chooser_button = builder.get_widget("font_chooser_button").?.ptr,
            .background_style_combobox = builder
                .get_widget("background_style_combobox").?.to_combo_box().?,
            .background_image_grid = builder.get_widget("background_image_grid").?,
            .background_image_file_button = builder
                .get_widget("background_image_file_button").?.ptr,
            .background_image_style_combobox = builder
                .get_widget("background_image_style_combobox").?.to_combo_box().?,
            .background_style_opacity_box = builder
                .get_widget("background_style_opacity_box").?,
            .background_style_opacity_scale = builder
                .get_widget("background_style_opacity_scale").?.to_scale().?,
            .close_button = builder.get_widget("close_button").?.to_button().?,
            .color_buttons = ColorButtons.init(builder).?,
            .gradient_editor = gradient.GradientEditor.init(builder).?,
        };
    }

    fn setWindowTitle(self: Self) void {
        self.window.set_title("Zterm-" ++ version ++ " ~ Preferences");
    }

    fn setInitialTitle(self: Self) void {
        const buf = self.initial_title_entry.get_buffer();
        const title = fmt.allocPrintZ(allocator, "{s}", .{conf.initial_title}) catch return;
        defer allocator.free(title);
        buf.set_text(title, -1);
    }

    fn getTitleStyle(self: Self) config.DynamicTitleStyle {
        return if (self.dynamic_title_combobox.get_active_id(allocator)) |id| blk: {
            break :blk if (config.parseEnum(config.DynamicTitleStyle, id)) |s|
                s else config.DynamicTitleStyle.default();
        } else config.DynamicTitleStyle.default();
    }

    fn setTitleStyle(self: Self) void {
        switch (conf.dynamic_title_style) {
            .replaces_title => _ = self.dynamic_title_combobox.set_active_id("replaces_title"),
            .before_title => _ = self.dynamic_title_combobox.set_active_id("before_title"),
            .after_title => _ = self.dynamic_title_combobox.set_active_id("after_title"),
            .not_displayed => _ = self.dynamic_title_combobox.set_active_id("not_displayed"),
        }
    }

    fn getCustomCommand(self: Self) config.CustomCommand {
        const is_custom = self.custom_command_checkbutton.as_toggle_button().get_active();
        if (is_custom) {
            const val = self.custom_command_entry.get_text(allocator);
            return if (val) |v| config.CustomCommand{ .command = v } else .none;
        } else {
            return .none;
        }
    }

    fn setCustomCommand(self: Self) void {
        const command = conf.custom_command;
        const buf = self.custom_command_entry.get_buffer();
        switch (command) {
            .command => |val| {
                self.custom_command_checkbutton.as_toggle_button().set_active(true);
                self.custom_command_entry.as_widget().set_sensitive(true);
                self.custom_command_label.set_sensitive(true);
                const cmd = fmt.allocPrintZ(allocator, "{s}", .{val}) catch |e| {
                    stderr.print("{s}\n", .{e}) catch {};
                    return;
                };
                defer allocator.free(cmd);
                buf.set_text(cmd, -1);
            },
            .none => {
                self.custom_command_checkbutton.as_toggle_button().set_active(false);
                self.custom_command_entry.as_widget().set_sensitive(false);
                self.custom_command_label.set_sensitive(false);
            },
        }
    }

    fn getScrollback(self: Self) config.Scrollback {
        const toggle = self.infinite_scrollback_checkbutton.as_toggle_button();
        if (toggle.get_active()) {
            return config.Scrollback.infinite;
        } else {
            const val = self.scrollback_lines_spinbox.get_value();
            return config.Scrollback{ .finite = val };
        }
    }

    fn setScrollback(self: Self) void {
        const scrollback = conf.scrollback;
        const toggle = self.infinite_scrollback_checkbutton.as_toggle_button();
        switch (scrollback) {
            .infinite => {
                toggle.set_active(true);
                self.scrollback_lines_spinbox.as_widget().set_sensitive(false);
            },
            .finite => |value| {
                toggle.set_active(false);
                self.scrollback_lines_spinbox.as_widget().set_sensitive(true);
                self.scrollback_lines_spinbox.set_value(value);
            },
        }
    }

    fn getFont(self: Self) config.Font {
        const toggle = self.system_font_checkbutton.as_toggle_button();
        const chooser = @ptrCast(*c.GtkFontChooser, self.font_chooser_button);
        if (toggle.get_active()) {
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

    fn setFont(self: Self) void {
        const toggle = self.system_font_checkbutton.as_toggle_button();
        const chooser = @ptrCast(*c.GtkFontChooser, self.font_chooser_button);
        const font = conf.font;
        switch (font) {
            .system => {
                toggle.set_active(true);
                c.gtk_widget_set_sensitive(self.font_chooser_button, 0);
            },
            .custom => |val| {
                const fontname = fmt.allocPrintZ(allocator, "{s}", .{val}) catch |e| {
                    stderr.print("{s}\n", .{e}) catch {};
                    toggle.set_active(true);
                    c.gtk_widget_set_sensitive(self.font_chooser_button, 0);
                    return;
                };
                defer allocator.free(fontname);
                toggle.set_active(false);
                c.gtk_widget_set_sensitive(self.font_chooser_button, 1);
                c.gtk_font_chooser_set_font(chooser, fontname);
            },
        }
    }

    fn getBackgroundStyle(self: Self) config.BackgroundStyle {
        return if (self.background_style_combobox.get_active_id(allocator)) |id| blk: {
            defer allocator.free(id);
            break :blk if (config.parseEnum(config.BackgroundStyle, id)) |s|
                s else config.BackgroundStyle.default();
        } else config.BackgroundStyle.default();
    }

    fn getImageStyle(self: PrefWidgets) config.ImageStyle {
        return if (self.background_image_style_combobox.get_active_id(allocator)) |id| blk: {
            defer allocator.free(id);
            break :blk if (config.parseEnum(config.ImageStyle, id)) |s|
                s else config.ImageStyle.default();
        } else config.ImageStyle.default();
    }

    fn setImageStyle(self: Self, image: config.BackgroundImage) void {
        const style = image.style;
        switch (style) {
            .tiled => _ = self.background_image_style_combobox.set_active_id("tiled"),
            .centered => _ = self.background_image_style_combobox.set_active_id("centered"),
            .scaled => _ = self.background_image_style_combobox.set_active_id("scaled"),
            .stretched => _ = self.background_image_style_combobox.set_active_id("stretched"),
        }
    }

    fn getBackgroundImage(self: Self) ?config.BackgroundImage {
        const button = @ptrCast(*c.GtkFileChooser, self.background_image_file_button);
        const val = c.gtk_file_chooser_get_filename(button);
        if (val == null) {
            return null;
        }
        const len = mem.len(val);
        const style = self.getImageStyle();
        return config.BackgroundImage{
            .file = val[0..len],
            .style = style,
        };
    }

    fn setBackgroundImage(self: Self, image: config.BackgroundImage) void {
        // stub
        const button = @ptrCast(*c.GtkFileChooser, self.background_image_file_button);
        const file = fmt.allocPrintZ(allocator, "{s}", .{image.file}) catch |e| {
            stderr.print("{s}\n", .{e}) catch {};
            return;
        };
        defer allocator.free(file);
        _ = c.gtk_file_chooser_set_filename(button, file);
        self.setImageStyle(image);
    }

    fn getBackground(self: Self) config.Background {
        const style = self.getBackgroundStyle();
        switch (style) {
            .solid_color => {
                return config.Background.solid_color;
            },
            .image => {
                if (self.getBackgroundImage()) |img| {
                    return config.Background{ .image = img };
                } else {
                    return config.Background.default();
                }
            },
            .transparent => {
                const val = self.background_style_opacity_scale.as_range().get_value();
                return config.Background{ .transparent = val };
            },
            .gradient => return config.Background.gradient,
        }
    }

    fn setTransparency(self: Self, percent: f64) void {
        self.background_style_opacity_scale.as_range().set_value(percent);
    }

    fn setBackground(self: Self) void {
        const bg = conf.background;
        switch (bg) {
            .solid_color => {
                self.background_image_grid.hide();
                self.background_style_opacity_box.hide();
                self.gradient_editor.editor.hide();
                self.background_style_combobox.set_active_id("solid_color");
            },
            .image => |img| {
                self.background_image_grid.show_all();
                self.background_style_opacity_box.hide();
                self.gradient_editor.editor.hide();
                self.background_style_combobox.set_active_id("image");
                self.setBackgroundImage(img);
            },
            .transparent => |percent| {
                self.background_image_grid.hide();
                self.background_style_opacity_box.show_all();
                self.gradient_editor.editor.hide();
                self.background_style_combobox.set_active_id("transparent");
                self.setTransparency(percent);
            },
            .gradient => {
                self.background_image_grid.hide();
                self.background_style_opacity_box.hide();
                self.gradient_editor.editor.show();
                self.background_style_combobox.set_active_id("gradient");
            },
        }
    }

    fn getCursorStyle(self: Self) config.CursorStyle {
        if (self.cursor_style_combobox.get_active_id(allocator)) |id| {
            return if (config.parseEnum(config.CursorStyle, id)) |s|
                s else config.CursorStyle.default();
        } else return config.CursorStyle.default();
    }

    fn getCursor(self: Self) config.Cursor {
        const style = self.getCursorStyle();
        const blinks = self.cursor_blinks_checkbutton.as_toggle_button().get_active();
        return config.Cursor{
            .style = style,
            .blinks = blinks,
        };
    }

    fn setCursor(self: Self) void {
        if (conf.cursor.blinks) {
            self.cursor_blinks_checkbutton.as_toggle_button().set_active(true);
        } else {
            self.cursor_blinks_checkbutton.as_toggle_button().set_active(false);
        }
        switch (conf.cursor.style) {
            .block => _ = self.cursor_style_combobox.set_active_id("block"),
            .ibeam => _ = self.cursor_style_combobox.set_active_id("ibeam"),
            .underline => _ = self.cursor_style_combobox.set_active_id("underline"),
        }
    }

    fn getConfig(self: Self) config.Config {
        return config.Config{
            .initial_title = if (self.initial_title_entry.get_text(allocator)) |t| t else "Zterm",
            .dynamic_title_style = self.getTitleStyle(),
            .custom_command = self.getCustomCommand(),
            .scrollback = self.getScrollback(),
            .font = self.getFont(),
            .background = self.getBackground(),
            .colors = self.color_buttons.getColors(),
            .cursor = self.getCursor(),
        };
    }

    fn setValues(self: Self) void {
        self.setWindowTitle();
        self.setInitialTitle();
        self.setTitleStyle();
        self.setCustomCommand();
        self.setScrollback();
        self.setBackground();
        self.color_buttons.setColors();
        self.setFont();
        self.setCursor();
    }

    fn connectSignals(self: Self) void {
        const Callbacks = struct {
            fn toggleCustomCommand(custom_command_checkbutton: *c.GtkCheckButton) void {
                const state = gtk.toggle_button_get_active(
                    @ptrCast(*c.GtkToggleButton, custom_command_checkbutton));
                widgets.custom_command_entry.as_widget().set_sensitive(state);
                widgets.custom_command_label.set_sensitive(state);
            }

            fn toggleScrollback(infinite_scrollback_checkbutton: *c.GtkCheckButton) void {
                const state = gtk.toggle_button_get_active(
                    @ptrCast(*c.GtkToggleButton, infinite_scrollback_checkbutton));
                widgets.scrollback_lines_label.set_sensitive(!state);
                widgets.scrollback_lines_spinbox.as_widget().set_sensitive(!state);
            }

            fn toggleFont(system_font_checkbutton: *c.GtkCheckButton) void {
                const state = gtk.toggle_button_get_active(
                    @ptrCast(*c.GtkToggleButton, system_font_checkbutton));
                gtk.widget_set_sensitive(
                    @ptrCast(*c.GtkWidget, widgets.font_chooser_button), !state);
            }

            fn toggleBackground(background_combobox: *c.GtkComboBox) void {
                const id = c.gtk_combo_box_get_active_id(@ptrCast(*c.GtkComboBox, background_combobox));
                const style = config.parseEnum(config.BackgroundStyle, id).?;
                switch (style) {
                    .solid_color => {
                        widgets.background_image_grid.set_visible(false);
                        widgets.background_style_opacity_box.set_visible(false);
                        widgets.gradient_editor.editor.set_visible(false);
                    },
                    .image => {
                        widgets.background_image_grid.set_visible(true);
                        widgets.background_style_opacity_box.set_visible(false);
                        widgets.gradient_editor.editor.set_visible(false);
                    },
                    .transparent => {
                        widgets.background_image_grid.set_visible(false);
                        widgets.background_style_opacity_box.set_visible(true);
                        widgets.gradient_editor.editor.set_visible(false);
                    },
                    .gradient => {
                        widgets.background_image_grid.set_visible(false);
                        widgets.background_style_opacity_box.set_visible(false);
                        widgets.gradient_editor.editor.set_visible(true);
                    },
                }
            }
        };

        self.custom_command_checkbutton.as_toggle_button().connect_toggled(
            @ptrCast(c.GCallback, Callbacks.toggleCustomCommand),
            null,
        );

        self.infinite_scrollback_checkbutton.as_toggle_button().connect_toggled(
            @ptrCast(c.GCallback, Callbacks.toggleScrollback),
            null,
        );

        self.system_font_checkbutton.as_toggle_button().connect_toggled(
            @ptrCast(c.GCallback, Callbacks.toggleFont),
            null,
        );

        self.background_style_combobox.connect_changed(
            @ptrCast(c.GCallback, Callbacks.toggleBackground),
            null,
        );
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
    widgets.setValues();
    widgets.connectSignals();

    widgets.close_button.connect_clicked(@ptrCast(c.GCallback, saveAndClose), null);

    const res = c.gtk_dialog_run(@ptrCast(*c.GtkDialog, widgets.window.ptr));
    if (res == -1) {
        return conf;
    } else {
        widgets.window.close();
        widgets.window.as_widget().destroy();
        return null;
    }
}

fn saveAndClose() void {
    conf = widgets.getConfig();
    widgets.window.close();
    widgets.window.as_widget().destroy();
}
