const std = @import("std");
const Fabric = @import("Fabric.zig");
const KeyGenerator = @import("Key.zig").KeyGenerator;
const utils = @import("utils.zig");
const hashKey = utils.hashKey;
const Writer = @import("Writer.zig");
const StringData = @import("Pool.zig").StringData;
// const CompactStyle = @import("types.zig").CompactStyle;

const types = @import("types.zig");

const Item = struct {
    ptr: ?*UINode,
    next: ?*Item = null,
};

const Style = types.Style;
const EType = types.ElementType;
const RenderCommand = types.RenderCommand;
const ElemDecl = types.ElementDeclaration;
const Direction = types.Direction;
const HooksIds = types.HooksIds;
const InputParams = types.InputParams;

const PackedFieldPtrs = struct {
    visual_ptr: ?*const types.PackedVisual = null,
    layout_ptr: ?*const types.PackedLayout = null,
    position_ptr: ?*const types.PackedPosition = null,
    margins_paddings_ptr: ?*const types.PackedMarginsPaddings = null,
    animations_ptr: ?*const types.PackedAnimations = null,
    interactive_ptr: ?*const types.PackedInteractive = null,
};

pub var key_depth_map: std.AutoHashMap(u32, usize) = undefined;
pub var component_index_map: std.AutoHashMap(u32, usize) = undefined;
pub var ui_nodes: []UINode = undefined;
pub const UIContext = @This();
root: ?*UINode = null,
current_parent: ?*UINode = null,
stack: ?*Item = null,
root_stack_ptr: ?*Item = null,
node_pool: std.heap.MemoryPool(UINode),
memory_pool: std.heap.MemoryPool(Item),
render_cmd_memory_pool: std.heap.MemoryPool(RenderCommand),
tree_memory_pool: std.heap.MemoryPool(CommandsTree),
current_offset: f32 = 0,
ui_tree: ?*CommandsTree = null,

pub const CommandsTree = struct {
    node: *RenderCommand,
    children: std.array_list.Managed(*CommandsTree),
};

pub const BoxSizing = struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,
};

// pub var styles: std.array_list.Managed(*Style) = undefined;

pub const UINode = struct {
    dirty: bool = false,
    parent: ?*UINode = null,
    type: EType = EType.FlexBox,
    children: std.ArrayListUnmanaged(*UINode) = undefined,
    text: ?[]const u8 = null,
    uuid: []const u8 = "",
    uuid_buf: [64]u8 = undefined,
    href: ?[]const u8 = null,
    index: usize = 0,
    hooks: HooksIds = .{},
    input_params: ?*const InputParams = null,
    event_type: ?types.EventType = null,
    state_type: types.StateType = .pure,
    aria_label: ?[]const u8 = null,
    class: ?[]const u8 = null,
    animation_enter: ?*const Fabric.Animation = null,
    animation_exit: ?*const Fabric.Animation = null,
    style_hash: u32 = 0,
    props_hash: u32 = 0,
    changed_style: bool = true,
    changed_props: bool = true,
    packed_field_ptrs: ?PackedFieldPtrs = null,
    can_have_children: bool = true,

    // nodes_flat_index: usize = 0,
    // tooltip: ?types.Tooltip = null,

    pub fn deinit(ui_node: *UINode) void {
        ui_node.children.deinit();
    }

    pub fn addChild(parent: *UINode, child: *UINode) !void {
        if (parent.children.items.len >= Fabric.page_node_count) return error.BufferOverflowIncreasePageNodeCount;
        parent.children.appendBounded(child) catch {
            return error.BufferOverflowIncreasePageNodeCount;
        };
    }
};

pub fn init(ui_ctx: *UIContext, parent: ?*UINode, etype: EType) !*UINode {
    const node = try ui_ctx.node_pool.create();
    // Fabric.frame_arena.incrementNodeCount();
    node.* = .{
        .parent = parent,
        .type = etype,
    };
    if (etype != .Text and etype != .TextFmt) {
        node.children = try std.ArrayListUnmanaged(*UINode).initCapacity(Fabric.frame_arena.getFrameAllocator(), Fabric.page_node_count);
    } else {
        node.can_have_children = false;
    }

    return node;
}

/// initContext initializes the UIContext and its associated memory pools
pub fn initContext(ui_ctx: *UIContext) !void {
    const allocator = Fabric.frame_arena.getFrameAllocator();
    ui_ctx.* = .{
        .node_pool = std.heap.MemoryPool(UINode).init(allocator),
        .memory_pool = std.heap.MemoryPool(Item).init(allocator),
        .render_cmd_memory_pool = std.heap.MemoryPool(RenderCommand).init(allocator),
        .tree_memory_pool = std.heap.MemoryPool(CommandsTree).init(allocator),
    };

    // Either change the init function to return a pointer directly
    const node_ptr = try ui_ctx.init(null, EType.Block);
    node_ptr.uuid = "fabric_root_id";
    node_ptr.dirty = false;
    ui_ctx.root = node_ptr;
    const item: *Item = try ui_ctx.memory_pool.create();
    item.* = .{
        .ptr = node_ptr,
    };
    ui_ctx.root_stack_ptr = item;
    ui_ctx.stack = item;
    node_count = 0;
    if (node_count >= nodes.len) {
        Fabric.printlnErr("Page Node count is too small {d}", .{node_count});
    } else {
        nodes[node_count] = ui_ctx.root.?;
        // ui_ctx.root.?.nodes_flat_index = node_count;
        seen_nodes[node_count] = true;
    }
    node_count += 1;

    packed_position = std.mem.zeroes(types.PackedPosition);
    packed_layout = std.mem.zeroes(types.PackedLayout);
    packed_margins_paddings = std.mem.zeroes(types.PackedMarginsPaddings);
    packed_visual = std.mem.zeroes(types.PackedVisual);
    packed_animations = .{};
    packed_interactive = std.mem.zeroes(types.PackedInteractive);
}

