const std = @import("std");
const print = std.debug.print;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("../data/day19.txt");

pub fn main() !void {
  var timer = try std.time.Timer.start();
  var scanners = try calculateScanners(data);
  defer { deinitScanners(scanners); }
  print("🎁 Magnitude: {}\n", .{try numberOfBeacons(scanners)});
  print("Day 19 - part 01 took {:15}ns\n", .{timer.lap()});
  timer.reset();


  print("🎁 Largest magnitude: {}\n", .{maxManhattan(scanners)});
  print("Day 19 - part 02 took {:15}ns\n", .{timer.lap()});
  print("❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️❄️\n", .{});
}

const Point = struct {
  x : i32,
  y : i32,
  z : i32,

  pub fn dump(me : *const @This()) void {
    print("({}, {}, {})\n", .{me.x, me.y, me.z});
  }

  pub fn init(x : i32, y : i32, z : i32) @This() {
    return Point {
      .x = x,
      .y = y,
      .z = z
    };
  }

  pub fn equals(me : *const @This(), other : @This()) bool {
    return me.x == other.x and me.y == other.y and me.z == other.z;
  }

  pub fn sub(me : *const @This(), other : @This()) @This() {
    return Point {
      .x = me.x - other.x,
      .y = me.y - other.y,
      .z = me.z - other.z,
    };
  }

  pub fn add(me : *const @This(), other : @This()) @This() {
    return Point {
      .x = me.x + other.x,
      .y = me.y + other.y,
      .z = me.z + other.z,
    };
  }

  pub fn abs(me : *const @This()) @This() {
    return Point {
      .x = if (me.x < 0) -me.x else me.x,
      .y = if (me.y < 0) -me.y else me.y,
      .z = if (me.z < 0) -me.z else me.z,
    };
  }
};

const BeaconIterator = struct {
  buffer : []const Point,
  index : usize,
  rotation : u6,
  position : ?Point,

  pub fn init(buffer : []const Point, rotation : u6, position : ?Point) @This() {
    return BeaconIterator {
      .buffer = buffer,
      .index = 0,
      .rotation = rotation,
      .position = position,
    };
  }

  fn rotate(a : *i32, b : *i32, rotation: u2) void {
    const aOld = a.*;
    const bOld = b.*;

    switch (rotation) {
      0 => {},
      1 => {
        // 90 degrees
        a.* = bOld;
        b.* = -aOld;
      },
      2 => {
        // 180 degrees
        a.* = -aOld;
        b.* = -bOld;
      },
      3 => {
        // 270 degrees
        a.* = -bOld;
        b.* = aOld;
      }
    }
  }

  pub fn next(me : *@This()) ?Point {
    if (me.index == me.buffer.len) {
      return null;
    }

    var point = me.buffer[me.index];

    const xRotation = @intCast(u2, (me.rotation >> 0) & 0x3);
    const yRotation = @intCast(u2, (me.rotation >> 2) & 0x3);
    const zRotation = @intCast(u2, (me.rotation >> 4) & 0x3);

    rotate(&point.x, &point.y, xRotation);
    rotate(&point.y, &point.z, yRotation);
    rotate(&point.x, &point.z, zRotation);

    // Bump our index too!
    me.index += 1;

    if (me.position != null) {
      point = point.add(me.position.?);
    }

    return point;
  }
};

