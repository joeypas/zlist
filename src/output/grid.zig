const std = @import("std");
const TextCell = @import("./cell.zig").TextCell;
const ansi_term = @import("ansi-term");
const Style = ansi_term.style.Style;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

const TextCells = ArrayList(ArrayList(TextCell));

pub const Grid = struct {
    allocator: Allocator,
    itms: ArrayList(TextCell),
    grid: ArrayList(*TextCells),

    pub fn init(allocator: Allocator) !Grid {
        return .{
            .allocator = allocator,
            .itms = ArrayList(TextCell).init(allocator),
            .grid = ArrayList(*ArrayList(TextCell)).init(allocator),
        };
    }

    pub fn deinit(self: *Grid) void {
        self.items.deinit();
        self.grid.deinit();
    }

    

    pub fn print(self: *Grid, writer: std.fs.File.Writer) !void {
        var i: usize = 0;
        while (i < self.grid.items.len) : (i += 1) {
            var temp: ArrayList(TextCell) = self.grid.items[i].*;
            for (temp.items) |cell| {
                try ansi_term.format.updateStyle(writer, cell.contents.style, undefined);
                writer.print("{s}\t", .{cell.contents.text});
            }
            try ansi_term.format.resetStyle(writer);
            try writer.print("\n", .{});
        }
    }
};
