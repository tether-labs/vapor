const std = @import("std");
const types = @import("types.zig");
const Fabric = @import("Fabric.zig");
const println = Fabric.println;
const UIContext = @import("UITree.zig");
const UINode = @import("UITree.zig").UINode;
const CommandsTree = UIContext.CommandsTree;
const Transition = @import("Transition.zig").Transition;
const TransitionState = @import("Transition.zig").TransitionState;
const Element = @import("Element.zig").Element;
const LifeCycle = Fabric.LifeCycle;
const Static = @import("Static.zig");
const Binded = @import("Binded.zig");
const Types = @import("types.zig");

const Style = types.Style;
const EventType = types.EventType;
const Active = types.Active;
const BoundingBox = types.BoundingBox;
const InputDetails = types.InputDetails;
const Dimensions = types.Dimensions;
const InputParams = types.InputParams;
const ElementDecl = types.ElementDeclaration;
const RenderCommand = types.RenderCommand;
const ElementType = types.ElementType;
const Hover = types.Hover;
const Transform = types.Transform;
const TransformType = types.TransformType;

const HeaderSize = enum(u32) {
    XXLarge = 12,
    XLarge = 8,
    Large = 4,
    Medium = 2,
    Small = 1,
};

const IconOptions = struct {
    icon_name: []const u8,
    style: ?*const Style = null,
};

pub inline fn Icon(options: IconOptions) void {
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

    const elem_decl = ElementDecl{
        .href = options.icon_name,
        .elem_type = .Icon,
        .style = options.style,
        .dynamic = .pure,
    };

    // if (style.style_id == null) {
    //     elem_decl.style.style_id = icon_name;
    // }

    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    _ = local.CloseElement();
}