const Scanner = struct {
  beacons : std.ArrayList(Point),
  aligned : bool,
  rotation : u6,
  position : ?Point,

  pub fn init(allocator : *std.mem.Allocator) @This() {
    return Scanner {
      .beacons = std.ArrayList(Point).init(gpa),
      .aligned = false,
      .rotation = 0,
      .position = null,
    };
  }

  pub fn deinit(me : @This()) void {
    me.beacons.deinit();
  }

  pub fn add(me : *@This(), point : Point) !void {
    try me.beacons.append(point);
  }

  pub fn fix(me : *@This(), rotation : u6, position : Point) void {
    me.aligned = true;
    me.rotation = rotation;
    me.position = position;
  }

  pub fn fixedIterator(me : *const @This()) BeaconIterator {
    std.debug.assert(me.aligned);
    std.debug.assert(me.beacons.items.len != 0);
    return BeaconIterator.init(me.beacons.items, me.rotation, me.position);
  }

  pub fn rotatedIterator(me : *const @This(), rotation : u6) BeaconIterator {
    // We cannot rotate an already aligned scanner!
    std.debug.assert(!me.aligned);
    std.debug.assert(me.beacons.items.len != 0);
    return BeaconIterator.init(me.beacons.items, rotation, null);
  }
};

pub fn deinitScanners(scanners : std.ArrayList(Scanner)) void {
  for (scanners.items) |scanner| {
    scanner.deinit();
  }
  scanners.deinit();
}

pub fn calculateScanners(input : []const u8) !std.ArrayList(Scanner) {
  var scanners = std.ArrayList(Scanner).init(gpa);

  var splitIterator = std.mem.split(input, "--- scanner ");

  while (splitIterator.next()) |split| {
    var lines = std.mem.tokenize(split, "\r\n");

    // Skip the first line that is just 'N ---'
    const discard = lines.next();

    var scanner = Scanner.init(gpa);

    while (lines.next()) |line| {
      var coordIterator = std.mem.tokenize(line, ",");

      const x = try std.fmt.parseInt(i32, coordIterator.next().?, 10);
      const y = try std.fmt.parseInt(i32, coordIterator.next().?, 10);
      const z = try std.fmt.parseInt(i32, coordIterator.next().?, 10);

      try scanner.add(Point.init(x, y, z));
    }

    if (scanner.beacons.items.len == 0) {
      scanner.deinit();
    } else {
      try scanners.append(scanner);
    }
  }

  // We are going to align all the scanners relative to scanner 0, so lock in
  // the alignment of scanner 0 now.
  scanners.items[0].fix(0, Point.init(0, 0, 0));

  while (true) {
    var anyUnaligned = false;

    for (scanners.items) |*scanner, i| {
      for (scanners.items) |other, k| {
        if (scanner.aligned) {
          break;
        }

        // Skip ourselves.
        if (i == k) {
          continue;
        }

        anyUnaligned = true;

        // We need the other scanner to be aligned.
        if (!other.aligned) {
          continue;
        }

        var rotation : u6 = 0;

        while (true) {
          var fixedIterator = other.fixedIterator();
          while (fixedIterator.next()) |fixed| {
            if (scanner.aligned) {
              break;
            }

            var rotatedIterator = scanner.rotatedIterator(rotation);
            while (rotatedIterator.next()) |rotated| {
              const diff = fixed.sub(rotated);

              var fixedIterator2 = other.fixedIterator();
              var matches : u32 = 0;
              
              while (fixedIterator2.next()) |fixed2| {
                var rotatedIterator2 = scanner.rotatedIterator(rotation);
                while (rotatedIterator2.next()) |rotated2| {
                  if (fixed2.equals(rotated2.add(diff))) {
                    matches += 1;
                  }
                }
              }

              if (matches >= 12) {
                scanner.fix(rotation, diff);
                break;
              }
            }
          }

          if (@addWithOverflow(u6, rotation, 1, &rotation)) {
            break;
          }
        }
      }
    }

    if (!anyUnaligned) {
      break;
    }
  }

  return scanners;
}

pub fn numberOfBeacons(scanners : std.ArrayList(Scanner)) !u32 {
  var map = std.AutoHashMap(Point, void).init(gpa);
  defer { map.deinit(); }

  for (scanners.items) |scanner| {
    var iterator = scanner.fixedIterator();

    while (iterator.next()) |beacon| {
      try map.put(beacon, .{});
    }
  }

  return map.count();
}

