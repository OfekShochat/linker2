const builtin = @import("builtin");
const std = @import("std");
const log = std.log.scoped(.options_parser);
const mem = std.mem;
const fs = std.fs;

const ArgIterator = std.process.ArgIterator;
const CrossTarget = std.zig.CrossTarget;
const Allocator = std.mem.Allocator;
const Dir = fs.Dir;

const Options = @This();

inputs: std.ArrayListUnmanaged([]const u8) = .{},
entry: []const u8 = "_start",
target: CrossTarget,
output: []const u8 = "a.out",
directory: Dir,

pub fn parseArgs(allocator: Allocator, args: *ArgIterator) !Options {
    var self = Options{
        .directory = fs.cwd(),
        .target = CrossTarget.fromTarget(builtin.target),
    };

    _ = args.skip(); // skip our path.

    while (args.next()) |part| {
        if (mem.eql(u8, part, "-o")) {
            self.output = args.next() orelse {
                log.err("Expected an output path after `-o`.", .{});
                return error.Unexpected;
            };
        } else {
            try self.inputs.append(allocator, part);
        }
    }

    return self;
}

pub fn format(
    self: Options,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;

    try writer.print("Options{{ .inputs = {{ ", .{});
    for (self.inputs.items) |input| {
        try writer.print("\"{s}\", ", .{input});
    }

    try writer.print("}}, .entry = {s}, .target = {}, .output = {s}, .directory = {} }}", .{
        self.entry,
        self.target.cpu_arch.?,
        self.output,
        self.directory,
    });
}
