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
pub const Event = @import("Event.zig");
const Canopy = @import("Canopy.zig");
const CSSGenerator = @import("CSSGenerator.zig");
const hashKey = utils.hashKey;
const Pool = @import("Pool.zig");
const mutateDomElementStyleString = @import("Element.zig").mutateDomElementStyleString;

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
const AllocText = ChainPure.AllocText;
const getStyle = @import("convertStyleCustomWriter.zig").getStyle;
const StyleCompiler = @import("convertStyleCustomWriter.zig");
pub const generateStyle = @import("convertStyleCustomWriter.zig").generateStyle;
const generateInputHTML = @import("grabInputDetails.zig").generateInputHTML;
const grabInputDetails = @import("grabInputDetails.zig");
const utils = @import("utils.zig");
// const createInput = grabInputDetails.createInput;
const getInputSize = grabInputDetails.getInputSize;
const getInputType = grabInputDetails.getInputType;
const getAriaLabel = utils.getAriaLabel;
pub const setGlobalStyleVariables = @import("convertStyleCustomWriter.zig").setGlobalStyleVariables;
pub const ThemeType = @import("convertStyleCustomWriter.zig").ThemeType;
const Theme = @import("theme");
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
pub var element_registry: std.AutoHashMap(u32, *Element) = undefined;

var serious_error: bool = false;

const Vapor = @This();
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
            Vapor.printlnErr("Cannot store non string or int float types", .{});
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
                Vapor.printlnErr("Cannot get non string or int float types", .{});
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

const EventHandler = struct {
    type: EventType,
    ctx_aware: bool = false,
    cb_opaque: *const anyopaque,
};

pub const EventHandlers = struct { handlers: std.ArrayListUnmanaged(EventHandler) };

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
    const args_ptr = try Vapor.allocator_global.create(Args);
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

    // 6. Create the VaporNode instance.
    const node_with_closure = try Vapor.allocator_global.create(CtxNode);
    node_with_closure.* = CtxNode{
        .closure = closure,
        // ... other node data
    };

    // Now you would create your VaporNode and put it in the registry.
    try Vapor.ctx_registry.put(id, node_with_closure);
    // ...
}

pub var btn_registry: std.AutoHashMap(u32, *const fn () void) = undefined;
pub var time_out_registry: std.AutoHashMap(u32, *const fn () void) = undefined;
pub var ctx_registry: std.AutoHashMap(u32, *Node) = undefined;
pub var time_out_ctx_registry: std.AutoHashMap(usize, *Node) = undefined;
pub var callback_registry: std.AutoHashMap(u32, *Node) = undefined;

pub const OpaqueNode = struct { data: struct { runFn: *const fn (*anyopaque) void } };
pub var opaque_registry: std.AutoHashMap(u32, *OpaqueNode) = undefined;
pub var fetch_registry: std.AutoHashMap(u32, *Kit.FetchNode) = undefined;
pub const EventNode = struct { cb: *const fn (*Event) void, ui_node: ?*UINode = null };
pub var events_callbacks: std.AutoHashMap(u32, EventNode) = undefined;
pub var nodes_with_events: std.AutoHashMap(u32, *UINode) = undefined;
pub var node_events_callbacks: std.AutoHashMap(u32, *CtxAwareEventNode) = undefined;
pub var events_inst_callbacks: std.AutoHashMap(u32, *EvtInstNode) = undefined;
pub var hooks_inst_callbacks: std.AutoHashMap(u32, *const fn (HookContext) void) = undefined;
pub var mounted_funcs: std.AutoHashMap(u32, *const fn () void) = undefined;
pub var on_end_funcs: std.array_list.Managed(*const fn () void) = undefined;
pub var on_commit_funcs: std.array_list.Managed(*const fn () void) = undefined;
pub var mounted_ctx_funcs: std.array_list.Managed(*Node) = undefined;
pub var created_funcs: std.AutoHashMap(u32, *const fn () void) = undefined;
pub var updated_funcs: std.AutoHashMap(u32, *const fn () void) = undefined;
pub var destroy_funcs: std.AutoHashMap(u32, *const fn () void) = undefined;
const RemovedNode = struct { uuid: []const u8, index: usize };
pub var removed_nodes: std.array_list.Managed(RemovedNode) = undefined;
pub var added_nodes: std.array_list.Managed(RenderCommand) = undefined;
pub var dirty_nodes: std.array_list.Managed(RenderCommand) = undefined;
// Potential nodes is an set to chekc if the potential nodes that are either shifted or removed on in the dom currently
// instead of an active set, we only record the nodes that are different from the current tree
pub var potential_nodes: std.StringHashMap(void) = undefined;
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

