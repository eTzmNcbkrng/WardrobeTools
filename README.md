# WardrobeTools

WardrobeTools is a simple World of Warcraft addon that streamlines transmog/appearance collection. It has two functions:

* **Mailer**: WardrobeTools adds a button to the default mailbox UI. With one click, WardobeTools examines all BOE armor and weapons in your inventory, determines if you have collected the appearance from each, and if not, automatically mails each item to alts that can equip them.

* **AppearanceCollector**: Once your alts have received the mailed items, use **/ac** to display the AppearanceCollector button. Clicking the button will equip an uncollected appearance item from your inventory. Clicking the button again will equip the next uncollected item, and so forth, until all appearances have been collected from items in your inventory. The last click will swap back to your original equipment.

### Setup 

* Open WardrobeTools settings from the default mailbox UI, by clicking the [>] button next to "Send Transmogs." 
* In this menu, enter the names of your alts that you want to send each armor and weapon type to.
* Then click "Send Transmogs" to mail items. 
* Hover on "Send Transmogs" for a preview of which items will be mailed.

### New Feature: TradeSkillMaster Filtering!

WardrobeTools' mailer can now stop items from being mailed, based on values from TradeSkillMaster. This is an entirely optional feature.

Let’s say you’ve finished running some old dungeons. Your inventory is full of BOEs. Some of these BOEs are appearances you haven't collected. But some of them are also really valuable! You *could* sift through all of them one by one, decide which items to auction, and which appearances to collect. That's time consuming. Now WardrobeTools can do that for you, by deciding whether to mail or not mail BOEs based on a TSM price source.

For example, if you want to auction items with a DBMarket value over 1000g instead of collecting the appearance, you can specify that in the settings. WardrobeTools will still mail uncollected items to your alts, *unless an item has a DBMarket value over 1000g.* Those items will stay in your inventory. **This is intended to work alongside TSM mailing operations: first run WardrobeTools' mailer to send "worthless" uncollected appearances to your alts, then run your TSM mailing operations so the remaining "valuable" items (plus *collected* appearances) are sent to your auction house alt, or to whatever character your TSM mailing operation specifies.** 

The TSM filter settings are located with the other settings accessible through the mailbox UI:

- **Enable TSM Filtering**: Turns the TSM filter on and off.
- **TSM Price Source**: any valid TradeSkillMaster price source (DBMarket, DBHistorical, etc.) or custom string.
- **Mail only if price source is less than**: WardrobeTools will *not* mail items if the price source is greater than this value. Must be a numeric value, including two silver and two copper digits. (For example, 1000g would be inputted as 10000000). Don't put a "g" or anything on the end.

If these settings aren't valid or TSM isn't installed, WardrobeTools will not send *any* mail until you fix the settings or un-check "Enable TSM filtering."

**IMPORTANT: TSM filtering only applies to MAILING. AppearanceCollector (/ac) does *not* look at TSM data. If there are valuable uncollected appearances in your inventory, /ac will *not* stop you from equipping them.**

### Do I need TradeSkillMaster to use WardrobeTools?

No. Open WardrobeTools’ settings, and uncheck “Enable TSM filtering.” WardrobeTools will then send items to your specified alts according to the other filters, regardless of value.

### What happened to using mouse scroll with AppearanceCollector?

That was a bit of a risky and hidden feature, which might cause you to accidentally equip transmogs you want to sell (it happened to me, I was unaware scroll wheel did anything until after months of using this addon). I've disabled the mouse scroll, but if you really want, you can re-enable it by un-commenting the two lines in the "BindMouseWheel" function in appearance_collector.lua.

### Addon History

- This Addon was initialy copied from a forum post [here](http://stormspire.net/general-tradeskillmaster-discussion/18409-mailing-groups-boe-armor-classes-post169681.html#post169681).  
- The majority was written by Martin Karer/Sezz and is distributed under his license.