pub fn deinit(ui_ctx: *UIContext) void {
    ui_ctx.root.?.children = undefined;
    ui_ctx.root = null;
    ui_ctx.ui_tree = null;
}

pub fn stackRegister(ui_ctx: *UIContext, ui_node: *UINode) !void {
    const item: *Item = try ui_ctx.memory_pool.create();
    const current_stack = ui_ctx.stack;
    item.* = .{
        .ptr = ui_node,
    };

    if (current_stack) |stack| {
        item.next = stack;
    }

    ui_ctx.stack = item;
}

pub fn stackPop(ui_ctx: *UIContext) void {
    const current_stack = ui_ctx.stack orelse return;
    ui_ctx.stack = current_stack.next;
}

pub var uuid_depth: usize = 0;
var current_tree: usize = 0;
fn setUUID(parent: *UINode, child: *UINode) void {
    uuid_depth += 1;
    const count = key_depth_map.get(hashKey(parent.uuid)) orelse blk: {
        break :blk 0;
    };

    const component_count = component_index_map.get(hashKey(parent.uuid)) orelse blk: {
        break :blk 0;
    };

    // Set the keyGenerator count
    KeyGenerator.setCount(count);
    KeyGenerator.setComponentCount(component_count);
    // KeyGenerator.resetCounter();
    const index: usize = uuid_depth;
    if (child.uuid.len > 0) {
        KeyGenerator.incrementComponentCount();
        // KeyGenerator.incrementCount();
        child.index = KeyGenerator.getComponentCount();
    } else {
        KeyGenerator.incrementComponentCount();
        KeyGenerator.incrementCount();
        child.uuid = KeyGenerator.generateKey(
            &child.uuid_buf,
            child.type,
            parent.uuid,
            index,
        );
        child.index = KeyGenerator.getComponentCount();
        // we add this so that animations are sepeate, we need to be careful though since
        // if a user does not specifc a id for a class, and the  rerender tree has the same id
        // and then previous one uses an animation then that transistion and animation will be
        // applied to the new parent since it has the same class name and styling
    }
    // Put the new keygenerator count in to the key_dpeht_map;
    key_depth_map.put(hashKey(parent.uuid), KeyGenerator.getCount()) catch |err| {
        Fabric.printlnSrcErr("{any}", .{err}, @src());
    };
    component_index_map.put(hashKey(parent.uuid), KeyGenerator.getComponentCount()) catch |err| {
        Fabric.printlnSrcErr("{any}", .{err}, @src());
    };
}

// Open takes a current stack and adds the elements depth first search
// Open and close get called in sequence
// depth first search
pub fn open(ui_ctx: *UIContext, elem_decl: ElemDecl) !*UINode {
    // const time = Fabric.nowMs();
    const stack = ui_ctx.stack.?;
    // Parent node
    const current_open = stack.ptr orelse unreachable;
    var node = try ui_ctx.init(current_open, elem_decl.elem_type);

    try current_open.addChild(node);
    try ui_ctx.stackRegister(node);

    const style = elem_decl.style;
    if (style != null and style.?.id != null) {
        node.uuid = style.?.id.?;
    }

    setUUID(current_open, node);

    if (node_count >= nodes.len) {
        Fabric.printlnErr("Page Node count is too small {d}", .{node_count});
    } else {
        // node.nodes_flat_index = node_count;
        nodes[node_count] = node;
        node_count += 1;
    }

    // Fabric.println("Open time {any}", .{Fabric.nowMs() - time});
    return node;
}

// This function was already DRY, no changes needed.
pub fn structToBytes(struct_ptr: anytype) u32 {
    const bytes = std.mem.asBytes(struct_ptr);
    return hashKey(bytes);
}

// -----------------------------------------------------------------------------
// NEW HELPER FUNCTIONS
// -----------------------------------------------------------------------------

/// Helper to pack a color union (`.Literal` or `.Thematic`) into a PackedColor struct.
fn packColor(source_color: types.Color, packed_color: *types.PackedColor) void {
    switch (source_color) {
        .Literal => |color| {
            packed_color.* = .{ .has_color = true, .color = color };
        },
        .Thematic => |token| {
            packed_color.* = .{ .has_token = true, .token = token };
        },
    }
}

/// Generic function to hash a packed data structure, look it up in a cache,
/// or create and cache it if it doesn't exist. Updates the style hash.
fn getOrPutAndUpdateHash(
    hash: u32,
    data: anytype,
    map: anytype,
    pool: anytype,
) !*const @TypeOf(data) {
    if (map.get(hash)) |ptr| {
        return ptr;
    }

    const new_ptr = try pool.create();
    new_ptr.* = data;
    try map.put(hash, new_ptr);

    return new_ptr;
}

// -----------------------------------------------------------------------------
// REFACTORED FUNCTIONS
// -----------------------------------------------------------------------------

