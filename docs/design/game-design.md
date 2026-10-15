# The Conduct of Magic: Game Design Document

> Living document for gameplay and story design. It holds no implementation details.
> Sections marked **Proposed** are suggestions that haven't been agreed yet. **Open questions** collect what still needs deciding.

## 1. Pitch

A shop-management, inspection and crafting game about running an enchanter's shop. By day you serve customers at the counter: you sell enchanted goods, take commissions and inspect what people bring you. At night you enchant items by laying enchantment patterns onto them and powering those patterns with materials. Over the days, the way you manage the shop, your materials and your relationships pushes a story forward.

**Inspirations**
- **Papers, Please**: the inspection style. You read documents and identification, examine goods and decide whether to accept.
- **Potion Craft**: a hands-on crafting system paired with a front-of-house customer loop.

## 2. Pillars

1. **Inspect before you commit.** Every commission is a judgement call made from the evidence on the counter.
2. **Enchanting is a spatial puzzle.** An item's capacity is a map of nodes. You fit and power enchantments on it by hand.
3. **Everything you make has a use.** Enchanted goods fulfil commissions, stock the shelves, upgrade the shop or become tools for inspecting.
4. **Relationships drive the story.** Customers return, remember and change what the story offers.

## 3. Core loop

```
┌──────────────── SHOP DAY ────────────────┐      ┌────────────── ENCHANTING DAY ──────────────┐
│ Customers browse and approach the counter │      │ Review accepted commissions                │
│  • Buy from stock                         │ ───► │ Enchant received or bought items           │
│  • Request a commission (custom or bulk)  │      │ Make stock, shop upgrades and inspection   │
│  • Collect a finished commission          │      │   consumables                              │
│ Inspect documents, ID, items, materials   │ ◄─── │ Finished commissions wait for pickup       │
│ Accept or decline                         │      │                                            │
└───────────────────────────────────────────┘      └────────────────────────────────────────────┘
                 Money · materials · reputation · relationships → story
```

## 4. The shop day

**View:** the shop is shown in isometric view. NPCs walk in, browse the goods on display and may come up to the counter.

**Counter interactions.** A customer at the counter may:
- **Buy an item from stock.**
- **Request a commission**, which is either:
  - **Custom**: a one-off piece made to their specification.
  - **Bulk**: repeat work you already do, the way a blacksmith takes orders.
- **Collect a commission** they placed on an earlier day.

**Taking a commission**
1. Read the commission, which states what they want and the terms.
2. Check any identification or documents they need to present.
3. Accept or decline.
4. They come back on a later day to collect it.

**Customer-supplied goods.** Some commissions come with the customer's own item, materials or both. Those goods can be inspected, and that's where the Papers, Please tension comes in.

**Inspection.** On the workstation you zoom in on items and examine their parts. Some inspections may need consumable tools that you enchant yourself (see §6).

## 5. The enchanting day

When the shop closes, the player moves to enchanting:
1. **Review commissions** to see what's owed, to whom and by when.
2. **Choose an item** you received from a customer or bought yourself.
3. **Open its enchantment map.** Every item contains a set of nodes, and these nodes are its *capacity for enchantment*.
4. **Place enchantments.** Each enchantment is itself a group of nodes that you drag onto the item's map.
5. **Activate the enchantment.** You insert materials into its nodes. Each material carries **conditions**, such as how many connections the node needs. You meet them by connecting the enchantment's nodes to nodes already on the map, and more kinds of condition may come later.
6. An enchantment works once every one of its nodes is activated.

**Existing enchantment ideas** (from `enchantments/enchantment_list.txt`)
- *Tier 1, physical:* Sharpness, Bluntness, Lightness, Heaviness, Roughness, Smoothness, Brittleness, Toughness.
- *Tier 2, tied to line geometry:*
  - Obtuse and acute angles give Loudness/Silentness, Reflectiveness/Dullness and enhanced or suppressed Smell and Taste.
  - Colinear lines give Fire, Water, Wind or Earth **Conductivity**, which enhances the effect of that element.
  - Right angles give Fire, Water, Wind or Earth **Resistance**, which suppresses the effect of that element.

## 6. Uses of enchanted items

- **Commissions**: deliver them to the customer for payment and relationship gain.
- **Stock**: sell from the shelves.
- **Shop upgrades**: for example, enchanted lights placed in the store for the coming day.
- **Inspection consumables**: tools that help you inspect what customers bring you.

## 7. Meta systems

- **Store management**: stock, displays, upgrades, money.
- **Material management**: sourcing, holding and spending materials, including materials customers provide.
- **Relationship management**: customers and NPCs who come back. How you treat them moves the story.

## 8. Story

The story moves forward through managing the store, materials and relationships. *(Setting, protagonist, premise and structure are still to be written. See the open questions.)*

Existing hook in the prototype: a custom item called **Father's Sword**.

## 9. Open questions

**Inspection**
1. What can be *wrong* with a commission or a customer's goods? For example stolen items, forged ID, cursed or flawed materials, items already enchanted or banned enchantments.
2. Who sets the rules you inspect against, such as a guild, the law or your own reputation? Papers, Please gets its tension from rules that change day by day.
3. What happens when you accept something you shouldn't have, or turn away something good?

**Shop**
4. How much does the player control the shop floor? Can they arrange displays and set prices, or only serve at the counter?
5. Is there time pressure during the shop day, such as a clock or a queue of customers?
6. Is the shop open every day, or are there market days, quiet days and events?

**Enchanting**
7. Is there a limit on the enchanting day, such as hours, energy or candles?
8. Can an enchantment fail or damage an item, and can it be undone?
9. Should the Tier 2 geometry idea (angles, colinear and right-angled lines) carry on as the core of the conditions system?
10. Where do materials come from: suppliers, customers, foraging or salvage from items?

**Story and relationships**
11. Who is the player, and why do they run this shop? How does Father's Sword fit in?
12. Is the story told in chapters or seasons, or does it follow from relationships?
13. How do relationships show up for the player: memory of past deals, prices, story events, endings?

## 10. Decision log

| Date | Decision |
|---|---|
| 2026-10-15 | The game alternates a **shop day** and an **enchanting day**. |
| 2026-10-15 | Inspiration: Papers, Please for inspection, Potion Craft for crafting and the customer-facing shop. |
| 2026-10-15 | Commissions are custom or bulk. Customers collect them on a later day and may supply their own items or materials, which can be inspected. |
| 2026-10-15 | An item's enchantment capacity is a map of nodes. Enchantments are node groups dragged onto it and activated by inserting materials that carry conditions. |
| 2026-10-15 | Enchanted items can also be shop upgrades (lights) and inspection consumables. |
