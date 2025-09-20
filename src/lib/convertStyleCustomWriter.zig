const std = @import("std");
const mem = std.mem;
const Types = @import("types.zig");
const Alignment = Types.Alignment;
const Direction = Types.Direction;
const PositionType = Types.PositionType;
const FloatType = Types.FloatType;
const UINode = @import("UITree.zig").UINode;
const Sizing = Types.Sizing;
const Transform = Types.Transform;
const TextDecoration = Types.TextDecoration;
const Appearance = Types.Appearance;
const WhiteSpace = Types.WhiteSpace;
const FlexWrap = Types.FlexWrap;
const BoxSizing = Types.BoxSizing;
const Pos = Types.Pos;
const PosType = Types.PosType;
const FlexType = Types.FlexType;
const TransformOrigin = Types.TransformOrigin;
const Fabric = @import("Fabric.zig");
const Animation = Fabric.Animation;
const AnimationType = Types.AnimationType;
const ListStyle = Types.ListStyle;
const Transition = Types.Transition;
const TimingFunction = Types.TimingFunction;
const Outline = Types.Outline;
const Cursor = Types.Cursor;
const Color = Types.Color;
const Writer = @import("Writer.zig");
const AnimDir = @import("Animation.zig").AnimDir;

const writer_t = *Writer;
// Global buffer to store the CSS string for returning to JavaScript
var css_buffer: [4096]u8 = undefined;

const PropValue = struct {
    tag: Tag,
    data: Data,

    // Enum to identify the type
    const Tag = enum {
        position_type,
        direction,
        sizing,
        padding,
        cursor,
        appearance,
        transform_type,
        transform_origin,
        margin,
        pos,
        text_decoration,
        white_space,
        flex_wrap,
        alignment,
        background,
        list_style,
        outline,
        animation_specs,
        transition,
        shadow,
        border,
        border_radius,
        flex_type,
        string_literal, // For values like "flex", "center", etc.
    };

    // Union to hold the actual data
    const Data = union(Tag) {
        position_type: Types.PositionType,
        direction: Types.Direction,
        sizing: Types.Sizing,
        padding: Types.Padding,
        cursor: Types.Cursor,
        appearance: Types.Appearance,
        transform_type: Types.Transform,
        transform_origin: Types.TransformOrigin,
        margin: Types.Margin,
        pos: Types.Pos,
        text_decoration: Types.TextDecoration,
        white_space: Types.WhiteSpace,
        flex_wrap: Types.FlexWrap,
        alignment: Types.Alignment,
        background: Types.Color,
        list_style: Types.ListStyle,
        outline: Types.Outline,
        animation_specs: Animation.Specs,
        transition: Types.Transition,
        shadow: Types.Shadow,
        border: Types.Border,
        border_radius: Types.BorderRadius,
        flex_type: Types.FlexType,
        string_literal: []const u8,
    };
};

