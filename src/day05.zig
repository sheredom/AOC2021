const std = @import("std");
const print = std.debug.print;

const data = @embedFile("../data/day05.txt");

pub fn main() !void {
  var timer = try std.time.Timer.start();

  // I've vetted the input, which is at max 1000x1000.
  const board_width = 1000;

  // We need two boards - one for the first hit on the location, and one for the
  // second (what our puzzle solution requires).
  var board_1st_hit = std.StaticBitSet(board_width * board_width).initEmpty();
  var board_2nd_hit = std.StaticBitSet(board_width * board_width).initEmpty();

  {
    var line_iterator = std.mem.tokenize(data, "\r\n");

    while (line_iterator.next()) |line| {
      var coord_iterator = std.mem.tokenize(line, ",-> ");

      var x1 : u32 = try std.fmt.parseInt(u32, coord_iterator.next().?, 10);
      var y1 : u32 = try std.fmt.parseInt(u32, coord_iterator.next().?, 10);
      var x2 : u32 = try std.fmt.parseInt(u32, coord_iterator.next().?, 10);
      var y2 : u32 = try std.fmt.parseInt(u32, coord_iterator.next().?, 10);

      // Skip non-straight line segments.
      if ((x1 != x2) and (y1 != y2)) {
        continue;
      }

      // We order points so that x1 is smaller.
      if (x1 > x2) {
        std.mem.swap(u32, &x1, &x2);
      }

      // We order points so that y1 is smaller.
      if (y1 > y2) {
        std.mem.swap(u32, &y1, &y2);
      }

      var y = y1;

      while (y <= y2) : (y += 1) {
        var x = x1;

        while (x <= x2) : (x += 1) {
          const index = y * board_width + x;

          if (board_1st_hit.isSet(index)) {
            board_2nd_hit.set(index);
          } else {
            board_1st_hit.set(index);
          }
        }
      }
    }
  }

  print("🎁 At least two overlaps: {}\n", .{board_2nd_hit.count()});
  print("Day 05 - part 01 took {:15}ns\n", .{timer.lap()});
  timer.reset();

  {
    var line_iterator = std.mem.tokenize(data, "\r\n");

    while (line_iterator.next()) |line| {
      var coord_iterator = std.mem.tokenize(line, ",-> ");

      var x1 : u32 = try std.fmt.parseInt(u32, coord_iterator.next().?, 10);
      var y1 : u32 = try std.fmt.parseInt(u32, coord_iterator.next().?, 10);
      var x2 : u32 = try std.fmt.parseInt(u32, coord_iterator.next().?, 10);
      var y2 : u32 = try std.fmt.parseInt(u32, coord_iterator.next().?, 10);

      // Skip non-diagonal line segments.
      if ((x1 == x2) or (y1 == y2)) {
        continue;
      }

      const steps = if (x1 < x2) x2 - x1 else x1 - x2;
      var step : u32 = 0;

      while (step <= steps) : (step += 1) {
        var x = if (x1 < x2) x1 + step else x1 - step;
        var y = if (y1 < y2) y1 + step else y1 - step;

        const index = y * board_width + x;

        if (board_1st_hit.isSet(index)) {
          board_2nd_hit.set(index);
        } else {
          board_1st_hit.set(index);
        }
      }
    }
  }

  print("🎁 At least two overlaps: {}\n", .{board_2nd_hit.count()});
  print("Day 05 - part 02 took {:15}ns\n", .{timer.lap()});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}
