const std = @import("std");
const VTE = @import("vte");
const c = VTE.c;
const gtk = VTE.gtk;
const config = @import("config.zig");
const gui = @import("gui.zig");
const RGB = config.RGB;
const allocator = std.heap.page_allocator;
const fmt = std.fmt;
const math = std.math;
const mem = std.mem;

var grad: ?Gradient = undefined;
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
                    2 => {
                        self.stop_selector.append("stop3", "Stop 3");
                        const adj = self.stop2_position.as_range().get_adjustment();
                        adj.set_value(50);
                    },
                    else => {},
                }
                numStops = 3;
            },
            4 => {
                switch (numStops) {
                    2 => {
                        self.stop_selector.append("stop3", "Stop 3");
                        var adj = self.stop2_position.as_range().get_adjustment();
                        adj.set_value(33);
                        self.stop_selector.append("stop4", "Stop 4");
                        adj = self.stop2_position.as_range().get_adjustment();
                        adj.set_value(66);
                    },
                    3 => {
                        self.stop_selector.append("stop4", "Stop 4");
                        const adj = self.stop3_position.as_range().get_adjustment();
                        adj.set_value(66);
                    },
                    else => {},
                }
                numStops = 4;
            },
            else => unreachable,
        }
    }

    fn setStops(self: Self) void {
        if (grad) |g| {
            self.stop1_color.as_color_chooser().set_rgba(g.stop1.color.toGdk());
            self.stop1_position.as_range().set_value(g.stop1.position);
            self.stop2_color.as_color_chooser().set_rgba(g.stop2.color.toGdk());
            self.stop2_position.as_range().set_value(g.stop2.position);
            if (g.stop3) |s| {
                self.stop3_color.as_color_chooser().set_rgba(s.color.toGdk());
                numStops = 3;
                self.stops.set_value(3);
                self.stop_selector.append("stop3", "Stop 3");
            } else numStops = 2;
            if (g.stop4) |s| {
                self.stop4_color.as_color_chooser().set_rgba(s.color.toGdk());
                numStops = 4;
                self.stops.set_value(4);
                self.stop_selector.append("stop4", "Stop 4");
            }
        }
    }

    fn setup(self: Self) void {
        self.connectSignals();
        self.setStops();
        self.toggle();
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
        const Callbacks = struct {
            fn stopsValueChanged() void {
                gradientEditor.stops.addRemoveStops();
                gradientEditor.setBg();
            }

            fn stopSelectorChanged() void {
                gradientEditor.stops.toggle();
            }

            fn stop1PositionValueChanged() void {
                gradientEditor.stops.updateScale2();
                gradientEditor.setBg();
            }

            fn stop2PositionValueChanged() void {
                gradientEditor.stops.updateScale3();
                gradientEditor.setBg();
            }

            fn stop3PositionValueChanged() void {
                gradientEditor.stops.updateScale4();
                gradientEditor.setBg();
            }

            fn updatePreview() void {
                gradientEditor.setBg();
            }
        };

        self.stops.connect_value_changed(
            @ptrCast(c.GCallback, Callbacks.stopsValueChanged),
            null
        );
        self.stop_selector.as_combo_box().connect_changed(
            @ptrCast(c.GCallback, Callbacks.stopSelectorChanged),
            null
        );
        self.stop1_position.as_range().connect_value_changed(
            @ptrCast(c.GCallback, Callbacks.stop1PositionValueChanged),
            null
        );
        self.stop1_color.connect_color_set(
            @ptrCast(c.GCallback, Callbacks.updatePreview),
            null
        );
        self.stop2_position.as_range().connect_value_changed(
            @ptrCast(c.GCallback, Callbacks.stop2PositionValueChanged),
            null
        );
        self.stop2_color.connect_color_set(
            @ptrCast(c.GCallback, Callbacks.updatePreview),
            null
        );
        self.stop3_position.as_range().connect_value_changed(
            @ptrCast(c.GCallback, Callbacks.stop3PositionValueChanged),
            null
        );
        self.stop3_color.connect_color_set(
            @ptrCast(c.GCallback, Callbacks.updatePreview),
            null
        );
        self.stop4_position.as_range().connect_value_changed(
            @ptrCast(c.GCallback, Callbacks.updatePreview),
            null
        );
        self.stop4_color.connect_color_set(
            @ptrCast(c.GCallback, Callbacks.updatePreview),
            null
        );
    }

    fn getStop(self: Self, button: gtk.ColorButton, scale: gtk.Scale) Stop {
        _ = self;
        return Stop{
            .color = RGB.fromButton(button),
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

    const Self = @This();

    pub fn init(builder: gtk.Builder, conf: config.Config) ?Self {
        grad = switch (conf.background) {
            .gradient => |g| g,
            else => null,
        };
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
        };
        gradientEditor.setup();
        return gradientEditor;
    }

    fn getKind(self: Self) ?GradientKind {
        if (self.kind.get_active_id(allocator)) |id| {
            defer allocator.free(id);
            return if (config.parseEnum(GradientKind, id)) |k| k else null;
        } else return null;
    }

    fn setKind(self: Self) void {
        if (grad) |g| {
            switch (g.kind) {
                .linear => {
                    self.kind.set_active_id("linear");
                    self.position_type.set_visible_child(self.end_position);
                },
                .radial => {
                    self.kind.set_active_id("radial");
                    self.position_type.set_visible_child(self.start_position);
                },
                .elliptical => {
                    self.kind.set_active_id("elliptical");
                    self.position_type.set_visible_child(self.start_position);
                },
            }
        }
    }

    fn getPlacement(self: Self) ?Placement {
        const vert = vblk: {
            if (self.vertical_position.get_active_id(allocator)) |id| {
                defer allocator.free(id);
                if (config.parseEnum(VerticalPlacement, id)) |v| break :vblk v else return null;
            } else return null;
        };

        const hor = hblk: {
            if (self.horizontal_position.get_active_id(allocator)) |id| {
                defer allocator.free(id);
                if (config.parseEnum(HorizontalPlacement, id)) |h| break :hblk h else return null;
            } else return null;
        };
        return Placement{
            .vertical = vert,
            .horizontal = hor,
        };
    }

    fn getDirectionType(self: Self) ?DirectionType {
        if (self.dir_type.get_active_id(allocator)) |id| {
            defer allocator.free(id);
            return if (config.parseEnum(DirectionType, id)) |d| d else null;
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

    fn setDirection(self: Self) void {
        if (grad) |g| {
            switch (g.pos) {
                .angle => |a| {
                    self.dir_stack.set_visible_child(self.angle_grid);
                    self.dir_type.set_active_id("angle");
                    self.angle.set_value(a);
                },
                .edge => |p| {
                    self.dir_stack.set_visible_child(self.edge_grid);
                    self.dir_type.set_active_id("edge");
                    switch (p.vertical) {
                        .top => self.vertical_position.set_active_id("top"),
                        .center => self.vertical_position.set_active_id("center"),
                        .bottom => self.vertical_position.set_active_id("bottom"),
                    }
                    switch (p.horizontal) {
                        .left => self.horizontal_position.set_active_id("left"),
                        .center => self.horizontal_position.set_active_id("center"),
                        .right => self.horizontal_position.set_active_id("right"),
                    }
                },
            }
        }
    }

    pub fn getGradient(self: Self) ?Gradient {
        const s3: ?Stop = switch (numStops) {
            2 => null,
            3, 4 => self.stops.getStop(self.stops.stop3_color, self.stops.stop3_position),
            else => return null,
        };
        const s4: ?Stop = switch (numStops) {
            2, 3 => null,
            4 => self.stops.getStop(self.stops.stop4_color, self.stops.stop4_position),
            else => return null,
        };
        const kind = if (self.getKind()) |k| k else return null;
        const pos = switch (kind) {
            .linear => lblk: {
                if (self.getDirection()) |d| {
                    break :lblk d;
                } else return null;
            },
            .radial, .elliptical => pblk: {
                if (self.getPlacement()) |p| {
                    break :pblk Direction{.edge = p, };
                } else return null;
            },
        };
        return Gradient{
            .kind = kind,
            .pos = pos,
            .stop1 = self.stops.getStop(self.stops.stop1_color, self.stops.stop1_position),
            .stop2 = self.stops.getStop(self.stops.stop2_color, self.stops.stop2_position),
            .stop3 = if (s3) |x| x else null,
            .stop4 = if (s4) |x| x else null,
        };
    }

    pub fn setBg(self: Self) void {
        if (self.getGradient()) |g| {
            if (g.toCss(".workview stack")) |css| {
                defer allocator.free(css);
                const provider = gui.css_provider;
                _ = c.gtk_css_provider_load_from_data(provider, css, -1, null);
            }
        }
    }

    fn connectSignals(self: Self) void {
        const Callbacks = struct {
            fn kindChanged() void {
                gradientEditor.togglePositionType();
                gradientEditor.setBg();
            }

            fn dirTypeChanged() void {
                gradientEditor.toggleDirectionType();
                gradientEditor.setBg();
            }

            fn setBg() void {
                gradientEditor.setBg();
            }
        };

        self.kind.connect_changed(
            @ptrCast(c.GCallback, Callbacks.kindChanged), null);
        self.dir_type.connect_changed(
            @ptrCast(c.GCallback, Callbacks.dirTypeChanged), null);
        self.angle.connect_value_changed(
            @ptrCast(c.GCallback, Callbacks.setBg), null);
        self.vertical_position.connect_changed(
            @ptrCast(c.GCallback, Callbacks.setBg), null);
        self.horizontal_position.connect_changed(
            @ptrCast(c.GCallback, Callbacks.setBg), null);
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
            if (config.parseEnum(DirectionType, id)) |kind| {
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
    }

    pub fn setup(self: Self) void {
        self.connectSignals();
        self.toggle();
        self.setKind();
        self.setDirection();
        self.stops.setup();
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

// This isn't used currently, because `zig-nestedtext` doesn't save the tag when
// parsing tagged unions and so cannot preserve our variant (linear, radial, elliptical)
// I want to keep it around because by using it it becomes impossible to create
// a `Gradient` struct that is a radial or elliptical variant with an angular
// direction.
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
        return Self{ .edge = Placement.default(), };
    }
};

pub const Stop = struct {
    color: RGB,
    position: f64,

    const Self = @This();

    fn toCss(self: Self, buf: *[26]u8) ?[]const u8 {
        const str = fmt.bufPrint(buf, ", rgb({d}, {d}, {d}) {d}%",
            .{self.color.red, self.color.green, self.color.blue, math.round(self.position)})
            catch return null;
        return str;
    }
};

pub const Gradient = struct {
    kind: GradientKind,
    pos: Direction,
    stop1: Stop,
    stop2: Stop,
    stop3: ?Stop,
    stop4: ?Stop,

    const Self = @This();

    pub fn default() Self {
        return Self{
            .kind = GradientKind.default(),
            .pos = Direction.default(),
            .stop1 = Stop{
                .color = RGB{ .red = 0, .green = 0, .blue = 0 },
                .position = 0.0,
            },
            .stop2 = Stop{
                .color = RGB{ .red = 64, .green = 64, .blue = 64 },
                .position = 100.0,
            },
            .stop3 = null,
            .stop4 = null,
        };
    }

    pub fn toCss(self: Self, class: []const u8) ?[:0]const u8 {
        var variety: []const u8 = "";
        var positioning: []const u8 = "";
        var angle: ?u16 = null;
        switch (self.kind) {
            .linear => {
                variety = "linear-gradient";
                switch (self.pos) {
                    .angle => |a| {
                        angle = @floatToInt(u16, math.round(a));
                    },
                    .edge => |e| {
                        positioning = switch (e.vertical) {
                            .top => switch (e.horizontal) {
                                .left => "to top left",
                                .center => "to top",
                                .right => "to top right",
                            },
                            .center => switch (e.horizontal) {
                                .left => "to left",
                                .center => "to bottom right",
                                .right => "to top right",
                            },
                            .bottom => switch (e.horizontal) {
                                .left => "to bottom left",
                                .center => "to bottom",
                                .right => "to bottom right",
                            },
                        };
                    },
                }
            },
            .radial => {
                variety = "radial-gradient";
                const pos = switch (self.pos) {
                    .angle => return null,
                    .edge => |e| e,
                };
                positioning = switch (pos.vertical) {
                    .top => switch (pos.horizontal) {
                        .left => "circle at top left",
                        .center => "circle at top",
                        .right => "circle at top right",
                    },
                    .center => switch (pos.horizontal) {
                        .left => "circle at left",
                        .center => "circle at center",
                        .right => "circle at right",
                    },
                    .bottom => switch (pos.horizontal) {
                        .left => "circle at bottom left",
                        .center => "circle at bottom",
                        .right => "circle at bottom right",
                    },
                };
            },
            .elliptical => {
                variety = "radial-gradient";
                const pos = switch (self.pos) {
                    .angle => return null,
                    .edge => |e| e,
                };
                positioning = switch (pos.vertical) {
                    .top => switch (pos.horizontal) {
                        .left => "ellipse at top left",
                        .center => "ellipse at top",
                        .right => "ellipse at top right",
                    },
                    .center => switch (pos.horizontal) {
                        .left => "ellipse at left",
                        .center => "ellipse at center",
                        .right => "ellipse at right",
                    },
                    .bottom => switch (pos.horizontal) {
                        .left => "ellipse at bottom left",
                        .center => "ellipse at bottom",
                        .right => "ellipse at bottom right",
                    },
                };
            },
        }
        if (angle) |a| {
            var buf: [7]u8 = undefined;
            const str = fmt.bufPrint(&buf, "{d}deg", .{a}) catch return null;
            positioning = str[0..];
        }

        var buf1: [26]u8 = undefined;
        const s1 = if (self.stop1.toCss(&buf1)) |css| css else return null;
        var buf2: [26]u8 = undefined;
        const s2 = if (self.stop2.toCss(&buf2)) |css| css else return null;

        const s3: []const u8 = if (self.stop3) |s| sblk: {
            var buf3: [26]u8 = undefined;
            if (s.toCss(&buf3)) |css| {
                break :sblk css;
            } else return null;
        } else "";

        const s4: []const u8 = if (self.stop4) |s| sblk: {
            var buf4: [26]u8 = undefined;
            if (s.toCss(&buf4)) |css| {
                break :sblk css;
            } else return null;
        } else "";

        const css_string = fmt.allocPrintZ(allocator,
            "{s} {{\n    background-image: {s}({s}{s}{s}{s}{s});\n    background-size: 100% 100%;\n\n}}",
            .{  class,
                variety,
                positioning,
                s1,
                s2,
                s3,
                s4,
            }
        ) catch return null;
        return css_string;
    }
};
