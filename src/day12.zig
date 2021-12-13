const std = @import("std");
const print = std.debug.print;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day12.txt");

const Type = enum {
  Start,
  End,
  Big,
  Small,
};

const Cave = struct {
  exits : [16]i16,
  ty : Type,

  pub fn init(name : []const u8) @This() {
    var ty = Type.Small;

    if (std.mem.eql(u8, name, "start")) {
      ty = Type.Start; 
    } else if (std.mem.eql(u8, name, "end")) {
      ty = Type.End;
    } else if (name[0] >= 'A' and name[0] <= 'Z') {
      ty = Type.Big;
    }

    return Cave { .exits = [_]i16{-1} ** 16 , .ty = ty };
  }

  pub fn addExit(this : *@This(), e : u8) void {
    for (this.exits) |*exit| {
      // Skip any indices that we've already used.
      if (exit.* != -1) {
        continue;
      }

      exit.* = e;
      return;
    }

    unreachable;
  }
};

pub fn main() !void {
  var timer = try std.time.Timer.start();

  var caves = std.ArrayList(Cave).init(gpa);
  defer { caves.deinit(); }

  var cavesToIndices = std.StringHashMap(u8).init(gpa);
  defer { cavesToIndices.deinit(); }

  {
    var lines = std.mem.tokenize(data, "\r\n");

    while (lines.next()) |line| {
      var entry = std.mem.tokenize(line, "-");
      const src = entry.next().?;
      const dst = entry.next().?;

      // If we haven't encountered the caves before, make new ones!

      if (cavesToIndices.get(src) == null) {
        const index = caves.items.len;
        try caves.append(Cave.init(src));
        try cavesToIndices.put(src, @intCast(u8, index));
      }

      if (cavesToIndices.get(dst) == null) {
        const index = caves.items.len;
        try caves.append(Cave.init(dst));
        try cavesToIndices.put(dst, @intCast(u8, index));
      }

      const srcIndex = cavesToIndices.get(src).?;
      const dstIndex = cavesToIndices.get(dst).?;

      // Caves are bi-directional, so we need to add to each.
      caves.items[srcIndex].addExit(dstIndex);
      caves.items[dstIndex].addExit(srcIndex);
    }
  }

  {
    const paths = countPathsPart1(caves);
    print("🎁 Unique paths: {}\n", .{paths});
    print("Day 12 - part 01 took {:15}ns\n", .{timer.lap()});
    timer.reset();
  }

  {
    const paths = countPathsPart2(caves);
    print("🎁 Middle score: {}\n", .{paths});
    print("Day 12 - part 02 took {:15}ns\n", .{timer.lap()});
    print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
  }
}

fn countPathsPart1(caves : std.ArrayList(Cave)) usize {
  var visited = std.ArrayList(usize).init(gpa);
  defer { visited.deinit(); }

  for (caves.items) |cave, i| {
    // Skip all but the start.
    if (cave.ty != Type.Start) {
      continue;
    }

    return countPathsRecursivePart1(i, caves, &visited);
  }

  unreachable;
}

fn countPathsRecursivePart1(index: usize,
  caves : std.ArrayList(Cave),
  visited : *std.ArrayList(usize)) usize {
  // First check if we've already visited this cave.
  for (visited.*.items) |v| {
    if (index == v) {
      return 0;
    }
  }

  const ty = caves.items[index].ty;

  // If we have the end cave, exit!
  if (ty == Type.End) {
    return 1;
  }

  // We can visit big caves multiple times, so we do not visit them!
  if (ty != Type.Big) {
    // Note: we have to use `catch unreachable` here because Zig cannot analyze
    // all the potential error states of this not complete recursive function!
    visited.*.append(index) catch unreachable;
  }

  var total : usize = 0;

  for (caves.items[index].exits) |exit| {
    if (exit == -1) {
      break;
    }

    total += countPathsRecursivePart1(@intCast(usize, exit), caves, visited);
  }
  
  if (ty != Type.Big) {
    const pop = visited.pop();
  }

  return total;
}

fn countPathsPart2(caves : std.ArrayList(Cave)) usize {
  var firstVisit = std.DynamicBitSet.initEmpty(caves.items.len, gpa)
    catch unreachable;
  defer { firstVisit.deinit(); }

  var secondVisit = std.DynamicBitSet.initEmpty(caves.items.len, gpa)
    catch unreachable;
  defer { secondVisit.deinit(); }

  for (caves.items) |cave, i| {
    // Skip all but the start.
    if (cave.ty != Type.Start) {
      continue;
    }

    return countPathsRecursivePart2(i, caves, &firstVisit, &secondVisit, 0);
  }

  unreachable;
}

fn countPathsRecursivePart2(index: usize,
  caves : std.ArrayList(Cave),
  firstVisit : *std.DynamicBitSet,
  secondVisit : *std.DynamicBitSet,
  depth : usize) usize {
  const ty = caves.items[index].ty;

  switch (ty) {
    Type.Start => {
      // We can only visit the start if we haven't visited anything!
      if (depth != 0) {
        return 0;
      }
    },
    Type.End => { return 1; },
    Type.Big => {},
    Type.Small => {
      // If we've visited this cave twice, we cannot visit it again!
      if (firstVisit.isSet(index)) {
        if (secondVisit.count() > 0) {
          return 0;
        }
        
        secondVisit.set(index);
      } else {
        firstVisit.set(index);
      }
    },
  }

  var total : usize = 0;

  for (caves.items[index].exits) |exit| {
    if (exit == -1) {
      break;
    }

    total += countPathsRecursivePart2(@intCast(usize, exit),
      caves,
      firstVisit,
      secondVisit,
      depth + 1);
  }
  
  if (ty == Type.Small) {
    if (secondVisit.isSet(index)) {
      secondVisit.unset(index);
    }
    else {
      std.debug.assert(firstVisit.isSet(index));
      firstVisit.unset(index);
    }
  }

  return total;
}
