# The Conduct of Magic: Game Design Document

> Living document for gameplay and story design. It holds no implementation details.
> Items marked **On hold** are ideas parked for later. Items marked **Proposed** are suggestions that haven't been agreed yet. **Open questions** collect what still needs deciding.

## 1. Pitch

A shop-management, inspection and crafting game about a young enchanter learning the trade in their uncle's workshop. By day you serve customers at the counter: you sell enchanted goods, take commissions and inspect what people bring you. At night you enchant items by laying enchantment patterns onto them and powering those patterns with materials. Who you choose to help, and how well you do the work, decides where your life goes next.

**Theme.** The title, *The Conduct of Magic*, is the question the game asks. You've been given a rare gift. Enchanting can help a great many people, and it can also make you rich. How you conduct yourself with it is up to you.

**Inspirations**
- **Papers, Please**: the inspection style. You read documents and identification, examine goods and decide whether to accept.
- **Potion Craft**: a hands-on crafting system paired with a front-of-house customer loop.

## 2. Pillars

1. **Inspect before you commit.** Every commission is a judgement call made from the evidence on the counter.
2. **Enchanting is a spatial puzzle.** An item's capacity is a map of nodes. You fit and power enchantments on it by hand.
3. **Everything you make has a use.** Enchanted goods fulfil commissions, stock the shelves, upgrade the shop or become tools for inspecting.
4. **Your choices of whom to serve shape the story.** Customers return, remember and carry their own plots, which your decisions move forward or cut off.

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
        End of day: the uncle settles the books → money · reputation · plot flags
