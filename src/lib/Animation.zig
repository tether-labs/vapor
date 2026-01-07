const std = @import("std");
const Vapor = @import("Vapor.zig");
const Allocator = std.mem.Allocator;
const StyleCompiler = @import("convertStyleCustomWriter.zig");
const getExitAnimationStyle = StyleCompiler.getExitAnimationStyle;
const getExitAnimationStyleLen = StyleCompiler.getAnimationsLen;
const UINode = @import("UITree.zig").UINode;
const Color = Vapor.Types.Color;

pub const Animation = @This();

pub const AnimationType = enum(u8) {
    none,
    // Position
    translateX,
    translateY,
    translateZ,
    // Scale
    scale,
    scaleX,
    scaleY,
    // Rotation
    rotate,
    rotateX,
    rotateY,
    rotateZ,
    // Skew
    skewX,
    skewY,
    // Visual
    opacity,
    // Size
    width,
    height,
    // Spacing
    marginTop,
    marginBottom,
    marginLeft,
    marginRight,
    paddingTop,
    paddingBottom,
    paddingLeft,
    paddingRight,
    // Position
    top,
    bottom,
    left,
    right,
    // Other
    borderRadius,
    borderWidth,
    blur,
    brightness,
    saturate,

    backgroundColor,

    pub fn isTransform(self: AnimationType) bool {
        return switch (self) {
            .translateX, .translateY, .translateZ, .scale, .scaleX, .scaleY, .rotate, .rotateX, .rotateY, .rotateZ, .skewX, .skewY => true,
            else => false,
        };
    }

    pub fn isFilter(self: AnimationType) bool {
        return switch (self) {
            .blur, .brightness, .saturate => true,
            else => false,
        };
    }

    pub fn toCss(self: AnimationType) []const u8 {
        return switch (self) {
            .none => "",
            .translateX => "translateX",
            .translateY => "translateY",
            .translateZ => "translateZ",
            .scale => "scale",
            .scaleX => "scaleX",
            .scaleY => "scaleY",
            .rotate => "rotate",
            .rotateX => "rotateX",
            .rotateY => "rotateY",
            .rotateZ => "rotateZ",
            .skewX => "skewX",
            .skewY => "skewY",
            .opacity => "opacity",
            .width => "width",
            .height => "height",
            .marginTop => "margin-top",
            .marginBottom => "margin-bottom",
            .marginLeft => "margin-left",
            .marginRight => "margin-right",
            .paddingTop => "padding-top",
            .paddingBottom => "padding-bottom",
            .paddingLeft => "padding-left",
            .paddingRight => "padding-right",
            .top => "top",
            .bottom => "bottom",
            .left => "left",
            .right => "right",
            .borderRadius => "border-radius",
            .borderWidth => "border-width",
            .blur => "blur",
            .brightness => "brightness",
            .saturate => "saturate",
            .backgroundColor => "background-color",
        };
    }
};

pub const Easing = enum(u8) {
    linear,
    ease,
    easeIn,
    easeOut,
    easeInOut,
    easeInQuad,
    easeOutQuad,
    easeInOutQuad,
    easeInCubic,
    easeOutCubic,
    easeInOutCubic,
    easeInBack,
    easeOutBack,
    easeInOutBack,
    easeOutBounce,

    pub fn toCss(self: Easing) []const u8 {
        return switch (self) {
            .linear => "linear",
            .ease => "ease",
            .easeIn => "ease-in",
            .easeOut => "ease-out",
            .easeInOut => "ease-in-out",
            .easeInQuad => "cubic-bezier(0.55, 0.085, 0.68, 0.53)",
            .easeOutQuad => "cubic-bezier(0.25, 0.46, 0.45, 0.94)",
            .easeInOutQuad => "cubic-bezier(0.455, 0.03, 0.515, 0.955)",
            .easeInCubic => "cubic-bezier(0.55, 0.055, 0.675, 0.19)",
            .easeOutCubic => "cubic-bezier(0.215, 0.61, 0.355, 1)",
            .easeInOutCubic => "cubic-bezier(0.645, 0.045, 0.355, 1)",
            .easeInBack => "cubic-bezier(0.6, -0.28, 0.735, 0.045)",
            .easeOutBack => "cubic-bezier(0.175, 0.885, 0.32, 1.275)",
            .easeInOutBack => "cubic-bezier(0.68, -0.55, 0.265, 1.55)",
            .easeOutBounce => "cubic-bezier(0.175, 0.885, 0.32, 1.275)",
        };
    }
};

