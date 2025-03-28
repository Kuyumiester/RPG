const output = @import("output.zig");
const input = @import("input.zig");
const pc = @import("player_character.zig");
const combat = @import("combat.zig");
const actors = @import("actors.zig");
const main = @import("main.zig");
const storage = @import("storage.zig");

pub const Location = struct { // scene is another good word
    name: []const u8,
    encounter: union(enum) {
        combat: *actors.Type,
        find: u16,
        none,
    },
    action_names: []const []const u8 = &.{},
    action_functions: []const *const fn () ?void = &.{},
    route_names: []const []const u8 = undefined,
    routes: []const *Location = undefined,
};

const Action = struct {
    name: []const u8,
    function: *const fn () ?void,
};

// ==============
//      map
// ==============

pub fn init() void {
    town.routes = &.{&dungeon_entrance};
    town.route_names = &.{"dungeon entrance"}; // can't use dungeon_entrance.name instead of "dungeon entrance" for some reason. i can set it to foo_string if it's const, but not if it's var.
    // this applies to all location.routes_names, not just for town

    dungeon_entrance.routes = &.{ &town, &dungeon_1 };
    dungeon_entrance.route_names = &.{ "town", "d" };

    dungeon_1.routes = &.{ &dungeon_entrance, &dungeon_2 };
    dungeon_1.route_names = &.{ "dungeon entrance", "ek" };

    dungeon_2.routes = &.{ &dungeon_1, &dungeon_r1, &dungeon_l1 };
    dungeon_2.route_names = &.{ "d", "r", "l" };

    dungeon_l1.routes = &.{&dungeon_2};
    dungeon_l1.route_names = &.{"ek"};

    dungeon_r1.routes = &.{ &dungeon_2, &dungeon_r2 };
    dungeon_r1.route_names = &.{ "ek", "dragon_room" };

    dungeon_r2.routes = &.{&dungeon_r1};
    dungeon_r2.route_names = &.{"r"};
}
// supposedly, i'm not supposed to have to do this since 0.14.0, but here we are.

pub var town = Location{
    .name = "town",
    .action_names = &.{ rest.name, shop.name },
    .action_functions = &.{ rest.function, shop.function },
    .route_names = &.{}, //&.{dungeon_entrance.name},
    .routes = undefined, //&.{&dungeon_entrance},

    .encounter = .none,
};

const rest = Action{
    .name = "rest",
    .function = &rest_function,
};
fn rest_function() ?void {
    output.newScreen();
    if (pc.health == pc.health_max) {
        output.writeAll("\nyour health is already full");
    } else {
        if (pc.copper >= 4) {
            pc.copper -= 4;
            pc.health = pc.health_max;
            output.writeAll("\nhealth fully restored for 4 copper");
        } else {
            output.print("\nyou don't have enough money to rest. you need 4 copper, but only have {}", .{pc.copper});
        }
    }
}

const shop = Action{
    .name = "shop",
    .function = &vendor,
};

pub var dungeon_entrance = Location{
    .name = "dungeon entrance",
    .route_names = &.{}, //&.{ town.name, dungeon_1.name },
    .routes = undefined, //&.{ &town, &dungeon_1 },

    .encounter = .{ .combat = &tank },
};
var tank = actors.array[actors.index("tank")];

pub var dungeon_1 = Location{
    .name = "d",
    .route_names = &.{}, //&.{ dungeon_entrance.name, dungeon_2.name },
    .routes = undefined, //&.{ &dungeon_entrance, &dungeon_2 },

    .encounter = .{ .find = 50 },
};

pub var dungeon_2 = Location{
    .name = "ek",
    .route_names = &.{}, //&.{ dungeon_1.name, dungeon_r1.name, dungeon_l1.name },
    .routes = undefined, //&.{ &dungeon_1, &dungeon_r1, &dungeon_l1 },

    .encounter = .{ .combat = &warrior },
};
var warrior = actors.array[actors.index("warrior")];

pub var dungeon_l1 = Location{
    .name = "l",
    .route_names = &.{}, //&.{dungeon_2.name},
    .routes = undefined, //&.{&dungeon_2},

    .encounter = .{ .find = 100 },
};

pub var dungeon_r1 = Location{
    .name = "r",
    .route_names = &.{}, //&.{ dungeon_2.name, dungeon_r2.name },
    .routes = undefined, //&.{ &dungeon_2, &dungeon_r2 },

    .encounter = .{ .combat = &knight },
};
var knight = actors.array[actors.index("knight")];

pub var dungeon_r2 = Location{
    .name = "dragon room",
    .route_names = &.{}, //&.{dungeon_r1.name},
    .routes = undefined, //&.{&dungeon_r1},

    .encounter = .{ .combat = &dragon },
};
var jon = actors.array[actors.index("jonathan blow")];
var dragon = actors.array[actors.index("dragon")];

//

pub fn find(amount: u16) void {
    pc.copper += amount;
    output.print("\nfound {} copper coins\n", .{amount});
}

//

// ======================================
//                  shop
// ======================================

pub fn setShopData() void {
    for (inventory.ids[0..inventory.len], inventory.names[0..inventory.len], inventory.costs[0..inventory.len]) |id, *name_index, *cost_index| {
        name_index.* = objects.array[id].name;
        cost_index.* = cost_catalogue[id];
    }
}

