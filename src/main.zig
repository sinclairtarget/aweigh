const std = @import("std");

const atrus = @import("atrus");

pub fn main() !void {
    // Prints to stderr, ignoring potential errors.
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    std.debug.print("libatrus version: {s}\n", .{atrus.version});
}
