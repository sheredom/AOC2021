const std = @import("std");
const print = std.debug.print;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day13.txt");

pub fn main() !void {
  var timer = try std.time.Timer.start();

  const width : u32 = 1500;

  var paper = std.StaticBitSet(width * width).initEmpty();

  {
    var dataAndFolds = std.mem.split(data, "fold along ");

    {
      var lines = std.mem.tokenize(dataAndFolds.next().?, "\r\n");

      while (lines.next()) |line| {
        var lineIterator = std.mem.tokenize(line, ",");
        const x = try std.fmt.parseInt(u32, lineIterator.next().?, 10);
        const y = try std.fmt.parseInt(u32, lineIterator.next().?, 10);

        std.debug.assert(x < width);
        std.debug.assert(y < width);

        paper.set(y * width + x);
      }
    }

    var firstFold = true;

    while (dataAndFolds.next()) |fold| {
      var lineIterator = std.mem.tokenize(fold, "=\r\n");
      const direction = lineIterator.next().?;
      const position = try std.fmt.parseInt(u32, lineIterator.next().?, 10);

      std.debug.assert(position < width);

      var dots = paper.iterator(.{});

      if (direction[0] == 'x') {
        while (dots.next()) |dot| {
          const x = dot % width;
          const y = dot / width;

          // Skip any dots that lie in the non-folded region.
          if (x < position) {
            continue;
          }

          const newX = position - (x - position);
          paper.set(y * width + newX);
          paper.unset(dot);
        }
      } else {
        while (dots.next()) |dot| {
          const x = dot % width;
          const y = dot / width;

          // Skip any dots that lie in the non-folded region.
          if (y < position) {
            continue;
          }

          const newY = position - (y - position);
          paper.set(newY * width + x);
          paper.unset(dot);
        }
      }

      if (firstFold) {
        firstFold = false;

        print("🎁 First fold dots: {}\n", .{paper.count()});
        print("Day 13 - part 01 took {:15}ns\n", .{timer.lap()});
        timer.reset();
      }
    }
  }

  // Work out the remaining actual width of the output after the folds.
  var xMax : usize = 0;
  var yMax : usize = 0;

  {
    var dots = paper.iterator(.{});

    while (dots.next()) |dot| {
      const x = dot % width;
      const y = dot / width;
      
      if (x > xMax) {
        xMax = x;
      }

      if (y > yMax) {
        yMax = y;
      }
    }
  }

  // Now we need to work out how to print the code.
  var y : usize = 0;
  while (y <= yMax) : (y += 1) {
    var x : usize = 0;
    while (x <= xMax) : (x += 1) {
      if (paper.isSet(y * width + x)) {
        print("#", .{});
      } else {
        print(" ", .{});
      }
    }
    print("\n", .{});
  }

  print("Day 13 - part 02 took {:15}ns\n", .{timer.lap()});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}
