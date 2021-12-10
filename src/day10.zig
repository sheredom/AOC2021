const std = @import("std");
const print = std.debug.print;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day10.txt");

pub fn main() !void {
  var timer = try std.time.Timer.start();

  var lines = std.mem.tokenize(data, "\r\n");

  var chunks = std.ArrayList(u8).init(gpa);
  defer { chunks.deinit(); }

  var scores = std.ArrayList(u64).init(gpa);
  defer { scores.deinit(); }

  var total : u32 = 0;

  while (lines.next()) |line| {
    var syntaxError = false;

    for (line) |c| {
      switch (c) {
        '(', '[', '{', '<' => try chunks.append(c),
        ')' => {
          const pop = chunks.popOrNull();
          if (pop == null or pop.? != '(') {
            total += 3;
            syntaxError = true;
            break;
          }
        },
        ']' => {
          const pop = chunks.popOrNull();
          if (pop == null or pop.? != '[') {
            total += 57;
            syntaxError = true;
            break;
          }
        },
        '}' => {
          const pop = chunks.popOrNull();
          if (pop == null or pop.? != '{') {
            total += 1197;
            syntaxError = true;
            break;
          }
        },
        '>' => {
          const pop = chunks.popOrNull();
          if (pop == null or pop.? != '<') {
            total += 25137;
            syntaxError = true;
            break;
          }
        },
        else => unreachable,
      }
    }

    // We need to skip any corrupted ones, and only score the incomplete ones.
    if (syntaxError) {
      // We're reusing chunks for each line check, so clear it for the next one!
      chunks.clearRetainingCapacity();

      continue;
    }

    var score : u64 = 0;

    while (chunks.items.len != 0) {
      score *= 5;
      
      switch (chunks.pop()) {
        '(' => score += 1,
        '[' => score += 2,
        '{' => score += 3,
        '<' => score += 4,
        else => unreachable
      }
    }

    try scores.append(score);
  }

  {
    print("🎁 Syntax error: {}\n", .{total});
    print("Day 10 - part 01 took {:12}ns\n", .{timer.lap()});
    timer.reset();
  }

  std.sort.sort(u64, scores.items, {}, compare);

  const middle = scores.items[scores.items.len / 2];

  {
    print("🎁 Middle score: {}\n", .{middle});
    print("Day 10 - part 02 took {:12}ns\n", .{timer.lap()});
    print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
  }
}

fn compare(context: void, a: u64, b: u64) bool {
    return a < b;
}