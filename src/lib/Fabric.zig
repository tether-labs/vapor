const std = @import("std");
const builtin = @import("builtin");
pub const isWasi = builtin.target.cpu.arch == .wasm32;
pub const debug = builtin.mode == .Debug;
// We cant use bools since they get recompiled each time, hence we use the builtin target
pub var isGenerated = !isWasi;
const types = @import("types.zig");
const UIContext = @import("UITree.zig");
const PureTree = @import("PureTree.zig");
const UINode = @import("UITree.zig").UINode;
const CommandsTree = UIContext.CommandsTree;
const Rune = @import("Rune.zig");
const GrainStruct = @import("Grain.zig");
const TransitionState = @import("Transition.zig").TransitionState;
const Router = @import("Router.zig");
pub const Element = @import("Element.zig").Element;
const KeyGenerator = @import("Key.zig").KeyGenerator;
const Reconciler = @import("Reconciler.zig");
const TrackingAllocator = @import("TrackingAllocator.zig");
pub const KeyStone = @import("keystone/KeyStone.zig");
pub const Wasm = @import("wasm");
const getVisualStyle = @import("convertStyleCustomWriter.zig").getVisualStyle;
const Bridge = @import("Bridge.zig");
const Event = @import("Event.zig");
const Canopy = @import("Canopy.zig");
const CSSGenerator = @import("CSSGenerator.zig");
const hashKey = utils.hashKey;
const Pool = @import("Pool.zig");

const DebugLevel = enum(u8) { all = 0, debug = 1, info = 2, warn = 3, none = 4 };

pub const build_options = struct {
    enable_debug: bool = debug,
    debug_level: DebugLevel = .none,
}{};
// const getFocusStyle = @import("convertFocus.zig").getFocusStyle;
// const getFocusWithinStyle = @import("convertFocusWithin.zig").getFocusWithinStyle;
const Chain = @import("Static.zig").Chain;
const ChainPure = @import("Pure.zig").Chain;
const AllocText = ChainPure.AllocText;
const getStyle = @import("convertStyleCustomWriter.zig").getStyle;
const StyleCompiler = @import("convertStyleCustomWriter.zig");
pub const generateStyle = @import("convertStyleCustomWriter.zig").generateStyle;
const generateInputHTML = @import("grabInputDetails.zig").generateInputHTML;
const grabInputDetails = @import("grabInputDetails.zig");
const utils = @import("utils.zig");
const createInput = grabInputDetails.createInput;
const getInputSize = grabInputDetails.getInputSize;
const getInputType = grabInputDetails.getInputType;
const getAriaLabel = utils.getAriaLabel;
pub const setGlobalStyleVariables = @import("convertStyleCustomWriter.zig").setGlobalStyleVariables;
pub const ThemeType = @import("convertStyleCustomWriter.zig").ThemeType;
const Theme = @import("theme");
const Debugger = @import("Debugger.zig");

pub const Component = fn (void) void;

const EventType = types.EventType;
const Active = types.Active;
pub const ElementDecl = types.ElementDeclaration;
const RenderCommand = types.RenderCommand;
pub const ElementType = types.ElementType;
const Hover = types.Hover;
const Focus = types.Focus;
pub var has_context: bool = false;
pub var current_ctx: *UIContext = undefined;
pub var pure_tree: PureTree = undefined;
pub var error_tree: PureTree = undefined;
pub var ctx_map: std.AutoHashMap(u32, *UIContext) = undefined;
pub var page_map: std.AutoHashMap(u32, void) = undefined;
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
pub var packed_visuals: std.AutoHashMap(u32, *const types.PackedVisual) = undefined;
pub var packed_layouts: std.AutoHashMap(u32, *const types.PackedLayout) = undefined;
pub var packed_positions: std.AutoHashMap(u32, *const types.PackedPosition) = undefined;
pub var packed_margins_paddings: std.AutoHashMap(u32, *const types.PackedMarginsPaddings) = undefined;
pub var packed_animations: std.AutoHashMap(u32, *const types.PackedAnimations) = undefined;
pub var packed_interactives: std.AutoHashMap(u32, *const types.PackedInteractive) = undefined;
pub var packed_layouts_pool: std.heap.MemoryPool(types.PackedLayout) = undefined;
pub var packed_positions_pool: std.heap.MemoryPool(types.PackedPosition) = undefined;
pub var packed_margins_paddings_pool: std.heap.MemoryPool(types.PackedMarginsPaddings) = undefined;
pub var packed_visuals_pool: std.heap.MemoryPool(types.PackedVisual) = undefined;
pub var packed_animations_pool: std.heap.MemoryPool(types.PackedAnimations) = undefined;
pub var packed_interactives_pool: std.heap.MemoryPool(types.PackedInteractive) = undefined;

var serious_error: bool = false;

const Fabric = @This();
pub const Kit = @import("kit/Kit.zig");
// pub const Chart = @import("components/charts/Chart.zig");
pub const Style = types.Style;
pub const Signal = Rune.Signal;
pub const Grain = GrainStruct.Grain;
pub const Types = types;
pub const DateTime = @import("DateTime.zig");
pub const Animation = @import("Animation.zig");
pub const Transition = @import("Transition.zig");
// pub const Error = @import("routes/nightwatch/Error.zig");

pub fn clearPersitantStorage() void {
    if (isWasi) {
        Wasm.clearLocalStorageWasm();
    } else {}
}

pub fn getWindowPath() []const u8 {
    if (isWasi) {
        return std.mem.span(Wasm.getWindowInformationWasm());
    } else {
        return "";
    }
}

pub fn setLocalStorageString(key: []const u8, value: []const u8) void {
    if (isWasi) {
        Wasm.setLocalStorageStringWasm(key.ptr, key.len, value.ptr, value.len);
    }
}

pub fn persist(key: []const u8, value: anytype) void {
    switch (@TypeOf(value)) {
        i32, u32, usize, f32 => Wasm.setLocalStorageNumberWasm(key.ptr, key.len, value),
        []const u8 => Wasm.setLocalStorageStringWasm(key.ptr, key.len, value.ptr, value.len),
        else => {
            Fabric.printlnErr("Cannot store non string or int float types", .{});
        },
    }
}

pub fn getPersistBytes(key: []const u8) ?[]const u8 {
    return getLocalStorageString(key);
}

pub fn getPersist(comptime T: type, key: []const u8) ?T {
    if (isWasi) {
        switch (T) {
            i32 => return Wasm.getLocalStorageI32Wasm(key.ptr, key.len),
            u32 => return Wasm.getLocalStorageU32Wasm(key.ptr, key.len),
            usize => return Wasm.getLocalStorageUIntWasm(key.ptr, key.len),
            f32 => return Wasm.getLocalStorageF32Wasm(key.ptr, key.len),
            []const u8 => {
                const value = Wasm.getLocalStorageStringWasm(key.ptr, key.len);
                const value_string = std.mem.span(value);
                if (std.mem.eql(u8, value_string, "null")) {
                    return null;
                } else {
                    return value_string;
                }
            },
            else => {
                Fabric.printlnErr("Cannot get non string or int float types", .{});
                return null;
            },
        }
    }
    return null;
}

pub fn removePersist(key: []const u8) void {
    if (isWasi) {
        Wasm.removeLocalStorageWasm(key.ptr, key.len);
    }
}

pub fn getLocalStorageString(key: []const u8) ?[]const u8 {
    if (isWasi) {
        const value = Wasm.getLocalStorageStringWasm(key.ptr, key.len);
        const value_string = std.mem.span(value);
        if (std.mem.eql(u8, value_string, "null")) {
            return null;
        } else {
            return value_string;
        }
    }
    return null;
}

pub fn removeLocalStorage(key: []const u8) void {
    if (isWasi) {
        Wasm.removeLocalStorageWasm(key.ptr, key.len);
    }
}

pub fn setLocalStorageNumber(key: []const u8, value: u32) void {
    if (isWasi) {
        Wasm.setLocalStorageNumberWasm(key.ptr, key.len, value);
    }
}

pub const Action = struct {
    runFn: ActionProto,
    deinitFn: NodeProto,
};

