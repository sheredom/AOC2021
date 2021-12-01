const std = @import("std");
const print = std.debug.print;

const data = @embedFile("../data/day01.txt");

fn is_int(c : u8) bool {
  return switch (c) {
      '0' => true,
      '1' => true,
      '2' => true,
      '3' => true,
      '4' => true,
      '5' => true,
      '6' => true,
      '7' => true,
      '8' => true,
      '9' => true,
      else => false
    };
}

fn day01() void {
  var index : usize = 0;
  var start : usize = index;

  // Initialize the previous depth to the maximum size of our integer, that way
  // we'll never mistake it for a valid depth increase!
  var previous_depth : u16 = std.math.maxInt(u16);

  var depth_increases : u32 = 0;

  while (index < data.len) : (index += 1) {
    if (!is_int(data[index]) and (start < index)) {
      var depth = std.fmt.parseInt(u16, data[start..index], 10) catch |err| @panic("SHIT");
      start = index + 1;

      if (depth > previous_depth) {
        depth_increases += 1;
      }

      previous_depth = depth;
    }
  }

  print("🎁 Depth increases: {}\n", .{depth_increases});
}

fn day02() void {
  var index : usize = 0;
  var start : usize = index;

  var depth_increases : u32 = 0;

  var window = [3]u32{0, 0, 0};
  var window_index : usize = 0;

  // First we accumulate enough data to get us started.
  while (index < data.len) : (index += 1) {
    if (!is_int(data[index]) and (start < index)) {
      var depth = std.fmt.parseInt(u32, data[start..index], 10) catch |err| @panic("SHIT");
      start = index + 1;
      
      window[window_index] = depth;

      window_index += 1;

      if (window_index == window.len) {
        break;
      }
    }
  }

  // We've parsed the first three elements into each bit of the window, which
  // isn't where they need to be. We accumulate all three into the first
  // element, the last two into the second element, and leave the third alone.
  window[0] += window[1] + window[2];
  window[1] += window[2];
  window_index = 0;

  // Now we do the actual check.
  while (index < data.len) : (index += 1) {
    if (!is_int(data[index]) and (start < index)) {
      var depth = std.fmt.parseInt(u32, data[start..index], 10) catch |err| @panic("SHIT");
      start = index + 1;

      var result = window[window_index];

      // Wipe out the window because we've consumed its value for comparison.
      window[window_index] = 0;

      // Wrap the window around to its new location.
      window_index += 1;
      window_index %= window.len;

      // Record the depth into each window location.
      for (window) |*item| {
        item.* += depth;
      }
      
      if (window[window_index] > result) {
        depth_increases += 1;
      }
    }
  }

  print("🎁 Three-window increases: {}\n", .{depth_increases});
}

pub fn main() !void {
  var timer = try std.time.Timer.start();
  day01();
  var part01 = timer.lap();
  print("Day 01 - part 01 took {:12}ns\n", .{part01});
  timer.reset();
  day02();
  var part02 = timer.lap();
  print("Day 01 - part 02 took {:12}ns\n", .{part02});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}
