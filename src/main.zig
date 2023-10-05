const std = @import("std");
const clap = @import("clap");
const ArrayList = std.ArrayList;
const fs = std.fs;

pub const zline = struct {
    allocator: std.mem.Allocator,
    paths: ArrayList([]const u8),
    dirs: ArrayList(fs.IterableDir.Entry),
    files: ArrayList(fs.IterableDir.Entry),

    pub fn init(allocator: std.mem.Allocator) !zline {
        return zline{
            .allocator = allocator,
            .paths = ArrayList([]const u8).init(allocator),
            .dirs = ArrayList(fs.IterableDir.Entry).init(allocator),
            .files = ArrayList(fs.IterableDir.Entry).init(allocator),
        };
    }

    pub fn deinit(self: *zline) void {
        self.paths.deinit();
        self.dirs.deinit();
        self.files.deinit();
    }

    pub fn run(self: *zline, args: []const u8) !i32 {
        var exit_status: i32 = 0;
        _ = exit_status;

        var t = std.mem.split(u8, args, " ");
        while (t.next()) |arg| {
            try self.paths.append(arg);
        }

        for (self.paths.items) |item| {
            var dir = try fs.openIterableDirAbsolute(item, .{});
            var itr = dir.iterate();
            while (try itr.next()) |file| {
                switch (file.kind) {
                    .file => {
                        try self.files.append(file);
                        std.debug.print("File: {s}\n", .{file.name});
                    },
                    .directory => {
                        try self.dirs.append(file);
                        std.debug.print("Dir: {s}\n", .{file.name});
                    },
                    else => continue,
                }
            }
        }
        return 0;
    }
};

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const allocator = std.heap.page_allocator;
    var zl = try zline.init(allocator);
    defer zl.deinit();

    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-n, --number <usize>   An option parameter, which takes a value.
        \\-s, --string <str>...  An option parameter which can be specified multiple times.
        \\<str>...
        \\
    );
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
    }) catch |err| {
        // Report useful error and exit
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0)
        std.debug.print("--help\n", .{});    
    for (res.args.string) |s| {
        _ = try zl.run(s);
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
