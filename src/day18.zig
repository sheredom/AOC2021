const std = @import("std");
const print = std.debug.print;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day18.txt");

pub fn main() !void {
  var timer = try std.time.Timer.start();
  print("🎁 Magnitude: {}\n", .{try part01(data)});
  print("Day 18 - part 01 took {:15}ns\n", .{timer.lap()});
  timer.reset();

  print("🎁 Largest magnitude: {}\n", .{try part02(data)});
  print("Day 18 - part 02 took {:15}ns\n", .{timer.lap()});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}

fn part01(input: []const u8) !i32 {
  var iterator = std.mem.tokenize(input, "\r\n");

  var number = try Number.init(gpa, iterator.next().?);
  defer { number.deinit(); }

  while (iterator.next()) |i| {
    const other = try Number.init(gpa, i);
    defer { other.deinit(); }

    try number.add(other);
  }

  return number.magnitude();
}

fn part02(input: []const u8) !i32 {
  var iterator1 = std.mem.tokenize(input, "\r\n");
  var index1 : u32 = 0;

  var max : i32 = 0;

  while (iterator1.next()) |next1| {
    index1 += 1;

    var iterator2 = std.mem.tokenize(input, "\r\n");
    var index2 : u32 = 0;

    while (iterator2.next()) |next2| {
      index2 += 1;

      if (index1 == index2) {
        continue;
      }

      {
        const number1 = try Number.init(gpa, next1);
        defer { number1.deinit(); }
        var number2 = try Number.init(gpa, next2);
        defer { number2.deinit(); }
        try number2.add(number1);
        max = std.math.max(number2.magnitude(), max);
      }

      {
        var number1 = try Number.init(gpa, next1);
        defer { number1.deinit(); }
        const number2 = try Number.init(gpa, next2);
        defer { number2.deinit(); }
        try number1.add(number2);
        max = std.math.max(number1.magnitude(), max);
      }
    }
  }

  return max;
}

const Element = struct {
  lhs : i32,
  rhs : i32,
  depth : u8,
};