pub fn checkVisual(visual: *const types.Visual, packet_visual: *types.PackedVisual) void {
    // Refactored to use the packColor helper
    if (visual.background) |background| {
        if (background.color) |color| {
            var background_color = packet_visual.background;
            packColor(color, &background_color);
            packet_visual.background = background_color;
        } else if (background.layer) |layer| {
            switch (layer) {
                .Grid => |grid| {
                    packet_visual.background_grid.size = grid.size;
                    packet_visual.background_grid.thickness = grid.thickness;
                    var grid_color = packet_visual.background_grid.packed_color;
                    packColor(grid.color, &grid_color);
                    packet_visual.background_grid.packed_color = grid_color;
                },
                .Image => {},
            }
        }
    }

    if (visual.fill) |fill| {
        var fill_color = packet_visual.fill;
        packColor(fill, &fill_color);
        packet_visual.fill = fill_color;
    }

    if (visual.stroke) |stroke| {
        var stroke_color = packet_visual.stroke;
        packColor(stroke, &stroke_color);
        packet_visual.stroke = stroke_color;
    }

    if (visual.border) |border| {
        packet_visual.border_thickness = border.thickness;
        packet_visual.has_border_thickeness = true;
        if (border.color) |color| {
            packet_visual.has_border_color = true;
            var border_color = packet_visual.border_color;
            packColor(color, &border_color);
            packet_visual.border_color = border_color;
        }
        if (border.radius) |radius| {
            packet_visual.has_border_radius = true;
            packet_visual.border_radius = radius;
        }
    }

    if (visual.font_size) |font_size| {
        packet_visual.font_size = font_size;
    }
    if (visual.font_weight) |font_weight| {
        packet_visual.font_weight = font_weight;
    }
    if (visual.text_color) |color| {
        var text_color = packet_visual.text_color;
        packColor(color, &text_color);
        packet_visual.text_color = text_color;
    }
    if (visual.opacity) |opacity| {
        packet_visual.has_opacity = true;
        packet_visual.opacity = opacity;
    }

    if (visual.shadow) |shadow| {
        packet_visual.shadow = .{
            .blur = shadow.blur,
            .spread = shadow.spread,
            .top = shadow.top,
            .left = shadow.left,
            .color = .{
                .has_color = true,
                .color = shadow.color.Literal,
            },
        };
    }

    if (visual.cursor) |cursor| {
        packet_visual.cursor = cursor;
    }

    if (visual.text_decoration) |text_decoration| {
        packet_visual.text_decoration = text_decoration;
    }

    if (visual.blur) |blur| {
        packet_visual.blur = blur;
    }
}

var packed_layout: types.PackedLayout = .{};
var packed_position: types.PackedPosition = .{};
var packed_margins_paddings: types.PackedMarginsPaddings = .{};
var packed_visual: types.PackedVisual = .{};
var packed_animations: types.PackedAnimations = .{};
var packed_interactive: types.PackedInteractive = .{};
var packed_transition: types.PackedTransition = .{};

fn setClass(current_open: *UINode, hash: u32, tag: []const u8) void {
    var allocator = Fabric.frame_arena.getFrameAllocator();
    const common = KeyGenerator.generateHashKeyAlloc(&allocator, hash, tag);
    if (current_open.class) |class| {
        current_open.class = std.fmt.allocPrint(Fabric.allocator_global, "{s} {s}", .{ class, common }) catch return;
    } else {
        current_open.class = common;
    }
}

fn buildClassString(
    field_ptrs: *const PackedFieldPtrs,
    current_open: *UINode,
    hash_l: u32,
    hash_p: u32,
    hash_m: u32,
    hash_v: u32,
    hash_a: u32,
    hash_i: u32,
) !void {
    var writer: Writer = undefined;
    var writer_buf: [512]u8 = undefined;
    writer.init(&writer_buf);

    if (current_open.class) |class| {
        writer.write(class) catch return error.CouldNotAllocate;
        writer.writeByte(' ') catch return error.CouldNotAllocate;
    }

    if (field_ptrs.layout_ptr) |_| {
        var buf: [128]u8 = undefined;
        const common = KeyGenerator.generateHashKey(&buf, hash_l, "cl");
        writer.write(common) catch return error.CouldNotAllocate;
        writer.writeByte(' ') catch return error.CouldNotAllocate;
    }

    if (field_ptrs.position_ptr) |_| {
        var buf: [128]u8 = undefined;
        const common = KeyGenerator.generateHashKey(&buf, hash_p, "cp");
        writer.write(common) catch return error.CouldNotAllocate;
        writer.writeByte(' ') catch return error.CouldNotAllocate;
    }

    if (field_ptrs.margins_paddings_ptr) |_| {
        var buf: [128]u8 = undefined;
        const common = KeyGenerator.generateHashKey(&buf, hash_m, "cmp");
        writer.write(common) catch return error.CouldNotAllocate;
        writer.writeByte(' ') catch return error.CouldNotAllocate;
    }

    if (field_ptrs.visual_ptr) |_| {
        var buf: [128]u8 = undefined;
        const common = KeyGenerator.generateHashKey(&buf, hash_v, "cv");
        writer.write(common) catch return error.CouldNotAllocate;
        writer.writeByte(' ') catch return error.CouldNotAllocate;
    }

    if (field_ptrs.animations_ptr) |_| {
        var buf: [128]u8 = undefined;
        const common = KeyGenerator.generateHashKey(&buf, hash_a, "ca");
        writer.write(common) catch return error.CouldNotAllocate;
        writer.writeByte(' ') catch return error.CouldNotAllocate;
    }

    if (field_ptrs.interactive_ptr) |_| {
        var buf: [128]u8 = undefined;
        const common = KeyGenerator.generateHashKey(&buf, hash_i, "ci");
        writer.write(common) catch return error.CouldNotAllocate;
        writer.writeByte(' ') catch return error.CouldNotAllocate;
    }

    const string_data = Fabric.pool.createString(writer.buffer[0..writer.pos]) catch return error.PoolCouldNotAllocate;
    current_open.class = string_data.asSlice();
}

// TODO: Hashing the value is slow, we need to create a better hashmap system
// running a comparison on each st.mem.bytes is expensive

