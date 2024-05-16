const std = @import("std");
const net = std.net;
const Reader = std.io.Reader;

var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();
// zig fmt: off

/// See [Redis Protocol](https://redis.io/docs/latest/develop/reference/protocol-spec/#simple-strings)
const DATA_TYPE = enum {
    simple_string,
    simple_errors,
    integers,
    bulk_strings,
    arrays,
    nulls,
    booleans,
    doubles,
    big_numbers,
    bulk_errors,
    verbatim_strings,
    maps,
    sets,
    pushes
};

// zig fmt: on

// pub fn encode_resp(reader: Reader) []u8 {
//     const chunks = std.mem.split(u8, message, "\r\n");
//     var resp = std.ArrayList(u8).init(allocator);
//     _ = resp; // autofix

//     for (chunks) |chunk| {
//         std.debug.print("chunk: {s}\n", .{chunk});
//     }
// }

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const address = try net.Address.resolveIp("127.0.0.1", 6379);

    var listener = try address.listen(.{
        .reuse_address = true,
    });
    defer listener.deinit();

    try stdout.print("listening on {}\n", .{address});

    while (true) {
        const conn = try listener.accept();
        defer conn.stream.close();

        const writer = conn.stream.writer();
        const reader = conn.stream.reader();

        try stdout.print("accepted new connection from {}\n", .{conn.address});

        const message = try allocator.alloc(u8, 1024);
        defer allocator.free(message);

        const len = reader.read(message) catch |err| {
            try stdout.print("error reading message: {}\n", .{err});
            continue;
        };

        try stdout.print("received message: {s}\n", .{message[0..len]});

        _ = try writer.write("+PONG\r\n");
    }
}
