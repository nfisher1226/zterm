const std = @import("std");
const config = @import("config.zig");
const gtk = @import("gtk.zig");
const allocator = std.heap.page_allocator;
const c = gtk.c;
const fmt = std.fmt;
const mem = std.mem;
const meta = std.meta;
const stderr = std.io.getStdErr().writer();
const stdout = std.io.getStdOut().writer();

var builder: *c.GtkBuilder = undefined;
var widgets: PrefWidgets = undefined;
var conf: config.Config = undefined;

pub const PrefWidgets = struct {
    window: *c.GtkWidget,
    initial_title_entry: *c.GtkWidget,
    dynamic_title_combobox: *c.GtkWidget,
    custom_command_checkbutton: *c.GtkWidget,
    custom_command_label: *c.GtkWidget,
    custom_command_entry: *c.GtkWidget,
    cursor_style_combobox: *c.GtkWidget,
    cursor_blinks_checkbutton: *c.GtkWidget,
    infinite_scrollback_checkbutton: *c.GtkWidget,
    scrollback_lines_label: *c.GtkWidget,
    scrollback_lines_spinbox: *c.GtkWidget,
    text_color: *c.GtkWidget,
    background_color: *c.GtkWidget,
    black_color: *c.GtkWidget,
    red_color: *c.GtkWidget,
    green_color: *c.GtkWidget,
    brown_color: *c.GtkWidget,
    blue_color: *c.GtkWidget,
    magenta_color: *c.GtkWidget,
    cyan_color: *c.GtkWidget,
    light_grey_color: *c.GtkWidget,
    dark_grey_color: *c.GtkWidget,
    light_red_color: *c.GtkWidget,
    light_green_color: *c.GtkWidget,
    yellow_color: *c.GtkWidget,
    light_blue_color: *c.GtkWidget,
    light_magenta_color: *c.GtkWidget,
    light_cyan_color: *c.GtkWidget,
    white_color: *c.GtkWidget,
    system_font_checkbutton: *c.GtkWidget,
    font_chooser_button: *c.GtkWidget,
    background_style_combobox: *c.GtkWidget,
    background_image_grid: *c.GtkWidget,
    background_image_file_button: *c.GtkWidget,
    background_image_style_combobox: *c.GtkWidget,
    background_style_opacity_box: *c.GtkWidget,
    background_style_opacity_scale: *c.GtkWidget,
    close_button: *c.GtkWidget,

    fn init(b: *c.GtkBuilder) PrefWidgets {
        return PrefWidgets {
            .window = gtk.builder_get_widget(builder, "window").?,
            .initial_title_entry = gtk.builder_get_widget(builder, "initial_title_entry").?,
            .dynamic_title_combobox = gtk.builder_get_widget(builder, "dynamic_title_combobox").?,
            .custom_command_checkbutton = gtk.builder_get_widget(builder, "custom_command_checkbutton").?,
            .custom_command_label = gtk.builder_get_widget(builder, "custom_command_label").?,
            .custom_command_entry = gtk.builder_get_widget(builder, "custom_command_entry").?,
            .cursor_style_combobox = gtk.builder_get_widget(builder, "cursor_style_combobox").?,
            .cursor_blinks_checkbutton = gtk.builder_get_widget(builder, "cursor_blinks_checkbutton").?,
            .infinite_scrollback_checkbutton = gtk.builder_get_widget(builder, "infinite_scrollback_checkbutton").?,
            .scrollback_lines_label = gtk.builder_get_widget(builder, "scrollback_lines_label").?,
            .scrollback_lines_spinbox = gtk.builder_get_widget(builder, "scrollback_lines_spinbox").?,
            .text_color = gtk.builder_get_widget(builder, "text_color").?,
            .background_color = gtk.builder_get_widget(builder, "background_color").?,
            .black_color = gtk.builder_get_widget(builder, "black_color").?,
            .red_color = gtk.builder_get_widget(builder, "red_color").?,
            .green_color = gtk.builder_get_widget(builder, "green_color").?,
            .brown_color = gtk.builder_get_widget(builder, "brown_color").?,
            .blue_color = gtk.builder_get_widget(builder, "blue_color").?,
            .magenta_color = gtk.builder_get_widget(builder, "magenta_color").?,
            .cyan_color = gtk.builder_get_widget(builder, "cyan_color").?,
            .light_grey_color = gtk.builder_get_widget(builder, "light_grey_color").?,
            .dark_grey_color = gtk.builder_get_widget(builder, "dark_grey_color").?,
            .light_red_color = gtk.builder_get_widget(builder, "light_red_color").?,
            .light_green_color = gtk.builder_get_widget(builder, "light_green_color").?,
            .yellow_color = gtk.builder_get_widget(builder, "yellow_color").?,
            .light_blue_color = gtk.builder_get_widget(builder, "light_blue_color").?,
            .light_magenta_color = gtk.builder_get_widget(builder, "light_magenta_color").?,
            .light_cyan_color = gtk.builder_get_widget(builder, "light_cyan_color").?,
            .white_color = gtk.builder_get_widget(builder, "white_color").?,
            .system_font_checkbutton = gtk.builder_get_widget(builder, "system_font_checkbutton").?,
            .font_chooser_button = gtk.builder_get_widget(builder, "font_chooser_button").?,
            .background_style_combobox = gtk.builder_get_widget(builder, "background_style_combobox").?,
            .background_image_grid = gtk.builder_get_widget(builder, "background_image_grid").?,
            .background_image_file_button = gtk.builder_get_widget(builder, "background_image_file_button").?,
            .background_image_style_combobox = gtk.builder_get_widget(builder, "background_image_style_combobox").?,
            .background_style_opacity_box = gtk.builder_get_widget(builder, "background_style_opacity_box").?,
            .background_style_opacity_scale = gtk.builder_get_widget(builder, "background_style_opacity_scale").?,
            .close_button = gtk.builder_get_widget(builder, "close_button").?,
        };
    }

    fn get_initial_title(self: PrefWidgets) []const u8 {
        const val = c.gtk_entry_get_text(@ptrCast(*c.GtkEntry, self.initial_title_entry));
        const len = mem.len(val);
        return val[0..len];
    }

    fn get_title_style(self: PrefWidgets) config.DynamicTitleStyle {
        const id = c.gtk_combo_box_get_active_id(@ptrCast(*c.GtkComboBox, self.dynamic_title_combobox));
        const style = config.parse_enum(config.DynamicTitleStyle, id).?;
        return style;
    }

    fn get_custom_command(self: PrefWidgets) config.CustomCommand {
        const is_custom = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, self.custom_command_checkbutton));
        if (is_custom) {
            const val = c.gtk_entry_get_text(@ptrCast(*c.GtkEntry, self.custom_command_entry));
            const len = mem.len(val);
            return config.CustomCommand{ .command = val[0..len] };
        } else {
            return config.CustomCommand.none;
        }
    }

    fn get_scrollback(self: PrefWidgets) config.Scrollback {
        const is_infinite = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, self.infinite_scrollback_checkbutton));
        if (is_infinite) {
            return config.Scrollback.infinite;
        } else {
            const val = c.gtk_spin_button_get_value(@ptrCast(*c.GtkSpinButton, self.scrollback_lines_spinbox));
            return config.Scrollback{ .finite = val };
        }
    }

    fn get_font(self: PrefWidgets) config.Font {
        const is_system = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, self.system_font_checkbutton));
        if (is_system) {
            return config.Font.system;
        } else {
            const val = c.gtk_font_chooser_get_font(@ptrCast(*c.GtkFontChooser, self.font_chooser_button));
            const len = mem.len(val);
            return config.Font{ .custom = val[0..len] };
        }
    }

    fn get_background_style(self: PrefWidgets) config.BackgroundStyle {
        const id = c.gtk_combo_box_get_active_id(@ptrCast(*c.GtkComboBox, self.background_style_combobox));
        const style = config.parse_enum(config.BackgroundStyle, id).?;
        return style;
    }

    fn get_image_style(self: PrefWidgets) config.ImageStyle {
        const id = c.gtk_combo_box_get_active_id(@ptrCast(*c.GtkComboBox, self.background_image_style_combobox));
        const style = config.parse_enum(config.ImageStyle, id).?;
        return style;
    }

    fn get_background_image(self: PrefWidgets) ?config.BackgroundImage {
        const val = c.gtk_file_chooser_get_filename(@ptrCast(*c.GtkFileChooser, self.background_image_file_button));
        if (val == null) {
            return null;
        }
        const len = mem.len(val);
        const style = self.get_image_style();
        return config.BackgroundImage {
            .file = val[0..len],
            .style = style,
        };
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

    fn get_cursor_style(self: PrefWidgets) config.CursorStyle {
        const id = c.gtk_combo_box_get_active_id(@ptrCast(*c.GtkComboBox, self.cursor_style_combobox));
        const style = config.parse_enum(config.CursorStyle, id).?;
        return style;
    }

    fn get_cursor(self:PrefWidgets) config.Cursor {
        const style = self.get_cursor_style();
        const blinks = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, self.cursor_blinks_checkbutton));
        return config.Cursor {
            .cursor_style = style,
            .cursor_blinks = blinks,
        };
    }

    fn get_colors(self: PrefWidgets) config.Colors {
        var colors = config.Colors.default();
        inline for (meta.fields(config.Colors)) |color| {
            const widget = @field(self, color.name);
            const value = config.RGBColor.from_widget(@ptrCast(*c.GtkColorButton, widget));
            @field(colors, color.name) = value;
        }
        return colors;
    }

    fn get_config(self: PrefWidgets) config.Config {
        return config.Config {
            .initial_title = self.get_initial_title(),
            .dynamic_title_style = self.get_title_style(),
            .custom_command = self.get_custom_command(),
            .scrollback = self.get_scrollback(),
            .font = self.get_font(),
            .background = self.get_background(),
            .colors = self.get_colors(),
            .cursor = self.get_cursor(),
        };
    }
};

