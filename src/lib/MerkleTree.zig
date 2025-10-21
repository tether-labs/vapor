const UINode = @import("UITree.zig").UINode;

pub const MerkleTree = @This();
root: ?Node = null,
allocator: std.mem.Allocator,

const Node = struct {
    left: ?Node,
    right: ?Node,
    hash: u32,
    data: *UINode,
};

pub fn init(merkle_tree: *MerkleTree, allocator: std.mem.Allocator) void {
    merkle_tree.* = .{
        .allocator = allocator,
    };
}

fn hash(node: *UINode) u32 {
    const children = node.children orelse return node.props_hash + node.style_hash;
    var hash: u32 = node.props_hash + node.style_hash;
    for (children.items) |child| {
        const child_hash = child.props_hash + child.style_hash;
        hash += child_hash;
    }
}

pub fn add(merkle_tree: *MerkleTree, data: *UINode) void {
    if (merkle_tree.root == null) {
        merkle_tree.root = Node{
            .left = null,
            .right = null,
            .hash = 0,
            .data = data,
        };
        return;
    }

    var current_node = merkle_tree.root.?;
    while (true) {
        if (current_node.left == null) {
            current_node.left = Node{
                .left = null,
                .right = null,
                .hash = 0,
                .data = data,
            };
            break;
        }
        if (current_node.right == null) {
            current_node.right = Node{
                .left = null,
                .right = null,
                .hash = 0,
                .data = data,
            };
            break;
        }
        current_node = current_node.left.?;
    }
}