/// Writes a CSS property and its value to the writer.
/// This function uses a tagged union (PropValue) to prevent code bloat from monomorphization.
fn writePropValue(prop: []const u8, value: PropValue, writer: writer_t) void {
    writer.write(prop) catch return;
    writer.writeByte(':') catch return;

    switch (value.tag) {
        // else => {},
        .position_type => positionTypeToCSS(value.data.position_type, writer) catch {},
        .direction => directionToCSS(value.data.direction, writer) catch {},
        .sizing => sizingTypeToCSS(value.data.sizing, writer) catch {},
        .padding => {
            writer.writeU32(value.data.padding.top) catch {};
            writer.write("px ") catch {};
            writer.writeU32(value.data.padding.right) catch {};
            writer.write("px ") catch {};
            writer.writeU32(value.data.padding.bottom) catch {};
            writer.write("px ") catch {};
            writer.writeU32(value.data.padding.left) catch {};
            writer.write("px") catch {};
        },
        .cursor => cursorToCSS(value.data.cursor, writer) catch {},
        .appearance => appearanceToCSS(value.data.appearance, writer) catch {},
        .transform_type => {
            const transform = value.data.transform_type;
            switch (transform.type) {
                .scale => {
                    writer.write("scale(") catch {};
                    writer.writeF32(transform.scale_size) catch {};
                    writer.writeByte(')') catch {};
                },
                .scaleY => {
                    writer.write("scaleY(") catch {};
                    writer.writeF32(transform.scale_size) catch {};
                    writer.writeByte(')') catch {};
                },
                .scaleX => {
                    writer.write("scaleX(") catch {};
                    writer.writeF32(transform.scale_size) catch {};
                    writer.writeByte(')') catch {};
                },
                .translateX => {
                    writer.write("translateX(") catch {};
                    writer.writeF32(transform.dist) catch {};
                    writer.writeByte(')') catch {};
                },
                .translateY => {
                    writer.write("translateY(") catch {};
                    writer.writeF32(transform.dist) catch {};
                    writer.writeByte(')') catch {};
                },
                .rotate => {
                    writer.write("rotate(") catch {};
                    writer.writeF32(transform.deg) catch {};
                    writer.write("deg)") catch {};
                },
                .rotateX => {
                    writer.write("rotateX(") catch {};
                    writer.writeF32(transform.deg) catch {};
                    writer.write("deg)") catch {};
                },
                .rotateY => {
                    writer.write("rotateY(") catch {};
                    writer.writeF32(transform.deg) catch {};
                    writer.write("deg)") catch {};
                },
                .rotateXYZ => {
                    writer.write("rotateX(") catch {};
                    writer.writeF32(transform.x) catch {};
                    writer.write("deg) ") catch {};
                    writer.write("rotateY(") catch {};
                    writer.writeF32(transform.y) catch {};
                    writer.write("deg) ") catch {};
                    writer.write("rotateZ(") catch {};
                    writer.writeF32(transform.z) catch {};
                    writer.write("deg)") catch {};
                },
                .none => {},
            }
        },
        .transform_origin => transformOriginToCSS(value.data.transform_origin, writer) catch {},
        .margin => {
            writer.writeU32(value.data.margin.top) catch {};
            writer.write("px ") catch {};
            writer.writeU32(value.data.margin.right) catch {};
            writer.write("px ") catch {};
            writer.writeU32(value.data.margin.bottom) catch {};
            writer.write("px ") catch {};
            writer.writeU32(value.data.margin.left) catch {};
            writer.write("px") catch {};
        },
        .pos => posTypeToCSS(value.data.pos, writer) catch {},
        .text_decoration => textDecoToCSS(value.data.text_decoration, writer) catch {},
        .white_space => whiteSpaceToCSS(value.data.white_space, writer) catch {},
        .flex_wrap => flexWrapToCSS(value.data.flex_wrap, writer) catch {},
        .alignment => alignmentToCSS(value.data.alignment, writer) catch {},
        .background => colorToCSS(value.data.background, writer) catch {},
        .list_style => listStyleToCSS(value.data.list_style, writer) catch {},
        .outline => outlineStyleToCSS(value.data.outline, writer) catch {},
        .animation_specs => animationToCSS(value.data.animation_specs, writer) catch {},
        .transition => transitionStyleToCSS(value.data.transition, writer),
        .shadow => {
            const shadow = value.data.shadow;
            writer.writeF32(shadow.left) catch {};
            writer.write("px ") catch {};
            writer.writeF32(shadow.top) catch {};
            writer.write("px ") catch {};
            writer.writeF32(shadow.blur) catch {};
            writer.write("px ") catch {};
            writer.writeF32(shadow.spread) catch {};
            writer.write("px ") catch {};
            colorToCSS(shadow.color, writer) catch {};
        },
        .border => {
            const border = value.data.border;
            writer.writeF32(border.top) catch {};
            writer.write("px ") catch {};
            writer.writeF32(border.right) catch {};
            writer.write("px ") catch {};
            writer.writeF32(border.bottom) catch {};
            writer.write("px ") catch {};
            writer.writeF32(border.left) catch {};
            writer.write("px") catch {};
        },
        .border_radius => {
            const radius = value.data.border_radius;
            if (radius.top_left == radius.top_right and radius.top_left == radius.bottom_right and radius.top_left == radius.bottom_left) {
                writer.writeF32(radius.top_left) catch {};
                writer.write("px") catch {};
            } else {
                writer.writeF32(radius.top_left) catch {};
                writer.write("px ") catch {};
                writer.writeF32(radius.top_right) catch {};
                writer.write("px ") catch {};
                writer.writeF32(radius.bottom_right) catch {};
                writer.write("px ") catch {};
                writer.writeF32(radius.bottom_left) catch {};
                writer.write("px") catch {};
            }
        },
        .flex_type => flexTypeToCSS(value.data.flex_type, writer) catch {},

        // This new case handles simple string values efficiently.
        .string_literal => writer.write(value.data.string_literal) catch {},
    }
    writer.write(";\n") catch {};
}

// Maps for simple enum-to-string conversions
const direction_map = [_][]const u8{ "column", "row" };
const alignment_map = [_][]const u8{ "center", "flex-start", "flex-end", "flex-start", "flex-end", "space-between", "space-evenly" };
const position_type_map = [_][]const u8{ "relative", "absolute", "fixed", "sticky" };
const float_type_map = [_][]const u8{ "top", "bottom", "left", "right" };
const transform_origin_map = [_][]const u8{ "top", "bottom", "right", "left" };
const text_decoration_map = [_][]const u8{ "none", "inherit", "underline", "initial", "overline", "unset", "revert" };
const appearance_map = [_][]const u8{ "none", "auto", "button", "textfield", "menulist", "searchfield", "textarea", "checkbox", "radio", "inherit", "initial", "revert", "unset" };
const outline_map = [_][]const u8{ "none", "auto", "dotted", "dashed", "solid", "double", "groove", "ridge", "inset", "outset", "inherit", "initial", "revert", "unset" };
const cursor_map = [_][]const u8{ "pointer", "help", "grab", "zoom-in", "zoom-out" };
const box_sizing_map = [_][]const u8{ "content-box", "border-box", "padding-box", "inherit", "initial", "revert", "unset" };
const list_style_map = [_][]const u8{ "none", "disc", "circle", "square", "decimal", "decimal-leading-zero", "lower-roman", "upper-roman", "lower-alpha", "upper-alpha", "lower-greek", "armenian", "georgian", "inherit", "initial", "revert", "unset" };
const flex_wrap_map = [_][]const u8{ "nowrap", "wrap", "wrap-reverse", "inherit", "initial", "revert", "unset" };
const white_space_map = [_][]const u8{ "normal", "nowrap", "pre", "pre-wrap", "pre-line", "break-spaces", "inherit", "initial", "revert", "unset" };
const flex_type_map = [_][]const u8{ "inline-flex", "inline-flex", "block", "inline-block", "none" };
const timing_function_map = [_][]const u8{ "ease", "linear", "ease-in", "ease-out", "ease-in-out", "bounce", "elastic" };
const animation_direction_map = [_][]const u8{ "normal ", "reverse ", "forwards ", "alternate " };

