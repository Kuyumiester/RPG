const std = @import("std");
const actors = @import("actors.zig");
const combat = @import("combat.zig");
const output = @import("output.zig");
const pc = @import("player_character.zig");
const input = @import("input.zig");
const world = @import("world.zig");
const devtools = @import("devtools.zig");
const storage = @import("storage.zig");

pub var scene: *world.Location = &world.town;

pub fn main() !void {
    {
        // initializing stuff
        @import("devtools.zig").startTiming();
        try output.init();
        pc.init();
        world.init();
        combat.init();

        output.writeAll(output.standard_color ++ output.csi ++ "?25l" ++ output.clear_screen);
        //                                                      ^hides cursor
        storage.mainMenu() orelse {
            output.writeAll(output.csi ++ "0m");
            output.flush();
            return;
        };

        output.newScreen();
        output.writeAll("game started\n");
    }

    // the loop
    while (true) {
        switch (scene.encounter) {
            .combat => |actor| combat.main(actor) orelse break,
            .find => |amount| world.find(amount),
            .none => {},
        }
        scene.encounter = .none;

        output.writeAll(output.selectable_color);

        // print scene actions
        if (scene.action_names.len != 0) {
            output.writeAll("\n");
            for (scene.action_names[0 .. scene.action_names.len - 1]) |string| {
                output.print("{s}   ", .{string});
            }
            output.print("{s}\n", .{scene.action_names[scene.action_names.len - 1]});
        }

        // print travel locations / routes
        output.writeAll("\n");
        for (scene.route_names[0 .. scene.route_names.len - 1]) |string| {
            output.print("{s}   ", .{string});
        }
        output.print("{s}\n\n", .{scene.route_names[scene.route_names.len - 1]});

        // choose your action
        input.first_try = true;
        const selection = input.selectFrom(&.{
            default_actions,
            scene.action_names,
            scene.route_names,
        });
        output.writeAll(output.standard_color);
        switch (selection.which_array) {
            0 => switchOnDefaultActions(selection.index) orelse break,
            1 => scene.action_functions[selection.index]() orelse break, // do a scene-specific action
            2 => {
                output.newScreen();
                scene = scene.routes[selection.index];
            }, // travel to another location
            else => unreachable,
        }
    }

    // do stuff before exiting the game
    output.writeAll(output.csi ++ "0m");
    output.flush();
    storage.file.close();
}

pub const default_actions: []const []const u8 = &.{
    "quit",
    "inventory",
};

pub fn switchOnDefaultActions(index: usize) ?void {
    switch (index) {
        0 => { // quit
            return null;
        },
        1 => { // print inventory object names and print health, power, etc.
            output.newScreen();
            output.print(
                \\stats:
                \\
                \\    health: {}    power: {}
                \\
                \\
                \\inventory:
                \\
                \\    copper: {}
                \\
                \\
            , .{ pc.health, pc.power, pc.copper });
            for (pc.inventory.names[0..pc.inventory.len]) |string| {
                output.print("    {s}", .{string});
            }
            output.writeAll("\n\n");
        },
        else => unreachable,
    }
}

//

//

//
