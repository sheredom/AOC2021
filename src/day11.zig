const std = @import("std");
const print = std.debug.print;

const data = @embedFile("../data/day11.txt");

fn dump(grid : [100]u8) void {
  for (grid) |g, i| {
    if (g > 9) {
      print(" ", .{});
    } else {
      print("{}", .{g});
    }

    if ((i % 10) == 9) {
      print("\n", .{});
    }
  }

  print("\n", .{});
}

pub fn main() !void {
  var timer = try std.time.Timer.start();

  var lines = std.mem.tokenize(data, "\r\n");

  const width : u32 = 10;
  var grid = [_]u8{0} ** 100;

  {
    var index : u32 = 0;

    while (lines.next()) |line| {
      for (line) |c| {
        grid[index] = c - '0';
        index += 1;
      }
    }
  }

  var total_flashes : u32 = 0;

  {
    const steps : u32 = 1000;
    var step : u32 = 0;

    while (step < steps) : (step += 1) {
      // First, the energy level of each octopus increases by 1.
      for (grid) |*g| {
        g.* += 1;
      }

      var flashed = std.StaticBitSet(100).initEmpty();

      // Now we flash our octopuses until there are no more to flash.
      while (true) {
        const lastFlashedCount = flashed.count();

        for (grid) |g, i| {
          // Skip any octopus that isn't flashing.
          if (g <= 9) {
            continue;
          }

          // Skip any octopus we've already flashed.
          if (flashed.isSet(i)) {
            continue;
          }

          // Remember that we've already flashed this octopus.
          flashed.set(i);

          // Increase the energy level of all adjacent octopuses by 1.
          const x = i % width;
          const y = i / width;

          // (x - 1, y - 1)
          if ((x > 0) and (y > 0)) {
            grid[(y - 1) * width + (x - 1)] += 1;
          }

          // (x, y - 1)
          if (y > 0) {
            grid[(y - 1) * width + x] += 1;
          }

          // (x + 1, y - 1)
          if (((x + 1) < width) and (y > 0)) {
            grid[(y - 1) * width + (x + 1)] += 1;
          }

          // (x - 1, y)
          if (x > 0) {
            grid[y * width + (x - 1)] += 1;
          }

          // (x + 1, y)
          if ((x + 1) < width) {
            grid[y * width + (x + 1)] += 1;
          }

          // (x - 1, y + 1)
          if ((x > 0) and ((y + 1) < width)) {
            grid[(y + 1) * width + (x - 1)] += 1;
          }

          // (x, y + 1)
          if ((y + 1) < width) {
            grid[(y + 1) * width + x] += 1;
          }

          // (x + 1, y + 1)
          if (((x + 1) < width) and ((y + 1) < width)) {
            grid[(y + 1) * width + (x + 1)] += 1;
          }
        }

        if (lastFlashedCount == flashed.count()) {
          break;
        }
      }

      if (flashed.count() == 100) {
        print("🎁 First synchronized flash: {}\n", .{step + 1});
        print("Day 11 - part 02 took {:15}ns\n", .{timer.lap()});
        print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
        break;
      }

      // Lastly do the actual flashes.
      for (grid) |*g| {
        // Skip any octopus that doesn't flash.
        if (g.* <= 9) {
          continue;
        }

        g.* = 0;
        total_flashes += 1;
      }

      if (step == 100) {
        print("🎁 Total flashes: {}\n", .{total_flashes});
        print("Day 11 - part 01 took {:15}ns\n", .{timer.lap()});
        timer.reset();
      }
    }
  }
}
