const std = @import("std");
const UIContext = @import("UITree.zig");
const Fabric = @import("Fabric.zig");
const Style = @import("types.zig").Style;
const Color = @import("types.zig").Color;
const UINode = @import("UITree.zig").UINode;
const utils = @import("utils.zig");
const hashKey = utils.hashKey;
const Self = @This();

var layout_path: []const u8 = "";
// pub var node_map: std.StringHashMap(usize) = undefined;
var reconcile_debug: bool = false;

pub fn reconcile(old_ctx: *UIContext, new_ctx: *UIContext) void {
    reconcile_debug = false;
    if (old_ctx.root == null or new_ctx.root == null) return;

    // node_map is file-scoped, so it's reused. Clear it.
    // node_map.clearRetainingCapacity();
    traverseNodes(old_ctx.root.?, new_ctx.root.?);
}

// --- Child Reconciliation Helpers ---

/// Case: Old children exist, new children list is empty.
fn removeAllChildren(old_items: []*UINode) void {
    for (old_items, 0..) |old_child, j| {
        // TODO: You may want to skip the debugger here too
        Fabric.removed_nodes.append(.{ .uuid = old_child.uuid, .index = j }) catch {};
    }
}

/// Case: Old children list is empty, new children exist.
fn addAllChildren(new_items: []*UINode) void {
    // Mark all new children as dirty (for creation)
    for (new_items) |node| {
        Fabric.markChildrenDirty(node);
    }
    Fabric.has_dirty = true;
}

/// Case: Both lists have the same number of children.
fn reconcileSameLength(old_items: []*UINode, new_items: []*UINode) void {
    for (old_items, 0..) |old_child, i| {
        const new_child = new_items[i];
        traverseNodes(old_child, new_child);
    }
}

/// Case: Keyed-diffing when old_items.len > new_items.len (Deletions)
fn reconcileDeletions(old_items: []*UINode, new_items: []*UINode, new_node: *UINode) void {
    // ---
    // FIX: Create a local map.
    // NOTE: You MUST replace 'Fabric.allocator' with your actual allocator!
    // ---
    var node_map = std.StringHashMap(usize).init(Fabric.frame_arena.getFrameAllocator());
    defer node_map.deinit();

    const len_old = old_items.len;
    const len_new = new_items.len;

    // 1. Sync from start
    var i: usize = 0;
    while (i < len_new) : (i += 1) {
        if (std.mem.eql(u8, old_items[i].uuid, new_items[i].uuid)) {
            traverseNodes(old_items[i], new_items[i]);
        } else {
            new_node.dirty = true;
            break;
        }
    }

    // 2. Sync from end
    var back_i_old: usize = len_old;
    var back_i_new: usize = len_new;
    while (back_i_new > i and back_i_old > i) {
        // ... (logic unchanged) ...
        const old_child = old_items[back_i_old - 1];
        const new_child = new_items[back_i_new - 1];

        if (std.mem.eql(u8, old_child.uuid, new_child.uuid)) {
            traverseNodes(old_child, new_child);
            back_i_old -= 1;
            back_i_new -= 1;
        } else {
            break;
        }
    }

    // 3. Process the middle "un-synced" section
    const start = i;
    const end_new = back_i_new;

    // Add all *old* nodes from the middle section to the (local) map
    for (old_items[start..back_i_old], start..) |old_child, j| {
        node_map.put(old_child.uuid, j) catch {
            Fabric.printlnSrcErr("Could not put node into node_map {any}\n", .{old_child.uuid}, @src());
        };
    }

    // Iterate *new* nodes in the middle section
    if (end_new > start) {
        for (new_items[start..end_new]) |new_child| {
            if (node_map.fetchRemove(new_child.uuid)) |old_child_entry| {
                const old_child = old_items[old_child_entry.value];
                traverseNodes(old_child, new_child); // This recursive call is now safe
                Fabric.has_dirty = true; // It moved
            }
        }
    }

    // 4. Any nodes *left* in the (local) map are deletions
    var node_itr = node_map.iterator();
    while (node_itr.next()) |entry| {
        const j = entry.value_ptr.*;
        const uuid = entry.key_ptr.*;
        Fabric.removed_nodes.append(.{ .uuid = uuid, .index = j }) catch {};
    }
}

