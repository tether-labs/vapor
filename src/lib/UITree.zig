const std = @import("std");
const Fabric = @import("Fabric.zig");
const println = std.debug.print;
const KeyGenerator = @import("Key.zig").KeyGenerator;

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

pub var key_depth_map: std.StringHashMap(usize) = undefined;
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

pub const UINode = struct {
    dirty: bool = false,
    parent: ?*UINode = null,
    type: EType = EType.FlexBox,
    style: ?Style = null,
    children: std.array_list.Managed(*UINode),
    text: []const u8 = "",
    uuid: []const u8 = "",
    href: []const u8 = "",
    index: usize = 0,
    hooks: HooksIds = .{},
    input_params: ?*const InputParams = null,
    event_type: ?types.EventType = null,
    dynamic: types.StateType = .pure,
    aria_label: ?[]const u8 = null,
    class: ?[]const u8 = null,
    udata: ?*anyopaque = null,
    box_sizing: ?BoxSizing = null,

    pub fn deinit(ui_node: *UINode) void {
        ui_node.children.deinit();
    }

    pub fn addChild(parent: *UINode, child: *UINode) !void {
        parent.children.append(child) catch {
            return error.ChildArrayOutOfMemory;
        };
    }
};

pub fn init(ui_ctx: *UIContext, parent: ?*UINode, etype: EType) !*UINode {
    const node = try ui_ctx.node_pool.create();
    Fabric.frame_arena.incrementNodeCount();
    node.* = .{
        .parent = parent,
        .type = etype,
        .children = std.array_list.Managed(*UINode).init(Fabric.frame_arena.getFrameAllocator()),
    };
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
    ui_ctx.root.?.box_sizing = .{
        .width = Fabric.browser_width,
        .height = Fabric.browser_height,
    };
    const item: *Item = try ui_ctx.memory_pool.create();
    item.* = .{
        .ptr = node_ptr,
    };
    ui_ctx.root_stack_ptr = item;
    ui_ctx.stack = item;
    node_count = 0;
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

var uuid_depth: usize = 0;
var current_tree: usize = 0;
fn setUUID(parent: *UINode, child: *UINode) void {
    uuid_depth += 1;
    const count = key_depth_map.get(parent.uuid) orelse blk: {
        break :blk 0;
    };

    // Set the keyGenerator count
    KeyGenerator.setCount(count);
    // KeyGenerator.resetCounter();
    const index: usize = uuid_depth;
    if (child.uuid.len > 0) {
        child.index = KeyGenerator.getCount();
        KeyGenerator.incrementCount();
    } else {
        const key = KeyGenerator.generateKey(
            child.type,
            parent.uuid,
            parent.style,
            index,
            parent,
            &Fabric.allocator_global,
        );

        child.uuid = key;
        child.index = KeyGenerator.getCount();
        // Fabric.println("{s}", .{child.uuid});
        // we add this so that animations are sepeate, we need to be careful though since
        // if a user does not specifc a id for a class, and the  rerender tree has the same id
        // and then previous one uses an animation then that transistion and animation will be
        // applied to the new parent since it has the same class name and styling
    }
    // Put the new keygenerator count in to the key_dpeht_map;
    key_depth_map.put(parent.uuid, KeyGenerator.getCount()) catch |err| {
        Fabric.printlnSrcErr("{any}", .{err}, @src());
    };
}

// Open takes a current stack and adds the elements depth first search
// Open and close get called in sequence
// depth first search
// open pluse close create a depth first search algo
// and breadth first post order
pub fn open(ui_ctx: *UIContext, elem_decl: ElemDecl) !*UINode {
    const stack = ui_ctx.stack.?;
    // Parent node
    const current_open = stack.ptr orelse unreachable;
    const node = try ui_ctx.init(current_open, elem_decl.elem_type);

    node.dynamic = elem_decl.dynamic;

    try current_open.addChild(node);
    try ui_ctx.stackRegister(node);

    // if (elem_decl.style) |style| {
    //     node.class = style.style_id;
    //     node.uuid = style.id orelse "";
    // } else {
    // node.uuid = "";
    // }

    setUUID(current_open, node);
    return node;
}

pub fn configure(ui_ctx: *UIContext, elem_decl: ElemDecl) *UINode {
    const stack = ui_ctx.stack orelse unreachable;
    const current_open = stack.ptr orelse unreachable;
    const style = elem_decl.style;

    if (style != null and style.?.id != null) {
        current_open.uuid = style.?.id.?;
    }

    if (elem_decl.elem_type == .Svg) {
        current_open.text = elem_decl.svg;
    } else if (elem_decl.elem_type == .Input) {
        current_open.input_params = elem_decl.input_params.?;
        current_open.text = elem_decl.text;
    } else if (elem_decl.text.len > 0) {
        current_open.text = elem_decl.text;
    }

    current_open.href = elem_decl.href;
    current_open.type = elem_decl.elem_type;

    if (style) |s| {
        current_open.class = s.style_id;
        current_open.style = s.*;
        if (s.size) |size| {
            current_open.box_sizing = .{
                .x = size.width.size.minmax.min,
                .y = size.height.size.minmax.min,
                .width = size.width.size.minmax.max,
                .height = size.height.size.minmax.max,
            };
        }
        if (node_count >= nodes.len) {
            Fabric.printlnErr("Page Node count is too small {d}", .{node_count});
        } else {
            nodes[node_count] = current_open;
        }
        node_count += 1;
    }

    if (current_open.type == .Hooks or current_open.type == .HooksCtx) {
        current_open.hooks = elem_decl.hooks;
    }
    current_open.dynamic = elem_decl.dynamic;
    current_open.aria_label = elem_decl.aria_label;

    return current_open;
}

// close is breadth post order first
pub fn close(ui_ctx: *UIContext) void {
    if (uuid_depth > 0) {
        uuid_depth -= 1;
    } else {
        Fabric.printlnSrcErr("Depth is negative {}", .{uuid_depth}, @src());
    }
    ui_ctx.stackPop();
}

pub fn endContext(ui_ctx: *UIContext) void {
    const root = ui_ctx.root.?;
    const render_cmd: *RenderCommand = ui_ctx.render_cmd_memory_pool.create() catch unreachable;
    Fabric.frame_arena.incrementCommandCount();
    render_cmd.* = .{
        .elem_type = root.type,
        .href = "",
        .style = root.style,
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
            println("Could not stack register\n", .{});
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
        if (parent.children.items.len > 0) {
            ui_tree_parent.children = std.array_list.Managed(*CommandsTree).init(Fabric.frame_arena.getFrameAllocator());
            depth += 1;
            for (parent.children.items) |child| {
                const render_cmd: *RenderCommand = ui_ctx.render_cmd_memory_pool.create() catch unreachable;
                Fabric.frame_arena.incrementCommandCount();
                render_cmd.* = .{
                    .elem_type = child.type,
                    .text = child.text,
                    .href = child.href,
                    .style = child.style,
                    .id = child.uuid,
                    .index = child.index,
                    .hooks = child.hooks,
                    .node_ptr = child,
                    .render_type = child.dynamic,
                };

                if (child.style) |style| {
                    if (style.interactive) |interactive| {
                        if (interactive.hover) |_| {
                            render_cmd.hover = true;
                        }
                        if (interactive.focus) |_| {
                            render_cmd.focus = true;
                        }
                        if (interactive.focus_within) |_| {
                            render_cmd.focus_within = true;
                        }
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
                if (child.dynamic == .animation) {
                    const class_name = child.style.?.child_styles.?[0].style_id;
                    Fabric.addToClassesList(child.uuid, class_name);
                }
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
var target_uuid: []const u8 = "";
var node_count: usize = 0;
var seen_count: usize = 0;

pub var common_nodes: []usize = undefined;
pub var common_size_nodes: []usize = undefined;
pub var seen_nodes: []bool = undefined;

pub var common_uuids: [][]const u8 = undefined;
pub var common_size_uuids: [][]const u8 = undefined;

var common_count: usize = 0;
var common_size_count: usize = 0;

var target_node_index: usize = 0;
pub var base_styles: []Style = undefined;
pub var base_style_count: usize = 0;
var common_size_style: ?Style = null;

pub fn reconcileStyles(_: *UINode) void {
    // deduplicateStyles(node);
    // seen_nodes[seen_count] = true;
    // seen_count += 1;
    // target_node_index += 1;
    // if (common_size_style) |size_style| {
    //     const common = KeyGenerator.generateCommonStyleKey(common_size_uuids[0..common_size_count], &Fabric.allocator_global);
    //     base_styles[base_style_count] = Style{ .style_id = common, .size = size_style.size };
    //     base_style_count += 1;
    //     for (common_size_nodes[0..common_size_count]) |index| {
    //         const c_node = nodes[index - 1];
    //         c_node.style.?.size = null;
    //         c_node.class = std.fmt.allocPrint(Fabric.allocator_global, "{s} {s}", .{ c_node.uuid, common }) catch return;
    //     }
    // }
    //
    // if (common_count > 1) {
    //     const common = KeyGenerator.generateCommonStyleKey(common_uuids[0..common_count], &Fabric.allocator_global);
    //     for (common_nodes[0..common_count]) |index| {
    //         const c_node = nodes[index - 1];
    //         c_node.class = common;
    //     }
    // }
    //
    // for (node.children.items) |child| {
    //     reconcileStyles(child);
    // }
}
pub fn deduplicateStyles(target_node: *UINode) void {
    common_size_style = null;
    common_count = 0;
    common_size_count = 0;

    common_nodes[common_count] = target_node_index;
    common_uuids[common_count] = target_node.uuid;

    common_size_nodes[common_size_count] = target_node_index;
    common_size_uuids[common_size_count] = target_node.uuid;

    common_count += 1;
    common_size_count += 1;
    if (target_node.type == .Icon) return;
    if (target_node.style == null) return;
    if (target_node.class != null) return;
    const target_style = target_node.style orelse return;
    if (target_style.style_id != null) return;
    for (nodes[0..node_count], 0..) |node, i| {
        if (seen_nodes[i]) continue;
        if (node.type == .Icon) continue;
        const node_style = node.style orelse continue;

        const same = std.meta.eql(target_style, node_style);
        if (same) {
            common_nodes[common_count] = i + 1;
            common_uuids[common_count] = node.uuid;
            common_count += 1;
            continue;
        }

        if (target_style.size != null and node_style.size != null) {
            const same_size = std.meta.eql(target_style.size.?, node_style.size.?);
            if (same_size) {
                common_size_style = target_style;
                common_size_nodes[common_size_count] = i + 1;
                common_size_uuids[common_size_count] = node.uuid;
                common_size_count += 1;
            }
        }
    }
}
