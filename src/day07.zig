const std = @import("std");
const print = std.debug.print;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day07.txt");

pub fn main() !void {
  var timer = try std.time.Timer.start();

  var crabs = std.ArrayList(u16).init(gpa);
  defer { crabs.deinit(); }

  var iterator = std.mem.tokenize(data, ", \r\n");

  while (iterator.next()) |crab| {
    try crabs.append(try std.fmt.parseInt(u16, crab, 10));
  }
  
  var max_crab : u16 = 0;
  {
    var index : usize = 0;
    while (index < crabs.items.len) : (index += 1) {
      const crab = crabs.items[index];

      if (max_crab < crab) {
        max_crab = crab;
      }
    }
  }

  {
    var least_fuel : u32 = std.math.maxInt(u32);
    var crab : u16 = 0;

    while (crab < max_crab) : (crab += 1) {
      var fuel : u32 = 0;

      var index : usize = 0;

      while (index < crabs.items.len) : (index += 1) {
        const other = crabs.items[index];
        fuel += if (crab < other) other - crab else crab - other;

        if (fuel > least_fuel) {
          break;
        }
      }

      if (fuel < least_fuel) {
        least_fuel = fuel;
      }
    }

    print("🎁 Least fuel: {}\n", .{least_fuel});
    print("Day 07 - part 01 took {:12}ns\n", .{timer.lap()});
    timer.reset();
  }

  {
    var least_fuel : u32 = std.math.maxInt(u32);
    var crab : u16 = 0;

    while (crab < max_crab) : (crab += 1) {
      var fuel : u32 = 0;

      var index : usize = 0;

      while (index < crabs.items.len) : (index += 1) {
        const other = crabs.items[index];

        const cost : u32 = if (crab < other) other - crab else crab - other;

        // Used Wolfram Alpha to solve the sequence here:
        // `0, 1, 3, 6, 10, 15, 21, 28, 36, 45, 55, 66, 78, 91, 105, ...`
        fuel += (cost * (cost + 1)) / 2;
      }

      if (fuel < least_fuel) {
        least_fuel = fuel;
      }
    }

    print("🎁 Least fuel: {}\n", .{least_fuel});
    print("Day 07 - part 02 took {:12}ns\n", .{timer.lap()});
    print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
  }
}