pub fn configure(ui_ctx: *UIContext, elem_decl: ElemDecl) *UINode {
    // packed_position = std.mem.zeroes(types.PackedPosition);
    // packed_layout = std.mem.zeroes(types.PackedLayout);
    // packed_margins_paddings = std.mem.zeroes(types.PackedMarginsPaddings);
    // packed_visual = std.mem.zeroes(types.PackedVisual);
    // packed_animations = .{};
    // packed_interactive = std.mem.zeroes(types.PackedInteractive);
    // packed_transition = std.mem.zeroes(types.PackedTransition);

    const stack = ui_ctx.stack orelse unreachable;
    const current_open = stack.ptr orelse unreachable;
    const style = elem_decl.style;
    if (style != null and style.?.id != null) {
        current_open.uuid = style.?.id.?;
    }

    packed_position = .{};
    packed_layout = .{};
    packed_margins_paddings = .{};
    packed_visual = .{};
    packed_animations = .{};
    packed_interactive = .{};
    packed_transition = .{};

    var hash_l: u32 = 0;
    var hash_p: u32 = 0;
    var hash_mp: u32 = 0;
    var hash_v: u32 = 0;
    var hash_a: u32 = 0;
    var hash_i: u32 = 0;

    if (elem_decl.elem_type == .Svg) {
        current_open.text = elem_decl.svg;
        current_open.props_hash +%= hashKey(elem_decl.svg);
    } else if (elem_decl.elem_type == .Input) {
        current_open.input_params = elem_decl.input_params.?;
        current_open.text = elem_decl.text orelse "";
        current_open.props_hash +%= hashKey(current_open.text.?);
    } else if (elem_decl.text) |text| {
        current_open.text = text;
        current_open.props_hash +%= hashKey(text);
    }

    current_open.href = elem_decl.href;
    current_open.type = elem_decl.elem_type;

    if (current_open.href) |href| {
        current_open.props_hash +%= hashKey(href);
    }

    if (style) |s| {
        current_open.packed_field_ptrs = PackedFieldPtrs{};
        var hash_id: bool = false;
        if (s.style_id != null) {
            hash_id = true;
            current_open.class = s.style_id.?;
        }

        // ** Packed Layout **
        if (s.layout != null or s.size != null or s.child_gap != null) {
            // packed_layout = .{};
            if (s.layout) |layout| {
                if (current_open.text != null) {
                    packed_layout.text_align = layout;
                } else {
                    packed_layout.flex = .flex;
                    packed_layout.layout = layout;
                }
            } else if (current_open.type == .FlexBox) {
                packed_layout.flex = .flex;
            }
            if (s.size) |size| packed_layout.size = size;
            if (s.child_gap) |child_gap| packed_layout.child_gap = child_gap;
            packed_layout.direction = s.direction;
            if (s.flex_wrap) |flex_wrap| packed_layout.flex_wrap = flex_wrap;
            if (s.scroll) |scroll| packed_layout.scroll = scroll;

            hash_l = hashKey(std.mem.asBytes(&packed_layout));

            if (!hash_id) {
                // setClass(current_open, hash, "c-l");
                current_open.packed_field_ptrs.?.layout_ptr = getOrPutAndUpdateHash(
                    hash_l,
                    packed_layout,
                    &Fabric.packed_layouts,
                    &Fabric.packed_layouts_pool,
                ) catch unreachable;
            } else {
                const packed_layout_ptr = Fabric.packed_layouts_pool.create() catch unreachable;
                packed_layout_ptr.* = packed_layout;
                current_open.packed_field_ptrs.?.layout_ptr = packed_layout_ptr;
            }
        }

        // ** Packed Position **
        if (s.position != null or s.z_index != null) {
            // packed_position = .{};
            if (s.position) |position| {
                packed_position.position_type = position.type;
                if (position.top) |top| packed_position.top = .{ .type = top.type, .value = top.value };
                if (position.right) |right| packed_position.right = .{ .type = right.type, .value = right.value };
                if (position.bottom) |bottom| packed_position.bottom = .{ .type = bottom.type, .value = bottom.value };
                if (position.left) |left| packed_position.left = .{ .type = left.type, .value = left.value };
            }
            if (s.z_index) |z_index| packed_position.z_index = z_index;

            hash_p = hashKey(std.mem.asBytes(&packed_position));

            if (!hash_id) {
                // setClass(current_open, hash, "c-p");
                current_open.packed_field_ptrs.?.position_ptr = getOrPutAndUpdateHash(
                    hash_p,
                    packed_position,
                    &Fabric.packed_positions,
                    &Fabric.packed_positions_pool,
                ) catch unreachable;
            } else {
                const packed_position_ptr = Fabric.packed_positions_pool.create() catch unreachable;
                packed_position_ptr.* = packed_position;
                current_open.packed_field_ptrs.?.position_ptr = packed_position_ptr;
            }
        }

        // ** Packed Margins and Paddings **
        if (s.padding != null or s.margin != null) {
            // packed_margins_paddings = .{};
            if (s.padding) |padding| packed_margins_paddings.padding = padding;
            if (s.margin) |margin| packed_margins_paddings.margin = margin;

            hash_mp = hashKey(std.mem.asBytes(&packed_margins_paddings));
            if (!hash_id) {
                // setClass(current_open, hash, "c-mp");
                current_open.packed_field_ptrs.?.margins_paddings_ptr = getOrPutAndUpdateHash(
                    hash_mp,
                    packed_margins_paddings,
                    &Fabric.packed_margins_paddings,
                    &Fabric.packed_margins_paddings_pool,
                ) catch unreachable;
            } else {
                const packed_margin_paddings_ptr = Fabric.packed_margins_paddings_pool.create() catch unreachable;
                packed_margin_paddings_ptr.* = packed_margins_paddings;
                current_open.packed_field_ptrs.?.margins_paddings_ptr = packed_margin_paddings_ptr;
            }
        }

        // ** Packed Visual **
        if (s.visual != null) {
            // packed_visual = .{};
            if (s.font_family) |font_family| {
                hash_v +%= hashKey(font_family);
            }
            if (s.visual) |visual| checkVisual(&visual, &packed_visual);
            if (s.white_space) |white_space| {
                packed_visual.has_white_space = true;
                packed_visual.white_space = white_space;
            }
            if (s.list_style) |list_style| packed_visual.list_style = list_style;
            if (s.outline) |outline| packed_visual.outline = outline;
            if (current_open.type == .Button or current_open.type == .ButtonCycle or current_open.type == .CtxButton) {
                if (!packed_visual.has_border_thickeness) {
                    packed_visual.has_border_thickeness = true;
                    packed_visual.border_thickness = .all(0);
                }
            }

            if (s.transition) |transition| {
                packed_visual.has_transitions = true;
                packed_transition.delay = transition.delay;
                packed_transition.duration = transition.duration;
                packed_transition.timing = transition.timing;
                packed_transition.properties_len = transition.properties.len;
                packed_transition.properties_ptr = null;
                packed_visual.transitions = packed_transition;
                for (transition.properties) |property| {
                    hash_v +%= hashKey(@tagName(property));
                }
            }

            hash_v = hashKey(std.mem.asBytes(&packed_visual));

            if (s.transition) |transition| {
                packed_transition.set(&transition);
                packed_visual.transitions = packed_transition;
            }
            if (s.font_family) |font_family| {
                const ff_slice = Fabric.frame_arena.getFrameAllocator().dupe(u8, font_family) catch |err| {
                    Fabric.printlnErr("Could not allocate font family {any}\n", .{err});
                    unreachable;
                };
                packed_visual.font_family_ptr = ff_slice.ptr;
                packed_visual.font_family_len = ff_slice.len;
            }

            if (!hash_id) {
                // setClass(current_open, hash, "c-v");
                current_open.packed_field_ptrs.?.visual_ptr = getOrPutAndUpdateHash(
                    hash_v,
                    packed_visual,
                    &Fabric.packed_visuals,
                    &Fabric.packed_visuals_pool,
                ) catch unreachable;
            } else {
                const packed_visual_ptr = Fabric.packed_visuals_pool.create() catch unreachable;
                packed_visual_ptr.* = packed_visual;
                current_open.packed_field_ptrs.?.visual_ptr = packed_visual_ptr;
            }
        }

        // ** Packed Animations and Interactive **
        if (s.transition != null or s.interactive != null) {
            // packed_animations = .{};
            if (s.interactive) |interactive| {
                packed_interactive = .{};
                if (interactive.hover) |hover| {
                    if (hover.transform) |transform| {
                        packed_animations.has_transform = true;
                        packed_animations.transform.size_type = transform.size_type;
                        packed_animations.transform.scale_size = transform.scale_size;
                        packed_animations.transform.trans_x = transform.trans_x;
                        packed_animations.transform.trans_y = transform.trans_y;
                        packed_animations.transform.deg = transform.deg;
                        packed_animations.transform.x = transform.x;
                        packed_animations.transform.y = transform.y;
                        packed_animations.transform.z = transform.z;
                        packed_animations.transform.opacity = transform.opacity;
                        packed_animations.transform.type_ptr = null;
                        packed_animations.transform.type_len = transform.type.len;

                        // var packed_transform: types.PackedTransform = undefined;
                        // packed_transform.set(&transform);
                        // packed_animations.transform = packed_transform;
                        for (transform.type) |property| {
                            hash_i +%= hashKey(@tagName(property));
                        }
                    }
                    var packed_hover: types.PackedVisual = .{};
                    checkVisual(&hover, &packed_hover);
                    packed_interactive.has_hover = true;
                    packed_interactive.hover = packed_hover;
                }
                if (interactive.focus) |focus| {
                    var packed_focus: types.PackedVisual = .{};
                    checkVisual(&focus, &packed_focus);
                    packed_interactive.has_focus = true;
                    packed_interactive.focus = packed_focus;
                }

                hash_i = hashKey(std.mem.asBytes(&packed_interactive));

                if (!hash_id) {
                    // setClass(current_open, hash, "c-h");
                    current_open.packed_field_ptrs.?.interactive_ptr = getOrPutAndUpdateHash(
                        hash_i,
                        packed_interactive,
                        &Fabric.packed_interactives,
                        &Fabric.packed_interactives_pool,
                    ) catch unreachable;
                }
            }

            hash_a = hashKey(std.mem.asBytes(&packed_animations));

            if (s.interactive) |interactive| {
                if (interactive.hover) |hover| {
                    if (hover.transform) |transform| {
                        var packed_transform: types.PackedTransform = undefined;
                        packed_transform.set(&transform);
                        packed_animations.transform = packed_transform;
                    }
                }
            }

            if (!hash_id) {
                // setClass(current_open, hash, "c-a");
                if (packed_animations.has_transform) {
                    current_open.packed_field_ptrs.?.animations_ptr = getOrPutAndUpdateHash(
                        hash_a,
                        packed_animations,
                        &Fabric.packed_animations,
                        &Fabric.packed_animations_pool,
                    ) catch unreachable;
                }
            }
        }

        current_open.style_hash +%= hash_l;
        current_open.style_hash +%= hash_p;
        current_open.style_hash +%= hash_mp;
        current_open.style_hash +%= hash_v;
        current_open.style_hash +%= hash_a;
        current_open.style_hash +%= hash_i;
        if (s.style_id != null) {
            Fabric.generator.writeNodeStyle(current_open);
        } else {
            // const class = std.fmt.allocPrint(Fabric.frame_arena.getFrameAllocator(), "{s}", .{elem_decl.href.?}) catch "";
            if (current_open.type == .Icon) {
                current_open.class = elem_decl.href.?;
            }
            buildClassString(
                &current_open.packed_field_ptrs.?,
                current_open,
                hash_l,
                hash_p,
                hash_mp,
                hash_v,
                hash_a,
                hash_i,
            ) catch |err| {
                Fabric.printlnErr("Could not build class string {any}\n", .{err});
            };
        }
    }

    if (current_open.type == .Hooks or current_open.type == .HooksCtx) {
        current_open.hooks = elem_decl.hooks;
    }

    if (elem_decl.animation_enter) |animation_enter| {
        current_open.animation_enter = animation_enter;
    }
    if (elem_decl.animation_exit) |animation_exit| {
        current_open.animation_exit = animation_exit;
    }

    current_open.state_type = elem_decl.state_type;
    current_open.aria_label = elem_decl.aria_label;

    return current_open;
}

