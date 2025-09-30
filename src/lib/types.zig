const std = @import("std");
const UINode = @import("UITree.zig").UINode;
const Fabric = @import("Fabric.zig");
pub const Transition = @import("Transition.zig").Transition;
pub const TransitionProperty = @import("Transition.zig").TransitionProperty;
const print = std.debug.print;
const ColorTheme = @import("constants/Color.zig");
const Animation = @import("Animation.zig");
pub const ElementType = @import("user_config").ElementType;
pub const ThemeTokens = @import("user_config").ThemeTokens;
pub const color_theme: ColorTheme = ColorTheme{};
const isMobile = @import("utils.zig").isMobile;
const Event = @import("Event.zig");

pub const TimingFunction = enum {
    linear,
    ease,
    ease_in,
    ease_out,
    ease_in_out,
    bounce,
    elastic,
};

// pub const ElementType = enum(u8) {
//     Rectangle,
//     Text,
//     Image,
//     FlexBox,
//     Input,
//     Button,
//     Block,
//     Box,
//     Header,
//     Svg,
//     Link,
//     EmbedLink,
//     List,
//     ListItem,
//     _If,
//     Hooks,
//     Layout,
//     Page,
//     Bind,
//     Dialog,
//     DialogBtnShow,
//     DialogBtnClose,
//     Draggable,
//     RedirectLink,
//     Select,
//     SelectItem,
//     CtxButton,
//     EmbedIcon,
//     Icon,
//     Label,
//     Form,
//     AllocText,
//     Table,
//     TableRow,
//     TableCell,
//     TableHeader,
//     TableBody,
//     TextArea,
//     Canvas,
//     SubmitCtxButton,
//     HooksCtx,
//     JsonEditor,
//     HtmlText,
//     Code,
//     Span,
//     LazyImage,
//     Intersection,
//     PreImage,
//     TextGradient,
//     Gradient,
//     Virtualize,
//     ButtonCycle,
// };

pub fn switchColorTheme() void {
    switch (color_theme.theme) {
        .dark => color_theme.theme = .light,
        .light => color_theme.theme = .dark,
    }
}

pub const Direction = enum(u8) {
    column = 0,
    row = 1,
};

pub const SizingType = enum(u8) {
    fit = 0,
    grow = 1,
    percent = 2,
    fixed = 3,
    elastic = 4,
    elastic_percent = 5,
    none = 6,
    clamp_px = 7,
    clamp_percent = 8,
    min_max_vp = 9,
};

const MinMax = struct {
    min: f32 = 0,
    max: f32 = 0,

    pub fn eql(self: MinMax, other: MinMax) bool {
        return self.min == other.min and self.max == other.max;
    }
};

const Clamp = struct {
    min: f32 = 0,
    max: f32 = 0,
    preferred: f32 = 0,

    pub fn eql(self: MinMax, other: MinMax) bool {
        return self.min == other.min and self.max == other.max;
    }
};

// Make it a tagged union by adding an enum
pub const SizingConstraint = union(enum) {
    minmax: MinMax,
    percent: MinMax,
    clamp_percent: Clamp,
    clamp_px: Clamp,
    min_max_vp: MinMax,

    pub fn eql(self: SizingConstraint, other: SizingConstraint) bool {
        if (std.meta.activeTag(self) != std.meta.activeTag(other)) return false;

        return switch (self) {
            .min_max_vp => |mm| mm.eql(other.min_max_vp),
            .minmax => |mm| mm.eql(other.minmax),
            .percent => |mm| mm.eql(other.percent),
            .clamp_px => |mm| mm.eql(other.clamp_px),
            .clamp_percent => |mm| mm.eql(other.clamp_percent),
        };
    }
};

pub const Size = struct {
    width: Sizing = .{},
    height: Sizing = .{},
    pub const full = Size{ .width = .percent(100), .height = .percent(100) };
    pub fn square_px(size: f32) Size {
        return .{
            .width = .px(size),
            .height = .px(size),
        };
    }
    pub fn square_percent(size: f32) Size {
        return .{
            .width = .percent(size),
            .height = .percent(size),
        };
    }
    /// Creates a height sizing
    pub fn h(size: Sizing) Size {
        return .{
            .height = size,
        };
    }
    /// Creates a width sizing
    pub fn w(size: Sizing) Size {
        return .{
            .width = size,
        };
    }
    /// Creates a height and width sizing
    pub fn hw(height: Sizing, width: Sizing) Size {
        return .{
            .width = width,
            .height = height,
        };
    }
    /// Creates a height and width sizing with pixel values
    pub fn hw_px(height: f32, width: f32) Size {
        return .{
            .width = .px(width),
            .height = .px(height),
        };
    }
    /// Creates a height and width sizing with percent values
    pub fn hw_percent(height: f32, width: f32) Size {
        return .{
            .width = .percent(width),
            .height = .percent(height),
        };
    }
};

pub const Sizing = struct {
    size: SizingConstraint = .{ .minmax = .{} },
    type: SizingType = .none,

    pub const grow = Sizing{ .type = .grow, .size = .{ .minmax = .{ .min = 0, .max = 0 } } };
    pub const fit = Sizing{ .type = .fit, .size = .{ .minmax = .{ .min = 0, .max = 0 } } };

    pub fn px(size: f32) Sizing {
        return .{ .type = .fixed, .size = .{ .minmax = .{
            .min = size,
            .max = size,
        } } };
    }

    pub fn elastic(min: f32, max: f32) Sizing {
        return .{ .type = .elastic, .size = .{ .minmax = .{
            .min = min,
            .max = max,
        } } };
    }

    pub fn percent(size: f32) Sizing {
        return .{ .type = .percent, .size = .{ .minmax = .{
            .min = size,
            .max = size,
        } } };
    }

    pub fn @"%"(size: f32) Sizing {
        return .{ .type = .percent, .size = .{ .minmax = .{
            .min = size,
        } } };
    }

    pub fn elastic_percent(min: f32, max: f32) Sizing {
        return .{ .type = .elastic_percent, .size = .{ .percent = .{
            .min = min,
            .max = max,
        } } };
    }

    pub fn clamp_px(min: f32, boundary: f32, max: f32) Sizing {
        return .{ .type = .clamp_px, .size = .{ .clamp_px = .{
            .min = min,
            .boundary = boundary,
            .max = max,
        } } };
    }

    pub fn min_max_vp(min: f32, max: f32) Sizing {
        return .{ .type = .min_max_vp, .size = .{ .min_max_vp = .{
            .min = min,
            .max = max,
        } } };
    }

    pub fn mobile_desktop_percent(mobile: f32, desktop: f32) Sizing {
        if (isMobile()) {
            return .{ .type = .percent, .size = .{ .minmax = .{
                .min = mobile,
                .max = mobile,
            } } };
        }
        return .{ .type = .percent, .size = .{ .minmax = .{
            .min = desktop,
            .max = desktop,
        } } };
    }

    pub fn mobile_desktop(mobile: Sizing, desktop: Sizing) Sizing {
        if (isMobile()) {
            return mobile;
        } else {
            return desktop;
        }
    }

    pub fn clamp_percent(min: f32, preferred: f32, max: f32) Sizing {
        return .{ .type = .clamp_percent, .size = .{ .clamp_percent = .{
            .min = min,
            .preferred = preferred,
            .max = max,
        } } };
    }

    // Add custom equality function for Sizing
    pub fn eql(self: Sizing, other: Sizing) bool {
        return self.type == other.type and self.size.eql(other.size);
    }
};

