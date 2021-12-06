const std = @import("std");
const print = std.debug.print;

const data = @embedFile("../data/day06.txt");

const util = @import("util.zig");
const gpa = util.gpa;

pub fn main() !void {
  var timer = try std.time.Timer.start();

  var lanternfishes = std.ArrayList(u8).init(gpa);

  var iterator = std.mem.tokenize(data, ", \r\n");

  while (iterator.next()) |laternfish| {
    try lanternfishes.append(try std.fmt.parseInt(u8, laternfish, 10));
  }

  {
    var day : usize = 0;
    const days = 80;

    while (day < days) : (day += 1) {
      var index : usize = 0;
      const count = lanternfishes.items.len;

      while (index < count) : (index += 1) {
        if (lanternfishes.items[index] == 0) {
          // Make a new fish.
          try lanternfishes.append(8);

          // And reset our timer.
          lanternfishes.items[index] = 6;
        } else {
          lanternfishes.items[index] -= 1;
        }
      }
    }
  }
    
  print("🎁 Lanternfish after 80 days: {}\n", .{lanternfishes.items.len});
  print("Day 06 - part 01 took {:12}ns\n", .{timer.lap()});
  timer.reset();

  {
    var day : usize = 80;
    const days = 256;

    while (day < days) : (day += 1) {
      var index : usize = 0;
      const count = lanternfishes.items.len;

      while (index < count) : (index += 1) {
        if (lanternfishes.items[index] == 0) {
          // Make a new fish.
          try lanternfishes.append(8);

          // And reset our timer.
          lanternfishes.items[index] = 6;
        } else {
          lanternfishes.items[index] -= 1;
        }
      }
    }
  }

  print("🎁 Lanternfish after 256 days: {}\n", .{lanternfishes.items.len});
  print("Day 06 - part 02 took {:12}ns\n", .{timer.lap()});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}