/// Case: Keyed-diffing when new_items.len > old_items.len (Additions)
fn reconcileAdditions(old_items: []*UINode, new_items: []*UINode) void {
    // ---
    // FIX: Create a local map.
    // NOTE: You MUST replace 'Fabric.allocator' with your actual allocator!
    // ---
    var node_map = std.StringHashMap(usize).init(Fabric.frame_arena.getFrameAllocator());
    defer node_map.deinit();

    const len_old = old_items.len;
    const len_new = new_items.len;

    // 1. Sync from start
    var i: usize = 0;
    while (i < len_old) : (i += 1) {
        // ... (logic unchanged) ...
        if (std.mem.eql(u8, old_items[i].uuid, new_items[i].uuid)) {
            traverseNodes(old_items[i], new_items[i]);
        } else {
            break;
        }
    }

    // 2. Sync from end
    var back_i_old: usize = len_old;
    var back_i_new: usize = len_new;
    while (back_i_old > i and back_i_new > i) {
        // ... (logic unchanged) ...
        const old_child = old_items[back_i_old - 1];
        const new_child = new_items[back_i_new - 1];

        if (std.mem.eql(u8, old_child.uuid, new_child.uuid)) {
            traverseNodes(old_child, new_child);
            back_i_old -= 1;
            back_i_new -= 1;
        } else {
            break;
        }
    }

    // 3. Process the middle "un-synced" section
    const start = i;
    const end_old = back_i_old;
    const end_new = back_i_new;

    // Add all *new* nodes from the middle section to the (local) map
    for (new_items[start..end_new], start..) |new_child, j| {
        node_map.put(new_child.uuid, j) catch {
            Fabric.printlnSrcErr("Could not put node into node_map {any}\n", .{new_child.uuid}, @src());
        };
    }

    // Iterate *old* nodes in the middle section
    for (old_items[start..end_old], start..) |old_child, offset| {
        if (node_map.fetchRemove(old_child.uuid)) |new_child_entry| {
            const new_child = new_items[new_child_entry.value];
            traverseNodes(old_child, new_child); // This recursive call is now safe
            Fabric.has_dirty = true; // It moved
        } else {
            Fabric.removed_nodes.append(.{ .uuid = old_child.uuid, .index = offset }) catch {};
        }
    }

    // 4. Any nodes *left* in the (local) map are *additions*.
    var node_itr = node_map.iterator();
    while (node_itr.next()) |entry| {
        const new_child_index = entry.value_ptr.*;
        // This is now safe! The map only contains indices for *this* call's new_items.
        const new_child = new_items[new_child_index];
        Fabric.markChildrenDirty(new_child); // Mark for creation
    }
    Fabric.has_dirty = true; // Parent is dirty due to adds/moves
}

// --- Main Reconciler Function ---
var empty_slice: []*UINode = &[_]*UINode{};
pub fn traverseNodes(old_node: *UINode, new_node: *UINode) void {
    if (!reconcile_debug and std.mem.eql(u8, old_node.uuid, "fabric-debugger")) {
        return;
    }

    // --- 1. Reconcile current node properties ---
    // This logic is much flatter and easier to read.
    const changed = (new_node.finger_print != old_node.finger_print);

    const is_dirty = changed or
        Fabric.rerender_everything or
        old_node.dirty;
    // !std.mem.eql(u8, old_node.uuid, new_node.uuid) or // Different node type
    // (new_node.type != old_node.type); // Same node, different component type

    new_node.dirty = is_dirty;
    if (is_dirty) {
        Fabric.has_dirty = true;
    }

    // --- 2. Reconcile children ---
    // Get child slices, defaulting to an empty slice if children are null.
    // This avoids all the `children != null` checks.
    const old_items = if (old_node.children) |l| l.items else empty_slice;
    const new_items = if (new_node.children) |l| l.items else empty_slice;

    // This single if/else block replaces all the nested logic.
    if (new_items.len == 0) {
        if (old_items.len > 0) {
            // Case: New is empty, Old had items -> Remove all old
            removeAllChildren(old_items);
        }
        // Else: Both empty -> Do nothing
    } else if (old_items.len == 0) {
        // Case: New has items, Old was empty -> Add all new
        addAllChildren(new_items);
    } else if (old_items.len == new_items.len) {
        // Case: Same length -> Simple 1:1 traversal
        reconcileSameLength(old_items, new_items);
    } else {
        // Case: Different lengths -> Keyed diff
        if (old_items.len > new_items.len) {
            reconcileDeletions(old_items, new_items, new_node);
        } else {
            reconcileAdditions(old_items, new_items);
        }
    }
}

