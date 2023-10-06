const std = @import("std");
const clap = @import("clap");
const ArrayList = std.ArrayList;
const fs = std.fs;

pub const zline = struct {
    allocator: std.mem.Allocator,
    writer: fs.File.Writer,
    paths: ArrayList([]const u8),
    dirs: ArrayList(fs.IterableDir.Entry),
    files: ArrayList(fs.IterableDir.Entry),

    pub fn init(allocator: std.mem.Allocator, writer: anytype) !zline {
        return zline{
            .allocator = allocator,
            .paths = ArrayList([]const u8).init(allocator),
            .dirs = ArrayList(fs.IterableDir.Entry).init(allocator),
            .files = ArrayList(fs.IterableDir.Entry).init(allocator),
            .writer = writer,
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
                    },
                    .directory => {
                        try self.dirs.append(file);
                    },
                    else => continue,
                }
            }
            try print_files(self);
            try print_dirs(self);
        }


        return 0;
    }

    fn print_dirs(self: *zline) !void {
        return for (self.dirs.items) |dir| {
            try self.writer.print("Dir: {s}\n", .{dir.name});
        };
    }

    fn print_files(self: *zline) !void {
        return for (self.files.items) |file| {
            try self.writer.print("File: {s}\n", .{file.name});
        };
    }
};

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    const allocator = std.heap.page_allocator;
    const writer = std.io.getStdOut();
    defer writer.close();
    var zl = try zline.init(allocator, writer.writer());
    defer zl.deinit();
    

    const params = comptime clap.parseParamsComptime(
        \\-h, --help             Display this help and exit.
        \\-p, --path <str>...    Display the listing of this path.
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
        std.debug.print(        
            \\-h, --help             Display this help and exit.
            \\-p, --path <str>...    Display the listing of this path.
            \\<str>...
            \\
            , .{}
        );    
    for (res.args.path) |s| {
        _ = try zl.run(s);
    }
}