/// Generic helper to write a CSS string from a pre-defined map based on an enum's value.
/// The `string_map` must have its string literals in the same order as the enum declaration.
inline fn writeMappedString(
    comptime EnumType: type,
    value: EnumType,
    string_map: []const []const u8,
    writer: anytype,
) !void {
    try writer.write(string_map[@intFromEnum(value)]);
}

fn directionToCSS(dir: Direction, writer: writer_t) !void {
    try writeMappedString(Direction, dir, &direction_map, writer);
}

fn alignmentToCSS(_align: Alignment, writer: writer_t) !void {
    try writeMappedString(Alignment, _align, &alignment_map, writer);
}

fn positionTypeToCSS(pos_type: PositionType, writer: writer_t) !void {
    try writeMappedString(PositionType, pos_type, &position_type_map, writer);
}

fn floatTypeToCSS(float_type: FloatType) []const u8 {
    return float_type_map[@intFromEnum(float_type)];
}

fn transformOriginToCSS(origin: TransformOrigin, writer: anytype) !void {
    try writeMappedString(TransformOrigin, origin, &transform_origin_map, writer);
}

fn textDecoToCSS(deco: TextDecoration, writer: anytype) !void {
    try writeMappedString(TextDecoration, deco, &text_decoration_map, writer);
}

// // Helper function to convert Direction enum to CSS flex-direction
// fn directionToCSS(dir: Direction, writer: writer_t) !void {
//     switch (dir) {
//         .column => try writer.write("column"),
//         .row => try writer.write("row"),
//     }
// }
//
// // Helper function to convert Alignment to CSS values
// fn alignmentToCSS(_align: Alignment, writer: writer_t) !void {
//     switch (_align) {
//         .center => try writer.write("center"),
//         .top => try writer.write("flex-start"),
//         .bottom => try writer.write("flex-end"),
//         .start => try writer.write("flex-start"),
//         .end => try writer.write("flex-end"),
//         .between => try writer.write("space-between"),
//         .even => try writer.write("space-evenly"),
//     }
// }
//
// // Helper function to convert PositionType to CSS values
// fn positionTypeToCSS(pos_type: PositionType, writer: writer_t) !void {
//     return switch (pos_type) {
//         .relative => try writer.write("relative"),
//         .absolute => try writer.write("absolute"),
//         .fixed => try writer.write("fixed"),
//         .sticky => try writer.write("sticky"),
//     };
// }
//
// // Helper function to convert FloatType to CSS values
// fn floatTypeToCSS(float_type: FloatType) []const u8 {
//     return switch (float_type) {
//         .top => "top",
//         .bottom => "bottom",
//         .left => "left",
//         .right => "right",
//     };
// }

// Helper function to convert SizingType to CSS values
fn sizingTypeToCSS(sizing: Sizing, writer: writer_t) !void {
    switch (sizing.type) {
        .fit => try writer.write("fit-content"),
        .grow => try writer.write("flex:1"),
        .percent => {
            try writer.writeF32(sizing.size.minmax.min);
            try writer.writeByte('%');
        },
        .fixed => {
            try writer.writeF32(sizing.size.minmax.min);
            try writer.write("px");
        },
        .elastic => try writer.write("auto"), // Could also use min/max width/height in separate properties
        .elastic_percent => {
            try writer.writeF32(sizing.size.percent.min);
            try writer.writeByte('%');
        },
        .clamp_px => {
            try writer.write("clamp(");
            try writer.writeF32(sizing.size.clamp_px.min);
            try writer.write("px,");
            try writer.writeF32(sizing.size.clamp_px.preferred);
            try writer.write("px,");
            try writer.writeF32(sizing.size.clamp_px.max);
            try writer.write("px)");
        },
        .clamp_percent => {
            try writer.write("clamp(");
            try writer.writeF32(sizing.size.clamp_px.min);
            try writer.write("%,");
            try writer.writeF32(sizing.size.clamp_px.preferred);
            try writer.write("%,");
            try writer.writeF32(sizing.size.clamp_px.max);
            try writer.write("%)");
        },
        .none => {},
        else => {},
    }
}

fn posTypeToCSS(pos: Pos, writer: writer_t) !void {
    switch (pos.type) {
        .fit => try writer.write("fit-content"),
        .grow => try writer.write("auto"),
        .percent => {
            try writer.writeF32(pos.value);
            try writer.writeByte('%');
        },
        .fixed => {
            try writer.writeF32(pos.value);
            try writer.write("px");
        },
    }
}