const devtools = @import("devtools.zig");
const objects = @import("objects.zig");
const FieldType = @import("std").meta.FieldType;

pub var inventory: Inventory = .{};
pub const inventory_capacity = 9;
const Inventory = struct { // optimization, we might be very slightly better off with AOS here for costs and quantities (and maybe ids, too), since we use them at the same time
    len: devtools.Int(inventory_capacity) = 0,
    quantities: [inventory_capacity]devtools.Int(99) = undefined,
    costs: [inventory_capacity]devtools.Int(80) = undefined,
    ids: [inventory_capacity]objects.Id = undefined,
    names: [inventory_capacity][]const u8 = undefined,
};

fn removeInventoryIndex(index: usize) void {
    for (
        inventory.costs[index .. inventory.len - 1],
        inventory.costs[index + 1 .. inventory.len],

        inventory.quantities[index .. inventory.len - 1],
        inventory.quantities[index + 1 .. inventory.len],

        inventory.ids[index .. inventory.len - 1],
        inventory.ids[index + 1 .. inventory.len],

        inventory.names[index .. inventory.len - 1],
        inventory.names[index + 1 .. inventory.len],
    ) |
        *cost_i,
        cost_e,
        *quantity_i,
        quantity_e,
        *id_i,
        id_e,
        *name_i,
        name_e,
    | {
        cost_i.* = cost_e;
        quantity_i.* = quantity_e;
        id_i.* = id_e;
        name_i.* = name_e;
    }

    inventory.len -= 1;
}

pub fn addToInventory(id: objects.Id, quantity: devtools.Int(99)) void {
    const insertion_point: usize = blk: {
        for (inventory.ids[0..inventory.len], 0..) |e, i| {
            if (e > id) break :blk i;
        }
    };

    var it: usize = inventory.len;
    while (it > insertion_point) : (it -= 1) {
        inventory.quantities[it] = inventory.quantities[it - 1];
        inventory.ids[it] = inventory.ids[it - 1];
        inventory.costs[it] = inventory.costs[it - 1];
        inventory.names[it] = inventory.names[it - 1];
    }

    inventory.quantities[insertion_point] = quantity;
    inventory.ids[insertion_point] = id;
    inventory.costs[insertion_point] = cost_catalogue[id];
    inventory.names[insertion_point] = objects.array[id].name;

    inventory.len += 1;
}

const cost_catalogue: [objects.array.len]devtools.Int(80) = init: {
    var array: [objects.array.len]devtools.Int(80) = undefined;
    array[objects.index("hammer")] = 0;
    array[objects.index("starscar shield")] = 60;
    array[objects.index("zeniba's solid gold monogram seal")] = 30;
    array[objects.index("heal charm")] = 60;
    array[objects.index("fireball")] = 10;
    array[objects.index("firegorger")] = 20;
    array[objects.index("ice missile")] = 25;
    array[objects.index("arc spell")] = 40;
    array[objects.index("thunder spell")] = 30;
    array[objects.index("sacred lance")] = 60;
    array[objects.index("potion of magic energy")] = 10;
    break :init array;
};

fn vendor() ?void {
    output.newScreen();
    output.writeAll("\nyou walk into a shop. a vendor shows you his wares");
    while (true) {
        output.writeAll("\n\n" ++ output.selectable_color ++ "leave\n" ++ output.standard_color ++ " " ** (objects.longest_name_len + 4) ++ "cost" ++ " " ** 8 ++ "in stock");

        // =======================
        //       print names
        // =======================

        // feature, turn this into a function and add indexes to the struct so we can print newlines in between the item types
        for (
            inventory.names[0..inventory.len],
            inventory.costs[0..inventory.len],
            inventory.quantities[0..inventory.len],
        ) |name, cost, quantity| {
            // format to line up the text like so:
            // potion of mana          cost: 4      in stock: 10
            // arc spell               cost: 20     in stock: 1

            output.print(output.selectable_color ++ "\n{s: <" ++ devtools.numberAsString(objects.longest_name_len + 4) ++ "}" ++ output.standard_color ++ "{: <12}{}", .{ name, cost, quantity });
        }
        output.print("\n\n" ++ " " ** (objects.longest_name_len + 4 - 9) ++ "you have {} currency\n\n", .{pc.copper});

        // =========================
        //       the other bit
        // =========================

        while (true) { // continue when the player doesn't have enough money
            const s = input.selectFrom(&.{
                main.default_actions,
                &.{"leave"},
                inventory.names[0..inventory.len],
            });
            switch (s.which_array) {
                0 => {
                    main.switchOnDefaultActions(s.index) orelse return null; // quit
                    break;
                },
                1 => { // leave the shop
                    output.newScreen();
                    return;
                },
                2 => {
                    if (pc.copper < inventory.costs[s.index]) {
                        input.maintainInvalidInputs();
                        output.writeAll("not enough money\n");
                        continue;
                    }
                    output.newScreen();
                    pc.copper -= inventory.costs[s.index];
                    output.print("purchased {s}\n", .{inventory.names[s.index]});
                    pc.addToInventory(inventory.ids[s.index], 1);

                    if (inventory.quantities[s.index] > 1) {
                        inventory.quantities[s.index] -= 1;
                    } else {
                        removeInventoryIndex(s.index);
                    }

                    break;
                },
                else => unreachable,
            }
        }
    }
}
