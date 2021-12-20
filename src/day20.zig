const std = @import("std");
const print = std.debug.print;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day20.txt");

const Image = struct {
  key : std.StaticBitSet(512),
  payload : std.DynamicBitSet,
  infinitePixelIndex : usize,

  pub fn deinit(me : *@This()) void {
    me.payload.deinit();
  }

  pub fn initEmpty(allocator : *std.mem.Allocator) !@This() {
    return Image {
      .key = std.StaticBitSet(512).initEmpty(),
      .payload = try std.DynamicBitSet.initEmpty(0, allocator),
      .infinitePixelIndex = 0,
    };
  }

  pub fn setKey(me : *@This(), key: []const u8) !void {
    std.debug.assert(key.len == 512);

    for (key) |c, i| {
      if (c == '#') {
        me.key.set(i);
      } else {
        // We set the initial infinite pixel index to any dark region of the key
        // because we know from the input that the infinite region is initially
        // all dark.
        me.infinitePixelIndex = i;
      }
    }
  }

  pub fn addRow(me : *@This(), row : []const u8) !void {
    const offset = me.payload.capacity();
    try me.payload.resize(me.payload.capacity() + row.len, false);

    for (row) |c, i| {
      if (c == '#') {
        me.payload.set(offset + i);
      }
    }
  }

  // Calculate whether a is in the range [offset..(offset + width))
  fn inBounds(a : usize, offset : i32, width : usize) bool {
    if (offset < 0) {
      const poffset = @intCast(usize, -offset);
      if (a < poffset) {
        return false;
      } else {
        return (a - poffset) < width;
      }
    } else {
      return (a + @intCast(usize, offset)) < width;
    }
  }

  fn doOffset(a : usize, o : i32) usize {
    if (o < 0) {
      return a - @intCast(usize, -o);
    } else {
      return a + @intCast(usize, o);
    }
  }

  fn lookupKeyIndex(me : *const @This(),
    infinitePixel : bool,
    newWidth : usize,
    x : usize,
    y : usize) usize {
    var values = [9]bool {
      infinitePixel, infinitePixel, infinitePixel,
      infinitePixel, infinitePixel, infinitePixel,
      infinitePixel, infinitePixel, infinitePixel};

    const originalWidth = newWidth - 4;

    var index : usize = 0;

    var yOffset : i32 = -3;
    
    while (yOffset <= -1) : (yOffset += 1) {
     var xOffset : i32 = -3;
    
      while (xOffset <= -1) : (xOffset += 1) {
        if (inBounds(x, xOffset, originalWidth) and inBounds(y, yOffset, originalWidth)) {
          values[index] = me.payload.isSet(doOffset(y, yOffset) * originalWidth + doOffset(x, xOffset));
        }

        index += 1;
      }
    }

    var result : usize = 0;
    
    for (values) |v| {
      result <<= 1;
      if (v) {
        result |= 1;
      }
    }

    return result;
  }

  pub fn dump(me : *const @This()) void {
    const width = std.math.sqrt(me.payload.capacity());

    var y : usize = 0;
    while (y < width) : (y += 1) {
      var x : usize = 0;
      while (x < width) : (x += 1) {
        const c : u8 = if (me.payload.isSet(y * width + x)) '#' else '.';
        print("{c}", .{c});
      }
      print("\n", .{});
    }
  }

  pub fn enhance(me : *@This()) !void {
    // First thing we need to do is increase our image canvas to account for
    // the new pixels.
    const originalWidth = std.math.sqrt(me.payload.capacity());

    // the 'interesting' region of the infinite image occurs 2 pixels in each
    // direction beyond our original image.
    const newWidth = 2 + originalWidth + 2;

    const newSize = newWidth * newWidth;

    const infinitePixel = me.key.isSet(me.infinitePixelIndex);

    // Set the infinite pixel index. This pixel index is the value that the rest
    // of the infinite image would be, assuming that it starts as dark pixels
    // (as the problem described). 9 dark pixels will map to the 0'th key in the
    // input (which cheekily in my input is #), and 9 light pixels will map to
    // the last index (which cheekily in my input is 0). This means that the
    // index of the infinite region can flip between lit/dark pixels on each
    // enhance, gross!
    me.infinitePixelIndex = if (infinitePixel) me.key.capacity() - 1 else 0;

    const newInfinitePixel = me.key.isSet(me.infinitePixelIndex);

    var new = if (newInfinitePixel) 
      try std.DynamicBitSet.initFull(newSize, me.payload.allocator) else
      try std.DynamicBitSet.initEmpty(newSize, me.payload.allocator);

    {
      var y : usize = 0;

      while (y < newWidth) : (y += 1) {
        var x : usize = 0;

        while (x < newWidth) : (x += 1) {
          const keyIndex = me.lookupKeyIndex(infinitePixel, newWidth, x, y);
          const value = me.key.isSet(keyIndex);

          new.setValue(y * newWidth + x, value);
        }
      }
    }

    me.payload.deinit();
    me.payload = new;
  }

  pub fn count(me : *const @This()) usize {
    std.debug.assert(!me.key.isSet(me.infinitePixelIndex));
    return me.payload.count();
  }
};

pub fn parseInput(input : []const u8) !Image {
  var image = try Image.initEmpty(gpa);

  var iterator = std.mem.tokenize(input, "\r\n");

  try image.setKey(iterator.next().?);

  while (iterator.next()) |line| {
    try image.addRow(line);
  }

  return image;
}

pub fn main() !void {
  var timer = try std.time.Timer.start();
  var image = try parseInput(data);
  defer { image.deinit(); }

  var index : u32 = 0;

  while (index < 50) : (index += 1) {
    if (index == 2) {
      print("🎁 Lit after 2: {}\n", .{image.count()});
      print("Day 20 - part 01 took {:15}ns\n", .{timer.lap()});
      timer.reset();
    }

    try image.enhance();
  }

  print("🎁 Lit after 50: {}\n", .{image.count()});
  print("Day 20 - part 02 took {:15}ns\n", .{timer.lap()});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}

test "example" {
  const input = \\..#.#..#####.#.#.#.###.##.....###.##.#..###.####..#####..#....#..#..##..###..######.###...####..#..#####..##..#.#####...##.#.#..#.##..#.#......#.###.######.###.####...#.##.##..#..#..#####.....#.#....###..#.##......#.....#..#..#..##..#...##.######.####.####.#.#...#.......#..#.#.#...####.##.#......#..#...##.#.##..#...##.#.##..###.#......#.#.......#.#.#.####.###.##...#.....####.#..#..#.##.#....##..#.####....##...##..#...#......#.#.......#.......##..####..#...#.#.#...##..#.#..###..#####........#..####......#..#
\\
\\#..#.
\\#....
\\##..#
\\..#..
\\..###
;

  var image = try parseInput(input);
  defer { image.deinit(); }

  var index : u32 = 0;

  while (index < 50) : (index += 1) {
    if (index == 2) {
      try std.testing.expect(image.count() == 35);
    }
    try image.enhance();
  }

  try std.testing.expect(image.count() == 3351);
}