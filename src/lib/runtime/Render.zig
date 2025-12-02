const std = @import("std");
const builtin = @import("builtin");
pub const isWasi = builtin.target.cpu.arch == .wasm32;
pub const debug = builtin.mode == .Debug;
// We cant use bools since they get recompiled each time, hence we use the builtin target
pub var isGenerated = !isWasi;
const types = @import("../types.zig");
const UIContext = @import("../UITree.zig");
const Router = @import("../Router.zig");
const UINode = @import("../UITree.zig").UINode;
const Reconciler = @import("../Reconciler.zig");

const FrameAllocator = @import("../FrameAllocator.zig");
pub var frame_arena: FrameAllocator = undefined;

const DebugLevel = enum(u8) { all = 0, debug = 1, info = 2, warn = 3, none = 4 };

pub var build_options = struct {
    enable_debug: bool = debug,
    debug_level: DebugLevel = .none,
}{};

pub var Timer = struct {
    generation_time: f64 = 0,
    reconcile_time: f64 = 0,
    commit_time: f64 = 0,
    total_time: f64 = 0,
}{};
// const getFocusStyle = @import("convertFocus.zig").getFocusStyle;
// const getFocusWithinStyle = @import("convertFocusWithin.zig").getFocusWithinStyle;
const Chain = @import("Static.zig").Chain;
const ChainPure = @import("Pure.zig").Chain;
const getStyle = @import("convertStyleCustomWriter.zig").getStyle;
const StyleCompiler = @import("convertStyleCustomWriter.zig");
const grabInputDetails = @import("grabInputDetails.zig");
const utils = @import("utils.zig");
// const createInput = grabInputDetails.createInput;
const getAriaLabel = utils.getAriaLabel;
pub const setGlobalStyleVariables = @import("convertStyleCustomWriter.zig").setGlobalStyleVariables;
const Debugger = @import("Debugger.zig");
const NodePool = @import("NodePool.zig");

pub const Component = fn (void) void;

pub const on_change_hash = "onChange";
pub const on_leave_hash = "onLeave";
pub const on_hover_hash = "onHover";
pub const on_submit_hash = "onSubmit";
pub const on_focus_hash = "onFocus";
pub const on_blur_hash = "onBlur";

const EventType = types.EventType;
const Active = types.Active;
pub const ElementDecl = types.ElementDeclaration;
const RenderCommand = types.RenderCommand;
pub const ElementType = types.ElementType;
const Hover = types.Hover;
const Focus = types.Focus;
pub var has_context: bool = false;
pub var current_ctx: *UIContext = undefined;
pub var ctx_map: std.AutoHashMap(u32, *UIContext) = undefined;
pub var page_map: std.StringHashMap(void) = undefined;
const LayoutItem = struct {
    reset: bool = false,
    call_fn: *const fn (*const fn () void) void,
};
pub var layout_map: std.AutoHashMap(u32, LayoutItem) = undefined;
pub var page_deinit_map: std.AutoHashMap(u32, *const fn () void) = undefined;
pub var global_rerender: bool = false;
pub var has_dirty: bool = false;
pub var rerender_everything: bool = false;
pub var grain_rerender: bool = false;
pub var grain_element_uuid: []const u8 = "";
pub var current_depth_node_id: []const u8 = "";
pub var router: Router = undefined;

var serious_error: bool = false;

const ArenaType = enum {
    frame,
    view,
    persist,
    scratch,
    request,
};

pub const VaporConfig = struct {
    // screen_width: f32,
    // screen_height: f32,
    page_node_count: u32 = 256,
    mode: Mode = .retained,
};

const Mode = enum {
    immediate,
    atomic,
    retained,
    static,
};

/// The LifeCycle struct
/// allows control over ui node in the tree
/// exposes open, configure, and close, must be called in this order to attach the node to the tree
pub const LifeCycle = struct {
    /// open takes an element decl and return a *UINode
    /// this opens the element to allow for children
    /// within the dom tree, node this current opened node is the current top stack node, ie any children
    /// will reference this node as their parent
    pub fn open(elem_decl: ElementDecl) ?*UINode {
        const ui_node = current_ctx.open(elem_decl) catch {
            return null;
        };
        return ui_node;
    }
    /// close, closes the current UINode
    pub fn close(_: void) void {
        _ = current_ctx.close();
        return;
    }
    /// configure is used internally to configure the UINode, used for adding text props, or hover props ect
    /// within configure, we check if the node has a id if so we use that, otherwise later we generate one
    /// we also set various props, such as text, style, is an SVG or not
    /// Any mainpulation of the node after this point is considered undefined behaviour be cautious;
    pub fn configure(elem_decl: ElementDecl) void {
        _ = current_ctx.configure(elem_decl);
    }
};
var route_segments: [][]const u8 = undefined;
var deepest_reset_layout: ?LayoutItem = null;
var deepest_reset_layout_path: []const u8 = "";
var target_min_layout_path: []const u8 = "";