```

## 4. The shop day

**View:** the shop is shown in isometric view. NPCs walk in, browse the goods on display and may come up to the counter.

**Counter interactions.** A customer at the counter may:
- **Buy an item from stock.**
- **Request a commission**, which is either custom (a one-off piece made to their specification) or bulk (repeat work you already do, the way a blacksmith takes orders). See §5.
- **Collect a commission** they placed on an earlier day.

**Inspection.** On the workstation you zoom in on items and examine their parts. Some inspections may need consumable tools that you enchant yourself (see §8).

## 5. Commissions

### 5.1 Lifecycle
1. **Request.** The customer presents the commission, which states what they want and the terms. They may also show identification or certification, and may hand over their own item, materials or both.
2. **Inspect.** You read the commission and check any documents. You examine anything they handed over.
3. **Accept or reject.**
4. **Fulfil.** On the enchanting day you do the work.
5. **Collect.** The customer returns **on a later day**, not the same day. Most consequences land at this point.

### 5.2 Why reject a commission
- **You don't want to support that NPC or their plot.** Every customer has a story of their own. Accepting moves it forward, and rejecting may cut it off or send it somewhere else.
- **You think they're lying.** Once you accept, you're responsible for delivering by the deadline. If the customer misdescribes their item or material (for example, claiming it's a material that can take the enchantment when it can't), the failure is yours.
- **It breaks the rules** you inspect against (see §6).
- **It's dangerous**, for example a cursed item or faulty materials.

### 5.3 Consequences
Consequences mostly land **when the commission is completed or due**, not when it's accepted. That fits a customer who comes back on another day.

| What went wrong | Possible consequence |
|---|---|
| Couldn't deliver (customer lied, or you overreached) | Lost payment, refund, reputation damage, the uncle docks your income |
| Cursed item | Strange effects in the shop, harm to you or the stock; you can only shed it by finding the right customer, cleansing it or giving it up |
| Faulty materials | They **blow up** when used or at the end of the market day. Recovering costs money, and in severe cases it's game over |
| Breaking guild or legal rules | Fines, investigation, loss of standing with a faction |

**Proposed design rule: fair blame.** A penalty should scale with whether the problem was **detectable at inspection with the tools you had**. If the clue was there and you missed it, you take the full consequence. If nothing could have revealed it, the customer takes the blame and you mostly lose time. This keeps the Papers, Please feeling that every mistake is your own, and gives inspection consumables (§8) a clear purpose because they reveal more.

### 5.4 Is the liability realistic?
Broadly yes, and real-world practice offers ready-made mechanics:
- **Craftspeople were liable for the goods in their care.** In law this is *bailment*. A smith or jeweller holding a customer's item has to take reasonable care of it, so damage from faulty materials in your workshop being your cost fits.
- **Misrepresentation shifts blame, but not completely.** If a client lies about a material fact, the contract can usually be undone and the craftsperson isn't at fault. However, a professional is expected to check what a trained eye would catch. That is exactly the fair-blame rule above, and the reputation hit happens either way.
- **Testing materials was part of the job.** Goldsmiths tested metal with a touchstone and acid before working it. Since 1300, London's goldsmiths' guild has stamped hallmarks to certify purity. Both map well onto inspection tools and guild certification.
- **Handling stolen goods was a crime** for the craftsperson too, not only the thief. That's a natural reason for ID checks and a legal rule to inspect against.

### 5.5 On hold
- **ID and certification with an effect at acceptance.** On hold because the consequence makes more narrative sense at completion. ID may still exist as evidence to inspect.
- **Deposits and loans.** You'd lend the customer equipment while their item is being enchanted, and what they leave as a deposit would also affect the plot.

## 6. Rules you inspect against

What counts as acceptable work comes from several sources, which can conflict:
- **Guilds**: the enchanters' guild (and possibly others) set standards, certifications and banned work.
- **Laws**: the town or city sets what's legal to make, sell or possess.
- **Personal reputation**: what the town expects of your shop.
- **Your allegiances**: the people or groups you choose to support. Helping one faction may break another's rules.

Rules can change over time, the way they do in Papers, Please.

## 7. The enchanting day

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

*Map features and further enchanting mechanics still need writing up.*

## 8. Uses of enchanted items

- **Commissions**: deliver them to the customer for payment and to move their story along.
- **Stock**: sell from the shelves.
- **Shop upgrades**: for example, enchanted lights placed in the store for the coming day.
- **Inspection consumables**: tools that reveal more about what customers bring you, such as true material, curses or flaws.

## 9. Story and progression

### 9.1 Premise
The main character has the gift of enchanting. They start out working in their **uncle's workshop**.

### 9.2 The uncle
The uncle owns the shop and settles the books at the end of each day. He's the immediate feedback for bad decisions: taking bad commissions means **lower income** that day. This makes consequences felt early without needing a game over.

### 9.3 Progression routes
After a few days or weeks in the uncle's shop, the player moves on. **Where they go depends on performance, money and choices:**

| Route | How you get there | What it means |
|---|---|---|
| **University** | A near-perfect run with enough money | The respectable, scholarly path |
| **Adventurers' Guild** | Not enough money for the university | Practical, dangerous work |
| **Black Market** | *(Proposed: reached through shady commissions or allegiances)* | High reward, high risk, and early game overs (death) are possible |

### 9.4 Macro levels (later)
Each route is a **macro level**: a new place with slightly different mechanics and new kinds of customers. This will be developed later.

### 9.5 Example items
- **Father's Sword**: an example item from the prototype, not a story commitment.

## 10. Open questions

**Commissions and inspection**
1. What can the player inspect on a customer's item to catch a lie? For example markings, weight, colour, a reaction to a test material, or the map's node layout itself.
2. How long does a customer give you to finish? Is it a fixed number of days per commission, or set by the customer?
3. Can you return or refuse an item *after* accepting, for example once you discover it's cursed? What does that cost?

**Rules and factions**
4. Which guilds and factions exist in the uncle's town, and which of them later lead to the University, Adventurers' Guild and Black Market?
5. How does the player learn the rules? Through a rulebook, the uncle's notes or guild notices?

**Story**
6. Is the main character's gift rare or unique, and who knows about it?
7. What is the uncle like? Does he have an agenda of his own, or is he a mentor?
8. Does the player choose a route, or does the game assign one from their results?
9. How many days or weeks does the uncle's-workshop chapter last?

**Shop and enchanting**
10. How much does the player control the shop floor? Can they arrange displays and set prices, or only serve at the counter?
11. Is there time pressure during the shop day or the enchanting day?
12. Can an enchantment fail or damage an item, and can it be undone?
13. Where do materials come from: suppliers, customers, foraging or salvage from items?

## 11. Decision log

| Date | Decision |
|---|---|
| 2026-10-15 | The game alternates a **shop day** and an **enchanting day**. |
| 2026-10-15 | Inspiration: Papers, Please for inspection, Potion Craft for crafting and the customer-facing shop. |
| 2026-10-15 | Commissions are custom or bulk. Customers collect them on a later day and may supply their own items or materials, which can be inspected. |
| 2026-10-15 | An item's enchantment capacity is a map of nodes. Enchantments are node groups dragged onto it and activated by inserting materials that carry conditions. |
| 2026-10-15 | Enchanted items can also be shop upgrades (lights) and inspection consumables. |
| 2026-10-15 | Consequences of a commission land at **completion**, not acceptance. The ID/certification system and deposits are **on hold**. |
| 2026-10-15 | Reasons to reject a commission: you don't want to back that NPC's plot, you suspect a lie, it breaks rules, or it's dangerous (cursed items, faulty materials). |
| 2026-10-15 | Rules to inspect against come from **guilds, laws, personal reputation and the player's chosen allegiances**. |
| 2026-10-15 | Theme: a gift that can help people or make you rich. The player starts in the **uncle's workshop**, and the uncle docks income for bad commissions. |
| 2026-10-15 | Progression routes: **University** (a near-perfect run with money), **Adventurers' Guild** (without money) and **Black Market** (risky, early death possible). Macro levels are for later. |
| 2026-10-15 | Father's Sword is an example item only. |
