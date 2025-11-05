const std = @import("std");
const types = @import("types.zig");
const Vapor = @import("Vapor.zig");
const UINode = @import("UITree.zig").UINode;
const LifeCycle = @import("Vapor.zig").LifeCycle;
const println = Vapor.println;
const Style = types.Style;
const InputParams = types.InputParams;
const ElementDecl = types.ElementDeclaration;
const ElementType = types.Elements.ElementType;
const Color = types.Color;
const Element = @import("Element.zig").Element;
pub const IconTokens = @import("user_config").IconTokens;
const utils = @import("utils.zig");
const hashKey = utils.hashKey;

const HeaderSize = enum(u32) {
    XXLarge = 12,
    XLarge = 8,
    Large = 4,
    Medium = 2,
    Small = 1,
};

pub inline fn Header(text: []const u8, size: HeaderSize, style: Style) void {
    var elem_decl = ElementDecl{
        .style = style,
        .state_type = .static,
        .elem_type = .Header,
        .text = text,
    };
    // const dimensions = measureText(text, &elem_decl.style);
    // // Make sure this is the right order of ops
    if (style.font_size == null) {
        switch (size) {
            .XXLarge => elem_decl.style.font_size = 12 * 12,
            .XLarge => elem_decl.style.font_size = 12 * 8,
            .Large => elem_decl.style.font_size = 12 * 4,
            .Medium => elem_decl.style.font_size = 12 * 2,
            .Small => elem_decl.style.font_size = 12 * 1,
        }
    }
    _ = LifeCycle.open(elem_decl);
    LifeCycle.configure(elem_decl);
    LifeCycle.close({});
}

pub inline fn CtxHooks(hooks: Vapor.HooksCtxFuncs, func: anytype, args: anytype, style: ?*const Style) fn (void) void {
    var elem_decl = ElementDecl{
        .elem_type = .HooksCtx,
        .state_type = .static,
        .style = style,
    };

    if (hooks == .mounted) {
        const Args = @TypeOf(args);
        const Closure = struct {
            arguments: Args,
            run_node: Vapor.Node = .{ .data = .{ .runFn = runFn, .deinitFn = deinitFn } },
            //
            fn runFn(action: *Vapor.Action) void {
                const run_node: *Vapor.Node = @fieldParentPtr("data", action);
                const closure: *@This() = @alignCast(@fieldParentPtr("run_node", run_node));
                @call(.auto, func, closure.arguments);
            }
            //
            fn deinitFn(node: *Vapor.Node) void {
                const closure: *@This() = @alignCast(@fieldParentPtr("run_node", node));
                Vapor.allocator_global.destroy(closure);
            }
        };

        const closure = Vapor.allocator_global.create(Closure) catch |err| {
            println("Error could not create closure {any}\n ", .{err});
            unreachable;
        };
        closure.* = .{
            .arguments = args,
        };

        const id = Vapor.mounted_ctx_funcs.items.len;
        elem_decl.hooks.mounted_id += id + 1;
        Vapor.mounted_ctx_funcs.append(&closure.run_node) catch |err| {
            println("Hooks Function Registry {any}\n", .{err});
        };
    }
    _ = LifeCycle.open(elem_decl);
    LifeCycle.configure(elem_decl);
    return LifeCycle.close;
}

pub inline fn Hooks(hooks: Vapor.HooksFuncs) fn (void) void {
    var elem_decl = ElementDecl{
        .state_type = .static,
        .elem_type = .Hooks,
    };

    const ui_node = LifeCycle.open(elem_decl) orelse unreachable;
    if (hooks.mounted) |f| {
        elem_decl.hooks.mounted_id = 1;
        Vapor.mounted_funcs.put(hashKey(ui_node.uuid), f) catch |err| {
            println("Mount Function Registry {any}\n", .{err});
        };
    }
    if (hooks.created) |f| {
        elem_decl.hooks.created_id += 1;
        Vapor.created_funcs.put(hashKey(ui_node.uuid), f) catch |err| {
            println("Mount Function Registry {any}\n", .{err});
        };
    }
    if (hooks.updated) |f| {
        elem_decl.hooks.updated_id += 1;
        Vapor.updated_funcs.put(hashKey(ui_node.uuid), f) catch |err| {
            println("Mount Function Registry {any}\n", .{err});
        };
    }
    if (hooks.destroy) |f| {
        elem_decl.hooks.destroy_id += 1;
        Vapor.destroy_funcs.put(hashKey(ui_node.uuid), f) catch |err| {
            println("Mount Function Registry {any}\n", .{err});
        };
    }

    LifeCycle.configure(elem_decl);
    return LifeCycle.close;
}

export fn ctxButtonCallback(id_ptr: [*:0]u8) void {
    const id = std.mem.span(id_ptr);
    defer Vapor.allocator_global.free(id);
    const node = Vapor.ctx_registry.get(hashKey(id)) orelse return;
    @call(.auto, node.data.runFn, .{&node.data});
}

export fn ctxHooksMountedCallback(id: u32) void {
    const node = Vapor.mounted_ctx_funcs.items[id - 1];
    @call(.auto, node.data.runFn, .{&node.data});
}

export fn buttonCallback(id_ptr: [*:0]u8) void {
    const id = std.mem.span(id_ptr);
    defer Vapor.allocator_global.free(id);
    Vapor.current_depth_node_id = std.mem.Allocator.dupe(Vapor.allocator_global, u8, id) catch return;
    const func = Vapor.btn_registry.get(hashKey(id)) orelse return;
    @call(.auto, func, .{});
}

export fn buttonCycleCallback(id_ptr: [*:0]u8) void {
    const id = std.mem.span(id_ptr);
    defer Vapor.allocator_global.free(id);
    Vapor.current_depth_node_id = std.mem.Allocator.dupe(Vapor.allocator_global, u8, id) catch return;
    const func = Vapor.btn_registry.get(hashKey(id)) orelse return;
    @call(.auto, func, .{});
    Vapor.cycle();
}

