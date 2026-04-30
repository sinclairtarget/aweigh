//! This is a small CLI program that simply reads a MyST Markdown file
//! (specified by path or piped to stdin), parses it, walks the AST, and prints
//! out all links.

const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const atrus = @import("atrus");

pub fn main() !void {
    // Set up stdout and allocator
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    // Process CLI args
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

    // Set up reader for input file
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

    // Parse document and print links
    try printLinks(allocator, reader, stdout);
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

fn printLinks(alloc: Allocator, in: *Io.Reader, out: *Io.Writer) !void {
    std.debug.print("libatrus version: {s}\n", .{atrus.version});

    const root_node = try atrus.parse(alloc, in, .{ .parse_level = .post });
    try handleNode(root_node, out);
}

fn handleNode(node: *atrus.ast.Node, out: *Io.Writer) !void {
    switch (node.tag) {
        inline .root, .paragraph, .block, .emphasis, .strong, .blockquote,
        .subscript, .superscript, .admonition_title, .caption, .myst_directive,
        .myst_role, .container, .admonition => |node_type| {
            const n = @field(node.payload, @tagName(node_type));
            const sliced = n.children[0..n.n_children];
            for (sliced) |child| {
                try handleNode(child, out);
            }
        },
        .link => {
            const n = node.payload.link;
            try out.print("{s}\n", .{n.url});
        },
        else => return,
    }
}
