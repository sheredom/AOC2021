const std = @import("std");
const print = std.debug.print;

const data = @embedFile("../data/day06.txt");

pub fn main() !void {
  var timer = try std.time.Timer.start();

  var lanternfishes = [_]u64{0} ** 9;

  var iterator = std.mem.tokenize(data, ", \r\n");

  while (iterator.next()) |lanternfish| {
    lanternfishes[try std.fmt.parseInt(u8, lanternfish, 10)] += 1;
  }

  {
    var day : usize = 0;
    const days = 80;

    while (day < days) : (day += 1) {
      var zero_day_lanternfish = lanternfishes[0];

      var index : usize = 1;

      while (index < lanternfishes.len) : (index += 1) {
        lanternfishes[index - 1] = lanternfishes[index];
      }

      // When a lanternfish reaches 0, we make it relive in slot 6, but it also
      // spawns a new fish in slot 8.
      lanternfishes[6] += zero_day_lanternfish;
      lanternfishes[8] = zero_day_lanternfish;
    }
  }

  {
    var total : u64 = 0;

    var index : usize = 0;

    while (index < lanternfishes.len) : (index += 1) {
      total += lanternfishes[index];
    }

    print("🎁 Lanternfish after 80 days: {}\n", .{total});
    print("Day 06 - part 01 took {:15}ns\n", .{timer.lap()});
    timer.reset();
  }

  {
    var day : usize = 80;
    const days = 256;

    while (day < days) : (day += 1) {
      var zero_day_lanternfish = lanternfishes[0];

      var index : usize = 1;

      while (index < lanternfishes.len) : (index += 1) {
        lanternfishes[index - 1] = lanternfishes[index];
      }

      // When a lanternfish reaches 0, we make it relive in slot 6, but it also
      // spawns a new fish in slot 8.
      lanternfishes[6] += zero_day_lanternfish;
      lanternfishes[8] = zero_day_lanternfish;
    }
  }

  {
    var total : u64 = 0;

    var index : usize = 0;

    while (index < lanternfishes.len) : (index += 1) {
      total += lanternfishes[index];
    }

    print("🎁 Lanternfish after 256 days: {}\n", .{total});
    print("Day 06 - part 02 took {:15}ns\n", .{timer.lap()});
    print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
  }
}
