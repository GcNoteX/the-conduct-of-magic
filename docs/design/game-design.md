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

**Inspection.** On the workstation (the inspection board) you zoom in on items and examine their parts. Some inspections need consumable tools that you enchant yourself (see §8).

### 4.1 What you can inspect
| Method | How it works | What it can reveal |
|---|---|---|
| **Visible markings** | Zoom in and look for stamps, engravings, maker's marks, wear and damage | Forged or missing guild marks, a wrong maker, stolen goods (marks filed off), signs of a curse |
| **Test reactions** | Use a tool on the item, or place a test material next to it on the board, and watch the visual response (colour change, glow, smoke, frost) | The true material, whether it can take an enchantment, hidden flaws, curses |
| **Weight** | Weigh the item or material | A cheaper core under a plated surface, a hollow item, a mislabelled material |

**Not available:** the item's enchantment node map can't be seen during inspection. It's only revealed on the enchanting day. *(It may come back later, for example as an advanced inspection tool.)*

**Proposed.** Test materials and tools could be consumed on use. Each check then costs something, and the player has to choose which tests are worth running on which customer. Stronger tools, such as ones that reveal curses, would come from your own enchanting (§8).

### 4.2 Books and printed matter
**There's no foraging.** Materials and knowledge come to you through the shop, so printed matter is the player's window to the wider world.

**Kinds**
| Kind | What it gives |
|---|---|
| **Material guides** | How materials look, what they weigh and how they react to tests. An inspection reference, like the rulebook in Papers, Please |
| **Research papers** | Enchanting knowledge, such as new enchantments or new ways to meet conditions |
| **Culture and group guides** | Customs, markings and goods of different cultures and factions, which helps you read customers and their items |
| **News** | What's happening in the world: rule changes, events, and story beats elsewhere |
| **Adverts for reputable people** | Who's trusted and who's notable, which helps you judge customers and claims |
| **Contact adverts** | **Unlock a new person to contact**, such as a supplier, a specialist or a client |

**How you get them**
- **Gifts or payment from customers.** This ties into relationships, because a pleased customer may bring you something.
- **A bookstore** the player can visit.
- **A travelling book peddler** who comes into your shop.

### 4.3 Contacts
Contact adverts (and other sources) unlock **contacts**, people outside the shop you can deal with. A contact may offer one or more of these:
- **Procurement:** access to **unique materials**, or regular materials at a **cheaper price**.
- **Remote commissions:** you do work for them and send it off, in exchange for **rewards**.
- **Visits:** they **come by your store** as a special customer.

### 4.4 Material supply
How the player gets materials changes as the game goes on:

| Phase | Source | Notes |
|---|---|---|
| **Start** | **The uncle's stock** | Given at the start of the game, and the uncle **restocks it early on** |
| **Later** | **Catalogue** | The player manages stock themselves and orders from a catalogue |
| **Any time** | **Customers in the store** | Chatting with customers, or asking whether they have anything to sell besides their commission. These are random encounters |
| **Any time** | **Contacts** | Unique or cheaper materials (§4.3) |
| **Fallback** | **The uncle's store** | **Expedited materials at a surcharge**, for when you forgot something or run short |

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

### 5.6 Customer negotiation (deadlines, price, payment)
Options ranked from simplest to most complex, with **when in the game** each could be introduced. Each layer adds onto the ones before it.

