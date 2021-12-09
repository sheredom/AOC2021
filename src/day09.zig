const std = @import("std");
const print = std.debug.print;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day09.txt");

pub fn main() !void {
  var timer = try std.time.Timer.start();

  var arrayList = std.ArrayList(u8).init(gpa);
  defer { arrayList.deinit(); }

  var lines = std.mem.tokenize(data, "\r\n");

  var maybeXWidth : ?usize = null;

  while (lines.next()) |line| {
    if (maybeXWidth == null) {
      maybeXWidth = line.len + 2;

      // If we're here it means we are the first row, so we pad in some 9's to
      // make the future calculation easier (less checks).
      var index : usize = 0;

      while (index < maybeXWidth.?) : (index += 1) {
        try arrayList.append(9);
      }
    } else {
      std.debug.assert(maybeXWidth.? == (line.len + 2));
    }

    // We start each row with a 9.
    try arrayList.append(9);

    for (line) |c| {
      try arrayList.append(c - '0');
    }

    // And end each row with a 9.
    try arrayList.append(9);
  }

  // Now pad in a last row of 9's too.
  {
      var index : usize = 0;

      while (index < maybeXWidth.?) : (index += 1) {
        try arrayList.append(9);
      }
  }

  const xWidth = maybeXWidth.?;

  {
    var sum : u32 = 0;

    for (arrayList.items) |item, index| {
      // 9's can never be low points so skip them.
      if (item == 9) {
        continue;
      }

      if (item >= arrayList.items[index - 1]) {
        continue;
      }

      if (item >= arrayList.items[index + 1]) {
        continue;
      }

      if (item >= arrayList.items[index - xWidth]) {
        continue;
      }

      if (item >= arrayList.items[index + xWidth]) {
        continue;
      }

      // We've got a low point!
      sum += 1 + item;
    }

    print("🎁 Sum of low points: {}\n", .{sum});
    print("Day 09 - part 01 took {:12}ns\n", .{timer.lap()});
    timer.reset();
  }

  {
    var threeLargestBasins = [_]usize{0} ** 3;

    for (arrayList.items) |item, index| {
      const count = countAndWipe(index, xWidth, arrayList);

      if (count != 0) {
        var smallestIndex : usize = 0;

        for (threeLargestBasins) |basin, i| {
          if (threeLargestBasins[smallestIndex] > basin) {
            smallestIndex = i;
          }
        }

        if (threeLargestBasins[smallestIndex] < count) {
          threeLargestBasins[smallestIndex] = count;
        }
      }
    }

    const total = threeLargestBasins[0] *
      threeLargestBasins[1] *
      threeLargestBasins[2];

    print("🎁 Three largest basins sum: {}\n", .{total});
    print("Day 09 - part 02 took {:12}ns\n", .{timer.lap()});
    print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
  }
}

fn countAndWipe(index : usize, xWidth : usize, map : std.ArrayList(u8)) usize {
  // 9's are not in a basin so do not form part of the count.
  if (map.items[index] == 9) {
    return 0;
  }

  // We are included in the count so it starts as 1.
  var count : usize = 1;

  // Wipe ourselves from the map so we don't accidentally count us twice.
  map.items[index] = 9;

  const neighbours = [4]usize {
    index - 1,
    index + 1,
    index - xWidth,
    index + xWidth,
  };

  for (neighbours) |neighbour| {
    count += countAndWipe(neighbour, xWidth, map);
  }

  return count;
}