// close is breadth post order first
pub fn close(ui_ctx: *UIContext) void {
    // const time = Fabric.nowMs();
    if (uuid_depth > 0) {
        uuid_depth -= 1;
    } else {
        Fabric.printlnSrcErr("Depth is negative {}", .{uuid_depth}, @src());
    }
    ui_ctx.stackPop();
    // Fabric.println("Close time {any}", .{Fabric.nowMs() - time});
}

pub fn endContext(ui_ctx: *UIContext) void {
    const root = ui_ctx.root.?;
    const render_cmd: *RenderCommand = ui_ctx.render_cmd_memory_pool.create() catch unreachable;
    Fabric.frame_arena.incrementCommandCount();
    render_cmd.* = .{
        .elem_type = root.type,
        .href = "",
        // .style = root.style,
        .hooks = root.hooks,
        .node_ptr = root,
        .id = root.uuid,
        .index = 0,
    };
    root.dirty = false;

    const tree: *CommandsTree = ui_ctx.tree_memory_pool.create() catch unreachable;
    tree.* = .{
        .node = render_cmd,
        .children = std.array_list.Managed(*CommandsTree).init(Fabric.frame_arena.getFrameAllocator()),
    };
    ui_ctx.ui_tree = tree;
}

pub fn createStack(ui_ctx: *UIContext, parent: *UINode) void {
    if (parent.children.items.len == 0) return;

    for (parent.children.items) |child| {
        ui_ctx.stackRegister(child) catch {
            Fabric.println("Could not stack register\n", .{});
            unreachable;
        };
    }
    var i = parent.children.items.len - 1;
    while (true) {
        const child = parent.children.items[i];
        if (i == 0) {
            ui_ctx.createStack(child);
            break;
        } else {
            ui_ctx.createStack(child);
        }
        i -= 1;
    }
}

