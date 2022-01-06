const std = @import("std");
const VTE = @import("vte");
const c = VTE.c;
const gtk = VTE.gtk;
const config = @import("config.zig");
const RGBColor = config.RGBColor;
const allocator = std.heap.page_allocator;

pub var gradientEditor: GradientEditor = undefined;
var numStops: u8 = 2;

pub const StopControls = struct {
    stops: gtk.SpinButton,
    stop_selector: gtk.ComboBoxText,
    stops_stack: gtk.Stack,
    stop1_grid: gtk.Widget,
    stop1_color: gtk.ColorButton,
    stop1_position: gtk.SpinButton,
    stop2_grid: gtk.Widget,
    stop2_color: gtk.ColorButton,
    stop2_position: gtk.SpinButton,
    stop3_grid: gtk.Widget,
    stop3_color: gtk.ColorButton,
    stop3_position: gtk.SpinButton,
    stop4_grid: gtk.Widget,
    stop4_color: gtk.ColorButton,
    stop4_position: gtk.SpinButton,

    const Self = @This();

    fn init(builder: gtk.Builder) ?Self {
        return Self{
            .stops = builder.get_widget("gradient_stops").?.to_spin_button().?,
            .stop_selector = builder.get_widget("gradient_stop_selector").?.to_combo_box_text().?,
            .stops_stack = builder.get_widget("stops_stack").?.to_stack().?,
            .stop1_grid = builder.get_widget("stop1_grid").?,
            .stop1_color = builder.get_widget("stop1_color").?.to_color_button().?,
            .stop1_position = builder.get_widget("stop1_position").?.to_spin_button().?,
            .stop2_grid = builder.get_widget("stop2_grid").?,
            .stop2_color = builder.get_widget("stop2_color").?.to_color_button().?,
            .stop2_position = builder.get_widget("stop2_position").?.to_spin_button().?,
            .stop3_grid = builder.get_widget("stop3_grid").?,
            .stop3_color = builder.get_widget("stop3_color").?.to_color_button().?,
            .stop3_position = builder.get_widget("stop3_position").?.to_spin_button().?,
            .stop4_grid = builder.get_widget("stop4_grid").?,
            .stop4_color = builder.get_widget("stop4_color").?.to_color_button().?,
            .stop4_position = builder.get_widget("stop4_position").?.to_spin_button().?,
        };
    }

    fn toggle(self: Self) void {
        if (self.stop_selector.as_combo_box().get_active()) |id| {
            switch (id) {
                0 => self.stops_stack.set_visible_child(self.stop1_grid),
                1 => self.stops_stack.set_visible_child(self.stop2_grid),
                2 => self.stops_stack.set_visible_child(self.stop3_grid),
                3 => self.stops_stack.set_visible_child(self.stop4_grid),
                else => unreachable,
            }
        }
    }

    fn addRemoveStops(self: Self) void {
        switch (self.stops.get_value_as_int()) {
            2 => {
                switch (numStops) {
                    3 => self.stop_selector.remove(2),
                    4 => {
                        self.stop_selector.remove(3);
                        self.stop_selector.remove(2);
                    },
                    else => {},
                }
                numStops = 2;
            },
            3 => {
                switch (numStops) {
                    4 => self.stop_selector.remove(3),
                    2 => self.stop_selector.append("stop3", "Stop 3"),
                    else => {},
                }
                numStops = 3;
            },
            4 => {
                switch (numStops) {
                    2 => {
                        self.stop_selector.append("stop3", "Stop 3");
                        self.stop_selector.append("stop4", "Stop 4");
                    },
                    3 => self.stop_selector.append("stop4", "Stop 4"),
                    else => {},
                }
                numStops = 3;
            },
            else => unreachable,
        }
    }

    fn connectSignals(self: Self) void {
        self.stops.connect_value_changed(@ptrCast(c.GCallback, alterNumStops), null);
        self.stop_selector.as_combo_box().connect_changed(@ptrCast(c.GCallback, toggleStops), null);
    }
};

