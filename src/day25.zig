const std = @import("std");
const print = std.debug.print;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day25.txt");

pub fn main() !void {
    
  const result = try part1(data);

  print("{}\n", .{result});
}

fn part1(input : []const u8) !usize {
  var board = std.ArrayList(u8).init(gpa);
  defer board.deinit();
  var width : usize = 0;

  {
    var maybeWidth : ?usize = null;

    var lines = std.mem.tokenize(input, "\r\n");

    while (lines.next()) |line| {
      if (maybeWidth == null) {
        maybeWidth = line.len;
      } else {
        std.debug.assert(maybeWidth.? == line.len);
      }

      for (line) |c| {
        try board.append(c);
      }
    }

    width = maybeWidth.?;
  }
  
  const height = board.items.len / width;

  var step : usize = 1;

  while (true) : (step += 1)
  {
    var move = false;

    var y : usize = 0;

    while (y < height) : (y += 1) {
      var x : usize = 0;

      while (x < width) : (x += 1) {
        const index = y * width + x;

        switch (board.items[index]) {
          '>' => {
            const next = y * width + (x + 1) % width;

            if (board.items[next] == '.') {
              board.items[index] = '-';
              board.items[next] = '@';
              move = true;
            }
          },
          else => {},
        }
      }
    }

    y = 0;

    while (y < height) : (y += 1) {
      var x : usize = 0;

      while (x < width) : (x += 1) {
        const index = y * width + x;

        switch (board.items[index]) {
          '-' => {
            board.items[index] = '.';
          },
          '@' => {
            board.items[index] = '>';
          },
          else => {},
        }
      }
    }

    y = 0;

    while (y < height) : (y += 1) {
      var x : usize = 0;

      while (x < width) : (x += 1) {
        const index = y * width + x;

        switch (board.items[index]) {
          'v' => {
            const next = ((y + 1) % height) * width + x;

            if (board.items[next] == '.') {
              board.items[index] = '|';
              board.items[next] = '@';
              move = true;
            }
          },
          else => {},
        }
      }
    }

    y = 0;

    while (y < height) : (y += 1) {
      var x : usize = 0;

      while (x < width) : (x += 1) {
        const index = y * width + x;

        switch (board.items[index]) {
          '|' => {
            board.items[index] = '.';
          },
          '@' => {
            board.items[index] = 'v';
          },
          else => {},
        }
      }
    }

    if (!move) {
      return step;
    }
  }

  unreachable;
}

test "example" {
  const input =
\\v...>>.vv>
\\.vv>>.vv..
\\>>.>v>...v
\\>>v>>.>.v.
\\v>v.vv.v..
\\>.>>..v...
\\.vv..>.>v.
\\v.v..>>v.v
\\....v..v.>
;

  const result = try part1(input);

  try std.testing.expect(result == 58);
}
