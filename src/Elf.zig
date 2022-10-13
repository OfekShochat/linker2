const std = @import("std");
const mem = std.mem;
const fs = std.fs;
const elf = std.elf;

const StringTable = @import("string_table.zig").StringTable;
const ThreadPool = @import("ThreadPool.zig");
const Object = @import("Elf/Object.zig");
const Options = @import("Options.zig");
const Allocator = std.mem.Allocator;

const default_base_addr: u64 = 0x200000;

const Archive = struct {
    name: []const u8,
};

const Section = struct {
    name: []const u8,
};

const Elf = @This();

allocator: Allocator,
options: Options,

archives: std.ArrayListUnmanaged(Archive) = .{},
objects: std.ArrayListUnmanaged(Object) = .{},

header: elf.Elf64_Ehdr,

sections: std.MultiArrayList(Section),

strtab: StringTable(.strtab) = .{},
shstrtab: StringTable(.shstrtab) = .{},

text_sect_index: ?u16 = null,
got_sect_index: ?u16 = null,
symtab_sect_index: ?u16 = null,
strtab_sect_index: ?u16 = null,
shstrtab_sect_index: ?u16 = null,

locals: std.ArrayListUnmanaged(elf.Elf64_Sym) = .{},
globals: std.StringArrayHashMapUnmanaged(SymbolWithLoc) = .{},
unresolved: std.AutoArrayHashMapUnmanaged(u32, void) = .{},

const SymbolWithLoc = struct {
    index: usize,
    file: ?usize,
};

pub fn createEmpty(allocator: Allocator, options: Options) !*Elf {
    var self = try allocator.create(Elf);
    errdefer allocator.destroy(self);

    self.allocator = allocator;
    self.options = options;

    self.populateHeader();
    self.locals = .{};
    self.globals = .{};
    self.unresolved = .{};
    self.shstrtab = .{};
    self.sections = .{};
    self.strtab = .{};

    return self;
}

pub fn format(
    self: Elf,
    comptime fmt: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void {
    _ = fmt;
    _ = options;
    try writer.print("Elf{{ .strtab = {}, .shstrtab = {}, .sections = {any} }}", .{ self.strtab, self.shstrtab, self.sections });
}

pub fn open(allocator: Allocator, options: Options) !*Elf {
    var file = try options.wd.openFile(options.sub_path, .{});

    var self = allocator.create(Elf);
    errdefer allocator.destroy(self);

    self.file = file;
    self.allocator = allocator;

    try self.populateHeader();
    try self.populatePhdr();

    return self;
}

fn populateHeader(self: *Elf) void {
    var header = elf.Elf64_Ehdr{
        .e_ident = undefined,
        .e_type = elf.ET.EXEC, // TODO: switch on the output type from self.options.
        .e_machine = self.options.target.cpu_arch.?.toElfMachine(), // TODO: options (it would also be easier to do relocations and check those).
        .e_version = 1,
        .e_entry = 0,
        .e_phoff = @sizeOf(elf.Elf64_Ehdr),
        .e_shoff = 0,
        .e_flags = 0,
        .e_ehsize = @sizeOf(elf.Elf64_Ehdr),
        .e_phentsize = @sizeOf(elf.Elf64_Phdr),
        .e_phnum = 0,
        .e_shentsize = @sizeOf(elf.Elf64_Shdr),
        .e_shnum = 0,
        .e_shstrndx = 0,
    };
    // Magic
    mem.copy(u8, header.e_ident[0..4], "\x7fELF");
    // Class
    header.e_ident[4] = elf.ELFCLASS64;
    // Endianness
    header.e_ident[5] = elf.ELFDATA2LSB;
    // ELF version
    header.e_ident[6] = 1;
    // OS ABI, often set to 0 regardless of target platform
    // ABI Version, possibly used by glibc but not by static executables
    // padding
    mem.set(u8, header.e_ident[7..][0..9], 0);
    self.header = header;
}

fn populatePhdr(self: *Elf) void {
    const offset = @sizeOf(elf.Elf64_Ehdr);
    const size = @sizeOf(elf.Elf64_Phdr);
    self.phdr_seg_index = @intCast(u16, self.phdrs.items.len);
    try self.phdrs.append(self.allocator, .{
        .p_type = elf.PT_PHDR,
        .p_flags = elf.PF_R,
        .p_offset = offset,
        .p_vaddr = offset + default_base_addr,
        .p_paddr = offset + default_base_addr,
        .p_filesz = size,
        .p_memsz = size,
        .p_align = @alignOf(elf.Elf64_Phdr),
    });
}

pub fn write(self: Elf) !void {
    _ = self;
}

/// read data from file
fn parseShdr(self: *Elf, thread_pool: *ThreadPool) !void {
    _ = self;
    _ = thread_pool;
}
