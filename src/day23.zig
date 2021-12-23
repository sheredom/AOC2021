const std = @import("std");
const print = std.debug.print;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day23.txt");

pub fn main() !void {
  var timer = try std.time.Timer.start();

  {
    var burrow = Burrow.init(data, false);

    print("🎁 Num moves: {}\n", .{try burrow.cost()});
    print("Day 23 - part 01 took {:15}ns\n", .{timer.lap()});
    timer.reset();
  }

  {
    var burrow = Burrow.init(data, true);

    print("🎁 On Cubes: {}\n", .{try burrow.cost()});
    print("Day 23 - part 02 took {:15}ns\n", .{timer.lap()});
    print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
  }
}

const Burrow = struct {
  rooms : [16]u8,
  hallway : [11]u8,
  roomSize : usize,

  pub fn init(input : []const u8, part2 : bool) @This() {
    var iterator = std.mem.tokenize(input, "#\r\n. ");

    var me = @This() {
      .rooms = [_]u8{'.'} ** 16,
      .hallway = [_]u8{'.'} ** 11,
      .roomSize = if (part2) 16 else 8,
    };

    for (me.rooms[0..8]) |*room| {
      room.* = iterator.next().?[0];
    }

    if (part2) {
      for (me.rooms[4..8]) |room, i| {
        me.rooms[12 + i] = room;
      }

      // Insert the new rooms.
      // #D#C#B#A#
      // #D#B#A#C#
      me.rooms[4] = 'D';
      me.rooms[5] = 'C';
      me.rooms[6] = 'B';
      me.rooms[7] = 'A';
      me.rooms[8] = 'D';
      me.rooms[9] = 'B';
      me.rooms[10] = 'A';
      me.rooms[11] = 'C';
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
      var index : usize = 4;

      while (index < me.roomSize) : (index += 4) {
        print("  #", .{});
        for (me.rooms[index..(index + 4)]) |p| {
          print("{c}#", .{p});
        }
        print("  \n", .{});
      }
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

      // If we're at the bottom of the room we can't be blocking anyone!
      if (room >= (me.roomSize - 4)) {
        return false;
      }

      var checkRoom = room;

      while (checkRoom < (me.roomSize - 4)) : (checkRoom += 4) {
        if (targetRoom(me.rooms[checkRoom + 4]) == (checkRoom % 4)) {
          return false;
        }
      }
    } else if (me.hallway[hallway] != '.') {
      const target = targetRoom(me.hallway[hallway]);
      var index : usize = 0;
      while (index < me.roomSize) : (index += 4) {
        const roomValue = me.rooms[target + index];

        if (roomValue == '.') {
          continue;
        } else if (roomValue != me.hallway[hallway]) {
          return false;
        }
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
    {
      var index : usize = 0;

      while (index < me.roomSize) : (index += 4) {
        for (me.rooms[index..(index + 4)]) |r, ri| {
          if (index >= 4 and me.rooms[index - 4 + ri] != '.') {
            continue;
          }

          switch (r) {
            'A', 'B', 'C', 'D' => {
              for (me.hallway) |h, hi| {
                if (me.isLegalMove(ri + index, hi)) {
                  moves.append(ri + index, hi);
                }
              }
            },
            '.' => {},
            else => unreachable,
          }
        }
      }
    }

    for (me.hallway) |h, hi| {
      switch (h) {
        'A', 'B', 'C', 'D' => {
          var ri = targetRoom(h);
          var offset : usize = 0;
          if (me.rooms[ri] == '.' and me.isLegalMove(ri, hi)) {
            // Check if the full room is empty, if so we'll move to the bottom
            // position.
            var index : usize = 4;

            while (index < me.roomSize) : (index += 4) {
              if (me.rooms[ri + index] == '.') {
                offset += 4;
              }
            }

            moves.append(ri + offset, hi);
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
    for (me.rooms[0..me.roomSize]) |r, ri| {
      switch (ri % 4) {
        0 => if (r != 'A') return false,
        1 => if (r != 'B') return false,
        2 => if (r != 'C') return false,
        3 => if (r != 'D') return false,
        else => unreachable,
      }
    }

    return true;
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

  {
    var burrow = Burrow.init(input, false);
    const result = try burrow.cost();
    try std.testing.expect(result == 12521);
  }

  {
    var burrow = Burrow.init(input, true);
    const result = try burrow.cost();
    try std.testing.expect(result == 44169);
  }
}