fn findResetLayout() void {
    var potential_path: []const u8 = "";
    for (route_segments, 0..) |segment, i| {
        potential_path = std.fmt.allocPrint(allocator_global, "{s}/{s}", .{ potential_path, segment }) catch return;
        const target_layout = layout_map.get(hashKey(potential_path)) orelse continue;
        if (target_layout.reset) {
            deepest_reset_layout = target_layout;
            deepest_reset_layout_path = potential_path;
            route_segments = route_segments[i + 1 ..];
        }
    }
    if (deepest_reset_layout) |_| {
        target_min_layout_path = deepest_reset_layout_path;
    } else {
        target_min_layout_path = current_route;
    }
}

var next_layout_path_to_check: []const u8 = "";
fn callNestedLayouts() void {
    if (route_segments.len == 0) {
        if (deepest_reset_layout) |layout| {
            const layout_fn = layout.call_fn;
            deepest_reset_layout = null;
            deepest_reset_layout_path = "";
            layout_fn(render_page);
        } else {
            // TODO: This is taking a lot of time we need to create a better hashmap system, currently the hashmap compare
            // with the node is long and slow
            // const time = nowMs();
            render_page();
            // Vapor.println("Render time {any}", .{nowMs() - time});
        }
        return;
    }

    // Get the current layout
    next_layout_path_to_check = fmtln("{s}/{s}", .{ next_layout_path_to_check, route_segments[0] });
    if (layout_map.get(hashKey(next_layout_path_to_check))) |entry| {
        const layout_path = next_layout_path_to_check; // "/root" or "/root/docs"
        const layout_fn = entry.call_fn;
        // We check if the layout path and current path are the same
        // Here we need to check if the layout_path starts with the target_min_layout_path
        // if the target path is /root/docs and the layout_path is /root
        if (std.mem.startsWith(u8, target_min_layout_path, layout_path)) {
            route_segments = route_segments[1..];
            layout_fn(callNestedLayouts);
        }
    } else {
        if (route_segments.len == 0) {
            return;
        }
        // No layout found, continue with remaining segments
        route_segments = route_segments[1..];
        callNestedLayouts();
    }
}

pub var clean_up_ctx: *UIContext = undefined;
var current_route: []const u8 = "";
var previous_route: []const u8 = "";
var render_page: *const fn () void = undefined;
const RenderPhase = enum {
    generating, // Building VDOM
    committing, // Running commit hooks
    applying, // Applying to real DOM
    idle, // Done
};
// pub var render_phase: RenderPhase = .idle;
var changed_route: bool = false;
pub fn renderCycle(route_ptr: [*:0]u8) void {
    frame_arena.beginFrame(); // For double-buffered approach
    frame_arena.resetScratchArena();
    const route = std.mem.span(route_ptr);

    if (!std.mem.eql(u8, current_route, route)) {
        changed_route = true;
        // We need to start a new route allocator
        // otherwise we are on the same route
        frame_arena.beginView();
    }

    // Get the old context for current route
    const old_route = router.searchRoute(route) orelse blk: {
        break :blk router.searchRoute("/root/error") orelse {
            return;
        };
    };
    render_page = old_route.page;
    const old_ctx = current_ctx;
    // Create new context
    const new_ctx: *UIContext = frame_arena.frameAllocator().create(UIContext) catch {
        return;
    };

    UIContext.initContext(new_ctx) catch {
        new_ctx.deinit();
        return;
    };

    new_ctx.root.?.uuid = old_ctx.root.?.uuid;

    current_ctx = new_ctx;
    var route_itr = std.mem.tokenizeScalar(u8, route, '/');
    var count: usize = 0;
    while (route_itr.next()) |_| {
        count += 1;
    }
    route_segments = frame_arena.frameAllocator().alloc([]const u8, count) catch return;
    count = 0;
    route_itr.reset();
    while (route_itr.next()) |route_token| {
        route_segments[count] = route_token;
        count += 1;
    }

    // Init the generator
    next_layout_path_to_check = "";

    findResetLayout();
    // This calls the render tree, with render_page as the root function call
    // First it traverses the layouts calling them in order, and then it calls the render_page
    callNestedLayouts(); // 4.5ms
    // Vapor.println("Total {d}", .{frame_arena.queryBytesUsed()});
    // Debugger.render();

    Reconciler.reconcile(old_ctx, new_ctx); // 3kb
    // We generate the render commands tree
    endPage(new_ctx);

    if (build_options.enable_debug and build_options.debug_level == .all) {
        frame_arena.printStats();
    }

    // Replace old context with new context in the map
    clean_up_ctx = old_ctx;
    changed_route = false;
    // _ = frame_arena.queryNodes();
    if (router.updateRouteTree(old_route.path, new_ctx)) {
        return;
    }

    previous_route = current_route;
}

pub fn createPage(path: []const u8, page: fn () void, page_deinit: ?fn () void) !void {
    if (isWasi) {
        has_context = true;
    }
    const path_ctx: *UIContext = try allocator_global.create(UIContext);
    // Initial render
    UIContext.initContext(path_ctx) catch {
        return;
    };

    current_ctx = path_ctx;

    router.addRoute(path, path_ctx, page) catch {};
    page_map.put(path, {}) catch {};

    if (page_deinit) |de| {
        page_deinit_map.put(path, de) catch {};
    }
    return;
}

pub fn endPage() void {}