pub const ActionProto = *const fn (*Action) void;
pub const NodeProto = *const fn (*Node) void;

pub const Node = struct { data: Action };

const UniformCallbackFn = fn (context: anyopaque) void;

pub fn ArgsTuple(comptime Fn: type) type {
    const out = std.meta.ArgsTuple(Fn);
    return if (std.meta.fields(out).len == 0) @TypeOf(.{}) else out;
}

const Options = struct {
    ArgsT: ?type = null,
};

const UniformClosure = struct {
    // Func: type,
    // ArgsT: type,
    // /// If the function this signature represents is compile-time known,
    // /// it can be held here.
    // func_ptr: ?type = null,
    //
    // Pointer to the actual function to be called.
    func: ?*anyopaque = null,
    // Type-erased pointer to the arguments for that function.
    context: *anyopaque,
    // A function pointer to correctly deallocate the context.
    // deinit_context_fn: fn (allocator: std.mem.Allocator, context: anyopaque) void,

    // This is the single, non-generic run function.
    pub fn run(self: *const UniformClosure) void {
        @call(.auto, self.func, .{self.context});
    }

    // // Step 4
    // // Here we pass the func and determine the args type
    // // here we check if the Func passed is a type or a function itself
    // pub fn init(comptime Func: anytype, options: Options) Signature {
    //     const FuncT = if (@TypeOf(Func) == type) Func else @TypeOf(Func);
    //     return .{
    //         .Func = FuncT,
    //         .YieldT = options.YieldT,
    //         .InjectT = options.InjectT,
    //         // ArgsT is the options if set, in our case options is .{}
    //         // hence we set the type of ArgsT to FuncT arguments
    //         .ArgsT = options.ArgsT orelse ArgsTuple(FuncT),
    //         // Here we set the val to the Func itselft so pub "fn incr() void {}" for example
    //         .func_ptr = if (@TypeOf(Func) == type) null else struct {
    //             const val = Func;
    //         },
    //     };
    // }
};

// This is the Node that will be stored in your registry.
const CtxNode = struct {
    // ... other node data
    closure: UniformClosure,
};

// A generic function to register any callback.
pub fn registerCallback(
    // The UI element's ID (we'll change this to u32 later).
    id: []const u8,
    // The actual function the user wants to call.
    comptime func: anytype,
    // The arguments for that function.
    args: anytype,
) !void {
    // 1. Define a type for the arguments' pointer.
    const Args = @TypeOf(args);
    const PtrArgs = *const Args;

    // 2. Allocate memory for the arguments and copy them over.
    const args_ptr = try Fabric.allocator_global.create(Args);
    args_ptr.* = args;

    // 3. Create the wrapper function that matches our uniform signature.
    // This wrapper casts the `anyopaque` back to the correct type.
    const wrapperFn = struct {
        fn run(context: anyopaque) void {
            const typed_context: PtrArgs = @ptrCast(@alignCast(context));
            @call(.auto, func, typed_context.*);
        }
    }.run;

    // 5. Create the UniformClosure instance.
    const closure = UniformClosure{
        .func = wrapperFn,
        .context = args_ptr,
    };

    // 6. Create the FabricNode instance.
    const node_with_closure = try Fabric.allocator_global.create(CtxNode);
    node_with_closure.* = CtxNode{
        .closure = closure,
        // ... other node data
    };

    // Now you would create your FabricNode and put it in the registry.
    try Fabric.ctx_registry.put(id, node_with_closure);
    // ...
}

pub var btn_registry: std.AutoHashMap(u32, *const fn () void) = undefined;
pub var time_out_registry: std.AutoHashMap(u32, *const fn () void) = undefined;
pub var ctx_registry: std.AutoHashMap(u32, *Node) = undefined;
pub var time_out_ctx_registry: std.AutoHashMap(usize, *Node) = undefined;
pub var callback_registry: std.AutoHashMap(u32, *Node) = undefined;
pub var fetch_registry: std.AutoHashMap(u32, *Kit.FetchNode) = undefined;
pub var events_callbacks: std.AutoHashMap(u32, *const fn (*Event) void) = undefined;
pub var events_inst_callbacks: std.AutoHashMap(u32, *EvtInstNode) = undefined;
pub var hooks_inst_callbacks: std.AutoHashMap(u32, *HookInstNode) = undefined;
pub var mounted_funcs: std.AutoHashMap(u32, *const fn () void) = undefined;
pub var mounted_ctx_funcs: std.array_list.Managed(*Node) = undefined;
pub var created_funcs: std.AutoHashMap(u32, *const fn () void) = undefined;
pub var updated_funcs: std.AutoHashMap(u32, *const fn () void) = undefined;
pub var destroy_funcs: std.AutoHashMap(u32, *const fn () void) = undefined;
const RemovedNode = struct {
    uuid: []const u8,
    index: usize,
};
pub var removed_nodes: std.array_list.Managed(RemovedNode) = undefined;
const Class = struct {
    element_id: []const u8,
    style_id: []const u8,
};
pub var classes_to_add: std.array_list.Managed(Class) = undefined;
pub var classes_to_remove: std.array_list.Managed(Class) = undefined;
pub var component_subscribers: std.array_list.Managed(*Rune.ComponentNode) = undefined;
// pub var grain_subs: std.array_list.Managed(*GrainStruct.ComponentNode) = undefined;
pub var animations: std.StringHashMap(Animation) = undefined;
// Define a type for continuation functions
var callback_count: u32 = 0;
const ContinuationFn = *const fn () void;

// Global array to store continuations
pub var continuations: [64]?ContinuationFn = undefined;

pub var allocator_global: std.mem.Allocator = undefined;
pub var browser_width: f32 = 0;
pub var browser_height: f32 = 0;
pub var page_node_count: usize = 256;
const FrameAllocator = @import("FrameAllocator.zig");
pub var frame_arena: FrameAllocator = undefined;

pub const FabricConfig = struct {
    screen_width: f32,
    screen_height: f32,
    allocator: std.mem.Allocator,
    page_node_count: usize = 256,
};

pub var pool: Pool = undefined;
pub fn init(config: FabricConfig) void {
    // Init the frame allocator;
    // This adds 500B
    frame_arena = FrameAllocator.init(config.allocator);
    // The persistent allocator is used for the Initialization of the registries as these persist over the lifetime of the program.
    var allocator = frame_arena.persistentAllocator();
    allocator_global = config.allocator;

    // Init Router // This adds 1kb
    router.init(&allocator) catch |err| {
        println("Could not init Router {any}\n", .{err});
    };

    browser_width = config.screen_width;
    browser_height = config.screen_height;
    page_node_count = config.page_node_count;

    // >1kb
    initPackedData(allocator);
    initPools(allocator);
    // 20kb
    initRegistries(allocator);
    // >1kb
    initCalls(allocator);
    // >1kb
    initContextData(allocator);

    UIContext.ui_nodes = allocator.alloc(UINode, config.page_node_count) catch unreachable;

    // Init string pool
    pool = Pool.init(allocator, 1024) catch |err| {
        printlnErr("Could not init Pool {any}\n", .{err});
        unreachable;
    };
    pool.initFreelist();

    animations = std.StringHashMap(Animation).init(allocator);
    component_subscribers = std.array_list.Managed(*Rune.ComponentNode).init(allocator);
    removed_nodes = std.array_list.Managed(RemovedNode).init(allocator);
    // grain_subs = std.array_list.Managed(*GrainStruct.ComponentNode).init(allocator);
    classes_to_add = std.array_list.Managed(Class).init(allocator);
    classes_to_remove = std.array_list.Managed(Class).init(allocator);

    // Init Context Data
    Reconciler.node_map = std.AutoHashMap(u32, usize).init(allocator);

    // Reconciliation styles dedupe // this is 2kb
    UIContext.nodes = allocator.alloc(*UINode, config.page_node_count) catch unreachable;
    UIContext.seen_nodes = allocator.alloc(bool, config.page_node_count) catch unreachable;
    UIContext.common_nodes = allocator.alloc(usize, config.page_node_count) catch unreachable;
    UIContext.common_size_nodes = allocator.alloc(usize, config.page_node_count) catch unreachable;
    UIContext.common_uuids = allocator.alloc([]const u8, config.page_node_count) catch unreachable;
    UIContext.common_size_uuids = allocator.alloc([]const u8, config.page_node_count) catch unreachable;
    UIContext.base_styles = allocator.alloc(Style, config.page_node_count) catch unreachable;
    @memset(UIContext.seen_nodes, false);
    @memset(UIContext.base_styles, Style{});
    @memset(UIContext.common_nodes, 0);

    // @memset(UIContext.common_nodes, 0);
    for (0..continuations.len) |i| {
        continuations[i] = null;
    }

    // this adds 7kb
    _ = getStyle(null); // 16kb
    _ = getVisualStyle(null, 0); // 20kb
    if (isWasi) {
        _ = Bridge.getRenderTreePtr();
    }
    // _ = getFocusStyle(null); // 20kb
    // _ = getFocusWithinStyle(null); // 20kb
    // this adds 4kb
    _ = createInput(null); // 20kb
    _ = getInputType(null); // 5kb
    _ = getInputSize(null); // 5kb
    _ = getAriaLabel(null); // < 1kb

    if (build_options.enable_debug) {
        eventListener(.keydown, Debugger.onKeyPress);
        printlnColor("-----------Debug Mode----------", .{}, .hex("#F6820C"));
    }
}

