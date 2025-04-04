# Terminal-Based RPG

This is an RPG than you can play in a terminal emulator.
It's far from being done, though.

This program is written in the Zig programming language.  
See this page for installing Zig: https://ziglang.org/learn/getting-started/#direct

### To compile and run the program:
Open a terminal emulator in the same directory/folder as the "build.zig" file and "src" folder, then enter:

    zig build run


## About the game

All interactions in the game are achieved by typing a string and pressing enter. Gameplay typically consists of
selecting between several options presented to you. Select an option by entering text matching the option.

If you see an option like "big hat", you select it by typing `big hat` and pressing enter.
But you don't have to type the whole string. Here are some possible shorthand inputs: `big`, `bi ha`, `h`.
But if you can choose between "big hat" and "big sword", then `big` won't work as an input, and you'll have to
include at least an `h` or an `s`.

Most actions that you can do will be visible as blue text, but some common actions won't be visible.
For instance, you can type `quit` from anywhere in the game, and you'll exit the program.
You can also type 'inventory' to see (some) of your character's attributes and belongings.

Gameplay consists of traveling, shopping, and fighting.

### Combat
Combat is subject to change, but here's how it works at the moment:
Combat is turn-based. You take a turn, then your enemy takes a turn, then it repeats.
Whatever action you selected on your turn will not affect the enemy until their turn. Whatever action your enemy
takes will not affect you until after you decide what action to take.
If you choose to `shield`, the incoming effect of the enemy's action will be diminished.

Attacking, kicking, and shielding all cost action points. You regenerate some action points each turn.
Effects of actions usually involve normal damage and balance damage. If an actor's balance drops to 0, they'll
take 2 extra damage, except from non-damaging attacks.

You can buy spells from the shop. Spells need "power" to use. Buy the artifact `zeniba's solid gold monogram seal`
from the shop to increase your power and use more powerful spells.
Once in battle, you will generate an amount of "magic energy" each turn. Once you have enough magic energy, you
can cast a spell. Here's some basic info about the spells:
```
                  cast cost    damage    balance damage
- fireball      :  4            7         3
- firegorger    :  8            11        4
- ice missile   :  3            5         5
- arc spell     :  4            *         2    (deals damage equal to magic energy)
- thunder spell :  9            10        16
- death spell   :  0            *         0    (kills opponent) (exclusive to developer build)
```

### Screenshots

![shop](/screenshot1.png)
![combat](/screenshot2.png)
