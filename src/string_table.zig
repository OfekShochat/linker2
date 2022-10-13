const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;

const StringIndexAdapter = std.hash_map.StringIndexAdapter;
const StringIndexContext = std.hash_map.StringIndexContext;

pub fn StringTable(comptime log_scope: @Type(.EnumLiteral)) type {
    return struct {
        const log = std.log.scoped(log_scope);

        buffer: std.ArrayListUnmanaged(u8) = .{},
        table: std.ArrayListUnmanaged(usize) = .{},

        pub fn deinit(self: *@This(), allocator: Allocator) void {
            self.buffer.deinit(allocator);
            self.table.deinit(allocator);
        }

        /// empties the string table
        pub fn toOwnedSlice(self: @This()) []const u8 {
            return self.buffer.toOwnedSlice();
        }

        pub fn insert(self: *@This(), allocator: Allocator, str: []const u8) !usize {
            try self.buffer.ensureUnusedCapacity(allocator, str.len + 1);
            const new_off = self.buffer.items.len + str.len;

            self.buffer.appendSliceAssumeCapacity(str);
            self.buffer.appendAssumeCapacity(0);

            try self.table.append(allocator, new_off);

            return new_off;
        }

        pub fn get(self: @This(), off: usize) ?[:0]const u8 {
            if (off >= self.buffer.items.len) return null;
            return mem.sliceTo(@ptrCast(*[:0]const u8, self.buffer.items.ptr + off), 0);
        }
    };
}