fn initRegistries(persistent_allocator: std.mem.Allocator) void {
    btn_registry = std.AutoHashMap(u32, *const fn () void).init(persistent_allocator);
    time_out_registry = std.AutoHashMap(u32, *const fn () void).init(persistent_allocator);
    ctx_registry = std.AutoHashMap(u32, *Node).init(persistent_allocator); // this adds like 30kb
    time_out_ctx_registry = std.AutoHashMap(usize, *Node).init(persistent_allocator);
    callback_registry = std.AutoHashMap(u32, *Node).init(persistent_allocator);
    fetch_registry = std.AutoHashMap(u32, *Kit.FetchNode).init(persistent_allocator);
}

fn initCalls(persistent_allocator: std.mem.Allocator) void {
    events_callbacks = std.AutoHashMap(u32, *const fn (*Event) void).init(persistent_allocator);
    events_inst_callbacks = std.AutoHashMap(u32, *EvtInstNode).init(persistent_allocator);
    hooks_inst_callbacks = std.AutoHashMap(u32, *HookInstNode).init(persistent_allocator);
    mounted_funcs = std.AutoHashMap(u32, *const fn () void).init(persistent_allocator);
    mounted_ctx_funcs = std.array_list.Managed(*Node).initCapacity(persistent_allocator, 32) catch |err| {
        println("Could not init Ctx Hooks {any}\n", .{err});
        return;
    };
    destroy_funcs = std.AutoHashMap(u32, *const fn () void).init(persistent_allocator);
    updated_funcs = std.AutoHashMap(u32, *const fn () void).init(persistent_allocator);
    created_funcs = std.AutoHashMap(u32, *const fn () void).init(persistent_allocator);
}

fn initContextData(persistent_allocator: std.mem.Allocator) void {
    ctx_map = std.AutoHashMap(u32, *UIContext).init(persistent_allocator);
    page_map = std.AutoHashMap(u32, void).init(persistent_allocator);
    layout_map = std.AutoHashMap(u32, LayoutItem).init(persistent_allocator);
    page_deinit_map = std.AutoHashMap(u32, *const fn () void).init(persistent_allocator);
    UIContext.key_depth_map = std.AutoHashMap(u32, usize).init(persistent_allocator);
    UIContext.component_index_map = std.AutoHashMap(u32, usize).init(persistent_allocator);
}

fn initPackedData(persistent_allocator: std.mem.Allocator) void {
    packed_visuals = std.AutoHashMap(u32, *const types.PackedVisual).init(persistent_allocator);
    packed_layouts = std.AutoHashMap(u32, *const types.PackedLayout).init(persistent_allocator);
    packed_positions = std.AutoHashMap(u32, *const types.PackedPosition).init(persistent_allocator);
    packed_margins_paddings = std.AutoHashMap(u32, *const types.PackedMarginsPaddings).init(persistent_allocator);
    packed_animations = std.AutoHashMap(u32, *const types.PackedAnimations).init(persistent_allocator);
    packed_interactives = std.AutoHashMap(u32, *const types.PackedInteractive).init(persistent_allocator);
}

fn initPools(persistent_allocator: std.mem.Allocator) void {
    packed_layouts_pool = std.heap.MemoryPool(types.PackedLayout).init(persistent_allocator);
    packed_positions_pool = std.heap.MemoryPool(types.PackedPosition).init(persistent_allocator);
    packed_margins_paddings_pool = std.heap.MemoryPool(types.PackedMarginsPaddings).init(persistent_allocator);
    packed_visuals_pool = std.heap.MemoryPool(types.PackedVisual).init(persistent_allocator);
    packed_animations_pool = std.heap.MemoryPool(types.PackedAnimations).init(persistent_allocator);
    packed_interactives_pool = std.heap.MemoryPool(types.PackedInteractive).init(persistent_allocator);
}