// Breadth first search
// This calcualtes the positions;
var depth: usize = 0;
pub fn traverseChildren(ui_ctx: *UIContext, parent_op: ?*UINode, ui_tree_parent: *CommandsTree) void {
    if (parent_op) |parent| {
        if (!parent.can_have_children) return;
        if (parent.children.items.len > 0) {
            ui_tree_parent.children = std.array_list.Managed(*CommandsTree).init(Fabric.frame_arena.getFrameAllocator());
            depth += 1;
            for (parent.children.items) |child| {
                const render_cmd: *RenderCommand = ui_ctx.render_cmd_memory_pool.create() catch unreachable;
                Fabric.frame_arena.incrementCommandCount();
                render_cmd.* = .{
                    .elem_type = child.type,
                    .text = child.text orelse "",
                    .href = child.href orelse "",
                    .id = child.uuid,
                    .index = child.index,
                    .hooks = child.hooks,
                    .node_ptr = child,
                    .render_type = child.state_type,
                    .changed_style = child.changed_style,
                    .changed_props = child.changed_props,
                    // .tooltip = child.tooltip,
                };

                if (child.packed_field_ptrs) |ptrs| {
                    if (ptrs.interactive_ptr) |interactive| {
                        render_cmd.hover = interactive.has_hover;
                        render_cmd.focus = interactive.has_focus;
                        render_cmd.focus_within = interactive.has_focus_within;
                    }
                    if (child.class) |id| {
                        render_cmd.class = id;
                    }
                }
                const tree: *CommandsTree = ui_ctx.tree_memory_pool.create() catch unreachable;
                tree.* = .{
                    .node = render_cmd,
                    .children = std.array_list.Managed(*CommandsTree).init(Fabric.frame_arena.getFrameAllocator()),
                };
                ui_tree_parent.children.append(tree) catch unreachable;
                // if (child.state_type == .animation) {
                //     const class_name = child.style.?.child_styles.?[0].style_id;
                //     Fabric.addToClassesList(child.uuid, class_name);
                // }
            }
            for (parent.children.items, 0..) |child, j| {
                ui_ctx.traverseChildren(child, ui_tree_parent.children.items[j]);
            }
            depth -= 1;
        }
    }
}
pub fn traverse(ui_ctx: *UIContext) void {
    ui_ctx.traverseChildren(ui_ctx.root, ui_ctx.ui_tree.?);
}

pub var nodes: []*UINode = undefined;
var node_count: usize = 0;
var seen_count: usize = 0;

pub var common_nodes: []usize = undefined;
pub var common_size_nodes: []usize = undefined;
pub var common_visual_nodes: []usize = undefined;

pub var seen_nodes: []bool = undefined;

pub var common_uuids: [][]const u8 = undefined;
pub var common_size_uuids: [][]const u8 = undefined;
pub var common_visual_uuids: [][]const u8 = undefined;

var common_count: usize = 0;
var common_size_count: usize = 0;
var common_visual_count: usize = 0;

pub var target_node_index: usize = 0;
pub var base_styles: []Style = undefined;
pub var base_style_count: usize = 0;
var common_size_style: ?Style = null;
var common_visual_style: ?Style = null;

