const std = @import("std");
const print = std.debug.print;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day14.txt");

const Value = struct {
  result : u8,
  lastVisitCount : u64,
  nextVisitCount : u64,
};

pub fn main() !void {
  var timer = try std.time.Timer.start();

  var map = std.StringHashMap(Value).init(gpa);
  defer { map.deinit(); }

  var lines = std.mem.tokenize(data, "\r\n");

  var template = lines.next().?;

  while (lines.next()) |line| {
    var tokens = std.mem.tokenize(line, " -> ");

    const pattern = tokens.next().?;
    std.debug.assert(pattern.len == 2);

    const result = tokens.next().?;
    std.debug.assert(result.len == 1);

    const value = Value {
      .result = result[0],
      .lastVisitCount = 0,
      .nextVisitCount = 0,
    };

    try map.put(pattern, value);
  }

  // Now we insert all the initial visit counts from our template into the map.
  {
    var index : u32 = 0;

    while (index < (template.len - 1)) : (index += 1) {
      var slice = template[index..(index + 2)];

      map.getPtr(slice).?.lastVisitCount += 1;
    }
  }

  var step : u32 = 0;
  const part1Steps : u32 = 10;
  const steps : u32 = 40;

  while (step < steps) : (step += 1) {
    if (step == part1Steps) {
      print("🎁 Quantity: {}\n", .{calculateQuantity(map)});
      print("Day 14 - part 01 took {:15}ns\n", .{timer.lap()});
      timer.reset();
    }

    // First pass we work out the next visit counts for the future step.
    {
      var iterator = map.iterator();
      
      while (iterator.next()) |pair| {
        const key = pair.key_ptr.*;
        const value = pair.value_ptr;

        // If we didn't visit this value on the last step, skip it!
        if (value.lastVisitCount == 0) {
          continue;
        }

        // Each pair inserts two new pairs with the result splicing the original
        // pairs letters.
        const newKey0 = [2]u8 {key[0], value.result};
        const newKey1 = [2]u8 {value.result, key[1]};

        // We visit each of these new keys next time as many times as we would
        // visit the last steps visit count.
        map.getPtr(&newKey0).?.nextVisitCount += value.lastVisitCount;
        map.getPtr(&newKey1).?.nextVisitCount += value.lastVisitCount;
      }
    }

    // Second pass we move the next visit counts to the last visit counts for
    // the next loop iteration.
    {
      var iterator = map.iterator();
      
      while (iterator.next()) |pair| {
        const key = pair.key_ptr.*;
        const value = pair.value_ptr;

        value.lastVisitCount = value.nextVisitCount;
        value.nextVisitCount = 0;
      }
    }
  }

  print("🎁 Quantity: {}\n", .{calculateQuantity(map)});
  print("Day 14 - part 02 took {:15}ns\n", .{timer.lap()});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}

fn dump(map : std.StringHashMap(Value)) void {
  var iterator = map.iterator();

  print("Map:\n", .{});

  while (iterator.next()) |pair| {
    const key = pair.key_ptr.*;
    const value = pair.value_ptr;

    print("  Key '{s}' -> Result '{c}', Count '{}'\n", .{key, value.result, value.lastVisitCount});
  }
}

fn calculateQuantity(map : std.StringHashMap(Value)) u64 {
  // Each letter of the alphabet gets a hit list.
  var hits = [_]u64{0} ** 27;

  var iterator = map.iterator();

  while (iterator.next()) |pair| {
    const key = pair.key_ptr.*;
    const value = pair.value_ptr;

    hits[key[0] - 'A'] += value.lastVisitCount;
    hits[key[1] - 'A'] += value.lastVisitCount;
  }

  var minNonZeroHit : u64 = std.math.maxInt(u64);
  var maxHit : u64 = 0;

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

  // Because of how we record things into the map, we need to adjust the
  // calculated resulted by diving it by 2 (because we record each element of
  // each pair twice effectively).
  return (maxHit - minNonZeroHit + 1) / 2;
}