/// The LifeCycle struct
/// allows control over ui node in the tree
/// exposes open, configure, and close, must be called in this order to attach the node to the tree
pub const LifeCycle = struct {
    /// open takes an element decl and return a *UINode
    /// this opens the element to allow for children
    /// within the dom tree, node this current opened node is the current top stack node, ie any children
    /// will reference this node as their parent
    pub fn open(elem_decl: ElementDecl) ?*UINode {
        const ui_node = current_ctx.open(elem_decl) catch |err| {
            println("{any}\n", .{err});
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

// var last_time: i64 = 0;
// /// throttle is used to throttle the render cycle
// /// we can pass a delay in ms, if the time since the last render cycle is less than the delay, we return true
// /// otherwise we return false
// pub fn throttle(delay: u32) bool {
//     const current_time = std.time.milliTimestamp();
//     if (current_time - last_time < delay) {
//         return true;
//     }
//     last_time = current_time;
//     return false;
// }

/// Force rerender forces the entire dom tree to check props of all dynamic and pure components and rerender the ui
/// since Fabric is built with zig and wasm, checking all props of 10000s of nodes and ui components is cheap
/// feel free to abuse force, its essentially a global signal
pub fn cycle() void {
    if (isWasi) {
        Fabric.global_rerender = true;
        Wasm.requestRerenderWasm();
    }
}

// /// Force rerender forces the entire dom tree to check props of all dynamic and pure components and rerender the ui
// /// since Fabric is built with zig and wasm, checking all props of 10000s of nodes and ui components is cheap
// /// feel free to abuse force, its essentially a global signal
// pub fn cycleGrain() void {
//     Fabric.grain_rerender = true;
//     Fabric.println("Grain rerender", .{});
//     Wasm.requestRerenderWasm();
// }

/// Force rerender forces the entire dom tree to check props and rerender the entire ui
/// since Fabric is built with zig and wasm, checking all props of 10000s of nodes and ui components is cheap
/// feel free to abuse force, its essentially a global signal
pub fn forceEverything() void {
    if (isWasi) {
        Fabric.rerender_everything = true;
        Fabric.global_rerender = true;
        Wasm.requestRerenderWasm();
    }
}

/// This function adds the route to the tether radix tree.
/// Deinitializes the tether instance recursively calls routes deinit routes from radix tree
/// # Parameters:
/// - `fabric`: *Fabric,
/// - `path`: []const u8,
/// - `page`: CommandTree
///
/// # Returns:
/// !void.
pub fn addRoute(
    path: []const u8,
    page: *CommandsTree,
) !void {
    try router.addRoute(path, page);
    return;
}

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
            // Fabric.println("Render time {any}", .{nowMs() - time});
        }
        return;
    }

    // Get the current layout
    next_layout_path_to_check = std.fmt.allocPrint(allocator_global, "{s}/{s}", .{ next_layout_path_to_check, route_segments[0] }) catch return;
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
var current_route: []const u8 = "/root";
var previous_route: []const u8 = "/root";
var render_page: *const fn () void = undefined;
pub var generator: CSSGenerator = undefined;
pub fn renderCycle(route_ptr: [*:0]u8) void {
    pool.resetFreeList();
    // const time = nowMs();
    frame_arena.beginFrame(); // For double-buffered approach
    const route = std.mem.span(route_ptr);
    current_route = route;
    UIContext.key_depth_map.clearRetainingCapacity();
    // Fabric.btn_registry.clearRetainingCapacity();
    // Fabric.mounted_funcs.clearRetainingCapacity();

    var ctx_itr = ctx_registry.iterator();
    while (ctx_itr.next()) |entry| {
        _ = entry.value_ptr.*;
        // node.data.deinitFn(node);
    }
    ctx_registry.clearRetainingCapacity();

    // var hooks_ctx_itr = mounted_ctx_funcs.iterator();
    for (mounted_ctx_funcs.items) |node| {
        node.data.deinitFn(node);
    }
    mounted_ctx_funcs.clearRetainingCapacity();

    // Get the old context for current route
    const old_route = router.searchRoute(route) orelse {
        printlnWithColor("No Router found {s}\n", .{route}, "#FF3029", "ERROR");
        printlnWithColor("Loading Error Page\n", .{}, "#FF3029", "ERROR");
        // renderErrorPage(route);
        return;
    };
    render_page = old_route.page;
    const old_ctx = current_ctx;
    // Create new context
    const new_ctx: *UIContext = allocator_global.create(UIContext) catch {
        println("Failed to allocate UIContext\n", .{});
        return;
    };

    UIContext.initContext(new_ctx) catch |err| {
        println("Allocator ran out of space {any}\n", .{err});
        new_ctx.deinit();
        allocator_global.destroy(new_ctx);
        return;
    };

    // new_ctx.root.?.style = old_ctx.root.?.style;
    new_ctx.root.?.uuid = old_ctx.root.?.uuid;

    // Pure tree is attached to the traversal algo, ie itll be updated when the traversal algo is updated
    // pure_tree.init(new_ctx.root.?, &allocator_global) catch {};
    // error_tree.init(new_ctx.root.?, &allocator_global) catch {};
    current_ctx = new_ctx;
    var route_itr = std.mem.tokenizeScalar(u8, route, '/');
    var count: usize = 0;
    while (route_itr.next()) |_| {
        count += 1;
    }
    route_segments = allocator_global.alloc([]const u8, count) catch return;
    count = 0;
    route_itr.reset();
    while (route_itr.next()) |route_token| {
        route_segments[count] = route_token;
        count += 1;
    }

    // Init the generator
    generator.init();
    next_layout_path_to_check = "";
    // We call the routes and nested layuts
    // This finds the reset layout, if it exists
    findResetLayout();
    // This calls the render tree, with render_page as the root function call
    // First it traverses the layouts calling them in order, and then it calls the render_page
    callNestedLayouts(); // 4.5ms
    // Fabric.println("Traverse time {any}", .{nowMs() - time});

    // We reconcile the new dom
    // the reason the fabric-debugger gets remvoed is the new ui tree does not include it;
    // printUITree(old_ctx.root.?);
    // printUITree(new_ctx.root.?);
    Reconciler.reconcile(old_ctx, new_ctx); // 3kb
    // // We iterate over the new dom and generate our pure tree  !!! we need to imrpove this perf wise
    // iterateChildren(new_ctx.root.?);
    // // we call debugger to determine the nodes that were updated
    // Debugger.render();
    // if (Debugger.old_debugger_node == null and Debugger.show_debugger) {
    //     // Here new_debugger_node is not null
    //     markChildrenDirty(Debugger.new_debugger_node.?);
    //     Debugger.old_debugger_node = Debugger.new_debugger_node;
    //     Fabric.has_dirty = true;
    // } else if (!Debugger.show_debugger) {
    //     // Here new_debugger_node is null
    //     removed_nodes.append(.{ .uuid = "fabric-debugger", .index = 0 }) catch {};
    //     Debugger.old_debugger_node = null;
    // } else if (Debugger.old_debugger_node != null and Debugger.new_debugger_node != null and !rerender_everything) {
    //     Reconciler.reconcileDebug(Debugger.old_debugger_node.?, Debugger.new_debugger_node.?);
    //     Debugger.old_debugger_node = Debugger.new_debugger_node;
    //     // printUITree(Debugger.new_debugger_node.?);
    // }

    // We generate the render commands tree
    endPage(new_ctx);
    if (!std.mem.eql(u8, previous_route, current_route)) {
        Fabric.has_dirty = true;
    }

    // generator.traverse(new_ctx.root.?);
    // generator.printCSS();

    // Replace old context with new context in the map
    clean_up_ctx = old_ctx;
    _ = router.addRoute(route, new_ctx, render_page) catch {
        printlnSrcErr("Failed to update context map\n", .{}, @src());
        new_ctx.deinit();
        allocator_global.destroy(new_ctx);
        return;
    };

    allocator_global.free(route); // return host‑allocated buffer
    if (build_options.enable_debug and build_options.debug_level == .all) {
        frame_arena.printStats();
    }
    previous_route = current_route;
    // Clean up the old context
}

fn renderErrorPage(route: []const u8) void {
    const local_allocator = std.heap.page_allocator;
    // Get the old context for current route
    const error_specific_route = std.fmt.allocPrint(local_allocator, "{s}/error", .{route}) catch return;
    defer local_allocator.free(error_specific_route);
    const old_route = router.searchRoute(error_specific_route) orelse blk: {
        printlnWithColor("No Route Error Page Found\n", .{}, "#FF3029", "ERROR");
        const default_error = router.searchRoute("/error") orelse {
            printlnWithColor("No Default Error Page Found\n", .{}, "#FF3029", "ERROR");
            serious_error = true;
            return;
        };
        break :blk default_error;
    };
    render_page = old_route.page;
    const old_ctx = current_ctx;

    // Create new context
    const new_ctx: *UIContext = allocator_global.create(UIContext) catch {
        println("Failed to allocate UIContext\n", .{});
        return;
    };

    UIContext.initContext(new_ctx) catch |err| {
        println("Allocator ran out of space {any}\n", .{err});
        new_ctx.deinit();
        allocator_global.destroy(new_ctx);
        return;
    };
    // Render the page with the new context
    current_ctx = new_ctx;
    @call(.auto, render_page, .{});
    endPage(new_ctx);

    // Reconcile between old and new
    // Reconciler.reconcile(old_ctx, new_ctx);

    // Replace old context with new context in the map
    clean_up_ctx = old_ctx;

    _ = router.addRoute(route, new_ctx, render_page) catch {
        printlnSrcErr("Failed to update context map\n", .{}, @src());
        new_ctx.deinit();
        allocator_global.destroy(new_ctx);
        return;
    };

    allocator_global.free(route); // return host‑allocated buffer
}
pub fn createPage(path: []const u8, page: fn () void, page_deinit: ?fn () void) !void {
    if (isWasi) {
        has_context = true;
    }
    const path_ctx: *UIContext = try allocator_global.create(UIContext);
    // Initial render
    UIContext.initContext(path_ctx) catch |err| {
        println("Allocator ran out of space {any}\n", .{err});
        return;
    };

    // if (style) |s| {
    //     // path_ctx.stack.?.ptr.?.style = s.*;
    //     // path_ctx.root.?.style = s.*;
    //     path_ctx.root.?.uuid = s.id orelse path_ctx.root.?.uuid;
    // }

    current_ctx = path_ctx;
    // try pure_tree.init(path_ctx.root.?, &allocator_global);
    // try error_tree.init(path_ctx.root.?, &allocator_global);

    router.addRoute(path, path_ctx, page) catch |err| {
        println("Could not put route {any}\n", .{err});
    };
    page_map.put(hashKey(path), {}) catch |err| {
        println("Could not put route {any}\n", .{err});
    };
    if (page_deinit) |de| {
        page_deinit_map.put(path, de) catch |err| {
            println("Could not put route {any}\n", .{err});
        };
    }
    return;
}
extern fn performance_now() f64; // imported from JS, for example
pub fn nowMs() f64 {
    if (isWasi) {
        return performance_now();
    } else {
        return 0;
    }
}
pub fn endPage(path_ctx: *UIContext) void {
    path_ctx.endContext();
    // TODO: We need to finish the layout engine for working with IOS
    // Canopy.createStack(path_ctx, path_ctx.root.?);
    // Canopy.calcWidth(path_ctx);
    // printUITree(path_ctx.root.?);

    // This adds 2kb
    // UIContext.reconcileStyles();
    generator.writeAllStyles();
    // @memset(UIContext.seen_nodes, false);
    // UIContext.target_node_index = 0;
    // UIContext.reconcileSizes(path_ctx.root.?);
    // @memset(UIContext.seen_nodes, false);
    // UIContext.target_node_index = 0;
    // UIContext.reconcileVisuals(path_ctx.root.?);
    path_ctx.traverse();
}

pub fn end(fabric: *Fabric) !void {
    const watch_paths: []const []const u8 = &.{"src/routes"};
    for (watch_paths) |watch_path| {
        var dir = try std.fs.cwd().openDir(watch_path, .{ .iterate = true });
        defer dir.close();

        var walker = try dir.walk(fabric.allocator.*);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            const path = try std.fs.path.join(fabric.allocator.*, &.{ watch_path, entry.path });
            println("{s}\n", .{path});
        }
    }
}

