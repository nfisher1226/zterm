const std = @import("std");
const VTE = @import("vte");
const c = VTE.c;
const gtk = VTE.gtk;
const config = @import("config.zig");
const RGBColor = config.RGBColor;
const RGB = @import("zig-color").RGB;
const allocator = std.heap.page_allocator;
const math = std.math;

var gradientEditor: GradientEditor = undefined;
var numStops: u8 = 2;

pub const StopControls = struct {
    stops: gtk.SpinButton,
    stop_selector: gtk.ComboBoxText,
    stops_stack: gtk.Stack,
    stop1_grid: gtk.Widget,
    stop1_color: gtk.ColorButton,
    stop1_position: gtk.Scale,
    stop2_grid: gtk.Widget,
    stop2_color: gtk.ColorButton,
    stop2_position: gtk.Scale,
    stop3_grid: gtk.Widget,
    stop3_color: gtk.ColorButton,
    stop3_position: gtk.Scale,
    stop4_grid: gtk.Widget,
    stop4_color: gtk.ColorButton,
    stop4_position: gtk.Scale,

    const Self = @This();

    fn init(builder: gtk.Builder) ?Self {
        return Self{
            .stops = builder.get_widget("gradient_stops").?.to_spin_button().?,
            .stop_selector = builder.get_widget("gradient_stop_selector").?.to_combo_box_text().?,
            .stops_stack = builder.get_widget("stops_stack").?.to_stack().?,
            .stop1_grid = builder.get_widget("stop1_grid").?,
            .stop1_color = builder.get_widget("stop1_color").?.to_color_button().?,
            .stop1_position = builder.get_widget("stop1_position").?.to_scale().?,
            .stop2_grid = builder.get_widget("stop2_grid").?,
            .stop2_color = builder.get_widget("stop2_color").?.to_color_button().?,
            .stop2_position = builder.get_widget("stop2_position").?.to_scale().?,
            .stop3_grid = builder.get_widget("stop3_grid").?,
            .stop3_color = builder.get_widget("stop3_color").?.to_color_button().?,
            .stop3_position = builder.get_widget("stop3_position").?.to_scale().?,
            .stop4_grid = builder.get_widget("stop4_grid").?,
            .stop4_color = builder.get_widget("stop4_color").?.to_color_button().?,
            .stop4_position = builder.get_widget("stop4_position").?.to_scale().?,
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
                numStops = 4;
            },
            else => unreachable,
        }
    }

    fn updateScale2(self: Self) void {
        const val = self.stop1_position.as_range().get_value();
        const adj = self.stop2_position.as_range().get_adjustment();
        if (adj.get_value() < val) adj.set_value(val);
        adj.set_lower(val);
    }

    fn updateScale3(self: Self) void {
        const val = self.stop2_position.as_range().get_value();
        const adj = self.stop3_position.as_range().get_adjustment();
        if (adj.get_value() < val) adj.set_value(val);
        adj.set_lower(val);
    }

    fn updateScale4(self: Self) void {
        const val = self.stop3_position.as_range().get_value();
        const adj = self.stop4_position.as_range().get_adjustment();
        if (adj.get_value() < val) adj.set_value(val);
        adj.set_lower(val);
    }

    fn connectSignals(self: Self) void {
        self.stops.connect_value_changed(@ptrCast(c.GCallback, alterNumStops), null);
        self.stop_selector.as_combo_box().connect_changed(@ptrCast(c.GCallback, toggleStops), null);
        self.stop1_position.as_range().connect_value_changed(@ptrCast(c.GCallback, clampScale2), null);
        self.stop2_position.as_range().connect_value_changed(@ptrCast(c.GCallback, clampScale3), null);
        self.stop3_position.as_range().connect_value_changed(@ptrCast(c.GCallback, clampScale4), null);
    }

    fn getStop(button: gtk.ColorButton, scale: gtk.Scale) ?Stop {
        const gdk = button.as_color_chooser().get_rgba();
        const f = RGB.new(f64, gdk.red, gdk.green, gdk.blue) catch return null;
        const color = f.toInt(u8) catch return null;
        return Stop{
            .color = color,
            .position = scale.as_range().get_value(),
        };
    }
};

