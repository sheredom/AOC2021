const std = @import("std");
const print = std.debug.print;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day14.txt");

pub fn main() !void {
  var timer = try std.time.Timer.start();

  var template = std.ArrayList(u8).init(gpa);
  var map = std.StringHashMap(u8).init(gpa);
  // TODO Defer

  var lines = std.mem.tokenize(data, "\r\n");

  // The first line is the template.
  for (lines.next().?) |c| {
    try template.append(c);
  }

  while (lines.next()) |line| {
    var tokens = std.mem.tokenize(line, " -> ");

    const pattern = tokens.next().?;
    std.debug.assert(pattern.len == 2);

    const result = tokens.next().?;
    std.debug.assert(result.len == 1);

    try map.put(pattern, result[0]);
  }

  var step : u32 = 0;
  const part1Steps : u32 = 10;

  while (step < part1Steps) : (step += 1) {
    var index : u32 = 0;

    // We stride by 2 here because each insertion will add a new element!
    while (index < (template.items.len - 1)) : (index += 2) {
      const pair = template.items[index..(index + 2)];

      const result = map.get(pair).?;
      
      try template.insert(index + 1, result);
    }
  }
  
  print("🎁 Quantity: {}\n", .{calculateQuantity(template)});
  print("Day 14 - part 01 took {:15}ns\n", .{timer.lap()});
  timer.reset();

  const part2Steps : u32 = 40;

  while (step < part2Steps) : (step += 1) {
    print("Step {}\n", .{step});
    var newTemplate = std.ArrayList(u8).init(gpa);
    
    var index : u32 = 0;

    while (index < (template.items.len - 1)) : (index += 1) {
      const pair = template.items[index..(index + 2)];

      const result = map.get(pair).?;
      
      try newTemplate.append(template.items[index]);
      try newTemplate.append(result);
    }

    try newTemplate.append(template.items[template.items.len - 1]);

    template.deinit();

    template = newTemplate;
  }

  print("🎁 Quantity: {}\n", .{calculateQuantity(template)});
  print("Day 14 - part 02 took {:15}ns\n", .{timer.lap()});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}

fn calculateQuantity(template : std.ArrayList(u8)) u64 {
  // Each letter of the alphabet gets a hit list.
  var hits = [_]u32{0} ** 27;

  for (template.items) |t| {
    hits[t - 'A'] += 1;
  }

  var minNonZeroHit : u32 = std.math.maxInt(u32);
  var maxHit : u32 = 0;

  for (hits) |hit| {
    if (hit == 0) {
      continue;
    }

    if (minNonZeroHit > hit) {
      minNonZeroHit = hit;
    }

    if (maxHit < hit) {
      maxHit = hit;
    }
  }

  return maxHit - minNonZeroHit;
}