pub const FillMode = enum(u8) {
    none,
    forwards,
    backwards,
    both,

    pub fn toCss(self: FillMode) []const u8 {
        return switch (self) {
            .none => "none",
            .forwards => "forwards",
            .backwards => "backwards",
            .both => "both",
        };
    }
};

pub const Direction = enum(u8) {
    normal,
    reverse,
    alternate,
    alternateReverse,

    pub fn toCss(self: Direction) []const u8 {
        return switch (self) {
            .normal => "normal",
            .reverse => "reverse",
            .alternate => "alternate",
            .alternateReverse => "alternate-reverse",
        };
    }
};

pub const Unit = enum(u8) {
    px,
    percent,
    em,
    rem,
    vw,
    vh,
    deg,
    none,

    pub fn toCss(self: Unit) []const u8 {
        return switch (self) {
            .px => "px",
            .percent => "%",
            .em => "em",
            .rem => "rem",
            .vw => "vw",
            .vh => "vh",
            .deg => "deg",
            .none => "",
        };
    }
};

// A single property to animate
pub const Property = struct {
    prop_type: AnimationType,
    from_value: f32,
    to_value: f32,
    unit: Unit,

    pub fn init(prop_type: AnimationType, from_val: f32, to_val: f32) Property {
        const default_unit: Unit = switch (prop_type) {
            .opacity, .scale, .scaleX, .scaleY, .brightness, .saturate => .none,
            .rotate, .rotateX, .rotateY, .rotateZ, .skewX, .skewY => .deg,
            else => .px,
        };

        return Property{
            .prop_type = prop_type,
            .from_value = from_val,
            .to_value = to_val,
            .unit = default_unit,
        };
    }

    pub fn inUnit(self: Property, unit: Unit) Property {
        var p = self;
        p.unit = unit;
        return p;
    }
};
// -- NEW: Value Logic (Handling Numbers vs Colors) --

// We need a way to store either a Float (for transforms) or a specific String/Color
// Since your previous example used f32, we will stick to that for simplicity,
// but for a true glitch effect (colors), you would ideally use a Union here.
// For this example, I will assume we are just animating the transforms/filters.
// 1. The container for the data (Number OR Color)
pub const Value = union(enum) {
    number: f32,
    color: Color,
};

pub const PropValue = struct {
    type: AnimationType,
    value: Value,
    unit: Unit,

    // Init for Numbers (Transforms, Opacity, etc.)
    pub fn init(t: AnimationType, v: f32) PropValue {
        const u: Unit = switch (t) {
            .rotate, .rotateX, .rotateY, .rotateZ => .deg,
            .opacity, .scale, .scaleX, .scaleY => .none,
            else => .px,
        };
        return .{ .type = t, .value = .{ .number = v }, .unit = u };
    }

    // Init for Numbers with explicit Unit
    pub fn initUnit(t: AnimationType, v: f32, u: Unit) PropValue {
        return .{ .type = t, .value = .{ .number = v }, .unit = u };
    }

    // Init for Colors (Background, Border, etc.)
    pub fn initColor(t: AnimationType, c: Color) PropValue {
        return .{ .type = t, .value = .{ .color = c }, .unit = .none };
    }
};

// -- NEW: Keyframe Storage --

const MAX_PROPS_PER_FRAME = 8;
const MAX_KEYFRAMES = 10; // 0%, 25%, 35%, 59%, 60%, 100%...

pub const Keyframe = struct {
    percent: u8, // 0 to 100
    props: [MAX_PROPS_PER_FRAME]?PropValue = [_]?PropValue{null} ** MAX_PROPS_PER_FRAME,
    count: u8 = 0,

    pub fn add(self: Keyframe, t: AnimationType, v: f32) Keyframe {
        var k = self;
        if (k.count < MAX_PROPS_PER_FRAME) {
            k.props[k.count] = PropValue.init(t, v);
            k.count += 1;
        }
        return k;
    }

    pub fn addUnit(self: Keyframe, t: AnimationType, v: f32, u: Unit) Keyframe {
        var k = self;
        if (k.count < MAX_PROPS_PER_FRAME) {
            k.props[k.count] = PropValue.initUnit(t, v, u);
            k.count += 1;
        }
        return k;
    }

    // NEW: Helper to add a color property
    pub fn addColor(self: Keyframe, t: AnimationType, c: Color) Keyframe {
        var k = self;
        if (k.count < MAX_PROPS_PER_FRAME) {
            k.props[k.count] = PropValue.initColor(t, c);
            k.count += 1;
        }
        return k;
    }
};

const MAX_PROPERTIES = 8;

