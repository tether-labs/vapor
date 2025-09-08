const std = @import("std");
const Fabric = @import("Fabric.zig");
const Types = @import("types.zig");
const UINode = @import("UITree.zig").UINode;

const writer_t = std.io.FixedBufferStream([]u8).Writer;

// --- Global State ---
var css_buffer: [4096]u8 = undefined;
var css_slice: []const u8 = "";
var g_show_scrollbar: bool = true;

// --- Lightweight Writer Helpers (to replace std.fmt.print) ---
// Using std.fmt.formatInt is a good compromise, providing integer formatting
// without the large overhead of the full print() function.
fn writeInt(w: writer_t, n: anytype) !void {
    switch (@typeInfo(@TypeOf(n))) {
        .int => {
            try std.fmt.formatInt(n, 10, .lower, .{}, w);
        },
        .float => {
            var buf: [20]u8 = undefined;
            const float_buf = try std.fmt.formatFloat(&buf, n, .{});
            try w.writeAll(float_buf);
        },
        else => unreachable,
    }
}

// Custom alpha-to-string to avoid float formatting.
fn writeAlpha(w: writer_t, alpha_u8: u8) !void {
    if (alpha_u8 == 255) return w.writeByte('1');
    if (alpha_u8 == 0) return w.writeByte('0');
    try w.writeAll("0.");
    // Fast integer-based approximation of (alpha * 1000) / 255
    var val = @as(u32, alpha_u8) * 1000 / 255;
    if (val > 999) val = 999; // cap value
    var buf: [3]u8 = .{ '0', '0', '0' };
    std.fmt.formatInt(val, 10, .lower, .{ .fill = '0' }, w) catch {};
    // Trim trailing zeros
    if (buf[2] == '0') {
        if (buf[1] == '0') {
            try w.writeAll(buf[0..1]);
        } else {
            try w.writeAll(buf[0..2]);
        }
    } else {
        try w.writeAll(&buf);
    }
}

// --- Optimized CSS Conversion Helpers ---

