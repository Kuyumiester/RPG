// potential names for this file: sailor, wizard, hero, player, character, player_character (abbreviated to pc in other files), adventurer, avatar, protagonist,
const std = @import("std");

const actors = @import("actors.zig");
const output = @import("output.zig");
const combat = @import("combat.zig");
const devtools = @import("devtools.zig");

pub var name: []const u8 = undefined;
pub var name_buffer: [60]u8 = undefined;
pub var health: u8 = 8;
pub var health_max: u8 = 8;
pub var balance_gen: u8 = 1;
pub var balance_max: u8 = 8;
pub var action_point_gen: u8 = 2;
pub var action_point_max: u8 = 12;
pub var magic_energy_gen: u8 = 1;
pub var magic_energy_max: u8 = 99;
pub var armor: u8 = 3;
pub var power: u8 = 2;
pub var trinket_effects_len: u8 = 0;
pub var trinket_effects_array: [1]*const fn (*combat.Actor) void = undefined;

pub fn addTrinketEffect(fn_ptr: *const fn (*combat.Actor) void) void {
    trinket_effects_array[trinket_effects_len] = fn_ptr;
    trinket_effects_len += 1;
}

// =========
// inventory
// =========

const objects = @import("objects.zig");
pub inline fn init() void {
    if (devtools.developer_build) {
        addToInventory(objects.index("death spell"), 1);
    }
}

// consider putting this in a money struct |if and only if| there's a good reason
pub var copper: u16 = 20;
pub var silver: u16 = 0;
pub var gold: u16 = 0;

// ==================================================================================
// weapons the player has equipped, affecting what normal actions they have access to
// ==================================================================================

const equipment = @import("equipment.zig");

pub var hand_1: equipment.Weapon = equipment.hammer.onion.weapon;
pub var hand_2: equipment.Weapon = equipment.basic_shield.onion.weapon;

const FieldType = std.meta.FieldType;

// ==============================
// spells the player has equipped
// ==============================

const spells = @import("spells.zig");

pub var spells_soa: SpellsSoa = .{};
const spells_soa_capacity = objects.number_of_spells; // what's the highest number of spells the player can choose to cast between at any given time?
const SpellsSoa = struct {
    len: devtools.Int(spells_soa_capacity) = 0,
    ids: [spells_soa_capacity]objects.Id = undefined, // optimization: have an array of spell function pointers, instead of getting them via id. unless we already fetch from the objects array previously... currently, we do --to check spell power
    names: [spells_soa_capacity][]const u8 = undefined,
    costs: [spells_soa_capacity]combat.ActionCost = undefined,

    fn add(
        self: *SpellsSoa,
        id: objects.Id,
    ) devtools.Int(spells_soa_capacity) {
        self.ids[self.len] = id;
        self.names[self.len] = objects.array[id].name;
        self.costs[self.len] = objects.array[id].onion.spell.cost;
        defer self.len += 1;
        return self.len;
    }
};

// ==========================
// consumables the player has
// ==========================

const consumables = @import("consumables.zig");

const consumables_soa_capacity = 4; // what's the highest number of consumables the player can carry?

// optimization, if we always have equal access to all consumables in our inventory, and our inventory will always be organized such that all consumables are next to each other, then we don't need a separate consumables_soa. *but* there's a half-decent chance we won't always have access to all our consumables.
pub var consumables_soa: struct {
    len: devtools.Int(consumables_soa_capacity) = 0,
    inventory_indexes: [consumables_soa_capacity]devtools.Int(inventory_capacity) = undefined,
    names: [consumables_soa_capacity][]const u8 = undefined,
    quantities: [consumables_soa_capacity]@TypeOf(inventory.quantities[0]) = undefined, // optimization, we should probably just use the quantities in the inventory. why didn't i do that?
} = .{};

// ==================================================================================
// the player's inventory, which holds all the player's consumables, spells, weapons,
// ==================================================================================

const inventory_capacity = objects.array.len; // what's the highest number of items the player can carry?

pub var inventory: struct {
    len: devtools.Int(inventory_capacity) = 0,
    quantities: [inventory_capacity]devtools.Int(99) = undefined,
    ids: [inventory_capacity]objects.Id = undefined,
    //enums: [inventory_capacity]objects.Enumerator { spell, consumable, weapon },
    names: [inventory_capacity][]const u8 = undefined,
    soa_indexes: [inventory_capacity]union(objects.Enumerator) {
        weapon: void,
        trinket: void,
        spell: devtools.Int(spells_soa_capacity),
        consumable: devtools.Int(consumables_soa_capacity),
    } = undefined,
} = .{};

pub fn addToInventory(
    id: objects.Id,
    quantity: devtools.Int(99),
) void {

    //      see if we already have this object in the inventory
    //
    for (inventory.ids, 0..) |inv_id, index| {
        if (inv_id == id) {
            inventory.quantities[index] += quantity;
            if (objects.array[id].onion == .consumable) {
                consumables_soa.quantities[inventory.soa_indexes[index].consumable] += quantity;
            }
            return;
        }
    }

    //      add the object to the inventory
    //

    inventory.ids[inventory.len] = id;
    inventory.names[inventory.len] = objects.array[id].name;
    inventory.quantities[inventory.len] = quantity;

    switch (objects.array[id].onion) {
        .trinket => |trinket| trinket.equip(),
        .spell => {
            inventory.soa_indexes[inventory.len] = .{ .spell = spells_soa.add(id) };
        },

        .consumable => {
            inventory.soa_indexes[inventory.len] = .{ .consumable = consumables_soa.len };

            // add consumable to the consumables_soa
            consumables_soa.inventory_indexes[consumables_soa.len] = inventory.len;
            consumables_soa.names[consumables_soa.len] = objects.array[id].name;
            consumables_soa.quantities[consumables_soa.len] = quantity;
            consumables_soa.len += 1;
        },
        else => {},
    }

    inventory.len += 1;
}
