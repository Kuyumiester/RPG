const combat = @import("combat.zig");
const output = @import("output.zig");
const devtools = @import("devtools.zig");
const objects = @import("objects.zig");

pub const Type = struct {
    function_pointer: combat.Action,
    power: u8,
    cost: combat.ActionCost,
};

// ======
// spells
// ======

pub const death = objects.Type{
    .name = "death spell",
    .onion = .{ .spell = .{
        .function_pointer = &deathFn,
        .power = 0,
        .cost = .{ .action_points = 0 },
    } },
};
fn deathFn(user: *combat.Actor, target: *combat.Actor) void {
    output.print("{s} used death spell!", .{user.name}); // nocheckin, we can take these out
    target.health = 0;
}

pub const fireball = objects.Type{
    .name = "fireball",
    .onion = .{ .spell = .{
        .function_pointer = &fireballFn,
        .power = 1,
        .cost = .{ .action_points = 1, .magic_energy = 4 },
    } },
};
pub fn fireballFn(user: *combat.Actor, target: *combat.Actor) void {
    output.print("{s} used fireball!", .{user.name}); // nocheckin
    target.incoming_effect = .{ .damage = 7, .balance_damage = 3 };
}

pub const firegorger = objects.Type{
    .name = "firegorger",
    .onion = .{ .spell = .{
        .function_pointer = &firegorgerFn,
        .power = 2,
        .cost = .{ .action_points = 2, .magic_energy = 8 },
    } },
};
pub fn firegorgerFn(user: *combat.Actor, target: *combat.Actor) void {
    output.print("{s} used firegorger!", .{user.name});
    target.incoming_effect = .{ .damage = 12, .balance_damage = 4 };
}

pub const ice_missile = objects.Type{
    .name = "ice missile",
    .onion = .{ .spell = .{
        .function_pointer = ice_missileFn,
        .power = 3,
        .cost = .{ .action_points = 0, .magic_energy = 3 },
    } },
};
pub fn ice_missileFn(user: *combat.Actor, target: *combat.Actor) void {
    output.print("{s} cast ice missile", .{user.name});
    target.incoming_effect = .{ .damage = 5, .balance_damage = 5 };
}

pub const arc = objects.Type{
    .name = "arc spell",
    .onion = .{ .spell = .{
        .function_pointer = &arcFn,
        .power = 4,
        .cost = .{ .action_points = 4, .magic_energy = 4 },
    } },
};
pub fn arcFn(user: *combat.Actor, target: *combat.Actor) void {
    const atk_pwr: u8 = user.magic_energy + comptime arc.onion.spell.cost.magic_energy;
    output.print("{s} used arc spell!", .{user.name});
    target.incoming_effect = .{ .damage = atk_pwr, .balance_damage = 2 };
}

pub const sacred_lance = objects.Type{
    .name = "sacred lance", // subject to change. "piercing light"?
    .onion = .{ .spell = .{
        .function_pointer = &sacred_lanceFn,
        .power = 5,
        .cost = .{ .action_points = 3, .magic_energy = 12 },
    } },
};
pub fn sacred_lanceFn(user: *combat.Actor, target: *combat.Actor) void {
    output.print("{s} used sacred lance", .{user.name});
    target.incoming_effect = .{ .damage = 26, .balance_damage = 6 };
}

pub const thunder = objects.Type{
    .name = "thunder spell",
    .onion = .{ .spell = .{
        .function_pointer = &thunderFn,
        .power = 4,
        .cost = .{ .action_points = 3, .magic_energy = 9 },
    } },
};
pub fn thunderFn(user: *combat.Actor, target: *combat.Actor) void {
    output.print("{s} used thunder spell", .{user.name});
    target.incoming_effect = .{ .damage = 10, .balance_damage = 16 };
}

//

// make a spell that attacks per turn or something. and maybe allow the user to increase the damage somehow
// the point is to force the enemy to keep dodging or blocking or something. it was inspired by outgoing_attack not resetting to 0 when it should.
//
