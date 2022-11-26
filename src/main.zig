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
        }
    }

    if (input == null) {
        std.debug.print("Input argument required.\n", .{});
    } else {
        try output_encoding(input.?, output_path);
    }
}

fn output_encoding(to_encode: []u8, output_path: ?[:0]const u8) anyerror!void {
    const allocator = std.heap.page_allocator;
    const output = try encode(to_encode, allocator);
    defer allocator.free(output);

    if (output_path != null) {
        const output_file = try std.fs.cwd().createFile(
            output_path.?,
            .{ .read = true },
        );
        defer output_file.close();
        try output_file.writeAll(output);
    } else {
        try std.io.getStdOut().writer().print("{s}\n", .{output});
    }
}

fn encode(to_encode: []u8, allocator: Allocator) anyerror![]u8 {
    var output = std.ArrayList(u8).init(allocator);
    defer output.deinit();

    var buffer: ?u8 = 0;
    var shift: u3 = 2;
    var item_count: u3 = 0;

    for (to_encode) |byte| {
        const next: u8 = buffer orelse 0 | byte >> shift;
        buffer = byte << 6 - shift & std.math.maxInt(u6);
        try output.append(encode_map[next]);
        item_count = (item_count + 1) % 4;

        if (shift == 6) {
            try output.append(encode_map[buffer.?]);
            item_count = (item_count + 1) % 4;
            buffer = null;
            shift = 2;
        } else {
            shift += 2;
        }
    }

    if (buffer != null) {
        try output.append(encode_map[buffer.?]);
        item_count = (item_count + 1) % 4;
    }

    while (item_count != 0) : (item_count = (item_count + 1) % 4) {
        try output.append('=');
    }

    return output.toOwnedSlice();
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