// Okay so we need to change the node in the tree depending on the page route
// for example we add the commads tree to the router tree
pub fn Page(src: std.builtin.SourceLocation, page: fn () void, page_deinit: ?fn () void) void {
    const allocator = std.heap.page_allocator;
    const full_route = src.file;
    var itr = std.mem.tokenizeScalar(u8, full_route[7..], '/');
    var buf = std.array_list.Managed(u8).init(allocator);

    buf.appendSlice("/root") catch |err| {
        println("Allocator ran out of space {any}\n", .{err});
        return;
    };

    var file_name: []const u8 = "";
    blk: while (itr.next()) |sub| {
        if (itr.peek() == null) {
            file_name = sub;
            break :blk;
        }
        buf.append('/') catch |err| {
            println("Allocator ran out of space {any}\n", .{err});
            return;
        };

        buf.appendSlice(sub) catch |err| {
            println("Allocator ran out of space {any}\n", .{err});
            return;
        };
    }

    // else
    if (std.mem.startsWith(u8, file_name, "Error")) {
        buf.appendSlice("/error") catch |err| {
            println("Allocator ran out of space {any}\n", .{err});
            return;
        };
    }

    const route = buf.toOwnedSlice() catch |err| {
        println("Could not parse route {any}\n", .{err});
        return;
    };

    createPage(route, page, page_deinit) catch |err| {
        println("Could not add page {any}\n", .{err});
        return;
    };
}
const LayoutOptions = struct {
    reset: bool = false,
};

pub fn registerLayout(path: []const u8, layout: fn (*const fn () void) void, options: LayoutOptions) !void {
    if (std.mem.eql(u8, path, "/root")) return error.CannotRegisterRootPath;
    if (std.mem.eql(u8, path, "/")) {
        layout_map.put(hashKey("/root"), .{ .call_fn = layout, .reset = options.reset }) catch |err| {
            printlnSrcErr("Could not add layout to registry {}", .{err}, @src());
        };
    } else {
        const layout_route = std.fmt.allocPrint(allocator_global, "/root{s}", .{path}) catch return;
        layout_map.put(hashKey(layout_route), .{ .call_fn = layout, .reset = options.reset }) catch |err| {
            printlnSrcErr("Could not add layout to registry {}", .{err}, @src());
        };
    }
}
pub const HooksFuncs = struct {
    created: ?*const fn () void = null,
    mounted: ?*const fn () void = null,
    destroy: ?*const fn () void = null,
    updated: ?*const fn () void = null,
};

pub const HooksCtxFuncs = enum { mounted };

pub fn toggleTheme() void {
    if (isWasi) {
        Wasm.toggleThemeWasm();
    }
}

/// This function creates an eventListener on the element.
/// Takes a callback function to be called when an event is received;
/// # Parameters:
/// - `element_id`: []const u8,
/// - `event_type`: *EventType,
/// - `cb`: *const fn (event: *Event) void,
///
/// # Returns:
/// !void
pub inline fn destroyElementEventListener(
    element_uuid: []const u8,
    event_type: types.EventType,
    cb_id: usize,
) ?bool {
    const event_type_str = std.enums.tagName(types.EventType, event_type) orelse return null;
    Wasm.removeElementEventListener(element_uuid.ptr, element_uuid.len, event_type_str.ptr, event_type_str.len, cb_id);
    Fabric.printlnSrc("Callback id {}", .{cb_id}, @src());
    if (events_callbacks.remove(cb_id)) {
        return true;
    }
    return false;
}

/// This function creates an eventListener on the element.
/// Takes a callback function to be called when an event is received;
/// # Parameters:
/// - `element_id`: []const u8,
/// - `event_type`: *EventType,
/// - `cb`: *const fn (event: *Event) void,
///
/// # Returns:
/// !void
pub inline fn destroyElementInstEventListener(
    element_uuid: []const u8,
    event_type: types.EventType,
    cb_id: usize,
) ?bool {
    const event_type_str = std.enums.tagName(types.EventType, event_type) orelse return null;
    Wasm.removeElementEventListener(element_uuid.ptr, element_uuid.len, event_type_str.ptr, event_type_str.len, cb_id);
    if (events_inst_callbacks.remove(cb_id)) {
        return true;
    }
    return false;
}

/// This function creates an focuses on the element.
/// # Parameters:
/// - `element_id`: []const u8,
///
/// # Returns:
/// void
pub inline fn focus(element_uuid: []const u8) void {
    Wasm.elementFocusWasm(element_uuid.ptr, element_uuid.len);
}

/// This function creates an eventListener on the element.
/// Takes a callback function to be called when an event is received;
/// # Parameters:
/// - `element_id`: []const u8,
/// - `event_type`: *EventType,
/// - `cb`: *const fn (event: *Event) void,
///
/// # Returns:
/// !void
pub inline fn elementEventListener(
    element_uuid: []const u8,
    event_type: types.EventType,
    cb: *const fn (event: *Event) void,
) ?usize {
    const id = events_callbacks.count() + 1;
    events_callbacks.put(id, cb) catch |err| {
        println("Event Callback Error: {any}\n", .{err});
    };

    const event_type_str = std.enums.tagName(types.EventType, event_type) orelse return null;
    Wasm.createElementEventListener(element_uuid.ptr, element_uuid.len, event_type_str.ptr, event_type_str.len, id);
    return id;
}

pub const EvtInst = struct {
    evt_cb: EvtInstProto,
    deinit: EvtInstNodeProto,
};

pub const EvtInstProto = *const fn (*EvtInst, *Event) void;
pub const EvtInstNodeProto = *const fn (*EvtInstNode) void;

pub const EvtInstNode = struct { data: EvtInst };

pub inline fn elementInstEventListener(
    element_uuid: []const u8,
    event_type: types.EventType,
    self: anytype,
    cb: anytype,
) ?usize {
    const Self = @TypeOf(self);
    const EvtClosure = struct {
        self: Self,
        evt_node: EvtInstNode = .{ .data = .{ .evt_cb = runFn, .deinit = deinitFn } },

        fn runFn(evt_inst: *EvtInst, evt: *Event) void {
            const evt_node: *EvtInstNode = @fieldParentPtr("data", evt_inst);
            const closure: *@This() = @alignCast(@fieldParentPtr("evt_node", evt_node));
            @call(.auto, cb, .{ closure.self, evt });
        }
        fn deinitFn(evt_node: *EvtInstNode) void {
            const closure: *@This() = @alignCast(@fieldParentPtr("evt_node", evt_node));
            Fabric.allocator_global.destroy(closure);
        }
    };

    const evt_closure = Fabric.allocator_global.create(EvtClosure) catch |err| {
        println("Error could not create closure {any}\n ", .{err});
        unreachable;
    };
    evt_closure.* = .{
        .self = self,
    };

    const id = events_inst_callbacks.count();
    events_inst_callbacks.put(id, &evt_closure.evt_node) catch |err| {
        println("Event Callback Error: {any}\n", .{err});
    };

    const event_type_str = std.enums.tagName(types.EventType, event_type) orelse return null;
    Wasm.createElementEventInstListener(element_uuid.ptr, element_uuid.len, event_type_str.ptr, event_type_str.len, id);
    return id;
}

