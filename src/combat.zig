const std = @import("std");

const actors = @import("actors.zig");
const output = @import("output.zig");
const input = @import("input.zig");
const m = @import("main.zig");
const pc = @import("player_character.zig");
const equipment = @import("equipment.zig");
const objects = @import("objects.zig");
const devtools = @import("devtools.zig");

pub const Action: type = *const fn (*Actor, *Actor) void;
pub const ActionCost = struct {
    action_points: u8,
    magic_energy: u8 = 0,
};

pub const Actor = struct { // only supposed to contain data that you'll pass as arguments to functions for combat actions
    name: []const u8,
    health: u8,
    health_max: u8,
    balance: u8,
    balance_gen: u8,
    balance_max: u8,
    action_points: u8,
    action_point_gen: u8,
    action_point_max: u8,
    magic_energy: u8 = 0,
    magic_energy_gen: u8,
    magic_energy_max: u8,
    armor: u8,
    power: u8,

    incoming_effect: struct { damage: u8 = 0, balance_damage: u8 = 0 } = .{},
};

var xoshiro: std.Random.Xoshiro256 = undefined;
var random: std.Random = undefined;
pub fn init() void {
    xoshiro = std.Random.Xoshiro256.init(@as(u64, @intCast(std.time.microTimestamp())));
    random = xoshiro.random();
}