// Helper function to convert color array to CSS rgba
fn colorToCSS(color: Color, writer: anytype) !void {
    const alpha = @as(f32, @floatFromInt(color.a)) / 255.0;
    try writer.write("rgba(");
    try writer.writeU8Num(color.r);
    try writer.writeByte(',');
    try writer.writeU8Num(color.g);
    try writer.writeByte(',');
    try writer.writeU8Num(color.b);
    try writer.writeByte(',');
    try writer.writeF32(alpha);
    try writer.writeByte(')');
}

// // Function to convert TransformType to CSS
// fn transformToCSS(transform: Transform, writer: anytype) !void {
//     switch (transform.type) {
//         .none => {},
//         .scale => try writer.print("scale({d})", .{transform.scale_size}),
//         .scaleY => try writer.print("scaleY({d})", .{transform.scale_size}),
//         .scaleX => try writer.print("scaleX({d})", .{transform.scale_size}),
//         .translateX => try writer.print("translateX({d})", .{transform.dist}),
//         .translateY => try writer.print("translateY({d})", .{transform.dist}),
//     }
// }
//
// // Function to convert TransformType to CSS
// fn transformOriginToCSS(transform_origin: TransformOrigin, writer: anytype) !void {
//     switch (transform_origin) {
//         .top => try writer.write("top"),
//         .bottom => try writer.write("bottom"),
//         .right => try writer.write("right"),
//         .left => try writer.write("left"),
//     }
// }
//
// fn textDecoToCSS(text_decoration: TextDecoration, writer: anytype) !void {
//     switch (text_decoration) {
//         .none => try writer.write("none"), // Not implemented in your struct
//         .inherit => try writer.write("inherit"), // Not implemented in your struct
//         .underline => try writer.write("underline"), // Not implemented in your struct
//         .initial => try writer.write("initial"), // Not implemented in your struct
//         .overline => try writer.write("overline"), // Not implemented in your struct
//         .unset => try writer.write("unset"), // Not implemented in your struct
//         .revert => try writer.write("revert"), // Not implemented in your struct
//     }
// }
fn appearanceToCSS(appearance: Appearance, writer: anytype) !void {
    try writeMappedString(Appearance, appearance, &appearance_map, writer);
    // switch (appearance) {
    //     .none => try writer.write("none"),
    //     .auto => try writer.write("auto"),
    //     .button => try writer.write("button"),
    //     .textfield => try writer.write("textfield"),
    //     .menulist => try writer.write("menulist"),
    //     .searchfield => try writer.write("searchfield"),
    //     .textarea => try writer.write("textarea"),
    //     .checkbox => try writer.write("checkbox"),
    //     .radio => try writer.write("radio"),
    //     .inherit => try writer.write("inherit"),
    //     .initial => try writer.write("initial"),
    //     .revert => try writer.write("revert"),
    //     .unset => try writer.write("unset"),
    // }
}

// Function to convert OutlineStyle enum to a CSS string
fn outlineStyleToCSS(outline: Outline, writer: anytype) !void {
    try writeMappedString(Outline, outline, &outline_map, writer);
    // switch (style) {
    //     .none => try writer.write("none"),
    //     .auto => try writer.write("auto"),
    //     .dotted => try writer.write("dotted"),
    //     .dashed => try writer.write("dashed"),
    //     .solid => try writer.write("solid"),
    //     .double => try writer.write("double"),
    //     .groove => try writer.write("groove"),
    //     .ridge => try writer.write("ridge"),
    //     .inset => try writer.write("inset"),
    //     .outset => try writer.write("outset"),
    //     .inherit => try writer.write("inherit"),
    //     .initial => try writer.write("initial"),
    //     .revert => try writer.write("revert"),
    //     .unset => try writer.write("unset"),
    // }
}

fn transitionStyleToCSS(style: Transition, writer: anytype) void {
    if (style.properties) |prop| {
        for (prop) |p| {
            switch (p) {
                .transform => {
                    const tag_name = @tagName(p);
                    writer.write(tag_name) catch return;
                    writer.write(" ") catch return;
                },
                else => {},
            }
        }
    } else {
        writer.write("all ") catch return;
    }
    writer.writeU32(style.duration) catch return;
    writer.write("ms ") catch return;
    try writeMappedString(TimingFunction, style.timing, &timing_function_map, writer);
    // switch (style.timing) {
    //     .ease => writer.write("ease") catch return,
    //     .linear => writer.write("linear") catch return,
    //     .ease_in => writer.write("ease-in") catch return,
    //     .ease_out => writer.write("ease-out") catch return,
    //     .ease_in_out => writer.write("ease-in-out") catch return,
    //     .bounce => writer.write("bounce") catch return,
    //     .elastic => writer.write("elastic") catch return,
    // }
}

// Function to convert ListStyle enum to CSS string
fn cursorToCSS(cursor_type: Cursor, writer: anytype) !void {
    try writeMappedString(Cursor, cursor_type, &cursor_map, writer);
    // switch (cursor_type) {
    //     .pointer => try writer.write("pointer"),
    //     .help => try writer.write("help"),
    //     .grab => try writer.write("grab"),
    //     .zoom_in => try writer.write("zoom-in"),
    //     .zoom_out => try writer.write("zoom-out"),
    // }
}