fn directionToCSS(dir: ?Types.Direction) []const u8 {
    // comptime array lookup is smaller and faster than a runtime switch.
    const mapping = [_][]const u8{ "column", "row" };
    return mapping[@intFromEnum(dir orelse .column)];
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

// Simpler kebab-case converter.
fn enumToKebabCase(name: []const u8, writer: writer_t) !void {
    for (name) |char| {
        try writer.writeByte(if (char == '_') '-' else char);
    }
}

fn sizingTypeToCSS(prop: []const u8, sizing: Types.Sizing, writer: writer_t) !void {
    switch (sizing.type) {
        .fit => try writer.print("{s}:fit-content", .{prop}),
        .grow => try writer.writeAll("flex:1"),
        .percent => try writer.print("{s}:{d}%", .{ prop, sizing.size.minmax.min }),
        .fixed => try writer.print("{s}:{d}px", .{ prop, sizing.size.minmax.min }),
        .elastic => try writer.print("{s}:auto", .{prop}),
        .clamp_px => try writer.print("{s}:clamp({d}px,{d}px,{d}px)", .{ prop, sizing.size.clamp_px.min, sizing.size.clamp_px.preferred, sizing.size.clamp_px.max }),
        .clamp_percent => try writer.print("{s}:clamp({d}%,{d}%,{d}%)", .{ prop, sizing.size.clamp_px.min, sizing.size.clamp_px.preferred, sizing.size.clamp_px.max }),
        .min_max_vp => try writer.print("max-{s}:{d}vw;min-{s}:{d}vw", .{ prop, sizing.size.min_max_vp.max, prop, sizing.size.min_max_vp.min }),
        .elastic_percent => try writer.print("max-{s}:{d}%;min-{s}:{d}%", .{ prop, sizing.size.percent.max, prop, sizing.size.percent.min }),
        .none => {},
    }
}

fn posTypeToCSS(pos: Types.Pos, writer: writer_t) !void {
    switch (pos.type) {
        .fit => try writer.writeAll("fit-content"),
        .grow => try writer.writeAll("auto"),
        .percent => {
            try writeInt(writer, pos.value);
            try writer.writeByte('%');
        },
        .fixed => {
            try writeInt(writer, pos.value);
            try writer.writeAll("px");
        },
    }
}

fn colorToCSS(color: Types.Background, writer: writer_t) !void {
    try writer.writeAll("rgba(");
    try writeInt(writer, color.r);
    try writer.writeByte(',');
    try writeInt(writer, color.g);
    try writer.writeByte(',');
    try writeInt(writer, color.b);
    try writer.writeByte(',');
    try writeAlpha(writer, color.a);
    try writer.writeByte(')');
}

fn writeFourValues(p: []const u8, vals: anytype, s: []const u8, w: writer_t) !void {
    switch (@TypeOf(vals)) {
        Types.BorderRadius => {
            try w.print("{s}:{d}{s} {d}{s} {d}{s} {d}{s};", .{ p, vals.top_left, s, vals.top_right, s, vals.bottom_right, s, vals.bottom_left, s });
        },
        Types.Padding, Types.Margin, Types.Border => {
            try w.print("{s}:{d}{s} {d}{s} {d}{s} {d}{s};", .{ p, vals.top, s, vals.right, s, vals.bottom, s, vals.left, s });
        },
        else => unreachable,
    }
}

// --- Core CSS Generation Logic (Shared Function) ---

/// This function contains the core logic for writing CSS properties.
/// It is called by both getStyle (for inline styles) and addEctClasses (for CSS classes).
fn writeStyleProperties(style: anytype, node: *const UINode, writer: writer_t) !void {
    // Position
    if (style.position) |p| {
        try writer.print("position:{s};left:", .{@tagName(p.type)});
        try posTypeToCSS(p.left, writer);
        try writer.writeAll(";right:");
        try posTypeToCSS(p.right, writer);
        try writer.writeAll(";top:");
        try posTypeToCSS(p.top, writer);
        try writer.writeAll(";bottom:");
        try posTypeToCSS(p.bottom, writer);
        try writer.writeByte(';');
    }

    // Display & Flex Layout
    if (node.type == .FlexBox or (style.display != null and style.display != .Center)) {
        try writer.writeAll("display:flex;");
        const dir = directionToCSS(style.direction);
        try writer.print("flex-direction:{s};", .{dir});
        if (@typeInfo(@TypeOf(style.child_alignment)) == .optional) {
            if (style.child_alignment) |ca| {
                const x = alignmentToCSS(ca.x);
                const y = alignmentToCSS(ca.y);
                if (style.direction == .row) {
                    try writer.print("justify-content:{s};align-items:{s};", .{ x, y });
                } else {
                    try writer.print("align-items:{s};justify-content:{s};", .{ y, x });
                }
            }
        } else {
            const x = alignmentToCSS(style.child_alignment.x);
            const y = alignmentToCSS(style.child_alignment.y);
            if (style.direction == .row) {
                try writer.print("justify-content:{s};align-items:{s};", .{ x, y });
            } else {
                try writer.print("align-items:{s};justify-content:{s};", .{ y, x });
            }
        }
    } else if (style.display) |d| {
        if (node.text.len > 0 and d == .Center and node.type != .Svg) {
            try writer.writeAll("text-align:center;");
        } else if (d == .Center) {
            try writer.writeAll("display:flex;justify-content:center;align-items:center;");
        }
    }

    // Sizing (Refactored logic)
    inline for (.{ "width", "height" }) |prop| {
        const sizing = @field(style, prop);

        if (@typeInfo(@TypeOf(sizing)) == .optional) {
            if (sizing) |s| {
                if (s.type != .none) {
                    try sizingTypeToCSS(prop, s, writer);
                    try writer.writeByte(';');
                }
            }
        } else {
            if (sizing.type != .none) {
                try sizingTypeToCSS(prop, sizing, writer);
                try writer.writeByte(';');
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
        try writeFourValues("border-width", bt, "px", writer);
        try writer.writeAll("border-style:solid;");
        if (b_color) |bc| {
            try writer.writeAll("border-color:");
            try colorToCSS(bc, writer);
            try writer.writeByte(';');
        }
    } else if (node.type == .Button or node.type == .CtxButton) {
        try writer.writeAll("border-width:0;");
    }
    if (b_radius) |br| try writeFourValues("border-radius", br, "px", writer);

    // Color & Background
    if (style.text_color) |c| {
        try writer.writeAll("color:");
        try colorToCSS(c, writer);
        try writer.writeByte(';');
    }
    if (style.background) |bg| {
        try writer.writeAll("background-color:");
        try colorToCSS(bg, writer);
        try writer.writeByte(';');
    } else if (node.type == .Button or node.type == .CtxButton) {
        try writer.writeAll("background-color:transparent;");
    }

    // Spacing
    if (style.padding) |p| try writeFourValues("padding", p, "px", writer);
    if (style.margin) |m| try writeFourValues("margin", m, "px", writer);
    if (style.child_gap > 0) try writer.print("gap:{d}px;", .{style.child_gap});

    // Effects
    if (style.shadow.blur > 0 or style.shadow.spread > 0 or style.shadow.top > 0 or style.shadow.left > 0) {
        try writer.print("box-shadow:{d}px {d}px {d}px {d}px ", .{ style.shadow.left, style.shadow.top, style.shadow.blur, style.shadow.spread });
        try colorToCSS(style.shadow.color, writer);
        try writer.writeByte(';');
    }
    if (style.blur) |bl| try writer.print("backdrop-filter:blur({d}px);", .{bl});

    // Text & Overflow
    inline for (.{ "text_decoration", "overflow", "overflow_x", "overflow_y", "list_style", "outline", "cursor", "appearance", "will_change", "transform_origin" }) |p| {
        if (@field(style, p)) |val| {
            try writer.writeAll(p);
            try writer.writeAll(":");
            try enumToKebabCase(@tagName(val), writer);
            try writer.writeByte(';');
        }
    }
    inline for (.{ "white_space", "flex_wrap" }) |p| {
        if (@field(style, p)) |val| {
            try writer.writeAll(p);
            try writer.writeAll(":");
            try enumToKebabCase(@tagName(val), writer);
            try writer.writeByte(';');
        }
    }

    // Misc & Transform
    if (style.z_index) |zi| try writer.print("z-index:{d};", .{zi});
    if (!style.show_scrollbar) {
        try writer.writeAll("scrollbar-width:none;");
        g_show_scrollbar = false;
    }
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
        try writer.writeByte(';');
    }
}

// // --- Core CSS Generation Logic ---
//
// fn generateCssFromStyle(style: anytype, node: *const UINode, writer: writer_t) !void {
//     // Position
//     if (style.position) |p| {
//         try writer.print("position:{s};left:", .{@tagName(p.type)});
//         try posTypeToCSS(p.left, writer);
//         try writer.writeAll(";right:");
//         try posTypeToCSS(p.right, writer);
//         try writer.writeAll(";top:");
//         try posTypeToCSS(p.top, writer);
//         try writer.writeAll(";bottom:");
//         try posTypeToCSS(p.bottom, writer);
//         try writer.writeByte(';');
//     }
//
//     // Display & Flex Layout
//     if (node.type == .FlexBox or (style.display != null and style.display != .Center)) {
//         try writer.writeAll("display:flex;");
//         const dir = directionToCSS(style.direction);
//         try writer.print("flex-direction:{s};", .{dir});
//         const x = alignmentToCSS(style.child_alignment.x);
//         const y = alignmentToCSS(style.child_alignment.y);
//         if (style.direction == .row) {
//             try writer.print("justify-content:{s};align-items:{s};", .{ x, y });
//         } else {
//             try writer.print("align-items:{s};justify-content:{s};", .{ y, x });
//         }
//     } else if (style.display) |d| {
//         if (node.text.len > 0 and d == .Center and node.type != .Svg) {
//             try writer.writeAll("text-align:center;");
//         } else if (d == .Center) {
//             try writer.writeAll("display:flex;justify-content:center;align-items:center;");
//         }
//     }
//
//     // Sizing (Refactored logic)
//     inline for (.{ "width", "height" }) |prop| {
//         const sizing = @field(style, prop);
//         if (sizing.type != .none) {
//             try sizingTypeToCSS(prop, sizing, writer);
//             try writer.writeByte(';');
//         }
//     }
//
//     // Font
//     if (style.font_size) |fs| try writer.print("font-size:{d}px;", .{fs});
//     if (style.font_weight) |fw| try writer.print("font-weight:{d};", .{fw});
//     if (style.font_family.len > 0) try writer.print("font-family:{s};", .{style.font_family});
//     if (style.letter_spacing) |ls| try writer.print("letter-spacing:{}px;", .{@as(f32, @floatFromInt(ls)) / 1000.0});
//     if (style.line_height) |lh| try writer.print("line-height:{d}px;", .{lh});
//
//     // Border
//     var b_thick = style.border_thickness;
//     var b_color = style.border_color;
//     var b_radius = style.border_radius;
//     if (style.border) |b| {
//         b_thick = b.thickness;
//         b_color = b.color;
//         b_radius = b.radius;
//     }
//     if (b_thick) |bt| {
//         try writeFourValues("border-width", bt, "px", writer);
//         try writer.writeAll("border-style:solid;");
//         if (b_color) |bc| {
//             try writer.writeAll("border-color:");
//             try colorToCSS(bc, writer);
//             try writer.writeByte(';');
//         }
//     } else if (node.type == .Button or node.type == .CtxButton) {
//         try writer.writeAll("border-width:0;");
//     }
//     if (b_radius) |br| try writeFourValues("border-radius", br, "px", writer);
//
//     // Color & Background
//     if (style.text_color) |c| {
//         try writer.writeAll("color:");
//         try colorToCSS(c, writer);
//         try writer.writeByte(';');
//     }
//     if (style.background) |bg| {
//         try writer.writeAll("background-color:");
//         try colorToCSS(bg, writer);
//         try writer.writeByte(';');
//     } else if (node.type == .Button or node.type == .CtxButton) {
//         try writer.writeAll("background-color:transparent;");
//     }
//
//     // Spacing
//     if (style.padding) |p| try writeFourValues("padding", p, "px", writer);
//     if (style.margin) |m| try writeFourValues("margin", m, "px", writer);
//     if (style.child_gap > 0) try writer.print("gap:{d}px;", .{style.child_gap});
//
//     // Effects
//     if (style.shadow.blur > 0 or style.shadow.spread > 0 or style.shadow.top > 0 or style.shadow.left > 0) {
//         try writer.print("box-shadow:{d}px {d}px {d}px {d}px ", .{ style.shadow.left, style.shadow.top, style.shadow.blur, style.shadow.spread });
//         try colorToCSS(style.shadow.color, writer);
//         try writer.writeByte(';');
//     }
//     if (style.blur) |bl| try writer.print("backdrop-filter:blur({d}px);", .{bl});
//
//     // Text & Overflow
//     inline for (.{ "text_decoration", "overflow", "overflow_x", "overflow_y", "list_style", "outline", "cursor", "appearance", "will_change", "transform_origin" }) |p| {
//         if (@field(style, p)) |val| {
//             try writer.writeAll(p);
//             try writer.writeAll(":");
//             try enumToKebabCase(@tagName(val), writer);
//             try writer.writeByte(';');
//         }
//     }
//     inline for (.{ "white_space", "flex_wrap" }) |p| {
//         if (@field(style, p)) |val| {
//             try writer.writeAll(p);
//             try writer.writeAll(":");
//             try enumToKebabCase(@tagName(val), writer);
//             try writer.writeByte(';');
//         }
//     }
//
//     // Misc & Transform
//     if (style.z_index) |zi| try writer.print("z-index:{d};", .{zi});
//     if (!style.show_scrollbar) {
//         try writer.writeAll("scrollbar-width:none;");
//         g_show_scrollbar = false;
//     }
//     if (style.transform) |tr| {
//         try writer.writeAll("transform:");
//         switch (tr.type) {
//             .none => {},
//             .scale => try writer.print("scale({d})", .{tr.scale_size}),
//             .scaleY => try writer.print("scaleY({d})", .{tr.scale_size}),
//             .scaleX => try writer.print("scaleX({d})", .{tr.scale_size}),
//             .translateX => try writer.print("translateX({d}%)", .{tr.percent * 100}),
//             .translateY => try writer.print("translateY({d}%)", .{tr.percent * 100}),
//         }
//         try writer.writeByte(';');
//     }
// }

// // --- Exported Functions ---
//
// pub export fn getStyle(node_ptr: ?*UINode) [*]const u8 {
//     const node = node_ptr orelse return css_slice.ptr;
//
//     var fbs = std.io.fixedBufferStream(&css_buffer);
//     generateCssFromStyle(node.style, node, fbs.writer()) catch {
//         // On error, return an empty string to avoid crashing.
//         css_slice = css_buffer[0..0];
//         return css_slice.ptr;
//     };
//
//     // No need for null termination if the slice length is correct.
//     const len = fbs.getPos() catch 0;
//     css_slice = css_buffer[0..@as(usize, @intCast(len))];
//     return css_slice.ptr;
// }

// --- Exported Functions ---

pub export fn getStyle(node_ptr: ?*UINode) [*]const u8 {
    const node = node_ptr orelse return css_slice.ptr;

    var fbs = std.io.fixedBufferStream(&css_buffer);
    // Call the shared style generation logic
    writeStyleProperties(node.style, node, fbs.writer()) catch {
        css_slice = css_buffer[0..0];
        return css_slice.ptr;
    };

    const len = fbs.getPos() catch 0;
    css_slice = css_buffer[0..@as(usize, @intCast(len))];
    return css_slice.ptr;
}

/// Generates CSS classes for child styles (e.g., hover, focus) and injects them.
pub export fn addEctClasses(node_ptr: ?*UINode) void {
    const node = node_ptr orelse return;
    const child_styles = node.style.child_styles orelse return;

    for (child_styles) |style| {
        var fbs = std.io.fixedBufferStream(&css_buffer);
        const writer = fbs.writer();

        // Write class selector and opening brace
        writer.print(".{s} {{", .{style.style_id}) catch continue;

        // Call the shared style generation logic
        writeStyleProperties(style, node, writer) catch continue;

        // Close CSS block
        writer.writeByte('}') catch continue;

        const len = fbs.getPos() catch {};
        const class_style_slice = css_buffer[0..@as(usize, @intCast(len))];

        // Assuming Fabric.createClass is an import that handles class injection
        Fabric.createClass(class_style_slice.ptr, class_style_slice.len);
    }
}

pub export fn showScrollBar() bool {
    return g_show_scrollbar;
}

pub export fn getStyleLen() usize {
    return css_slice.len;
}

export fn hasEctClasses(node_ptr: ?*UINode) usize {
    if (node_ptr == null) return 0;
    const style = node_ptr.?.style;
    if (style.child_styles) |_| {
        return 1;
    }
    return 0;
}

// export fn addEctClasses(node_ptr: ?*UINode) void {
//     if (node_ptr == null) return;
//     const node_style = node_ptr.?.style;
//     // const ptr = node_ptr.?;
//     // Create a default Hover style
//
//     for (node_style.child_styles.?) |style| {
//         // Use a fixed buffer with a fbs to build the CSS string
//         var fbs = std.io.fixedBufferStream(&css_buffer);
//         var writer = fbs.writer();
//
//         // Write position properties
//         writer.print(".{s} ", .{style.style_id}) catch {};
//         writer.writeAll("{\n") catch {};
//         // Write position properties
//         if (style.position) |p| {
//             writer.print("  position: {s};\n", .{positionTypeToCSS(p.type)}) catch {};
//             writer.writeAll("  left: ") catch {};
//             posTypeToCSS(p.left, writer) catch {};
//             writer.writeAll(";\n") catch {};
//
//             writer.writeAll("  right: ") catch {};
//             posTypeToCSS(p.right, writer) catch {};
//             writer.writeAll(";\n") catch {};
//
//             writer.writeAll("  top: ") catch {};
//             posTypeToCSS(p.top, writer) catch {};
//             writer.writeAll(";\n") catch {};
//
//             writer.writeAll("  bottom: ") catch {};
//             posTypeToCSS(p.bottom, writer) catch {};
//             writer.writeAll(";\n") catch {};
//         }
//         // // Write display and flex properties
//         // if (ptr.type == .FlexBox or ptr.type == .List or style.display != null) {
//         //     writer.writeAll("  display: flex;\n") catch {};
//         //     writer.print("  flex-direction: {s};\n", .{directionToCSS(style.direction)}) catch {};
//         // }
//
//         // Write width and height
//         if (style.display) |d| {
//             writer.writeAll("  display: ") catch {};
//             flexTypeToCSS(d, writer) catch {};
//             writer.writeAll(";\n") catch {};
//         }
//
//         // Write width and height
//         if (style.width) |hw| {
//             if (hw.type != .none) {
//                 writer.writeAll("  width: ") catch {};
//                 sizingTypeToCSS(hw, writer) catch {};
//                 writer.writeAll(";\n") catch {};
//             }
//         }
//
//         if (style.height) |hh| {
//             if (hh.type != .none) {
//                 writer.writeAll("  height: ") catch {};
//                 sizingTypeToCSS(hh, writer) catch {};
//                 writer.writeAll(";\n") catch {};
//             }
//         }
//
//         // Border properties
//         if (style.border_thickness) |hbt| {
//             if (hbt.top > 0 or
//                 hbt.right > 0 or
//                 hbt.bottom > 0 or
//                 hbt.left > 0)
//             {
//                 writer.print("  border-width: {d}px {d}px {d}px {d}px;\n", .{
//                     hbt.top,
//                     hbt.right,
//                     hbt.bottom,
//                     hbt.left,
//                 }) catch {};
//
//                 writer.writeAll("  border-style: solid;\n") catch {};
//
//                 if (style.border_color) |bc| {
//                     writer.writeAll("  border-color: ") catch {};
//                     colorToCSS(bc, writer) catch {};
//                     writer.writeAll(";\n") catch {};
//                 }
//             }
//         }
//
//         // Border radius
//         if (style.border_radius) |hbr| {
//             if (hbr.top_left > 0 or
//                 hbr.top_right > 0 or
//                 hbr.bottom_right > 0 or
//                 hbr.bottom_left > 0)
//             {
//                 writer.print("  border-radius: {d}px {d}px {d}px {d}px;\n", .{
//                     hbr.top_left,
//                     hbr.top_right,
//                     hbr.bottom_right,
//                     hbr.bottom_left,
//                 }) catch {};
//             }
//         }
//
//         // Text color
//         if (style.text_color) |tc| {
//             writer.writeAll("  color: ") catch {};
//             colorToCSS(tc, writer) catch {};
//             writer.writeAll(";\n") catch {};
//         }
//
//         // Padding
//         if (style.padding) |tp| {
//             if (tp.top > 0 or
//                 tp.right > 0 or
//                 tp.bottom > 0 or
//                 tp.left > 0)
//             {
//                 writer.print("  padding: {d}px {d}px {d}px {d}px;\n", .{
//                     tp.top,
//                     tp.right,
//                     tp.bottom,
//                     tp.left,
//                 }) catch {};
//             }
//         }
//
//         if (style.margin) |m| {
//             writer.print("  margin: {d}px {d}px {d}px {d}px;\n", .{
//                 m.top,
//                 m.right,
//                 m.bottom,
//                 m.left,
//             }) catch {};
//         }
//
//         // Alignment
//         if (style.child_alignment) |ca| {
//             writer.print("  justify-content: {s};\n", .{alignmentToCSS(ca.x)}) catch {};
//             writer.print("  align-items: {s};\n", .{alignmentToCSS(ca.y)}) catch {};
//         }
//
//         if (style.child_gap > 0) {
//             writer.print("  gap: {d}px;\n", .{style.child_gap}) catch {};
//         }
//
//         // Background color
//         if (style.background) |b| {
//             writer.writeAll("  background-color: ") catch {};
//             colorToCSS(b, writer) catch {};
//             writer.writeAll(";\n") catch {};
//         }
//
//         // Shadow
//         if (style.shadow.blur > 0 or style.shadow.spread > 0 or
//             style.shadow.top > 0 or style.shadow.left > 0)
//         {
//             writer.writeAll("  box-shadow: ") catch {};
//             writer.print("{d}px {d}px {d}px {d}px ", .{
//                 style.shadow.left,
//                 style.shadow.top,
//                 style.shadow.blur,
//                 style.shadow.spread,
//             }) catch {};
//
//             colorToCSS(style.shadow.color, writer) catch {};
//             writer.writeAll(";\n") catch {};
//         }
//
//         // Text-Deco
//         if (style.text_decoration) |td| {
//             writer.writeAll("  text-decoration: ") catch {};
//             textDecoToCSS(td, writer) catch {};
//             writer.writeAll(";\n") catch {};
//         }
//
//         if (style.white_space) |ws| {
//             writer.writeAll("  white-space: ") catch {};
//             whiteSpaceToCSS(ws, writer) catch {};
//             writer.writeAll(";\n") catch {};
//         }
//         if (style.flex_wrap) |fw| {
//             writer.writeAll("  flex-wrap: ") catch {};
//             flexWrapToCSS(fw, writer) catch {};
//             writer.writeAll(";\n") catch {};
//         }
//
//         if (style.animation) |an| {
//             writer.writeAll("  animation: ") catch {};
//             animationToCSS(an, writer) catch {};
//             writer.writeAll(";\n") catch {};
//             writer.print("  animation-delay: {any}s", .{an.delay}) catch {};
//             writer.writeAll(";\n") catch {};
//         }
//
//         if (style.z_index) |zi| {
//             writer.print("  z-index: {d}", .{zi}) catch {};
//             writer.writeAll(";\n") catch {};
//         }
//
//         if (style.blur) |bl| {
//             writer.print("  backdrop-filter: blur({d}px)", .{bl}) catch {};
//             writer.writeAll(";\n") catch {};
//         }
//
//         if (style.overflow) |ovf| {
//             switch (ovf) {
//                 .scroll => writer.writeAll("  overflow: scroll;\n") catch {},
//                 .hidden => writer.writeAll("  overflow: hidden;\n") catch {},
//             }
//         }
//
//         if (style.overflow_x) |ovf| {
//             switch (ovf) {
//                 .scroll => writer.writeAll("  overflow-x: scroll;\n") catch {},
//                 .hidden => writer.writeAll("  overflow-x: hidden;\n") catch {},
//             }
//         }
//
//         if (style.overflow_y) |ovf| {
//             switch (ovf) {
//                 .scroll => writer.writeAll("  overflow-y: scroll;\n") catch {},
//                 .hidden => writer.writeAll("  overflow-y: hidden;\n") catch {},
//             }
//         }
//
//         if (style.list_style) |ls| {
//             writer.writeAll("  list-style: ") catch {};
//             listStyleToCSS(ls, writer) catch {};
//             writer.writeAll(";\n") catch {};
//         }
//
//         if (style.outline) |ol| {
//             writer.writeAll("  outline: ") catch {};
//             outlineStyleToCSS(ol, writer) catch {};
//             writer.writeAll(";\n") catch {};
//         }
//
//         writer.print("  opacity: {d};\n", .{style.opacity}) catch {};
//
//         if (style.transition) |tr| {
//             writer.writeAll("  transition: ") catch {};
//             transitionStyleToCSS(tr, writer);
//             writer.writeAll(";\n") catch {};
//         }
//
//         if (!style.show_scrollbar) {
//             writer.writeAll("  scrollbar-width: none;\n") catch {};
//             show_scrollbar = false;
//         }
//
//         // Close CSS block
//         writer.writeAll("}\n") catch {};
//
//         // Null-terminate the string
//         const len: usize = @intCast(fbs.getPos() catch 0);
//         css_buffer[len] = 0;
//         style_style = css_buffer[0..len];
//         Fabric.createClass(style_style.ptr, style_style.len);
//     }
// }

pub export fn nextMotion() bool {
    if (Fabric.motions.items.len == 0) return false;
    return true;
}

var key_frames_buffer: [4096]u8 = undefined;
var key_frame_style: []const u8 = "";
pub export fn getKeyFrames(_: *Fabric.Animation.Motion) ?[*]const u8 {
    const motion = Fabric.motions.pop() orelse return null;
    // Create a default Hover style

    // Use a fixed buffer with a fbs to build the CSS string
    var fbs = std.io.fixedBufferStream(&key_frames_buffer);
    var writer = fbs.writer();

    writer.print("@keyframes {s} ", .{motion.tag}) catch {};
    writer.writeAll("{\n") catch {};
    // FROM
    writer.writeAll("  from {\n") catch {};
    if (motion.from.type != .none) {
        writer.writeAll("    transform: ") catch {};
    }
    switch (motion.from.type) {
        .none => {},
        .scale => writer.print("scale({d});\n", .{motion.from.scale_size}) catch {},
        .scaleY => writer.print("scaleY({d});\n", .{motion.from.scale_size}) catch {},
        .scaleX => writer.print("scaleX({d});\n", .{motion.from.scale_size}) catch {},
        .translateX => writer.print("translateX({d}px);\n", .{motion.from.dist}) catch {},
        .translateY => writer.print("translateY({d}px);\n", .{motion.from.dist}) catch {},
    }
    if (motion.from.opacity) |from_op| {
        writer.print("    opacity: {d};\n", .{from_op}) catch {};
    }
    if (motion.from.height) |from_h| {
        sizingTypeToCSS("height", from_h, writer) catch {};
        writer.writeByte(';') catch {};
    }
    if (motion.from.width) |from_w| {
        sizingTypeToCSS("width", from_w, writer) catch {};
        writer.writeByte(';') catch {};
    }

    writer.writeAll("  }\n") catch {};

    // TO
    writer.writeAll("  to {\n") catch {};
    if (motion.from.type != .none) {
        writer.writeAll("    transform: ") catch {};
    }
    switch (motion.to.type) {
        .none => {},
        .scale => writer.print("scale({d});\n", .{motion.to.scale_size}) catch {},
        .scaleY => writer.print("scaleY({d});\n", .{motion.to.scale_size}) catch {},
        .scaleX => writer.print("scaleX({d});\n", .{motion.to.scale_size}) catch {},
        .translateX => writer.print("translateX({d}px);\n", .{motion.to.dist}) catch {},
        .translateY => writer.print("translateY({d}px);\n", .{motion.to.dist}) catch {},
    }
    if (motion.to.opacity) |to_op| {
        writer.print("    opacity: {d};\n", .{to_op}) catch {};
    }
    if (motion.to.height) |to_h| {
        sizingTypeToCSS("height", to_h, writer) catch {};
        writer.writeByte(';') catch {};
    }
    if (motion.to.width) |to_w| {
        sizingTypeToCSS("width", to_w, writer) catch {};
        writer.writeByte(';') catch {};
    }

    writer.writeAll("  }\n") catch {};
    writer.writeAll("  }\n") catch {};

    const len: usize = @intCast(fbs.getPos() catch 0);
    key_frames_buffer[len] = 0;
    key_frame_style = key_frames_buffer[0..len];

    // Return a pointer to the CSS string
    return key_frame_style.ptr;
}
export fn getKeyFramesLen() usize {
    return key_frame_style.len;
}

