const std = @import("std");
const Fabric = @import("Fabric.zig");
const Types = @import("types.zig");
const UINode = @import("UITree.zig").UINode;

// Type aliases for brevity
const writer_t = std.io.FixedBufferStream([]u8).Writer;

// Global Buffers and State
var css_buffer: [4096]u8 = undefined;
var checkmark_css_buffer: [4096]u8 = undefined;
var css_slice: []const u8 = "";
var checkmark_css_slice: []const u8 = "";
var g_show_scrollbar: bool = true;

// --- Helper Functions ---
// These functions convert Zig enums and structs to their corresponding CSS string values.

fn directionToCSS(dir: ?Types.Direction) []const u8 {
    return switch (dir orelse return "column") {
        .column => "column",
        .row => "row",
    };
}

fn alignmentToCSS(alignment: Types.Alignment) []const u8 {
    return switch (alignment) {
        .center => "center",
        .top, .start => "flex-start",
        .bottom, .end => "flex-end",
        .between => "space-between",
        .even => "space-evenly",
    };
}

fn positionTypeToCSS(pos_type: Types.PositionType) []const u8 {
    return @tagName(pos_type);
}

fn sizingTypeToCSS(sizing: Types.Sizing, writer: writer_t) !void {
    switch (sizing.type) {
        .fit => try writer.writeAll("fit-content"),
        .percent => try writer.print("{d}%", .{sizing.size.minmax.min}),
        .fixed => try writer.print("{d}px", .{sizing.size.minmax.min}),
        .elastic => try writer.writeAll("auto"),
        .elastic_percent => try writer.print("{d}%", .{sizing.size.percent.min}),
        .clamp_px => try writer.print("clamp({d}px,{d}px,{d}px)", .{ sizing.size.clamp_px.min, sizing.size.clamp_px.preferred, sizing.size.clamp_px.max }),
        .clamp_percent => try writer.print("clamp({d}%,{d}%,{d}%)", .{ sizing.size.clamp_px.min, sizing.size.clamp_px.preferred, sizing.size.clamp_px.max }),
        .none, .grow => {},
        else => {},
    }
}

fn posTypeToCSS(pos: Types.Pos, writer: writer_t) !void {
    switch (pos.type) {
        .fit => try writer.writeAll("fit-content"),
        .grow => try writer.writeAll("auto"),
        .percent => try writer.print("{d}%", .{pos.value}),
        .fixed => try writer.print("{d}px", .{pos.value}),
    }
}

fn colorToCSS(color: Types.Background, writer: writer_t) !void {
    const alpha = @as(f32, @floatFromInt(color.a)) / 255.0;
    try writer.print("rgba({d},{d},{d},{d})", .{ color.r, color.g, color.b, alpha });
}

fn enumToKebabCase(comptime E: type, value: E, writer: writer_t) !void {
    const name = @tagName(value);
    var it = std.mem.splitScalar(u8, name, '_');
    if (it.next()) |part| {
        try writer.writeAll(part);
    }
    while (it.next()) |part| {
        try writer.print("-{s}", .{part});
    }
}

fn transitionStyleToCSS(style: Types.Transition, writer: anytype) void {
    if (style.properties) |prop| {
        for (prop) |p| {
            switch (p) {
                .transform => {
                    writer.print("{s} ", .{@tagName(p)}) catch return;
                },
                else => {},
            }
        }
    } else {
        writer.print("{s} ", .{"all"}) catch return;
    }
    writer.print("{any}ms ", .{style.duration}) catch return;
    switch (style.timing) {
        .ease => writer.writeAll("ease") catch return,
        .linear => writer.writeAll("linear") catch return,
        .ease_in => writer.writeAll("ease-in") catch return,
        .ease_out => writer.writeAll("ease-out") catch return,
        .ease_in_out => writer.writeAll("ease-in-out") catch return,
        .bounce => writer.writeAll("bounce") catch return,
        .elastic => writer.writeAll("elastic") catch return,
    }
}

fn animationToCSS(animation: Fabric.Animation.Specs, writer: anytype) !void {
    try writer.print("{s} {any}s ", .{ animation.tag, animation.duration_s });
    switch (animation.timing_function) {
        .linear => try writer.writeAll("linear "),
        .ease => try writer.writeAll("ease "),
        .ease_in => try writer.writeAll("ease-in "),
        .ease_in_out => try writer.writeAll("ease-in-out "),
        .ease_out => try writer.writeAll("ease_out "),
    }
    switch (animation.direction) {
        .normal => try writer.writeAll("normal "),
        .reverse => try writer.writeAll("reverse "),
        .forwards => try writer.writeAll("forwards "),
        .pingpong => try writer.writeAll("alternate "),
    }
    if (animation.iteration_count.iter_count == 0) {
        try writer.writeAll("infinite");
    } else {
        // try writer.print("{d}", .{animation.iteration_count.iter_count});
    }
}