frames: [MAX_KEYFRAMES]?Keyframe = [_]?Keyframe{null} ** MAX_KEYFRAMES,
frame_count: u8 = 0,
// Used for the builder chain to know which frame we are editing
current_percent: u8 = 0,

// Core animation fields
_name: []const u8,
properties: [MAX_PROPERTIES]?Property = [_]?Property{null} ** MAX_PROPERTIES,
property_count: u8 = 0,
duration_ms: u32 = 1000,
delay_ms: u32 = 0,
easing_fn: Easing = .linear,
fill_mode: FillMode = .none,
direction: Direction = .normal,
iteration_count: ?u32 = 1,

pub fn init(name: []const u8) Animation {
    return Animation{
        ._name = name,
    };
}

// -- The New "Glitch" Builder API --

/// Sets the current "cursor" to a specific percentage.
/// If a keyframe doesn't exist for this percent, it creates one.
pub fn at(self: Animation, percent: u8) Animation {
    var a = self;
    a.current_percent = percent;

    // Check if frame exists
    for (a.frames) |f| {
        if (f) |frame| {
            if (frame.percent == percent) return a;
        }
    }

    // Create new frame if not found
    if (a.frame_count < MAX_KEYFRAMES) {
        a.frames[a.frame_count] = Keyframe{ .percent = percent };
        a.frame_count += 1;
    }
    return a;
}

/// Adds a property value to the current percentage (set by .at())
pub fn set(self: Animation, prop_type: AnimationType, val: f32) Animation {
    var a = self;
    // Find the frame matching current_percent and add to it
    for (0..a.frame_count) |i| {
        if (a.frames[i]) |*f| {
            if (f.percent == a.current_percent) {
                a.frames[i] = f.add(prop_type, val);
                break;
            }
        }
    }
    return a;
}

/// Adds a property with a specific unit
pub fn setUnit(self: Animation, prop_type: AnimationType, val: f32, unit: Unit) Animation {
    var a = self;
    for (0..a.frame_count) |i| {
        if (a.frames[i]) |*f| {
            if (f.percent == a.current_percent) {
                a.frames[i] = f.addUnit(prop_type, val, unit);
                break;
            }
        }
    }
    return a;
}
// NEW: Builder method for colors
pub fn setColor(self: Animation, prop_type: AnimationType, val: Color) Animation {
    var a = self;
    for (0..a.frame_count) |i| {
        if (a.frames[i]) |*f| {
            if (f.percent == a.current_percent) {
                a.frames[i] = f.addColor(prop_type, val);
                break;
            }
        }
    }
    return a;
}

// Add a property to animate
pub fn prop(self: Animation, prop_type: AnimationType, from_val: f32, to_val: f32) Animation {
    var a = self;
    if (a.property_count < MAX_PROPERTIES) {
        a.properties[a.property_count] = Property.init(prop_type, from_val, to_val);
        a.property_count += 1;
    }
    return a;
}

// Add a property with custom unit
pub fn propUnit(self: Animation, prop_type: AnimationType, from_val: f32, to_val: f32, unit: Unit) Animation {
    var a = self;
    if (a.property_count < MAX_PROPERTIES) {
        a.properties[a.property_count] = Property.init(prop_type, from_val, to_val).inUnit(unit);
        a.property_count += 1;
    }
    return a;
}

pub fn duration(self: Animation, milliseconds: u32) Animation {
    var a = self;
    a.duration_ms = milliseconds;
    return a;
}

pub fn delay(self: Animation, milliseconds: u32) Animation {
    var a = self;
    a.delay_ms = milliseconds;
    return a;
}

pub fn easing(self: Animation, value: Easing) Animation {
    var a = self;
    a.easing_fn = value;
    return a;
}

pub fn fill(self: Animation, value: FillMode) Animation {
    var a = self;
    a.fill_mode = value;
    return a;
}

pub fn dir(self: Animation, value: Direction) Animation {
    var a = self;
    a.direction = value;
    return a;
}

pub fn iterations(self: Animation, count: u32) Animation {
    var a = self;
    a.iteration_count = count;
    return a;
}

pub fn infinite(self: Animation) Animation {
    var a = self;
    a.iteration_count = null;
    return a;
}

// Convenience presets
pub fn fadeIn(name: []const u8) Animation {
    return init(name)
        .prop(.opacity, 0, 1)
        .fill(.forwards);
}

pub fn fadeOut(name: []const u8) Animation {
    return init(name)
        .prop(.opacity, 1, 0)
        .fill(.forwards);
}

pub fn slideInLeft(name: []const u8, distance: f32) Animation {
    return init(name)
        .prop(.translateX, -distance, 0)
        .prop(.opacity, 0, 1)
        .fill(.forwards);
}

