const std = @import("std");
const print = std.debug.print;

const data = @embedFile("../data/day03.txt");

const Direction = enum(u2) {
    up,
    down,
    forward
};

fn day01() !usize {
  var iterator = std.mem.tokenize(data, "\r\n");

  var accumulation = [12]i16{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

  var token_size : ?usize = null;

  while (iterator.next()) |token| {
    if (token_size == null) {
      token_size = token.len;
    } else {
      std.debug.assert(token_size.? == token.len);
    }

    for (token) |t, i| {
      if (t == '1')
      {
        accumulation[i] += 1;
      }
      else 
      {
        accumulation[i] -= 1;
      }
    }
  }

  var gamma_rate : u32 = 0;
  var epsilon_rate : u32 = 0;

  for (accumulation) |a, i| {
    if (a > 0) {
      gamma_rate |= 1;
    } else {
      epsilon_rate |= 1;
    }

    if ((i + 1) >= token_size.?) {
      break;
    }

    gamma_rate <<= 1;
    epsilon_rate <<= 1;
  }

  print("🎁 Power Consumption: {}\n", .{gamma_rate * epsilon_rate});

  return token_size.?;
}

fn day02(token_size : usize) !void {
  var oxygen_generator_rating = [12]u8{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
  var co2_generator_rating = [12]u8{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

  var bit : usize = 0;

  while (bit < token_size) : (bit += 1) {
    var iterator = std.mem.tokenize(data, "\r\n");

    var num_oxygens_alive : u32 = 0;
    var oxygen_accumulation : i16 = 0;

    var num_co2s_alive : u32 = 0;
    var co2_accumulation : i16 = 0;
    while (iterator.next()) |token| {
      if (std.mem.startsWith(u8, token, oxygen_generator_rating[0..bit])) {
        num_oxygens_alive += 1;

        if (token[bit] == '1') {
          oxygen_accumulation += 1;
        } else {
          oxygen_accumulation -= 1;
        }
      }

      if (std.mem.startsWith(u8, token, co2_generator_rating[0..bit])) {
        num_co2s_alive += 1;

        if (token[bit] == '1') {
          co2_accumulation += 1;
        } else {
          co2_accumulation -= 1;
        }
      }
    }

    if (num_oxygens_alive == 1) {
      std.debug.assert(oxygen_accumulation != 0);

      if (oxygen_accumulation == 1) {
        oxygen_generator_rating[bit] = '1';
      } else {
        oxygen_generator_rating[bit] = '0';
      }
    } else if (oxygen_accumulation >= 0) {
      oxygen_generator_rating[bit] = '1';
    } else {
      oxygen_generator_rating[bit] = '0';
    }

    if (num_co2s_alive == 1) {
      std.debug.assert(co2_accumulation != 0);
      
      if (co2_accumulation == 1) {
        co2_generator_rating[bit] = '1';
      } else {
        co2_generator_rating[bit] = '0';
      }
    } else {
      if (co2_accumulation >= 0) {
        co2_generator_rating[bit] = '0';
      } else {
        co2_generator_rating[bit] = '1';
      }
    }
  }

  // Note: This really confused me! The `parseInt` function won't stop at a null
  // terminating byte, so you need to manually slice it down to only the valid
  // characters!
  var oxygen_generator_rating_result = try std.fmt.parseInt(
    u32, oxygen_generator_rating[0..token_size], 2);
  var co2_generator_rating_result = try std.fmt.parseInt(
    u32, co2_generator_rating[0..token_size], 2);

  print("🎁 Life support rating: {}\n",
    .{oxygen_generator_rating_result * co2_generator_rating_result});
}

pub fn main() !void {
  var timer = try std.time.Timer.start();
  var token_size = try day01();
  var part01 = timer.lap();
  print("Day 03 - part 01 took {:12}ns\n", .{part01});
  timer.reset();
  try day02(token_size);
  var part02 = timer.lap();
  print("Day 03 - part 02 took {:12}ns\n", .{part02});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}