// pub fn reconcileStyles() void {
//     var layout_itr = Fabric.packed_layouts.iterator();
//     var allocator = Fabric.frame_arena.getFrameAllocator();
//     while (layout_itr.next()) |entry| {
//         const hash = entry.key_ptr.*;
//         const buf = allocator.alloc(u8, 128) catch unreachable;
//         const common = KeyGenerator.generateCommonHashKey(buf, hash, "c-l");
//         const packed_layout = entry.value_ptr.*;
//         for (packed_layout.nodes.items) |node| {
//             if (node.class) |class| {
//                 node.class = std.fmt.allocPrint(allocator, "{s} {s}", .{ class, common }) catch return;
//             } else {
//                 node.class = common;
//             }
//         }
//     }
//     // Make sure seen_nodes is initialized to all false
//     // @memset(seen_nodes, false);
//     //
//     // var i: usize = 0;
//     // while (i < node_count) : (i += 1) {
//     //     // 1. Skip if already processed or has no style
//     //     if (seen_nodes[i]) continue;
//     //     const target_node = nodes[i];
//     //     _ = target_node.compact_style orelse continue;
//     //
//     //     // 2. This is a new potential target, start a new common group
//     //     common_count = 0;
//     //     common_nodes[common_count] = i;
//     //     common_uuids[common_count] = target_node.uuid;
//     //     common_count += 1;
//     //     // Mark self as seen, though it's implicitly handled by the outer loop
//     //     seen_nodes[i] = true;
//     //
//     //     // 3. Find all other matching nodes
//     //     var j: usize = i + 1;
//     //     while (j < node_count) : (j += 1) {
//     //         if (seen_nodes[j]) continue;
//     //         const other_node = nodes[j];
//     //         _ = other_node.compact_style orelse continue;
//     //
//     //         // Your existing style comparison logic is good, just adapt it
//     //         // if (stylesAreTheSame(target_style, other_style)) {
//     //         //     common_nodes[common_count] = j;
//     //         //     common_uuids[common_count] = other_node.uuid;
//     //         //     common_count += 1;
//     //         //     seen_nodes[j] = true; // Mark the duplicate as handled
//     //         // }
//     //     }
//     //
//     //     // 4. If we found at least one duplicate, apply the common class
//     //     if (common_count > 1) {
//     //         const common_key = KeyGenerator.generateCommonStyleKey(common_uuids[0..common_count], &Fabric.allocator_global);
//     //         for (common_nodes[0..common_count]) |node_index| {
//     //             const c_node = nodes[node_index];
//     //             if (c_node.class) |class| {
//     //                 c_node.class = std.fmt.allocPrint(Fabric.allocator_global, "{s} {s}", .{ class, common_key }) catch return;
//     //             } else {
//     //                 c_node.class = common_key;
//     //             }
//     //         }
//     //     }
//     // }
// }

// Helper function to contain your comparison logic
// fn stylesAreTheSame(style_a: *CompactStyle, style_b: *CompactStyle) bool {
//     var same_basic: bool = false;
//     if (style_a.basic != null and style_b.basic != null) {
//         // same_basic = std.meta.eql(style_a.basic.?.*, style_b.basic.?.*);
//     } else if (style_a.basic == null and style_b.basic == null) {
//         same_basic = true;
//     }
//
//     var same_visual: bool = false;
//     if (style_a.visual != null and style_b.visual != null) {
//         same_visual = std.meta.eql(style_a.visual.?.*, style_b.visual.?.*);
//     } else if (style_a.visual == null and style_b.visual == null) {
//         same_visual = true;
//     }
//
//     var same_interactive: bool = false;
//     if (style_a.interactive != null and style_b.interactive != null) {
//         same_interactive = std.meta.eql(style_a.interactive.?.*, style_b.interactive.?.*);
//     } else if (style_a.interactive == null and style_b.interactive == null) {
//         same_interactive = true;
//     }
//
//     return same_basic and same_visual and same_interactive;
// }

pub fn deduplicateStyles(target_node: *UINode) void {
    common_count = 0;
    common_nodes[common_count] = target_node_index;
    common_uuids[common_count] = target_node.uuid;
    // Set the target node as seen
    seen_nodes[target_node_index] = true;
    common_count += 1;
    // if no style then return
    if (target_node.compact_style == null) return;
    const target_style = target_node.compact_style orelse return;
    // if the style id is set then we dont want to gen a common style
    if (target_node.class != null) return;
    // Fabric.println("-----------------------------Target :{s} ============", .{target_node.uuid});

    for (nodes[0..node_count], 0..) |node, i| {
        if (seen_nodes[i]) continue;
        if (std.mem.eql(u8, node.uuid, target_node.uuid)) continue;
        const node_style = node.compact_style orelse continue;

        var same_basic: bool = false;
        var same_visual: bool = false;
        var same_interactive: bool = false;
        if (node_style.basic != null and target_style.basic != null) {
            same_basic = std.meta.eql(target_style.basic.?.*, node_style.basic.?.*);
        } else if (node_style.basic == null and target_style.basic == null) {
            same_basic = true;
        }

        if (node_style.visual != null and target_style.visual != null) {
            same_visual = std.meta.eql(target_style.visual.?.*, node_style.visual.?.*);
        } else if (node_style.visual == null and target_style.visual == null) {
            same_visual = true;
        }

        if (node_style.interactive != null and target_style.interactive != null) {
            same_interactive = std.meta.eql(target_style.interactive.?.*, node_style.interactive.?.*);
        } else if (node_style.interactive == null and target_style.interactive == null) {
            same_interactive = true;
        }

        // We first check if the whole style is the same
        if (same_basic and same_visual and same_interactive) {
            Fabric.println("Same Style {s} {s} {any}", .{ target_node.uuid, node.uuid, same_interactive });
            common_nodes[common_count] = i;
            common_uuids[common_count] = node.uuid;
            common_count += 1;
            seen_nodes[i] = true;
            continue;
        }
    }
}

pub fn reconcileSizes(node: *UINode) void {
    if (node.style != null) {
        // We only incrment the target node index if the node has a style
        deduplicateSizes(node);
        if (common_count > 1) {
            const common = KeyGenerator.generateStyleKey("size", common_uuids[0..common_count], &Fabric.allocator_global);
            // base_styles[base_style_count] = Style{};
            // base_styles[base_style_count].visual = node.style.?.visual.?;
            // base_styles[base_style_count].style_id = common;
            // base_style_count += 1;
            for (common_nodes[0..common_count]) |node_index| {
                const c_node = nodes[node_index];
                if (c_node.class) |class| {
                    c_node.class = std.fmt.allocPrint(Fabric.allocator_global, "{s} {s}", .{ class, common }) catch return;
                } else {
                    c_node.class = std.fmt.allocPrint(Fabric.allocator_global, "{s} {s}", .{ c_node.uuid, common }) catch return;
                }
                c_node.style.?.style_id = c_node.class;
            }
        }
        target_node_index += 1;
    }
    for (node.children.items) |child| {
        reconcileSizes(child);
    }
}