pub fn getFrameAllocator() std.mem.Allocator {
    return frame_arena.getFrameAllocator();
}

pub fn frameList(comptime T: type) std.array_list.Managed(T) {
    var array_list: std.array_list.Managed(T) = undefined;
    array_list = std.array_list.Managed(T).init(frame_arena.getFrameAllocator());
    return array_list;
}

pub fn getPersistentAllocator() std.mem.Allocator {
    return frame_arena.persistentAllocator();
}

pub fn getRouteAllocator() std.mem.Allocator {
    return frame_arena.getRouteAllocator();
}

pub fn getFrameArena() *FrameAllocator {
    return &frame_arena;
}

pub const VaporConfig = struct {
    screen_width: f32,
    screen_height: f32,
    allocator: std.mem.Allocator,
    page_node_count: usize = 256,
};

pub var pool: Pool = undefined;
pub fn init(config: VaporConfig) void {
    browser_width = config.screen_width;
    browser_height = config.screen_height;
    page_node_count = config.page_node_count;
    allocator_global = config.allocator;

    // Init the frame allocator;
    // This adds 500B
    frame_arena = FrameAllocator.init(config.allocator, page_node_count);
    // The persistent allocator is used for the Initialization of the registries as these persist over the lifetime of the program.
    var allocator = frame_arena.persistentAllocator();

    // Init Router // This adds 1kb
    router.init(&allocator) catch |err| {
        println("Could not init Router {any}\n", .{err});
    };

    // >1kb
    initPackedData(allocator);
    initPools(allocator);
    // 20kb
    initRegistries(allocator);
    // >1kb
    initCalls(allocator);
    // >1kb
    initContextData(allocator);
    UIContext.class_map = std.StringHashMap(Pool.StringData).init(allocator);

    // UIContext.ui_nodes = allocator.alloc(UINode, config.page_node_count) catch unreachable;

    // Init string pool adds 1kb
    pool = Pool.init(allocator, page_node_count) catch |err| {
        printlnErr("Could not init Pool {any}\n", .{err});
        unreachable;
    };
    pool.initFreelist();
    KeyGenerator.initWriter();
    // UIContext.debugPrintUINodeLayout();

    // All this below adds 3kb
    animations = std.StringHashMap(Animation).init(allocator);
    component_subscribers = std.array_list.Managed(*Rune.ComponentNode).init(allocator);
    removed_nodes = std.array_list.Managed(RemovedNode).init(allocator);
    added_nodes = std.array_list.Managed(RenderCommand).init(allocator);
    dirty_nodes = std.array_list.Managed(RenderCommand).init(allocator);
    potential_nodes = std.StringHashMap(void).init(allocator);
    // grain_subs = std.array_list.Managed(*GrainStruct.ComponentNode).init(allocator);
    classes_to_add = std.array_list.Managed(Class).init(allocator);
    classes_to_remove = std.array_list.Managed(Class).init(allocator);
    element_registry = std.AutoHashMap(u32, *Element).init(allocator);

    // Init Context Data
    // Reconciler.node_map = std.StringHashMap(usize).init(allocator);

    // Reconciliation styles dedupe // this is 2kb
    // UIContext.nodes = allocator.alloc(*UINode, config.page_node_count) catch unreachable;

    UIContext.indexes = std.AutoHashMap(u32, usize).init(allocator);
    // @memset(UIContext.common_nodes, 0);
    // for (0..continuations.len) |i| {
    //     continuations[i] = null;
    // }

    // this adds 7kb
    _ = getStyle(null); // 16kb
    _ = getVisualStyle(null, 0); // 20kb
    if (isWasi) {
        _ = Bridge.getRenderTreePtr();
    }
    // _ = getFocusStyle(null); // 20kb
    // _ = getFocusWithinStyle(null); // 20kb
    // this adds 4kb
    // _ = createInput(null); // 20kb
    // _ = getInputType(null); // 5kb
    // _ = getInputSize(null); // 5kb
    _ = getAriaLabel(null); // < 1kb

    if (build_options.enable_debug) {
        // eventListener(.keydown, Debugger.onKeyPress);
        printlnColor("-----------Debug Mode----------", .{}, .hex("#F6820C"));
    }
    // printDebug() catch unreachable;
}