pub fn run() ?config.Config {
    builder = c.gtk_builder_new();
    const glade_str = @embedFile("prefs.glade");
    _ = c.gtk_builder_add_from_string(builder, glade_str, glade_str.len, @intToPtr([*c][*c]c._GError, 0));
    widgets = PrefWidgets.init(builder);

    _ = gtk.g_signal_connect(
        widgets.custom_command_checkbutton,
        "toggled",
        @ptrCast(c.GCallback, toggle_custom_command),
        null,
    );

    _ = gtk.g_signal_connect(
        widgets.infinite_scrollback_checkbutton,
        "toggled",
        @ptrCast(c.GCallback, toggle_scrollback),
        null,
    );

    _ = gtk.g_signal_connect(
        widgets.system_font_checkbutton,
        "toggled",
        @ptrCast(c.GCallback, toggle_font),
        null,
    );

    _ = gtk.g_signal_connect(
        widgets.background_style_combobox,
        "changed",
        @ptrCast(c.GCallback, toggle_background),
        null,
    );

    _ = gtk.g_signal_connect(
        widgets.close_button,
        "clicked",
        @ptrCast(c.GCallback, save_and_close),
        null,
    );

    const res = c.gtk_dialog_run(@ptrCast(*c.GtkDialog, widgets.window));
    if (res == -1) {
        return conf;
    } else {
        c.gtk_window_close(@ptrCast(*c.GtkWindow, widgets.window));
        c.gtk_widget_destroy(widgets.window);
        return null;
    }
}

fn toggle_custom_command(custom_command_checkbutton: *c.GtkCheckButton, data: c.gpointer) void {
    const state = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, custom_command_checkbutton));
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, widgets.custom_command_entry), state);
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, widgets.custom_command_label), state);
}

fn toggle_scrollback(infinite_scrollback_checkbutton: *c.GtkCheckButton, data: c.gpointer) void {
    const state = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, infinite_scrollback_checkbutton));
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, widgets.scrollback_lines_label), !state);
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, widgets.scrollback_lines_spinbox), !state);
}

fn toggle_font(system_font_checkbutton: *c.GtkCheckButton, data: c.gpointer) void {
    const state = gtk.toggle_button_get_active(@ptrCast(*c.GtkToggleButton, system_font_checkbutton));
    gtk.widget_set_sensitive(@ptrCast(*c.GtkWidget, widgets.font_chooser_button), !state);
}

fn toggle_background(background_combobox: *c.GtkComboBox, data: c.gpointer) void {
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

fn save_and_close(b: *c.GtkButton, data: c.gpointer) void {
    conf = widgets.get_config();
    c.gtk_window_close(@ptrCast(*c.GtkWindow, widgets.window));
    c.gtk_widget_destroy(widgets.window);
}