/// This is the core function that generates a CSS string from a style object.
/// It eliminates code duplication by handling CSS generation for any style struct
/// that follows the expected structure (e.g., fields are optionals).
fn generateCssFromStyle(style: anytype, node: *const UINode, writer: writer_t) !void {
    // Position
    if (style.position) |p| {
        try writer.print("position:{s};", .{positionTypeToCSS(p.type)});
        try writer.writeAll("left:");
        try posTypeToCSS(p.left, writer);
        try writer.writeAll(";");
        try writer.writeAll("right:");
        try posTypeToCSS(p.right, writer);
        try writer.writeAll(";");
        try writer.writeAll("top:");
        try posTypeToCSS(p.top, writer);
        try writer.writeAll(";");
        try writer.writeAll("bottom:");
        try posTypeToCSS(p.bottom, writer);
        try writer.writeAll(";");
    }

    // Display & Flex Layout
    if (node.type == .FlexBox) {
        try writer.writeAll("display:flex;");
        try writer.print("flex-direction:{s};", .{directionToCSS(style.direction)});
        if (style.direction == .row) {
            try writer.print("justify-content:{s};align-items:{s};", .{ alignmentToCSS(style.child_alignment.x), alignmentToCSS(style.child_alignment.y) });
        } else {
            try writer.print("align-items:{s};justify-content:{s};", .{ alignmentToCSS(style.child_alignment.x), alignmentToCSS(style.child_alignment.y) });
        }
    } else if (style.display) |d| {
        if (node.text.len > 0 and d == .Center and node.type != .Svg) {
            try writer.writeAll("text-align:center;");
        } else {
            try writer.print("display:{s};flex-direction:{s};", .{ @tagName(d), directionToCSS(style.direction) });
            if (d == .Center) {
                try writer.writeAll("justify-content:center;align-items:center;");
            } else if (style.direction == .row) {
                try writer.print("justify-content:{s};align-items:{s};", .{ alignmentToCSS(style.child_alignment.x), alignmentToCSS(style.child_alignment.y) });
            } else {
                try writer.print("align-items:{s};justify-content:{s};", .{ alignmentToCSS(style.child_alignment.x), alignmentToCSS(style.child_alignment.y) });
            }
        }
    }

    // Sizing
    inline for (.{ "width", "height" }) |prop| {
        const sizing = @field(style, prop);
        if (sizing.type == .grow) {
            try writer.writeAll("flex:1;");
        } else if (sizing.type != .none) {
            if (style.width.type == .min_max_vp) {
                writer.writeAll("  max-width: ") catch {};
                writer.print("{d}vw", .{style.width.size.min_max_vp.max}) catch {};
                writer.writeAll(";\n") catch {};
                writer.writeAll("  min-width: ") catch {};
                writer.print("{d}vw", .{style.width.size.min_max_vp.min}) catch {};
                writer.writeAll(";\n") catch {};
            } else if (style.width.type == .elastic_percent) {
                writer.writeAll("  max-width: ") catch {};
                writer.print("{d}%", .{style.width.size.percent.max}) catch {};
                writer.writeAll(";\n") catch {};
                writer.writeAll("  min-width: ") catch {};
                writer.print("{d}%", .{style.width.size.percent.min}) catch {};
                writer.writeAll(";\n") catch {};
            } else {
                try writer.print("{s}:", .{prop});
                try sizingTypeToCSS(sizing, writer);
                try writer.writeAll(";");
            }
        }
    }

    // Font
    if (style.font_size) |fs| try writer.print("font-size:{d}px;", .{fs});
    if (style.font_weight) |fw| try writer.print("font-weight:{d};", .{fw});
    if (style.font_family.len > 0) try writer.print("font-family:{s};", .{style.font_family});
    if (style.letter_spacing) |ls| try writer.print("letter-spacing:{}px;", .{@as(f32, @floatFromInt(ls)) / 1000.0});
    if (style.line_height) |lh| try writer.print("line-height:{d}px;", .{lh});

    // Border
    var b_thick = style.border_thickness;
    var b_color = style.border_color;
    var b_radius = style.border_radius;
    if (style.border) |b| {
        b_thick = b.thickness;
        b_color = b.color;
        b_radius = b.radius;
    }
    if (b_thick) |bt| {
        try writer.print("border-width:{d}px {d}px {d}px {d}px;border-style:solid;", .{ bt.top, bt.right, bt.bottom, bt.left });
        if (b_color) |bc| {
            try writer.writeAll("border-color:");
            try colorToCSS(bc, writer);
            try writer.writeAll(";");
        }
    } else if (node.type == .Button or node.type == .CtxButton) {
        try writer.writeAll("border-width:0px;");
    }
    if (b_radius) |br| try writer.print("border-radius:{d}px {d}px {d}px {d}px;", .{ br.top_left, br.top_right, br.bottom_right, br.bottom_left });

    // Color & Background
    if (style.text_color) |c| {
        try writer.writeAll("color:");
        try colorToCSS(c, writer);
        try writer.writeAll(";");
    }
    if (style.background) |bg| {
        try writer.writeAll("background-color:");
        try colorToCSS(bg, writer);
        try writer.writeAll(";");
    } else if (node.type == .Button or node.type == .CtxButton) {
        try writer.writeAll("background-color:rgba(0,0,0,0);");
    }

    // Spacing
    if (style.padding) |p| try writer.print("padding:{d}px {d}px {d}px {d}px;", .{ p.top, p.right, p.bottom, p.left });
    if (style.margin) |m| try writer.print("margin:{d}px {d}px {d}px {d}px;", .{ m.top, m.right, m.bottom, m.left });
    if (style.child_gap > 0) try writer.print("gap:{d}px;", .{style.child_gap});

    // Effects
    if (style.shadow.blur > 0 or style.shadow.spread > 0 or style.shadow.top > 0 or style.shadow.left > 0) {
        try writer.print("box-shadow:{d}px {d}px {d}px {d}px ", .{ style.shadow.left, style.shadow.top, style.shadow.blur, style.shadow.spread });
        try colorToCSS(style.shadow.color, writer);
        try writer.writeAll(";");
    }
    if (style.blur) |bl| try writer.print("backdrop-filter:blur({d}px);", .{bl});

    // Text & Overflow
    if (style.text_decoration) |td| try writer.print("text-decoration:{s};", .{@tagName(td)});
    if (style.white_space) |ws| {
        try writer.writeAll("white-space:");
        try enumToKebabCase(Types.WhiteSpace, ws, writer);
        try writer.writeAll(";");
    }
    if (style.flex_wrap) |fw| {
        try writer.writeAll("flex-wrap:");
        try enumToKebabCase(Types.FlexWrap, fw, writer);
        try writer.writeAll(";");
    }
    if (style.overflow) |o| try writer.print("overflow:{s};", .{@tagName(o)});
    if (style.overflow_x) |ox| try writer.print("overflow-x:{s};", .{@tagName(ox)});
    if (style.overflow_y) |oy| try writer.print("overflow-y:{s};", .{@tagName(oy)});

    // Animation & Transition
    if (style.animation) |an| {
        try writer.writeAll("animation:");
        try animationToCSS(an, writer);
        try writer.writeAll(";");
        try writer.print("animation-delay:{any}s;", .{an.delay});
    }
    if (style.transition) |tr| {
        try writer.writeAll("transition:");
        transitionStyleToCSS(tr, writer);
        try writer.writeAll(";");
    }

    // Misc Styles
    if (style.z_index) |zi| try writer.print("z-index:{d};", .{zi});
    if (style.list_style) |ls| try writer.print("list-style:{s};", .{@tagName(ls)});
    if (style.outline) |ol| try writer.print("outline:{s};", .{@tagName(ol)});
    if (style.cursor) |c| try writer.print("cursor:{s};", .{@tagName(c)});
    if (style.appearance) |ap| try writer.print("appearance:{s};", .{@tagName(ap)});
    if (style.will_change) |wc| try writer.print("will-change:{s};", .{@tagName(wc)});
    if (!style.show_scrollbar) {
        try writer.writeAll("scrollbar-width:none;");
        g_show_scrollbar = false;
    }

    // Transform
    if (style.transform) |tr| {
        try writer.writeAll("transform:");
        switch (tr.type) {
            .none => {},
            .scale => try writer.print("scale({d})", .{tr.scale_size}),
            .scaleY => try writer.print("scaleY({d})", .{tr.scale_size}),
            .scaleX => try writer.print("scaleX({d})", .{tr.scale_size}),
            .translateX => try writer.print("translateX({d}%)", .{tr.percent * 100}),
            .translateY => try writer.print("translateY({d}%)", .{tr.percent * 100}),
        }
        try writer.writeAll(";");
    }
    if (style.transform_origin) |to| try writer.print("transform-origin:{s};", .{@tagName(to)});
}

