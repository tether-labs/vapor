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
        .dynamic = .static,
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
        .dynamic = .static,
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
        Fabric.mounted_ctx_funcs.append(elem_decl.hooks.mounted_id, &closure.run_node) catch |err| {
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
        .dynamic = .static,
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
    const node = Fabric.ctx_registry.get(id) orelse return;
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
    const func = Fabric.btn_registry.get(id) orelse return;
    @call(.auto, func, .{});
}

export fn buttonCycleCallback(id_ptr: [*:0]u8) void {
    const id = std.mem.span(id_ptr);
    defer Fabric.allocator_global.free(id);
    Fabric.current_depth_node_id = std.mem.Allocator.dupe(Fabric.allocator_global, u8, id) catch return;
    const func = Fabric.btn_registry.get(id) orelse return;
    @call(.auto, func, .{});
    Fabric.cycle();
}

export fn hooksRemoveMountedKey(id_ptr: [*:0]u8) void {
    const id = std.mem.span(id_ptr);
    defer Fabric.allocator_global.free(id);
    const hook = Fabric.mounted_funcs.fetchRemove(id) orelse return;
    Fabric.allocator_global.free(hook.key);
}

export fn hooksMountedCallback(id_ptr: [*:0]u8) void {
    const id = std.mem.span(id_ptr);
    defer Fabric.allocator_global.free(id);
    const func = Fabric.mounted_funcs.get(id) orelse {
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

pub inline fn SubmitCtxButton(style: Style) fn (void) void {
    const local = struct {
        fn CloseElement(_: void) void {
            _ = Fabric.current_ctx.close();
            return;
        }
        fn ConfigureElement(elem_decl: ElementDecl) *const fn (void) void {
            _ = Fabric.current_ctx.configure(elem_decl);
            return CloseElement;
        }
    };

    const elem_decl = ElementDecl{
        .style = style,
        .dynamic = .static,
        .elem_type = .SubmitCtxButton,
    };

    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };

    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
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

pub inline fn Select(style: Style) fn (void) void {
    const local = struct {
        fn CloseElement(_: void) void {
            _ = Fabric.current_ctx.close();
            return;
        }
        fn ConfigureElement(elem_decl: ElementDecl) *const fn (void) void {
            _ = Fabric.current_ctx.configure(elem_decl);
            return CloseElement;
        }
    };

    const elem_decl = ElementDecl{
        .style = style,
        .dynamic = .static,
        .elem_type = .Select,
    };
    _ = Fabric.current_ctx.open(elem_decl) catch {};
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

pub inline fn SelectItem(style: Style) fn (void) void {
    const local = struct {
        fn CloseElement(_: void) void {
            _ = Fabric.current_ctx.close();
            return;
        }
        fn ConfigureElement(elem_decl: ElementDecl) *const fn (void) void {
            _ = Fabric.current_ctx.configure(elem_decl);
            return CloseElement;
        }
    };

    const elem_decl = ElementDecl{
        .style = style,
        .dynamic = .static,
        .elem_type = .SelectItem,
    };
    _ = Fabric.current_ctx.open(elem_decl) catch {};
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

pub inline fn Form(style: Style) fn (void) void {
    const local = struct {
        fn CloseElement(_: void) void {
            _ = Fabric.current_ctx.close();
            return;
        }
        fn ConfigureElement(elem_decl: ElementDecl) *const fn (void) void {
            _ = Fabric.current_ctx.configure(elem_decl);
            return CloseElement;
        }
    };

    const elem_decl = ElementDecl{
        .style = style,
        .dynamic = .static,
        .elem_type = .Form,
    };
    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

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
    text: []const u8 = "",
    href: []const u8 = "",
    svg: []const u8 = "",
    aria_label: ?[]const u8 = null,

    pub fn Text(text: []const u8) Self {
        return Self{ .elem_type = .Text, .text = text };
    }
    pub fn Icon(name: []const u8) Self {
        return Self{ .elem_type = .Icon, .href = name };
    }
    pub fn Image(options: struct { src: []const u8 }) Self {
        return Self{ .elem_type = .Image, .href = options.src };
    }

    pub fn Svg(options: struct { svg: []const u8 }) Self {
        return Self{ .elem_type = .Svg, .svg = options.svg };
    }

    pub inline fn style(self: *const Self, style_ptr: *const Fabric.Style) void {
        const elem_decl = Fabric.ElementDecl{
            .dynamic = .static,
            .elem_type = self.elem_type,
            .text = self.text,
            .style = style_ptr,
            .href = self.href,
            .svg = self.svg,
            .aria_label = self.aria_label,
        };

        _ = Fabric.LifeCycle.open(elem_decl) orelse unreachable;
        Fabric.LifeCycle.configure(elem_decl);
        return Fabric.LifeCycle.close({});
    }
};

pub const Chain = struct {
    const Self = @This();
    _elem_type: Fabric.ElementType,
    _flex_type: FlexType = .Flex,
    _text: []const u8 = "",
    _href: []const u8 = "",
    _svg: []const u8 = "",
    _aria_label: ?[]const u8 = null,
    _options: ?ButtonOptions = null,
    _input_params: ?*const InputParams = null,
    _ui_node: ?*UINode = null,
    _id: ?[]const u8 = null,

    pub fn Text(text: []const u8) Self {
        return Self{ ._elem_type = .Text, ._text = text };
    }
    pub fn TextArea(text: []const u8) Self {
        return Self{ ._elem_type = .TextArea, ._text = text };
    }

    pub fn Label(text: []const u8, tag: []const u8) Self {
        return Self{ .elem_type = .Text, .text = text, .href = tag };
    }

    pub fn Input(params: InputParams) Self {
        return Self{ .elem_type = .Input, ._input_params = params, .style = style };
    }

    pub fn Icon(name: []const u8) Self {
        return Self{ ._elem_type = .Icon, ._href = name };
    }

    pub fn Button(options: ButtonOptions) Self {
        return Self{ ._elem_type = .Button, ._aria_label = options.aria_label, ._options = options };
    }

    pub fn CtxButton(func: anytype, args: anytype) Self {
        const elem_decl = ElementDecl{
            .dynamic = .static,
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

        Fabric.ctx_registry.put(ui_node.uuid, &closure.run_node) catch |err| {
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
        return Self{ ._elem_type = .Link, ._href = options.url, ._aria_label = options.aria_label };
    }

    pub fn RedirectLink(options: struct { url: []const u8, aria_label: ?[]const u8 }) Self {
        return Self{ ._elem_type = .RedirectLink, ._href = options.url, ._aria_label = options.aria_label };
    }

    pub fn Image(options: struct { src: []const u8 }) Self {
        return Self{ ._elem_type = .Image, ._href = options.src };
    }

    pub fn Svg(options: struct { svg: []const u8 }) Self {
        if (options.svg.len > 2048 and Fabric.build_options.enable_debug) {
            Fabric.printlnErr("Svg is too large inlining: {d}B, use Graphic;\nSVG Content:\n{s}...", .{ options.svg.len, options.svg[0..100] });
            if (!Fabric.isWasi) {
                @panic("Svg is too large, crashing!");
            } else return Self{ ._elem_type = .Svg, ._svg = "" };
        } else {
            return Self{ ._elem_type = .Svg, ._svg = options.svg };
        }
    }

    /// Graphic takes a url to a svg file, during client side rendering it will be fetched and inlined
    /// Graphic(.{ .src = "https://example.com/image.svg" }).style(...);
    /// # Parameters:
    /// - `src`: []const u8,
    ///
    /// # Returns:
    /// Self: Component
    pub inline fn Graphic(options: struct { src: []const u8 }) Self {
        return Self{ ._elem_type = .Graphic, ._href = options.src };
    }

    pub inline fn id(self: *const Self, element_id: []const u8) Self {
        var new_self: Self = self.*;
        new_self._id = element_id;
        return new_self;
    }

    pub inline fn style(self: *const Self, style_ptr: *const Fabric.Style) fn (void) void {
        var elem_decl = Fabric.ElementDecl{
            .dynamic = .static,
            .elem_type = self._elem_type,
            .text = self._text,
            .style = style_ptr,
            .href = self._href,
            .svg = self._svg,
            .aria_label = self._aria_label,
            .input_params = self._input_params,
        };

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

        if (self._elem_type != .CtxButton) {
            const ui_node = Fabric.LifeCycle.open(elem_decl) orelse unreachable;
            if (self._elem_type == .Button or self._elem_type == .ButtonCycle) {
                if (self._options.?.on_press) |on_press| {
                    Fabric.btn_registry.put(ui_node.uuid, on_press) catch |err| {
                        println("Button Function Registry {any}\n", .{err});
                    };
                }
            }
        } else if (self._elem_type == .CtxButton) {
            const ui_node = self._ui_node orelse unreachable;
            if (style_ptr.id) |element_id| {
                const kv = Fabric.ctx_registry.fetchRemove(ui_node.uuid) orelse unreachable;
                Fabric.ctx_registry.put(element_id, kv.value) catch |err| {
                    println("Button Function Registry {any}\n", .{err});
                    unreachable;
                };
            }
        }

        Fabric.LifeCycle.configure(elem_decl);
        return Fabric.LifeCycle.close;
    }

    pub inline fn plain(self: *const Self) void {
        const elem_decl = Fabric.ElementDecl{
            .dynamic = .static,
            .elem_type = self._elem_type,
            .text = self._text,
        };
        _ = Fabric.LifeCycle.open(elem_decl);
        Fabric.LifeCycle.configure(elem_decl);
        Fabric.LifeCycle.close({});
    }

    pub inline fn child(_: *const Self, children: void) void {
        Fabric.LifeCycle.close(children);
    }
};

pub inline fn EmbedIcon(link: []const u8) fn (void) void {
    const elem_decl = ElementDecl{
        .href = link,
        .elem_type = .EmbedIcon,
    };

    _ = LifeCycle.open(elem_decl);
    LifeCycle.configure(elem_decl);
    return LifeCycle.close;
}

const IconOptions = struct {
    icon_name: []const u8,
    style: ?*const Style = null,
};

pub inline fn Icon(options: IconOptions) void {
    const elem_decl = ElementDecl{
        .href = options.icon_name,
        .elem_type = .Icon,
        .style = options.style,
        .dynamic = .static,
    };
    _ = LifeCycle.open(elem_decl);
    LifeCycle.configure(elem_decl);
    LifeCycle.close({});
}

const ImageOptions = struct {
    src: []const u8,
    style: *const Style = &.{},
};

pub inline fn EmbedLink(link: []const u8) fn (void) void {
    const local = struct {
        fn CloseElement(_: void) void {
            _ = Fabric.current_ctx.close();
            return;
        }
        fn ConfigureElement(elem_decl: ElementDecl) *const fn (void) void {
            _ = Fabric.current_ctx.configure(elem_decl);
            return CloseElement;
        }
    };

    const elem_decl = ElementDecl{
        .href = link,
        .elem_type = .EmbedLink,
    };
    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

pub inline fn Table(style: Style) fn (void) void {
    const local = struct {
        fn CloseElement(_: void) void {
            _ = Fabric.current_ctx.close();
            return;
        }
        fn ConfigureElement(elem_decl: ElementDecl) *const fn (void) void {
            _ = Fabric.current_ctx.configure(elem_decl);
            return CloseElement;
        }
    };

    const elem_decl = ElementDecl{
        .elem_type = .Table,
        .style = style,
        .dynamic = .static,
    };
    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

pub inline fn TableHeader(style: Style) fn (void) void {
    const local = struct {
        fn CloseElement(_: void) void {
            _ = Fabric.current_ctx.close();
            return;
        }
        fn ConfigureElement(elem_decl: ElementDecl) *const fn (void) void {
            _ = Fabric.current_ctx.configure(elem_decl);
            return CloseElement;
        }
    };

    const elem_decl = ElementDecl{
        .elem_type = .TableHeader,
        .style = style,
        .dynamic = .static,
    };
    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

pub inline fn TableCell(style: Style) fn (void) void {
    const local = struct {
        fn CloseElement(_: void) void {
            _ = Fabric.current_ctx.close();
            return;
        }
        fn ConfigureElement(elem_decl: ElementDecl) *const fn (void) void {
            _ = Fabric.current_ctx.configure(elem_decl);
            return CloseElement;
        }
    };

    const elem_decl = ElementDecl{
        .elem_type = .TableCell,
        .style = style,
        .dynamic = .static,
    };
    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

pub inline fn TableBody(style: Style) fn (void) void {
    const local = struct {
        fn CloseElement(_: void) void {
            _ = Fabric.current_ctx.close();
            return;
        }
        fn ConfigureElement(elem_decl: ElementDecl) *const fn (void) void {
            _ = Fabric.current_ctx.configure(elem_decl);
            return CloseElement;
        }
    };

    const elem_decl = ElementDecl{
        .elem_type = .TableBody,
        .style = style,
        .dynamic = .static,
    };
    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

pub inline fn TableRow(style: Style) fn (void) void {
    const local = struct {
        fn CloseElement(_: void) void {
            _ = Fabric.current_ctx.close();
            return;
        }
        fn ConfigureElement(elem_decl: ElementDecl) *const fn (void) void {
            _ = Fabric.current_ctx.configure(elem_decl);
            return CloseElement;
        }
    };

    const elem_decl = ElementDecl{
        .elem_type = .TableRow,
        .style = style,
        .dynamic = .static,
    };
    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

pub inline fn Canvas(id: []const u8) void {
    const local = struct {
        fn CloseElement() void {
            _ = Fabric.current_ctx.close();
            return;
        }
        fn ConfigureElement(elem_decl: ElementDecl) void {
            _ = Fabric.current_ctx.configure(elem_decl);
            return;
        }
    };

    var elem_decl = ElementDecl{
        .dynamic = .static,
        .elem_type = .Canvas,
    };
    elem_decl.style.id = id;

    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    _ = local.CloseElement();
    return;
}
