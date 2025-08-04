# SellNPC

### Command Usage:
```
sellnpc <item_name>	-- add item_name to sales queue. quotes not needed, accepts auto-translate. 
sellnpc <profile_name> 	-- load a group of items from profiles.lua into the sales queue
```
Sales are now triggered by opening a shop window, you will need to queue items prior to this.

Items are removed from queue once selling has completed.

Will not try to sell items equipped, in bazaar or that can not be sold to NPC vendors.

##### If there has been a mainenance or update to the game make sure windowers resource files have been updated to reflect new items added.

### Auto-sell

[Kaiconure](https://github.com/Kaiconure) created a [fork of SellNPC](https://github.com/Kaiconure/SellNPC) in July of 2025, which adds support for a managed auto-sell list. This allows you to maintain a list of items that are always sold automatically anytime you interact with a vendor npc.

For command format takes the following form:

```bash
sellnpc auto [<command>] [<arguments>]
```

Here's a list of the currently supported commands:

- `on` - This turns the auto-sell feature on. Run as `sellnpc auto on` or view the current status with `sellnpc auto`.
- `off` - This turns the auto-sell feature off. Run as `sellnpc auto off` or view the current status with `sellnpc auto`.
- `list [<filter>]` - This lists all items you have in your auto-sell list, in alphabetical order. Run as `sellnpc auto list`. If you specify a filter, only auto-sell items with that filter somewhere in the name will be shown. For exmple, `sellnpc auto list ore` will show all ores you've got configured for auto-sale. Of course, you'd _also_ see things like "Mantic**ore** Hide".
- `add <item_name>` - This adds an item to your auto-sell list. Run as `sellnpc auto add bone chip`.
- `remove <item_name>` - This removes an item from your auto-sell list. Run as `sellnpc auto remove beehive chip`.

The new features are fully compatible with multibox setups. This means you can run something like `send @all sellnpc auto add treant bulb` and there will be no risk of cross-corruption of data.

---

Keep in mind that the auto-sell list is OFF by default. You'll need to run `sellnpc auto on` to use it. 

**There's no way to recover items that were accidentally sold to an NPC, so use it at your own risk. I will not be held responsible for mistakes made using this addon.**

