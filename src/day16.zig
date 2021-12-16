const std = @import("std");
const print = std.debug.print;

const data = @embedFile("../data/day16.txt");

pub fn main() !void {
  var timer = try std.time.Timer.start();
  print("🎁 Total versions: {}\n", .{totalVersionInPacket(data)});
  print("Day 16 - part 01 took {:15}ns\n", .{timer.lap()});
  timer.reset();

  print("🎁 Evaluation: {}\n", .{evaluatePacket(data)});
  print("Day 16 - part 02 took {:15}ns\n", .{timer.lap()});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}

const Packet = struct {
  input : []const u8,
  bitOffset : u32,

  pub fn init(input : []const u8) @This() {
    return @This() { .input = input, .bitOffset = 0 };
  }

  pub fn skipBits(this: *@This(), bits : u32) void {
    this.bitOffset += bits;
  }

  pub fn readBits(this : *@This(), comptime T : type) T {
    const numBits : u32 = @typeInfo(T).Int.bits;

    // We support at most 32-bits read this way.
    std.debug.assert(numBits <= @typeInfo(u32).Int.bits);

    // Input is in hex.
    const inputLo = this.bitOffset / 4;
    const inputHi = std.math.min(this.input.len, (this.bitOffset + numBits + 4) / 4);

    const slice = this.input[inputLo..inputHi];

    var sliceAsInt : u32 = std.fmt.parseInt(u32, slice, 16) catch unreachable;

    // Our algorithm effectively always needs a pad hex character on the end,
    // so if we end up on the last word, add a pad character by shiting by 4.
    if (((this.bitOffset + numBits + 4) / 4) > this.input.len) {
      sliceAsInt <<= 4;
    }

    const sliceHi = 4 - ((this.bitOffset + numBits) % 4);

    // Remove any trailing bits that don't form part of our result.
    sliceAsInt >>= @intCast(u5, sliceHi);

    // Remove any leading bits that don't form part of our result.
    sliceAsInt &= (1 << numBits) - 1;

    // Move the bit offset on.
    this.bitOffset += numBits;

    return @intCast(T, sliceAsInt);
  }

  pub fn totalVersion(this : *@This()) u32 {
    const version = this.readBits(u3);
    const typeId = this.readBits(u3);

    var total : u32 = version;

    switch (typeId) {
      4 => {
        var decimal : u32 = 0;

        // We've got a literal!
        while (this.readBits(u1) == 1) {
          const bits = @intCast(@TypeOf(decimal), this.readBits(u4));
          decimal <<= 4;
          decimal |= bits;
        }

        const bits = @intCast(@TypeOf(decimal), this.readBits(u4));
        decimal <<= 4;
        decimal |= bits;
      },
      else => {
        // Check the 'length type ID'.
        if (this.readBits(u1) == 0) {
          // If the length type ID is 0, then the next 15 bits are a number that
          // represents the total length in bits of the sub-packets contained by
          // this packet.
          const lengthInBits = this.readBits(u15);
          
          const currentOffset = this.bitOffset;

          while ((currentOffset + lengthInBits) != this.bitOffset) {
            total += this.totalVersion();
          }
        } else {
          const numSubPackets = this.readBits(u11);

          var index : u32 = 0;

          while (index < numSubPackets) : (index += 1) {
            total += this.totalVersion();
          }
        }
      },
    }

    return total;
  }

  fn foldResult(typeId : u3, a : u64, b : u64) u64 {
    switch (typeId) {
      0 => return a + b,
      1 => return a * b,
      2 => return std.math.min(a, b),
      3 => return std.math.max(a, b),
      5 => return if (a > b) 1 else 0,
      6 => return if (a < b) 1 else 0,
      7 => return if (a == b) 1 else 0,
      else => unreachable,
    }
  }

  pub fn evaluate(this : *@This()) u64 {
    const version = this.readBits(u3);
    const typeId = this.readBits(u3);

    switch (typeId) {
      4 => {
        var decimal : u64 = 0;

        // We've got a literal!
        while (this.readBits(u1) == 1) {
          const bits = @intCast(@TypeOf(decimal), this.readBits(u4));
          decimal <<= 4;
          decimal |= bits;
        }

        const bits = @intCast(@TypeOf(decimal), this.readBits(u4));
        decimal <<= 4;
        decimal |= bits;

        return decimal;
      },
      else => {
        // Check the 'length type ID'.
        if (this.readBits(u1) == 0) {
          // If the length type ID is 0, then the next 15 bits are a number that
          // represents the total length in bits of the sub-packets contained by
          // this packet.
          const lengthInBits = this.readBits(u15);
          
          const currentOffset = this.bitOffset;

          var result : ?u64 = null;

          while ((currentOffset + lengthInBits) != this.bitOffset) {
            const subPacketResult = this.evaluate();

            if (result == null) {
              result = subPacketResult;
            } else {
              result = foldResult(typeId, result.?, subPacketResult);
            }
          }

          return result.?;
        } else {
          const numSubPackets = this.readBits(u11);

          var result : ?u64 = null;

          var index : u32 = 0;

          while (index < numSubPackets) : (index += 1) {
            const subPacketResult = this.evaluate();

            if (result == null) {
              result = subPacketResult;
            } else {
              result = foldResult(typeId, result.?, subPacketResult);
            }
          }

          return result.?;
        }
      },
    }

    return total;
  }
};