// --- Exported Functions ---

pub export fn getStyle(node_ptr: ?*UINode) [*]const u8 {
    const node = node_ptr orelse return css_slice.ptr;

    var fbs = std.io.fixedBufferStream(&css_buffer);
    generateCssFromStyle(node.style, node, fbs.writer()) catch {};

    const len = fbs.getPos() catch 0;
    css_buffer[@as(usize, @intCast(len))] = 0;
    css_slice = css_buffer[0..@as(usize, @intCast(len))];
    return css_slice.ptr;
}

pub export fn getCheckMarkStylePtr(node_ptr: ?*UINode) [*]const u8 {
    _ = node_ptr orelse return checkmark_css_slice.ptr;
    // const checkmark_style = node.style.checkmark_style orelse return checkmark_css_slice.ptr;
    //
    // var fbs = std.io.fixedBufferStream(&checkmark_css_buffer);
    // generateCssFromStyle(checkmark_style, node, fbs.writer()) catch {};
    //
    // const len = fbs.getPos() catch 0;
    // checkmark_css_buffer[len] = 0;
    // checkmark_css_slice = checkmark_css_buffer[0..len];
    return checkmark_css_slice.ptr;
}

pub export fn showScrollBar() bool {
    return g_show_scrollbar;
}

pub export fn getStyleLen() usize {
    return css_slice.len;
}
