const std = @import("std");
const string_table = @import("string_table.zig");
const Options = @import("Options.zig");
const Elf = @import("Elf.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var allocator = gpa.allocator();

    var args_iterator = std.process.args();
    const options = try Options.parseArgs(allocator, &args_iterator);
    std.log.info("{}", .{options});

    var elf = try Elf.createEmpty(allocator, options);
    std.log.info("{}", .{elf});
}