pub const GradientEditor = struct {
    editor: gtk.Widget,
    kind: gtk.ComboBox,
    position_type: gtk.Stack,
    start_position: gtk.Widget,
    end_position: gtk.Widget,
    dir_type: gtk.ComboBox,
    dir_stack: gtk.Stack,
    angle_grid: gtk.Widget,
    angle: gtk.SpinButton,
    edge_grid: gtk.Widget,
    vertical_position: gtk.ComboBox,
    horizontal_position: gtk.ComboBox,
    stops: StopControls,
    gradient_preview: gtk.Box,

    const Self = @This();

    pub fn init(builder: gtk.Builder) ?Self {
        gradientEditor = Self{
            .editor = builder.get_widget("gradient_editor").?,
            .kind = builder.get_widget("gradient_kind").?.to_combo_box().?,
            .position_type = builder.get_widget("position_type_stack").?.to_stack().?,
            .start_position = builder.get_widget("start_position").?,
            .end_position = builder.get_widget("end_position").?,
            .dir_type = builder.get_widget("gradient_direction_type").?.to_combo_box().?,
            .dir_stack = builder.get_widget("gradient_direction_stack").?.to_stack().?,
            .angle_grid = builder.get_widget("gradient_angle_grid").?,
            .angle = builder.get_widget("gradient_angle").?.to_spin_button().?,
            .edge_grid = builder.get_widget("gradient_edge_grid").?,
            .vertical_position = builder.get_widget("gradient_vertical_position").?.to_combo_box().?,
            .horizontal_position = builder.get_widget("gradient_horizontal_position").?.to_combo_box().?,
            .stops = StopControls.init(builder).?,
            .gradient_preview = builder.get_widget("gradient_preview").?.to_box().?,
        };
        gradientEditor.setup();
        return gradientEditor;
    }

    fn getGradientKind(self: Self) ?GradientKind {
        if (self.kind.get_active_id(allocator)) |id| {
            defer allocator.free(id);
            return if (config.parse_enum(GradientKind, id)) |k| k else null;
        } else return null;
    }

    fn getKind(self: Self) ?Kind {
        const gradient_kind = if (self.getGradientKind()) |k| k else return null;
        const kind: ?Kind = switch (gradient_kind) {
            .linear => lblk: {
                if (self.getDirection()) |d| {
                    break :lblk GradientKind{ .linear = d };
                } else return null;
            },
            .radial => rblk: {
                if (self.getPlacement()) |p| {
                    break :rblk GradientKind{ .radial = p };
                } else return null;
            },
            .elliptical => eblk: {
                if (self.getPlacement()) |p| {
                    break eblk: GradientKind{ .elliptical = p };
                } else return null;
            },
        };
        return kind;
    }

    fn getPlacement(self: Self) ?Placement {
        const vert = if (self.vertical_position.get_active_id(allocator)) |id| vblk: {
            defer allocator.free(id);
            if (config.parse_enum(VerticalPlacement, id)) |v| break :vblk v else return null;
        };

        const hor = if (self.horizontal_placement.get_active_id(allocator)) |id| hblk: {
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
                .edge => if (self.getPlacement()) |p| Direction{ .edge = p } else null,
            };
        } else return null;
    }

    fn getGradient(self: Self) ?Gradient {
        const s3: ?Stop = switch (numStops) {
            2 => null,
            3, 4 => if (self.stops.getStop(self.stop3_color, self.stop3_position)) |s| s else return null,
        };
        const s4: ?Stop = switch (numStops) {
            2, 3 => null,
            4 => if (self.stops.getStop(self.stop4_color, self.stop4_position)) |s| s else return null,
        };
        return Gradient{
            .kind = if (self.getKind()) |k| k else return null,
            .stop1 = if (self.stops.getStop(self.stop1_color, self.stop1_position)) |x| x else return null,
            .stop2 = if (self.stops.getStop(self.stop2_color, self.stop2_position)) |x| x else return null,
            .stop3 = if (s3) |x| x else null,
            .stop4 = if (s4) |x| x else null,
        };
    }

    fn connectSignals(self: Self) void {
        self.kind.connect_changed(@ptrCast(c.GCallback, togglePosition), null);
        self.dir_type.connect_changed(@ptrCast(c.GCallback, toggleDirection), null);
        self.stops.connectSignals();
    }

    fn togglePositionType(self: Self) void {
        if (self.getKind()) |kind| {
            switch (kind) {
                .linear => {
                    self.position_type.set_visible_child(self.end_position);
                    self.toggleDirectionType();
                },
                .radial, .elliptical => {
                    self.position_type.set_visible_child(self.start_position);
                    self.dir_stack.set_visible_child(self.edge_grid);
                },
            }
        }
    }

    fn toggleDirectionType(self: Self) void {
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
        self.toggleDirectionType();
        self.togglePositionType();
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
};

pub const Kind = union(GradientKind) {
    linear: Direction,
    radial: Placement,
    elliptical: Placement,

    const Self = @This();

    fn default() Self {
        return Self{ .linear = Direction{ .edge = Placement.default() }};
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
    color: RGB,
    position: f64,
};

pub const Gradient = struct {
    kind: Kind,
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
            .stop1 = Stop{
                .color = RGBColor{ .red = 0, .green = 0, .blue = 0 },
                .position = 0.0,
            },
            .stop2 = Stop{
                .color = RGBColor{ .red = 64, .green = 64, .blue = 64 },
                .position = 100.0,
            },
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

fn clampScale2() void {
    gradientEditor.stops.updateScale2();
}

fn clampScale3() void {
    gradientEditor.stops.updateScale3();
}

fn clampScale4() void {
    gradientEditor.stops.updateScale4();
}

fn togglePosition() void {
    gradientEditor.togglePositionType();
}

fn toggleDirection() void {
    gradientEditor.toggleDirectionType();
}
