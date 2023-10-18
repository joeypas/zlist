const std = @import("std");
const clap = @import("clap");
const ansi_term = @import("ansi_term");
const cell = @import("./output/cell.zig");
const TextCell = cell.TextCell;
const ArrayList = std.ArrayList;
const fs = std.fs;
const Style = ansi_term.style.Style;

pub const zline = struct {
    allocator: std.mem.Allocator,
    writer: fs.File.Writer,
    f_style: Style,
    d_style: Style,
    paths: ArrayList([]const u8),
    dirs: ArrayList([]const u8),
    files: ArrayList([]const u8),

    pub fn init(allocator: std.mem.Allocator, writer: anytype, fst: Style, dst: Style) !zline {
        return zline{ .allocator = allocator, .paths = ArrayList([]const u8).init(allocator), .dirs = ArrayList([]const u8).init(allocator), .files = ArrayList([]const u8).init(allocator), .writer = writer, .f_style = fst, .d_style = dst };
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
                        try self.files.append(file.name);
                    },
                    .directory => {
                        try self.dirs.append(file.name);
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
        try ansi_term.format.resetStyle(self.writer);
        try ansi_term.format.updateStyle(self.writer, self.d_style, undefined);
        var i: usize = 0;
        return for (self.dirs.items) |dir| {
            try self.writer.print("{s}", .{dir});
            if (i == 2) {
                try self.writer.print("\n", .{});
                i = 0;
                continue;
            } else {
                try self.writer.print("\t", .{});
            }
            i += 1;
        };
    }

    fn print_files(self: *zline) !void {
        try ansi_term.format.resetStyle(self.writer);
        try ansi_term.format.updateStyle(self.writer, self.f_style, undefined);
        var i: usize = 0;
        return for (self.files.items) |file| {
            try self.writer.print("{s}", .{file});
            if (i == 2) {
                try self.writer.print("\n", .{});
                i = 0;
                continue;
            } else {
                try self.writer.print("\t", .{});
            }
            i += 1;
        };
    }
};

pub fn main() !void {
    var f_style: Style = undefined;
    f_style.foreground = .Cyan;
    f_style.font_style = ansi_term.style.FontStyle{};
    f_style.background = .Default;
    var d_style: Style = undefined;
    d_style.foreground = .Red;
    d_style.font_style = ansi_term.style.FontStyle{};
    d_style.background = .Default;

    const allocator = std.heap.page_allocator;
    const writer = std.io.getStdOut();
    defer writer.close();
    var zl = try zline.init(allocator, writer.writer(), f_style, d_style);
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
        , .{});
    for (res.args.path) |s| {
        _ = try zl.run(s);
    }
}
