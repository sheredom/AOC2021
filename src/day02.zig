const std = @import("std");
const print = std.debug.print;

const data = @embedFile("../data/day02.txt");

const Direction = enum(u2) {
    up,
    down,
    forward
};

fn day01() !void {
  var depth : i32 = 0;
  var position : i32 = 0;

  var iterator = std.mem.tokenize(data, "\r\n ");

  var nextCommand : ?Direction = null;

  while (iterator.next()) |token| {
    if (std.mem.startsWith(u8, token, "up")) {
      nextCommand = Direction.up;
    } else if (std.mem.startsWith(u8, token, "down")) {
      nextCommand = Direction.down;
    } else if (std.mem.startsWith(u8, token, "forward")) {
      nextCommand = Direction.forward;
    } else {
      var change = try std.fmt.parseInt(i32, token, 10);

      switch (nextCommand.?) {
        Direction.up => depth -= change,
        Direction.down => depth += change,
        Direction.forward => position += change,
      }
    }
  }

  print("🎁 Horizontal Position * Depth: {}\n", .{position * depth});
}

fn day02() !void {
  var depth : i32 = 0;
  var position : i32 = 0;
  var aim : i32 = 0;

  var iterator = std.mem.tokenize(data, "\r\n ");

  var nextCommand : ?Direction = null;

  while (iterator.next()) |token| {

    if (std.mem.startsWith(u8, token, "up")) {
      nextCommand = Direction.up;
    } else if (std.mem.startsWith(u8, token, "down")) {
      nextCommand = Direction.down;
    } else if (std.mem.startsWith(u8, token, "forward")) {
      nextCommand = Direction.forward;
    } else {
      var change = try std.fmt.parseInt(i32, token, 10);

      switch (nextCommand.?) {
        Direction.up => aim -= change,
        Direction.down => aim += change,
        Direction.forward => {
          position += change;
          depth += aim * change;
        },
      }
    }
  }

  print("🎁 Horizontal Position * Depth: {}\n", .{position * depth});
}

pub fn main() !void {
  var timer = try std.time.Timer.start();
  try day01();
  var part01 = timer.lap();
  print("Day 02 - part 01 took {:12}ns\n", .{part01});
  timer.reset();
  try day02();
  var part02 = timer.lap();
  print("Day 02 - part 02 took {:12}ns\n", .{part02});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}