pub fn slideInRight(name: []const u8, distance: f32) Animation {
    return init(name)
        .prop(.translateX, distance, 0)
        .prop(.opacity, 0, 1)
        .fill(.forwards);
}

pub fn slideInUp(name: []const u8, distance: f32) Animation {
    return init(name)
        .prop(.translateY, distance, 0)
        .prop(.opacity, 0, 1)
        .fill(.forwards);
}

pub fn slideInDown(name: []const u8, distance: f32) Animation {
    return init(name)
        .prop(.translateY, -distance, 0)
        .prop(.opacity, 0, 1)
        .fill(.forwards);
}

pub fn slideOutLeft(name: []const u8, distance: f32) Animation {
    return init(name)
        .prop(.translateX, 0, -distance)
        .prop(.opacity, 1, 0)
        .fill(.forwards);
}

pub fn slideOutRight(name: []const u8, distance: f32) Animation {
    return init(name)
        .prop(.translateX, 0, distance)
        .prop(.opacity, 1, 0)
        .fill(.forwards);
}

pub fn slideOutUp(name: []const u8, distance: f32) Animation {
    return init(name)
        .prop(.translateY, 0, -distance)
        .prop(.opacity, 1, 0)
        .fill(.forwards);
}

pub fn slideOutDown(name: []const u8, distance: f32) Animation {
    return init(name)
        .prop(.translateY, 0, distance)
        .prop(.opacity, 1, 0)
        .fill(.forwards);
}

pub fn zoomIn(name: []const u8) Animation {
    return init(name)
        .prop(.scale, 0, 1)
        .prop(.opacity, 0, 1)
        .fill(.forwards);
}

pub fn zoomOut(name: []const u8) Animation {
    return init(name)
        .prop(.scale, 1, 0)
        .prop(.opacity, 1, 0)
        .fill(.forwards);
}

pub fn spin(name: []const u8) Animation {
    return init(name)
        .prop(.rotate, 0, 360)
        .infinite();
}

pub fn pulse(name: []const u8) Animation {
    return init(name)
        .prop(.scale, 1, 1.05)
        .dir(.alternate)
        .infinite();
}

pub fn build(self: Animation) void {
    Vapor.animations.put(self._name, self) catch |err| {
        Vapor.println("Could not create animation {any}\n", .{err});
    };
}

// Examples:
test "Animation examples" {
    // Single property
    Animation.init("fadeOut")
        .prop(.opacity, 1, 0)
        .build();
    // Output:
    // @keyframes fadeOut {
    // from { opacity: 1; }
    // to { opacity: 0; }
    // }

    // Multiple transforms + opacity
    Animation.init("slideAndFade")
        .prop(.translateX, -50, 0)
        .prop(.opacity, 0, 1)
        .build();
    // Output:
    // @keyframes slideAndFade {
    // from { transform: translateX(-50px); opacity: 0; }
    // to { transform: translateX(0px); opacity: 1; }
    // }

    // Complex: scale + rotate + opacity
    Animation.init("zoomRotate")
        .prop(.scale, 0.5, 1)
        .prop(.rotate, -45, 0)
        .prop(.opacity, 0, 1)
        .build();
    // Output:
    // @keyframes zoomRotate {
    // from { transform: scale(0.5) rotate(-45deg); opacity: 0; }
    // to { transform: scale(1) rotate(0deg); opacity: 1; }
    // }

    // With filters
    Animation.init("blurIn")
        .prop(.blur, 10, 0)
        .prop(.opacity, 0, 1)
        .build();
    // Output:
    // @keyframes blurIn {
    // from { filter: blur(10px); opacity: 0; }
    // to { filter: blur(0px); opacity: 1; }
    // }
}

const AnimationId = u16; // supports 65k unique animations, plenty

const AnimationIntern = struct {
    allocator: Allocator,
    strings: std.array_list.Managed([]const u8),
    lookup: std.StringHashMap(AnimationId),
    ref_counts: std.array_list.Managed(u32),

    pub fn init(allocator: Allocator) AnimationIntern {
        return .{
            .allocator = allocator,
            .strings = std.array_list.Managed([]const u8).init(allocator),
            .lookup = std.StringHashMap(AnimationId).init(allocator),
            .ref_counts = std.array_list.Managed(u32).init(allocator),
        };
    }

    pub fn intern(self: *AnimationIntern, css: []const u8) !AnimationId {
        if (self.lookup.get(css)) |id| {
            self.ref_counts.items[id] += 1;
            return id;
        }

        const owned = try self.allocator.dupe(u8, css);
        const id: AnimationId = @intCast(self.strings.items.len);
        try self.strings.append(owned);
        try self.ref_counts.append(1);
        try self.lookup.put(owned, id);
        return id;
    }

    pub fn get(self: *AnimationIntern, id: AnimationId) ?[]const u8 {
        if (id >= self.strings.items.len) return null;
        return self.strings.items[id];
    }

    pub fn release(self: *AnimationIntern, id: AnimationId) void {
        if (id >= self.ref_counts.items.len) return;
        if (self.ref_counts.items[id] == 0) return;
        self.ref_counts.items[id] -= 1;
        // Optional: cleanup when ref_count hits 0
        // or batch cleanup periodically
    }
};