export fn hooksRemoveMountedKey(id_ptr: [*:0]u8) void {
    const id = std.mem.span(id_ptr);
    defer Vapor.allocator_global.free(id);
    _ = Vapor.mounted_funcs.fetchRemove(hashKey(id)) orelse return;
    // Vapor.allocator_global.free(hook.key);
}

export fn hooksMountedCallback(id_ptr: [*:0]u8) void {
    const id = std.mem.span(id_ptr);
    defer Vapor.allocator_global.free(id);
    const kv = Vapor.mounted_funcs.fetchRemove(hashKey(id)) orelse {
        println("Mounted Function {s} not found\n", .{id});
        return;
    };
    @call(.auto, kv.value, .{});
}

export fn callAllMountedCallbacks() void {
    var itr = Vapor.mounted_funcs.iterator();
    while (itr.next()) |entry| {
        const func = entry.value_ptr.*;
        @call(.auto, func, .{});
    }
}

export fn hooksCreatedCallback(id: u32) void {
    const func = Vapor.created_funcs.get(id).?;
    @call(.auto, func, .{});
}
export fn hooksUpdatedCallback(id: u32) void {
    const func = Vapor.updated_funcs.get(id).?;
    @call(.auto, func, .{});
}
export fn hooksDestroyCallback(id: u32) void {
    const func = Vapor.destroy_funcs.get(id).?;
    @call(.auto, func, .{});
}

fn callsiteId() u64 {
    const loc = @src().line;
    return loc;
}

const ButtonOptions = struct {
    on_press: ?*const fn () void = null,
    onRelease: ?*const fn () void = null,
    aria_label: ?[]const u8 = null,
};

const FlexType = enum(u8) {
    Flex = 0, // "flex"
    Center = 1,
    Stack = 2, // "inline-flex"
    Flow = 3, // "inherit"
    None = 4, // "centers the child content"
};

const TextInput = struct {
    value: []const u8,
};

pub const Input = union(enum) {
    // int: InputParamsInt,
    // float: InputParamsFloat,
    text: TextInput,
    // checkbox: InputParamsCheckBox,
    // radio: InputParamsRadio,
    // password: InputParamsPassword,
    // email: InputParamsEmail,

    pub fn onSubmit(self: *const Input, cb: anytype) void {
        switch (self.*) {
            .text => |text| {
                text.onInput = cb;
            },
        }
    }
};