// Function to convert ListStyle enum to CSS string
fn listStyleToCSS(list_style: ListStyle, writer: anytype) !void {
    try writeMappedString(ListStyle, list_style, &list_style_map, writer);
    // switch (list_style) {
    //     .none => try writer.write("none"),
    //     .disc => try writer.write("disc"),
    //     .circle => try writer.write("circle"),
    //     .square => try writer.write("square"),
    //     .decimal => try writer.write("decimal"),
    //     .decimal_leading_zero => try writer.write("decimal-leading-zero"),
    //     .lower_roman => try writer.write("lower-roman"),
    //     .upper_roman => try writer.write("upper-roman"),
    //     .lower_alpha => try writer.write("lower-alpha"),
    //     .upper_alpha => try writer.write("upper-alpha"),
    //     .lower_greek => try writer.write("lower-greek"),
    //     .armenian => try writer.write("armenian"),
    //     .georgian => try writer.write("georgian"),
    //     .inherit => try writer.write("inherit"),
    //     .initial => try writer.write("initial"),
    //     .revert => try writer.write("revert"),
    //     .unset => try writer.write("unset"),
    // }
}

// Function to convert FlexWrap enum to CSS string
fn flexWrapToCSS(flex_wrap: FlexWrap, writer: anytype) !void {
    try writeMappedString(FlexWrap, flex_wrap, &flex_wrap_map, writer);
    // switch (flex_wrap) {
    //     .nowrap => try writer.write("nowrap"),
    //     .wrap => try writer.write("wrap"),
    //     .wrap_reverse => try writer.write("wrap-reverse"),
    //     .inherit => try writer.write("inherit"),
    //     .initial => try writer.write("initial"),
    //     .revert => try writer.write("revert"),
    //     .unset => try writer.write("unset"),
    // }
}
fn animationToCSS(animation: Animation.Specs, writer: anytype) !void {
    writer.write(animation.tag) catch {};
    writer.write(" ") catch {};
    writer.writeF32(animation.duration_s) catch {};
    writer.write("s ") catch {};
    try writeMappedString(TimingFunction, animation.timing_function, &timing_function_map, writer);
    // switch (animation.timing_function) {
    //     .linear => try writer.write("linear "),
    //     .ease => try writer.write("ease "),
    //     .ease_in => try writer.write("ease-in "),
    //     .ease_in_out => try writer.write("ease-in-out "),
    //     .ease_out => try writer.write("ease_out "),
    // }
    try writeMappedString(AnimDir, animation.direction, &animation_direction_map, writer);
    // switch (animation.direction) {
    //     .normal => try writer.write("normal "),
    //     .reverse => try writer.write("reverse "),
    //     .forwards => try writer.write("forwards "),
    //     .pingpong => try writer.write("alternate "),
    // }
    if (animation.iteration_count.iter_count == 0) {
        try writer.write("infinite");
    } else {
        // try writer.print("{d}", .{animation.iteration_count.iter_count});
    }
}

fn whiteSpaceToCSS(white_space: WhiteSpace, writer: anytype) !void {
    try writeMappedString(WhiteSpace, white_space, &white_space_map, writer);
    // switch (white_space) {
    //     .normal => try writer.write("normal"),
    //     .nowrap => try writer.write("nowrap"),
    //     .pre => try writer.write("pre"),
    //     .pre_wrap => try writer.write("pre-wrap"),
    //     .pre_line => try writer.write("pre-line"),
    //     .break_spaces => try writer.write("break-spaces"),
    //     .inherit => try writer.write("inherit"),
    //     .initial => try writer.write("initial"),
    //     .revert => try writer.write("revert"),
    //     .unset => try writer.write("unset"),
    // }
}

// Function to convert FlexType enum to a CSS string
fn flexTypeToCSS(flex_type: FlexType, writer: anytype) !void {
    try writeMappedString(FlexType, flex_type, &flex_type_map, writer);
    // switch (flex_type) {
    //     .Flex, .Center => try writer.write("flex"),
    //     .Stack => try writer.write("block"),
    //     .Flow => try writer.write("inline-block"),
    //     .None => try writer.write("none"),
    // }
}