const PendingRemoval = struct {
    uuid: []const u8,
    node_index: u16,
    animation_id: AnimationId, // 2 bytes instead of duplicated string
    generation: u32, // for staleness detection
};

pub const RemovalQueue = struct {
    allocator: Allocator,
    items: std.array_list.Managed(PendingRemoval),
    animations: AnimationIntern,
    current_generation: u32 = 0,
    removals: std.array_list.Managed(u32),

    pub fn init(allocator: Allocator) void {
        removal_queue = .{
            .allocator = allocator,
            .items = std.array_list.Managed(PendingRemoval).init(allocator),
            .animations = AnimationIntern.init(allocator),
            .current_generation = 0,
            .removals = std.array_list.Managed(u32).init(allocator),
        };
    }

    pub fn enqueue(
        self: *RemovalQueue,
        node: *UINode,
        node_index: usize,
    ) !void {
        const has_exit_animation = node.animation_exit != null;

        const anim_id: AnimationId = if (has_exit_animation) blk: {
            const css_ptr = getExitAnimationStyle(node) orelse unreachable;
            const len = StyleCompiler.getAnimationLen();
            break :blk try self.animations.intern(css_ptr[0..len]);
        } else std.math.maxInt(AnimationId); // sentinel for "no animation"

        const handle: u32 = @intCast(self.items.items.len);
        try self.items.append(.{
            .uuid = node.uuid,
            .node_index = @intCast(node_index),
            .animation_id = anim_id,
            .generation = self.current_generation,
        });
        try self.removals.append(handle);
    }

    pub fn getAnimationCss(self: *RemovalQueue, handle: u32) ?[]const u8 {
        if (handle >= self.items.items.len) return null;
        const item = self.items.items[handle];
        if (item.animation_id == std.math.maxInt(AnimationId)) return null;
        return self.animations.get(item.animation_id);
    }

    pub fn getId(self: *RemovalQueue, handle: u32) ?[]const u8 {
        if (handle >= self.items.items.len) return null;
        const item = self.items.items[handle];
        return item.uuid;
    }

    pub fn release(self: *RemovalQueue, handle: u32) void {
        if (handle >= self.items.items.len) return;
        const item = self.items.items[handle];

        // Free the id string
        self.allocator.free(item.id_ptr[0..item.id_len]);

        // Decrement animation ref count
        if (item.animation_id != std.math.maxInt(AnimationId)) {
            self.animations.release(item.animation_id);
        }

        // Mark slot as free (or swap-remove if order doesn't matter)
        self.items.items[handle].id_len = 0; // tombstone
    }

    pub fn nextGeneration(self: *RemovalQueue) void {
        self.current_generation += 1;
    }

    pub fn clearRetainingCapacity(self: *RemovalQueue) void {
        self.items.clearRetainingCapacity();
        self.animations.strings.clearRetainingCapacity();
        self.animations.lookup.clearRetainingCapacity();
        self.animations.ref_counts.clearRetainingCapacity();
        self.current_generation = 0;
        self.removals.clearRetainingCapacity();
    }
};

pub var removal_queue: RemovalQueue = undefined;

export fn clearRemovalQueueRetainingCapacity() void {
    removal_queue.clearRetainingCapacity();
}

pub export fn removalCount() usize {
    return removal_queue.items.items.len;
}

pub export fn getRemovalAnimationPtr(handle: u32) ?[*]const u8 {
    const css = removal_queue.getAnimationCss(handle) orelse return null;
    return css.ptr;
}
//
pub export fn getRemovalAnimationLen(handle: u32) usize {
    const css = removal_queue.getAnimationCss(handle) orelse return 0;
    return css.len;
}

pub export fn getRemovalIdPtr(handle: u32) ?[*]const u8 {
    const id = removal_queue.getId(handle) orelse return null;
    return id.ptr;
}

pub export fn getRemovalIdLen(handle: u32) usize {
    const id = removal_queue.getId(handle) orelse return 0;
    return id.len;
}
