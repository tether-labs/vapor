const std = @import("std");
const types = @import("types.zig");
const Fabric = @import("Fabric.zig");
const UINode = @import("UITree.zig").UINode;
const LifeCycle = @import("Fabric.zig").LifeCycle;
const println = Fabric.println;
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

pub inline fn CtxHooks(hooks: Fabric.HooksCtxFuncs, func: anytype, args: anytype, style: ?*const Style) fn (void) void {
    var elem_decl = ElementDecl{
        .elem_type = .HooksCtx,
        .state_type = .static,
        .style = style,
    };

    if (hooks == .mounted) {
        const Args = @TypeOf(args);
        const Closure = struct {
            arguments: Args,
            run_node: Fabric.Node = .{ .data = .{ .runFn = runFn, .deinitFn = deinitFn } },
            //
            fn runFn(action: *Fabric.Action) void {
                const run_node: *Fabric.Node = @fieldParentPtr("data", action);
                const closure: *@This() = @alignCast(@fieldParentPtr("run_node", run_node));
                @call(.auto, func, closure.arguments);
            }
            //
            fn deinitFn(node: *Fabric.Node) void {
                const closure: *@This() = @alignCast(@fieldParentPtr("run_node", node));
                Fabric.allocator_global.destroy(closure);
            }
        };

        const closure = Fabric.allocator_global.create(Closure) catch |err| {
            println("Error could not create closure {any}\n ", .{err});
            unreachable;
        };
        closure.* = .{
            .arguments = args,
        };

        const id = Fabric.mounted_ctx_funcs.items.len;
        elem_decl.hooks.mounted_id += id + 1;
        Fabric.mounted_ctx_funcs.append(&closure.run_node) catch |err| {
            println("Hooks Function Registry {any}\n", .{err});
        };
    }
    _ = LifeCycle.open(elem_decl);
    LifeCycle.configure(elem_decl);
    return LifeCycle.close;
}

const HooksOptions = struct {
    hooks: Fabric.HooksFuncs,
    style: ?*const Style = null,
};

pub inline fn Hooks(options: HooksOptions) fn (void) void {
    var elem_decl = ElementDecl{
        .state_type = .static,
        .style = options.style,
        .elem_type = .Hooks,
    };

    const hooks = options.hooks;
    const ui_node = LifeCycle.open(elem_decl) orelse unreachable;
    if (hooks.mounted) |f| {
        elem_decl.hooks.mounted_id = 1;
        const uuid_alloc = Fabric.allocator_global.alloc(u8, ui_node.uuid.len) catch |err| {
            println("Allocator ran out of space {any}\n", .{err});
            unreachable;
        };
        @memcpy(uuid_alloc, ui_node.uuid);
        Fabric.mounted_funcs.put(uuid_alloc, f) catch |err| {
            println("Mount Function Registry {any}\n", .{err});
        };
    }
    if (hooks.created) |f| {
        const id = Fabric.created_funcs.count();
        elem_decl.hooks.created_id += id + 1;
        Fabric.created_funcs.put(elem_decl.hooks.created_id, f) catch |err| {
            println("Mount Function Registry {any}\n", .{err});
        };
    }
    if (hooks.updated) |f| {
        const id = Fabric.updated_funcs.count();
        elem_decl.hooks.updated_id += id + 1;
        Fabric.updated_funcs.put(elem_decl.hooks.updated_id, f) catch |err| {
            println("Mount Function Registry {any}\n", .{err});
        };
    }
    if (hooks.destroy) |f| {
        const id = Fabric.destroy_funcs.count();
        elem_decl.hooks.destroy_id += id + 1;
        Fabric.destroy_funcs.put(elem_decl.hooks.destroy_id, f) catch |err| {
            println("Mount Function Registry {any}\n", .{err});
        };
    }

    LifeCycle.configure(elem_decl);
    return LifeCycle.close;
}

export fn ctxButtonCallback(id_ptr: [*:0]u8) void {
    const id = std.mem.span(id_ptr);
    defer Fabric.allocator_global.free(id);
    const node = Fabric.ctx_registry.get(hashKey(id)) orelse return;
    @call(.auto, node.data.runFn, .{&node.data});
}

export fn ctxHooksMountedCallback(id: u32) void {
    const node = Fabric.mounted_ctx_funcs.items[id - 1];
    @call(.auto, node.data.runFn, .{&node.data});
}