pub const PosType = enum(u8) {
    fit = 0,
    grow = 1,
    percent = 2,
    fixed = 3,
};

pub const Pos = struct {
    type: PosType = .fit,
    value: f32 = 0,

    pub const grow = Pos{ .type = .grow, .value = 0 };
    pub fn px(pos: f32) Pos {
        return .{ .type = .fixed, .value = pos };
    }

    pub fn percent(pos: f32) Pos {
        return .{ .type = .percent, .value = pos };
    }
};

pub const Rgba = struct { r: u8 = 0, g: u8 = 0, b: u8 = 0, a: u8 = 0 };
pub const Color = union(enum) {
    Literal: Rgba, // A hardcoded, specific color
    Thematic: ThemeTokens, // A token name, like "primaryText" or "accentColor"

    pub const transparent = Color{ .Literal = .{ .r = 0, .g = 0, .b = 0, .a = 0 } };
    pub const white = Color{ .Literal = .{ .r = 255, .g = 255, .b = 255, .a = 255 } };
    pub const black = Color{ .Literal = .{ .r = 0, .g = 0, .b = 0, .a = 255 } };
    pub const red = Color{ .Literal = .{ .r = 255, .g = 0, .b = 0, .a = 255 } };
    pub const green = Color{ .Literal = .{ .r = 0, .g = 255, .b = 0, .a = 255 } };
    pub const blue = Color{ .Literal = .{ .r = 0, .g = 0, .b = 255, .a = 255 } };
    pub const yellow = Color{ .Literal = .{ .r = 255, .g = 255, .b = 0, .a = 255 } };
    pub const cyan = Color{ .Literal = .{ .r = 0, .g = 255, .b = 255, .a = 255 } };
    pub const magenta = Color{ .Literal = .{ .r = 255, .g = 0, .b = 255, .a = 255 } };

    pub fn palette(thematic: ThemeTokens) Color {
        return .{ .Thematic = thematic };
    }
    pub fn hex(hex_str: []const u8) Color {
        const rgba_arr = Fabric.hexToRgba(hex_str);
        return .{ .Literal = .{
            .r = rgba_arr[0],
            .g = rgba_arr[1],
            .b = rgba_arr[2],
            .a = rgba_arr[3],
        } };
    }

    // Function to darken a hex color string by a percentage and return Color struct
    pub fn darken(hex_str: []const u8, percentage: f32) Color {
        if (percentage < 0.0 or percentage > 100.0) {
            @panic("Percentage must be between 0 and 100");
        }

        const rgba_arr = Fabric.hexToRgba(hex_str);
        const factor = 1.0 - (percentage / 100.0);

        return .{
            .Literal = .{
                .r = @intFromFloat(@as(f32, @floatFromInt(rgba_arr[0])) * factor),
                .g = @intFromFloat(@as(f32, @floatFromInt(rgba_arr[1])) * factor),
                .b = @intFromFloat(@as(f32, @floatFromInt(rgba_arr[2])) * factor),
                .a = rgba_arr[3], // Keep alpha unchanged
            },
        };
    }

    // // Function to lighten a hex color string by a percentage and return Color struct
    pub fn lighten(hex_str: []const u8, percentage: f32) Color {
        if (percentage < 0.0 or percentage > 100.0) {
            @panic("Percentage must be between 0 and 100");
        }

        const rgba_arr = Fabric.hexToRgba(hex_str);
        const factor = percentage / 100.0;

        return .{
            .Literal = .{
                .r = @intFromFloat(@as(f32, @floatFromInt(rgba_arr[0])) + (@as(f32, 255.0) - @as(f32, @floatFromInt(rgba_arr[0]))) * factor),
                .g = @intFromFloat(@as(f32, @floatFromInt(rgba_arr[1])) + (@as(f32, 255.0) - @as(f32, @floatFromInt(rgba_arr[1]))) * factor),
                .b = @intFromFloat(@as(f32, @floatFromInt(rgba_arr[2])) + (@as(f32, 255.0) - @as(f32, @floatFromInt(rgba_arr[2]))) * factor),
                .a = rgba_arr[3], // Keep alpha unchanged
            },
        };
    }
    pub fn rgba(r: u8, g: u8, b: u8, a: u8) Color {
        return .{ .Literal = .{
            .r = r,
            .g = g,
            .b = b,
            .a = a,
        } };
    }
    pub fn rgb(r: u8, g: u8, b: u8) Color {
        return .{ .Literal = .{
            .r = r,
            .g = g,
            .b = b,
            .a = 255,
        } };
    }
    pub fn transparentizeHex(hex_str: []const u8, alpha: u8) Color {
        const rgba_arr = Fabric.transparentize(hex_str, alpha);
        return .{ .Literal = .{
            .r = rgba_arr[0],
            .g = rgba_arr[1],
            .b = rgba_arr[2],
            .a = rgba_arr[3],
        } };
    }
};

pub const Padding = struct {
    top: u32 = 0,
    bottom: u32 = 0,
    left: u32 = 0,
    right: u32 = 0,
    pub fn all(size: u32) Padding {
        return Padding{
            .top = size,
            .bottom = size,
            .left = size,
            .right = size,
        };
    }
    pub fn tblr(top: u32, bottom: u32, left: u32, right: u32) Padding {
        return Padding{
            .top = top,
            .bottom = bottom,
            .left = left,
            .right = right,
        };
    }

    pub fn tb(top: u32, bottom: u32) Padding {
        return Padding{
            .top = top,
            .bottom = bottom,
            .left = 0,
            .right = 0,
        };
    }
    pub fn lr(left: u32, right: u32) Padding {
        return Padding{
            .top = 0,
            .bottom = 0,
            .left = left,
            .right = right,
        };
    }
    pub fn horizontal(size: u32) Padding {
        return Padding{
            .top = 0,
            .bottom = 0,
            .left = size,
            .right = size,
        };
    }
    pub fn vertical(size: u32) Padding {
        return Padding{
            .top = size,
            .bottom = size,
            .left = 0,
            .right = 0,
        };
    }
    pub fn t(size: u32) Padding {
        return Padding{
            .top = size,
            .bottom = 0,
            .left = 0,
            .right = 0,
        };
    }
    pub fn l(size: u32) Padding {
        return Padding{
            .top = 0,
            .bottom = 0,
            .left = size,
            .right = 0,
        };
    }
    pub fn r(size: u32) Padding {
        return Padding{
            .top = 0,
            .bottom = 0,
            .left = 0,
            .right = size,
        };
    }
    pub fn b(size: u32) Padding {
        return Padding{
            .top = 0,
            .bottom = size,
            .left = 0,
            .right = 0,
        };
    }
};

pub const Margin = struct {
    top: u32 = 0,
    bottom: u32 = 0,
    left: u32 = 0,
    right: u32 = 0,
    pub fn all(size: u32) Margin {
        return Margin{
            .top = size,
            .bottom = size,
            .left = size,
            .right = size,
        };
    }
    pub fn tblr(top: u32, bottom: u32, left: u32, right: u32) Margin {
        return Margin{
            .top = top,
            .bottom = bottom,
            .left = left,
            .right = right,
        };
    }
    pub fn tb(top: u32, bottom: u32) Margin {
        return Margin{
            .top = top,
            .bottom = bottom,
        };
    }
    pub fn br(bottom: u32, right: u32) Margin {
        return Margin{
            .bottom = bottom,
            .right = right,
        };
    }
    pub fn lr(left: u32, right: u32) Margin {
        return Margin{
            .left = left,
            .right = right,
        };
    }
    pub fn t(top: u32) Margin {
        return Margin{
            .top = top,
        };
    }
    pub fn b(bottom: u32) Margin {
        return Margin{
            .bottom = bottom,
        };
    }
    pub fn l(left: u32) Margin {
        return Margin{
            .left = left,
        };
    }
    pub fn r(right: u32) Margin {
        return Margin{
            .right = right,
        };
    }
};

