const std = @import("std");
const print = std.debug.print;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day23.txt");

pub fn main() !void {
  var timer = try std.time.Timer.start();
  var burrow = Burrow.init(data);

  print("🎁 Num moves: {}\n", .{try burrow.cost()});
  print("Day 23 - part 01 took {:15}ns\n", .{timer.lap()});
  timer.reset();

  print("🎁 On Cubes: {}\n", .{42});
  print("Day 23 - part 02 took {:15}ns\n", .{timer.lap()});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}

const Burrow = struct {
  rooms : [8]u8,
  hallway : [11]u8,

  pub fn init(input : []const u8) @This() {
    var iterator = std.mem.tokenize(input, "#\r\n. ");

    var me = @This() {
      .rooms = [_]u8{'.'} ** 8,
      .hallway = [_]u8{'.'} ** 11,
    };

    for (me.rooms) |*room| {
      room.* = iterator.next().?[0];
    }

    return me;
  }

  pub fn dump(me : *const @This()) void {
    {
      var index : u32 = 0;
      while (index < 13) : (index += 1) {
        print("#", .{});
      }
      print("\n", .{});
    }

    {
      print("#", .{});
      var index : u32 = 0;
      for (me.hallway) |p| {
        print("{c}", .{p});
      }
      print("#\n", .{});
    }

    {
      print("###", .{});
      var index : u32 = 0;
      for (me.rooms[0..4]) |p| {
        print("{c}#", .{p});
      }
      print("##\n", .{});
    }

    {
      print("  #", .{});
      var index : u32 = 0;
      for (me.rooms[4..8]) |p| {
        print("{c}#", .{p});
      }
      print("  \n", .{});
    }

    {
      print("  ", .{});
      var index : u32 = 0;
      while (index < 9) : (index += 1) {
        print("#", .{});
      }
      print("  \n", .{});
    }
  }

  const Move = struct {
    room : usize,
    hallway : usize,
  };

  const Moves = struct {
    const maxSize : usize = 32;
    payload : [maxSize]Move,
    size : usize,

    pub fn init() @This() {
      return @This() {
        .payload = undefined,
        .size = 0,
      };
    }

    pub fn append(me : *@This(), room : usize, hallway : usize) void {
      if (me.size >= maxSize) {
        unreachable;
      }

      me.payload[me.size] = Move { .room = room, .hallway = hallway };
      me.size += 1;
    }

    pub fn moves(me : *const @This()) []const Move {
      return me.payload[0..me.size];
    }
  };

  fn isLegalMove(me : *const @This(), room : usize, hallway : usize) bool {
    // We are not allowed to move into the hallway and stop outside a room.
    if (hallway >= 2 and hallway <= 8 and (hallway % 2) == 0) {
      return false;
    }

    const inRoom = me.rooms[room] != '.';

    // We cannot leave the room we are already meant to be in...
    if (inRoom and targetRoom(me.rooms[room]) == (room % 4)) {
      // ... unless we are blocking someone who isn't meant to be in our room
      // in there!
      if (room < 4) {
        if (targetRoom(me.rooms[room + 4]) == (room % 4)) {
          return false;
        }
      } else {
        return false;
      }
    }

    const roomToHallwayTranslation = translateRoomToHallway(room);

    var lo = std.math.min(roomToHallwayTranslation, hallway);
    var hi = std.math.max(roomToHallwayTranslation, hallway) + 1;

    // If we aren't in the room, we need to skip ourselves when checking if the
    // hallway is clear.
    if (!inRoom) {
      if (lo == hallway) {
        lo += 1;
      } else {
        hi -= 1;
      }
    }

    for (me.hallway[lo..hi]) |p, pi| {
      // If the space is occupied, we cannot move to it or through it.
      if (p != '.') {
        return false;
      }
    }

    if (room == 1 and me.rooms[room] == 'C') {
      me.dump();
    }
    return true;
  }

  fn translateRoomToHallway(room : usize) usize {
    return 2 + (2 * (room % 4));
  }

  fn targetRoom(p : u8) usize {
    switch (p) {
      'A' => return 0,
      'B' => return 1,
      'C' => return 2,
      'D' => return 3,
      else => unreachable,
    }
  }

  fn possibleMoves(me : *const @This()) Moves {
    var moves = Moves.init();

    // First we check the top positions in each room for moves.
    for (me.rooms[0..4]) |r, ri| {
      switch (r) {
        'A', 'B', 'C', 'D' => {
          for (me.hallway) |h, hi| {
            if (me.isLegalMove(ri, hi)) {
              moves.append(ri, hi);
            }
          }
        },
        '.' => {
          // An empty top position we cannot move from, but we can maybe move
          // from the bottom position in the room!
          switch (me.rooms[ri + 4]) {
            'A', 'B', 'C', 'D' => {
              for (me.hallway) |h, hi| {
                if (me.isLegalMove(ri + 4, hi)) {
                  moves.append(ri + 4, hi);
                }
              }
            },
            '.' => {},
            else => unreachable,
          }
        },
        else => unreachable,
      }
    }

    for (me.hallway) |h, hi| {
      switch (h) {
        'A', 'B', 'C', 'D' => {
          var ri = targetRoom(h);
          if (me.rooms[ri] == '.' and me.isLegalMove(ri, hi)) {
            // Check if the full room is empty, if so we'll move to the bottom
            // position.
            if (me.rooms[ri + 4] == '.') {
              ri += 4;
            }

            moves.append(ri, hi);
          }
        },
        '.' => {},
        else => unreachable,
      }
    }

    return moves;
  }

  fn moveCost(me : *const @This(), move : Move) usize {
    var numMoves : usize = (move.room / 4) + 1;
    const roomToHallwayTranslation = translateRoomToHallway(move.room);

    numMoves += 
      std.math.max(roomToHallwayTranslation, move.hallway) -
      std.math.min(roomToHallwayTranslation, move.hallway);

    const room = me.rooms[move.room];
    const hallway = me.hallway[move.hallway];

    const p = if (room == '.') hallway else room;

    switch (p) {
      'A' => return numMoves * 1,
      'B' => return numMoves * 10,
      'C' => return numMoves * 100,
      'D' => return numMoves * 1000,
      else => unreachable,
    }
  }

  fn finished(me : *const @This()) bool {
    return
      me.rooms[0] == 'A' and
      me.rooms[1] == 'B' and
      me.rooms[2] == 'C' and
      me.rooms[3] == 'D' and
      me.rooms[4] == 'A' and
      me.rooms[5] == 'B' and
      me.rooms[6] == 'C' and
      me.rooms[7] == 'D';
  }

  const Potential = struct {
    burrow : Burrow,
    theCost : usize,

    pub fn init(burrow : Burrow, theCost : usize) @This() {
      return @This() {
        .burrow = burrow,
        .theCost = theCost,
      };
    }
  };

  fn cost(me : *const @This()) !usize {
    var search = std.ArrayList(Potential).init(gpa);
    var reducer = std.AutoHashMap(Burrow, usize).init(gpa);

    try search.append(Potential.init(me.*, 0));

    var result : ?usize = null;

    while (search.items.len != 0) {
      const pop = search.swapRemove(0);

      var seenAlready = reducer.get(pop.burrow);
      
      if (seenAlready == null) {
        try reducer.put(pop.burrow, pop.theCost);
      } else {
        if (seenAlready.? <= pop.theCost) {
          // Skip processing this one because we've got to this position once
          // before but with a lower cost.
          continue;
        }

        try reducer.put(pop.burrow, pop.theCost);
      }

      // If we've already found at least one result, and it is cheaper than the
      // current searched result, don't check it any further.
      if (result != null) {
        if (result.? <= pop.theCost) {
          continue;
        }
      }

      const searchResult = try pop.burrow.searchCost(pop.theCost, &search);

      if (searchResult != null) {
        if (result == null) {
          result = searchResult.?;
        } else {
          result = std.math.min(result.?, searchResult.?);
        }
      }
    }

    return result.?;
  }

  fn searchCost(me : *const @This(), inputCost : usize, search : *std.ArrayList(Potential)) !?usize {
    const moves = me.possibleMoves();

    var mi : usize = 0;

    while (mi < moves.size) : (mi += 1) {
      const move = moves.payload[mi];
      var newMe = me.*;
      
      const myMoveCost = me.moveCost(move);
      const moveIntoRoom = newMe.rooms[move.room] == '.';

      if (moveIntoRoom) {
        newMe.rooms[move.room] = newMe.hallway[move.hallway];
        newMe.hallway[move.hallway] = '.';
      } else {
        newMe.hallway[move.hallway] = newMe.rooms[move.room];
        newMe.rooms[move.room] = '.';
      }

      const totalCost = inputCost + myMoveCost;

      if (newMe.finished()) {
        return totalCost;
      }
      
      try search.append(Potential.init(newMe, totalCost));
    }

    return null;
  }
};


test "example" {
  const input =
\\#############
\\#...........#
\\###B#C#B#D###
\\  #A#D#C#A#
\\  #########
;

  var burrow = Burrow.init(input);

  const result = try burrow.cost();

  try std.testing.expect(result == 12521);
}