fn initRegistries(persistent_allocator: std.mem.Allocator) void {
    btn_registry = std.AutoHashMap(u32, *const fn () void).init(persistent_allocator);
    time_out_registry = std.AutoHashMap(u32, *const fn () void).init(persistent_allocator);
    ctx_registry = std.AutoHashMap(u32, *Node).init(persistent_allocator); // this adds like 30kb
    time_out_ctx_registry = std.AutoHashMap(usize, *Node).init(persistent_allocator);
    callback_registry = std.AutoHashMap(u32, *Node).init(persistent_allocator);
    opaque_registry = std.AutoHashMap(u32, *OpaqueNode).init(persistent_allocator);
    fetch_registry = std.AutoHashMap(u32, *Kit.FetchNode).init(persistent_allocator);
}

fn initCalls(persistent_allocator: std.mem.Allocator) void {
    events_callbacks = std.AutoHashMap(u32, EventNode).init(persistent_allocator);
    nodes_with_events = std.AutoHashMap(u32, *UINode).init(persistent_allocator);
    node_events_callbacks = std.AutoHashMap(u32, *CtxAwareEventNode).init(persistent_allocator);
    events_inst_callbacks = std.AutoHashMap(u32, *EvtInstNode).init(persistent_allocator);
    hooks_inst_callbacks = std.AutoHashMap(u32, *const fn (HookContext) void).init(persistent_allocator);
    mounted_funcs = std.AutoHashMap(u32, *const fn () void).init(persistent_allocator);
    on_end_funcs = std.array_list.Managed(*const fn () void).init(persistent_allocator);
    on_commit_funcs = std.array_list.Managed(*const fn () void).init(persistent_allocator);
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

/// Force rerender forces the entire dom tree to check props of all dynamic and pure components and rerender the ui
/// since Vapor is built with zig and wasm, checking all props of 10000s of nodes and ui components is cheap
/// feel free to abuse force, its essentially a global signal
pub fn cycle() void {
    if (isWasi) {
        Vapor.global_rerender = true;
        // render_phase = .generating;
        Wasm.requestRerenderWasm();
    }
    // } else if (render_phase == .committing) {
    //     const route_ptr = frame_arena.getFrameAllocator().dupeZ(u8, current_route) catch unreachable;
    //     defer frame_arena.getFrameAllocator().free(route_ptr);
    //     renderCycle(route_ptr.ptr);
    // }
}

// /// Force rerender forces the entire dom tree to check props of all dynamic and pure components and rerender the ui
// /// since Vapor is built with zig and wasm, checking all props of 10000s of nodes and ui components is cheap
// /// feel free to abuse force, its essentially a global signal
// pub fn cycleGrain() void {
//     Vapor.grain_rerender = true;
//     Vapor.println("Grain rerender", .{});
//     Wasm.requestRerenderWasm();
// }

/// Force rerender forces the entire dom tree to check props and rerender the entire ui
/// since Vapor is built with zig and wasm, checking all props of 10000s of nodes and ui components is cheap
/// feel free to abuse force, its essentially a global signal
pub fn forceEverything() void {
    if (isWasi) {
        Vapor.rerender_everything = true;
        Vapor.global_rerender = true;
        Wasm.requestRerenderWasm();
    }
}

/// This function adds the route to the tether radix tree.
/// Deinitializes the tether instance recursively calls routes deinit routes from radix tree
/// # Parameters:
/// - `vapor`: *Vapor,
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
            // Vapor.println("Render time {any}", .{nowMs() - time});
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
var current_route: []const u8 = "";
var previous_route: []const u8 = "";
var render_page: *const fn () void = undefined;
pub var generator: CSSGenerator = undefined;
const RenderPhase = enum {
    generating, // Building VDOM
    committing, // Running commit hooks
    applying, // Applying to real DOM
    idle, // Done
};
// pub var render_phase: RenderPhase = .idle;
pub fn renderCycle(route_ptr: [*:0]u8) void {
    frame_arena.beginFrame(); // For double-buffered approach
    const start = nowMs();
    const route = std.mem.span(route_ptr);

    if (!std.mem.eql(u8, current_route, route)) {
        // We need to start a new route allocator
        // otherwise we are on the same route
        frame_arena.beginRoute();
    }

    current_route = route;
    removed_nodes.clearRetainingCapacity();
    added_nodes.clearRetainingCapacity();
    dirty_nodes.clearRetainingCapacity();
    potential_nodes.clearRetainingCapacity();
    node_events_callbacks.clearRetainingCapacity();
    events_callbacks.clearRetainingCapacity();
    nodes_with_events.clearRetainingCapacity();
    UIContext.indexes.clearRetainingCapacity();

    var ctx_itr = ctx_registry.iterator();
    while (ctx_itr.next()) |entry| {
        _ = entry.value_ptr.*;
    }
    ctx_registry.clearRetainingCapacity();

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

    new_ctx.root.?.uuid = old_ctx.root.?.uuid;

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

    const generation_start = nowMs();
    findResetLayout();
    // This calls the render tree, with render_page as the root function call
    // First it traverses the layouts calling them in order, and then it calls the render_page
    callNestedLayouts(); // 4.5ms
    Timer.generation_time = nowMs() - generation_start;
    // Debugger.render();

    on_commit_funcs.clearRetainingCapacity();

    const reconcile_start = nowMs();
    Reconciler.reconcile(old_ctx, new_ctx); // 3kb
    Timer.reconcile_time = nowMs() - reconcile_start;
    // We generate the render commands tree
    const commit_start = nowMs();
    endPage(new_ctx);
    Timer.commit_time = nowMs() - commit_start;
    // Vapor.println("Total {d}", .{frame_arena.queryBytesUsed()});
    if (!std.mem.eql(u8, previous_route, current_route)) {
        Vapor.has_dirty = true;
    }

    // Replace old context with new context in the map
    clean_up_ctx = old_ctx;
    Timer.total_time = nowMs() - start;
    // _ = frame_arena.queryNodes();
    if (router.updateRouteTree(old_route.path, new_ctx)) {
        return;
    }

    allocator_global.free(route); // return host‑allocated buffer
    if (build_options.enable_debug and build_options.debug_level == .all) {
        frame_arena.printStats();
    }
    previous_route = current_route;
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

pub fn end(vapor: *Vapor) !void {
    const watch_paths: []const []const u8 = &.{"src/routes"};
    for (watch_paths) |watch_path| {
        var dir = try std.fs.cwd().openDir(watch_path, .{ .iterate = true });
        defer dir.close();

        var walker = try dir.walk(vapor.allocator.*);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            const path = try std.fs.path.join(vapor.allocator.*, &.{ watch_path, entry.path });
            println("{s}\n", .{path});
        }
    }
}

// Okay so we need to change the node in the tree depending on the page route
// for example we add the commads tree to the router tree
const Path = union(enum) {
    route: []const u8,
    src: std.builtin.SourceLocation,
};
pub fn Page(path: Path, page: fn () void, page_deinit: ?fn () void) void {
    const allocator = Vapor.frame_arena.persistentAllocator();
    var full_route: []const u8 = "";
    var itr: std.mem.TokenIterator(u8, std.mem.DelimiterType.scalar) = undefined;
    if (path == .src) {
        full_route = path.src.file[0..path.src.file.len];
        itr = std.mem.tokenizeScalar(u8, full_route[7..], '/');
    } else {
        full_route = path.route;
        itr = std.mem.tokenizeScalar(u8, full_route, '/');
    }
    var buf = std.array_list.Managed(u8).init(allocator);

    buf.appendSlice("/root") catch |err| {
        println("Allocator ran out of space {any}\n", .{err});
        return;
    };

    var file_name: []const u8 = "";
    blk: while (itr.next()) |sub| {
        if (itr.peek() == null and path == .src) {
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
    Vapor.printlnSrc("Callback id {}", .{cb_id}, @src());
    // if (events_callbacks.remove(cb_id)) {
    //     return true;
    // }
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

/// This function creates an focuses on the element.
/// # Parameters:
/// - `element_id`: []const u8,
///
/// # Returns:
/// void
pub inline fn focused(element_uuid: []const u8) bool {
    return Wasm.elementFocusedWasm(element_uuid.ptr, element_uuid.len);
}

pub fn attachEventCtxCallback(ui_node: *UINode, event_type: EventType, cb: anytype, args: anytype) !void {
    const onid = hashKey(ui_node.uuid);

    const Args = @TypeOf(args);
    const Closure = struct {
        arguments: Args,
        event_type: EventType,
        ui_node: *UINode,
        run_node: Vapor.CtxAwareEventNode = .{ .data = .{ .runFn = runFn } },
        fn runFn(data: *const Vapor.CtxAwareEvent) void {
            const run_node: *const Vapor.CtxAwareEventNode = @fieldParentPtr("data", data);
            const closure: *const @This() = @alignCast(@fieldParentPtr("run_node", run_node));
            _ = Vapor.elementInstEventListener(closure.ui_node.uuid, closure.event_type, closure.arguments, cb);
        }
    };

    const closure = Vapor.getFrameAllocator().create(Closure) catch |err| {
        println("Error could not create closure {any}\n ", .{err});
        unreachable;
    };

    closure.* = .{
        .ui_node = ui_node,
        .arguments = args,
        .event_type = event_type,
    };

    if (ui_node.event_handlers) |*handlers| {
        handlers.handlers.ensureUnusedCapacity(frame_arena.getFrameAllocator(), 1) catch |err| {
            printlnSrcErr("Event Callback Error: {any}\n", .{err}, @src());
            return error.EventCallbackError;
        };
        handlers.handlers.appendAssumeCapacity(.{ .type = event_type, .cb_opaque = @ptrCast(@alignCast(&closure.run_node)), .ctx_aware = true });
    } else {
        var handlers = std.ArrayListUnmanaged(EventHandler).initCapacity(frame_arena.getFrameAllocator(), 1) catch |err| {
            printlnSrcErr("Event Callback Error: {any}\n", .{err}, @src());
            return error.EventCallbackError;
        };
        handlers.appendBounded(.{ .type = event_type, .cb_opaque = @ptrCast(@alignCast(&closure.run_node)), .ctx_aware = true }) catch |err| {
            println("Event Callback Error: {any}\n", .{err});
            return error.EventCallbackError;
        };
        ui_node.event_handlers = EventHandlers{ .handlers = handlers };
    }

    nodes_with_events.put(onid, ui_node) catch |err| {
        println("Event Callback Error: {any}\n", .{err});
        return error.EventCallbackError;
    };
}

pub fn attachEventCallback(ui_node: *UINode, event_type: EventType, cb: *const fn (event: *Event) void) !void {
    const onid = hashKey(ui_node.uuid);

    if (ui_node.event_handlers) |*handlers| {
        handlers.handlers.ensureUnusedCapacity(frame_arena.getFrameAllocator(), 1) catch |err| {
            printlnSrcErr("Event Callback Error: {any}\n", .{err}, @src());
            return error.EventCallbackError;
        };
        handlers.handlers.appendAssumeCapacity(.{ .type = event_type, .cb_opaque = @ptrCast(@alignCast(cb)) });
    } else {
        var handlers = std.ArrayListUnmanaged(EventHandler).initCapacity(frame_arena.getFrameAllocator(), 1) catch |err| {
            printlnSrcErr("Event Callback Error: {any}\n", .{err}, @src());
            return error.EventCallbackError;
        };
        handlers.appendBounded(.{ .type = event_type, .cb_opaque = @ptrCast(@alignCast(cb)) }) catch |err| {
            println("Event Callback Error: {any}\n", .{err});
            return error.EventCallbackError;
        };
        ui_node.event_handlers = EventHandlers{ .handlers = handlers };
    }

    nodes_with_events.put(onid, ui_node) catch |err| {
        println("Event Callback Error: {any}\n", .{err});
        return error.EventCallbackError;
    };
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
    ui_node: *UINode,
    event_type: types.EventType,
    cb: *const fn (event: *Event) void,
) ?usize {
    var onid = hashKey(ui_node.uuid);
    onid +%= @intFromEnum(event_type);
    events_callbacks.put(onid, .{ .cb = cb, .ui_node = ui_node }) catch |err| {
        println("Event Callback Error: {any}\n", .{err});
    };

    const event_type_str = std.enums.tagName(types.EventType, event_type) orelse return null;
    Wasm.createElementEventListener(ui_node.uuid.ptr, ui_node.uuid.len, event_type_str.ptr, event_type_str.len, onid);
    return onid;
}

pub const EvtInst = struct {
    evt_cb: EvtInstProto,
    deinit: EvtInstNodeProto,
};

pub const EvtInstProto = *const fn (*EvtInst, *Event) void;
pub const EvtInstNodeProto = *const fn (*EvtInstNode) void;

pub const EvtInstNode = struct { data: EvtInst };

pub const CtxAwareEventNode = struct { data: CtxAwareEvent };

pub const CtxAwareEvent = struct {
    runFn: CtxAwareEventNodeProto,
};

pub const CtxAwareEventNodeProto = *const fn (*const CtxAwareEvent) void;

pub inline fn elementInstEventListener(
    element_uuid: []const u8,
    event_type: types.EventType,
    arguments: anytype,
    cb: anytype,
) ?usize {
    const Args = @TypeOf(arguments);
    const EvtClosure = struct {
        arguments: Args,
        evt_node: EvtInstNode = .{ .data = .{ .evt_cb = runFn, .deinit = deinitFn } },

        fn runFn(evt_inst: *EvtInst, evt: *Event) void {
            const evt_node: *EvtInstNode = @fieldParentPtr("data", evt_inst);
            const closure: *@This() = @alignCast(@fieldParentPtr("evt_node", evt_node));
            @call(.auto, cb, .{ evt, closure.arguments });
        }
        fn deinitFn(_: *EvtInstNode) void {
            // const closure: *@This() = @alignCast(@fieldParentPtr("evt_node", evt_node));
            // Vapor.allocator_global.destroy(closure);
        }
    };

    const evt_closure = Vapor.frame_arena.getFrameAllocator().create(EvtClosure) catch |err| {
        println("Error could not create closure {any}\n ", .{err});
        unreachable;
    };
    evt_closure.* = .{
        .arguments = arguments,
    };

    var onid = hashKey(element_uuid);
    onid +%= @intFromEnum(event_type);
    events_inst_callbacks.put(onid, &evt_closure.evt_node) catch |err| {
        println("Event Callback Error: {any}\n", .{err});
    };

    const event_type_str = std.enums.tagName(types.EventType, event_type) orelse return null;
    Wasm.createElementEventInstListener(element_uuid.ptr, element_uuid.len, event_type_str.ptr, event_type_str.len, onid);
    return onid;
}

pub const HookInst = struct {
    hook_cb: HookInstProto,
};

pub const HookInstProto = *const fn (*HookInst) void;
pub const HookInstNodeProto = *const fn (*HookInstNode) void;

pub const HookInstNode = struct { data: HookInst };

pub const HookContext = struct {
    from_path: []const u8,
    to_path: []const u8,
    params: std.StringHashMap([]const u8),
    query: std.StringHashMap([]const u8),
};

pub const HookType = enum(u8) {
    before = 0,
    after = 1,
};

/// cb(Self)
pub inline fn registerHook(
    url: []const u8,
    cb: anytype,
    hook_type: HookType,
) ?usize {
    const id = hooks_inst_callbacks.count();
    hooks_inst_callbacks.put(id, cb) catch |err| {
        println("Event Callback Error: {any}\n", .{err});
    };

    Wasm.createHookWASM(url.ptr, url.len, id, @intFromEnum(hook_type));
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
    events_callbacks.put(id, .{ .cb = cb, .ui_node = null }) catch |err| {
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
    if (node.children) |children| {
        for (children.items) |child| {
            markChildrenDirty(child);
        }
    }
}
// The first node needs to be marked as false always
pub fn markChildrenNotDirty(node: *UINode) void {
    if (node.parent != null) {
        node.dirty = false;
    }
    if (node.children) |children| {
        for (children.items) |child| {
            markChildrenNotDirty(child);
        }
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
    // Vapor.btn_registry.clearRetainingCapacity();
    // Vapor.mounted_funcs.clearRetainingCapacity();

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
    // the reason the vapor-debugger gets remvoed is the new ui tree does not include it;

    // const valid_route = replace_dash(current_route) catch unreachable;
    // defer allocator_global.free(valid_route);

    writer.print("\"{s}\":", .{current_route}) catch unreachable;
    writer.writeAll("{\n") catch unreachable;
    printStaticTextNode(new_ctx.root.?);
    writer.writeAll("}\n") catch unreachable;
}

pub fn printUITree(node: *UINode) void {
    if (node.dirty) {
        println("UI: {s}", .{node.uuid});
    }
    if (node.children) |children| {
        for (children.items) |child| {
            printUITree(child);
        }
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

fn collectComponentIds(node: *UINode, selected_type: ElementType, component_ids: *std.array_list.Managed([]const u8)) void {
    if (node.type == selected_type) {
        component_ids.append(node.uuid) catch unreachable;
    }
    if (node.children == null) return;
    for (node.children.?.items) |child| {
        collectComponentIds(child, selected_type, component_ids);
    }
}

pub fn queryComponentIds(target_type: ElementType) ![][]const u8 {
    const root = current_ctx.root orelse return error.NoTree;
    var component_ids = std.array_list.Managed([]const u8).init(allocator_global);
    collectComponentIds(root, target_type, &component_ids);
    return try component_ids.toOwnedSlice();
}

fn findNodeByUUID(node: *UINode, uuid: []const u8) UINode {
    if (std.mem.eql(u8, node.uuid, uuid)) {
        return node.*;
    }
    if (node.children == null) return;
    for (node.children.?.items) |child| {
        collectComponentIds(child, uuid);
    }
}

pub fn queryByUUID(uuid: []const u8) !UINode {
    const root = current_ctx.root orelse return error.NoTree;
    const node = findNodeByUUID(root, uuid);
    return node;
}

pub fn mutateById(uuid: []const u8, attribute: []const u8, value: []const u8) void {
    mutateDomElementStyleString(uuid.ptr, uuid.len, attribute.ptr, attribute.len, value.ptr, value.len);
}

pub const Bounds = struct {
    top: f32 = 0,
    left: f32 = 0,
    right: f32 = 0,
    bottom: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,
};

pub fn getComponentBounds(uuid: []const u8) ?Bounds {
    const bounds_ptr = if (isWasi) blk: {
        break :blk Wasm.getBoundingClientRectWasm(uuid.ptr, uuid.len);
    } else {
        return null;
    };

    return Bounds{
        .top = bounds_ptr[0],
        .left = bounds_ptr[1],
        .right = bounds_ptr[2],
        .bottom = bounds_ptr[3],
        .width = bounds_ptr[4],
        .height = bounds_ptr[5],
    };
}

fn iterateChildren(node: *UINode) void {
    if (node.state_type == .pure) {
        const pure_node = pure_tree.createNode(node) catch return;
        Vapor.pure_tree.openNode(pure_node) catch return;
    }

    if (node.state_type == .err) {
        const error_node = error_tree.createNode(node) catch return;
        Vapor.error_tree.openNode(error_node) catch return;
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
    has_children_offset: u32,
    hash_offset: u32,
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
    .has_children_offset = @offsetOf(RenderCommand, "has_children"),
    .hash_offset = @offsetOf(RenderCommand, "hash"),
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
        const buf_with_src = std.fmt.allocPrint(allocator_global, "[Vapor] [%cERROR%c] {s}", .{buf[0..]}) catch return;
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
        const buf_with_src = std.fmt.allocPrint(allocator_global, "[Vapor] [%c{s}:{d}%c]\n[Vapor] [ERROR] {s}", .{ src.file, src.line, buf[0..] }) catch return;
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
    const buf_with_src = std.fmt.allocPrint(allocator_global, "[Vapor] [%c{s}%c] {s}", .{ title, buf[0..] }) catch return;
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
    const buf_with_src = std.fmt.allocPrint(allocator_global, "[Vapor] [%cALLOC%c] {s}", .{buf[0..]}) catch return;
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

pub fn printDebug() !void {
    // std.debug.print("Hello World\n", .{});
    // const addr: std.builtin.StackTrace = @errorReturnTrace().?.*;
    // for (addr.instruction_addresses) |_addr| {
    //     std.debug.print("    0x{d}\n", .{_addr});
    // }
    var buffer_debug: [512]u8 = undefined;
    var stream = std.Io.Writer.fixed(&buffer_debug);
    const writer_debug = &stream;
    // // var writer_debug = std.fs.File.writer(std.fs.File.stderr(), &buffer_debug).interface;
    // // _ = addr.format(&writer_debug) catch unreachable;
    // std.debug.print("{*}", .{&addr});
    std.debug.dumpCurrentStackTraceToWriter(@returnAddress(), writer_debug) catch unreachable;
    std.debug.print("Called from: 0x{s}\n", .{writer_debug.buffer[0..writer_debug.end]});

    // try std.debug.dumpCurrentStackTraceToWriter(@returnAddress(), &writer_debug);
    // Vapor.print("{any}", .{@returnAddress()});
    // try writer_debug.print("Error\n", .{});
    // try writer_debug.flush();
    // Let's say you have an address you want to inspect
    // 1. Get the standard error writer (maps to console.error() in browser)
    // const stderr = std.io.getStdErr().writer();

    // 2. Just print the address. The browser will symbolicate it for you.
    //    You don't need printSourceAtAddress.

    // 3. Or, if you just want a full stack trace:
    //    Zig's built-in stack dumper will print the raw addresses.
    //    The browser DevTools will automatically convert this
    //    trace into file:line locations.
    // const ret_addr = @returnAddress();
    // const debug_info = std.debug.getSelfDebugInfo() catch @panic("Could not get debug_info");
    // // 1) Prepare a big enough buffer on the stack
    // var buffer_debug: [512]u8 = undefined;
    // var stream = std.Io.Writer.fixed(&buffer_debug);
    // const writer_debug = &stream;
    //
    // // 3) Call printSourceAtAddress into *your*writer_debug
    // const tty = std.io.tty.detectConfig(std.fs.File.stderr());
    // try std.debug.printSourceAtAddress(debug_info, writer_debug, ret_addr, tty);
    // std.debug.dumpStackTrace();
    // const outSlice = buffer_debug[0..stream.end];
    // const start = std.mem.indexOf(u8, outSlice, "src") orelse std.mem.indexOf(u8, outSlice, "std") orelse 0;
    // const src = buffer_debug[start..stream.end];
    // Vapor.print("{s}", .{src});
    // var sections = std.mem.splitScalar(u8, src, ':');
    // var indents = std.mem.splitScalar(u8, src, '\n');
    // const file_name = sections.next() orelse return;
    // const line = sections.next() orelse return;
    // const u32_line_n: u32 = std.fmt.parseInt(u32, line, 10) catch return;
    // _ = indents.next().?;
    // const fn_name = indents.next().?;
    // const err_str = try std.fmt.allocPrint(reverb.arena.*, "{any}", .{error.MethodNotSupported});
    // const function_name = try std.fmt.allocPrint(reverb.arena.*, "{s}", .{fn_name[0 .. fn_name.len - 2]});
    // const file_name_alloc = try std.fmt.allocPrint(reverb.arena.*, "{s}", .{file_name});
}

pub fn print(
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

    callback_registry.put(hashKey(name), &closure.run_node) catch |err| {
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

pub fn onEnd(callback: *const fn () void) void {
    on_end_funcs.append(callback) catch |err| {
        printlnErr("Button Function Registry {any}\n", .{err});
    };
}

/// This hook takes a function callback and calls it after the virtual dom has been created
/// WARNING: This is a dangerous hook, and can cause infinite loops
pub fn onCommit(callback: *const fn () void) void {
    on_commit_funcs.append(callback) catch |err| {
        printlnErr("Button Function Registry {any}\n", .{err});
    };
}
