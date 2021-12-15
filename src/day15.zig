const std = @import("std");
const print = std.debug.print;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day15.txt");

pub fn main() !void {
  var timer = try std.time.Timer.start();

  var map = std.ArrayList(u8).init(gpa);
  defer { map.deinit(); }

  var width : usize = 0;

  {
    var maybeWidth : ?usize = null;

    var lines = std.mem.tokenize(data, "\r\n");

    while (lines.next()) |line| {
      if (maybeWidth == null) {
        maybeWidth = line.len;
      } else {
        std.debug.assert(maybeWidth.? == line.len);
      }

      for (line) |c| {
        try map.append(c - '0');
      }
    }

    width = maybeWidth.?;
  }

  print("🎁 Lowest total risk: {}\n", .{try aStar(map, width)});
  print("Day 15 - part 01 took {:15}ns\n", .{timer.lap()});
  timer.reset();

  const biggerWidth = width * 5;

  var biggerMap = std.ArrayList(u8).init(gpa);
  defer { biggerMap.deinit(); }

  var yTile : u8 = 0;
  while (yTile < 5) : (yTile += 1) {
    var y : u32 = 0;
    while (y < width) : (y += 1) {
      var xTile : u8 = 0;
      while (xTile < 5) : (xTile += 1) {
        var x : u32 = 0;
        while (x < width) : (x += 1) {
          const originalValue = map.items[y * width + x];
          const value = (originalValue + yTile + xTile) % 9;

          try biggerMap.append(if (0 == value) 9 else value);
        }
      }
    }
  }

  print("🎁 Quantity: {}\n", .{try aStar(biggerMap, biggerWidth)});
  print("Day 15 - part 02 took {:15}ns\n", .{timer.lap()});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}

fn aStar(map: std.ArrayList(u8), width: usize) !usize {
  var openSet = std.ArrayList(usize).init(gpa);
  defer { openSet.deinit(); }

  // We start at (0, 0).
  try openSet.append(0);

  var costs = std.ArrayList(u32).init(gpa);
  defer { costs.deinit(); }

  // Initially everything so that it costs a bomb!
  try costs.appendNTimes(std.math.maxInt(u32) - 10, map.items.len);

  // Except the start, it cost us 0 to get where we already are!
  costs.items[0] = 0;

  while (openSet.items.len > 0) {
    const current = openSet.swapRemove(0);

    if (current == (map.items.len - 1)) {
      return costs.items[current] + map.items[current] - map.items[0];
    }

    const x = current % width;
    const y = current / width;

    const cost = map.items[current] + costs.items[current];
    if (x > 0) {
      const neighbour = current - 1;

      if (cost < costs.items[neighbour]) {
        costs.items[neighbour] = cost;
        try openSet.append(neighbour);
      }
    }

    if (x < (width - 1)) {
      const neighbour = current + 1;

      if (cost < costs.items[neighbour]) {
        costs.items[neighbour] = cost;
        try openSet.append(neighbour);
      }
    }

    if (y > 0) {
      const neighbour = current - width;

      if (cost < costs.items[neighbour]) {
        costs.items[neighbour] = cost;
        try openSet.append(neighbour);
      }
    }

    if (y < (width - 1)) {
      const neighbour = current + width;

      if (cost < costs.items[neighbour]) {
        costs.items[neighbour] = cost;
        try openSet.append(neighbour);
      }
    }

    // Sort the set so that the first element is the cheapest cost.
    std.sort.sort(usize, openSet.items, costs, compare);

    // De-duplicate the set too.
    var index : u32 = 1;

    while (index < openSet.items.len) {
      if (openSet.items[index - 1] == openSet.items[index]) {
        const removed = openSet.swapRemove(index);
      } else {
        index += 1;
      }
    }
  }

  unreachable;
}

fn compare(costs: std.ArrayList(u32), a: usize, b: usize) bool {
    return costs.items[a] < costs.items[b];
}
