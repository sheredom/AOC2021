const std = @import("std");
const Allocator = std.mem.Allocator;
const assert = std.debug.assert;
const print = std.debug.print;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;
const Str = []const u8;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day21.txt");

pub fn main() !void {
  var timer = try std.time.Timer.start();
  var board = try Board.init(data);

  print("🎁 Score: {}\n", .{board.part1()});
  print("Day 21 - part 01 took {:15}ns\n", .{timer.lap()});
  timer.reset();

  print("🎁 Score: {}\n", .{board.part2()});
  print("Day 21 - part 02 took {:15}ns\n", .{timer.lap()});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}

const Board = struct {
  player1 : u16,
  player2 : u16,

  pub fn init(input : []const u8) !@This() {
    var iterator = std.mem.tokenize(input, " \r\n");

    var discard = iterator.next().?;
    discard = iterator.next().?;
    discard = iterator.next().?;
    discard = iterator.next().?;

    var player1 = try std.fmt.parseInt(u8, iterator.next().?, 10);

    discard = iterator.next().?;
    discard = iterator.next().?;
    discard = iterator.next().?;
    discard = iterator.next().?;

    var player2 = try std.fmt.parseInt(u8, iterator.next().?, 10);

    // -1 because the board is [1..10] but we count that as [0..10) so we can
    // use integer modulus to wrap the numbers.
    return Board {
      .player1 = player1 - 1,
      .player2 = player2 - 1,
    };
  }

  fn roll(nextRoll : *u16, diceRolls : *u16) u16 {
    // +1 because the dice goes from [1..100] but we store it as [0..100) to use
    // integer modulus for the wrapping.
    const myRoll = nextRoll.* + 1;

    nextRoll.* += 1;
    nextRoll.* %= 100;

    diceRolls.* += 1;
    
    return myRoll;
  }

  pub fn part1(me : *const @This()) u32 {
    var player1 = me.player1;
    var player2 = me.player2;
    var player1Turn = true;
    var player1Score : u16 = 0;
    var player2Score : u16 = 0;
    var nextRoll : u16 = 0;
    var diceRolls : u16 = 0;

    while (player1Score < 1000 and player2Score < 1000) {
      var score = roll(&nextRoll, &diceRolls) + 
        roll(&nextRoll, &diceRolls) +
        roll(&nextRoll, &diceRolls);

      if (player1Turn) {
        player1 += score;
        player1 %= 10;
        player1Score += player1 + 1;
      } else {
        player2 += score;
        player2 %= 10;
        player2Score += player2 + 1;
      }

      player1Turn = !player1Turn;
    }

    var score : u32 = std.math.min(player1Score, player2Score);

    return diceRolls * score;
  }

  fn dump(scores : [31]u64) void {
    print("Scores [", .{});
    for (scores) |score| {
      print("{}, ", .{score});
    }
    print("]\n", .{});
  }

  pub fn part2(me : *const @This()) u64 {
    var state = Part2State.init(me.player1, me.player2);
    var result = state.play();
    return std.math.max(result.player1Score, result.player2Score);
  }
};

const Pair = struct {
  player1Score : u64,
  player2Score : u64,

  pub fn init() @This() {
    return Pair {
      .player1Score = 0,
      .player2Score = 0,
    };
  }
};

const Part2State = struct {
  player1Turn : bool,
  player1 : u16,
  player2 : u16,
  player1Score : u64,
  player2Score : u64,
  winMultiplier : u64,

  pub fn init(player1 : u16, player2 : u16) @This() {
    return Part2State {
      .player1Turn = true,
      .player1 = player1,
      .player2 = player2,
      .player1Score = 0,
      .player2Score = 0,
      .winMultiplier = 1,
    };
  }

  pub fn play(me : *@This()) Pair {
    // These are the chances that any given 3 x rolls will end up on a given
    // result.
    const rollProbabilities = [10]u8 {0, 0, 0, 1, 3, 6, 7, 6, 3, 1};

    var wins = Pair.init();

    var index : u16 = 3;

    while (index < 10) : (index += 1) {
      var newState = me.*;

      // For each of the given chances that three rolls in [1..3], we increase
      // our multiplier for the win of the new state by that. For instance, we
      // can only roll 1, 1, 1 once, whereas we could roll 2, 1, 1 or 1, 2, 1
      // or 1, 1, 2 (all moving our score on by 4 positions).
      newState.winMultiplier *= rollProbabilities[index];

      if (newState.player1Turn) {
        newState.player1 += index;
        newState.player1 %= 10;
        newState.player1Score += newState.player1 + 1;
      } else {
        newState.player2 += index;
        newState.player2 %= 10;
        newState.player2Score += newState.player2 + 1;
      }

      if (newState.player1Turn and newState.player1Score >= 21) {
        wins.player1Score += newState.winMultiplier;
      } else if (!newState.player1Turn and newState.player2Score >= 21) {
        wins.player2Score += newState.winMultiplier;
      } else {
        newState.player1Turn = !newState.player1Turn;
        const result = newState.play();
        wins.player1Score += result.player1Score;
        wins.player2Score += result.player2Score;
      }
    }

    return wins;
  }
};

test "example" {
  const input = \\Player 1 starting position: 4
\\Player 2 starting position: 8
;

  var board = try Board.init(input);
  try std.testing.expect(board.part1() == 739785);
  try std.testing.expect(board.part2() == 444356092776315);
}
