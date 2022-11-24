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

    _ = args.skip();
    const to_encode = args.next();

    if (to_encode == null or args.skip()) {
        std.debug.print("Exactly one argument required.\n", .{});
    } else {
        try output_encoding(to_encode.?, null);
    }
}

fn output_encoding(to_encode: [:0]const u8, output_filename: ?[:0]const u8) anyerror!void {
    const allocator = std.heap.page_allocator;
    const output = try encode(to_encode, allocator);
    defer allocator.free(output);

    if (output_filename != null) {
        const output_file = try std.fs.cwd().createFile(
            output_filename.?,
            .{ .read = true },
        );
        defer output_file.close();
        try output_file.writeAll(output);
    } else {
        try std.io.getStdOut().writer().print("{s}\n", .{output});
    }
}

fn encode(to_encode: [:0]const u8, allocator: Allocator) anyerror![]u8 {
    var output = std.ArrayList(u8).init(allocator);
    defer output.deinit();

    var buffer: u8 = 0;
    var shift: u3 = 2;
    var item_count: u3 = 0;

    for (to_encode) |byte| {
        const next: u8 = buffer | byte >> shift;
        buffer = byte << 6 - shift & std.math.maxInt(u6);
        try output.append(next);
        item_count = (item_count + 1) % 4;

        if (shift == 6) {
            try output.append(buffer);
            item_count = (item_count + 1) % 4;
            buffer = 0;
            shift = 2;
        } else {
            shift += 2;
        }
    }

    if (buffer != 0) {
        try output.append(buffer);
        item_count = (item_count + 1) % 4;
    }

    for (output.items) |item, i| {
        output.items[i] = encode_map[item];
    }

    while (item_count != 0) : (item_count = (item_count + 1) % 4) {
        try output.append('=');
    }

    return output.toOwnedSlice();
}

test "encode test" {
    const allocator = std.testing.allocator;
    const encoding_expected = "QWxsIHlvdXIgY29kZWJhc2UgYXJlIGJlbG9uZyB0byB1cy4=";
    const encoded_by_function = try encode("All your codebase are belong to us.", allocator);
    defer allocator.free(encoded_by_function);

    try std.testing.expectEqualStrings(encoded_by_function, encoding_expected);
}