pub const Overflow = enum(u8) {
    scroll = 0,
    hidden = 1,
};

pub const Scroll = struct {
    x: ?Overflow = null,
    y: ?Overflow = null,

    pub fn none() Scroll {
        return .{ .x = .hidden, .y = .hidden };
    }

    pub fn none_x() Scroll {
        return .{ .x = .hidden };
    }

    pub fn none_y() Scroll {
        return .{ .y = .hidden };
    }
    pub fn scroll() Scroll {
        return .{ .x = .scroll, .y = .scroll };
    }

    pub fn scroll_x() Scroll {
        return .{ .x = .scroll };
    }

    pub fn scroll_y() Scroll {
        return .{ .y = .scroll };
    }
};

pub const BorderRadius = struct {
    top_left: f32 = 0,
    top_right: f32 = 0,
    bottom_left: f32 = 0,
    bottom_right: f32 = 0,
    fn default() BorderRadius {
        return BorderRadius{
            .top_left = 0,
            .top_right = 0,
            .bottom_left = 0,
            .bottom_right = 0,
        };
    }
    pub fn all(radius: f32) BorderRadius {
        return BorderRadius{
            .top_left = radius,
            .top_right = radius,
            .bottom_left = radius,
            .bottom_right = radius,
        };
    }
    pub fn specific(top_left: f32, top_right: f32, bottom_left: f32, bottom_right: f32) BorderRadius {
        return BorderRadius{
            .top_left = top_left,
            .top_right = top_right,
            .bottom_left = bottom_left,
            .bottom_right = bottom_right,
        };
    }
    pub fn top_bottom(top_radius: f32, bottom_radius: f32) BorderRadius {
        return BorderRadius{
            .top_left = top_radius,
            .top_right = top_radius,
            .bottom_left = bottom_radius,
            .bottom_right = bottom_radius,
        };
    }
    pub fn bottom(radius: f32) BorderRadius {
        return BorderRadius{
            .top_left = 0,
            .top_right = 0,
            .bottom_left = radius,
            .bottom_right = radius,
        };
    }
    pub fn top(radius: f32) BorderRadius {
        return BorderRadius{
            .top_left = radius,
            .top_right = radius,
            .bottom_left = 0,
            .bottom_right = 0,
        };
    }
    pub fn left_right(left: f32, right: f32) BorderRadius {
        return BorderRadius{
            .top_left = left,
            .top_right = right,
            .bottom_left = left,
            .bottom_right = right,
        };
    }
};

pub const Shadow = struct {
    top: f32 = 0,
    left: f32 = 0,
    blur: f32 = 0,
    spread: f32 = 0,
    color: Color = .{ .Literal = .{} },
};

pub const Border = struct {
    top: f32 = 0,
    bottom: f32 = 0,
    left: f32 = 0,
    right: f32 = 0,
    pub fn default() Border {
        return Border{
            .top = 0,
            .bottom = 0,
            .left = 0,
            .right = 0,
        };
    }
    pub fn all(thickness: f32) Border {
        return Border{
            .top = thickness,
            .bottom = thickness,
            .left = thickness,
            .right = thickness,
        };
    }
    pub fn specific(left: f32, top: f32, right: f32, bottom: f32) Border {
        return Border{
            .top = top,
            .bottom = bottom,
            .left = left,
            .right = right,
        };
    }

    pub fn tb(thickness: f32) Border {
        return Border{
            .top = thickness,
            .bottom = thickness,
            .left = 0,
            .right = 0,
        };
    }

    pub fn b(thickness: f32) Border {
        return Border{
            .top = 0,
            .bottom = thickness,
            .left = 0,
            .right = 0,
        };
    }

    pub fn t(thickness: f32) Border {
        return Border{
            .top = thickness,
            .bottom = 0,
            .left = 0,
            .right = 0,
        };
    }

    pub fn l(thickness: f32) Border {
        return Border{
            .top = 0,
            .bottom = 0,
            .left = thickness,
            .right = 0,
        };
    }

    pub fn r(thickness: f32) Border {
        return Border{
            .top = 0,
            .bottom = 0,
            .left = 0,
            .right = thickness,
        };
    }
};

pub const Alignment = enum(u8) {
    center = 0,
    top = 1,
    bottom = 2,
    start = 3,
    end = 4,
    between = 5,
    even = 6,
};

pub const BoundingBox = struct {
    /// X coordinate of the top-left corner
    x: f32,
    /// Y coordinate of the top-left corner
    y: f32,
    /// Width of the bounding box
    width: f32,
    /// Height of the bounding box
    height: f32,
};

pub const FloatType = enum(u8) {
    right,
    left,
    top,
    bottom,
};

pub const PositionType = enum(u8) {
    relative = 0,
    absolute = 1,
    fixed = 2,
    sticky = 3,
};

pub const Position = struct {
    right: ?Pos = null,
    left: ?Pos = null,
    top: ?Pos = null,
    bottom: ?Pos = null,
    type: PositionType = .relative,

    pub const nav = Position{
        .left = .px(0),
        .right = .px(0),
        .type = .fixed,
        .top = .px(0),
    };

    /// Creates a top bottom left right position
    pub fn tblr(top: Pos, bottom: Pos, left: Pos, right: Pos, pos_type: PositionType) Position {
        return .{
            .top = top,
            .bottom = bottom,
            .left = left,
            .right = right,
            .type = pos_type,
        };
    }
    /// Creates a top bottom position
    pub fn tb(top: Pos, bottom: Pos, pos_type: PositionType) Position {
        return .{
            .top = top,
            .bottom = bottom,
            .type = pos_type,
        };
    }
    /// Creates a left right position
    pub fn lr(left: Pos, right: Pos, pos_type: PositionType) Position {
        return .{
            .left = left,
            .right = right,
            .type = pos_type,
        };
    }
    /// Creates a bottom right position
    pub fn br(bottom: Pos, right: Pos, pos_type: PositionType) Position {
        return .{
            .bottom = bottom,
            .right = right,
            .type = pos_type,
        };
    }
    /// Creates a top left position
    pub fn tl(top: Pos, left: Pos, pos_type: PositionType) Position {
        return .{
            .top = top,
            .left = left,
            .type = pos_type,
        };
    }
    /// Creates a bottom left position
    pub fn bl(bottom: Pos, left: Pos, pos_type: PositionType) Position {
        return .{
            .bottom = bottom,
            .left = left,
            .type = pos_type,
        };
    }
    /// Creates a top right position
    pub fn tr(top: Pos, right: Pos, pos_type: PositionType) Position {
        return .{
            .top = top,
            .right = right,
            .type = pos_type,
        };
    }
};

pub const TransformType = enum {
    none,
    translateX,
    translateY,
    scale,
    scaleY,
    scaleX,
    rotate,
    rotateX,
    rotateY,
    rotateXYZ,
};

