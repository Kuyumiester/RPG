const devtools = @import("devtools.zig");
const combat = @import("combat.zig");
const equipment = @import("equipment.zig");
const objects = @import("objects.zig");
const spells = @import("spells.zig");

pub const Type = struct {
    name: []const u8 = "unnamed actor",
    health: u8,
    health_max: u8,
    balance_gen: u8,
    balance_max: u8,
    action_point_gen: u8,
    action_point_max: u8,
    magic_energy_gen: u8 = 0,
    magic_energy_max: u8 = 99,
    armor: u8,
    power: u8 = 0,
    // should actions and spells be combined? they have the same arguments, just different costs. but it's likely that i'll have actions that require magic and action points
    action_quantity: u8 = 0,
    action_functions: [*]const combat.Action = undefined,
    action_costs: [*]const combat.ActionCost = undefined,
    trinket_effects: []const *const fn (*combat.Actor) void = undefined,
    //enchantment_power
    //sludge_power // maybe should be part of a different category? what would that even be? decrepit power? dark power? if dark magic is significant and powerful in a different way, i probably don't want it to be the same.
    //fire_power
    //golden_power?
    //ice power?
    //mass power?
};

pub const Id = devtools.Int(array.len - 1);

pub const array = [_]Type{ // maybe these shouldn't be in an array... i don't have a good reason to do so yet.
    // one advantage: you can easily do comptime things like "what's the largest length value".
    // one disadvantage: you can't declare action functions next to the actors.
    // a potential advantage/the reason i put them in an array: if i want to store actor information "in the world", i can just use a u8, instead of a pointer. the reason this might not end up being very helpful is because it's possible that i'll want a bunch of persisting variable actors roaming the world. but i bet it would still be at least somewhat useful, because i'll need some way to select spawning
    // advantage: i like the way it looks
    .{
        .name = "warrior",
        .health = 11,
        .health_max = 11,
        .balance_gen = 1,
        .balance_max = 9,
        .action_point_gen = 2,
        .action_point_max = 16,
        .armor = 3,
        .action_quantity = 2,
        .action_functions = &.{ equipment.hammerFnAttack, equipment.hammerFnKick },
        .action_costs = &.{ equipment.hammer.onion.weapon.action_costs[0], equipment.hammer.onion.weapon.action_costs[1] },
    },
    .{
        .name = "tank",
        .health = 8,
        .health_max = 8,
        .balance_gen = 1,
        .balance_max = 8, // TODO: how should tank be different than the others?
        .action_point_gen = 2,
        .action_point_max = 12,
        .armor = 4,
        .action_quantity = 2,
        .action_functions = &.{ equipment.hammerFnAttack, equipment.hammerFnKick },
        .action_costs = &.{ equipment.hammer.onion.weapon.action_costs[0], equipment.hammer.onion.weapon.action_costs[1] },
    },
    .{
        .name = "knight",
        .health = 8,
        .health_max = 8,
        .balance_gen = 1,
        .balance_max = 8,
        .action_point_gen = 2,
        .action_point_max = 12,
        .armor = 3,
        .action_quantity = 3,
        .action_functions = &.{ equipment.hammerFnAttack, equipment.basic_shieldFnShield, equipment.basic_shieldFnBash },
        .action_costs = &.{ equipment.hammer.onion.weapon.action_costs[0], equipment.basic_shield.onion.weapon.action_costs[0], equipment.basic_shield.onion.weapon.action_costs[1] },
    },
    .{
        .name = "dragon",
        .health = 70,
        .health_max = 70,
        .balance_gen = 5,
        .balance_max = 60,
        .action_point_gen = 3,
        .action_point_max = 16,
        .magic_energy_gen = 3,
        .magic_energy_max = 99,
        .armor = 6,
        .action_quantity = 2,
        .action_functions = &.{ dragonAttack, dragonFire },
        .action_costs = &.{ .{ .action_points = 9 }, .{ .action_points = 5, .magic_energy = 7 } },
    },
    .{
        .name = "jonathan blow",
        .health = 30,
        .health_max = 30,
        .balance_gen = 2,
        .balance_max = 30,
        .action_point_gen = 5,
        .action_point_max = 20,
        .magic_energy_gen = 1,
        .armor = 5,
        .power = 5,
        .action_quantity = 3,
        .action_functions = &.{ equipment.heavy_arming_swordFnAttack, equipment.starscar_shieldFnShield, spells.sacred_lanceFn },
        .action_costs = &.{ equipment.heavy_arming_sword.onion.weapon.action_costs[0], equipment.starscar_shield.onion.weapon.action_costs[0], spells.sacred_lance.onion.spell.cost },
        .trinket_effects = &.{equipment.heal_charmFn},
    },
};
// should i put actions in an array, so we don't have to store pointers to them? that kinda seems like a good idea, but we don't currently loop through them anyway, so it might be worse.

// maybe actors could have items *and* custom/manual actions

const output = @import("output.zig");

fn dragonAttack(user: *combat.Actor, target: *combat.Actor) void {
    output.print("{s} attacks", .{user.name});
    target.incoming_effect = .{ .damage = 8, .balance_damage = 12 };
}
fn dragonFire(user: *combat.Actor, target: *combat.Actor) void {
    output.print("{s} spews fire!", .{user.name});
    target.incoming_effect = .{ .damage = 10, .balance_damage = 4 };
}

pub inline fn index(string: []const u8) Id {
    outer: for (array, 0..) |obj, id| {
        if (obj.name.len != string.len) continue;
        for (string, obj.name) |string_letter, obj_letter| {
            if (string_letter != obj_letter) continue :outer;
        }
        return @intCast(id);
    }
    unreachable; // no object name matches the given string
    //return array.len; // try to access an index that doesn't exist, since @compileError fucks everything up

    // this fucks things up for some reason
    //@compileError("no object name matches the given string"); // can't do `++ string` for some reason
}
