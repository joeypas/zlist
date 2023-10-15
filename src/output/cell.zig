const std = @import("std");
const ansi_term = @import("ansi-term");
const Style = ansi_term.style.Style;
const ArrayList = std.ArrayList;

const TextCellContents = struct {
    text: []const u8,
    style: Style,
};

pub const TextCell = struct {
    contents: TextCellContents,
    width: usize,

    pub fn init(style: Style, text: []const u8) !TextCell {
        return .{
            .contents = .{.text = text, .style = style},
            .width = text.len,
        };
    }
};