fn totalVersionInPacket(input : []const u8) u32 {
  var packet = Packet.init(input);
  return packet.totalVersion();
}

fn evaluatePacket(input : []const u8) u64 {
  var packet = Packet.init(input);
  return packet.evaluate();
}

test "D2FE28" {
  const input = "D2FE28";
  try std.testing.expect(totalVersionInPacket(input) == 6);
}

test "38006F45291200" {
  const input = "38006F45291200";
  try std.testing.expect(totalVersionInPacket(input) == 9);
}

test "EE00D40C823060" {
  const input = "EE00D40C823060";
  try std.testing.expect(totalVersionInPacket(input) == 14);
}

test "8A004A801A8002F478" {
  const input = "8A004A801A8002F478";
  try std.testing.expect(totalVersionInPacket(input) == 16);
}

test "620080001611562C8802118E34" {
  const input = "620080001611562C8802118E34";
  try std.testing.expect(totalVersionInPacket(input) == 12);
}

test "C0015000016115A2E0802F182340" {
  const input = "C0015000016115A2E0802F182340";
  try std.testing.expect(totalVersionInPacket(input) == 23);
}

test "A0016C880162017C3686B18A3D4780" {
  const input = "A0016C880162017C3686B18A3D4780";
  try std.testing.expect(totalVersionInPacket(input) == 31);
}

test "C200B40A82" {
  const input = "C200B40A82";
  try std.testing.expect(evaluatePacket(input) == 3);
}

test "04005AC33890" {
  const input = "04005AC33890";
  try std.testing.expect(evaluatePacket(input) == 54);
}

test "880086C3E88112" {
  const input = "880086C3E88112";
  try std.testing.expect(evaluatePacket(input) == 7);
}

test "CE00C43D881120" {
  const input = "CE00C43D881120";
  try std.testing.expect(evaluatePacket(input) == 9);
}

test "D8005AC2A8F0" {
  const input = "D8005AC2A8F0";
  try std.testing.expect(evaluatePacket(input) == 1);
}

test "F600BC2D8F" {
  const input = "F600BC2D8F";
  try std.testing.expect(evaluatePacket(input) == 0);
}

test "9C005AC2F8F0" {
  const input = "9C005AC2F8F0";
  try std.testing.expect(evaluatePacket(input) == 0);
}

test "9C0141080250320F1802104A08" {
  const input = "9C0141080250320F1802104A08";
  try std.testing.expect(evaluatePacket(input) == 1);
}
