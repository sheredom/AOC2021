const std = @import("std");
const print = std.debug.print;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day24.txt");

const Type = enum {
  // First the real instructions.
  inp,
  add,
  mul,
  div,
  mod,
  eql,

  // Then we encode a different instruction for the variants that take an imm.
  add_imm,
  mul_imm,
  div_imm,
  mod_imm,
  eql_imm,
};

const Instruction = struct {
  ty : Type,
  a : i64,
  b : i64,

  pub fn init(ty : Type, a : i64, b : i64) @This() {
    return @This() {
      .ty = ty,
      .a = a,
      .b = b,
    };
  }
};

const Program = struct {
  instructions : std.ArrayList(Instruction),

  pub fn init(input : []const u8, allocator : *std.mem.Allocator) !@This() {
    var me = @This() {
      .instructions = std.ArrayList(Instruction).init(allocator),
    };

    var lines = std.mem.tokenize(input, "\r\n");

    while (lines.next()) |line| {
      var tokens = std.mem.tokenize(line, " ");

      const instruction = tokens.next().?;

      var ty : Type = undefined;

      if (std.mem.eql(u8, instruction, "inp")) {
        ty = Type.inp;
      } else if (std.mem.eql(u8, instruction, "add")) {
        ty = Type.add;
      } else if (std.mem.eql(u8, instruction, "mul")) {
        ty = Type.mul;
      } else if (std.mem.eql(u8, instruction, "div")) {
        ty = Type.div;
      } else if (std.mem.eql(u8, instruction, "mod")) {
        ty = Type.mod;
      } else if (std.mem.eql(u8, instruction, "eql")) {
        ty = Type.eql;
      } else {
        unreachable;
      }

      // The first is always a register.
      const a = tokens.next().?[0] - 'w';

      var b : i64 = undefined;

      if (ty != Type.inp) {
        const bStr = tokens.next().?;

        switch (bStr[0]) {
          'w'...'z' => b = bStr[0] - 'w',
          else => {
            b = try std.fmt.parseInt(i64, bStr, 10);

            // Also convert our instruction into the imm form.
            switch (ty) {
              Type.add => ty = Type.add_imm,
              Type.mul => ty = Type.mul_imm,
              Type.div => ty = Type.div_imm,
              Type.mod => ty = Type.mod_imm,
              Type.eql => ty = Type.eql_imm,
              else => unreachable,
            }
          },
        }
      }

      try me.instructions.append(Instruction.init(ty, a, b));
    }

    return me;
  }

  pub fn deinit(me : @This()) void {
    me.instructions.deinit();
  }

  const State = struct {
    registers : [4]i64,
    index : usize,
  };

  pub fn part1(me : *const @This(), input : [14]u8, map : *std.AutoHashMap(i64, State)) bool {    
    var inputIndex : u8 = 0;

    var registers = [_]i64{0} ** 4;

    for (me.instructions.items) |instruction| {
      const a = instruction.a;
      const b = instruction.b;
      
      switch (instruction.ty) {
        Type.inp => {
          registers[@intCast(usize, @intCast(usize, a))] = input[inputIndex];
          inputIndex += 1;
        },
        Type.add => registers[@intCast(usize, a)] += registers[@intCast(usize, b)],
        Type.mul => registers[@intCast(usize, a)] *= registers[@intCast(usize, b)],
        Type.div => registers[@intCast(usize, a)] = @divTrunc(registers[@intCast(usize, a)], registers[@intCast(usize, b)]),
        Type.mod => registers[@intCast(usize, a)] = @mod(registers[@intCast(usize, a)], registers[@intCast(usize, b)]),
        Type.eql => registers[@intCast(usize, a)] = if (registers[@intCast(usize, a)] == registers[@intCast(usize, b)]) 1 else 0,
        Type.add_imm => registers[@intCast(usize, a)] += b,
        Type.mul_imm => registers[@intCast(usize, a)] *= b,
        Type.div_imm => registers[@intCast(usize, a)] = @divTrunc(registers[@intCast(usize, a)], b),
        Type.mod_imm => registers[@intCast(usize, a)] = @mod(registers[@intCast(usize, a)], b),
        Type.eql_imm => registers[@intCast(usize, a)] = if (registers[@intCast(usize,a)] == b) 1 else 0,
      }

      print("{} {} {} [{} {} {} {}]\n", .{instruction.ty, a, b, registers[0], registers[1], registers[2], registers[3]});
    }

    return registers['z' - 'w'] == 0;
  }
};

pub fn main() !void {
  const program = try Program.init(data, gpa);
  defer program.deinit();

  var input = [_]u8{1} ** 14;

  var map = std.AutoHashMap(i64, void).init(gpa);

  var discard = program.part1(input, &map);
  if (!discard) {
    unreachable;
  }

  // Best guess so far was 99999952878116
  while (!program.part1(input, &map)) {
    var index : u8 = 14;

    while (index > 0) : (index -= 1) {
      if (input[index - 1] == 1) {
        input[index - 1] = 9;
        continue;
      }

      input[index - 1] -= 1;
      break;
    }
  }
}