export fn buttonCallback(id_ptr: [*:0]u8) void {
    const id = std.mem.span(id_ptr);
    defer Fabric.allocator_global.free(id);
    Fabric.current_depth_node_id = std.mem.Allocator.dupe(Fabric.allocator_global, u8, id) catch return;
    const func = Fabric.btn_registry.get(hashKey(id)) orelse return;
    @call(.auto, func, .{});
}

export fn buttonCycleCallback(id_ptr: [*:0]u8) void {
    const id = std.mem.span(id_ptr);
    defer Fabric.allocator_global.free(id);
    Fabric.current_depth_node_id = std.mem.Allocator.dupe(Fabric.allocator_global, u8, id) catch return;
    const func = Fabric.btn_registry.get(hashKey(id)) orelse return;
    @call(.auto, func, .{});
    Fabric.cycle();
}

export fn hooksRemoveMountedKey(id_ptr: [*:0]u8) void {
    const id = std.mem.span(id_ptr);
    defer Fabric.allocator_global.free(id);
    _ = Fabric.mounted_funcs.fetchRemove(hashKey(id)) orelse return;
    // Fabric.allocator_global.free(hook.key);
}

export fn hooksMountedCallback(id_ptr: [*:0]u8) void {
    const id = std.mem.span(id_ptr);
    defer Fabric.allocator_global.free(id);
    const func = Fabric.mounted_funcs.get(hashKey(id)) orelse {
        println("Mounted Function {s} not found\n", .{id});
        return;
    };
    @call(.auto, func, .{});
}
export fn hooksCreatedCallback(id: u32) void {
    const func = Fabric.created_funcs.get(id).?;
    @call(.auto, func, .{});
}
export fn hooksUpdatedCallback(id: u32) void {
    const func = Fabric.updated_funcs.get(id).?;
    @call(.auto, func, .{});
}
export fn hooksDestroyCallback(id: u32) void {
    const func = Fabric.destroy_funcs.get(id).?;
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

pub const ChainClose = struct {
    const Self = @This();
    elem_type: Fabric.ElementType,
    _flex_type: FlexType = .Flex,
    text: ?[]const u8 = null,
    href: ?[]const u8 = null,
    svg: []const u8 = "",
    aria_label: ?[]const u8 = null,
    style_id: ?[]const u8 = null,
    _state_type: types.StateType = .static,
    _id: ?[]const u8 = null,
    _font_size: u8 = 0,
    _font_weight: ?u16 = null,
    _text_color: ?Color = null,
    _padding: ?types.Padding = null,
    _layout: ?types.Layout = null,
    _background: ?types.Background = null,
    _border: ?types.BorderGrouped = null,
    _border_radius: ?types.BorderRadius = null,
    _margin: ?types.Margin = null,
    _size: ?types.Size = null,

    pub fn Text(text: []const u8) Self {
        return Self{
            .elem_type = .Text,
            .text = if (Fabric.isGenerated) "" else text,
        };
    }

    pub fn TextFmt(comptime fmt: []const u8, args: anytype) Self {
        const allocator = Fabric.frame_arena.getFrameAllocator();
        const text = std.fmt.allocPrint(allocator, fmt, args) catch |err| {
            Fabric.printlnColor(
                \\Error formatting text: {any}\n"
                \\FMT: {s}\n"
                \\ARGS: {any}\n"
            , .{ err, fmt, args }, .hex("#FF3029"));
            return Self{ .elem_type = .Text, .text = "ERROR", ._state_type = .err };
        };
        Fabric.frame_arena.addBytesUsed(text.len);
        return Self{ .elem_type = .TextFmt, .text = if (Fabric.isGenerated) "" else text };
    }

    /// Graphic takes a url to a svg file, during client side rendering it will be fetched and inlined
    /// Graphic(.{ .src = "https://example.com/image.svg" }).style(...);
    /// # Parameters:
    /// - `src`: []const u8,
    ///
    /// # Returns:
    /// Self: Component
    pub fn Graphic(options: struct { src: []const u8 }) Self {
        return Self{ .elem_type = .Graphic, .href = options.src };
    }

    pub fn Icon(token: *const IconTokens) Self {
        if (Fabric.isWasi) {
            return Self{ .elem_type = .Icon, .href = token.web orelse "" };
        } else {
            return Self{ .elem_type = .Icon, .href = token.svg orelse "" };
        }
    }

    pub fn Image(options: struct { src: []const u8 }) Self {
        return Self{ .elem_type = .Image, .href = options.src };
    }

    pub fn Svg(options: struct { svg: []const u8 }) Self {
        if (options.svg.len > 2048 and Fabric.build_options.enable_debug) {
            Fabric.printlnErr("Svg is too large inlining: {d}B, use Graphic;\nSVG Content:\n{s}...", .{ options.svg.len, options.svg[0..100] });
            if (!Fabric.isWasi) {
                @panic("Svg is too large, crashing!");
            } else return Self{ .elem_type = .Svg, .svg = "" };
        }
        return Self{ .elem_type = .Svg, .svg = if (!Fabric.isGenerated or options.svg.len < 128) options.svg else "" };
    }

    pub fn font(self: *const Self, font_size: u8, weight: ?u16, color: ?Color) Self {
        var new_self: Self = self.*;
        new_self._font_size = font_size;
        new_self._font_weight = weight;
        new_self._text_color = color;
        return new_self;
    }

    pub fn layout(self: *const Self, value: types.Layout) Self {
        var new_self: Self = self.*;
        new_self._layout = value;
        return new_self;
    }

    pub fn padding(self: *const Self, value: types.Padding) Self {
        var new_self: Self = self.*;
        new_self._padding = value;
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
        new_self._border = value;
        return new_self;
    }

    pub fn borderRadius(self: *const Self, value: types.BorderRadius) Self {
        var new_self: Self = self.*;
        new_self._border_radius = value;
        return new_self;
    }

    pub fn close(self: *const Self) void {
        var elem_decl = Fabric.ElementDecl{
            .elem_type = self.elem_type,
            .state_type = self._state_type,
            .text = self.text,
            .style = &.{
                .visual = .{
                    .font_size = self._font_size,
                    .font_weight = self._font_weight,
                    .text_color = self._text_color,
                    .background = self._background,
                    .border = self._border,
                    .border_radius = self._border_radius,
                },
                .padding = self._padding,
                .layout = self._layout,
                .margin = self._margin,
                .size = self._size,
            },
            .href = self.href,
            .svg = self.svg,
            .aria_label = self.aria_label,
        };

        if (self._id) |_id| {
            var mutable_style = elem_decl.style.?.*;
            mutable_style.id = _id;
            elem_decl.style = &mutable_style;
        }

        _ = Fabric.LifeCycle.open(elem_decl) orelse unreachable;
        Fabric.LifeCycle.configure(elem_decl);
        return Fabric.LifeCycle.close({});
    }

    pub fn id(self: *const Self, element_id: []const u8) Self {
        var new_self: Self = self.*;
        new_self._id = element_id;
        return new_self;
    }

    pub fn style(self: *const Self, style_ptr: *const Fabric.Style) void {
        var elem_decl = Fabric.ElementDecl{
            .elem_type = self.elem_type,
            .state_type = self._state_type,
            .text = self.text,
            .style = style_ptr,
            .href = self.href,
            .svg = self.svg,
            .aria_label = self.aria_label,
        };

        if (self._id) |_id| {
            var mutable_style = style_ptr.*;
            mutable_style.id = _id;
            elem_decl.style = &mutable_style;
        }

        _ = Fabric.LifeCycle.open(elem_decl) orelse unreachable;
        Fabric.LifeCycle.configure(elem_decl);
        return Fabric.LifeCycle.close({});
    }

    pub inline fn plain(self: *const Self) void {
        const elem_decl = Fabric.ElementDecl{
            .state_type = self._state_type,
            .elem_type = self.elem_type,
            .text = self.text,
            .href = self.href,
            .svg = self.svg,
            .aria_label = self.aria_label,
        };
        _ = Fabric.LifeCycle.open(elem_decl);
        Fabric.LifeCycle.configure(elem_decl);
        Fabric.LifeCycle.close({});
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
    color: ?Fabric.Types.Color = null,
    background: ?Fabric.Types.Background = null,
    border: ?Fabric.Types.BorderGrouped = null,
    delay: u32 = 300,
};

pub const Chain = struct {
    const Self = @This();
    _elem_type: Fabric.ElementType,
    _flex_type: FlexType = .Flex,
    _text: ?[]const u8 = null,
    _href: ?[]const u8 = null,
    _svg: []const u8 = "",
    _aria_label: ?[]const u8 = null,
    _options: ?ButtonOptions = null,
    _input_params: ?*const InputParams = null,
    _ui_node: ?*UINode = null,
    _id: ?[]const u8 = null,
    _style: ?*const Fabric.Style = null,

    _animation_enter: ?*const Fabric.Animation = null,
    _animation_exit: ?*const Fabric.Animation = null,

    // Style props
    _pos: ?types.Position = null,
    _padding: ?types.Padding = null,
    _layout: ?types.Layout = null,
    _margin: ?types.Margin = null,
    _size: ?types.Size = null,
    _child_gap: ?u8 = null,
    _visual: ?types.Visual = null,
    _text_decoration: ?types.TextDecoration = null,
    _interactive: ?types.Interactive = null,
    _transition: ?types.Transition = null,
    _z_index: ?i16 = null,
    _direction: types.Direction = .row,
    _list_style: ?types.ListStyle = .none,

    // _tooltip: ?types.Tooltip = null,

    pub fn TextArea(text: []const u8) Self {
        return Self{ ._elem_type = .TextArea, ._text = text };
    }

    pub fn Label(text: []const u8, tag: []const u8) Self {
        return Self{ .elem_type = .Text, .text = text, .href = tag };
    }

    pub fn Input(params: InputParams) Self {
        return Self{ .elem_type = .Input, ._input_params = params, .style = style };
    }

    pub fn Button(options: ButtonOptions) Self {
        return Self{ ._elem_type = .Button, ._aria_label = options.aria_label, ._options = options };
    }

    pub fn CtxButton(func: anytype, args: anytype) Self {
        const elem_decl = ElementDecl{
            .state_type = .static,
            .elem_type = .CtxButton,
        };

        const ui_node = Fabric.current_ctx.open(elem_decl) catch |err| {
            println("{any}\n", .{err});
            unreachable;
        };
        const Args = @TypeOf(args);
        const Closure = struct {
            arguments: Args,
            run_node: Fabric.Node = .{ .data = .{ .runFn = runFn, .deinitFn = deinitFn } },
            fn runFn(action: *Fabric.Action) void {
                const run_node: *Fabric.Node = @fieldParentPtr("data", action);
                const closure: *@This() = @alignCast(@fieldParentPtr("run_node", run_node));
                @call(.auto, func, closure.arguments);
            }
            fn deinitFn(node: *Fabric.Node) void {
                const closure: *@This() = @alignCast(@fieldParentPtr("run_node", node));
                Fabric.allocator_global.destroy(closure);
            }
        };

        const closure = Fabric.allocator_global.create(Closure) catch |err| {
            println("Error could not create closure {any}\n ", .{err});
            unreachable;
        };
        closure.* = .{
            .arguments = args,
        };

        Fabric.ctx_registry.put(hashKey(ui_node.uuid), &closure.run_node) catch |err| {
            println("Button Function Registry {any}\n", .{err});
            unreachable;
        };

        return Self{ ._elem_type = .CtxButton, ._ui_node = ui_node };
    }

    pub fn ButtonCycle(options: ButtonOptions) Self {
        return Self{ ._elem_type = .ButtonCycle, ._aria_label = options.aria_label, ._options = options };
    }

    pub const Box = Self{ ._elem_type = .FlexBox };
    pub const Center = Self{ ._elem_type = .FlexBox, ._flex_type = .Center };
    pub const Stack = Self{ ._elem_type = .FlexBox, ._flex_type = .Stack };
    pub const List = Self{ ._elem_type = .List };
    pub const ListItem = Self{ ._elem_type = .ListItem };

    pub fn Link(options: struct { url: []const u8, aria_label: ?[]const u8 }) Self {
        return Self{
            ._elem_type = .Link,
            ._aria_label = options.aria_label,
            // ._href = options.url,
            ._href = if (Fabric.isGenerated) "" else options.url,
        };
    }

    pub fn RedirectLink(options: struct { url: []const u8, aria_label: ?[]const u8 }) Self {
        return Self{
            ._elem_type = .RedirectLink,
            // ._href = options.url,
            ._href = if (Fabric.isGenerated) "" else options.url,
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

    pub fn bind(self: *const Self, element: *Element) *const Self {
        element._node_ptr = self._ui_node orelse unreachable;
        return self;
    }

    pub fn animationEnter(self: *const Self, animation_ptr: *const Fabric.Animation) Self {
        var new_self: Self = self.*;
        new_self._animation_enter = animation_ptr;
        return new_self;
    }

    pub fn animationExit(self: *const Self, animation_ptr: *const Fabric.Animation) Self {
        var new_self: Self = self.*;
        new_self._animation_exit = animation_ptr;
        return new_self;
    }

    pub fn tooltip(self: *const Self, tool_tip: *const Tooltip) Self {
        var new_self: Self = self.*;
        var tooltip_style: Fabric.Style = .{
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

    pub fn baseStyle(self: *const Self, style_ptr: *const Fabric.Style) Self {
        var new_self: Self = self.*;
        new_self._style = style_ptr;
        return new_self;
    }

    /// This function takes a const pointer to a Style Struct, and returns the body function callback
    /// This function is static, so any styles added via chaining methods will not be applied
    /// Use baseStyle to keep all chained additions
    pub fn style(self: *const Self, style_ptr: *const Fabric.Style) *const fn (void) void {
        var elem_decl = Fabric.ElementDecl{
            .state_type = .static,
            .elem_type = self._elem_type,
            .text = self._text,
            .style = style_ptr,
            .href = self._href,
            .svg = self._svg,
            .aria_label = self._aria_label,
            .input_params = self._input_params,
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

        if (self._elem_type != .CtxButton) {
            const ui_node = Fabric.LifeCycle.open(elem_decl) orelse unreachable;
            if (self._elem_type == .Button or self._elem_type == .ButtonCycle) {
                if (self._options.?.on_press) |on_press| {
                    Fabric.btn_registry.put(hashKey(ui_node.uuid), on_press) catch |err| {
                        println("Button Function Registry {any}\n", .{err});
                    };
                }
            }
        } else if (self._elem_type == .CtxButton) {
            const ui_node = self._ui_node orelse unreachable;
            if (style_ptr.id) |element_id| {
                const kv = Fabric.ctx_registry.fetchRemove(hashKey(ui_node.uuid)) orelse unreachable;
                Fabric.ctx_registry.put(hashKey(element_id), kv.value) catch |err| {
                    println("Button Function Registry {any}\n", .{err});
                    unreachable;
                };
            }
        }

        Fabric.LifeCycle.configure(elem_decl);
        return Fabric.LifeCycle.close;
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
        new_self._pos = position;
        return new_self;
    }

    pub fn zIndex(self: *const Self, z_index: ?i16) Self {
        var new_self: Self = self.*;
        new_self._z_index = z_index;
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
        visual._background = value;
        new_self._visual = visual;
        return new_self;
    }

    pub fn textDecoration(self: *const Self, value: types.TextDecoration) Self {
        var new_self: Self = self.*;
        new_self._text_decoration = value;
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

    pub fn childGap(self: *const Self, value: u32) Self {
        var new_self: Self = self.*;
        new_self._child_gap = value;
        return new_self;
    }

    pub fn padding(self: *const Self, value: types.Padding) Self {
        var new_self: Self = self.*;
        new_self._padding = value;
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
        if (mutable_style.z_index == null) mutable_style.z_index = self._z_index;
        mutable_style.direction = self._direction;
        mutable_style.list_style = self._list_style;

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

        const elem_decl = Fabric.ElementDecl{
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

        if (self._elem_type != .CtxButton) {
            const ui_node = Fabric.LifeCycle.open(elem_decl) orelse unreachable;
            if (self._elem_type == .Button or self._elem_type == .ButtonCycle) {
                if (self._options.?.on_press) |on_press| {
                    Fabric.btn_registry.put(hashKey(ui_node.uuid), on_press) catch |err| {
                        println("Button Function Registry {any}\n", .{err});
                    };
                }
            }
        } else if (self._elem_type == .CtxButton) {
            const ui_node = self._ui_node orelse unreachable;
            if (elem_decl.style.?.style_id) |element_id| {
                const kv = Fabric.ctx_registry.fetchRemove(hashKey(ui_node.uuid)) orelse unreachable;
                Fabric.ctx_registry.put(hashKey(element_id), kv.value) catch |err| {
                    println("Button Function Registry {any}\n", .{err});
                    unreachable;
                };
            }
        }

        Fabric.LifeCycle.configure(elem_decl);
        return Fabric.LifeCycle.close;
    }

    pub fn plain(self: *const Self) void {
        const elem_decl = Fabric.ElementDecl{
            .state_type = .static,
            .elem_type = self._elem_type,
            .text = self._text,
        };
        _ = Fabric.LifeCycle.open(elem_decl);
        Fabric.LifeCycle.configure(elem_decl);
        Fabric.LifeCycle.close({});
    }
};