pub const HookInst = struct {
    hook_cb: HookInstProto,
    deinit: HookInstNodeProto,
};

pub const HookInstProto = *const fn (*HookInst) void;
pub const HookInstNodeProto = *const fn (*HookInstNode) void;

pub const HookInstNode = struct { data: HookInst };

/// cb(Self)
pub inline fn createHook(
    self: anytype,
    cb: anytype,
    url: []const u8,
) ?usize {
    const Self = @TypeOf(self);
    const HookClosure = struct {
        self: Self,
        hook_node: HookInstNode = .{ .data = .{ .hook_cb = runFn, .deinit = deinitFn } },

        fn runFn(hook_inst: *HookInst) void {
            const hook_node: *HookInstNode = @fieldParentPtr("data", hook_inst);
            const closure: *@This() = @alignCast(@fieldParentPtr("hook_node", hook_node));
            @call(.auto, cb, .{closure.self});
        }
        fn deinitFn(hook_node: *HookInstNode) void {
            const closure: *@This() = @alignCast(@fieldParentPtr("hook_node", hook_node));
            Fabric.allocator_global.destroy(closure);
        }
    };

    const hook_closure = Fabric.allocator_global.create(HookClosure) catch |err| {
        println("Error could not create closure {any}\n ", .{err});
        unreachable;
    };
    hook_closure.* = .{
        .self = self,
    };

    const id = hooks_inst_callbacks.count();
    hooks_inst_callbacks.put(id, &hook_closure.hook_node) catch |err| {
        println("Event Callback Error: {any}\n", .{err});
    };

    Wasm.createHookWASM(url.ptr, url.len, id);
    return id;
}

/// This function creates an eventListener on the document.
/// Takes a callback function to be called when an event is received;
/// # Parameters:
/// - `event_type`: *EventType,
/// - `cb`: *const fn (event: *Event) void,
///
/// # Returns:
/// !void
pub inline fn eventListener(
    event_type: types.EventType,
    cb: *const fn (event: *Event) void,
) void {
    const id = events_callbacks.count() + 1;
    events_callbacks.put(id, cb) catch |err| {
        println("Event Callback Error: {any}\n", .{err});
    };

    const event_type_str: []const u8 = std.enums.tagName(types.EventType, event_type) orelse return;
    if (isWasi) {
        Wasm.createEventListener(event_type_str.ptr, event_type_str.len, id);
    }
    return;
}

// The first node needs to be marked as false always
pub fn markChildrenDirty(node: *UINode) void {
    if (node.parent != null) {
        node.dirty = true;
    }
    if (!node.can_have_children) return;
    for (node.children.items) |child| {
        markChildrenDirty(child);
    }
}
// The first node needs to be marked as false always
pub fn markChildrenNotDirty(node: *UINode) void {
    if (node.parent != null) {
        node.dirty = false;
    }
    if (!node.can_have_children) return;
    for (node.children.items) |child| {
        markChildrenNotDirty(child);
    }
}

var buffer: [5_000_000]u8 = undefined;
var writer: std.Io.Writer = undefined;
var generated_file: std.fs.File = undefined;
pub fn generateTextData() void {
    generated_file = std.fs.cwd().createFile("dist/text_data.json", .{}) catch unreachable;
    defer generated_file.close();
    var page_itr = page_map.iterator();
    _ = generated_file.write("{\n") catch unreachable;
    while (page_itr.next()) |entry| {
        writer = std.io.Writer.fixed(&buffer);
        const route = entry.key_ptr.*;
        const size = generated_file.getPos() catch unreachable;
        if (size > 10) {
            _ = writer.write(",\n") catch unreachable;
        }
        printUIRouteTree(route);
        _ = generated_file.write(writer.buffer[0..writer.end]) catch unreachable;
    }
    _ = generated_file.write("}\n") catch unreachable;
    // writer.flush() catch unreachable;
    // isGenerated = true;
}
pub fn printUIRouteTree(route: u32) void {
    frame_arena.beginFrame(); // For double-buffered approach
    current_route = route;
    UIContext.key_depth_map.clearRetainingCapacity();
    // Fabric.btn_registry.clearRetainingCapacity();
    // Fabric.mounted_funcs.clearRetainingCapacity();

    ctx_registry.clearRetainingCapacity();

    mounted_ctx_funcs.clearRetainingCapacity();

    // Get the old context for current route
    const old_route = router.searchRoute(route) orelse {
        printlnWithColor("No Router found {s}\n", .{route}, "#FF3029", "ERROR");
        printlnWithColor("Loading Error Page\n", .{}, "#FF3029", "ERROR");
        return;
    };
    render_page = old_route.page;
    const old_ctx = current_ctx;
    // Create new context
    const new_ctx: *UIContext = allocator_global.create(UIContext) catch {
        println("Failed to allocate UIContext\n", .{});
        return;
    };

    UIContext.initContext(new_ctx) catch |err| {
        println("Allocator ran out of space {any}\n", .{err});
        new_ctx.deinit();
        allocator_global.destroy(new_ctx);
        return;
    };

    new_ctx.root.?.style = old_ctx.root.?.style;
    new_ctx.root.?.uuid = old_ctx.root.?.uuid;

    // Pure tree is attached to the traversal algo, ie itll be updated when the traversal algo is updated
    // pure_tree.init(new_ctx.root.?, &allocator_global) catch {};
    // error_tree.init(new_ctx.root.?, &allocator_global) catch {};
    // Here we set the current_ctx to the new_ctx
    current_ctx = new_ctx;
    var route_itr = std.mem.tokenizeScalar(u8, route, '/');
    var count: usize = 0;
    while (route_itr.next()) |_| {
        count += 1;
    }
    route_segments = allocator_global.alloc([]const u8, count) catch return;
    count = 0;
    route_itr.reset();
    while (route_itr.next()) |route_token| {
        route_segments[count] = route_token;
        count += 1;
    }

    next_layout_path_to_check = "";
    // We call the routes and nested layuts
    // This finds the reset layout, if it exists
    findResetLayout();
    // This calls the render tree, with render_page as the root function call
    // First it traverses the layouts calling them in order, and then it calls the render_page
    callNestedLayouts(); // 4.5ms

    // We reconcile the new dom
    // the reason the fabric-debugger gets remvoed is the new ui tree does not include it;

    // const valid_route = replace_dash(current_route) catch unreachable;
    // defer allocator_global.free(valid_route);

    writer.print("\"{s}\":", .{current_route}) catch unreachable;
    writer.writeAll("{\n") catch unreachable;
    printStaticTextNode(new_ctx.root.?);
    writer.writeAll("}\n") catch unreachable;
}

pub fn printUITree(node: *UINode) void {
    if (node.dirty and std.mem.eql(u8, node.uuid, "3708577890_Html-genk")) {
        println("UI: {s}", .{node.uuid});
    }
    for (node.children.items) |child| {
        printUITree(child);
    }
}

pub fn escapeForJson(input: []const u8) ![]u8 {
    var list = std.array_list.Managed(u8).init(allocator_global);

    for (input) |c| {
        switch (c) {
            '"' => {
                // Add backslash before quote: → \"
                try list.append('\\');
                try list.append('"');
            },
            '\\' => {
                // Optional: also escape existing backslashes → \\
                try list.append('\\');
                try list.append('\\');
            },
            '\n' => {
                // Optional: also escape existing backslashes → \\
                continue;
            },
            else => {
                try list.append(c);
            },
        }
    }

    return list.toOwnedSlice();
}