pub const ChainClose = struct {
    const Self = @This();
    _elem_type: Vapor.ElementType,
    _flex_type: FlexType = .Flex,
    text: ?[]const u8 = null,
    href: ?[]const u8 = null,
    svg: []const u8 = "",
    aria_label: ?[]const u8 = null,
    style_id: ?[]const u8 = null,
    _state_type: types.StateType = .static,
    _id: ?[]const u8 = null,

    _pos: ?types.Position = null,
    _padding: ?types.Padding = null,
    _layout: ?types.Layout = null,
    _margin: ?types.Margin = null,
    _size: ?types.Size = null,
    _child_gap: ?u8 = null,
    _visual: ?types.Visual = null,
    _text_decoration: ?types.TextDecoration = null,
    _flex_wrap: ?types.FlexWrap = null,
    _interactive: ?types.Interactive = null,
    _transition: ?types.Transition = null,
    _direction: types.Direction = .row,
    _list_style: ?types.ListStyle = null,
    _input: ?Input = null,
    _ui_node: ?*UINode = null,
    _element: ?*Element = null,
    _style: ?*const Vapor.Style = null,
    _level: ?u8 = null,
    _video: ?*const types.Video = null,
    _font_family: []const u8 = "",

    pub fn Null() void {
        _ = LifeCycle.open(.{
            .elem_type = .Noop,
            .state_type = .static,
        });
        LifeCycle.configure(.{
            .elem_type = .Noop,
            .state_type = .static,
        });
        LifeCycle.close({});
    }

    pub fn Text(text: []const u8) Self {
        return Self{
            ._elem_type = .Text,
            .text = if (Vapor.isGenerated) "" else text,
        };
    }

    pub fn Code(text: []const u8) Self {
        return Self{
            ._elem_type = .Code,
            .text = if (Vapor.isGenerated) "" else text,
        };
    }

    pub fn Heading(level: u8, text: []const u8) Self {
        return Self{ ._elem_type = .Heading, .text = text, ._level = level };
    }

    pub fn Video(options: *const types.Video) Self {
        const elem_decl = ElementDecl{
            .state_type = .static,
            ._elem_type = .Video,
        };
        const ui_node = Vapor.current_ctx.open(elem_decl) catch |err| {
            println("{any}\n", .{err});
            unreachable;
        };
        return Self{
            ._elem_type = .Video,
            ._video = options,
            ._ui_node = ui_node,
        };
    }

    pub fn TextFmt(comptime fmt: []const u8, args: anytype) Self {
        const allocator = Vapor.frame_arena.getFrameAllocator();
        const text = std.fmt.allocPrint(allocator, fmt, args) catch |err| {
            Vapor.printlnColor(
                \\Error formatting text: {any}\n"
                \\FMT: {s}\n"
                \\ARGS: {any}\n"
            , .{ err, fmt, args }, .hex("#FF3029"));
            return Self{ ._elem_type = .Text, .text = "ERROR", ._state_type = .err };
        };
        Vapor.frame_arena.addBytesUsed(text.len);
        return Self{ ._elem_type = .TextFmt, .text = if (Vapor.isGenerated) "" else text };
    }

    pub fn TextArea(textfield_type: types.InputTypes) Self {
        const elem_decl = ElementDecl{
            .state_type = .static,
            ._elem_type = .TextArea,
        };
        const ui_node = Vapor.current_ctx.open(elem_decl) catch |err| {
            println("{any}\n", .{err});
            unreachable;
        };

        switch (textfield_type) {
            .string => {
                return Self{
                    ._elem_type = .TextField,
                    ._ui_node = ui_node,
                };
            },
            else => {
                unreachable;
                // @compileError("TextField only accepts []const u8 or TextInput");
            },
        }
    }

    pub fn TextField(textfield_type: types.InputTypes) Self {
        const elem_decl = ElementDecl{
            .state_type = .static,
            .elem_type = .TextField,
        };
        const ui_node = Vapor.current_ctx.open(elem_decl) catch |err| {
            println("{any}\n", .{err});
            unreachable;
        };

        switch (textfield_type) {
            .string => {
                return Self{
                    ._elem_type = .TextField,
                    ._ui_node = ui_node,
                };
            },
            else => {
                unreachable;
                // @compileError("TextField only accepts []const u8 or TextInput");
            },
        }
    }

    pub fn bind(self: *const Self, element: *Element) Self {
        var new_self: Self = self.*;
        element.element_type = self._elem_type;
        new_self._element = element;

        const ui_node = self._ui_node orelse blk: {
            const ui_node = LifeCycle.open(ElementDecl{
                .state_type = .static,
                .elem_type = self._elem_type,
            }) orelse {
                Vapor.printlnSrcErr("Node is null", .{}, @src());
                unreachable;
            };
            new_self._ui_node = ui_node;

            break :blk ui_node;
        };

        const uuid = ui_node.uuid;
        Vapor.element_registry.put(hashKey(uuid), element) catch unreachable;
        return new_self;
    }

    pub fn onFocus(self: *const Self, cb: fn (*Vapor.Event) void) Self {
        var new_self: Self = self.*;
        var element = self._element orelse {
            Vapor.printlnSrcErr("Element is null must bind() first, before setting onChange", .{}, @src());
            unreachable;
        };

        const ui_node = self._ui_node orelse blk: {
            const ui_node = LifeCycle.open(ElementDecl{
                .state_type = .static,
                ._elem_type = self._elem_type,
            }) orelse {
                Vapor.printlnSrcErr("Node is null", .{}, @src());
                unreachable;
            };
            new_self._ui_node = ui_node;

            break :blk ui_node;
        };

        const uuid = ui_node.uuid;
        var onid = hashKey(uuid);
        onid +%= hashKey(Vapor.on_change_hash);
        element.on_focus = cb;
        Vapor.events_callbacks.put(onid, cb) catch |err| {
            Vapor.println("Event Callback Error: {any}\n", .{err});
        };
        return new_self;
    }

    pub fn onBlur(self: *const Self, cb: fn (*Vapor.Event) void) Self {
        var new_self: Self = self.*;
        var element = self._element orelse {
            Vapor.printlnSrcErr("Element is null must bind() first, before setting onChange", .{}, @src());
            unreachable;
        };

        const ui_node = self._ui_node orelse blk: {
            const ui_node = LifeCycle.open(ElementDecl{
                .state_type = .static,
                ._elem_type = self._elem_type,
            }) orelse {
                Vapor.printlnSrcErr("Node is null", .{}, @src());
                unreachable;
            };
            new_self._ui_node = ui_node;

            break :blk ui_node;
        };

        const uuid = ui_node.uuid;
        var onid = hashKey(uuid);
        onid +%= hashKey(Vapor.on_blur_hash);
        element.on_blur = cb;
        Vapor.events_callbacks.put(onid, cb) catch |err| {
            Vapor.println("Event Callback Error: {any}\n", .{err});
        };
        return new_self;
    }

    pub fn onChange(self: *const Self, cb: fn (*Vapor.Event) void) Self {
        var new_self: Self = self.*;

        const ui_node = self._ui_node orelse blk: {
            const ui_node = LifeCycle.open(ElementDecl{
                .state_type = .static,
                .elem_type = self._elem_type,
            }) orelse {
                Vapor.printlnSrcErr("Node is null", .{}, @src());
                unreachable;
            };
            new_self._ui_node = ui_node;

            break :blk ui_node;
        };
        Vapor.attachEventCallback(ui_node, .input, cb) catch |err| {
            Vapor.println("ONLEAVE: Could not attach event callback {any}\n", .{err});
            unreachable;
        };
        return new_self;
    }

    /// Graphic takes a url to a svg file, during client side rendering it will be fetched and inlined
    /// Graphic(.{ .src = "https://example.com/image.svg" }).style(...);
    /// # Parameters:
    /// - `src`: []const u8,
    ///
    /// # Returns:
    /// Self: Component
    pub fn Graphic(options: struct { src: []const u8 }) Self {
        return Self{ ._elem_type = .Graphic, .href = options.src };
    }

    pub fn Icon(token: *const IconTokens) Self {
        if (Vapor.isWasi) {
            return Self{ ._elem_type = .Icon, .href = token.web orelse "" };
        } else {
            return Self{ ._elem_type = .Icon, .href = token.svg orelse "" };
        }
    }

    pub fn Image(options: struct { src: []const u8 }) Self {
        return Self{ ._elem_type = .Image, .href = options.src };
    }

    pub fn Svg(options: struct { svg: []const u8 }) Self {
        if (options.svg.len > 2048 and Vapor.build_options.enable_debug) {
            Vapor.printlnErr("Svg is too large inlining: {d}B, use Graphic;\nSVG Content:\n{s}...", .{ options.svg.len, options.svg[0..100] });
            if (!Vapor.isWasi) {
                @panic("Svg is too large, crashing!");
            } else return Self{ ._elem_type = .Svg, .svg = "" };
        }
        return Self{ ._elem_type = .Svg, .svg = if (!Vapor.isGenerated or options.svg.len < 128) options.svg else "" };
    }

    pub fn font(self: *const Self, font_size: u8, weight: ?u16, color: ?Color) Self {
        var new_self: Self = self.*;
        var visual = new_self._visual orelse types.Visual{};
        visual.font_size = font_size;
        visual.font_weight = weight;
        visual.text_color = color;
        new_self._visual = visual;
        return new_self;
    }

    pub fn fontFamily(self: *const Self, font_family: []const u8) Self {
        var new_self: Self = self.*;
        new_self._font_family = font_family;
        return new_self;
    }

    pub fn pos(self: *const Self, position: types.Position) Self {
        var new_self: Self = self.*;
        var new_position = new_self._pos orelse types.Position{};
        new_position.top = position.top;
        new_position.right = position.right;
        new_position.bottom = position.bottom;
        new_position.left = position.left;
        new_position.type = position.type;
        new_self._pos = new_position;
        return new_self;
    }

    pub fn zIndex(self: *const Self, z_index: ?i16) Self {
        var new_self: Self = self.*;
        var position = new_self._pos orelse types.Position{};
        position.z_index = z_index;
        new_self._pos = position;
        return new_self;
    }

    pub fn blur(self: *const Self, value: ?u8) Self {
        var new_self: Self = self.*;
        var visual = new_self._visual orelse types.Visual{};
        visual.blur = value;
        new_self._visual = visual;
        return new_self;
    }

    pub fn layout(self: *const Self, value: types.Layout) Self {
        var new_self: Self = self.*;
        new_self._layout = value;
        return new_self;
    }

    pub fn background(self: *const Self, value: types.Background) Self {
        var new_self: Self = self.*;
        var visual = new_self._visual orelse types.Visual{};
        visual.background = value;
        new_self._visual = visual;
        return new_self;
    }

    pub fn textDecoration(self: *const Self, value: types.TextDecoration) Self {
        var new_self: Self = self.*;
        var visual = new_self._visual orelse types.Visual{};
        visual.text_decoration = value;
        new_self._visual = visual;
        return new_self;
    }

    pub fn hoverScale(self: *const Self) Self {
        var new_self: Self = self.*;
        new_self._interactive = .hover_scale();
        return new_self;
    }

    pub fn hoverText(self: *const Self, color: Color) Self {
        var new_self: Self = self.*;
        new_self._interactive = .hover_text(color);
        return new_self;
    }

    pub fn childGap(self: *const Self, value: u8) Self {
        var new_self: Self = self.*;
        new_self._child_gap = value;
        return new_self;
    }

    pub fn spacing(self: *const Self, value: u8) Self {
        var new_self: Self = self.*;
        new_self._child_gap = value;
        return new_self;
    }

    pub fn padding(self: *const Self, value: types.Padding) Self {
        var new_self: Self = self.*;
        new_self._padding = value;
        return new_self;
    }

    pub fn cursor(self: *const Self, value: types.Cursor) Self {
        var new_self: Self = self.*;
        var visual = new_self._visual orelse types.Visual{};
        visual.cursor = value;
        new_self._visual = visual;
        return new_self;
    }

    pub fn margin(self: *const Self, value: types.Margin) Self {
        var new_self: Self = self.*;
        new_self._margin = value;
        return new_self;
    }

    pub fn size(self: *const Self, dim: types.Size) Self {
        var new_self: Self = self.*;
        new_self._size = dim;
        return new_self;
    }

    pub fn width(self: *const Self, length: types.Sizing) Self {
        var new_self: Self = self.*;
        if (new_self._size == null) {
            new_self._size = .{ .width = length };
        } else {
            new_self._size.?.width = length;
        }
        return new_self;
    }

    pub fn height(self: *const Self, length: types.Sizing) Self {
        var new_self: Self = self.*;
        if (new_self._size == null) {
            new_self._size = .{ .height = length };
        } else {
            new_self._size.?.height = length;
        }
        return new_self;
    }

    pub fn border(self: *const Self, value: types.BorderGrouped) Self {
        var new_self: Self = self.*;
        var visual = new_self._visual orelse types.Visual{};
        visual.border = value;
        new_self._visual = visual;
        return new_self;
    }

    pub fn radius(self: *const Self, value: types.BorderRadius) Self {
        var new_self: Self = self.*;
        var visual = new_self._visual orelse types.Visual{};
        visual.border_radius = value;
        new_self._visual = visual;
        return new_self;
    }

    pub fn duration(self: *const Self, value: u32) Self {
        var new_self: Self = self.*;
        new_self._transition = .{ .duration = value };
        return new_self;
    }

    pub fn direction(self: *const Self, value: types.Direction) Self {
        var new_self: Self = self.*;
        new_self._direction = value;
        return new_self;
    }

    pub fn listStyle(self: *const Self, value: types.ListStyle) Self {
        var new_self: Self = self.*;
        new_self._list_style = value;
        return new_self;
    }

    pub fn close(self: *const Self) void {
        var mutable_style = Style{};
        if (self._style) |style_ptr| {
            mutable_style = style_ptr.*;
        }

        if (mutable_style.position == null) mutable_style.position = self._pos;
        if (mutable_style.visual == null) mutable_style.visual = self._visual;
        if (mutable_style.interactive == null) mutable_style.interactive = self._interactive;
        if (mutable_style.child_gap == null) mutable_style.child_gap = self._child_gap;
        if (mutable_style.padding == null) mutable_style.padding = self._padding;
        if (mutable_style.layout == null) mutable_style.layout = self._layout;
        if (mutable_style.margin == null) mutable_style.margin = self._margin;
        if (mutable_style.size == null) mutable_style.size = self._size;
        if (mutable_style.transition == null) mutable_style.transition = self._transition;
        mutable_style.direction = self._direction;
        if (mutable_style.list_style == null) mutable_style.list_style = self._list_style;
        if (mutable_style.font_family == null) mutable_style.font_family = self._font_family;

        if (self._id) |_id| {
            mutable_style.id = _id;
        }

        const elem_decl = Vapor.ElementDecl{
            .elem_type = self._elem_type,
            .state_type = self._state_type,
            .text = self.text,
            .style = &mutable_style,
            .href = self.href,
            .svg = self.svg,
            .aria_label = self.aria_label,
            .level = self._level,
            .video = self._video,
        };

        if (self._ui_node == null) {
            _ = Vapor.LifeCycle.open(elem_decl) orelse unreachable;
        }

        Vapor.LifeCycle.configure(elem_decl);
        return Vapor.LifeCycle.close({});
    }

    pub fn id(self: *const Self, element_id: []const u8) Self {
        var new_self: Self = self.*;
        new_self._id = element_id;
        return new_self;
    }

    pub fn baseStyle(self: *const Self, style_ptr: *const Vapor.Style) Self {
        var new_self: Self = self.*;
        new_self._style = style_ptr;
        return new_self;
    }

    pub fn style(self: *const Self, style_ptr: *const Vapor.Style) void {
        var elem_decl = Vapor.ElementDecl{
            .elem_type = self._elem_type,
            .state_type = self._state_type,
            .text = self.text,
            .style = style_ptr,
            .href = self.href,
            .svg = self.svg,
            .aria_label = self.aria_label,
            .level = self._level,
        };

        if (self._id) |_id| {
            var mutable_style = style_ptr.*;
            mutable_style.id = _id;
            elem_decl.style = &mutable_style;
        }

        if (self._ui_node == null) {
            _ = Vapor.LifeCycle.open(elem_decl) orelse unreachable;
        }
        Vapor.LifeCycle.configure(elem_decl);
        return Vapor.LifeCycle.close({});
    }

    pub fn plain(self: *const Self) void {
        const elem_decl = Vapor.ElementDecl{
            .state_type = self._state_type,
            .elem_type = self._elem_type,
            .text = self.text,
            .href = self.href,
            .svg = self.svg,
            .aria_label = self.aria_label,
            .level = self._level,
        };
        if (self._ui_node == null) {
            _ = Vapor.LifeCycle.open(elem_decl);
        }
        Vapor.LifeCycle.configure(elem_decl);
        Vapor.LifeCycle.close({});
    }
};

