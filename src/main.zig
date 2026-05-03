//! This is a small CLI program that reads a MyST Markdown file (specified by
//! path or piped to stdin), parses it, transforms the AST by adding the anchor
//! emoji to all link text, then renders everything out as HTML.

const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const atrus = @import("atrus");

pub fn main() !void {
    // Set up stdout and allocator. Standard Zig stuff.
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Process CLI args. Standard Zig stuff.
    const args = try std.process.argsAlloc(allocator);
    if (args.len > 2) {
        printUsage();
        die("Too many arguments.", .{});
    }

    if (args.len > 1) {
        if (std.mem.eql(u8, "-h", args[1])
            or std.mem.eql(u8, "--help", args[1])) {
            printUsage();
            return;
        }
    }

    // Set up reader for input file. `atrus.parse()` below takes an *Io.Reader
    // and not a string as input.
    //
    // Here we create an input stream that points to either stdin or the named
    // file on disk, depending on the args passed.
    const file = blk: {
        if (args.len > 1) {
            const filepath = args[1];
            break :blk std.fs.cwd().openFile(filepath, .{}) catch |err| {
                switch (err) {
                    error.FileNotFound => {
                        die("File \"{s}\" could not be found.", .{filepath});
                    },
                    else => return err,
                }
            };
        } else {
            break :blk std.fs.File.stdin();
        }
    };
    defer file.close();

    var input_buffer: [1024]u8 = undefined;
    var reader_impl = file.reader(&input_buffer);
    const reader = &reader_impl.interface;

    // Print library version.
    std.debug.print("libatrus version: {s}\n", .{atrus.version});

    // Parse MyST document.
    var root_node = try atrus.parse(allocator, reader, .{
        // Here we specify a parse level of "pre", overriding the default parse
        // level of "post". This gives us access to the AST before the standard
        // post-processing transforms have been applied. We make a call to
        // `atrus.transform()` below to apply those transforms after we've made
        // our modification to the AST.
        .parse_level = .pre,
    });

    // Custom transform operation on the AST.
    // We do our custom transformation here before calling `atrus.transform()`.
    // We do this because we are inserting nodes into the AST here but still
    // want those nodes to be processed by the standard transformations.
    root_node = try myCustomTransform(allocator, root_node);

    // This applies the remaining standard transformations on the AST (e.g.
    // resolving of references, unwrapping of directives/roles).
    root_node = try atrus.transform(allocator, root_node, .{});

    // This renders the AST as HTML.
    try atrus.renderHTML(root_node, stdout, .{});

    try stdout.flush();
}

fn printUsage() void {
    const usage =
        \\Usage: aweigh [FILEPATH]
        \\
        \\If no filepath is given, input is read from stdin.
        \\
        \\Flags:
        \\  -h|--help  Output this help text.
        \\
    ;

    std.debug.print("{s}", .{usage});
}

fn die(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print(fmt ++ "\n", args);
    std.process.exit(1);
}

/// In our custom transform, we add an extra text node as the first child of
/// all link nodes found in the AST.
fn myCustomTransform(
    alloc: Allocator,
    node: *atrus.ast.Node,
) !*atrus.ast.Node {
    const anchor_prefix = "⚓ ";

    // Here we use a fancy Zig-ism that allows us to divide our node type union
    // into disjoint sets of node types along some dimension. In this case, we
    // want to handle nodes with children differently from nodes without
    // children.
    //
    // See https://mitchellh.com/writing/zig-comptime-tagged-union-subset for
    // more on this pattern.
    switch (node.hasChildren()) {
        .no => {}, // Ignore all leaf nodes.
        .yes => |branch_node| switch (branch_node) {
            // This switch is exaustive over only those node types that can
            // have children.
            .link => |n| {
                // Create new text node.
                const text_node = try alloc.create(atrus.ast.Node);
                text_node.* = .{
                    .text = .{
                        // All strings in the AST must be null-terminated.
                        // This makes them C-ABI-compatible.
                        .value = try alloc.dupeZ(u8, anchor_prefix),
                    },
                };

                // Create new slice holding the existing children plus the
                // new one.
                const new_len = n.children.len + 1;
                const new_children = try alloc.alloc(
                    *atrus.ast.Node,
                    new_len,
                );
                new_children[0] = text_node;
                for (n.children, 1..) |child, i| {
                    new_children[i] = child;
                }

                // Replace the old slice.
                alloc.free(n.children);
                n.children = new_children;
            },
            // "inline else" is one way Zig does compile-time polymorphism.
            inline else => |n| {
                // For nodes with children, apply transformation
                // recursively.
                for (n.children, 0..) |child, i| {
                    n.children[i] = try myCustomTransform(alloc, child);
                }
            }
        },
    }

    return node;
}