// pub fn reconcile(old_ctx: *UIContext, new_ctx: *UIContext) void {
//     reconcile_debug = false;
//     if (old_ctx.root == null) return;
//     if (new_ctx.root == null) return;
//     node_map.clearRetainingCapacity();
//     traverseNodes(old_ctx.root.?, new_ctx.root.?);
// }
//
// pub fn reconcileDebug(old_node: *UINode, new_node: *UINode) void {
//     // Fabric.println("Reconciling debug\n", .{});
//     reconcile_debug = true;
//     node_map.clearRetainingCapacity();
//     traverseNodes(old_node, new_node);
// }
//
// /// Compares two Style instances shallowly (all top-level fields).
// /// Returns true if every field is equal, false otherwise.
// pub fn nodesEqual(old_node: *UINode, new_node: *UINode) bool {
//     if (old_node.compact_style == null and new_node.compact_style == null) return true;
//     if (old_node.compact_style == null and new_node.compact_style != null) return false;
//     if (old_node.compact_style != null and new_node.compact_style == null) return false;
//     const a = old_node.compact_style.?;
//     const b = new_node.compact_style.?;
//     const a_basic = a.basic orelse return false;
//     const b_basic = b.basic orelse return false;
//     // Compare optional string fields
//     if (!compareOptionalSlice(a_basic.id, b_basic.id)) return false;
//     if (!compareOptionalSlice(old_node.text, new_node.text)) return false;
//     if (!compareOptionalSlice(a_basic.style_id, b_basic.style_id)) return false;
//     if (!compareOptionalSlice(old_node.href, new_node.href)) return false;
//
//     // if (a_basic.hover != null and b_basic.hover != null) {
//     //     const hovera = a_basic.hover.?;
//     //     const hoverb = b_basic.hover.?;
//     //     if (hovera_basic.background != null) {
//     //         if (!compareRgba(hovera_basic.background.?, hoverb_basic.background.?)) return false;
//     //     }
//     // }
//
//     // if (a_basic.layout != b_basic.layout) return false;
//     if (a_basic.position != null and b_basic.position != null) {
//         if (a_basic.position.?.type != b_basic.position.?.type) return false;
//         if (a_basic.position.?.top != null and b_basic.position.?.top != null) {
//             if (a_basic.position.?.top.?.value != b_basic.position.?.top.?.value) return false;
//         }
//         if (a_basic.position.?.bottom != null and b_basic.position.?.bottom != null) {
//             if (a_basic.position.?.bottom.?.value != b_basic.position.?.bottom.?.value) return false;
//         }
//         if (a_basic.position.?.left != null and b_basic.position.?.left != null) {
//             if (a_basic.position.?.left.?.value != b_basic.position.?.left.?.value) return false;
//         }
//         if (a_basic.position.?.right != null and b_basic.position.?.right != null) {
//             if (a_basic.position.?.right.?.value != b_basic.position.?.right.?.value) return false;
//         }
//     }
//
//     if (a_basic.direction != b_basic.direction) return false;
//
//     if (a_basic.size) |a_size| {
//         if (b_basic.size) |b_size| {
//             if (a_size.width.size.minmax.min != b_size.width.size.minmax.min) return false;
//             if (a_size.width.size.minmax.max != b_size.width.size.minmax.max) return false;
//             if (a_size.height.size.minmax.min != b_size.height.size.minmax.min) return false;
//             if (a_size.height.size.minmax.max != b_size.height.size.minmax.max) return false;
//         }
//     }
//
//     if (a_basic.padding != null and b_basic.padding != null) {
//         if (a_basic.padding.?.top != b_basic.padding.?.top) return false;
//         if (a_basic.padding.?.left != b_basic.padding.?.left) return false;
//         if (a_basic.padding.?.bottom != b_basic.padding.?.bottom) return false;
//         if (a_basic.padding.?.right != b_basic.padding.?.right) return false;
//     }
//     if (a_basic.margin != null and b_basic.margin != null) {
//         if (a_basic.margin.?.top != b_basic.margin.?.top) return false;
//         if (a_basic.margin.?.left != b_basic.margin.?.left) return false;
//         if (a_basic.margin.?.bottom != b_basic.margin.?.bottom) return false;
//         if (a_basic.margin.?.right != b_basic.margin.?.right) return false;
//     }
//
//     if (a.visual != null and b.visual != null) {
//         const a_visual = a.visual.?;
//         const b_visual = b.visual.?;
//         // if (a_visual.background != null and b_visual.background != null) {
//         //     if (!compareRgba(a_visual.background.?, b_visual.background.?)) return false;
//         // }
//
//         if (a_visual.font_size != b_visual.font_size) return false;
//         if (a_visual.letter_spacing != b_visual.letter_spacing) return false;
//         if (a_visual.line_height != b_visual.line_height) return false;
//         if (a_visual.font_weight != b_visual.font_weight) return false;
//         if (a_visual.border_radius != null and b_visual.border_radius != null) {
//             if (a_visual.border_radius.?.top_left != b_visual.border_radius.?.top_left) return false;
//             if (a_visual.border_radius.?.top_right != b_visual.border_radius.?.top_right) return false;
//             if (a_visual.border_radius.?.bottom_left != b_visual.border_radius.?.bottom_left) return false;
//             if (a_visual.border_radius.?.bottom_right != b_visual.border_radius.?.bottom_right) return false;
//         }
//         if (a_visual.border_thickness != null and b_visual.border_thickness != null) {
//             if (a_visual.border_thickness.?.top != b_visual.border_thickness.?.top) return false;
//             if (a_visual.border_thickness.?.left != b_visual.border_thickness.?.left) return false;
//             if (a_visual.border_thickness.?.right != b_visual.border_thickness.?.right) return false;
//             if (a_visual.border_thickness.?.bottom != b_visual.border_thickness.?.bottom) return false;
//         }
//         if (a_visual.border_color != null and b_visual.border_color != null) {
//             if (!compareRgba(a_visual.border_color.?, b_visual.border_color.?)) return false;
//         }
//         if (a_visual.border != null and b_visual.border != null) {
//             const border_a = a_visual.border.?;
//             const border_b = b_visual.border.?;
//             if (border_a.color != null and border_b.color != null) {
//                 if (!compareRgba(border_a.color.?, border_b.color.?)) return false;
//             }
//         }
//         // if (a_visual.text_color != null and b_visual.text_color != null) {
//         //     if (!compareRgba(a_visual.text_color.?, b_visual.text_color.?)) return false;
//         // }
//
//         if (a_visual.opacity != b_visual.opacity) return false;
//     }
//
//     // if (a.overflow != b.overflow) return false;
//
//     // if (a.overflow_x != b.overflow_x) return false;
//     // if (a.overflow_y != b.overflow_y) return false;
//     if (a_basic.layout != null and b_basic.layout != null) {
//         if (a_basic.layout.?.y != b_basic.layout.?.y) return false;
//         if (a_basic.layout.?.x != b_basic.layout.?.x) return false;
//     }
//     if (a_basic.child_gap != b_basic.child_gap) return false;
//     if (!compareOptionalSlice(a_basic.dialog_id, b_basic.dialog_id)) return false;
//
//     // // Compare non-optional slice fields
//     // if (!std.mem.eql(u8, a.font_family_file, b.font_family_file)) return false;
//     // if (!std.mem.eql(u8, a.font_family, b.font_family)) return false;
//     // if (!std.mem.eql(f32, a.color[0..], b.color[0..])) return false;
//     // if (a.text_decoration != b.text_decoration) return false;
//     // if (a.shadow != b.shadow) return false;
//     // if (a.white_space != b.white_space) return false;
//     // if (a.flex_wrap != b.flex_wrap) return false;
//     // if (a.key_frame != b.key_frame) return false;
//     // if (a.animation != b.animation) return false;
//     // if (a.z_index != b.z_index) return false;
//     // if (a.list_style != b.list_style) return false;
//     // if (a.blur != b.blur) return false;
//     // if (a.outline != b.outline) return false;
//     // if (a.transition != b.transition) return false;
//     // if (a.show_scrollbar != b.show_scrollbar) return false;
//     // if (a.hover != b.hover) return false;
//     // if (a.btn_id != b.btn_id) return false;
//
//     return true;
// }
//
// /// Helper to compare optional slices of u8
// fn compareFloat32Slice(
//     a: [4]u8,
//     b: [4]u8,
// ) bool {
//     if (a[0] == b[0] and a[1] == b[1] and a[2] == b[2] and a[3] == b[3]) {
//         return true;
//     } else {
//         return false;
//     }
// }
//
// fn compareRgba(a: Color, b: Color) bool {
//     switch (a) {
//         .Literal => {
//             const c_a = a.Literal;
//             const c_b = b.Literal;
//             if (c_a.r == c_b.r and c_a.g == c_b.g and c_a.b == c_b.b and c_a.a == c_b.a) {
//                 return true;
//             } else {
//                 return false;
//             }
//         },
//         else => return false,
//     }
// }
//
// fn compareOptionalUint32(
//     a: ?u32,
//     b: ?u32,
// ) bool {
//     if (a == null and b == null) {
//         return true;
//     } else if (a != null and b != null) {
//         return a.? == b.?;
//     } else {
//         return false;
//     }
// }
//
// fn compareOptionalFloat32(
//     a: ?f32,
//     b: ?f32,
// ) bool {
//     if (a == null and b == null) {
//         return true;
//     } else if (a != null and b != null) {
//         return a.? == b.?;
//     } else {
//         return false;
//     }
// }
// /// Helper to compare optional slices of u8
// fn compareOptionalFloat32Slice(
//     a: ?[4]u8,
//     b: ?[4]u8,
// ) bool {
//     if (a == null and b == null) {
//         return true;
//     } else if (a != null and b != null) {
//         if (a.?[0] == b.?[0] and a.?[1] == b.?[1] and a.?[2] == b.?[2] and a.?[3] == b.?[3]) {
//             return true;
//         } else {
//             return false;
//         }
//     } else {
//         return false;
//     }
// }
//
// /// Helper to compare optional slices of u8
// fn compareOptionalSlice(
//     a: ?[]const u8,
//     b: ?[]const u8,
// ) bool {
//     if (a == null and b == null) {
//         return true;
//     } else if (a != null and b != null) {
//         return std.mem.eql(u8, a.?, b.?);
//     } else {
//         return false;
//     }
// }
//
// var reconcile_debug: bool = false;
// pub fn traverseNodes(old_node: *UINode, new_node: *UINode) void {
//     if (!reconcile_debug and std.mem.eql(u8, old_node.uuid, "fabric-debugger")) {
//         return;
//     }
//
//     if (new_node.props_hash != old_node.props_hash) {
//         new_node.changed_props = true;
//         new_node.dirty = true;
//         Fabric.has_dirty = true;
//     } else {
//         new_node.changed_props = false;
//     }
//     if (new_node.style_hash != old_node.style_hash) {
//         new_node.changed_style = true;
//         new_node.dirty = true;
//         Fabric.has_dirty = true;
//     } else {
//         new_node.changed_style = false;
//     }
//     if (new_node.dirty and Fabric.has_dirty) {} else if (Fabric.rerender_everything or old_node.dirty) {
//         new_node.dirty = true;
//         Fabric.has_dirty = true;
//     } else if (!std.mem.eql(u8, old_node.uuid, new_node.uuid)) {
//         // If the uuids are different it means the node needs to be removed as it is a new node replacing an old node.
//         new_node.dirty = true;
//         Fabric.has_dirty = true;
//     } else {
//         if (new_node.type != old_node.type) {
//             new_node.dirty = true;
//             Fabric.has_dirty = true;
//         } else {
//             new_node.dirty = false;
//         }
//     }
//
//     if (old_node.children == null and new_node.children == null) return;
//     if (old_node.children != null and new_node.children != null) {
//         const old_children = old_node.children.?;
//         const new_children = new_node.children.?;
//         if (old_children.items.len != new_children.items.len) {
//
//             // Here we remove items, since old_node has more children than new_node
//             // [1,2,3,4,5]
//             // [3,4,5]
//             // we should plan on improving this part of the algorithm since if we remove items 1,2 then below
//             // we compare items 1,2,3 with 3,4,5 and so we remove and replace even though in the previous tree, we already had
//             // 3,4,5 just different ids of the nodes. below 1 == 3, 2 == 4, 3 == 5
//             // this is why keys are typically better in slices since if each node had a unique id, we could just compare
//             // that was length independent then we can compare said slices
//             if (old_children.items.len > new_children.items.len) {
//                 if (new_children.items.len == 0) {
//                     for (old_children.items, 0..) |node, j| {
//                         if (!reconcile_debug and std.mem.eql(u8, node.uuid, "fabric-debugger")) {
//                             continue;
//                         }
//                         Fabric.removed_nodes.append(.{ .uuid = node.uuid, .index = j }) catch {};
//                     }
//                     return;
//                 }
//
//                 // First we perform a diff sync checking the beginning and end of the slices;
//                 // this assume the keys are unique
//                 const len_old = old_children.items.len;
//                 const len_new = new_children.items.len;
//                 var i: usize = 0;
//                 blk: while (i < len_new) : (i += 1) {
//                     const new_child = new_children.items[i];
//                     const old_child = old_children.items[i];
//                     // Here we the first node are equal in uuid
//                     if (std.mem.eql(u8, old_child.uuid, new_child.uuid)) {
//                         traverseNodes(old_child, new_child);
//                     } else {
//                         new_node.dirty = true;
//                         break :blk;
//                     }
//                 }
//
//                 // i = 1; then element 0 is the same and thus we want to check everything from the back up to element 1
//                 // since element 1 was checked in the previous loop
//                 var back_i_new: usize = len_new;
//                 var back_i_old: usize = len_old;
//                 // Here we decrement the back_i_new and back_i_old until we find a non equal element
//                 blk: while (back_i_new > i) : (back_i_new -= 1) {
//                     const new_child = new_children.items[back_i_new - 1];
//                     const old_child = old_children.items[back_i_old - 1];
//                     // Here we the last node are equal in uuid
//                     if (std.mem.eql(u8, old_child.uuid, new_child.uuid)) {
//                         traverseNodes(old_child, new_child);
//                         back_i_old -= 1;
//                     } else {
//                         break :blk;
//                     }
//                 }
//
//                 // now we know the middle section where nodes on either side are not equal
//                 // We only check reording if there are still new nodes to be processed
//                 // const end = back_i_old;
//                 const end_new = back_i_new;
//                 // const end_old = len_old;
//                 // the start is the index of the first node that is not equal it is the same for both slices
//                 const start = i;
//                 // We create a node map of all the old nodes this is used to find the index of the new node in case things shifted
//                 for (old_children.items[start..back_i_old], start..) |old_child, j| {
//                     node_map.put(old_child.uuid, j) catch {
//                         Fabric.printlnSrcErr("Could not put node into node_map {any}\n", .{old_child.uuid}, @src());
//                     };
//                 }
//
//                 // We iterate over the new nodes and compare them to the old nodes
//                 if (end_new > 0 and end_new > start) {
//                     for (new_children.items[start..end_new]) |new_child| {
//                         // We check if the new node is in the node map if so then we know it shifted
//                         const old_child_index = node_map.get(new_child.uuid) orelse continue;
//                         const old_child = old_children.items[old_child_index];
//                         traverseNodes(old_child, new_child);
//                         // We mark this as dirty since we are shifting the nodes even if the nodes content hasnt changed
//                         Fabric.has_dirty = true;
//                     }
//                 }
//
//                 // Then we iterate through the node map and remove all the nodes that are not in the new node
//                 var node_itr = node_map.iterator();
//                 while (node_itr.next()) |entry| {
//                     const j = entry.value_ptr.*;
//                     const uuid = entry.key_ptr.*;
//                     Fabric.removed_nodes.append(.{ .uuid = uuid, .index = j }) catch {};
//                 }
//
//                 for (old_children.items) |old_child| {
//                     if (!reconcile_debug and std.mem.eql(u8, old_child.uuid, "fabric-debugger")) {
//                         continue;
//                     }
//                     _ = node_map.fetchRemove(old_child.uuid) orelse continue;
//                 }
//             } else if (old_children.items.len > 0 and new_children.items.len > 0 and old_children.items.len < new_children.items.len) {
//                 if (!reconcile_debug and std.mem.eql(u8, old_node.uuid, "fabric-debugger")) {
//                     return;
//                 }
//
//                 // First we perform a diff sync checking the beginning and end of the slices;
//                 // Moving inwards from both ends, ie [0,1,2,3] and [3,2,1,0]
//                 // we check 0 == 3 and 1 == 2 and 2 == 1 and 3 == 0
//                 // this assume the keys are unique
//                 const len_old = old_children.items.len;
//                 const len_new = new_children.items.len;
//                 // We check as long as i is less than old length since we are adding new nodes now
//                 // We dont want to go over the old length via indexing thus we only loop until the old length
//                 var i: usize = 0;
//                 blk: while (i < len_old - 1) : (i += 1) {
//                     const new_child = new_children.items[i];
//                     const old_child = old_children.items[i];
//                     // We compare the uuids of the nodes, if they are equal then we traverse the nodes
//                     // to see if there styles or props have changed
//                     if (std.mem.eql(u8, old_child.uuid, new_child.uuid)) {
//                         traverseNodes(old_child, new_child);
//                     } else {
//                         // Otherwise we break out of the loop and we have foudn the first node that is not equal
//                         break :blk;
//                     }
//                 }
//                 // This is the index of the first node that is not equal
//                 const start_unique = i;
//
//                 // We create copies of the lengths, to iterate backwards
//                 var back_i_old: usize = len_old - 1;
//                 var back_i_new: usize = len_new - 1;
//                 // We perform the same loop but now backwards up to start_unique
//                 // Again we start from the old length since we are adding new nodes, and dont want to use an undefined index
//                 // [0,1,2,3] and [5,4,3,2,1,0], len_old = 4, len_new = 6, start_unique = 0
//                 blk: while (i < back_i_old) : (back_i_old -= 1) {
//                     const new_child = new_children.items[back_i_new];
//                     const old_child = old_children.items[back_i_old];
//                     // Here we the last node are equal in uuid
//                     if (std.mem.eql(u8, old_child.uuid, new_child.uuid)) {
//                         traverseNodes(old_child, new_child);
//                         if (back_i_new == 0 or back_i_old == 0) break :blk;
//                         back_i_new -= 1;
//                     } else {
//                         break :blk;
//                     }
//                 } // Here old node has less then new_node, which means we added nodes
//
//                 const end_unique_new = back_i_new + 1;
//                 const end_unique_old = back_i_old + 1;
//                 // Now we know the middle section where nodes on either side are not equal
//                 // We only check reording if there are still new nodes to be processed
//                 // the start is the index of the first node that is not equal it is the same for both slices
//                 // We create a node map of all the new nodes this is used to find the index of the old node in case things shifted
//                 // We add the nodes beyond the middle section for example [0,1,2,3] and [0,4,5,2,1,3]
//                 // middle section of the new nodes is [4,5,2,1] since before we checked the first node 0 == 0 and the last node 3 == 3
//                 for (new_children.items[start_unique..end_unique_new], start_unique..) |new_child, offset| {
//                     node_map.put(new_child.uuid, offset) catch {
//                         Fabric.printlnSrcErr("Could not put node into node_map {any}\n", .{new_child.uuid}, @src());
//                     };
//                 }
//
//                 // Now we check shifting of the old nodes we use the end_unique_old since we are looping backwards through the old nodes
//                 // [1,2] is the old nodes middle section
//                 // node_map = [4,5,2,1]
//                 for (old_children.items[start_unique..end_unique_old], start_unique..) |old_child, offset| {
//                     // '1' is in the node map and so is '2', thus it shifted
//                     // We check if the new node is in the node map if so then we know it shifted
//                     const new_child_index = node_map.get(old_child.uuid) orelse {
//                         // This means the old node is not in the new set of nodes
//                         Fabric.removed_nodes.append(.{ .uuid = old_child.uuid, .index = offset }) catch {};
//                         continue;
//                     };
//                     // We remove the node from the map
//                     _ = node_map.remove(old_child.uuid);
//                     // We grab the new nodes that shifted and the curren old node that got shifted and compare them
//                     // In the old slice, '1' is at index 1 and in the new slice '1' is at index 4
//                     const new_child = new_children.items[new_child_index];
//                     traverseNodes(old_child, new_child);
//                     // We mark this as dirty since we are shifting the nodes even if the nodes content hasnt changed
//                     Fabric.has_dirty = true;
//                 }
//
//                 for (new_children.items[start_unique..end_unique_new]) |new_child| {
//                     Fabric.markChildrenDirty(new_child);
//                 }
//                 Fabric.has_dirty = true;
//             } else if (new_node.children != null and new_node.children.?.items.len > 0) {
//                 if (!reconcile_debug and std.mem.eql(u8, old_node.uuid, "fabric-debugger")) {
//                     return;
//                 }
//
//                 Fabric.removed_nodes.append(.{ .uuid = old_node.uuid, .index = 0 }) catch {};
//                 for (new_children.items) |node| {
//                     Fabric.markChildrenDirty(node);
//                 }
//             } else if (old_node.children != null and old_node.children.?.items.len > 0 and new_node.children == null) {
//                 for (old_children.items, 0..) |old_child, j| {
//                     Fabric.removed_nodes.append(.{ .uuid = old_child.uuid, .index = j }) catch {};
//                 }
//             } else {
//                 for (old_children.items, 0..) |old_child, i| {
//                     const new_child = new_children.items[i];
//                     traverseNodes(old_child, new_child);
//                 }
//             }
//         } else {
//             for (old_children.items, 0..) |old_child, i| {
//                 const new_child = new_children.items[i];
//                 traverseNodes(old_child, new_child);
//             }
//         }
//     } else if (new_node.children != null and new_node.children.?.items.len > 0) {
//         const new_children = new_node.children.?;
//         if (!reconcile_debug and std.mem.eql(u8, old_node.uuid, "fabric-debugger")) {
//             return;
//         }
//
//         Fabric.removed_nodes.append(.{ .uuid = old_node.uuid, .index = 0 }) catch {};
//         for (new_children.items) |node| {
//             Fabric.markChildrenDirty(node);
//         }
//     } else if (old_node.children != null and old_node.children.?.items.len > 0 and new_node.children == null) {
//         const old_children = old_node.children.?;
//         for (old_children.items, 0..) |old_child, j| {
//             Fabric.removed_nodes.append(.{ .uuid = old_child.uuid, .index = j }) catch {};
//         }
//     } else {
//         const old_children = old_node.children orelse return;
//         const new_children = new_node.children orelse return;
//         for (old_children.items, 0..) |old_child, i| {
//             const new_child = new_children.items[i];
//             traverseNodes(old_child, new_child);
//         }
//     }
// }