pub const Transform = struct {
    scale_size: f32 = 1,
    dist: f32 = 0,
    percent: f32 = 0,
    deg: f32 = 0,
    x: f32 = 0,
    y: f32 = 0,
    z: f32 = 0,
    type: TransformType = .none,
    opacity: ?u32 = null,

    pub fn scale() Transform {
        return .{ .scale_size = 1.05, .type = .scale };
    }

    pub fn rotate(deg: f32) Transform {
        return .{ .deg = deg, .type = .rotate };
    }

    pub fn rotateX(deg: f32) Transform {
        return .{ .deg = deg, .type = .rotateX };
    }

    pub fn rotateY(deg: f32) Transform {
        return .{ .deg = deg, .type = .rotateY };
    }

    pub fn rotateXYZ(x: f32, y: f32, z: f32) Transform {
        return .{ .x = x, .y = y, .z = z, .type = .rotateXYZ };
    }
};

pub const Focus = struct {
    position: ?Position = null,
    display: ?FlexType = null,
    direction: ?Direction = null,
    width: ?Sizing = null,
    height: ?Sizing = null,
    font_size: ?i32 = null,
    letter_spacing: ?i32 = null,
    line_height: ?i32 = null,
    font_weight: ?usize = null,
    border_radius: ?BorderRadius = null,
    border_thickness: ?Border = null,
    border_color: ?Color = null,
    text_color: ?Color = null,
    padding: ?Padding = null,
    child_alignment: ?struct { x: Alignment, y: Alignment } = null,
    child_gap: u16 = 0,
    background: ?Color = null,
    shadow: Shadow = .{},
    transform: Transform = .{},
    opacity: f32 = 1,
    child_style: ?ChildStyle = null,
};

// pub const Hover = struct {
//     position: ?Position = null,
//     display: ?FlexType = null,
//     direction: ?Direction = null,
//     width: ?Sizing = null,
//     height: ?Sizing = null,
//     font_size: ?i32 = null,
//     letter_spacing: ?i32 = null,
//     line_height: ?i32 = null,
//     font_weight: ?usize = null,
//
//     border_radius: ?BorderRadius = null,
//     border_thickness: ?Border = null,
//     border_color: ?Color = null,
//
//     border: ?struct {
//         thickness: Border = .all(1),
//         color: ?Color = null,
//         radius: ?BorderRadius = null,
//     } = null,
//
//     text_color: ?Color = null,
//     padding: ?Padding = null,
//     child_alignment: ?struct { x: Alignment, y: Alignment } = null,
//     child_gap: u16 = 0,
//     background: ?Color = null,
//     shadow: Shadow = .{},
//     transform: Transform = .{},
//     opacity: f32 = 1,
//     child_style: ?ChildStyle = null,
// };

pub const Hover = struct {
    position: ?Position = null,
    // display: ?FlexType = null,
    // direction: ?Direction = null,

    /// Size configuration for the element
    size: ?Size = null,

    font_size: ?i32 = null,
    letter_spacing: ?i32 = null,
    line_height: ?i32 = null,
    font_weight: ?usize = null,

    border: ?struct {
        thickness: Border = .all(1),
        color: ?Color = null,
        radius: ?BorderRadius = null,
    } = null,

    border_radius: ?BorderRadius = null,
    border_thickness: ?Border = null,
    border_color: ?Color = null,

    text_color: ?Color = null,
    padding: ?Padding = null,

    /// External spacing configuration
    margin: ?Margin = .{},

    // child_alignment: ?struct { x: Alignment, y: Alignment } = null,
    child_gap: u16 = 0,
    background: ?Color = null,
    shadow: Shadow = .{},
    transform: Transform = .{},
    // opacity: f32 = 1,
    child_style: ?ChildStyle = null,
};

pub const CheckMark = struct {
    position: ?Position = null,
    display: ?FlexType = null,
    direction: ?Direction = null,
    width: ?Sizing = null,
    height: ?Sizing = null,
    font_size: ?i32 = null,
    letter_spacing: ?i32 = null,
    line_height: ?i32 = null,
    font_weight: ?usize = null,
    border_radius: ?BorderRadius = null,
    border_thickness: ?Border = null,
    border_color: ?Color = null,
    text_color: ?Color = null,
    padding: ?Padding = null,
    child_alignment: ?struct { x: Alignment, y: Alignment } = null,
    child_gap: u16 = 0,
    background: ?Color = null,
    shadow: Shadow = .{},
    transform: Transform = .{},
    opacity: f32 = 1,
    child_style: ?ChildStyle = null,
};

pub const TextColor: [4]u8 = .{ 0, 0, 0, 255 };

pub const Dim = struct {
    type: SizingType = .fit,
    pub const grow = Sizing{ .type = .grow, .size = .{ .minmax = .{ .min = 0, .max = 0 } } };
    pub const fit = Sizing{ .type = .fit, .size = .{ .minmax = .{ .min = 0, .max = 0 } } };
    pub fn fixed(size: f32) Sizing {
        return .{ .type = .fixed, .size = .{ .minmax = .{
            .min = size,
            .max = size,
        } } };
    }
    pub fn elastic(min: f32, max: f32) Sizing {
        return .{ .type = .elastic, .size = .{ .minmax = .{
            .min = min,
            .max = max,
        } } };
    }
};

pub const TextDecoration = enum(u8) {
    none = 0,
    overline = 1,
    underline = 2,
    inherit = 3,
    initial = 4,
    revert = 5,
    unset = 6,
};

pub const WhiteSpace = enum(u8) {
    normal = 0, // Collapses whitespace and breaks on necessary
    nowrap = 1, // Collapses whitespace but prevents breaking
    pre = 2, // Preserves whitespace and breaks on newlines
    pre_wrap = 3, // Preserves whitespace and breaks as needed
    pre_line = 4, // Collapses whitespace but preserves line breaks
    break_spaces = 5, // Like pre-wrap but also breaks at spaces
    inherit = 6, // Inherits from parent
    initial = 7, // Default value
    revert = 8, // Reverts to inherited value
    unset = 9, // Resets to inherited value or initial
};

// Enum definition for CSS list-style-type property
pub const ListStyle = enum(u8) {
    none = 0, // No bullet or marker
    disc = 1, // Filled circle (default for unordered lists)
    circle = 2, // Open circle
    square = 3, // Square marker
    decimal = 4, // Decimal numbers (default for ordered lists)
    decimal_leading_zero = 5, // Decimal numbers with a leading zero (e.g. 01, 02, 03, ...)
    lower_roman = 6, // Lowercase roman numerals (i, ii, iii, ...)
    upper_roman = 7, // Uppercase roman numerals (I, II, III, ...)
    lower_alpha = 8, // Lowercase alphabetic (a, b, c, ...)
    upper_alpha = 9, // Uppercase alphabetic (A, B, C, ...)
    lower_greek = 10, // Lowercase Greek letters (α, β, γ, ...)
    armenian = 11, // Armenian numbering
    georgian = 12, // Georgian numbering
    inherit = 13, // Inherits from parent element
    initial = 14, // Resets to the default value
    revert = 15, // Reverts to the inherited value if explicitly changed
    unset = 16, // Resets to inherited or initial value
};

pub const Outline = enum(u8) {
    none = 0, // No outline
    auto = 1, // Default outline (typically browser-specific)
    dotted = 2, // Dotted outline
    dashed = 3, // Dashed outline
    solid = 4, // Solid outline
    double = 5, // Two parallel solid lines
    groove = 6, // 3D grooved effect
    ridge = 7, // 3D ridged effect
    inset = 8, // 3D inset effect
    outset = 9, // 3D outset effect
    inherit = 10, // Inherits from the parent element
    initial = 11, // Resets to the default value
    revert = 12, // Reverts to the inherited value if explicitly changed
    unset = 13, // Resets to inherited or initial value
};