pub inline fn Header(text: []const u8, size: HeaderSize, style: Style) void {
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
        .style = style,
        .dynamic = .pure,
        .elem_type = .Header,
        .text = text,
    };
    // const dimensions = measureText(text, &elem_decl.style);
    // // Make sure this is the right order of ops
    // elem_decl.style.width = dimensions.width;
    // elem_decl.style.height = dimensions.height;
    elem_decl.style.width.type = .elastic;
    if (style.font_size == 0) {
        switch (size) {
            .XXLarge => elem_decl.style.font_size = 12 * 12,
            .XLarge => elem_decl.style.font_size = 12 * 8,
            .Large => elem_decl.style.font_size = 12 * 4,
            .Medium => elem_decl.style.font_size = 12 * 2,
            .Small => elem_decl.style.font_size = 12 * 1,
        }
    }
    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    _ = local.CloseElement();
    return;
}
pub inline fn Hooks(hooks: Fabric.HooksFuncs) fn (void) void {
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

    var elem_decl = ElementDecl{
        .elem_type = .Hooks,
    };

    if (hooks.mounted) |f| {
        const id = Fabric.mounted_funcs.count();
        elem_decl.hooks.mounted_id += id + 1;
        Fabric.mounted_funcs.put(elem_decl.hooks.mounted_id, f) catch |err| {
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

    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

pub inline fn Draggable(element: *Element, style: Style) fn (void) void {
    const local = struct {
        fn CloseElement(_: void) void {
            _ = Fabric.current_ctx.close();
            return;
        }
        fn ConfigureElement(elem_decl: ElementDecl) *UINode {
            return Fabric.current_ctx.configure(elem_decl);
        }
    };

    var elem_decl = ElementDecl{
        .style = style,
        .dynamic = .pure,
        .elem_type = .Draggable,
    };

    elem_decl.style.position.type = .absolute;

    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
        unreachable;
    };
    const ui_node = local.ConfigureElement(elem_decl);
    element.uuid = ui_node.uuid;
    element.draggable = true;
    element.element_type = .Draggable;
    return local.CloseElement;
}

const FlexType = enum(u8) {
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
};

const ButtonOptions = struct {
    on_press: ?*const fn () void = null,
    onRelease: ?*const fn () void = null,
    aria_label: ?[]const u8 = null,
};

pub fn VirtualList(comptime T: type) type {
    return struct {
        var total_height: f32 = 0;
        var list_height: f32 = 0;
        var total_items: f32 = 0;
        var scroll_top_max: f32 = 0;
        var total_window_items: usize = 0;
        const VirtualListOptions = struct {
            data: []const T,
            render: *const fn (T, usize) void,
            buffer_size: usize = 10,
            item_height: Types.Sizing,
            item_width: Types.Sizing,
        };
        const ScrollDirection = enum {
            up,
            down,
            none,
        };
        const Self = @This();
        data: []const T,
        render: *const fn (T, usize) void,
        buffer_size: f32 = 10,
        item_height: f32,
        item_width: f32,
        _internal_slice: []T,
        list_element: Element = undefined,
        inner_container: Element = undefined,
        window_element: Element = undefined,
        current_scroll: f32 = 0, // the current scroll of the list
        current_item_index: usize = 0, // the current item index

        // Add these fields to your struct
        prev_scroll_top: f32 = 0,
        prev_item_index: f32 = 0,
        up_threshold: f32 = 0,
        down_threshold: f32 = 0,

        pub fn init(options: VirtualListOptions) Self {
            const calculated_item_height = options.item_height.size.minmax.min;
            const calculated_item_width = options.item_width.size.minmax.min;

            var item_height: f32 = 0;
            var item_width: f32 = 0;
            switch (options.item_height.type) {
                .fit => item_height = calculated_item_height,
                .min_max_vp => item_height = calculated_item_height,
                .grow => item_height = calculated_item_height,
                .percent => item_height = calculated_item_height * Fabric.browser_height / 100,
                .fixed => item_height = options.item_height.size.minmax.min,
                .elastic => item_height = calculated_item_height,
                .elastic_percent => item_height = calculated_item_height,
                .clamp_px => item_height = calculated_item_height,
                .clamp_percent => item_height = calculated_item_height,
                .none => {},
            }
            switch (options.item_width.type) {
                .fit => item_width = calculated_item_width,
                .min_max_vp => item_width = calculated_item_width,
                .grow => item_width = calculated_item_width,
                .percent => item_width = calculated_item_width * Fabric.browser_width / 100,
                .fixed => item_width = options.item_width.size.minmax.min,
                .elastic => item_width = calculated_item_width,
                .elastic_percent => item_width = calculated_item_width,
                .clamp_px => item_width = calculated_item_width,
                .clamp_percent => item_width = calculated_item_width,
                .none => {},
            }

            total_height = @as(f32, @floatFromInt(options.data.len)) * item_height;
            total_items = @as(f32, @floatFromInt(options.data.len));
            scroll_top_max = total_height - Fabric.browser_height;

            const number_of_items_fit = @as(usize, @intFromFloat(@floor(Fabric.browser_height / item_height)));
            const min_buffer: usize = 20;
            const max_buffer: usize = 100;

            // Use larger buffer for smaller visible counts, smaller buffer for larger visible counts
            const buffer_size = if (number_of_items_fit <= 5)
                @min(number_of_items_fit * 5, max_buffer)
            else if (number_of_items_fit <= 20)
                @min(number_of_items_fit * 3, max_buffer)
            else
                @min(number_of_items_fit * 2, max_buffer);

            total_window_items = @max(min_buffer, @min(buffer_size, options.data.len));
            Fabric.println("total_window_items {d}", .{total_window_items});

            list_height = @as(f32, @floatFromInt(total_window_items)) * item_height;

            var internal_slice: []T = Fabric.allocator_global.alloc(T, total_window_items) catch unreachable;
            for (0..total_window_items) |i| {
                internal_slice[i] = options.data[i];
            }

            return Self{
                .data = options.data,
                .render = options.render,
                .buffer_size = @as(f32, @floatFromInt(options.buffer_size)),
                .item_height = item_height,
                .item_width = item_width,
                ._internal_slice = internal_slice,
                .list_element = Element{},
                .inner_container = Element{},
                .window_element = Element{},
                .current_scroll = 0,
                .current_item_index = 0,
            };
        }

        fn mount(self: *Self) void {
            Fabric.println("Mount {s}\n", .{self.inner_container._get_id().?});
            _ = self.inner_container.addInstListener(.scroll, self, trackScroll);
        }

        fn rerender_list(self: *Self, current_index: f32, direction: ScrollDirection) void {
            const start_index: usize = @max(0, @as(usize, @intFromFloat(@max(0, current_index - self.buffer_size))));
            // Add 1 to include the end_index item, but cap at data length
            const end_index: usize = @min(self.data.len, @as(usize, @intFromFloat(@min(total_items, current_index + self.buffer_size + 1))));

            if (start_index >= self.data.len) return;

            // Optional: Add momentum-based preloading
            const preload_extra = switch (direction) {
                .down => @min(5, self.data.len - end_index), // Preload 5 more items when scrolling down
                .up => 0, // Less preloading when scrolling up
                .none => 0,
            };

            const final_end = @min(self.data.len, end_index + preload_extra);

            for (start_index..final_end, 0..) |data_index, i| {
                self._internal_slice[i] = self.data[data_index];
            }

            // for (start_index..end_index, 0..) |data_index, i| {
            //     self._internal_slice[i] = self.data[data_index];
            // }

            const translation = Fabric.fmtln("translateY({d}px)", .{start_index * @as(usize, @intFromFloat(self.item_height))});
            self.window_element.mutateStyle("transform", .{ .string = translation });
            Fabric.cycle();
        }

        pub fn trackScroll(self: *Self, _: *Fabric.Event) void {
            const scroll_top: f32 = @floatFromInt(self.inner_container.getAttributeNumber("scrollTop"));
            const current_item_index = @floor(@divExact(scroll_top, self.item_height));

            // Determine scroll direction
            const direction: ScrollDirection = if (scroll_top > self.prev_scroll_top) .down else if (scroll_top < self.prev_scroll_top) .up else .none;

            // Check if we need to rerender based on direction and thresholds
            const should_rerender = switch (direction) {
                .down => scroll_top > self.down_threshold and !self.isAtEnd(current_item_index),
                .up => scroll_top < self.up_threshold and !self.isAtStart(current_item_index),
                .none => false,
            };
            if (should_rerender) {
                self.rerender_list(current_item_index, direction);

                // Update thresholds based on direction
                switch (direction) {
                    .down => {
                        self.down_threshold = scroll_top + (5 * self.item_height); // Next rerender point
                        self.up_threshold = scroll_top - (5 * self.item_height); // Reverse direction threshold
                    },
                    .up => {
                        self.up_threshold = scroll_top - (5 * self.item_height); // Next rerender point
                        self.down_threshold = scroll_top + (5 * self.item_height); // Reverse direction threshold
                    },
                    .none => {},
                }
            }

            // Store current state for next comparison
            self.prev_scroll_top = scroll_top;
            self.prev_item_index = current_item_index;
        }

        fn isAtEnd(self: *Self, current_item_index: f32) bool {
            return current_item_index + self.buffer_size - 1 >= @as(f32, @floatFromInt(self.data.len));
        }

        fn isAtStart(_: *Self, current_item_index: f32) bool {
            return current_item_index <= 0;
        }

        pub fn generate(self: *Self) void {
            Static.CtxHooks(.mounted, mount, .{self}, &.{
                .size = .{ .width = .percent(100) },
            })({
                Binded.List(.{
                    .element = &self.inner_container,
                    .style = &.{
                        .size = .{
                            .height = .px(Fabric.browser_height),
                            .width = .percent(100),
                        },
                        .direction = .column,
                        .scroll = .scroll_y(),
                        .padding = .all(0),
                        .list_style = .none,
                        .show_scrollbar = false,
                    },
                })({
                    Binded.Box(.{
                        .element = &self.list_element,
                        .style = &.{
                            .size = .{
                                .height = .px(total_height),
                                .width = .percent(100),
                            },
                            .direction = .column,
                        },
                    })({
                        Binded.List(.{
                            .element = &self.window_element,
                            .style = &.{
                                .position = .{
                                    .type = .absolute,
                                    .top = .px(0),
                                },
                                .list_style = .none,
                                .size = .{
                                    .height = .px(list_height),
                                    .width = .percent(100),
                                },
                                .direction = .column,
                                .scroll = .none(),
                                .padding = .all(0),
                            },
                        })({
                            for (self._internal_slice, 0..) |item, i| {
                                Static.ListItem(.{ .style = &.{
                                    .size = .{
                                        .height = .px(self.item_height),
                                        .width = .percent(self.item_width),
                                    },
                                } })({
                                    @call(.auto, self.render, .{ item, i });
                                });
                            }
                        });
                    });
                });
            });
        }
    };
}

pub const ChainClose = struct {
    const Self = @This();
    elem_type: Fabric.ElementType,
    state_type: Types.StateType = .pure,
    _flex_type: FlexType = .Flex,
    text: []const u8 = "",
    href: []const u8 = "",
    svg: []const u8 = "",
    aria_label: ?[]const u8 = null,

    pub fn Text(text: []const u8) Self {
        return Self{ .elem_type = .Text, .text = text };
    }

    /// TextFmt takes a format string and a array of arguments and allocates a new string
    /// This string is handled by the Fabric engine and is not freed by the user
    pub inline fn TextFmt(fmt: []const u8, args: anytype) Self {
        const allocator = Fabric.frame_arena.getFrameAllocator();
        const text = std.fmt.allocPrint(allocator, fmt, args) catch |err| {
            Fabric.printlnColor(
                \\Error formatting text: {any}\n"
                \\FMT: {s}\n"
                \\ARGS: {any}\n"
            , .{ err, fmt, args }, .hex("#FF3029"));
            return Self{ .elem_type = .Text, .text = "ERROR", .state_type = .err };
        };
        Fabric.frame_arena.addBytesUsed(text.len);
        return Self{ .elem_type = .TextFmt, .text = text };
    }

    /// TextFmt takes a format string and a array of arguments and allocates a new string
    /// This string is handled by the Fabric engine and is not freed by the user
    pub inline fn TextFmtErr(fmt: []const u8, args: anytype) Self {
        // const allocator = Fabric.frame_arena.getFrameAllocator();
        // const text = std.fmt.allocPrint(allocator, fmt, args) catch |err| {
        //     std.debug.print("Error formatting text: {any}\n", .{err});
        Fabric.printlnColor(
            \\Error formatting text: {any}
            \\FMT: {s}
            \\ARGS: {any}
        , .{ error.CouldNotAllocate, fmt, args }, .hex("#FF3029"));
        return Self{ .elem_type = .Text, .text = "ERROR", .state_type = .err };
        // };
        // Fabric.frame_arena.addBytesUsed(text.len);
        // return Self{ .elem_type = .TextFmt, .text = text };
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
            .dynamic = self.state_type,
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
    elem_type: Fabric.ElementType,
    _flex_type: FlexType = .Flex,
    text: []const u8 = "",
    href: []const u8 = "",
    svg: []const u8 = "",
    aria_label: ?[]const u8 = null,
    options: ?ButtonOptions = null,
    _ui_node: *UINode = undefined,

    pub fn Icon(name: []const u8) Self {
        return Self{ .elem_type = .Icon, .href = name };
    }

    pub fn Button(options: ButtonOptions) Self {
        return Self{ .elem_type = .Button, .aria_label = options.aria_label, .options = options };
    }

    pub fn CtxButton(func: anytype, args: anytype) Self {
        const elem_decl = ElementDecl{
            .dynamic = .pure,
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

        return Self{ .elem_type = .CtxButton, ._ui_node = ui_node };
    }

    pub fn ButtonCycle(options: ButtonOptions) Self {
        return Self{ .elem_type = .ButtonCycle, .aria_label = options.aria_label, .options = options };
    }

    pub const Box = Self{ .elem_type = .FlexBox };
    pub const Center = Self{ .elem_type = .FlexBox, ._flex_type = .Center };
    pub const Stack = Self{ .elem_type = .FlexBox, ._flex_type = .Stack };

    pub fn Link(options: struct { url: []const u8, aria_label: ?[]const u8 }) Self {
        return Self{ .elem_type = .Link, .href = options.url, .aria_label = options.aria_label };
    }

    pub fn Image(options: struct { src: []const u8 }) Self {
        return Self{ .elem_type = .Image, .href = options.src };
    }

    pub fn Svg(options: struct { svg: []const u8 }) Self {
        return Self{ .elem_type = .Svg, .svg = options.svg };
    }

    pub inline fn style(self: *const Self, style_ptr: *const Fabric.Style) fn (void) void {
        var elem_decl = Fabric.ElementDecl{
            .dynamic = .pure,
            .elem_type = self.elem_type,
            .text = self.text,
            .style = style_ptr,
            .href = self.href,
            .svg = self.svg,
            .aria_label = self.aria_label,
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

        if (self.elem_type != .CtxButton) {
            const ui_node = Fabric.LifeCycle.open(elem_decl) orelse unreachable;
            if (self.elem_type == .Button or self.elem_type == .ButtonCycle) {
                if (self.options.?.on_press) |on_press| {
                    Fabric.btn_registry.put(ui_node.uuid, on_press) catch |err| {
                        println("Button Function Registry {any}\n", .{err});
                    };
                }
            }
        }

        Fabric.LifeCycle.configure(elem_decl);
        return Fabric.LifeCycle.close;
    }

    pub inline fn plain(self: *const Self) void {
        const elem_decl = Fabric.ElementDecl{
            .dynamic = .static,
            .elem_type = self.elem_type,
            .text = self.text,
        };
        _ = Fabric.LifeCycle.open(elem_decl);
        Fabric.LifeCycle.configure(elem_decl);
        Fabric.LifeCycle.close({});
    }
};

pub inline fn Text(text: []const u8, style: Style) void {
    const local = struct {
        fn CloseElement() void {
            _ = Fabric.current_ctx.close();
            return;
        }
        fn ConfigureElement(elem_decl: ElementDecl) void {
            _ = Fabric.current_ctx.configure(elem_decl);
            // CloseElement();
            return;
        }
    };

    var elem_decl = ElementDecl{
        .style = style,
        .dynamic = .pure,
        .elem_type = .Text,
        .text = text,
    };
    elem_decl.style.width.type = .elastic;
    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    _ = local.CloseElement();
    return;
}

pub inline fn TextArea(text: []const u8, style: Style) void {
    const local = struct {
        fn CloseElement() void {
            _ = Fabric.current_ctx.close();
            return;
        }
        fn ConfigureElement(elem_decl: ElementDecl) void {
            _ = Fabric.current_ctx.configure(elem_decl);
            // CloseElement();
            return;
        }
    };

    const elem_decl = ElementDecl{
        .style = style,
        .dynamic = .pure,
        .elem_type = .TextArea,
        .text = text,
    };
    // const dimensions = measureText(text, &elem_decl.style);
    // Make sure this is the right order of ops
    // elem_decl.style.width = dimensions.width;
    // elem_decl.style.height = dimensions.height;
    // println("Min: {}\n", .{elem_decl.style.width.size.minmax.min});
    // println("Max: {}\n", .{elem_decl.style.width.size.minmax.max});
    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    _ = local.CloseElement();
    return;
}
pub inline fn Box(style: Style) fn (void) void {
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
        .dynamic = .pure,
        .elem_type = .Box,
    };
    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

pub inline fn Svg(svg: []const u8, style: Style) fn (void) void {
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
        .svg = svg,
        .style = style,
        .dynamic = .pure,
        .elem_type = .Svg,
    };
    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

const CtxButtonOptions = struct {
    style: ?*const Style = null,
};

pub inline fn CtxButton(func: anytype, args: anytype, options: CtxButtonOptions) fn (void) void {
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
        .style = options.style,
        .dynamic = .pure,
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

    Fabric.ctx_registry.put(ui_node.uuid, &closure.run_node) catch |err| {
        println("Button Function Registry {any}\n", .{err});
        unreachable;
    };

    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}
pub const BtnProps = struct {
    onPress: ?*const fn () void = null,
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
        .dynamic = .pure,
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
        .dynamic = .pure,
        .elem_type = .SelectItem,
    };
    _ = Fabric.current_ctx.open(elem_decl) catch {};
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}
const ListOptions = struct {
    style: ?*const Style = null,
};

pub inline fn List(options: ListOptions) fn (void) void {
    const elem_decl = ElementDecl{
        .style = options.style,
        .dynamic = .pure,
        .elem_type = .List,
    };
    _ = LifeCycle.open(elem_decl);
    _ = LifeCycle.configure(elem_decl);
    return LifeCycle.close;
}

const ListItemOptions = struct {
    style: ?*const Style = null,
};

pub inline fn ListItem(options: ListItemOptions) fn (void) void {
    const elem_decl = ElementDecl{
        .style = options.style,
        .dynamic = .pure,
        .elem_type = .ListItem,
    };

    _ = LifeCycle.open(elem_decl);
    LifeCycle.configure(elem_decl);
    return LifeCycle.close;
}

pub inline fn Circle(style: Style) fn (void) void {
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

    var elem_decl = ElementDecl{
        .style = style,
        .dynamic = .pure,
        .elem_type = .Block,
    };
    elem_decl.style.border_radius = .all(99);

    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
        unreachable;
    };
    // if (style.active) |act| {
    //     act.signal_ptr.subscribe(ui_node);
    // }
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

pub inline fn Bind(element: *Element, style: Style) fn (void) void {
    const local = struct {
        fn CloseElement(_: void) void {
            _ = Fabric.current_ctx.close();
            return;
        }
        fn ConfigureElement(elem_decl: ElementDecl) *UINode {
            return Fabric.current_ctx.configure(elem_decl);
        }
    };

    const elem_decl = ElementDecl{
        .style = style,
        .dynamic = .pure,
        .elem_type = .Bind,
    };

    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
        unreachable;
    };
    // ui_node.uuid = .{'1'} ** 36;
    // if (style.active) |act| {
    //     act.signal_ptr.subscribe(ui_node);
    // }
    const ui_node = local.ConfigureElement(elem_decl);
    element.uuid = ui_node.uuid;
    return local.CloseElement;
}

pub inline fn Input(params: InputParams, style: Style) void {
    const local = struct {
        fn CloseElement() void {
            _ = Fabric.current_ctx.close();
            return;
        }
        fn ConfigureElement(elem_decl: ElementDecl) void {
            _ = Fabric.current_ctx.configure(elem_decl);
        }
    };

    const elem_decl = ElementDecl{
        .style = style,
        .dynamic = .pure,
        .elem_type = .Input,
        .input_params = params,
    };

    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
        unreachable;
    };
    // if (style.active) |act| {
    //     act.signal_ptr.subscribe(ui_node);
    // }
    local.ConfigureElement(elem_decl);
    local.CloseElement();
    return;
}

pub inline fn Block(style: Style) fn (void) void {
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
        .dynamic = .pure,
        .elem_type = .Block,
    };

    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
        unreachable;
    };
    // if (style.active) |act| {
    //     act.signal_ptr.subscribe(ui_node);
    // }
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

pub inline fn FlexBox(style: Style) fn (void) void {
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
        .dynamic = .pure,
        .elem_type = .FlexBox,
    };
    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

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

pub inline fn RedirectLink(url: []const u8, style: Style) fn (void) void {
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
        .href = url,
        .elem_type = .RedirectLink,
        .style = style,
        .dynamic = .pure,
    };
    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

pub inline fn Link(url: []const u8, style: Style) fn (void) void {
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
        .href = url,
        .elem_type = .Link,
        .style = style,
        .dynamic = .pure,
    };
    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}

pub inline fn Dialog(style: Style) fn (void) void {
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
        .elem_type = .Dialog,
        .style = style,
        .dynamic = .pure,
    };
    _ = Fabric.current_ctx.open(elem_decl) catch |err| {
        println("{any}\n", .{err});
    };
    _ = local.ConfigureElement(elem_decl);
    return local.CloseElement;
}
