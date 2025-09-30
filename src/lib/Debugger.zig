const std = @import("std");
const Fabric = @import("Fabric.zig");
const UIContext = @import("UITree.zig");
const LifeCycle = @import("Fabric.zig").LifeCycle;
const Chain = @import("Static.zig").Chain;
const UINode = @import("UITree.zig").UINode;
const Wasm = @import("wasm");
const PureTree = @import("PureTree.zig");
const Event = @import("Event.zig");
const Types = @import("types.zig");
const ChainPure = @import("Pure.zig").Chain;
const ChainPureClose = @import("Pure.zig").ChainClose;
const TextFmt = ChainPureClose.TextFmt;
const Static = @import("Static.zig");

pub var old_debugger_node: ?*UINode = null;
pub var new_debugger_node: ?*UINode = null;
pub var show_debugger: bool = false;

pub const Debug = struct {
    const Self = @This();
    _elem_type: Fabric.ElementType,

    pub const Debugger = Self{ ._elem_type = .FlexBox };
    pub inline fn style(self: *const Self, style_ptr: *const Fabric.Style) fn (void) void {
        var elem_decl = Fabric.ElementDecl{
            .dynamic = .static,
            .elem_type = self._elem_type,
            .style = style_ptr,
        };
        var mutable_style = style_ptr.*;
        mutable_style.direction = .column;
        elem_decl.style = &mutable_style;

        new_debugger_node = LifeCycle.open(elem_decl) orelse unreachable;

        LifeCycle.configure(elem_decl);
        return Fabric.LifeCycle.close;
    }
};

const Tree = enum {
    Pure,
    Error,
};

var tree: Tree = .Pure;
fn toggleTree() void {
    if (tree == .Pure) {
        tree = .Error;
    } else {
        tree = .Pure;
    }
}

pub fn render() void {
    if (show_debugger) {
        Debug.Debugger.style(&.{
            .id = "fabric-debugger",
            .position = .{ .type = .fixed, .top = .px(0), .right = .px(0) },
            .size = .hw(.percent(100), .px(400)),
            .padding = .tb(12, 12),
            .z_index = 999,
            .visual = .{ .background = .white },
        })({
            Chain.Stack.style(&.{
                .size = .hw(.percent(100), .percent(100)),
                .child_gap = 6,
            })({
                Chain.Box.style(&.{
                    .visual = .{ .border = .bottom(.hex("#000000")) },
                    .child_gap = 6,
                    .layout = .x_between_center,
                })({
                    // Trees;
                    Chain.ButtonCycle(.{ .on_press = toggleTree }).style(&.{ .visual = .{ .background = .transparent } })({
                        TextFmt("{s} Tree", .{@tagName(tree)}).style(&.{
                            .visual = .{
                                .font_size = 20,
                                .font_weight = 400,
                            },
                            .interactive = .hover_text(.hex("#4800FF")),
                        });
                    });

                    Chain.Button(.{ .on_press = clearHighlight }).style(&.{ .visual = .{ .background = .transparent } })({
                        Chain.Text("Clear").style(&.{
                            .visual = .{ .font_size = 20 },
                            .interactive = .hover_text(.hex("#4800FF")),
                        })({});
                    });
                });
                if (tree == .Pure) {
                    displayChild(Fabric.pure_tree.root);
                } else {
                    displayChild(Fabric.error_tree.root);
                }
            });
        });
    } else {
        new_debugger_node = null;
    }
}

fn highlightTarget(target_id: []const u8) void {
    Wasm.highlightTargetNode(target_id.ptr, target_id.len, 0);
}

fn highlightErrorTarget(target_id: []const u8) void {
    Wasm.highlightTargetNode(target_id.ptr, target_id.len, 1);
}

fn highlightHoverTarget(target_id: []const u8) void {
    Wasm.highlightHoverTargetNode(target_id.ptr, target_id.len, 0);
}

fn highlightHoverErrorTarget(target_id: []const u8) void {
    Wasm.highlightHoverTargetNode(target_id.ptr, target_id.len, 1);
}

fn clearHoverHighlight(_: *Event) void {
    Wasm.clearHoverHighlight();
}

fn clearHighlight() void {
    Wasm.clearHighlight();
}

fn highlight(target_id: []const u8) void {
    if (tree == .Pure) {
        highlightTarget(target_id);
    } else {
        highlightErrorTarget(target_id);
    }
}

fn hoverHighlight(target_id: []const u8, _: *Event) void {
    if (tree == .Pure) {
        highlightHoverTarget(target_id);
    } else {
        highlightHoverErrorTarget(target_id);
    }
}

fn mount(node: *PureTree.PureNode) void {
    _ = node.element.addInstListener(.mouseenter, node.uuid, hoverHighlight);
    _ = node.element.addListener(.mouseleave, clearHoverHighlight);
}

var margin_left: usize = 0;
fn displayChild(node: *PureTree.PureNode) void {
    margin_left += 10;
    for (node.children.items) |child| {
        const visual = Types.Visual{
            .font_size = 12,
            .border = if (child.dirty) .simple(.hex("#4800FF")) else .simple(.transparent),
        };
        Static.CtxHooks(.mounted, mount, .{child}, &.{})({
            ChainPure.CtxButton(highlight, .{child.uuid}).bind(&child.element).style(&.{
                .layout = .{},
                .direction = .row,
                .margin = .l(margin_left),
                .size = .hw(.fit, .fit),
                .padding = .lr(4, 4),
                .visual = visual,
            })({
                TextFmt("{s}", .{@tagName(child.ui_node.type)}).style(&.{
                    .visual = .{ .font_size = 12, .font_weight = 600 },
                    .margin = .r(4),
                });
                TextFmt("UUID: {s}", .{child.uuid}).style(&.{});
            });
        });
        displayChild(child);
    }
    margin_left -= 10;
}

pub fn onKeyPress(evt: *Event) void {
    const key = evt.key();
    if (std.mem.eql(u8, key, "x") and evt.metaKey()) {
        evt.preventDefault();
        show_debugger = true;
        Fabric.cycle();
    } else if (std.mem.eql(u8, key, "Escape")) {
        evt.preventDefault();
        show_debugger = false;
        Fabric.cycle();
    }
}