pub const FlexType = enum(u8) {
    Flex = 0, // "flex"
    Center = 1,
    Stack = 2, // "inline-flex"
    Flow = 3, // "inherit"
    // Initial = 3, // "initial"
    // Revert = 4, // "revert"
    // Unset = 5, // "unset"
    // InlineBlock = 7, // "inline-block"
    // Inline = 8, // "inline-flex"
    None = 4, // "centers the child content"
    CenterStack = 5, // "centers the child content"
};

// Enum definition for flex-wrap property
pub const FlexWrap = enum(u8) {
    nowrap = 0, // Single-line, no wrapping
    wrap = 1, // Multi-line, wrapping if needed
    wrap_reverse = 2, // Multi-line, reverse wrapping direction
    inherit = 3, // Inherits from parent
    initial = 4, // Default value
    revert = 5, // Reverts to inherited value
    unset = 6, // Resets to inherited value or initial
};

pub const KeyFrame = struct {
    tag: []const u8,
    from: Transform = .{},
    to: Transform = .{},
};
const AnimDir = enum {
    normal,
    reverse,
    forwards,
};

const Iteration = struct {
    iter_count: u32 = 1,
    pub fn infinite() Iteration {
        return .{
            .iter_count = 0,
        };
    }
    pub fn count(c: u32) Iteration {
        return .{
            .iter_count = c,
        };
    }
};

pub const AnimationType = struct {
    tag: []const u8,
    delay: f32 = 0,
    direction: AnimDir = .normal,
    duration: f32 = 0,
    iteration_count: Iteration = .count(1),
    timing_function: TimingFunction = .ease,
};

pub const ChildStyle = struct {
    style_id: []const u8,
    display: ?FlexType = null,
    position: ?Position = null,
    direction: Direction = .row,
    background: ?Color = null,
    width: ?Sizing = null,
    height: ?Sizing = null,
    font_size: ?i32 = null,
    letter_spacing: ?i32 = null,
    line_height: ?i32 = null,
    font_weight: ?usize = null,
    border_radius: ?BorderRadius = null,
    border_thickness: ?Border = null,
    border_color: ?Color = null,
    text_color: ?Color = null,
    padding: ?Padding = null,
    margin: ?Margin = null,
    overflow: ?Overflow = null,
    overflow_x: ?Overflow = null,
    overflow_y: ?Overflow = null,
    child_alignment: ?struct { x: Alignment, y: Alignment } = null,
    child_gap: u32 = 0,
    flex_shrink: ?u32 = null,
    font_family_file: []const u8 = "",
    font_family: []const u8 = "",
    opacity: f32 = 1,
    text_decoration: ?TextDecoration = null,
    shadow: Shadow = .{},
    white_space: ?WhiteSpace = null,
    flex_wrap: ?FlexWrap = null,
    key_frame: ?KeyFrame = null,
    key_frames: ?[]const KeyFrame = null,
    animation: ?Animation.Specs = null,
    z_index: ?f32 = null,
    list_style: ?ListStyle = null,
    blur: ?u32 = null,
    outline: ?Outline = null,
    transition: ?Transition = null,
    show_scrollbar: bool = true,
    btn_id: u32 = 0,
    dialog_id: ?[]const u8 = null,
    accent_color: ?[4]u8 = null,
};

pub const Cursor = enum {
    pointer,
    help,
    grab,
    zoom_in,
    zoom_out,
};

pub const Appearance = enum(u8) {
    none = 0, // Remove default styling completely
    auto = 1, // Default browser styling
    button = 2, // Style as a button
    textfield = 3, // Style as a text input field
    menulist = 4, // Style as a dropdown menu
    searchfield = 5, // Style as a search input
    textarea = 6, // Style as a multiline text area
    checkbox = 7, // Style as a checkbox
    radio = 8, // Style as a radio button
    inherit = 9, // Inherit from parent
    initial = 10, // Default value
    revert = 11, // Revert to inherited value
    unset = 12, // Reset to inherited value or initial
};

pub const BoxSizing = enum(u8) {
    content_box = 0, // Default CSS box model
    border_box = 1, // Alternative CSS box model (padding and border included in width/height)
    padding_box = 2, // Experimental value (width/height includes content and padding)
    inherit = 3, // Inherits from parent
    initial = 4, // Default value
    revert = 5, // Reverts to inherited value
    unset = 6, // Resets to inherited value or initial
};

pub const TransformOrigin = enum(u8) {
    top = 0,
    bottom = 1,
    right = 2,
    left = 3,
};

pub const Layout = struct {
    x: Alignment = .start,
    y: Alignment = .start,
    pub const flex = Layout{};
    pub const center = Layout{ .x = .center, .y = .center };
    pub const top_center = Layout{ .x = .center, .y = .start };
    pub const left_center = Layout{ .x = .start, .y = .center };
    pub const right_center = Layout{ .x = .end, .y = .center };
    pub const bottom_center = Layout{ .x = .center, .y = .end };
    pub const top_right = Layout{ .x = .end, .y = .start };
    pub const top_left = Layout{ .x = .start, .y = .start };
    pub const bottom_right = Layout{ .x = .end, .y = .end };
    pub const bottom_left = Layout{ .x = .start, .y = .end };
    pub const x_even = Layout{ .x = .even, .y = .start };
    pub const x_even_center = Layout{ .x = .even, .y = .center };
    pub const y_even = Layout{ .x = .start, .y = .even };
    pub const y_even_center = Layout{ .x = .center, .y = .even };
    pub const x_between_center = Layout{ .x = .between, .y = .center };
    pub const y_between_center = Layout{ .x = .center, .y = .between };
};

const BorderGrouped = struct {
    thickness: Border = .all(1),
    color: ?Color = .hex("#000000"),
    radius: ?BorderRadius = null,

    pub fn solid(thickness: Border, color: Color, radius: BorderRadius) BorderGrouped {
        return .{
            .thickness = thickness,
            .color = color,
            .radius = radius,
        };
    }

    pub fn simple(color: Color) BorderGrouped {
        return .{ .color = color }; // Uses default thickness = .all(1)
    }

    pub fn thin(color: Color) BorderGrouped {
        return .{ .thickness = .all(1), .color = color };
    }

    pub fn thick(color: Color) BorderGrouped {
        return .{ .thickness = .all(2), .color = color };
    }

    // Just thickness, use default color
    pub fn width(thickness: Border) BorderGrouped {
        return .{ .thickness = thickness };
    }

    // Rounded variants (common radius values)
    pub fn rounded(color: Color) BorderGrouped {
        return .{ .color = color, .radius = .all(4) };
    }

    pub fn pill(color: Color) BorderGrouped {
        return .{ .color = color, .radius = .all(999) }; // Large radius for pill shape
    }

    // Side-specific shortcuts
    pub fn bottom(color: Color) BorderGrouped {
        return .{ .thickness = .b(1), .color = color };
    }

    pub fn l(thickness: f32, color: Color) BorderGrouped {
        return .{ .thickness = .l(thickness), .color = color };
    }

    pub fn r(thickness: f32, color: Color) BorderGrouped {
        return .{ .thickness = .l(thickness), .color = color };
    }

    pub fn tb(color: Color) BorderGrouped {
        return .{ .thickness = .tb(1), .color = color };
    }

    pub fn top(color: Color) BorderGrouped {
        return .{ .thickness = .t(1), .color = color };
    }

    // Zero/none helper
    pub fn none() BorderGrouped {
        return .{ .thickness = .all(0) };
    }
};

