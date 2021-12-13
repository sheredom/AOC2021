const std = @import("std");
const print = std.debug.print;

const data = @embedFile("../data/day08.txt");

pub fn count_overlap(haystack: []const u8, needle: []const u8) u8 {
  var count : u8 = 0;
  for (haystack) |h| {
    for (needle) |n| {
      if (h == n) {
        count += 1;
      }
    }
  }

  return count;
}

pub fn main() !void {
  var timer = try std.time.Timer.start();

  {
    var lines = std.mem.tokenize(data, "\r\n");

    var total : u32 = 0;

    while (lines.next()) |line| {
      var unique_signal_values_or_input = std.mem.tokenize(line, "|");
      var unique_signal_values = unique_signal_values_or_input.next().?;
      var inputs = unique_signal_values_or_input.next().?;

      var inputs_iterator = std.mem.tokenize(inputs, " ");

      while (inputs_iterator.next()) |input| {
        total += switch (input.len) {
          2, 3, 4, 7 => 1,
          else => @as(u32, 0)
        };
      }
    }

    print("🎁 Total 1, 4, 7, 8 digits: {}\n", .{total});
    print("Day 08 - part 01 took {:15}ns\n", .{timer.lap()});
    timer.reset();
  }

  {
    var lines = std.mem.tokenize(data, "\r\n");

    var total : usize = 0;

    while (lines.next()) |line| {
      var digits = [_]?[]const u8{null} ** 10;

      var unique_signal_values_or_input = std.mem.tokenize(line, "|");
      var unique_signal_values = unique_signal_values_or_input.next().?;

      {
        var iterator = std.mem.tokenize(unique_signal_values, " ");

        // First we record the easy ones: 2, 4, 3, & 7
        while (iterator.next()) |unique_signal_value| {
          switch (unique_signal_value.len) {
            2 => digits[1] = unique_signal_value,
            4 => digits[4] = unique_signal_value,
            3 => digits[7] = unique_signal_value,
            7 => digits[8] = unique_signal_value,
            else => {},
          }
        }
      }

      {
        var iterator = std.mem.tokenize(unique_signal_values, " ");

        while (iterator.next()) |unique_signal_value| {
          // 3 is the only digit with 5 segments that contains 1
          if (unique_signal_value.len == 5) {
            const overlap = count_overlap(unique_signal_value, digits[1].?);

            if (overlap == 2) {
              digits[3] = unique_signal_value;
            }
          }

          // 6 is the only digit with 6 segments that does not contain 1
          if (unique_signal_value.len == 6) {
            const overlap = count_overlap(unique_signal_value, digits[1].?);

            if (overlap != 2) {
              digits[6] = unique_signal_value;
            }
          }

          // 9 is the only digit with 6 segments that contains 4
          if (unique_signal_value.len == 6) {
            const overlap = count_overlap(unique_signal_value, digits[4].?);

            if (overlap == 4) {
              digits[9] = unique_signal_value;
            }
          }
        }
      }

      {
        var iterator = std.mem.tokenize(unique_signal_values, " ");

        while (iterator.next()) |unique_signal_value| {
          // 5 is the only digit with 5 segments that is contained in 6, and
          // 2 is the only digit with 5 segments that has 4 overlaps with 6, and
          // does not contain 1 (this excludes 3)
          if (unique_signal_value.len == 5) {
            const overlap = count_overlap(unique_signal_value, digits[6].?);

            if (overlap == 5) {
              digits[5] = unique_signal_value;
            }
            
            if (overlap == 4) {
              if (1 == count_overlap(unique_signal_value, digits[1].?)) {
                digits[2] = unique_signal_value;
              }
            }
          }

          // 0 is the only digit with 6 segments that isn't 6 or 9
          if (unique_signal_value.len == 6) {
            if ((6 != count_overlap(unique_signal_value, digits[6].?)) and
              (6 != count_overlap(unique_signal_value, digits[9].?))) {
                digits[0] = unique_signal_value;
              }
          }
        }
      }

      var output : usize = 0;

      var inputs = unique_signal_values_or_input.next().?;

      var inputs_iterator = std.mem.tokenize(inputs, " ");

      while (inputs_iterator.next()) |input| {
        for (digits) |digit, i| {
          if (input.len != digit.?.len) {
            continue;
          }

          if (input.len != count_overlap(input, digit.?)) {
            continue;
          }

          output *= 10;
          output += i;
          break;
        }
      }

      total += output;
    }

    print("🎁 Total output values: {}\n", .{total});
    print("Day 08 - part 02 took {:15}ns\n", .{timer.lap()});
    print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
  }
}