pub fn deduplicateSizes(target_node: *UINode) void {
    common_count = 0;
    common_nodes[common_count] = target_node_index;
    common_uuids[common_count] = target_node.uuid;
    // Set the target node as seen
    seen_nodes[target_node_index] = true;
    common_count += 1;
    // if no style then return
    if (target_node.style == null) return;
    const target_style = target_node.style orelse return;
    const style_id = target_style.style_id orelse return;
    if (indexOf(style_id, "size")) |_| return;
    for (nodes[0..node_count], 0..) |node, i| {
        if (seen_nodes[i]) continue;

        const node_style = node.style orelse continue;
        const node_size = node_style.size orelse continue;
        const target_size = target_style.size orelse continue;
        if (std.meta.eql(target_size, node_size)) {
            common_nodes[common_count] = i;
            common_uuids[common_count] = node.uuid;
            common_count += 1;
            seen_nodes[i] = true;
        }
    }
}

pub fn reconcileVisuals(node: *UINode) void {
    if (node.style != null) {
        // We only incrment the target node index if the node has a style
        deduplicateVisuals(node);
        if (common_count > 1) {
            const common = KeyGenerator.generateStyleKey("visual", common_uuids[0..common_count], &Fabric.allocator_global);
            // base_styles[base_style_count] = Style{};
            // base_styles[base_style_count].visual = node.style.?.visual.?;
            // base_styles[base_style_count].style_id = std.fmt.allocPrint(Fabric.allocator_global, "{s}", .{common}) catch return;
            // base_style_count += 1;
            for (common_nodes[0..common_count]) |node_index| {
                const c_node = nodes[node_index];
                if (c_node.class) |class| {
                    c_node.class = std.fmt.allocPrint(Fabric.allocator_global, "{s} {s}", .{ class, common }) catch return;
                } else {
                    c_node.class = std.fmt.allocPrint(Fabric.allocator_global, "{s} {s}", .{ c_node.uuid, common }) catch return;
                }
                c_node.style.?.style_id = c_node.class;
                // c_node.style.?.visual = null;
            }
        }
        target_node_index += 1;
    }
    for (node.children.items) |child| {
        reconcileVisuals(child);
    }
}

pub fn deduplicateVisuals(target_node: *UINode) void {
    common_count = 0;
    common_nodes[common_count] = target_node_index;
    common_uuids[common_count] = target_node.uuid;
    // Set the target node as seen
    seen_nodes[target_node_index] = true;
    common_count += 1;
    // if no style then return
    if (target_node.style == null) return;
    const target_style = target_node.style orelse return;
    // If the style id is not set then it doesnt have anything in common
    const style_id = target_style.style_id orelse return;
    // If it does have something in common then return
    if (indexOf(style_id, "visual")) |_| return;
    for (nodes[0..node_count], 0..) |node, i| {
        if (seen_nodes[i]) continue;

        const node_style = node.style orelse continue;
        const node_visual = node_style.visual orelse continue;
        const target_visual = target_style.visual orelse continue;
        if (std.meta.eql(target_visual, node_visual)) {
            common_nodes[common_count] = i;
            common_uuids[common_count] = node.uuid;
            common_count += 1;
            seen_nodes[i] = true;
            // node.style.?.visual = null;
        }
    }
}

/// Finds the first index of a `needle` within a `haystack` using SIMD acceleration.
/// Returns the starting byte index of the `needle` if found, otherwise `null`.
pub fn indexOf(haystack: []const u8, needle: []const u8) ?usize {
    // Basic edge cases
    if (needle.len == 0) return 0;
    if (haystack.len < needle.len) return null;

    const first_char = needle[0];
    const last_possible_start = haystack.len - needle.len;

    // SIMD setup for 16-byte vectors (128-bit)
    const vec_len = 16;
    const Vec16 = @Vector(vec_len, u8);

    // Create a vector where every element is the first character of the needle.
    // This will be used to compare against 16 bytes of the haystack at once.
    const first_char_vec: Vec16 = @splat(first_char);

    var i: usize = 0;

    // Main SIMD loop. It processes the haystack in 16-byte chunks.
    // The loop condition ensures we don't read past the end of the haystack.
    while (i + vec_len <= haystack.len) : (i += vec_len) {
        // Load a 16-byte chunk from the haystack into a vector.
        const chunk = haystack[i..][0..vec_len].*;
        const haystack_vec: Vec16 = @bitCast(chunk);

        // Perform 16 parallel comparisons. The result is a mask vector.
        const eq_mask = haystack_vec == first_char_vec;

        // Convert the mask vector into a single u16 integer. Each bit in this
        // integer corresponds to a match for the first character in the chunk.
        var bits: u16 = @bitCast(eq_mask);

        // If bits is 0, no potential matches were found in this chunk, so we continue.
        if (bits == 0) continue;

        // If there are potential matches, iterate through each of them.
        while (bits != 0) {
            // `@ctz` (count trailing zeros) finds the index of the first match in our 16-byte chunk.
            const offset = @ctz(bits);
            const potential_idx = i + offset;

            // Ensure the potential match is not too close to the end of the haystack
            // for the full needle to fit.
            if (potential_idx > last_possible_start) {
                // Since offsets are processed in increasing order, no further
                // matches in this chunk can be valid.
                break;
            }

            // Now, verify if the full substring matches at this position.
            if (std.mem.eql(u8, haystack[potential_idx..][0..needle.len], needle)) {
                // We found it!
                return potential_idx;
            }

            // Clear the bit we just checked so we can find the next one.
            // This is a common trick to iterate over set bits.
            bits &= (bits - 1);
        }
    }

    // Scalar fallback loop for the remaining part of the haystack that didn't
    // fit into a full 16-byte chunk.
    while (i <= last_possible_start) : (i += 1) {
        // A simple check is sufficient here.
        if (haystack[i] == first_char and std.mem.eql(u8, haystack[i..][0..needle.len], needle)) {
            return i;
        }
    }

    return null;
}