const Number = struct {
  payload : std.ArrayList(Element),

  pub fn deinit(me : @This()) void {
    me.payload.deinit();
  }

  pub fn init(allocator : *std.mem.Allocator, input : []const u8) !@This() {
    var payload = std.ArrayList(Element).init(allocator);

    var depth : u8 = 0;

    var lhs : i32 = -1;
    var rhs : i32 = -1;
    var isLhs = true;

    for (input) |c| {
      switch (c) {
        '[' => {
          // If we are entering another pair and we've got a lhs, we need to
          // create an element here!
          if (lhs != -1) {
            try payload.append(Element {
              .lhs = lhs,
              .rhs = rhs,
              .depth = depth,
            });
          }

          // Increase the depth as we are entering a pair.
          depth += 1;

          // And reset whether we are the lhs of a pair or not (because we are
          // entering a new pair).
          isLhs = true;

          // And reset our stored values.
          lhs = -1;
          rhs = -1;
        },
        ']' => {
          // If we are exiting another pair and we've got a rhs, we need to
          // create an element here!
          if (rhs != -1) {
            try payload.append(Element {
              .lhs = lhs,
              .rhs = rhs,
              .depth = depth,
            });
          }

          // Decrease the depth as we are exiting a pair.
          depth -= 1;

          // And reset whether we are the lhs of a pair or not.
          isLhs = true;

          // And reset our stored values.
          lhs = -1;
          rhs = -1;
        },
        ',' => {
          // The comma means the next value we have is our rhs value.
          isLhs = false;
        },
        else => {
          var digit = c - '0';
          
          if (isLhs) {
            // Check we haven't accidentally stored a valid number ih lhs.
            std.debug.assert(lhs == -1);
            lhs = digit;
          } else {
            // Check we haven't accidentally stored a valid number ih rhs.
            std.debug.assert(rhs == -1);
            rhs = digit;
          }
        }
      }
    }

    return Number {
      .payload = payload,
    };
  }

  fn assert(me : *const @This()) void {
    for (me.payload.items) |element, i| {
      std.debug.assert(element.lhs != -1 or element.rhs != -1);

      if (element.lhs == -1) {
        const left = me.payload.items[i - 1];
        std.debug.assert(i > 0);
        std.debug.assert(left.rhs != -1);
      } else if (element.rhs == -1) {
        const right = me.payload.items[i + 1];
        std.debug.assert((i + 1) < me.payload.items.len);
        std.debug.assert(right.lhs != -1);
      }
    }
  }

  pub fn reduce(me : *@This()) void {
    while (true) {
      var changed = false;

      me.assert();

      for (me.payload.items) |element, i| {
        // Explode!
        if (element.depth > 4) {
          var goLeft : bool = undefined;
          var sameDepth = false;

          std.debug.assert(element.lhs != -1);
          std.debug.assert(element.rhs != -1);

          // Check if we need to explode our pair into the left or right pairs.
          if (i > 0 and me.payload.items[i - 1].rhs == -1 and me.payload.items[i - 1].depth + 1 == element.depth) {
            // Go left!
            goLeft = true;
          } else if (i < (me.payload.items.len - 1) and me.payload.items[i + 1].lhs == -1 and me.payload.items[i + 1].depth + 1 == element.depth) {
            // Go right!
            goLeft = false;
          } else if (i < (me.payload.items.len - 1) and element.depth == me.payload.items[i + 1].depth) {
            // If we get here, it means we have two pairs that are on an equal
            // depth that are both full, and we need to fold the first one.
            sameDepth = true;
          } else {
            unreachable;
          }

          // Propagate our rhs pair value right.
          var index = i + 1;
          while (index < me.payload.items.len) : (index += 1) {
            if (me.payload.items[index].lhs != -1) {
              me.payload.items[index].lhs += element.rhs;
              break;
            }

            if (me.payload.items[index].rhs != -1) {
              me.payload.items[index].rhs += element.rhs;
              break;
            }
          }

          // Propagate our lhs pair value left.
          index = i;
          while (index > 0) : (index -= 1) {
            if (me.payload.items[index - 1].rhs != -1) {
              me.payload.items[index - 1].rhs += element.lhs;
              break;
            }

            if (me.payload.items[index - 1].lhs != -1) {
              me.payload.items[index - 1].lhs += element.lhs;
              break;
            }
          }

          if (sameDepth) {
            // If we are the same depth, we turn our left pair into a parent
            // pair instead.
            me.payload.items[i].lhs = 0;
            me.payload.items[i].rhs = -1;
            me.payload.items[i].depth -= 1;
          } else if (goLeft) {
            me.payload.items[i - 1].rhs = 0;
          } else {
            me.payload.items[i + 1].lhs = 0;
          }

          if (!sameDepth) {
            var removed = me.payload.orderedRemove(i);
          }

          changed = true;
          break;
        }
      }

      if (changed) {
        continue;
      }

      for (me.payload.items) |element, i| {
        if (element.lhs >= 10) {
          const newElement = Element {
            .lhs = @divTrunc(element.lhs, 2),
            .rhs = @divTrunc(element.lhs + 1, 2),
            .depth = element.depth + 1,
          };

          if (me.payload.items[i].rhs == -1) {
            // Replace our own pair since it is now dead.
            me.payload.items[i] = newElement;
          } else {
            // Otherwise insert the new pair for it.
            me.payload.insert(i, newElement) catch unreachable;

            // Wipe out our lhs.
            me.payload.items[i + 1].lhs = -1;
          }

          changed = true;
          break;
        }

        if (element.rhs >= 10) {
          const newElement = Element {
            .lhs = @divTrunc(element.rhs, 2),
            .rhs = @divTrunc(element.rhs + 1, 2),
            .depth = element.depth + 1,
          };

          if (me.payload.items[i].lhs == -1) {
            // Replace our own pair since it is now dead.
            me.payload.items[i] = newElement;
          } else {
            // Otherwise insert the new pair for it.
            me.payload.insert(i + 1, newElement) catch unreachable;

            // Wipe out our rhs.
            me.payload.items[i].rhs = -1;
          }

          changed = true;
          break;
        }
      }

      if (!changed) {
        break;
      }
    }
  }

  pub fn dump(me : *const @This()) void {
    print("Dump:\n", .{});
    var lastDepth : u8 = 0;
    for (me.payload.items) |element, i| {
      print("{} = ({}, {}, {})\n", .{i, element.lhs, element.rhs, element.depth});
    }
  }

  pub fn magnitude(me : *@This()) i32 {
    while (me.payload.items.len > 1) {
      for (me.payload.items) |element, i| {
        if (element.lhs != -1 and element.rhs != -1) {
          var goLeft : bool = undefined;

          // Check if we need to explode our pair into the left or right pairs.
          if (i > 0 and me.payload.items[i - 1].rhs == -1 and me.payload.items[i - 1].depth + 1 == element.depth) {
            // Go left!
            goLeft = true;
          } else if (i < (me.payload.items.len - 1) and me.payload.items[i + 1].lhs == -1 and me.payload.items[i + 1].depth + 1 == element.depth) {
            // Go right!
            goLeft = false;
          } else if ((i < (me.payload.items.len - 1)) and element.depth == me.payload.items[i + 1].depth) {
            // If we get here, it means we have two pairs that are on an equal
            // depth that are both full, and we need to fold them together.
            const other = me.payload.items[i + 1];

            if (element.lhs == -1 or element.rhs == -1 or other.lhs == -1 or other.rhs == -1) {
              continue;
            }

            me.payload.items[i].lhs = (3 * element.lhs) + (2 * element.rhs);
            me.payload.items[i].rhs = (3 * other.lhs) + (2 * other.rhs);
            me.payload.items[i].depth -= 1;

            const removed = me.payload.orderedRemove(i + 1);
            break;
          } else {
            continue;
          }

          if (goLeft) {
            me.payload.items[i - 1].rhs = (3 * element.lhs) + (2 * element.rhs);
          } else {
            me.payload.items[i + 1].lhs = (3 * element.lhs) + (2 * element.rhs);
          }

          const removed = me.payload.orderedRemove(i);
          break;
        }
      }
    }

    const element = me.payload.items[0];

    std.debug.assert(element.lhs != -1);
    std.debug.assert(element.rhs != -1);

    return (3 * element.lhs) + (2 * element.rhs);
  }

  pub fn add(me : *@This(), other: Number) !void {
    for (other.payload.items) |element| {
      try me.payload.append(element);
    }

    for (me.payload.items) |*element| {
      element.depth += 1;
    }

    me.reduce();
  }
};