const FontParams = struct {
    _size: i32,
    _weight: ?usize = null,
    _color: ?Color = null,
    pub fn size(font_size: i32) FontParams {
        return .{
            ._size = font_size,
        };
    }
    pub fn weight(font_weight: ?usize) FontParams {
        return .{
            ._weight = font_weight,
        };
    }

    pub fn color(font_color: ?Color) FontParams {
        return .{
            ._color = font_color,
        };
    }
    pub fn all(font_size: i32, font_weight: ?usize, font_color: ?Color) FontParams {
        return .{
            ._size = font_size,
            ._weight = font_weight,
            ._color = font_color,
        };
    }
    pub fn size_weight(font_size: i32, font_weight: ?usize) FontParams {
        return .{
            ._size = font_size,
            ._weight = font_weight,
        };
    }
    pub fn size_color(font_size: i32, font_color: ?Color) FontParams {
        return .{
            ._size = font_size,
            ._color = font_color,
        };
    }
};

pub const Visual = struct {
    /// Color color as RGBA array [red, green, blue, alpha] (0-255 each)
    /// Default: transparent black
    background: ?Color = null,

    /// Font size in pixels
    font_size: ?i32 = null,

    /// Letter spacing in pixels (can be negative for tighter spacing)
    letter_spacing: ?i32 = null,

    /// Line height in pixels for text content
    line_height: ?i32 = null,

    /// Font weight (100-900, where 400 is normal, 700 is bold)
    font_weight: ?usize = null,

    /// Border radius configuration for rounded corners
    border_radius: ?BorderRadius = null,

    /// Border thickness specification
    border_thickness: ?Border = null,

    /// Border color as RGBA array [red, green, blue, alpha]
    border_color: ?Color = null,

    border: ?BorderGrouped = null,

    /// Text color as RGBA array [red, green, blue, alpha]
    /// Default: solid black
    text_color: ?Color = null,

    /// Gradient color as RGBA array [red, green, blue, alpha]
    gradient: ?[]const Color = null,

    /// Element opacity (0.0 = fully transparent, 1.0 = fully opaque)
    opacity: ?f32 = null,

    /// Shadow configuration for drop shadows
    shadow: Shadow = .{},

    /// 2D/3D transformation configuration
    transform: ?Transform = null,

    pub fn font(size: i32, weight: ?usize, color: ?Color) Visual {
        return .{
            .font_size = size,
            .font_weight = weight,
            .text_color = color,
        };
    }

    pub fn borderSolid(thickness: Border, color: Color) Visual {
        return .{
            .border = BorderGrouped{
                .thickness = thickness,
                .color = color,
            },
        };
    }

    // Background shortcuts
    pub fn bg(color: Color) Visual {
        return .{ .background = color };
    }

    pub fn pill(color: Color) Visual {
        return .{ .border = .pill(color) };
    }

    pub fn when(condition: bool, visual_true: Visual, visual_false: Visual) Visual {
        if (condition) {
            return visual_true;
        } else {
            return visual_false;
        }
    }

    pub fn button(background: Color, border: BorderGrouped) Visual {
        return .{
            .background = background,
            .border = border,
        };
    }
};

pub const Interactive = struct {
    hover: ?Visual = null,
    focus: ?Visual = null,
    focus_within: ?Visual = null,

    pub fn hover_scale() Interactive {
        return .{
            .hover = .{ .transform = .scale() },
        };
    }
    pub fn hover_text(color: Color) Interactive {
        return .{
            .hover = .{ .text_color = color },
        };
    }
};

/// Global user-defined default style that overrides system defaults
var user_defaults: ?Style = null;