pub fn replace_dash(input: []const u8) ![]u8 {
    var list = std.array_list.Managed(u8).init(allocator_global);

    for (input) |c| {
        switch (c) {
            '/' => {
                // Add backslash before quote: → \"
                try list.append('-');
            },
            else => {
                try list.append(c);
            },
        }
    }

    return list.toOwnedSlice();
}

fn printStaticTextNode(node: *UINode) void {
    if (node.state_type == .static) blk: {
        var valid_text: []const u8 = "";
        if (node.text) |text| {
            valid_text = escapeForJson(text) catch unreachable;
        } else if (node.href) |href| {
            valid_text = escapeForJson(href) catch unreachable;
        } else break :blk;
        defer allocator_global.free(valid_text);
        if (writer.end > current_route.len + 10) {
            _ = writer.write(",\n") catch unreachable;
        }
        writer.print("\"{s}\":\"{s}\"", .{ node.uuid, valid_text }) catch unreachable;
    }
    for (node.children.items) |child| {
        printStaticTextNode(child);
    }
}

fn iterateChildren(node: *UINode) void {
    if (node.state_type == .pure) {
        const pure_node = pure_tree.createNode(node) catch return;
        Fabric.pure_tree.openNode(pure_node) catch return;
    }

    if (node.state_type == .err) {
        const error_node = error_tree.createNode(node) catch return;
        Fabric.error_tree.openNode(error_node) catch return;
    }

    for (node.children.items) |child| {
        iterateChildren(child);
    }
    if (node.state_type == .pure and node.parent != null) {
        _ = pure_tree.popStack();
    }
    if (node.state_type == .err and node.parent != null) {
        _ = error_tree.popStack();
    }
}

pub fn iterateTreeChildren(tree: *CommandsTree) void {
    for (tree.children.items) |child| {
        iterateTreeChildren(child);
    }
}

// Export memory layout information for JavaScript to correctly read the struct
// Export function to get a pointer to the memory layout information
// Corrected layout information
pub var layout_info = packed struct {
    render_command_size: u32,

    // Offsets within RenderCommand
    elem_type_offset: u32,
    text_ptr_offset: u32,
    href_ptr_offset: u32,
    id_ptr_offset: u32,
    index_offset: u32,
    hooks_offset: u32,
    node_ptr_offset: u32,
    classname_ptr_offset: u32,

    // Offsets for fields inside the nested 'style' struct
    style_btn_id_offset: u32,
    style_dialog_id_offset: u32,
    style_exit_animation_ptr_offset: u32,

    // Offsets for fields inside the nested 'hover' struct
    hover_size: u32,
    hover_offset: u32,

    // Offsets for fields inside the nested 'focus' struct
    focus_size: u32,
    focus_offset: u32,

    // Offsets for fields inside the nested 'focus_within' struct
    focus_within_size: u32,
    focus_within_offset: u32,
    render_type_offset: u32,
    tooltip_size: u32,
    tooltip_offset: u32,
    changed_style_offset: u32,
    changed_props_offset: u32,
}{
    .render_command_size = @sizeOf(RenderCommand),

    // --- Direct fields of RenderCommand ---
    .elem_type_offset = @offsetOf(RenderCommand, "elem_type"),
    .text_ptr_offset = @offsetOf(RenderCommand, "text"),
    .href_ptr_offset = @offsetOf(RenderCommand, "href"),
    .id_ptr_offset = @offsetOf(RenderCommand, "id"),
    .index_offset = @offsetOf(RenderCommand, "index"),
    .hooks_offset = @offsetOf(RenderCommand, "hooks"),
    .node_ptr_offset = @offsetOf(RenderCommand, "node_ptr"),
    .classname_ptr_offset = @offsetOf(RenderCommand, "class"),

    // --- Absolute offsets for fields within the nested 'style' struct ---
    .style_btn_id_offset = @offsetOf(RenderCommand, "style") + @offsetOf(Style, "btn_id"),
    .style_dialog_id_offset = @offsetOf(RenderCommand, "style") + @offsetOf(Style, "dialog_id"),
    .style_exit_animation_ptr_offset = @offsetOf(RenderCommand, "style") + @offsetOf(Style, "exit_animation"),

    // --- Nested struct sizes and offsets ---
    .hover_offset = @offsetOf(RenderCommand, "hover"),
    .hover_size = @sizeOf(Hover),
    .focus_offset = @offsetOf(RenderCommand, "focus"),
    .focus_size = @sizeOf(Focus),
    .focus_within_offset = @offsetOf(RenderCommand, "focus_within"),
    .focus_within_size = @sizeOf(Focus),
    .render_type_offset = @offsetOf(RenderCommand, "render_type"),
    .tooltip_size = @sizeOf(types.Tooltip),
    .tooltip_offset = @offsetOf(RenderCommand, "tooltip"),
    .changed_style_offset = @offsetOf(RenderCommand, "changed_style"),
    .changed_props_offset = @offsetOf(RenderCommand, "changed_props"),
};

// Make sure this function is not evaluated at compile time
pub fn hexToRgba(hex_str: []const u8) [4]f32 {
    if (hex_str.len < 7 or hex_str[0] != '#') return .{ 0, 0, 0, 1 };

    // Parse at runtime instead of compile-time
    var r: f32 = 0;
    var g: f32 = 0;
    var b: f32 = 0;

    // Manual hex parsing to avoid compile-time evaluation issues
    r = @floatFromInt(parseHexByte(hex_str[1..3]) catch 0);
    g = @floatFromInt(parseHexByte(hex_str[3..5]) catch 0);
    b = @floatFromInt(parseHexByte(hex_str[5..7]) catch 0);

    return .{ r, g, b, 1 };
}

fn parseHexByte(hex: []const u8) !u8 {
    if (hex.len != 2) return error.InvalidLength;

    const high = try charToHex(hex[0]);
    const low = try charToHex(hex[1]);

    return (high << 4) | low;
}

fn charToHex(c: u8) !u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'a'...'f' => c - 'a' + 10,
        'A'...'F' => c - 'A' + 10,
        else => error.InvalidCharacter,
    };
}

/// fmtln is a wrapper around std.fmt.allocPrint that allocates memory from the frame allocator
/// this means that this slice is deallocated on each frame
/// this is useful for formatting ids passed into the style struct
pub fn fmtln(
    comptime fmt: []const u8,
    args: anytype,
) []const u8 {
    const allocator = frame_arena.getFrameAllocator();
    const buf = std.fmt.allocPrint(allocator, fmt, args) catch |err| {
        println("Formatting, Error Could not format argument alloc Error details: {any}\n", .{err});
        return "";
    };
    return buf;
}

pub fn printlnErr(
    comptime fmt: []const u8,
    args: anytype,
) void {
    if (isWasi and build_options.enable_debug) {
        const buf = std.fmt.allocPrint(allocator_global, fmt, args) catch return;
        const buf_with_src = std.fmt.allocPrint(allocator_global, "[Fabric] [%cERROR%c] {s}", .{buf[0..]}) catch return;
        const style_1 = "color: #FF3029;";
        const style_2 = "";
        _ = Wasm.consoleLogColoredWasm(buf_with_src.ptr, buf_with_src.len, style_1[0..].ptr, style_1.len, style_2[0..].ptr, style_2.len);
        allocator_global.free(buf_with_src);
        allocator_global.free(buf);
    }
}

pub fn printlnSrcErr(
    comptime fmt: []const u8,
    args: anytype,
    src: std.builtin.SourceLocation,
) void {
    if (isWasi and build_options.enable_debug) {
        const buf = std.fmt.allocPrint(allocator_global, fmt, args) catch return;
        const buf_with_src = std.fmt.allocPrint(allocator_global, "[Fabric] [%c{s}:{d}%c]\n[Fabric] [ERROR] {s}", .{ src.file, src.line, buf[0..] }) catch return;
        const style_1 = "color: #FF3029;";
        const style_2 = "";
        _ = Wasm.consoleLogColoredWasm(buf_with_src.ptr, buf_with_src.len, style_1[0..].ptr, style_1.len, style_2[0..].ptr, style_2.len);
        allocator_global.free(buf_with_src);
        allocator_global.free(buf);
    }
}

