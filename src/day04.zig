const std = @import("std");
const print = std.debug.print;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day04.txt");

const Board = struct {
  numbers : [25]u8,
  row_hits : [5]std.StaticBitSet(5),
  col_hits : [5]std.StaticBitSet(5),

  pub fn init() @This() {
    return Board {
      .numbers = [_]u8{0} ** 25,
      .row_hits = [_]std.StaticBitSet(5){std.StaticBitSet(5).initEmpty()} ** 5,
      .col_hits = [_]std.StaticBitSet(5){std.StaticBitSet(5).initEmpty()} ** 5,
    };
  }

  pub fn setNumber(this: *@This(), row: usize, col: usize, number: u8) void {
    this.numbers[row * 5 + col] = number;
  }

  pub fn hitNumber(this: *@This(), hit: u8) void {
    for (this.numbers) |number, i| {
      if (number == hit) {
        var row = i / 5;
        var col = i % 5;

        this.row_hits[row].set(col);
        this.col_hits[col].set(row);
      }
    }
  }

  pub fn bingo(this: *@This()) bool {
    var i : usize = 0;

    while (i < 5) : (i += 1) {
      if (this.row_hits[i].count() == 5) {
        return true;
      }

      if (this.col_hits[i].count() == 5) {
        return true;
      }
    }

    return false;
  }

  pub fn sumOfUnmarkedNumbers(this: *const @This()) u32 {
    var sum : u32 = 0;

    for (this.numbers) |number, i| {
      var row = i / 5;
      var col = i % 5;

      if (!this.row_hits[row].isSet(col)) {
        sum += number;
      }
    }

    return sum;
  }
};

pub fn main() !void {
  var timer = try std.time.Timer.start();

  var boards = std.ArrayList(Board).init(gpa);
  defer { boards.deinit(); }

  var iterator = std.mem.tokenize(data, "\r\n");

  var caller_numbers = std.mem.tokenize(iterator.next().?, ",");

  while (iterator.next()) |t| {
    var token = t;

    var board = Board.init();
    var index : usize = 0;

    while (index < 5) : (index += 1) {
      var row_iterator = std.mem.tokenize(token, " ");

      var col_index : usize = 0;

      while (row_iterator.next()) |row_token| {
        board.setNumber(index, col_index, try std.fmt.parseInt(u8, row_token, 10));
        col_index += 1;
      }

      if (index + 1 != 5) {
        token = iterator.next().?;
      }
    }

    try boards.append(board);
  }

  var found_winner = false;

  while (caller_numbers.next()) |token| {
    const call = try std.fmt.parseInt(u8, token, 10);

    for (boards.items) |*board| {
      board.hitNumber(call);
    }

    var i : usize = 0;

    while (i < boards.items.len) {
      if (boards.items[i].bingo()) {
        var board = boards.swapRemove(i);
        if (!found_winner) {
          found_winner = true;
          print("🎁 Bingo: {}\n", .{board.sumOfUnmarkedNumbers() * call});
          print("Day 04 - part 01 took {:12}ns\n", .{timer.lap()});
          timer.reset();
        }

        // If we're the last board, we've found our last bingo!
        if (boards.items.len == 0) {
          print("🎁 Last Bingo: {}\n", .{board.sumOfUnmarkedNumbers() * call});
          print("Day 04 - part 02 took {:12}ns\n", .{timer.lap()});
          timer.reset();
          return;
        }

        // We don't bump `i` if we got bingo on a board because we've swapped in
        // the last element of the list, and we need to check that one too!
      } else {
        i += 1;
      }
    }
  }

  @panic("Unreachable!");
}
