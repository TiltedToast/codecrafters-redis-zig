const std = @import("std");
const net = std.net;

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

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

        try stdout.print("accepted new connection from {}\n", .{conn.address});

        const message = conn.stream.reader().readUntilDelimiterAlloc(allocator, '\n', 1024) catch |err| {
            try stdout.print("error reading message: {}\n", .{err});
            continue;
        };
        defer allocator.free(message);

        try stdout.print("received message: {s}\n", .{message});

        if (std.mem.startsWith(u8, message, "PING")) {
            _ = try writer.write("+PONG\r\n");
        }
    }
}
