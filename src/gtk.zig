pub const c = @cImport({
    @cInclude("gtk/gtk.h");
    @cInclude("vte/vte.h");
});

pub fn g_signal_connect(instance: c.gpointer, detailed_signal: [*c]const c.gchar, c_handler: c.GCallback, data: c.gpointer) c.gulong {
    var zero: u32 = 0;
    const flags: *c.GConnectFlags = @ptrCast(*c.GConnectFlags, &zero);
    return c.g_signal_connect_data(instance, detailed_signal, c_handler, data, null, flags.*);
}

pub fn builder_get_widget(builder: *c.GtkBuilder, name: [*]const u8) [*]c.GtkWidget {
    var gobject = @ptrCast([*c]c.GTypeInstance, c.gtk_builder_get_object(builder, name));
    var gwidget = @ptrCast([*c]c.GtkWidget, c.g_type_check_instance_cast(gobject, c.gtk_widget_get_type()));
    return gwidget;
}