pub fn printlnWithColor(
    comptime fmt: []const u8,
    args: anytype,
    color: []const u8,
    title: []const u8,
) void {
    const buf = std.fmt.allocPrint(allocator_global, fmt, args) catch return;
    const color_buf = std.fmt.allocPrint(allocator_global, "color: {s};", .{color}) catch return;
    const buf_with_src = std.fmt.allocPrint(allocator_global, "[Fabric] [%c{s}%c] {s}", .{ title, buf[0..] }) catch return;
    // const style_2 = "";
    // _ = consoleLogColoredWasm(buf_with_src.ptr, buf_with_src.len, color_buf[0..].ptr, color_buf.len, style_2[0..].ptr, style_2.len);
    allocator_global.free(buf_with_src);
    allocator_global.free(color_buf);
    allocator_global.free(buf);
}

fn convertColorToString(color: Types.Color) []const u8 {
    return switch (color) {
        .Literal => |rgba| rgbaToString(rgba),
        else => "",
    };
}

fn rgbaToString(rgba: Types.Rgba) []const u8 {
    return std.fmt.allocPrint(allocator_global, "rgba({d},{d},{d},{d})", .{
        rgba.r,
        rgba.g,
        rgba.b,
        rgba.a,
    }) catch return "";
}

pub fn printlnColor(
    comptime fmt: []const u8,
    args: anytype,
    color: Types.Color,
) void {
    if (isWasi and build_options.enable_debug) {
        const buf = std.fmt.allocPrint(allocator_global, fmt, args) catch return;
        const color_buf = std.fmt.allocPrint(allocator_global, "color: {s};", .{convertColorToString(color)}) catch return;
        const buf_with_src = std.fmt.allocPrint(allocator_global, "%c{s}%c", .{buf[0..]}) catch return;
        const style_2 = "";
        _ = Wasm.consoleLogColoredWasm(buf_with_src.ptr, buf_with_src.len, color_buf[0..].ptr, color_buf.len, style_2[0..].ptr, style_2.len);
        allocator_global.free(buf_with_src);
        allocator_global.free(color_buf);
        allocator_global.free(buf);
    }
}

pub fn printlnAllocation(
    comptime fmt: []const u8,
    args: anytype,
) void {
    const buf = std.fmt.allocPrint(allocator_global, fmt, args) catch return;
    const buf_with_src = std.fmt.allocPrint(allocator_global, "[Fabric] [%cALLOC%c] {s}", .{buf[0..]}) catch return;
    // const style_1 = "color: #744EFF;";
    // const style_2 = "";
    // _ = consoleLogColoredWasm(buf_with_src.ptr, buf_with_src.len, style_1[0..].ptr, style_1.len, style_2[0..].ptr, style_2.len);
    allocator_global.free(buf_with_src);
    allocator_global.free(buf);
}

pub fn printlnSrc(
    comptime fmt: []const u8,
    args: anytype,
    src: std.builtin.SourceLocation,
) void {
    if (isWasi and build_options.enable_debug) {
        const buf = std.fmt.allocPrint(allocator_global, fmt, args) catch return;
        const buf_with_src = std.fmt.allocPrint(allocator_global, "[%c{s}:{d}%c]\n[MSG] {s}", .{ src.file, src.line, buf[0..] }) catch return;
        const style_1 = "color: #3CE98A;";
        const style_2 = "";
        _ = Wasm.consoleLogColoredWasm(buf_with_src.ptr, buf_with_src.len, style_1[0..].ptr, style_1.len, style_2[0..].ptr, style_2.len);
        allocator_global.free(buf_with_src);
        allocator_global.free(buf);
    }
}

pub fn println(
    comptime fmt: []const u8,
    args: anytype,
) void {
    if (isWasi and build_options.enable_debug) {
        const buf = std.fmt.allocPrint(allocator_global, fmt, args) catch return;
        _ = Wasm.consoleLogWasm(buf.ptr, buf.len);
        allocator_global.free(buf);
    } else if (!isWasi) {
        std.debug.print(fmt, args);
    }
}

pub fn addToClassesList(id: []const u8, style_id: []const u8) void {
    const clta = Class{ .element_id = id, .style_id = style_id };
    classes_to_add.append(clta) catch |err| {
        println("Could not add to class_list: {any}\n", .{err});
        return;
    };
}

pub fn addToRemoveClassesList(id: []const u8, style_id: []const u8) void {
    const cltr = Class{ .element_id = id, .style_id = style_id };
    classes_to_remove.append(cltr) catch |err| {
        println("Could not add to class_list: {any}\n", .{err});
        return;
    };
}

/// name: name of the interval
/// cb: callback function
/// args: arguments to pass to the callback function
/// delay: delay in ms
pub fn loopInterval(name: []const u8, cb: anytype, args: anytype, delay: u32) void {
    const Args = @TypeOf(args);
    const Closure = struct {
        arguments: Args,
        run_node: Node = .{ .data = .{ .runFn = runFn, .deinitFn = deinitFn } },
        //
        fn runFn(action: *Action) void {
            const run_node: *Node = @fieldParentPtr("data", action);
            const closure: *@This() = @alignCast(@fieldParentPtr("run_node", run_node));
            @call(.auto, cb, closure.arguments);
        }
        //
        fn deinitFn(node: *Node) void {
            const closure: *@This() = @alignCast(@fieldParentPtr("run_node", node));
            allocator_global.destroy(closure);
        }
    };

    const closure = allocator_global.create(Closure) catch |err| {
        println("Error could not create closure {any}\n ", .{err});
        unreachable;
    };
    closure.* = .{
        .arguments = args,
    };

    callback_registry.put(name, &closure.run_node) catch |err| {
        println("Button Function Registry {any}\n", .{err});
    };

    if (isWasi) {
        Wasm.createInterval(name.ptr, name.len, delay);
    } else {
        return;
    }
}

pub fn registerCtxTimeout(ms: u32, cb: anytype, args: anytype) void {
    const Args = @TypeOf(args);
    const Closure = struct {
        arguments: Args,
        run_node: Node = .{ .data = .{ .runFn = runFn, .deinitFn = deinitFn } },
        //
        fn runFn(action: *Action) void {
            const run_node: *Node = @fieldParentPtr("data", action);
            const closure: *@This() = @alignCast(@fieldParentPtr("run_node", run_node));
            @call(.auto, cb, closure.arguments);
        }
        //
        fn deinitFn(node: *Node) void {
            const closure: *@This() = @alignCast(@fieldParentPtr("run_node", node));
            allocator_global.destroy(closure);
        }
    };

    const closure = allocator_global.create(Closure) catch |err| {
        println("Error could not create closure {any}\n ", .{err});
        unreachable;
    };
    closure.* = .{
        .arguments = args,
    };

    const id = time_out_ctx_registry.count() + 1;
    time_out_ctx_registry.put(id, &closure.run_node) catch |err| {
        println("Button Function Registry {any}\n", .{err});
    };

    if (isWasi) {
        Wasm.timeoutCtx(ms, id);
    } else {
        return;
    }
}

pub fn registerTimeout(ms: u32, cb: *const fn () void) void {
    const id = time_out_registry.count() + 1;
    time_out_registry.put(id, cb) catch |err| {
        println("Button Function Registry {any}\n", .{err});
    };
    if (isWasi) {
        Wasm.timeout(ms, id);
    } else {
        return;
    }
}

pub fn setCookie(cookie: []const u8) void {
    Wasm.setCookieWASM(cookie.ptr, cookie.len);
}

pub fn getCookies() []const u8 {
    const cookie = Wasm.getCookiesWASM();
    return std.mem.span(cookie);
}

pub fn getCookie(name: []const u8) ?[]const u8 {
    const cookie = Wasm.getCookieWASM(name.ptr, name.len);
    if (cookie == null) return null;
    return std.mem.span(cookie);
}
pub fn createCallback(cb: *const fn () void) void {
    continuations[callback_count] = cb;
}

pub const Clipboard = struct {
    pub fn copy(text: []const u8) void {
        if (isWasi) {
            Wasm.copyTextWasm(text.ptr, text.len);
        }
    }
    fn paste(_: []const u8) void {}
};
