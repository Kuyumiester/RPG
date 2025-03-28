const std = @import("std");
const input = @import("input.zig");
const devtools = @import("devtools.zig");

var bw: std.io.BufferedWriter(4096, std.fs.File.Writer) = undefined;
const stdout = bw.writer();

pub fn init() !void {
    bw = std.io.bufferedWriter(std.io.getStdOut().writer());
}

var temporary_lines: u8 = 1;

pub fn print(comptime fmt: []const u8, args: anytype) void {
    for (fmt) |byte| {
        if (byte == '\n') temporary_lines += 1;
    }
    stdout.print(fmt, args) catch unreachable;
}

pub fn writeAll(comptime str: []const u8) void {
    for (str) |byte| {
        if (byte == '\n') temporary_lines += 1;
    }
    stdout.writeAll(str) catch unreachable;
}

pub fn flush() void {
    bw.flush() catch unreachable;
}

pub fn newScreen() void {
    if (devtools.developer_build) {
        stdout.print(clear_screen, .{}) catch unreachable;
    } else {
        stdout.print(csi ++ "{}F" ++ clear_to_screen_end, .{temporary_lines}) catch unreachable;
    }

    input.first_try = true;
    temporary_lines = 1;
}

//
//      escape codes
//

pub const csi = [2]u8{ 27, '[' }; //same as "\x1B[";
pub const clear_screen = csi ++ "2J"; // clears the screen by moving all the text up, as if scrolling down or entering newlines, until all the text is off the screen
pub const clear_line = csi ++ "2K"; // clear the line your cursor is on
pub const backspace = [1]u8{8};
pub const clear_to_screen_end = csi ++ "J"; // clear from cursor to end of screen

pub fn previousLine(n: comptime_int) []const u8 { // move cursor to beginning of a previous line
    // if number_of_lines == 0, it will do the same thing as number_of_lines == 1
    return csi ++ devtools.numberAsString(n) ++ "F";
}
pub fn subsequentLine(n: comptime_int) []const u8 { // move cursor to beginning of a subsequent line
    // I ASSUME if number_of_lines == 0, it will do the same thing as number_of_lines == 1
    return csi ++ devtools.numberAsString(n) ++ "E";
}

pub fn cursorForward(n: comptime_int) []const u8 {
    return csi ++ devtools.numberAsString(n) ++ "C";
}

//
// i'm not totally clear yet on how these two work
// i think scrolling moves the cursor as well. that's probably what confused me.
//
pub fn scrollUp(n: comptime_int) []const u8 {
    return csi ++ devtools.numberAsString(n) ++ "S";
}
pub fn scrollDown(n: comptime_int) []const u8 {
    return csi ++ devtools.numberAsString(n) ++ "T";
}

//
//      colors
//
// things i want colors for: normal, player's typed input, "selectable", purchaseable?, no-take-backsies-ness?, player character's name?, character's name?, enemy's name?

// colors that seem good together
// 111 (blue), 170 (pink), 253 (grey)
pub const standard_color = csi ++ "38;5;253m";
pub const input_color = csi ++ "38;5;170m";
pub const selectable_color = csi ++ "38;5;111m"; //128 213 170