pub fn main(opponent_data: *actors.Type) ?void {
    var player = Actor{
        .name = pc.name,
        .health = pc.health,
        .health_max = pc.health_max,
        .balance = pc.balance_max,
        .balance_gen = pc.balance_gen,
        .balance_max = pc.balance_max,
        .action_points = pc.action_point_max / 2,
        .action_point_gen = pc.action_point_gen,
        .action_point_max = pc.action_point_max,
        .magic_energy_gen = pc.magic_energy_gen,
        .magic_energy_max = pc.magic_energy_max,
        .armor = pc.armor,
        .power = pc.power,
    };

    var opponent = Actor{
        .name = opponent_data.name,
        .health_max = opponent_data.health_max,
        .health = opponent_data.health,
        .balance = opponent_data.balance_max,
        .balance_gen = opponent_data.balance_gen,
        .balance_max = opponent_data.balance_max,
        .action_points = opponent_data.action_point_max / 2,
        .action_point_gen = opponent_data.action_point_gen,
        .action_point_max = opponent_data.action_point_max,
        .magic_energy_gen = opponent_data.magic_energy_gen,
        .magic_energy_max = opponent_data.magic_energy_max,
        .armor = opponent_data.armor,
        .power = opponent_data.power,
    };

    output.newScreen();
    output.print("combat initiated with opponent {s}", .{opponent.name});

    const combat_result: ?void = combat: while (true) {

        //
        //
        //          player's turn
        //
        //

        player.balance = @min(player.balance + player.balance_gen, player.balance_max);
        player.action_points = @min(player.action_points + player.action_point_gen, player.action_point_max);
        player.magic_energy = @min(player.magic_energy + player.magic_energy_gen, player.magic_energy_max);
        for (pc.trinket_effects_array[0..pc.trinket_effects_len]) |fun| {
            fun(&player);
        }

        // ====================================
        // print combat actions
        // and
        // add combat actions to options_buffer
        // ====================================

        output.print(
            \\
            \\
            \\
            \\
            \\{s}
            \\    health: {}    defense: {}    balance: {}+{}/{}    action points: {}+{}/{}    magic energy: {}+{}/{}
            \\
            \\
            \\
            \\incoming effect:
            \\     damage: {}    balance damage: {}
            \\
            \\{s}
            \\    health: {}    defense: {}    balance: {}+{}/{}    action points: {}+{}/{}    magic energy: {}+{}/{}
        , .{
            opponent.name,
            opponent.health,
            opponent.armor,
            opponent.balance,
            opponent.balance_gen,
            opponent.balance_max,
            opponent.action_points,
            opponent.action_point_gen,
            opponent.action_point_max,
            opponent.magic_energy,
            opponent.magic_energy_gen,
            opponent.magic_energy_max,
            player.incoming_effect.damage,
            player.incoming_effect.balance_damage,
            player.name,
            player.health,
            player.armor,
            player.balance,
            player.balance_gen,
            player.balance_max,
            player.action_points,
            player.action_point_gen,
            player.action_point_max,
            player.magic_energy,
            player.magic_energy_gen,
            player.magic_energy_max,
        });

        // print normal actions
        output.writeAll("\n");

        for (pc.hand_1.action_names[0..pc.hand_1.len], pc.hand_1.action_costs) |name, cost| output.print(output.selectable_color ++ "{s} " ++ output.standard_color ++ "{}    ", .{ name, cost.action_points });
        for (pc.hand_2.action_names[0..pc.hand_2.len], pc.hand_2.action_costs) |name, cost| output.print(output.selectable_color ++ "{s} " ++ output.standard_color ++ "{}    ", .{ name, cost.action_points }); // TODO: write the magic costs too

        // print spells
        if (pc.spells_soa.len != 0) {
            output.writeAll("\n");
            for (
                pc.spells_soa.names[0..pc.spells_soa.len],
                pc.spells_soa.costs[0..pc.spells_soa.len],
            ) |name, cost| {
                output.print(output.selectable_color ++ "{s}" ++ output.standard_color ++ "  {}    ", .{ name, cost.magic_energy });
            }
        }

        // print consumables
        if (pc.consumables_soa.len != 0) {
            output.writeAll("\n");
            for (
                pc.consumables_soa.names[0..pc.consumables_soa.len],
                pc.consumables_soa.quantities[0..pc.consumables_soa.len],
            ) |name, quantity| {
                output.print(output.selectable_color ++ "{s}" ++ output.standard_color ++ "  {}    ", .{ name, quantity });
            }
        }

        output.writeAll(output.standard_color ++ "\n");

        while (true) { // start a while loop in case the player chooses a spell they can't afford to cast
            const selection = input.selectFrom(&.{
                m.default_actions,
                &.{"wait"},
                pc.hand_1.action_names[0..pc.hand_1.len],
                pc.hand_2.action_names[0..pc.hand_2.len],
                pc.spells_soa.names[0..pc.spells_soa.len],
                pc.consumables_soa.names[0..pc.consumables_soa.len],
            });

            switch (selection.which_array) { // TODO: account for new similarities between normal actions and spells. maybe i should just add them all to the same array...
                0 => m.switchOnDefaultActions(selection.index) orelse return null, // default actions eg. quit, inventory
                1 => {
                    output.print("{s} does nothing", .{player.name});
                    output.newScreen();
                },
                2 => { // normal action (hand 1)

                    // check if the player has enough action_points to do the action
                    if (pc.hand_1.action_costs[selection.index].action_points > player.action_points) {
                        input.maintainInvalidInputs();
                        output.print("not enough action points. you need {} action points to use {s}, but you only have {}.\n", .{
                            pc.hand_1.action_costs[selection.index].action_points,
                            pc.hand_1.action_names[selection.index],
                            player.action_points,
                        });
                        continue;
                    }

                    output.newScreen();

                    player.action_points -= pc.hand_1.action_costs[selection.index].action_points;
                    // TODO: check and substract magic energy as well

                    pc.hand_1.action_pointers[selection.index](&player, &opponent);
                },
                3 => { // normal action (hand 2)

                    // check if the player has enough action points to do the action
                    if (pc.hand_2.action_costs[selection.index].action_points > player.action_points) {
                        input.maintainInvalidInputs();
                        output.print("not enough action points. you need {} action points to use {s}, but you only have {}.\n", .{
                            pc.hand_2.action_costs[selection.index].action_points,
                            pc.hand_2.action_names[selection.index],
                            player.action_points,
                        });
                        continue;
                    }

                    output.newScreen();

                    player.action_points -= pc.hand_2.action_costs[selection.index].action_points;
                    // TODO: check and substract magic energy as well

                    pc.hand_2.action_pointers[selection.index](&player, &opponent);
                },
                4 => { // spell

                    // check if the player has enough power to cast the spell
                    if (objects.array[pc.spells_soa.ids[selection.index]].onion.spell.power > player.power) { // optimization: checking power this way gives me the ick
                        input.maintainInvalidInputs();
                        output.print("not enough power. you need {} power to cast {s}, but you only have {}.\n", .{
                            objects.array[pc.spells_soa.ids[selection.index]].onion.spell.power,
                            pc.spells_soa.names[selection.index],
                            player.power,
                        });
                        continue;
                    }

                    // check if the player has enough action points to cast the spell
                    if (pc.spells_soa.costs[selection.index].action_points > player.action_points) {
                        input.maintainInvalidInputs();
                        output.print("not enough action points. you need {} action points to cast {s}, but you only have {}.\n", .{
                            pc.spells_soa.costs[selection.index].action_points,
                            pc.spells_soa.names[selection.index],
                            player.action_points,
                        });
                        continue;
                    }

                    // check if the player has enough magic_energy to cast the spell
                    if (pc.spells_soa.costs[selection.index].magic_energy > player.magic_energy) {
                        input.maintainInvalidInputs();
                        output.print("not enough magic energy. you need {} magic energy to cast {s}, but you only have {}.\n", .{
                            pc.spells_soa.costs[selection.index].magic_energy,
                            pc.spells_soa.names[selection.index],
                            player.magic_energy,
                        });
                        continue;
                    }

                    output.newScreen();

                    const cost = pc.spells_soa.costs[selection.index];
                    player.magic_energy -= cost.magic_energy;
                    player.action_points -= cost.action_points;

                    // cast the spell
                    objects.array[pc.spells_soa.ids[selection.index]].onion.spell.function_pointer(&player, &opponent);
                },

                5 => { // consumable
                    output.newScreen();

                    objects.array[pc.inventory.ids[pc.consumables_soa.inventory_indexes[selection.index]]].onion.consumable.function_pointer(&player, &opponent);

                    if (pc.consumables_soa.quantities[selection.index] > 1) {
                        pc.consumables_soa.quantities[selection.index] -= 1;
                        pc.inventory.quantities[pc.consumables_soa.inventory_indexes[selection.index]] -= 1;
                    } else {

                        // remove from the inventory
                        for ( // optimization, would abstracting pc.consumables_soa.inventory_indexes[selection.index] be faster? will the compiler just optimize this away anyway, such that abstracting it will just take more space and time?
                            pc.inventory.quantities[pc.consumables_soa.inventory_indexes[selection.index] .. pc.inventory.len - 1],
                            pc.inventory.quantities[pc.consumables_soa.inventory_indexes[selection.index] + 1 .. pc.inventory.len],

                            pc.inventory.ids[pc.consumables_soa.inventory_indexes[selection.index] .. pc.inventory.len - 1],
                            pc.inventory.ids[pc.consumables_soa.inventory_indexes[selection.index] + 1 .. pc.inventory.len],

                            pc.inventory.names[pc.consumables_soa.inventory_indexes[selection.index] .. pc.inventory.len - 1],
                            pc.inventory.names[pc.consumables_soa.inventory_indexes[selection.index] + 1 .. pc.inventory.len],

                            pc.inventory.soa_indexes[pc.consumables_soa.inventory_indexes[selection.index] .. pc.inventory.len - 1],
                            pc.inventory.soa_indexes[pc.consumables_soa.inventory_indexes[selection.index] + 1 .. pc.inventory.len],
                        ) |*quantity_index, quantity_element, *id_i, id_e, *name_i, name_e, *soa_index_i, soa_index_e| {
                            quantity_index.* = quantity_element;
                            id_i.* = id_e;
                            name_i.* = name_e;
                            soa_index_i.* = switch (soa_index_e) {
                                .consumable => |index| .{ .consumable = index + 1 },
                                else => soa_index_e,
                            };
                        }

                        pc.inventory.len -= 1;

                        //remove things from soa
                        // nocheckin, do this
                        // we're doing this after removing from inventory so we don't have to save the inventory_index temporarily
                        //
                        // oh right, i just remembered why this is hard. because we have to update the soa_indexes and inventory_indexes we just have to subtract though. but with the inventory, that means using a switch statement.
                        //
                        // i don't remember what this nocheckin is for...
                        pc.consumables_soa.len -= 1;
                    }
                },
                else => unreachable,
            }

            break;
        }

        effectTarget(&player) orelse break :combat null;

        //
        //
        //          opponent's turn
        //
        //

        output.writeAll("\n\n");
        opponent.balance = @min(opponent.balance + opponent.balance_gen, opponent.balance_max);
        opponent.action_points = @min(opponent.action_points + opponent.action_point_gen, opponent.action_point_max);
        opponent.magic_energy = @min(opponent.magic_energy + opponent.magic_energy_gen, opponent.magic_energy_max);
        for (opponent_data.trinket_effects) |fun| {
            fun(&opponent);
        }

        var affordable_indexes: [8]usize = undefined;
        var len: usize = 0;
        for (opponent_data.action_costs[0..opponent_data.action_quantity], 0..) |cost, i| {
            if (cost.action_points <= opponent.action_points and cost.magic_energy <= opponent.magic_energy) {
                affordable_indexes[len] = i;
                len += 1;
            }
        }
        const indexes_index: usize = random.intRangeAtMost(u8, 0, @intCast(len));
        if (indexes_index == len) { // do nothing
            output.print("{s} does nothing", .{opponent.name});
        } else {
            const action_index: usize = affordable_indexes[indexes_index];
            const cost = opponent_data.action_costs[action_index];
            opponent.action_points -= cost.action_points;
            opponent.magic_energy -= cost.magic_energy;
            opponent_data.action_functions[action_index](&opponent, &player);
        }

        effectTarget(&opponent) orelse break :combat;
    };

    output.print("\nbattle over\n\n", .{});

    pc.health = player.health;

    return combat_result;
}

//pub fn damageTarget(target: *Actor, dmg: u7) void {
//    target.health -|= dmg;
//    output.print("\n{s} took {} damage", .{ target.name, dmg });
//}

pub fn effectTarget(target: *Actor) ?void {
    var atk_pow = target.incoming_effect.damage;
    target.balance -|= target.incoming_effect.balance_damage;
    if (target.balance == 0 and target.incoming_effect.damage > 0) atk_pow += 2;
    atk_pow -|= target.armor;

    output.print("\n{s} took {} damage and lost {} balance", .{ target.name, atk_pow, target.incoming_effect.balance_damage });

    if (target.health <= atk_pow) {
        output.print("\n{s} has died", .{target.name});
        return null;
    }
    target.health -= atk_pow;
    target.incoming_effect = .{ .damage = 0, .balance_damage = 0 };
}
