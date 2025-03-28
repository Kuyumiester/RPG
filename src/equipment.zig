const combat = @import("combat.zig");
const output = @import("output.zig");
const objects = @import("objects.zig");
const devtools = @import("devtools.zig");
const pc = @import("player_character.zig");

pub const Weapon = struct {
    len: u8,
    action_names: [*]const []const u8,
    action_pointers: [*]const combat.Action, // should be renamed to action_functions
    action_costs: [*]const combat.ActionCost,
};

pub const hammer = objects.Type{
    .name = "hammer",
    .onion = .{ .weapon = .{
        .len = 2,
        .action_names = &.{ "attack", "kick" },
        .action_pointers = &.{ hammerFnAttack, hammerFnKick },
        .action_costs = &.{ .{ .action_points = 6 }, .{ .action_points = 4 } },
    } },
};
pub fn hammerFnAttack(user: *combat.Actor, target: *combat.Actor) void {
    output.print("{s} attacks", .{user.name});
    target.incoming_effect = .{ .damage = 5, .balance_damage = 4 };
}
pub fn hammerFnKick(user: *combat.Actor, target: *combat.Actor) void {
    output.print("{s} kicks", .{user.name});
    target.incoming_effect = .{ .damage = 1, .balance_damage = 6 };
}

pub const heavy_arming_sword = objects.Type{
    .name = "heavy arming sword",
    .onion = .{ .weapon = .{
        .len = 1,
        .action_names = &.{"attack"},
        .action_pointers = &.{heavy_arming_swordFnAttack},
        .action_costs = &.{.{ .action_points = 8 }},
    } },
};
pub fn heavy_arming_swordFnAttack(user: *combat.Actor, target: *combat.Actor) void {
    output.print("{s} attacks", .{user.name});
    target.incoming_effect = .{ .damage = 7, .balance_damage = 4 };
}

pub const basic_shield = objects.Type{
    .name = "basic shield",
    .onion = .{ .weapon = .{
        .len = 2,
        .action_names = &.{ "shield", "bash" },
        .action_pointers = &.{ basic_shieldFnShield, basic_shieldFnBash },
        .action_costs = &.{ .{ .action_points = 2 }, .{ .action_points = 5 } },
    } },
};
pub fn basic_shieldFnShield(user: *combat.Actor, target: *combat.Actor) void {
    _ = target;
    output.print("{s} blocks with a shield", .{user.name});
    user.incoming_effect.damage -|= 4;
}
pub fn basic_shieldFnBash(user: *combat.Actor, target: *combat.Actor) void {
    output.print("{s} bashes with a shield", .{user.name});
    user.incoming_effect.damage -|= 2;
    target.incoming_effect = .{ .damage = 3, .balance_damage = 2 };
}

pub const starscar_shield = objects.Type{
    .name = "starscar shield",
    .onion = .{ .weapon = .{
        .len = 1,
        .action_names = &.{"shield"},
        .action_pointers = &.{starscar_shieldFnShield},
        .action_costs = &.{.{ .action_points = 6 }},
    } },
};
pub fn starscar_shieldFnShield(user: *combat.Actor, target: *combat.Actor) void {
    _ = target;
    output.print("{s} blocks with a shield", .{user.name});
    user.incoming_effect.damage -|= 8;
    user.incoming_effect.balance_damage -|= 4;
}

//const excalibur = Weapon{
//    .name = "excalibur",
//    .action_names = &.{ "attack", "invest" },
//    .action_pointers = &.{ &attack, &invest },
//};

// trinkets    artifacts?    charms?
// i'm not sure if trinkets should be in a "trinkets" file, or in a "equipment" file. (similar deal with armor and weapons)
// these groups are more related than spells and consumables, at least; since consumables and spells don't have passive benefits from being equipped.
//

const actors = @import("actors.zig");

pub const Trinket = struct {
    equip: *const fn () void,
};

pub const gold_monogram_seal = objects.Type{
    .name = "zeniba's solid gold monogram seal",
    .onion = .{ .trinket = .{
        .equip = &equipGoldMonogramSeal,
    } },
};
fn equipGoldMonogramSeal() void {
    pc.power += 3;
}

pub const heal_charm = objects.Type{
    .name = "heal charm",
    .onion = .{ .trinket = .{
        .equip = &equipHealCharm,
    } },
};
fn equipHealCharm() void {
    pc.addTrinketEffect(heal_charmFn);
}
pub fn heal_charmFn(wearer: *combat.Actor) void {
    wearer.health = @min(wearer.health + 1, wearer.health_max);
}

// wizard suit

// writing down equipment-type stuff to add here
// longsword
//  can block, low action point usage or whatever
// hammer/mace
//  high balance damage
// spear
//  high damage, higher action point usage, lower balance damage?
// magic swords/weapons
//  +1 stamina regen
//  enchanted effect like attacking thrice in a row does extra (magical) damage on the third strike
//  spell attached that lets you buff your weapon
//  normal-ish fireball-like spell attached
//
// heavy armor
// shield
// heavy shield
//  better blocking power, but harder to use
//
// spells
//  enchantment
//
// something that increases these stats:
//  health
//  stamina max
//  stamina regen
//  balance max
//  balance regen
//  defense
//  magic energy regen
//
//
//
//
// it'd be good to tackle these one *type* at a time. ie. make a bunch of weapons, *then* make a bunch of armor