fn checkVisual(ptr: ?*UINode, visual: *const Types.Visual, writer: writer_t, visual_type: u8) void {
    // Color color
    if (visual.background) |background| {
        writePropValue("background-color", .{ .tag = .background, .data = .{ .background = background } }, writer);
        // writePropValue("background-color", background, &writer);
    } else if (ptr != null and ptr.?.type == .Button or ptr.?.type == .CtxButton) {
        _ = writer.write("background-color:rgba(0,0,0,0);\n") catch {};
    }

    // Write font properties
    if (visual.font_size) |fs| {
        writer.write("font-size:") catch {};
        writer.writeI32(fs) catch {};
        writer.write("px;\n") catch {};
    }
    if (visual.letter_spacing) |ls| {
        writer.write("letter-spacing:") catch {};
        writer.writeI32(ls) catch {};
        writer.write("px;\n") catch {};
    }
    if (visual.line_height) |lh| {
        writer.write("line-height:") catch {};
        writer.writeI32(lh) catch {};
        writer.write("px;\n") catch {};
    }

    if (visual.font_weight) |sf| {
        writer.write("font-weight:") catch {};
        writer.writeUsize(sf) catch {};
        writer.write(";\n") catch {};
    }

    if (visual.border) |border| {
        const border_thickness = border.thickness;
        writePropValue("border-width", .{ .tag = .border, .data = .{ .border = border_thickness } }, writer);
        // writePropValue("border-width", border_thickness, writer);
        if (border.color) |border_color| {
            writePropValue("border-color", .{ .tag = .background, .data = .{ .background = border_color } }, writer);
            // writePropValue("border-color", border_color, writer);
        }
        writer.write("border-style: solid;\n") catch {};

        // Border radius
        if (border.radius) |border_radius| {
            writePropValue("border-radius", .{ .tag = .border_radius, .data = .{ .border_radius = border_radius } }, writer);
            // writePropValue("border-radius", border_radius, writer);
        }
    } else if (visual.border_thickness) |border_thickness| {
        writePropValue("border-width", .{ .tag = .border, .data = .{ .border = border_thickness } }, writer);
        // writePropValue("border-width", border_thickness, writer);
        if (visual.border_color) |border_color| {
            writePropValue("border-color", .{ .tag = .background, .data = .{ .background = border_color } }, writer);
            // writePropValue("border-color", border_color, writer);
        }
        writer.write("border-style:solid;\n") catch {};
    } else if (visual_type != 0) {
        if (ptr != null and ptr.?.type == .Button or ptr.?.type == .CtxButton or ptr.?.type == .ButtonCycle) {
            _ = writer.write("border:none;\n") catch {};
        }
    }

    // Border radius
    if (visual.border_radius) |border_radius| {
        writePropValue("border-radius", .{ .tag = .border_radius, .data = .{ .border_radius = border_radius } }, writer);
        // writePropValue("border-radius", border_radius, writer);
    }

    // Text color
    if (visual.text_color) |color| {
        if (ptr.?.type == .Svg) {
            writePropValue("fill", .{ .tag = .background, .data = .{ .background = color } }, writer);
        } else {
            writePropValue("color", .{ .tag = .background, .data = .{ .background = color } }, writer);
        }
        // writePropValue("color", color, writer);
    }

    // Shadow
    if (visual.shadow.blur > 0 or visual.shadow.spread > 0 or
        visual.shadow.top > 0 or visual.shadow.left > 0)
    {
        writePropValue("box-shadow", .{ .tag = .shadow, .data = .{ .shadow = visual.shadow } }, writer);
    }
    // Transform
    if (visual.transform) |tr| {
        writePropValue("transform", .{ .tag = .transform_type, .data = .{ .transform_type = tr } }, writer);
        // writePropValue("transform", tr, &writer);
    }
}

// Export this function to be called from JavaScript to get the CSS representation
pub var style_style: []const u8 = "";
var global_len: usize = 0;
var show_scrollbar: bool = true;
// 61.8kb before this function
// adds 20kb

