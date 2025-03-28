const combat = @import("combat.zig");
const output = @import("output.zig");
const devtools = @import("devtools.zig");
const objects = @import("objects.zig");

pub const Type = struct {
    function_pointer: *const fn (*combat.Actor, *combat.Actor) void,
};

// ===========
// consumables
// ===========

pub const potion_of_magic_energy = objects.Type{
    .name = "potion of magic energy",
    .onion = .{ .consumable = .{
        .function_pointer = &potion_of_magic_energyFn,
    } },
};
fn potion_of_magic_energyFn(user: *combat.Actor, opponent: *combat.Actor) void {
    _ = opponent;
    user.magic_energy = @min(user.magic_energy + 12, user.magic_energy_max);
    output.print("{s} used potion of magic energy", .{user.name});
}

//pub const thunder_missile = objects.Type{
//    .name = "thunder missile",
//    .onion = .{ .consumable = .{
//        .function_pointer = &thunderMissile,
//    } },
//};
//fn thunderMissile(s: combat.ActionArgument) void {
//    var defense: u5 = 0;
//    for (s.target.armor) |armor_struct| {
//        if (armor_struct == null) continue;
//        defense += armor_struct.?.defense;
//    }
//
//    const dmg_dealt: u7 = 10 -| defense;
//    output.print("{s} used thunder missile", .{s.user.name});
//    combat.damageTarget(s.target, dmg_dealt);
//}
//
//pub const holy_hand_grenade = objects.Type{
//    .name = "holy hand grenade",
//    .onion = .{ .consumable = .{
//        .function_pointer = &holyHandGrenade,
//    } },
//};
//fn holyHandGrenade(s: combat.ActionArgument) void {
//    var defense: u5 = 0;
//    for (s.target.armor) |armor_struct| {
//        if (armor_struct == null) continue;
//        defense += armor_struct.?.defense;
//    }
//
//    const dmg_dealt: u7 = 30 -| defense;
//    output.print("{s} used holy hand grenade", .{s.user.name});
//    combat.damageTarget(s.target, dmg_dealt);
//}
