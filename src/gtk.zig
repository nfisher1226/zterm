pub const c = @cImport({
    @cInclude("gtk/gtk.h");
    @cInclude("vte/vte.h");
});

pub const menu_size = @intToEnum(c.GtkIconSize, c.GTK_ICON_SIZE_MENU);
pub const horizontal = @intToEnum(c.GtkOrientation, c.GTK_ORIENTATION_HORIZONTAL);
pub const pack_end = @intToEnum(c.GtkPackType, c.GTK_PACK_END);
pub const pack_start = @intToEnum(c.GtkPackType, c.GTK_PACK_START);
pub const relief_none = @intToEnum(c.GtkReliefStyle, c.GTK_RELIEF_NONE);
pub const vertical = @intToEnum(c.GtkOrientation, c.GTK_ORIENTATION_VERTICAL);
pub const shift_mask = @intToEnum(c.GdkModifierType, c.GDK_SHIFT_MASK);
pub const alt_mask = @intToEnum(c.GdkModifierType, c.GDK_MOD1_MASK);
pub const ctrl_mask = @intToEnum(c.GdkModifierType, c.GDK_CONTROL_MASK);
pub const accel_locked = @intToEnum(c.GtkAccelFlags, c.GTK_ACCEL_LOCKED);

pub fn g_signal_connect(instance: c.gpointer, detailed_signal: [*c]const c.gchar, c_handler: c.GCallback, data: c.gpointer) c.gulong {
    var zero: u32 = 0;
    const flags: *c.GConnectFlags = @ptrCast(*c.GConnectFlags, &zero);
    return c.g_signal_connect_data(instance, detailed_signal, c_handler, data, null, flags.*);
}

pub fn builder_get_widget(builder: *c.GtkBuilder, name: [*]const u8) ?*c.GtkWidget {
    const obj = c.gtk_builder_get_object(builder, name);
    if (obj == null) {
        return null;
    } else {
        var gobject = @ptrCast([*c]c.GTypeInstance, obj);
        var gwidget = @ptrCast(*c.GtkWidget, c.g_type_check_instance_cast(gobject, c.gtk_widget_get_type()));
        return gwidget;
    }
}

pub fn toggle_button_get_active(but: *c.GtkToggleButton) bool {
    if (c.gtk_toggle_button_get_active(but) == 0) {
        return false;
    } else {
        return true;
    }
}

pub fn widget_set_sensitive(widget: *c.GtkWidget, state: bool) void {
    if (state) {
        c.gtk_widget_set_sensitive(widget, 1);
    } else {
        c.gtk_widget_set_sensitive(widget, 0);
    }
}
pub fn widget_set_visible(widget: *c.GtkWidget, state: bool) void {
    if (state) {
        c.gtk_widget_set_visible(widget, 1);
    } else {
        c.gtk_widget_set_visible(widget, 0);
    }
}