/// Comprehensive styling struct that provides CSS-like properties for UI components.
/// Supports layout, visual styling, typography, animations, and interactions.
/// Uses a three-tier inheritance system: system defaults -> user defaults -> component styles.
///
/// # Usage Example:
/// ```zig
/// const button_style = Style.with(.{
///     .background = .{ 70, 130, 180, 255 }, // Steel blue
///     .border_radius = .all(8),
///     .padding = .all(12),
///     .font_weight = 600,
/// });
/// ```
pub const Style = struct {
    /// Unique identifier for the element id="92d7dd45a43f36e4_Text_0-genk...
    /// this defaults to the uuid of the element, which is autogenerated
    /// It is used during reconciliation to find the correct node to update
    /// duplicate ids on the same page are considered undefined behaviour
    id: ?[]const u8 = null,

    /// Class-like identifier for grouping styles
    style_id: ?[]const u8 = null,

    /// Positioning method (static, relative, absolute, fixed)
    position: ?Position = null,

    /// Flex direction for child elements (row, column, row-reverse, column-reverse)
    direction: Direction = .row,

    /// Size configuration for the element
    size: ?Size = null,

    /// Internal spacing configuration
    padding: ?Padding = null,

    /// External spacing configuration
    margin: ?Margin = .{},

    /// Style Props
    visual: ?Visual = null,

    /// Horizontal overflow behavior
    scroll: ?Scroll = null,

    /// Text decoration (underline, strikethrough, etc.)
    text_decoration: ?TextDecoration = null,

    /// Alignment configuration for child elements
    layout: ?Layout = null,

    /// Gap between child elements in pixels
    child_gap: u32 = 0,

    /// Font family name (e.g., "Arial", "Helvetica", "Montserrat")
    font_family: []const u8 = "",

    /// White space handling (normal, nowrap, pre, pre-wrap)
    white_space: ?WhiteSpace = null,

    /// Flex wrap behavior (nowrap, wrap, wrap-reverse)
    flex_wrap: ?FlexWrap = null,

    /// Single keyframe for simple animations
    key_frame: ?KeyFrame = null,

    /// Array of keyframes for complex animations
    key_frames: ?[]const KeyFrame = null,

    /// Animation specifications (duration, timing, etc.)
    animation: ?Animation.Specs = null,

    /// Animation name for exit/removal animations
    exit_animation: ?[]const u8 = null,

    /// Z-index for layering control (higher values appear on top)
    z_index: ?f32 = null,

    /// List styling for ul/ol elements
    list_style: ?ListStyle = null,

    /// Blur effect intensity in pixels
    blur: ?u32 = null,

    /// Outline configuration (different from border)
    outline: ?Outline = null,

    /// Transition specifications for smooth property changes
    transition: ?Transition = null,

    /// Whether to show scrollbars when content overflows
    show_scrollbar: bool = true,

    /// Cursor type when hovering over element
    cursor: ?Cursor = null,

    /// Interactive
    interactive: ?Interactive = null,

    /// Button identifier for click handling
    btn_id: u32 = 0,

    /// Dialog identifier for modal/popup elements
    dialog_id: ?[]const u8 = null,

    /// Array of child-specific style overrides
    child_styles: ?[]const ChildStyle = null,

    /// Element appearance override
    appearance: ?Appearance = null,

    /// Custom checkmark styling for checkboxes
    checkmark_style: ?CheckMark = null,

    /// Hint to browser about which properties will change (optimization)
    will_change: ?TransitionProperty = null,

    /// Origin point for transformations
    transform_origin: ?TransformOrigin = null,

    /// Backface visibility for 3D transforms
    backface_visibility: ?[]const u8 = null,

    /// System default style configuration with sensible defaults.
    /// Used as the base when no user defaults are set.
    pub const default: Style = Style{};

    /// Pre-configured opaque style with common visual properties.
    /// Useful as a starting point for solid, bordered elements.
    ///
    /// # Properties:
    /// - Font: Montserrat
    /// - Border radius: 4px on all corners
    /// - Border: 1px solid light gray (#DFDFDF)
    pub const Opaque: Style = .{
        .font_family = "Montserrat",
        .border_radius = .all(4),
        .border_color = .hex("#DFDFDF"),
        .border_thickness = .default(),
    };

    pub const Container: Style = .{
        .display = .flex,
        .direction = .row,
        .child_gap = 12,
        .child_alignment = .{ .x = .start, .y = .center },
        .flex_wrap = .wrap,
        .width = .percent(100),
    };

    pub const Button: Style = .{
        .padding = .{ .top = 8, .bottom = 8, .left = 12, .right = 12 },
        .border_radius = .all(6),
        .display = .inline_flex,
        .child_alignment = .{ .x = .center, .y = .center },
        .cursor = .pointer,
        .font_weight = 600,
    };

    pub const Card: Style = .{
        .background = .{ 255, 255, 255, 255 }, // White
        .padding = .all(16),
        .border_radius = .all(8),
        .shadow = .{ .blur = 8, .top = 2, .color = .{ 0, 0, 0, 25 } },
        .display = .block,
    };

    /// Gets the current base style to use for inheritance.
    /// Returns user-defined defaults if set, otherwise returns system defaults.
    ///
    /// # Returns:
    /// Style - The base style configuration
    ///
    /// # Usage:
    /// ```zig
    /// const base = Style.getDefault();
    /// const custom = Style{ .font_size = 16 }.merge(base);
    /// ```
    pub fn getDefault() Style {
        return user_defaults orelse Style.default;
    }

    /// Merges this style with a base style, creating a new style where
    /// non-default properties from this style override the base style.
    /// Only properties that differ from system defaults are applied.
    ///
    /// # Parameters:
    /// - `self`: Style - The style with override properties
    /// - `base`: Style - The base style to merge with
    ///
    /// # Returns:
    /// Style - New style with merged properties
    ///
    /// # Usage:
    /// ```zig
    /// const base_style = Style{ .font_size = 14, .padding = .all(8) };
    /// const override_style = Style{ .font_size = 18 }; // Only override font size
    /// const merged = override_style.merge(base_style);
    /// // Result: font_size = 18, padding = .all(8)
    /// ```
    pub fn merge(self: *const Style, base: Style) Style {
        var result = base;
        inline for (@typeInfo(Style).@"struct".fields) |field| {
            const field_value = @field(self, field.name);
            const default_value = @field(default, field.name);

            // Only override if the field is not the default value
            if (!std.meta.eql(field_value, default_value)) {
                @field(result, field.name) = field_value;
            }
        }
        return result;
    }

    pub fn extend(self: *Style, target: Style) void {
        inline for (@typeInfo(Style).@"struct".fields) |field| {
            const target_value = @field(target, field.name);
            const field_value = @field(self, field.name);
            const default_value = @field(default, field.name);

            // Only override if the field is not the default value
            if (!std.meta.eql(field_value, target_value) and !std.meta.eql(target_value, default_value)) {
                @field(self, field.name) = target_value;
            }
        }
    }

    /// Creates a new style by merging the provided overrides with the current default style.
    /// This is the primary way to create styled components with inheritance.
    ///
    /// # Parameters:
    /// - `overrides`: Style - Style properties to override defaults
    ///
    /// # Returns:
    /// Style - New style with default properties and specified overrides
    ///
    /// # Usage:
    /// ```zig
    /// // Create a button style with custom background and padding
    /// const button_style = Style.override(.{
    ///     .background = .{ 70, 130, 180, 255 }, // Steel blue
    ///     .padding = .all(12),
    ///     .border_radius = .all(6),
    ///     .text_color = .{ 255, 255, 255, 255 }, // White text
    /// });
    ///
    /// // Create a card style with shadow and border
    /// const card_style = Style.override(.{
    ///     .background = .{ 255, 255, 255, 255 }, // White background
    ///     .shadow = .{ .blur = 10, .color = .{ 0, 0, 0, 50 } },
    ///     .border_radius = .all(8),
    ///     .padding = .all(16),
    /// });
    /// ```
    pub fn override(overrides: Style) Style {
        return overrides.merge(Style.getDefault());
    }

    /// Sets the global user defaults that will be used as the base for all future styles.
    /// This allows you to establish consistent theming across your application.
    ///
    /// # Parameters:
    /// - `new_default`: Style - The new default style configuration
    ///
    /// # Returns:
    /// void
    ///
    /// # Usage:
    /// ```zig
    /// // Set up application-wide defaults
    /// Style.setDefault(.{
    ///     .font_family = "Inter",
    ///     .font_size = 14,
    ///     .text_color = .{ 33, 37, 41, 255 }, // Dark gray
    ///     .background = .{ 248, 249, 250, 255 }, // Light gray
    /// });
    ///
    /// // All subsequent Style.override() calls will inherit these defaults
    /// const button = Style.override(.{ .padding = .all(8) });
    /// // button now has Inter font, 14px size, dark gray text, etc.
    /// ```
    pub fn setDefault(new_default: Style) void {
        user_defaults = new_default;
    }
};
pub const Config = struct {
    style: Style,
};

pub const HooksIds = struct {
    created_id: u32 = 0,
    mounted_id: u32 = 0,
    updated_id: u32 = 0,
    destroy_id: u32 = 0,
};

const InputType = enum(u8) {
    text = 0,
    number = 1,
    password = 2,
    radio = 3,
    checkbox = 4,
    email = 5,
    search = 6,
    telephone = 7,
};
const Callback = *const fn (*Event) void;
pub const InputParamsStr = struct {
    default: ?[]const u8 = null,
    tag: ?[]const u8 = null,
    value: ?[]const u8 = null,
    min_len: ?u32 = null,
    max_len: ?u32 = null,
    required: ?bool = null,
    src: ?[]const u8 = null,
    alt: ?[]const u8 = null,
    disabled: ?bool = null,
    include_capital: ?u32 = null,
    onInput: ?Callback = null,
};

pub const InputParamsEmail = struct {
    default: ?[]const u8 = null,
    tag: ?[]const u8 = null,
    value: ?[]const u8 = null,
    min_len: ?u32 = null,
    max_len: ?u32 = null,
    required: ?bool = null,
    src: ?[]const u8 = null,
    alt: ?[]const u8 = null,
    disabled: ?bool = null,
    include_pattern: ?bool = null,
};

pub const InputParamsPassword = struct {
    default: ?[]const u8 = null,
    tag: ?[]const u8 = null,
    value: ?[]const u8 = null,
    min_len: ?u32 = null,
    max_len: ?u32 = null,
    required: ?bool = null,
    src: ?[]const u8 = null,
    alt: ?[]const u8 = null,
    disabled: ?bool = null,
    include_digit: ?u32 = null,
    include_capital: ?u32 = null,
    include_symbol: ?u32 = null,
};

const InputParamsFloat = struct {
    default: ?f32 = null,
    tag: ?[]const u8 = null,
    value: ?f32 = null,
    min_len: ?u32 = null,
    max_len: ?u32 = null,
    required: ?bool = null,
    src: ?[]const u8 = null,
    alt: ?[]const u8 = null,
    disabled: ?bool = null,
};
const InputParamsInt = struct {
    default: ?i32 = null,
    tag: ?[]const u8 = null,
    value: ?i32 = null,
    min_len: ?u32 = null,
    max_len: ?u32 = null,
    required: ?bool = null,
    src: ?[]const u8 = null,
    alt: ?[]const u8 = null,
    disabled: ?bool = null,
};