pub fn maxManhattan(scanners : std.ArrayList(Scanner)) i32 {
  var max : i32 = 0;

  for (scanners.items) |i| {
    for (scanners.items) |k| {
      const vector = i.position.?.sub(k.position.?).abs();
      const distance = vector.x + vector.y + vector.z;

      max = std.math.max(max, distance);
    }
  }

  return max;
}

test "example" {
  const input = \\--- scanner 0 ---
\\404,-588,-901
\\528,-643,409
\\-838,591,734
\\390,-675,-793
\\-537,-823,-458
\\-485,-357,347
\\-345,-311,381
\\-661,-816,-575
\\-876,649,763
\\-618,-824,-621
\\553,345,-567
\\474,580,667
\\-447,-329,318
\\-584,868,-557
\\544,-627,-890
\\564,392,-477
\\455,729,728
\\-892,524,684
\\-689,845,-530
\\423,-701,434
\\7,-33,-71
\\630,319,-379
\\443,580,662
\\-789,900,-551
\\459,-707,401
\\
\\--- scanner 1 ---
\\686,422,578
\\605,423,415
\\515,917,-361
\\-336,658,858
\\95,138,22
\\-476,619,847
\\-340,-569,-846
\\567,-361,727
\\-460,603,-452
\\669,-402,600
\\729,430,532
\\-500,-761,534
\\-322,571,750
\\-466,-666,-811
\\-429,-592,574
\\-355,545,-477
\\703,-491,-529
\\-328,-685,520
\\413,935,-424
\\-391,539,-444
\\586,-435,557
\\-364,-763,-893
\\807,-499,-711
\\755,-354,-619
\\553,889,-390
\\
\\--- scanner 2 ---
\\649,640,665
\\682,-795,504
\\-784,533,-524
\\-644,584,-595
\\-588,-843,648
\\-30,6,44
\\-674,560,763
\\500,723,-460
\\609,671,-379
\\-555,-800,653
\\-675,-892,-343
\\697,-426,-610
\\578,704,681
\\493,664,-388
\\-671,-858,530
\\-667,343,800
\\571,-461,-707
\\-138,-166,112
\\-889,563,-600
\\646,-828,498
\\640,759,510
\\-630,509,768
\\-681,-892,-333
\\673,-379,-804
\\-742,-814,-386
\\577,-820,562
\\
\\--- scanner 3 ---
\\-589,542,597
\\605,-692,669
\\-500,565,-823
\\-660,373,557
\\-458,-679,-417
\\-488,449,543
\\-626,468,-788
\\338,-750,-386
\\528,-832,-391
\\562,-778,733
\\-938,-730,414
\\543,643,-506
\\-524,371,-870
\\407,773,750
\\-104,29,83
\\378,-903,-323
\\-778,-728,485
\\426,699,580
\\-438,-605,-362
\\-469,-447,-387
\\509,732,623
\\647,635,-688
\\-868,-804,481
\\614,-800,639
\\595,780,-596
\\
\\--- scanner 4 ---
\\727,592,562
\\-293,-554,779
\\441,611,-461
\\-714,465,-776
\\-743,427,-804
\\-660,-479,-426
\\832,-632,460
\\927,-485,-438
\\408,393,-506
\\466,436,-512
\\110,16,151
\\-258,-428,682
\\-393,719,612
\\-211,-452,876
\\808,-476,-593
\\-575,615,604
\\-485,667,467
\\-680,325,-822
\\-627,-443,-432
\\872,-547,-609
\\833,512,582
\\807,604,487
\\839,-516,451
\\891,-625,532
\\-652,-548,-490
\\30,-46,-14
;

  var scanners = try calculateScanners(input);
  defer { scanners.deinit(); }
  const total = try numberOfBeacons(scanners);
  try std.testing.expect(total == 79);
  const max = maxManhattan(scanners);
  try std.testing.expect(max == 3621);
}
