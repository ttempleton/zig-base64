const std = @import("std");
const Allocator = std.mem.Allocator;

const encode_map = [64:0]u8{
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L',
    'M',
    'N',
    'O',
    'P',
    'Q',
    'R',
    'S',
    'T',
    'U',
    'V',
    'W',
    'X',
    'Y',
    'Z',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '+',
    '/',
};

pub fn main() anyerror!void {
    const allocator = std.heap.page_allocator;
    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    var input: ?[]u8 = null;
    var output_path: ?[:0]const u8 = null;
    var encode_input = true;

    // Skip the program name first
    _ = args.skip();

    // Handle arguments for getting input (either as an argument or from a file)
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-i") or std.mem.eql(u8, arg, "--input")) {
            const next_arg = args.next();

            if (next_arg == null) {
                std.debug.print("{s} requires input.\n", .{arg});
                return;
            }

            input = try allocator.dupe(u8, next_arg.?);
        } else if (std.mem.eql(u8, arg, "-f") or std.mem.eql(u8, arg, "--file")) {
            const next_arg = args.next();

            if (next_arg == null) {
                std.debug.print("{s} requires a filename.\n", .{arg});
                return;
            }

            const input_file = try std.fs.cwd().openFile(
                next_arg.?,
                .{},
            );
            defer input_file.close();

            const file_size = try input_file.getEndPos();
            input = try input_file.reader().readAllAlloc(allocator, file_size);
        } else if (std.mem.eql(u8, arg, "-o") or std.mem.eql(u8, arg, "--output")) {
            output_path = args.next();
        } else if (std.mem.eql(u8, arg, "-d") or std.mem.eql(u8, arg, "--decode")) {
            encode_input = false;
        }
    }

    if (input == null) {
        std.debug.print("Input argument required.\n", .{});
    } else {
        try output(encode_input, input.?, output_path);
        allocator.free(input.?);
    }
}

fn output(encode_input: bool, input: []u8, output_path: ?[:0]const u8) anyerror!void {
    const allocator = std.heap.page_allocator;
    const out = if (encode_input) try encode(input, allocator) else try decode(input, allocator);
    defer allocator.free(out);

    if (output_path != null) {
        const output_file = try std.fs.cwd().createFile(
            output_path.?,
            .{ .read = true },
        );
        defer output_file.close();
        try output_file.writeAll(out);
    } else {
        try std.io.getStdOut().writer().print("{s}\n", .{out});
    }
}

fn encode(to_encode: []u8, allocator: Allocator) anyerror![]u8 {
    var out = std.ArrayList(u8).init(allocator);
    defer out.deinit();

    var buffer: ?u8 = 0;
    var shift: u3 = 2;
    var item_count: u3 = 0;

    for (to_encode) |byte| {
        const next: u8 = buffer orelse 0 | byte >> shift;
        buffer = byte << 6 - shift & std.math.maxInt(u6);
        try out.append(encode_map[next]);
        item_count = (item_count + 1) % 4;

        if (shift == 6) {
            try out.append(encode_map[buffer.?]);
            item_count = (item_count + 1) % 4;
            buffer = null;
            shift = 2;
        } else {
            shift += 2;
        }
    }

    if (buffer != null) {
        try out.append(encode_map[buffer.?]);
        item_count = (item_count + 1) % 4;
    }

    while (item_count != 0) : (item_count = (item_count + 1) % 4) {
        try out.append('=');
    }

    return out.toOwnedSlice();
}

fn decode(to_decode: []u8, allocator: Allocator) anyerror![]u8 {
    var out = std.ArrayList(u8).init(allocator);
    defer out.deinit();

    var buffer: ?u8 = null;
    var shift: u3 = 0;
    var had_padding = false;

    for (to_decode) |byte| {
        if (byte == '=') {
            had_padding = true;
            break;
        }

        const mapped_byte = decodeMap(byte);

        if (shift != 0) {
            const next_result = buffer orelse 0 | mapped_byte >> 6 - shift;
            try out.append(next_result);
            buffer = null;
        }

        shift = if (shift == 6) 0 else shift + 2;

        if (shift != 0) {
            buffer = mapped_byte << shift & std.math.maxInt(u8);
        }
    }

    if (!had_padding and buffer != null) {
        try out.append(buffer.?);
    }

    return out.toOwnedSlice();
}

fn decodeMap(input: u8) u8 {
    return switch (input) {
        'A' => 0x00,
        'B' => 0x01,
        'C' => 0x02,
        'D' => 0x03,
        'E' => 0x04,
        'F' => 0x05,
        'G' => 0x06,
        'H' => 0x07,
        'I' => 0x08,
        'J' => 0x09,
        'K' => 0x0A,
        'L' => 0x0B,
        'M' => 0x0C,
        'N' => 0x0D,
        'O' => 0x0E,
        'P' => 0x0F,
        'Q' => 0x10,
        'R' => 0x11,
        'S' => 0x12,
        'T' => 0x13,
        'U' => 0x14,
        'V' => 0x15,
        'W' => 0x16,
        'X' => 0x17,
        'Y' => 0x18,
        'Z' => 0x19,
        'a' => 0x1A,
        'b' => 0x1B,
        'c' => 0x1C,
        'd' => 0x1D,
        'e' => 0x1E,
        'f' => 0x1F,
        'g' => 0x20,
        'h' => 0x21,
        'i' => 0x22,
        'j' => 0x23,
        'k' => 0x24,
        'l' => 0x25,
        'm' => 0x26,
        'n' => 0x27,
        'o' => 0x28,
        'p' => 0x29,
        'q' => 0x2A,
        'r' => 0x2B,
        's' => 0x2C,
        't' => 0x2D,
        'u' => 0x2E,
        'v' => 0x2F,
        'w' => 0x30,
        'x' => 0x31,
        'y' => 0x32,
        'z' => 0x33,
        '0' => 0x34,
        '1' => 0x35,
        '2' => 0x36,
        '3' => 0x37,
        '4' => 0x38,
        '5' => 0x39,
        '6' => 0x3A,
        '7' => 0x3B,
        '8' => 0x3C,
        '9' => 0x3D,
        '+' => 0x3E,
        '/' => 0x3F,
        else => unreachable,
    };
}

test "encode test" {
    const allocator = std.testing.allocator;
    const input = try allocator.dupe(u8, "All your codebase are belong to us.");
    defer allocator.free(input);
    const encoding_expected = "QWxsIHlvdXIgY29kZWJhc2UgYXJlIGJlbG9uZyB0byB1cy4=";
    const encoded_by_function = try encode(input, allocator);
    defer allocator.free(encoded_by_function);

    try std.testing.expectEqualStrings(encoded_by_function, encoding_expected);
}

test "decode test" {
    const allocator = std.testing.allocator;
    const input = try allocator.dupe(u8, "QWxsIHlvdXIgY29kZWJhc2UgYXJlIGJlbG9uZyB0byB1cy4=");
    defer allocator.free(input);
    const decoding_expected = "All your codebase are belong to us.";
    const decoded_by_function = try decode(input, allocator);
    defer allocator.free(decoded_by_function);

    try std.testing.expectEqualStrings(decoded_by_function, decoding_expected);
}