pub fn generateStyle(ptr: ?*UINode, style: *const Types.Style) void {
    // Use a fixed buffer with a fbs to build the CSS string
    var writer: Writer = undefined;
    writer.init(&css_buffer);

    // Write position properties
    if (style.position) |p| {
        writePropValue("position", .{ .tag = .position_type, .data = .{ .position_type = p.type } }, &writer); // adds 9kb
        if (p.left) |pl| {
            writePropValue("left", .{ .tag = .pos, .data = .{ .pos = pl } }, &writer);
        }
        if (p.right) |pr| {
            writePropValue("right", .{ .tag = .pos, .data = .{ .pos = pr } }, &writer);
        }
        if (p.top) |pt| {
            writePropValue("top", .{ .tag = .pos, .data = .{ .pos = pt } }, &writer);
        }
        if (p.bottom) |pb| {
            writePropValue("bottom", .{ .tag = .pos, .data = .{ .pos = pb } }, &writer);
        }
    }

    // Write display and flex properties
    if (ptr != null and ptr.?.type == .FlexBox) {
        writePropValue("display", .{ .tag = .flex_type, .data = .{ .flex_type = .Flex } }, &writer);
        // if (style.layout) |layout| {
        //     writePropValue("display", .{ .tag = .flex_type, .data = .{ .flex_type = layout } }, &writer);
        //     // writePropValue("display", layout, &writer);
        // } else {
        //     writePropValue("display", .{ .tag = .flex_type, .data = .{ .flex_type = .Flex } }, &writer);
        //     // writePropValue("display", "flex", &writer);
        // }
        writePropValue("flex-direction", .{ .tag = .direction, .data = .{ .direction = style.direction } }, &writer);
        // writePropValue("flex-direction", style.direction, &writer);

        // justify content is x by default
        // align items is y by default and they swap when doing direction .column
        if (style.layout) |layout| {
            if (style.direction == .row) {
                writePropValue("justify-content", .{ .tag = .alignment, .data = .{ .alignment = layout.x } }, &writer);
                writePropValue("align-items", .{ .tag = .alignment, .data = .{ .alignment = layout.y } }, &writer);
                // writePropValue("justify-content", layout.x, &writer);
                // writePropValue("align-items", layout.y, &writer);
            } else {
                writePropValue("align-items", .{ .tag = .alignment, .data = .{ .alignment = layout.x } }, &writer);
                writePropValue("justify-content", .{ .tag = .alignment, .data = .{ .alignment = layout.y } }, &writer);
                // writePropValue("align-items", layout.x, &writer);
                // writePropValue("justify-content", layout.y, &writer);
            }
        }
    } else if (style.layout) |layout| {
        if (ptr != null and ptr.?.text.len > 0 and layout.x == .center and layout.y == .center and ptr.?.type != .Svg) {
            writePropValue("text-align", .{ .tag = .alignment, .data = .{ .alignment = .center } }, &writer);
            // writePropValue("text-align", "center", &writer);
        } else {
            // writePropValue("display", d, &writer);
            writePropValue("display", .{ .tag = .flex_type, .data = .{ .flex_type = .Flex } }, &writer);
            // writePropValue("flex-direction", style.direction, &writer);

            if (layout.x == .center and layout.y == .center) {
                writePropValue("justify-content", .{ .tag = .alignment, .data = .{ .alignment = .center } }, &writer);
                writePropValue("align-items", .{ .tag = .alignment, .data = .{ .alignment = .center } }, &writer);
                // writePropValue("justify-content", "center", &writer);
                // writePropValue("align-items", "center", &writer);
            } else {
                if (style.direction == .row) {
                    writePropValue("justify-content", .{ .tag = .alignment, .data = .{ .alignment = layout.x } }, &writer);
                    writePropValue("align-items", .{ .tag = .alignment, .data = .{ .alignment = layout.y } }, &writer);
                    // writePropValue("justify-content", layout.x, &writer);
                    // writePropValue("align-items", layout.y, &writer);
                } else {
                    writePropValue("align-items", .{ .tag = .alignment, .data = .{ .alignment = layout.x } }, &writer);
                    writePropValue("justify-content", .{ .tag = .alignment, .data = .{ .alignment = layout.y } }, &writer);
                    // writePropValue("align-items", layout.x, &writer);
                    // writePropValue("justify-content", layout.y, &writer);
                }
            }
        }
    }

    if (style.size) |size| {
        if (size.width.type != .none and size.width.type != .grow) {
            if (size.width.type == .min_max_vp) {
                writer.write("max-width:") catch {};
                writer.writeF32(size.width.size.min_max_vp.max) catch {};
                writer.write("vw;\n") catch {};
                writer.write("min-width:") catch {};
                writer.writeF32(size.width.size.min_max_vp.max) catch {};
                writer.write("vw;\n") catch {};
            } else if (size.width.type == .elastic_percent) {
                writer.write("max-width:") catch {};
                writer.writeF32(size.width.size.min_max_vp.max) catch {};
                writer.write("%;\n") catch {};
                writer.write("min-width:") catch {};
                writer.writeF32(size.width.size.min_max_vp.max) catch {};
                writer.write("%;\n") catch {};
            } else {
                writePropValue("width", .{ .tag = .sizing, .data = .{ .sizing = size.width } }, &writer);
                // writePropValue("width", size.width, &writer);
            }
        } else if (size.width.type == .grow) {
            writer.write("flex: 1;\n") catch {};
        }

        if (size.height.type != .none and size.height.type != .grow) {
            if (size.height.type == .min_max_vp) {
                writer.write("min-height:") catch {};
                writer.writeF32(size.height.size.min_max_vp.min) catch {};
                writer.write("vh;\n") catch {};
            } else {
                writePropValue("height", .{ .tag = .sizing, .data = .{ .sizing = size.height } }, &writer);
                // writePropValue("height", size.height, &writer);
            }
        } else if (size.height.type == .grow) {
            writer.write("flex: 1;\n") catch {};
        }
    }

    // Padding
    if (style.padding) |padding| {
        writePropValue("padding", .{ .tag = .padding, .data = .{ .padding = padding } }, &writer);
        // writePropValue("padding", padding, &writer);
    }
    if (style.margin) |margin| {
        writePropValue("margin", .{ .tag = .margin, .data = .{ .margin = margin } }, &writer);
        // writePropValue("margin", margin, &writer);
    }

    if (style.visual) |visual| {
        checkVisual(ptr, &visual, &writer, 4);
    }

    // Alignment

    if (style.child_gap > 0) {
        writer.write("gap:") catch {};
        writer.writeU32(style.child_gap) catch {};
        writer.write("px;\n") catch {};
    }

    // Text-Deco
    if (style.text_decoration) |td| {
        writePropValue("text-decoration", .{ .tag = .text_decoration, .data = .{ .text_decoration = td } }, &writer);
        // writePropValue("text-decoration", td, &writer);
    }

    if (style.white_space) |ws| {
        writePropValue("white-space", .{ .tag = .white_space, .data = .{ .white_space = ws } }, &writer);
        // writePropValue("white-space", ws, &writer);
    }
    if (style.flex_wrap) |fw| {
        writePropValue("flex-wrap", .{ .tag = .flex_wrap, .data = .{ .flex_wrap = fw } }, &writer);
        // writePropValue("flex-wrap", fw, &writer);
    }

    if (style.animation) |an| {
        writePropValue("animation", .{ .tag = .animation_specs, .data = .{ .animation_specs = an } }, &writer);
        // writePropValue("animation", an, &writer);
        writer.write("animation-delay:") catch {};
        writer.writeF32(an.delay) catch {};
        writer.write("s;\n") catch {};
        // writer.print("animation-delay:{any}s;\n", .{an.delay}) catch {};
    }

    if (style.z_index) |zi| {
        writer.write("z-index:") catch {};
        writer.writeF32(zi) catch {};
        writer.write(";\n") catch {};
    }

    if (style.blur) |bl| {
        writer.write("backdrop-filter:blur(") catch {};
        writer.writeU32(bl) catch {};
        writer.write("px);\n") catch {};
    }

    if (style.scroll) |scroll| {
        if (scroll.x) |x| {
            switch (x) {
                .scroll => writer.write("overflow-x:scroll;\n") catch {},
                .hidden => writer.write("overflow-x:hidden;\n") catch {},
            }
        }
        if (scroll.y) |y| {
            switch (y) {
                .scroll => writer.write("overflow-y:scroll;\n") catch {},
                .hidden => writer.write("overflow-y:hidden;\n") catch {},
            }
        }

        if (style.position == null) {
            writer.write("position:relative;\n") catch {};
        }
    }

    if (style.list_style) |ls| {
        writePropValue("list-style", .{ .tag = .list_style, .data = .{ .list_style = ls } }, &writer);
        // writePropValue("list-style", ls, &writer);
    }

    if (style.outline) |ol| {
        writePropValue("outline", .{ .tag = .outline, .data = .{ .outline = ol } }, &writer);
        // writePropValue("outline", ol, &writer);
    }

    if (style.font_family.len > 0) {
        writer.write("font-family:") catch {};
        writer.write(style.font_family) catch {};
        writer.write(";\n") catch {};
    }

    if (style.transition) |tr| {
        writePropValue("transition", .{ .tag = .transition, .data = .{ .transition = tr } }, &writer);
        // writePropValue("transition", tr, &writer);
    }

    if (!style.show_scrollbar) {
        writer.write("scrollbar-width:none;\n") catch {};
        show_scrollbar = false;
    }

    if (style.cursor) |c| {
        writePropValue("cursor", .{ .tag = .cursor, .data = .{ .cursor = c } }, &writer);
        // writePropValue("cursor", c, &writer);
    } else if (ptr != null and ptr.?.type == .Button or ptr.?.type == .CtxButton or ptr.?.type == .ButtonCycle) {
        writePropValue("cursor", .{ .tag = .cursor, .data = .{ .cursor = .pointer } }, &writer);
    }

    if (style.appearance) |ap| {
        writePropValue("appearance", .{ .tag = .appearance, .data = .{ .appearance = ap } }, &writer);
        // writePropValue("appearance", ap, &writer);
    }

    if (style.will_change) |wc| {
        switch (wc) {
            .transform => {
                writer.write("will-change:") catch {};
                writer.write("transform") catch {};
                writer.write(";\n") catch {};
            },
            else => {},
        }
    }

    if (style.transform_origin) |to| {
        writePropValue("transform-origin", .{ .tag = .transform_origin, .data = .{ .transform_origin = to } }, &writer);
        // writePropValue("transform-origin", to, &writer);
    }

    writer.write("box-sizing: border-box;\n") catch {};

    // Null-terminate the string
    const len: usize = writer.pos;
    css_buffer[len] = 0;
    style_style = css_buffer[0..len];
}