const Position = enum {
    top,
    bottom,
    left,
    right,
};

const Layout = enum {
    center,
    start,
    end,
};

const Tooltip = struct {
    text: []const u8,
    position: Position,
    layout: Layout,
    color: ?Vapor.Types.Color = null,
    background: ?Vapor.Types.Background = null,
    border: ?Vapor.Types.BorderGrouped = null,
    delay: u32 = 300,
};

pub const Chain = struct {
    const Self = @This();
    _elem_type: Vapor.ElementType,
    _flex_type: FlexType = .Flex,
    _text: ?[]const u8 = null,
    _href: ?[]const u8 = null,
    _svg: []const u8 = "",
    _aria_label: ?[]const u8 = null,
    _options: ?ButtonOptions = null,
    _ui_node: ?*UINode = null,
    _id: ?[]const u8 = null,
    _style: ?*const Vapor.Style = null,
    _element: ?*Element = null,

    _animation_enter: ?*const Vapor.Animation = null,
    _animation_exit: ?*const Vapor.Animation = null,

    // Style props
    _pos: ?types.Position = null,
    _padding: ?types.Padding = null,
    _layout: ?types.Layout = null,
    _margin: ?types.Margin = null,
    _size: ?types.Size = null,
    _child_gap: ?u8 = null,
    _visual: ?types.Visual = null,
    _text_decoration: ?types.TextDecoration = null,
    _flex_wrap: ?types.FlexWrap = null,
    _interactive: ?types.Interactive = null,
    _transition: ?types.Transition = null,
    _direction: types.Direction = .row,
    _list_style: ?types.ListStyle = null,

    // _tooltip: ?types.Tooltip = null,

    pub fn TextArea(text: []const u8) Self {
        return Self{ ._elem_type = .TextArea, ._text = text };
    }

    pub fn Label(text: []const u8, tag: []const u8) Self {
        return Self{ .elem_type = .Text, .text = text, .href = tag };
    }

    pub fn Button(options: ButtonOptions) Self {
        return Self{ ._elem_type = .Button, ._aria_label = options.aria_label, ._options = options };
    }

    pub fn Hooks(_: Vapor.HooksFuncs) Self {
        // const elem_decl = ElementDecl{
        //     .state_type = .static,
        //     .elem_type = .Hooks,
        // };

        // const ui_node = Vapor.LifeCycle.open(elem_decl) orelse {
        //     println("Hooks: {any}\n", .{error.CouldNotAllocate});
        //     unreachable;
        // };
        // if (hooks.mounted) |f| {
        //     elem_decl.hooks.mounted_id = 1;
        //     Vapor.print("Mounted Funcs {s}\n", .{ui_node.uuid});
        //     Vapor.mounted_funcs.put(hashKey(ui_node.uuid), f) catch |err| {
        //         println("Mount Function Registry {any}\n", .{err});
        //     };
        // }
        // if (hooks.created) |f| {
        //     elem_decl.hooks.created_id += 1;
        //     Vapor.created_funcs.put(hashKey(ui_node.uuid), f) catch |err| {
        //         println("Mount Function Registry {any}\n", .{err});
        //     };
        // }
        // if (hooks.updated) |f| {
        //     elem_decl.hooks.updated_id += 1;
        //     Vapor.updated_funcs.put(hashKey(ui_node.uuid), f) catch |err| {
        //         println("Mount Function Registry {any}\n", .{err});
        //     };
        // }
        // if (hooks.destroy) |f| {
        //     elem_decl.hooks.destroy_id += 1;
        //     Vapor.destroy_funcs.put(hashKey(ui_node.uuid), f) catch |err| {
        //         println("Mount Function Registry {any}\n", .{err});
        //     };
        // }
        return Self{ ._elem_type = .Hooks };
    }

    pub fn CtxButton(func: anytype, args: anytype) Self {
        const elem_decl = ElementDecl{
            .state_type = .static,
            .elem_type = .CtxButton,
        };

        const ui_node = Vapor.current_ctx.open(elem_decl) catch |err| {
            println("{any}\n", .{err});
            unreachable;
        };
        const Args = @TypeOf(args);
        const Closure = struct {
            arguments: Args,
            run_node: Vapor.Node = .{ .data = .{ .runFn = runFn, .deinitFn = deinitFn } },
            fn runFn(action: *Vapor.Action) void {
                const run_node: *Vapor.Node = @fieldParentPtr("data", action);
                const closure: *@This() = @alignCast(@fieldParentPtr("run_node", run_node));
                @call(.auto, func, closure.arguments);
            }
            fn deinitFn(node: *Vapor.Node) void {
                const closure: *@This() = @alignCast(@fieldParentPtr("run_node", node));
                Vapor.allocator_global.destroy(closure);
            }
        };

        const closure = Vapor.allocator_global.create(Closure) catch |err| {
            println("Error could not create closure {any}\n ", .{err});
            unreachable;
        };
        closure.* = .{
            .arguments = args,
        };

        Vapor.ctx_registry.put(hashKey(ui_node.uuid), &closure.run_node) catch |err| {
            println("Button Function Registry {any}\n", .{err});
            unreachable;
        };

        return Self{ ._elem_type = .CtxButton, ._ui_node = ui_node };
    }

    pub fn ButtonCycle(options: ButtonOptions) Self {
        return Self{ ._elem_type = .ButtonCycle, ._aria_label = options.aria_label, ._options = options };
    }

    pub const Box = Self{ ._elem_type = .FlexBox };
    pub const Section = Self{ ._elem_type = .Intersection };
    pub const Center = Self{ ._elem_type = .FlexBox, ._flex_type = .Center };
    pub const Stack = Self{ ._elem_type = .FlexBox, ._flex_type = .Stack };
    pub const List = Self{ ._elem_type = .List };
    pub const ListItem = Self{ ._elem_type = .ListItem };
    pub fn Link(options: struct { url: []const u8, aria_label: ?[]const u8 }) Self {
        const elem_decl = ElementDecl{
            .state_type = .static,
            .elem_type = .Link,
            .href = options.url,
            .aria_label = options.aria_label,
        };
        const ui_node = LifeCycle.open(elem_decl) orelse {
            Vapor.printlnSrcErr("Could not add component Link to lifecycle {any}\n", .{error.CouldNotAllocate}, @src());
            unreachable;
        };

        return Self{
            ._ui_node = ui_node,
            ._elem_type = .Link,
            ._aria_label = options.aria_label,
            ._href = options.url,
        };
    }

    pub fn onHover(self: *const Self, cb: fn (*Vapor.Event) void) Self {
        var new_self: Self = self.*;

        const ui_node = self._ui_node orelse blk: {
            const ui_node = LifeCycle.open(ElementDecl{
                .state_type = .static,
                .elem_type = self._elem_type,
            }) orelse {
                Vapor.printlnSrcErr("Node is null", .{}, @src());
                unreachable;
            };
            new_self._ui_node = ui_node;

            break :blk ui_node;
        };

        Vapor.attachEventCallback(ui_node, .mouseleave, cb) catch |err| {
            Vapor.println("ONLEAVE: Could not attach event callback {any}\n", .{err});
            unreachable;
        };

        return new_self;
    }

    pub fn onLeave(self: *const Self, cb: fn (*Vapor.Event) void) Self {
        var new_self: Self = self.*;

        const ui_node = self._ui_node orelse blk: {
            const ui_node = LifeCycle.open(ElementDecl{
                .state_type = .static,
                .elem_type = self._elem_type,
            }) orelse {
                Vapor.printlnSrcErr("Node is null", .{}, @src());
                unreachable;
            };
            new_self._ui_node = ui_node;

            break :blk ui_node;
        };
        Vapor.attachEventCallback(ui_node, .mouseleave, cb) catch |err| {
            Vapor.println("ONLEAVE: Could not attach event callback {any}\n", .{err});
            unreachable;
        };

        return new_self;
    }

    pub fn onHoverCtx(self: *const Self, cb: anytype, args: anytype) Self {
        var new_self: Self = self.*;

        const ui_node = self._ui_node orelse blk: {
            const ui_node = LifeCycle.open(ElementDecl{
                .state_type = .static,
                .elem_type = self._elem_type,
            }) orelse {
                Vapor.printlnSrcErr("Node is null", .{}, @src());
                unreachable;
            };
            new_self._ui_node = ui_node;

            break :blk ui_node;
        };

        Vapor.attachEventCtxCallback(ui_node, .mouseenter, cb, args) catch |err| {
            Vapor.println("ONLEAVE: Could not attach event callback {any}\n", .{err});
            unreachable;
        };

        return new_self;
    }

    pub fn RedirectLink(options: struct { url: []const u8, aria_label: ?[]const u8 }) Self {
        return Self{
            ._elem_type = .RedirectLink,
            ._href = options.url,
            // ._href = if (Vapor.isGenerated) "" else options.url,
            ._aria_label = options.aria_label,
        };
    }

    pub fn Image(options: struct { src: []const u8 }) Self {
        return Self{ ._elem_type = .Image, ._href = options.src };
    }

    pub fn id(self: *const Self, element_id: []const u8) Self {
        var new_self: Self = self.*;
        new_self._id = element_id;
        return new_self;
    }

    pub fn bind(self: *const Self, element: *Element) Self {
        var new_self: Self = self.*;
        element.element_type = self._elem_type;
        new_self._element = element;

        const ui_node = self._ui_node orelse blk: {
            const ui_node = LifeCycle.open(ElementDecl{
                .state_type = .static,
                .elem_type = self._elem_type,
            }) orelse {
                Vapor.printlnSrcErr("Node is null", .{}, @src());
                unreachable;
            };
            new_self._ui_node = ui_node;

            break :blk ui_node;
        };

        element._node_ptr = ui_node orelse {
            Vapor.printlnSrcErr("Node is null", .{}, @src());
            unreachable;
        };
        const uuid = element._get_id() orelse {
            Vapor.printlnSrcErr("Id is null", .{}, @src());
            unreachable;
        };
        Vapor.element_registry.put(hashKey(uuid), element) catch unreachable;
        return new_self;
    }

    pub fn animationEnter(self: *const Self, animation_ptr: *const Vapor.Animation) Self {
        var new_self: Self = self.*;
        new_self._animation_enter = animation_ptr;
        return new_self;
    }

    pub fn animationExit(self: *const Self, animation_ptr: *const Vapor.Animation) Self {
        var new_self: Self = self.*;
        new_self._animation_exit = animation_ptr;
        return new_self;
    }

    pub fn tooltip(self: *const Self, tool_tip: *const Tooltip) Self {
        var new_self: Self = self.*;
        var tooltip_style: Vapor.Style = .{
            .layout = .center,
            .position = .{ .type = .absolute },
            .padding = .tblr(4, 4, 8, 8),
            .visual = .{
                .opacity = 0,
                .font_size = 14,
                .background = tool_tip.background,
                .text_color = tool_tip.color,
                .border = tool_tip.border,
            },
            .transition = .{ .duration = tool_tip.delay, .properties = &.{.opacity} },
            .white_space = .nowrap,
        };

        switch (tool_tip.position) {
            .top => {
                tooltip_style.position.?.bottom = .percent(100);
                tooltip_style.margin = .b(8);
                switch (tool_tip.layout) {
                    .center => {
                        tooltip_style.position.?.left = .percent(50);
                        tooltip_style.visual.?.transform = .left_percent(-50); // Centers the tooltip horizontally
                    },
                    .start => {},
                    .end => {},
                }
            },
            .bottom => {
                tooltip_style.position.?.top = .percent(125);
            },
            .left => {
                tooltip_style.position.?.right = .percent(100);
                tooltip_style.margin = .r(8);
                switch (tool_tip.layout) {
                    .center => {
                        tooltip_style.position.?.top = .percent(50);
                        tooltip_style.visual.?.transform = .top_percent(-50); // Centers the tooltip horizontally
                    },
                    .start => {},
                    .end => {},
                }
            },
            .right => {
                tooltip_style.position.?.left = .percent(100);
                tooltip_style.margin = .l(8);
                switch (tool_tip.layout) {
                    .center => {
                        tooltip_style.position.?.top = .percent(50);
                        tooltip_style.visual.?.transform = .top_percent(-50); // Centers the tooltip horizontally
                    },
                    .start => {},
                    .end => {},
                }
            },
        }

        new_self._tooltip = types.Tooltip{
            .text = tool_tip.text,
            .style = tooltip_style,
        };
        return new_self;
    }

    pub fn baseStyle(self: *const Self, style_ptr: *const Vapor.Style) Self {
        var new_self: Self = self.*;
        new_self._style = style_ptr;
        return new_self;
    }

    /// This function takes a const pointer to a Style Struct, and returns the body function callback
    /// This function is static, so any styles added via chaining methods will not be applied
    /// Use baseStyle to keep all chained additions
    pub fn style(self: *const Self, style_ptr: *const Vapor.Style) *const fn (void) void {
        var elem_decl = Vapor.ElementDecl{
            .state_type = .static,
            .elem_type = self._elem_type,
            .text = self._text,
            .style = style_ptr,
            .href = self._href,
            .svg = self._svg,
            .aria_label = self._aria_label,
            .animation_enter = self._animation_enter,
            .animation_exit = self._animation_exit,
        };

        // if (self._tooltip) |_tooltip| {
        //     elem_decl.tooltip = &_tooltip;
        // }

        if (self._flex_type == .Center) {
            // Create a mutable copy of the style struct
            var mutable_style = style_ptr.*;

            // Now you can safely modify the local, mutable copy
            mutable_style.layout = .center;
            elem_decl.style = &mutable_style;
        } else if (self._flex_type == .Stack) {
            var mutable_style = style_ptr.*;
            mutable_style.direction = .column;
            elem_decl.style = &mutable_style;
        }

        if (self._id) |_id| {
            var mutable_style = style_ptr.*;
            mutable_style.id = _id;
            elem_decl.style = &mutable_style;
        }

        if (self._ui_node == null) {
            const ui_node = Vapor.LifeCycle.open(elem_decl) orelse unreachable;
            if (self._elem_type == .Button or self._elem_type == .ButtonCycle) {
                if (self._options.?.on_press) |on_press| {
                    Vapor.btn_registry.put(hashKey(ui_node.uuid), on_press) catch |err| {
                        println("Button Function Registry {any}\n", .{err});
                    };
                }
            }
        } else if (self._elem_type == .CtxButton) {
            const ui_node = self._ui_node orelse unreachable;
            if (style_ptr.id) |element_id| {
                const kv = Vapor.ctx_registry.fetchRemove(hashKey(ui_node.uuid)) orelse unreachable;
                Vapor.ctx_registry.put(hashKey(element_id), kv.value) catch |err| {
                    println("Button Function Registry {any}\n", .{err});
                    unreachable;
                };
            }
        }

        Vapor.LifeCycle.configure(elem_decl);
        return Vapor.LifeCycle.close;
    }

    pub fn font(self: *const Self, font_size: u8, weight: ?u16, color: ?Color) Self {
        var new_self: Self = self.*;
        var visual = new_self._visual orelse types.Visual{};
        visual.font_size = font_size;
        visual.font_weight = weight;
        visual.text_color = color;
        new_self._visual = visual;
        return new_self;
    }

    pub fn pos(self: *const Self, position: types.Position) Self {
        var new_self: Self = self.*;
        var new_position = new_self._pos orelse types.Position{};
        new_position.top = position.top;
        new_position.right = position.right;
        new_position.bottom = position.bottom;
        new_position.left = position.left;
        new_position.type = position.type;
        new_self._pos = new_position;
        return new_self;
    }

    pub fn zIndex(self: *const Self, z_index: ?i16) Self {
        var new_self: Self = self.*;
        var position = new_self._pos orelse types.Position{};
        position.z_index = z_index;
        new_self._pos = position;
        return new_self;
    }

    pub fn blur(self: *const Self, value: ?u8) Self {
        var new_self: Self = self.*;
        var visual = new_self._visual orelse types.Visual{};
        visual.blur = value;
        new_self._visual = visual;
        return new_self;
    }

    pub fn layout(self: *const Self, value: types.Layout) Self {
        var new_self: Self = self.*;
        new_self._layout = value;
        return new_self;
    }

    pub fn background(self: *const Self, value: types.Background) Self {
        var new_self: Self = self.*;
        var visual = new_self._visual orelse types.Visual{};
        visual.background = value;
        new_self._visual = visual;
        return new_self;
    }

    pub fn wrap(self: *const Self, value: types.FlexWrap) Self {
        var new_self: Self = self.*;
        new_self._flex_wrap = value;
        return new_self;
    }

    pub fn textDecoration(self: *const Self, value: types.TextDecoration) Self {
        var new_self: Self = self.*;
        var visual = new_self._visual orelse types.Visual{};
        visual.text_decoration = value;
        new_self._visual = visual;
        return new_self;
    }

    pub fn hoverScale(self: *const Self) Self {
        var new_self: Self = self.*;
        new_self._interactive = .hover_scale();
        return new_self;
    }

    pub fn hoverText(self: *const Self, color: Color) Self {
        var new_self: Self = self.*;
        new_self._interactive = .hover_text(color);
        return new_self;
    }

    pub fn childGap(self: *const Self, value: u8) Self {
        var new_self: Self = self.*;
        new_self._child_gap = value;
        return new_self;
    }

    pub fn spacing(self: *const Self, value: u8) Self {
        var new_self: Self = self.*;
        new_self._child_gap = value;
        return new_self;
    }

    pub fn padding(self: *const Self, value: types.Padding) Self {
        var new_self: Self = self.*;
        new_self._padding = value;
        return new_self;
    }

    pub fn cursor(self: *const Self, value: types.Cursor) Self {
        var new_self: Self = self.*;
        var visual = new_self._visual orelse types.Visual{};
        visual.cursor = value;
        new_self._visual = visual;
        return new_self;
    }

    pub fn margin(self: *const Self, value: types.Margin) Self {
        var new_self: Self = self.*;
        new_self._margin = value;
        return new_self;
    }

    pub fn size(self: *const Self, dim: types.Size) Self {
        var new_self: Self = self.*;
        new_self._size = dim;
        return new_self;
    }

    pub fn width(self: *const Self, length: types.Sizing) Self {
        var new_self: Self = self.*;
        if (new_self._size == null) {
            new_self._size = .{ .width = length };
        } else {
            new_self._size.?.width = length;
        }
        return new_self;
    }

    pub fn height(self: *const Self, length: types.Sizing) Self {
        var new_self: Self = self.*;
        if (new_self._size == null) {
            new_self._size = .{ .height = length };
        } else {
            new_self._size.?.height = length;
        }
        return new_self;
    }

    pub fn border(self: *const Self, value: types.BorderGrouped) Self {
        var new_self: Self = self.*;
        var visual = new_self._visual orelse types.Visual{};
        visual.border = value;
        new_self._visual = visual;
        return new_self;
    }

    pub fn radius(self: *const Self, value: types.BorderRadius) Self {
        var new_self: Self = self.*;
        var visual = new_self._visual orelse types.Visual{};
        visual.border_radius = value;
        new_self._visual = visual;
        return new_self;
    }

    pub fn duration(self: *const Self, value: u32) Self {
        var new_self: Self = self.*;
        new_self._transition = .{ .duration = value };
        return new_self;
    }

    pub fn direction(self: *const Self, value: types.Direction) Self {
        var new_self: Self = self.*;
        new_self._direction = value;
        return new_self;
    }

    pub fn listStyle(self: *const Self, value: types.ListStyle) Self {
        var new_self: Self = self.*;
        new_self._list_style = value;
        return new_self;
    }

    pub fn body(self: *const Self) *const fn (void) void {
        var mutable_style = Style{};
        if (self._style) |style_ptr| {
            mutable_style = style_ptr.*;
        }
        if (mutable_style.position == null) mutable_style.position = self._pos;
        if (mutable_style.visual == null) mutable_style.visual = self._visual;
        if (mutable_style.interactive == null) mutable_style.interactive = self._interactive;
        if (mutable_style.child_gap == null) mutable_style.child_gap = self._child_gap;
        if (mutable_style.padding == null) mutable_style.padding = self._padding;
        if (mutable_style.layout == null) mutable_style.layout = self._layout;
        if (mutable_style.margin == null) mutable_style.margin = self._margin;
        if (mutable_style.size == null) mutable_style.size = self._size;
        if (mutable_style.transition == null) mutable_style.transition = self._transition;
        if (mutable_style.flex_wrap == null) mutable_style.flex_wrap = self._flex_wrap;
        mutable_style.direction = self._direction;
        if (mutable_style.list_style == null) mutable_style.list_style = self._list_style;

        // if (self._tooltip) |_tooltip| {
        //     elem_decl.tooltip = &_tooltip;
        // }

        if (self._flex_type == .Center) {
            mutable_style.layout = .center;
        } else if (self._flex_type == .Stack) {
            mutable_style.direction = .column;
        }

        if (self._id) |_id| {
            mutable_style.id = _id;
        }

        const elem_decl = Vapor.ElementDecl{
            .state_type = .static,
            .elem_type = self._elem_type,
            .text = self._text,
            .style = &mutable_style,
            .href = self._href,
            .svg = self._svg,
            .aria_label = self._aria_label,
            .animation_enter = self._animation_enter,
            .animation_exit = self._animation_exit,
        };

        if (self._ui_node == null) {
            const ui_node = Vapor.LifeCycle.open(elem_decl) orelse unreachable;
            if (self._elem_type == .Button or self._elem_type == .ButtonCycle) {
                if (self._options.?.on_press) |on_press| {
                    Vapor.btn_registry.put(hashKey(ui_node.uuid), on_press) catch |err| {
                        println("Button Function Registry {any}\n", .{err});
                    };
                }
            }
        } else if (self._elem_type == .CtxButton) {
            const ui_node = self._ui_node orelse unreachable;
            if (elem_decl.style.?.style_id) |element_id| {
                const kv = Vapor.ctx_registry.fetchRemove(hashKey(ui_node.uuid)) orelse unreachable;
                Vapor.ctx_registry.put(hashKey(element_id), kv.value) catch |err| {
                    println("Button Function Registry {any}\n", .{err});
                    unreachable;
                };
            }
        }

        Vapor.LifeCycle.configure(elem_decl);
        return Vapor.LifeCycle.close;
    }

    pub fn plain(self: *const Self) void {
        const elem_decl = Vapor.ElementDecl{
            .state_type = .static,
            .elem_type = self._elem_type,
            .text = self._text,
        };
        _ = Vapor.LifeCycle.open(elem_decl);
        Vapor.LifeCycle.configure(elem_decl);
        Vapor.LifeCycle.close({});
    }
};