pub const GradientEditor = struct {
    editor: gtk.Widget,
    kind: gtk.ComboBox,
    vstart: gtk.ComboBox,
    hstart: gtk.ComboBox,
    dir_type: gtk.ComboBox,
    dir_stack: gtk.Stack,
    edge_grid: gtk.Widget,
    angle_grid: gtk.Widget,
    angle: gtk.SpinButton,
    vend: gtk.ComboBox,
    hend: gtk.ComboBox,
    stops: StopControls,
    gradient_preview: gtk.Box,

    const Self = @This();

    pub fn init(builder: gtk.Builder) ?Self {
        return Self{
            .editor = builder.get_widget("gradient_editor").?,
            .kind = builder.get_widget("gradient_kind").?.to_combo_box().?,
            .vstart = builder.get_widget("gradient_vertical_start").?.to_combo_box().?,
            .hstart = builder.get_widget("gradient_horizontal_start").?.to_combo_box().?,
            .dir_type = builder.get_widget("gradient_direction_type").?.to_combo_box().?,
            .dir_stack = builder.get_widget("gradient_direction_stack").?.to_stack().?,
            .edge_grid = builder.get_widget("gradient_edge_grid").?,
            .angle_grid = builder.get_widget("gradient_angle_grid").?,
            .angle = builder.get_widget("gradient_angle").?.to_spin_button().?,
            .vend = builder.get_widget("gradient_vertical_end").?.to_combo_box().?,
            .hend = builder.get_widget("gradient_horizontal_end").?.to_combo_box().?,
            .stops = StopControls.init(builder).?,
            .gradient_preview = builder.get_widget("gradient_preview").?.to_box().?,
        };
    }

    fn getKind(self: Self) ?GradientKind {
        if (self.kind.get_active_id(allocator)) |id| {
            defer allocator.free(id);
            return if (config.parse_enum(GradientKind, id)) |k| k else null;
        } else return null;
    }

    fn getStart(self: Self) ?Placement {
        const vert = if (self.vstart.get_active_id(allocator)) |id| vblk: {
            defer allocator.free(id);
            if (config.parse_enum(VerticalPlacement, id)) |v| break :vblk v else return null;
        };

        const hor = if (self.hstart.get_active_id(allocator)) |id| hblk: {
            defer allocator.free(id);
            if (config.parse_enum(HorizontalPlacement, id)) |h| break :hblk h else return null;
        };
        return Placement{
            .vertical = vert,
            .horizontal = hor,
        };
    }

    fn getEnd(self: Self) ?Placement {
        const vert = if (self.vend.get_active_id(allocator)) |id| vblk: {
            defer allocator.free(id);
            if (config.parse_enum(VerticalPlacement, id)) |v| break :vblk v else return null;
        };

        const hor = if (self.hend.get_active_id(allocator)) |id| hblk: {
            defer allocator.free(id);
            if (config.parse_enum(HorizontalPlacement, id)) |h| break :hblk h else return null;
        };
        return Placement{
            .vertical = vert,
            .horizontal = hor,
        };
    }

    fn getDirectionType(self: Self) DirectionType {
        if (self.dir_type.get_active_id(allocator)) |id| {
            defer allocator.free(id);
            return if (config.parse_enum(DirectionType, id)) |d| d else null;
        } else return null;
    }

    fn getDirection(self: Self) ?Direction {
        if (self.getDirectionType()) |dtype| {
            return switch (dtype) {
                .angle => Direction{ .angle = self.angle.get_value() },
                .edge => if (self.getEnd()) |end| Direction{ .edge = end } else null,
            };
        } else return null;
    }


    fn connectSignals(self: Self) void {
        self.kind.connect_changed(@ptrCast(c.GCallback, toggleDirectionControls), null);
        self.dir_type.connect_changed(@ptrCast(c.GCallback, toggleGradientEnd), null);
        self.stops.connectSignals();
    }

    fn toggleDirGrid(self: Self) void {
        if (self.getKind()) |kind| {
            switch (kind) {
                .linear => {
                    self.dir_type.as_widget().show();
                    self.dir_stack.as_widget().show();
                },
                .radial, .elliptical => {
                    self.dir_type.as_widget().hide();
                    self.dir_stack.as_widget().hide();
                },
            }
        }
    }

    fn toggleEnd(self: Self) void {
        if (self.dir_type.get_active_id(allocator)) |id| {
            defer allocator.free(id);
            if (config.parse_enum(DirectionType, id)) |kind| {
                switch (kind) {
                    .angle => {
                        self.dir_stack.set_visible_child(self.angle_grid);
                    },
                    .edge => {
                        self.dir_stack.set_visible_child(self.edge_grid);
                    },
                }
            }
        }
    }

    fn toggle(self: Self) void {
        self.toggleDirGrid();
        self.toggleEnd();
        self.stops.toggle();
    }

    pub fn setup(self: Self) void {
        self.connectSignals();
        self.toggle();
    }
};

pub const GradientKind = enum {
    linear,
    radial,
    elliptical,

    const Self = @This();

    fn default() Self {
        return Self.linear;
    }
};

pub const VerticalPlacement = enum {
    top,
    center,
    bottom,

    const Self = @This();

    fn default() Self {
        return Self.top;
    }
};

pub const HorizontalPlacement = enum {
    left,
    center,
    right,

    const Self = @This();

    fn default() Self {
        return Self.left;
    }
};

pub const Placement = struct {
    vertical: VerticalPlacement,
    horizontal: HorizontalPlacement,

    const Self = @This();

    fn default() Self {
        return Self{
            .vertical = VerticalPlacement.default(),
            .horizontal = HorizontalPlacement.default(),
        };
    }
};

const DirectionType = enum {
    angle,
    edge,
};

pub const Direction = union(DirectionType) {
    angle: f64,
    edge: Placement,

    const Self = @This();

    fn default() Self {
        return Self{
            .angle = 45.0,
        };
    }
};

pub const Stop = struct {
    color: RGBColor,
    position: f64,
};

pub const Gradient = struct {
    kind: GradientKind,
    start: Placement,
    direction: ?Direction,
    stop1: Stop,
    stop2: Stop,
    stop3: ?Stop,
    stop4: ?Stop,

    const Self = @This();

    pub fn default() Self {
        return Self{
            .kind = GradientKind.default(),
            .start = Placement.default(),
            .direction = Direction.default(),
            .stop1 = RGBColor{ .red = 0, .green = 0, .blue = 0 },
            .stop2 = RGBColor{ .red = 64, .green = 64, .blue = 64 },
            .stop4 = null,
            .stop4 = null,
        };
    }
};

fn alterNumStops() void {
    gradientEditor.stops.addRemoveStops();
}

fn toggleStops() void {
    gradientEditor.stops.toggle();
}

fn toggleDirectionControls() void {
    gradientEditor.toggleDirGrid();
}

fn toggleGradientEnd() void {
    gradientEditor.toggleEnd();
}