const InputParamsRadio = struct {
    tag: []const u8,
    value: []const u8,
    required: ?bool = null,
    checked: ?bool = null,
    src: ?[]const u8 = null,
    alt: ?[]const u8 = null,
    disabled: ?bool = null,
};

const InputParamsCheckBox = struct {
    tag: ?[]const u8 = null,
    checked: bool = false,
    required: ?bool = null,
    alt: ?[]const u8 = null,
    disabled: ?bool = null,
    checkmark: ?Style = null,
};

const InputParamsFile = struct {
    tag: ?[]const u8 = null,
    required: ?bool = null,
    disabled: ?bool = null,
};

pub const InputParams = union(enum) {
    int: InputParamsInt,
    float: InputParamsFloat,
    string: InputParamsStr,
    checkbox: InputParamsCheckBox,
    radio: InputParamsRadio,
    password: InputParamsPassword,
    email: InputParamsEmail,
    file: InputParamsFile,
};

pub const StateType = enum {
    static,
    pure,
    dynamic,
    animation,
    grain,
    err,
};

pub const ButtonType = enum {
    submit,
    button,
};

pub const ElementDeclaration = struct {
    hooks: HooksIds = .{},
    style: ?*const Style = null,
    elem_type: ElementType,
    text: []const u8 = "",
    svg: []const u8 = "",
    href: []const u8 = "",
    show: bool = true,
    input_params: ?*const InputParams = null,
    event_type: ?EventType = null,
    dynamic: StateType = .static,
    aria_label: ?[]const u8 = null,
    /// Used for passing ect data
    udata: usize = 0,
};

// A comptime function to merge two enums
pub fn createMergedEnum(comptime BaseEnum: type, comptime CustomEnum: type) type {
    // Get the fields of both enums using @typeInfo
    const base_fields = @typeInfo(BaseEnum).@"enum".fields;
    const custom_fields = @typeInfo(CustomEnum).@"enum".fields;

    // Create a new array to hold the merged fields
    var merged_fields: [base_fields.len + custom_fields.len]std.builtin.Type.EnumField = undefined;

    // Copy fields from the base enum
    for (base_fields, 0..) |field, i| {
        merged_fields[i] = .{
            .name = field.name,
            .value = field.value,
        };
    }

    // Copy fields from the custom enum, adjusting their values to avoid conflicts
    for (custom_fields, 0..) |field, i| {
        merged_fields[base_fields.len + i] = .{
            .name = field.name,
            .value = base_fields.len + field.value,
        };
    }

    // Create the new enum type using @Type
    return @Type(.{
        .@"enum" = .{
            .tag_type = u8, // Or another suitable integer type
            .fields = &merged_fields,
            .decls = &.{},
            .is_exhaustive = true,
        },
    });
}
pub fn addCustomChoice(_name: []const u8, comptime T: anytype) type {
    const name = std.mem.Allocator.dupeZ(std.heap.page_allocator, u8, _name) catch {};
    // we should probably add some error-checks here that T is an enum etc!

    // use reflection to get the information of the comptime parameter T
    const enum_type = @typeInfo(T).@"enum";

    // define an array, in compile time, with the fields of our new enum
    // that has room for "custom".
    comptime var fields: [enum_type.fields.len + 1]std.builtin.Type.EnumField = undefined;

    // define our first field to be "custom" and have the value "1 more than
    // the number of fields".
    fields[0] = .{ .name = name, .value = enum_type.fields.len };

    // copy the field from the "base" enum
    inline for (1.., enum_type.fields) |idx, f| {
        fields[idx] = f;
    }

    // and declare and return our new type!
    const enumInfo = std.builtin.Type.Enum{
        .tag_type = u8,
        .fields = &fields,
        .decls = &[0]std.builtin.Type.Declaration{},
        .is_exhaustive = true,
    };

    return @Type(std.builtin.Type{ .@"enum" = enumInfo });
}

pub const RenderCommand = struct {
    /// Rectangular box that fully encloses this UI element
    elem_type: ElementType,
    text: []const u8 = "",
    href: []const u8 = "",
    style: ?Style = null,
    id: []const u8 = "",
    index: usize = 0,
    hooks: HooksIds,
    node_ptr: *UINode,
    hover: bool = false,
    focus: bool = false,
    focus_within: bool = false,
    class: ?[]const u8 = null,
    render_type: StateType = .static,
};

pub const EventType = enum(u8) {
    // Mouse events
    none = 0,
    click, // Fired when a pointing device button is clicked.
    dblclick, // Fired when a pointing device button is double-clicked.
    mousedown, // Fired when a pointing device button is pressed.
    mouseup, // Fired when a pointing device button is released.
    mousemove, // Fired when a pointing device is moved.
    mouseover, // Fired when a pointing device is moved onto an element.
    mouseout, // Fired when a pointing device is moved off an element.
    mouseenter, // Similar to mouseover but does not bubble.
    mouseleave, // Similar to mouseout but does not bubble.
    contextmenu, // Fired when the right mouse button is clicked.

    // Keyboard events
    keydown, // Fired when a key is pressed.
    keyup, // Fired when a key is released.
    keypress, // Fired when a key that produces a character value is pressed.

    // Focus events
    focus, // Fired when an element gains focus.
    blur, // Fired when an element loses focus.
    focusin, // Fired when an element is about to receive focus.
    focusout, // Fired when an element is about to lose focus.

    // Form events
    change, // Fired when the value of an element changes.
    input, // Fired every time the value of an element changes.
    submit, // Fired when a form is submitted.
    reset, // Fired when a form is reset.

    // Window events
    resize, // Fired when the window is resized.
    scroll, // Fired when the document view is scrolled.
    wheel, // Fired when the mouse wheel is rotated.

    // Drag & Drop events
    drag, // Fired continuously while an element or text selection is being dragged.
    dragstart, // Fired at the start of a drag operation.
    dragend, // Fired at the end of a drag operation.
    dragover, // Fired when an element is being dragged over a valid drop target.
    dragenter, // Fired when a dragged element enters a valid drop target.
    dragleave, // Fired when a dragged element leaves a valid drop target.
    drop, // Fired when a dragged element is dropped on a valid drop target.

    // Clipboard events
    copy, // Fired when the user initiates a copy action.
    cut, // Fired when the user initiates a cut action.
    paste, // Fired when the user initiates a paste action.

    // Touch events
    touchstart, // Fired when one or more touch points are placed on the touch surface.
    touchmove, // Fired when one or more touch points are moved along the touch surface.
    touchend, // Fired when one or more touch points are removed from the touch surface.
    touchcancel, // Fired when a touch point is disrupted (e.g., by a modal interruption).

    // Pointer events (unify mouse, touch, and pen input)
    pointerover, // Fired when a pointer enters the hit test boundaries of an element.
    pointerenter, // Similar to pointerover but does not bubble.
    pointerdown, // Fired when a pointer becomes active.
    pointermove, // Fired when a pointer changes coordinates.
    pointerup, // Fired when a pointer is no longer active.
    pointercancel, // Fired when a pointer is canceled.
    pointerout, // Fired when a pointer moves out of an element.
    pointerleave, // Similar to pointerout but does not bubble.

    // Document / Media / Error events
    load, // Fired when a resource and its dependent resources have finished loading.
    unload, // Fired when the document is being unloaded.
    abort, // Fired when the loading of a resource is aborted.
    show,
    close,
    cancel,
};