test "[[1,2],[[3,4],5]]" {
  const input = "[[1,2],[[3,4],5]]";
  var number = try Number.init(gpa, input);
  number.reduce();
  const magnitude = number.magnitude();
  try std.testing.expect(magnitude == 143);
}

test "[[[[0,7],4],[[7,8],[6,0]]],[8,1]]" {
  const input = "[[[[0,7],4],[[7,8],[6,0]]],[8,1]]";
  var number = try Number.init(gpa, input);
  number.reduce();
  const magnitude = number.magnitude();
  try std.testing.expect(magnitude == 1384);
}

test "example" {
  const input = \\[[[0,[5,8]],[[1,7],[9,6]]],[[4,[1,2]],[[1,4],2]]]
\\[[[5,[2,8]],4],[5,[[9,9],0]]]
\\[6,[[[6,2],[5,6]],[[7,6],[4,7]]]]
\\[[[6,[0,7]],[0,9]],[4,[9,[9,0]]]]
\\[[[7,[6,4]],[3,[1,3]]],[[[5,5],1],9]]
\\[[6,[[7,3],[3,2]]],[[[3,8],[5,7]],4]]
\\[[[[5,4],[7,7]],8],[[8,3],8]]
\\[[9,3],[[9,9],[6,[4,9]]]]
\\[[2,[[7,7],7]],[[5,8],[[9,3],[0,2]]]]
\\[[[[5,2],5],[8,[3,7]]],[[5,[7,5]],[4,4]]]
;

  const magnitude = try part01(input);
  try std.testing.expect(magnitude == 4140);
}