pub export fn getStyle(node_ptr: ?*UINode) ?[*]const u8 {
    if (node_ptr == null) return style_style.ptr;
    const style = node_ptr.?.style orelse return null;
    generateStyle(node_ptr, &style);
    // Return a pointer to the CSS string
    return style_style.ptr;
}

export fn showScrollBar() bool {
    return show_scrollbar;
}

export fn getStyleLen() usize {
    return style_style.len;
}

var visual_style: []const u8 = "";
pub export fn getVisualStyle(node_ptr: ?*UINode, visual_type: u8) ?[*]const u8 {
    if (node_ptr == null) return visual_style.ptr;
    const node_style = node_ptr.?.style orelse return null;
    const interactive = node_style.interactive orelse return null;
    const ptr = node_ptr.?;
    var writer: Writer = undefined;
    writer.init(&css_buffer);
    if (visual_type == 0) {
        const visual = interactive.hover.?;
        checkVisual(ptr, &visual, &writer, 0);
    } else if (visual_type == 1) {
        const visual = interactive.focus.?;
        checkVisual(ptr, &visual, &writer, 1);
    } else if (visual_type == 2) {
        const visual = interactive.focus_within.?;
        checkVisual(ptr, &visual, &writer, 2);
    }
    // Null-terminate the string
    const len: usize = writer.pos;
    css_buffer[len] = 0;
    visual_style = css_buffer[0..len];

    // Return a pointer to the CSS string
    return visual_style.ptr;
}

export fn getVisualLen() usize {
    return visual_style.len;
}

test "generateCss" {
    var node = UINode{
        .style = &.{
            .position = .{ .top = .px(100), .right = .px(600) },
            .layout = .Flex,
            .direction = .row,
            .child_gap = 0,
            .font_family = "",
            .padding = .horizontal(16),
            .visual = .{
                .opacity = 1,
                .background = .{ .a = 255, .r = 0, .g = 0, .b = 0 },
                .border = .{ .thickness = .all(1), .color = .hex("#DFDFDF"), .radius = .all(8) },
            },
            .text_decoration = .underline,
            .white_space = .pre_line,
            .flex_wrap = .wrap,
            .cursor = .pointer,
        },
    };

    _ = getStyle(&node) orelse return error.StyleNull;
    const len = getStyleLen();
    std.debug.print("{s}\n", .{css_buffer[0..len]});
}