| # | Mechanic | How it works | Complexity | When to introduce |
|---|---|---|---|---|
| 1 | **Fixed deadline** | Each commission type has a set turnaround, for example 3 days | Very low | Day 1. It's the uncle's shop rule while you learn |
| 2 | **Customer-set deadline** | The deadline is written on the commission slip, and you take it or leave it | Low | First week. It adds a reason to reject ("I can't make that date") |
| 3 | **Preset options** | The customer offers two or three choices, such as "2 days for 150g or 4 days for 100g" | Low to medium | Late in the uncle's-workshop chapter, once you have overlapping commissions |
| 4 | **Calendar pick** *(Gavin's idea)* | A calendar is laid out on the counter. The customer proposes a date and you drag a marker to counter. Earlier dates pay more and later dates pay less. Each customer has a **patience window**, and pushing past it makes them leave or sour | Medium | When the player runs the counter on their own. The same calendar can double as the commission schedule on the enchanting day |
| 5 | **Pay in materials (simple)** | The customer offers some or all of the payment as materials, and you accept or decline | Low to medium | Early to mid. It's a natural fit because customers already bring materials |
| 6 | **Price haggling** | A back-and-forth offer meter, in the style of Potion Craft | Medium | Mid. Possibly combined with the calendar so you trade time against money |
| 7 | **Full bartering** | Both sides put goods on the counter until the trade balances. Needs an item-valuation system | High | Late, or a macro-level special such as the Black Market |
| 8 | **Renegotiation on return** | The customer comes back early or late. They ask for an extension, you ask for one, partial delivery, late penalties | Medium to high | Late, once relationships carry weight |
| 9 | **Relationship and faction modifiers** | Trust and allegiance change patience, discounts and willingness to barter | Medium (a layer over the rest) | Grows alongside the relationship system |

**Patience** is shown in two ways: the customer's **reactions** (expressions, dialogue, body language) and, for now, a **patience bar** at the side. The bar may be removed later so players have to read the customer.

**Proposed path:** start with #1, then #2, then make **#4 (calendar pick)** the first real negotiation mechanic, with #5 alongside it. Hold #7 and #8 for later macro levels. Bartering is only overcomplicated in its full form (#7). The simple accept-or-decline version (#5) is cheap and fits the game.

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
3. **Enchant it** (see below).

### 7.1 The three ingredients
Every enchanting job combines three things:

| Ingredient | What it is |
|---|---|
| **The item** | Its **item map**: the item's internal enchanting structure, made of **magic nodes**. This is the item's capacity for enchantment |
| **Enchantments** | **Fixed-shape** graphs of **enchantment nodes** that you drag and drop onto the item map |
| **Materials** | Inserted into enchantment nodes to activate them |

**No free-form enchanting.** Enchantments have a fixed shape. Earlier ideas where the shape you drew decided the effect (angles, colinear and right-angled lines) are dropped, because they were too hard to design.

### 7.2 How an enchantment comes together
1. **Place.** Drag an enchantment onto the item map.
2. **Connect.** Draw **edges** between the enchantment's nodes and the item's magic nodes. Other kinds of link may come later. Connecting alone does little.
3. **Insert materials** into each enchantment node. This sets the conditions that node needs to activate.
4. **Meet the conditions** by connecting, rearranging or changing materials.
5. **Activate.** When **every** enchantment node is active, the enchantment activates.

### 7.3 Where conditions come from
| Source | When it applies | Example |
|---|---|---|
| **The enchantment node** | Decides which materials it **accepts** | "Only water-type materials" |
| **The material's activation conditions** | Must be met for the node to activate | "With this material, the node needs **3 edges** connected" |
| **Constraints a material adds** | Once inserted, it adds rules about its surroundings | "No **adjacent fire-type** connections" |

**Condition types to experiment with**
- **Edge count:** at least, exactly or at most N edges on this node.
- **Adjacency by type:** must or must not connect to a node or material of a given element.
- **Connect to a specific magic node:** for example a "core" or "hilt" node on the item.
- **Distance or line length:** within or beyond a distance.
- **Shared node:** two enchantment nodes connect to the same magic node.
- **Cross-enchantment:** connects to, or stays clear of, another enchantment on the same item.

Both nodes and materials can carry conditions, but **materials will carry most of them**. For now a node's only condition is **which materials it accepts**.

**Later: node types.** Nodes will eventually have their own types, which conditions can reference.

**Movable nodes.** Some nodes can **shift**: you drag them along a short slider to move them a little. This lets you change distances and positions to meet conditions. Both magic nodes and enchantment nodes can shift (which ones will vary), and shifting is **free**, with no cost in money or items.

### 7.4 Map layout: hex grid
| | Free-form (current prototype) | Square grid | Hex grid |
|---|---|---|---|
| **Readability** | Hard to judge distances by eye | Clear | Clear |
| **Adjacency** | Fuzzy; needs collision checks | 4 or 8 neighbours, with diagonals ambiguous | **6 equal neighbours, no ambiguity** |
| **Distance conditions** | Continuous, so fiddly to meet exactly | Whole steps, but diagonals count differently | **Whole steps, the same in every direction** |
| **Shifting nodes** | Continuous slider | Snaps to cells | Snaps to cells, in 6 directions |
| **Rotating enchantments** | Any angle | 90° steps | 60° steps |
| **Look** | Organic | Technical, like a circuit board or inventory | **Arcane and organic, like honeycomb or rune circles** |
| **Item silhouettes** | Any shape | Blocky | Rounder |

**Decision: hex grid.** Discrete placement makes conditions exact ("adjacent" means a neighbouring cell, and distance is a count of steps). Shifting becomes a snap of one or a few cells. Hexes avoid the square grid's diagonal problem and look more like magic than a circuit board. Edges can still be drawn as straight lines between nodes.



Difficulty comes from combining conditions. A formal ranking of enchantments will be added when it's needed.

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

### 9.2.1 Working the counter with the uncle (tutorial phase)
At first the **uncle runs the business**, and the player is his apprentice.

**Proposed flow:** the customer comes to **you first**.
1. The customer arrives with a **commission sheet** already filled in.
2. You read what they want made and **check it against the rules**. You also inspect any goods they brought.
3. You pass the sheet to the uncle, either approved or flagged with a concern.
4. **The uncle negotiates**, setting a **fixed deadline** (negotiation option #1) and the price, and makes the final call.
5. At night you do the enchanting.

Why you first rather than the uncle first:
- **You stay the checkpoint.** Inspection is the core verb, and it stays in your hands from day 1, as in Papers, Please.
- **Blame is clear.** If you approve a bad commission and the uncle takes it on your word, docking your pay at the end of the day follows naturally.
- **Clean handover.** As you earn trust, the uncle stops doing the negotiation and you take over, starting with customer-set deadlines and then the calendar pick (§5.6). That's progression without a separate tutorial.

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
1. Which specific test materials and tools exist, and what reaction does each one show for each material?
2. For the calendar pick: what limits the latest date you can choose (the customer's patience, a hard deadline, or both)?
3. Can you return or refuse an item *after* accepting, for example once you discover it's cursed? What does that cost?

**Rules and factions**
4. Which guilds and factions exist in the uncle's town, and which of them later lead to the University, Adventurers' Guild and Black Market?
5. How does the player learn the rules: from the uncle, guild notices or books?

**Story**
6. Is the main character's gift rare or unique, and who knows about it?
7. What is the uncle like? Does he have an agenda of his own, or is he a mentor?
8. Does the player choose a route, or does the game assign one from their results?
9. How many days or weeks does the uncle's-workshop chapter last?

**Shop and enchanting**
10. How much does the player control the shop floor? Can they arrange displays and set prices, or only serve at the counter?
11. Is there time pressure during the shop day or the enchanting day?
12. Can an enchantment fail or damage an item, and can it be undone?
13. When does the uncle stop restocking, and how fast do catalogue orders arrive (next day, a few days)?
14. Do edges follow hex cell lines, or run as straight lines between nodes? Can edges cross?
15. Is drawing edges free, or limited (by a budget of edges, edges not being allowed to cross, or a cost)?
16. Can two enchantments share magic nodes, or overlap on the map?

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
| 2026-10-15 | Inspection methods are **visible markings**, **test reactions** (tools or test materials on the inspection board) and **weight**. The item's node map is **not** visible during inspection. |
| 2026-10-15 | Deadlines, price and payment are part of **customer negotiation**. Gavin's idea of a calendar pick, where you negotiate the date on a calendar, is on the table, and bartering is kept simple at first. See §5.6. |
| 2026-10-15 | Customer patience is shown through **reactions** and, for now, a **side bar**. |
| 2026-10-15 | **Books** teach about materials and cultures and act as an inspection reference. |
| 2026-10-15 | In the opening chapter the **uncle negotiates** (using fixed deadlines), while the player inspects commission sheets against the rules and enchants. |
| 2026-10-15 | **No foraging.** Materials and knowledge come through the shop, its visitors and its contacts. |
| 2026-10-15 | Printed matter includes research papers, culture guides, news and adverts (including adverts that unlock new contacts). It comes as **gifts or payment from customers**, from a **bookstore** or from a **book peddler**. |
| 2026-10-15 | **Contacts** can offer unique or cheaper materials, remote commissions for rewards, or visits to the store. |
| 2026-10-15 | Materials come from the **uncle's stock** (restocked early on), then a **catalogue** and **customers selling in the store**. The **uncle's store** is a surcharge fallback for urgent materials. |
| 2026-10-15 | Enchanting uses three ingredients: the **item map** (magic nodes), **fixed-shape enchantments** (enchantment nodes) and **materials**. **No free-form enchanting.** The tier list and geometry-based enchantments are dropped, and difficulty rankings come later. |
| 2026-10-15 | Conditions come from the enchantment node (which materials it accepts), the material (its activation conditions) and constraints the material adds once inserted (such as no adjacent fire). An enchantment activates when all its nodes are active. |
| 2026-10-15 | Condition types will be tested by experiment. For now a node's only condition is which materials it accepts, and node types come later. Materials carry most conditions. Some nodes can **shift** along a short slider. |
| 2026-10-15 | Both magic nodes and enchantment nodes can shift, and shifting is **free**. |
| 2026-10-15 | The item map uses a **hex grid**. Nodes sit in cells, shifting snaps to cells, and enchantments rotate in 60° steps. |
