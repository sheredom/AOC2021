const std = @import("std");
const print = std.debug.print;

const data = @embedFile("../data/day17.txt");

pub fn main() !void {
  var timer = try std.time.Timer.start();
  print("🎁 Max Height: {}\n", .{try highestY(data)});
  print("Day 17 - part 01 took {:15}ns\n", .{timer.lap()});
  timer.reset();

  print("🎁 Total velocities: {}\n", .{try totalVelocities(data)});
  print("Day 17 - part 02 took {:15}ns\n", .{timer.lap()});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}

fn highestY(input : []const u8) !i32 {
  const startSkip = "target area: x=";
  const removePrefix = input[startSkip.len..input.len];

  var iterator = std.mem.tokenize(removePrefix, ".,y= \r\n");

  var xLo = try std.fmt.parseInt(i32, iterator.next().?, 10);
  var xHi = try std.fmt.parseInt(i32, iterator.next().?, 10);
  var yLo = try std.fmt.parseInt(i32, iterator.next().?, 10);
  var yHi = try std.fmt.parseInt(i32, iterator.next().?, 10);

  var bestMaxHeight : i32 = std.math.minInt(i32);

  const maxXVelocityWeWillConsider : i32 = xHi + 1;
  const maxYVelocityWeWillConsider : i32 = 200;

  var yStartVel : i32 = 0;

  while (yStartVel < maxYVelocityWeWillConsider) : (yStartVel += 1) {
    var xStartVel : i32 = 0;

    while (xStartVel < maxXVelocityWeWillConsider) : (xStartVel += 1) {
      var xPos : i32 = 0;
      var yPos : i32 = 0;
      var xVel = xStartVel;
      var yVel = yStartVel;
      var maxHeight : i32 = std.math.minInt(i32);

      while (true) {
        // The probe's x position increases by its x velocity.
        xPos += xVel;

        // The probe's y position increases by its y velocity.
        yPos += yVel;

        maxHeight = std.math.max(maxHeight, yPos);

        // Due to drag, the probe's x velocity changes by 1 toward the value 0;
        // that is, it decreases by 1 if it is greater than 0, increases by 1 if
        // it is less than 0, or does not change if it is already 0.
        if (xVel > 0) {
          xVel -= 1;
        } else if (xVel < 0) {
          xVel += 1;
        }

        // Due to gravity, the probe's y velocity decreases by 1.
        yVel -= 1;

        // Detect if we've overshot the target area.
        if ((xPos > xHi) or (yPos < yLo)) {
          break;
        }

        // We now detect whether our position was in the target.
        if ((xPos >= xLo) and
            (xPos <= xHi) and
            (yPos >= yLo) and
            (yPos <= yHi)) {
          bestMaxHeight = std.math.max(bestMaxHeight, maxHeight);
          break;
        }
      }
    }
  }

  return bestMaxHeight;
}

fn totalVelocities(input : []const u8) !u32 {
  const startSkip = "target area: x=";
  const removePrefix = input[startSkip.len..input.len];

  var iterator = std.mem.tokenize(removePrefix, ".,y= \r\n");

  var xLo = try std.fmt.parseInt(i32, iterator.next().?, 10);
  var xHi = try std.fmt.parseInt(i32, iterator.next().?, 10);
  var yLo = try std.fmt.parseInt(i32, iterator.next().?, 10);
  var yHi = try std.fmt.parseInt(i32, iterator.next().?, 10);

  var total : u32 = 0;

  const maxXVelocityWeWillConsider : i32 = xHi + 1;
  const maxYVelocityWeWillConsider : i32 = 200;

  var yStartVel : i32 = -maxYVelocityWeWillConsider;

  while (yStartVel < maxYVelocityWeWillConsider) : (yStartVel += 1) {
    var xStartVel : i32 = 0;

    while (xStartVel < maxXVelocityWeWillConsider) : (xStartVel += 1) {
      var xPos : i32 = 0;
      var yPos : i32 = 0;
      var xVel = xStartVel;
      var yVel = yStartVel;

      while (true) {
        // The probe's x position increases by its x velocity.
        xPos += xVel;

        // The probe's y position increases by its y velocity.
        yPos += yVel;

        // Due to drag, the probe's x velocity changes by 1 toward the value 0;
        // that is, it decreases by 1 if it is greater than 0, increases by 1 if
        // it is less than 0, or does not change if it is already 0.
        if (xVel > 0) {
          xVel -= 1;
        } else if (xVel < 0) {
          xVel += 1;
        }

        // Due to gravity, the probe's y velocity decreases by 1.
        yVel -= 1;

        // Detect if we've overshot the target area.
        if ((xPos > xHi) or (yPos < yLo)) {
          break;
        }

        // We now detect whether our position was in the target.
        if ((xPos >= xLo) and
            (xPos <= xHi) and
            (yPos >= yLo) and
            (yPos <= yHi)) {
          total += 1;
          break;
        }
      }
    }
  }

  return total;
}

test "example_part1" {
  const input = "target area: x=20..30, y=-10..-5";
  var result = try highestY(input);
  try std.testing.expect(result == 45);
}

test "example_part2" {
  const input = "target area: x=20..30, y=-10..-5";
  var result = try totalVelocities(input);
  try std.testing.expect(result == 112);
}
