# item_drop
By [PilzAdam](https://github.com/PilzAdam), [texmex](https://github.com/tacotexmex/).

## Description
This mod adds Minecraft like drop/pick up of items to Minetest.

## Licensing
LGPLv2.1/CC BY-SA 3.0.

## Notes
item_drop can be played with Minetest 0.4.16 or above. It was originally developed by [PilzAdam](https://github.com/PilzAdam/item_drop).

## List of features
- All settings may be configured from within the game itself (Settings tab > Advanced settings > Mods > item_drop)
- Drops nodes as in-world items on dig if `enable_item_drop` is `true`. (true by default)
- Pulls items to the player's inventory if `enable_item_pickup` is `true`. (true by default) It uses a node radius set in `pickup_radius` (default 0.75)
- Plays a sound the items are picked up, with the gain level set it `pickup_gain` (default 0.4)
- Requires a key to be pressed in order to pull items if `enable_item_pickup_key` is `true`. (true by default). The keytypes to choose from by setting `item_pickup_keytype` are:
 - Use key (`Use`)
 - Sneak key (`Sneak`)
 - Left and Right keys combined (`LeftAndRight`)
 - Right mouse button (`RMB`)
 - Sneak key and right mouse button combined (`SneakAndRMB`)

## Known issues

## Bug reports and suggestions
You can report bugs or suggest ideas by [filing an issue](http://github.com/tacotexmex/item_drop/issues/new).

## Links
* [Download ZIP](https://github.com/tacotexmex/item_drop/archive/master.zip)
* [Source](https://github.com/tacotexmex/item_drop/)
* [Forum thread](https://forum.minetest.net/viewtopic.php?t=16913)
