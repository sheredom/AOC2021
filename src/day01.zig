const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day01.txt");

fn day01() void {

}

fn day02() void {

}

pub fn main() !void {
  var timer = try std.time.Timer.start();
  day01();
  var part01 = timer.lap();
  day02();
  var part02 = timer.lap();

  print("Day 01 - part 01 took {:12}ns\n", .{part01});
  print("Day 01 - part 02 took {:12}ns\n", .{part02});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}
