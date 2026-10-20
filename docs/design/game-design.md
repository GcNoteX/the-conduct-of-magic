# The Conduct of Magic: Game Design Document

> Living document for gameplay and story design. It holds no implementation details.
> Items marked **On hold** are ideas parked for later. Items marked **Proposed** are suggestions that haven't been agreed yet. **Open questions** collect what still needs deciding.

## 1. Pitch

A shop-management, inspection and crafting game about a young enchanter learning the trade as an apprentice in their mentor's workshop. By day you serve customers at the counter: you sell enchanted goods, take commissions and inspect what people bring you. At night you enchant items by laying enchantment patterns onto them and powering those patterns with materials. Who you choose to help, and how well you do the work, decides where your life goes next.

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
        End of day: the mentor settles the books → money · reputation · plot flags
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
| **Silhouette check** | Check that the item is still in its proper shape | Damage that would cut part of its map away |
| **Seal check** | Check whether the item's node arrangement is **already sealed** | If it's sealed, you're stuck with an arrangement you can't see. Accept it and you have to work with that map whatever it turns out to be, or **pay to unseal** it |
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
| **Start** | **The mentor's stock** | Given at the start of the game, and the mentor **restocks it early on** |
| **Later** | **Catalogue** | The player manages stock themselves and orders from a catalogue |
| **Any time** | **Customers in the store** | Chatting with customers, or asking whether they have anything to sell besides their commission. These are random encounters |
| **Any time** | **Contacts** | Unique or cheaper materials (§4.3) |
| **Fallback** | **The mentor's store** | **Expedited materials at a surcharge**, for when you forgot something or run short |

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
| Couldn't deliver (customer lied, or you overreached) | Lost payment, refund, reputation damage, the mentor docks your income |
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
| 1 | **Fixed deadline** | Each commission type has a set turnaround, for example 3 days | Very low | Day 1. It's the mentor's shop rule while you learn |
| 2 | **Customer-set deadline** | The deadline is written on the commission slip, and you take it or leave it | Low | First week. It adds a reason to reject ("I can't make that date") |
| 3 | **Preset options** | The customer offers two or three choices, such as "2 days for 150g or 4 days for 100g" | Low to medium | Late in the mentor's-workshop chapter, once you have overlapping commissions |
| 4 | **Calendar pick** *(Gavin's idea)* | A calendar is laid out on the counter. The customer proposes a date and you drag a marker to counter. Earlier dates pay more and later dates pay less. Each customer has a **patience window**, and pushing past it makes them leave or sour | Medium | When the player runs the counter on their own. The same calendar can double as the commission schedule on the enchanting day |
| 5 | **Pay in materials (simple)** | The customer offers some or all of the payment as materials, and you accept or decline | Low to medium | Early to mid. It's a natural fit because customers already bring materials |
| 6 | **Price haggling** | A back-and-forth offer meter, in the style of Potion Craft | Medium | Mid. Possibly combined with the calendar so you trade time against money |
| 7 | **Full bartering** | Both sides put goods on the counter until the trade balances. Needs an item-valuation system | High | Late, or a special for a later location |
| 8 | **Renegotiation on return** | The customer comes back early or late. They ask for an extension, you ask for one, partial delivery, late penalties | Medium to high | Late, once relationships carry weight |
| 9 | **Relationship and faction modifiers** | Trust and allegiance change patience, discounts and willingness to barter | Medium (a layer over the rest) | Grows alongside the relationship system |

**Patience** is shown in two ways: the customer's **reactions** (expressions, dialogue, body language) and, for now, a **patience bar** at the side. The bar may be removed later so players have to read the customer.

**Proposed path:** start with #1, then #2, then make **#4 (calendar pick)** the first real negotiation mechanic, with #5 alongside it. Hold #7 and #8 for later macro levels. Bartering is only overcomplicated in its full form (#7). The simple accept-or-decline version (#5) is cheap and fits the game.

### 5.7 Items you can give back
Gifts are **not a system of their own**. Sometimes the player gets an item that they can **give to another character**, and it may or may not be something they can inscribe. These are added for **particular storylines and characters**, not as a general gift mechanic.

## 6. Rules you inspect against

What counts as acceptable work comes from several sources, which can conflict:
- **Guilds**: the enchanters' guild (and possibly others) set standards, certifications and banned work.
- **Laws**: the town or city sets what's legal to make, sell or possess.
- **Personal reputation**: what the town expects of your shop.
- **Your allegiances**: the people or groups you choose to support. Helping one faction may break another's rules.

Rules can change over time, the way they do in Papers, Please.

## 7. The enchanting day

**Terminology:** the form enchanting takes is **carving**, or **inscribing**.

When the shop closes, the player moves to enchanting:
1. **Review commissions** to see what's owed, to whom and by when.
2. **Choose an item** you received from a customer or bought yourself.
3. **Enchant it** (see below).

**Time is the main pressure.** The enchanting day has a **fixed amount of time** for all your enchanting, so being slow is already a cost. Mistakes cost time even when they cost nothing else. That amount of time is the player's **stamina** (§9.6).

**For playtesting**, the timer just runs continuously, set to about **an hour** for now.

**Done means the end of the day.** Finished items go into the player's **inventory** along with all their materials. You take things out later to give to customers. Depending on the enchantment, the **customer can evidently tell whether it works**.

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

**Committing and drafts**
- **You can't commit an enchantment that isn't activated**, because you plan the whole puzzle before committing.
- You **can** commit an enchantment, then come back later to add another one.
- **Drafts are saved**, so you can take a break and come back to a plan where you left it. It makes no sense for the enchanter to forget what they planned. Include this now if it's easy, otherwise eventually.

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

**How acceptance works in the current prototype.** An enchantment node sets the **tier** a material must be (that tier or higher) and which **material attributes** it accepts, which together give the range of materials that fit. Materials carry their own **activation conditions**.

**Lines are unlimited.** Players can draw as many lines as they like (they still can't cross).

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

**Decision: hex grid.** Discrete placement makes conditions exact ("adjacent" means a neighbouring cell, and distance is a count of steps). Shifting becomes a snap of one or a few cells. Hexes avoid the square grid's diagonal problem and look more like magic than a circuit board. 
**Edges**
- ~~**Snapping is free** for edges the player drew themselves.~~ Superseded: once committed, a line's cost to cut depends only on the **nodes it's attached to**, not on who drew it (§7.6).
- **No crossing**: edges can't cross each other. This is a rule to try out.
- **Edges you draw don't have to be straight.** They can bend around obstacles.
- **An enchantment's own lines are fixed** and come with it when you drag it on, usually straight.
- **Later (advanced):** variants that let you reshape a specific line inside an enchantment, for example changing the line between A and B to another shape.

**Item maps are handcrafted**
- Each item's map can have its own size and shape. Its **silhouette roughly matches the item** (a sword is long and thin, a ring is round).
- Maps and their magic nodes are **designed by hand**. Fully random generation risks bad maps.
- **Workflow:** a script may generate random candidate maps, and we playtest and keep only the good ones.
- **Grid size** can vary between items.
- **Fixed silhouettes (current decision):** each **item type has one fixed map shape**, with no randomness. This keeps things consistent so players can learn shapes, and they may be able to **preview** an item's shape in the shop.
- **Later, maybe:** worse-quality items get worse silhouettes, for example a map with a **missing part**.

**Node arrangements are the variable part.** An item's map can offer several **magic node arrangements**, and the player picks one and **seals** it.
- **Sealed is permanent by default.** It stays the same if the item comes back, and **unsealing costs** something.
- Arrangements trade capacity against difficulty. For example, on a square map:
  - a **3-node** arrangement with nodes in good spots, or
  - a **4-node** arrangement with more nodes in worse spots, or
  - a **finer grid** (smaller cells for the same map) that fits more enchantments.
- Arrangements with more capacity come with **map terrain** or another kind of added difficulty.

**Map terrain (first version): condition cells.** Some cells add a condition to whatever is placed on them. For example, an enchantment node placed on a fire cell must use a **fire material**. Other kinds of terrain will be worked out later.

**Node size and shape.** By default a node takes up **one hex cell**. Later, nodes could come in **different shapes** that cover several cells.

### 7.5 Macro enchantments (later)
Larger **macro enchantments** could be made of **micro enchantments**:
- either arranged in a specific pattern relative to each other,
- or simply all present somewhere on the same map.



Difficulty comes from combining conditions. A formal ranking of enchantments will be added when it's needed.

### 7.6 Existing enchantments and disenchanting
**Items can arrive already enchanted**, and their enchantments **take up space on the map**.

**No durability for now.** There is no such thing as a mistake, so items have no durability for now. (Earlier idea: removing an enchantment with activated materials damages durability, and **scars** leave removed enchantments' cells as terrain.)

**Decided**
- **Inserted materials are used up.** They can never be taken back out or recycled.
- **Lines are part of planning.** You plan enchantments, materials and lines, then **commit** one or more connected enchantments together.
- **Disenchanting means cutting all of an enchantment's lines, then pulling the enchantment out.** How to make that a game is still open.
  - **The lines to cut are the enchantment's whole chain:** its own lines, its lines to magic nodes, and the magic-to-magic lines in that chain.
  - **Pulled-out cells are free again**, as if the enchantment was never there.
- **Disenchanting also uses planning.** There are **no waiting or quick-time mechanics**, because time is already the limit.
- **Lines must be cut in an order**, and finding that order involves some kind of calculation. It may be solved in **one pass**, working out the correct order as you go (like Minesweeper). The exact system is to be experimented with.

- **Every disenchant board must be solvable**, whatever layout the player made when enchanting. For now this is **checked with a dev tool**; the in-game guarantee waits for real numbers.
- **Disenchanting follows the same plan, then commit to execute** flow as enchanting.
- **Materials can optionally influence disenchanting**, and **some disenchants may require materials**.

**Runes (the disenchanting system to build on)**
- Lines carry **runes**. **Cutting a line consumes runes and gives runes.**
- **Materials can be dissolved** to give you runes.
- You keep cutting, spending runes as needed. **When you are blocked, a material is needed** to get the runes to continue. That is how you solve the board.
- **The material inserted defines the runes** on the lines at its node, and they are visible when viewed. ~~Lines leaving in different directions (top left, bottom right) give different runes.~~ Superseded: **a material puts the same cost on all its edges**.
- ~~**Runes are an inverse representation of the material.**~~ Superseded: **no inverses. A material's runes are its own kind.** A Fire stone puts fire runes on its edges (1 per edge for now) and gives fire runes back when its node is freed. The same goes for every material, to encourage using different materials.
- **An edge's cost is determined by the nodes it's attached to: it costs whatever is connected to it, added together.** This applies to every kind of edge: enchantment node to enchantment node, enchantment node to magic node, and magic node to magic node. **Magic nodes have their own fixed set of runes.**
- **Cutting a line costs the runes it displays** (not their inverse), so it's easy to read. Cutting is not a simple swap of one rune for another.
- **What a cut gives back is deterministic**, not random.
- **Who drew a line doesn't matter.** Your own committed lines follow the same rule as anyone else's, because enchanting and disenchanting don't happen at the same time.
- **Cutting a line costs runes; freed nodes give runes back.**
  - **Magic nodes** give back a deterministic set, fixed by the node arrangement chosen when you pick which map to bind to.
  - **Enchantment nodes** give back whatever is set on the material inside them.
- **So a material defines three things:** its requirements, the rune cost it puts on the edges it touches, and what it returns when its node is freed (harvested).
- **Runes don't carry over** to another session with the item or to another item. They're "hot", live material that disperses if not reused straight away. That is why runes aren't materials themselves.
- **No par** is shown on the board.
- **You start with 0 runes.** Dissolving a material gives you your starting runes, then cutting lines takes and gives runes.
- **4 rune types** for now: **water, fire, wind and stone**.
- What a material gives is **deterministic**. ~~A material could give any number of runes, but **1** for now.~~ Superseded: **each material has its own dissolve result**, 1 or more runes of 1 or more types, and you get all of it.
- **Dissolving is planned too.** Nothing is dissolved until you commit, just as with enchanting.
- ~~**Edge case:** if you plan a disenchant, use that material somewhere else, then come back, the **commit is highlighted red**. You can carry on if you like, or undo until that use of the material is gone.~~ Superseded: **planned materials stay with the item.** Putting a material into a plan, for carving or disenchanting, takes it out of your inventory and holds it in that item. Taking it out of the plan gives it back, so commits never clash across items. A later feature will let you browse your items and see what each plan holds.
- **A node pays out once,** when its last line is cut, so cutting order decides when you get the runes.
- **No order rule** beyond being able to afford a cut.
- **No partial commits:** every enchantment in a plan must be fully cut and pulled out.
- **Prototype:** a **pre-carved demo sword** to practise on, plus a **Disenchant mode** for any item you carved.
- This grew from the idea of symbols and numbers on each line, where cutting a line gives you its set of symbols and the next cut must share at least one of them.

**Direction:** disenchanting may play like **defusing a bomb**.

*Candidate ideas for disenchanting are archived in Appendix A.*

### 7.7 First prototype
- Build the **enchanting part first**: set up a player with materials and demo items for testing. The shop day comes later.
- **Starter content:** about **5 materials** (each with the nodes that accept it, its conditions and its rune pattern), **3 or 4 enchantment shapes** and **one item map**.
- **Enchantments can't share magic nodes** for now. Magic nodes are **1 cell**. Special nodes may come later.
- **Scope of the first build: carving only.** Hex map, dragging enchantments on, drawing lines, inserting materials, activation, commit, inventory and the timer. Disenchanting comes in the second build.
- **No condition cells** in the first build (hard to test, a later feature). **Condition nodes** are fine, such as enchantment nodes that accept only certain materials.
- One demo sword with one fixed node arrangement. Drafts are kept per item during the session. No art pass.

**Magic node to magic node lines.** These happen while enchanting. The magic nodes come from the template you bind to the item, and to activate an enchantment you may need to chain **magic node → magic node → enchantment node** to complete a condition. The game tracks which nodes are connected but **don't chain to an enchantment node**. Those are effectively **dead**, and ~~they're **ignored on commit**~~ (superseded 2026-10-17) a dead chain **blocks the commit** until it's connected or removed.

**Commit needs a clean board.** You can only commit when every planned enchantment is fully active and every drawn line chains to an enchantment. A half-done enchantment or a dead chain blocks the commit until it's finished or taken off.

## 8. Uses of enchanted items

- **Commissions**: deliver them to the customer for payment and to move their story along.
- **Stock**: sell from the shelves.
- **Shop upgrades**: for example, enchanted lights placed in the store for the coming day.
- **Inspection consumables**: tools that reveal more about what customers bring you, such as true material, curses or flaws.

## 9. Story and progression

Characters, setting, chapters and endings are developed in the [story bible](../story/story-bible.md). This section keeps the progression rules.

### 9.1 Premise
The main character has the gift of enchanting. They start out as an apprentice in their **mentor's workshop**. The mentor isn't related to them; earlier drafts called him the uncle.

### 9.2 The mentor
The mentor owns the shop and settles the books at the end of each day. He's the immediate feedback for bad decisions: taking bad commissions means **lower income** that day. This makes consequences felt early without needing a game over.

### 9.2.1 Working the counter with the mentor (tutorial phase)
At first the **mentor runs the business**, and the player is his apprentice.

**Proposed flow:** the customer comes to **you first**.
1. The customer arrives with a **commission sheet** already filled in.
2. You read what they want made and **check it against the rules**. You also inspect any goods they brought.
3. You pass the sheet to the mentor, either approved or flagged with a concern.
4. **The mentor negotiates**, setting a **fixed deadline** (negotiation option #1) and the price, and makes the final call.
5. At night you do the enchanting.

Why you first rather than the mentor first:
- **You stay the checkpoint.** Inspection is the core verb, and it stays in your hands from day 1, as in Papers, Please.
- **Blame is clear.** If you approve a bad commission and the mentor takes it on your word, docking your pay at the end of the day follows naturally.
- **Clean handover.** As you earn trust, the mentor stops doing the negotiation and you take over, starting with customer-set deadlines and then the calendar pick (§5.6). That's progression without a separate tutorial.

### 9.2.2 End of the workshop year
- The game keeps progressing day to day across the year.
- Near the end of the year is **application day** for the university, which costs money. Getting in needs three things: a **total amount of money**, **Mr. Leywin's recommendation** and a **resume** (§9.6).
- **One place decides pass or fail.** It reads the player's state and Mr. Leywin's state and makes the call, separate from the systems that feed it (money, relationships, resume).
- The year has a closing and ends with a **letter** saying whether the player got into the university.
- The patron and the recruiter each give the player a **business-card-like item** that fits who they are.
- The player then chooses from the routes open to them (§9.3).
- **Fail state: no route out of the workshop.** The player can't go to the university (not enough money, no recommendation or too thin a resume) and impressed neither the recruiter nor the patron.
- **Running out of money** also leads to different endings. Death or similar may come later.

### 9.3 Progression routes
After a year-long apprenticeship in the mentor's shop, across four seasons, the player moves on. The game has four location streams: the **shop** (the mentor's workshop, where it starts), then one of three routes. Reputation here means the player's relationship with particular people. If the player qualifies for more than one route, they choose. Story details are in the [story bible](../story/story-bible.md).

| Route | What it is | How you get there |
|---|---|---|
| **University** | The job by its nature. A prestigious school for young adults in many professions; the player's dream goal | Mr. Leywin's recommendation; costs money and a good reputation |
| **Luxury shop** *(temporary name)* | The money side: a fancier workshop that caters to luxuries | A nouveau riche patron's taxing but well-paid tasks |
| **Guild** (Adventurers' Guild) | The practical, people side | A guild recruiter, if the player is generally reputable with townsfolk or adventurers |

The Black Market is archived (A.13).

### 9.4 Macro levels (later)
Each route is a **macro level**: a new place with slightly different mechanics and new kinds of customers. This will be developed later.

### 9.5 Example items
- **Father's Sword**: an example item from the prototype, not a story commitment.

### 9.6 The player's own life
**Rent.** The player lives in a rented apartment and pays rent **each week**. Money comes from an **allowance** from his parents, which arrives by the mailman with their letters, plus his **pay** from Mr. Leywin's books. Missing rent once brings a warning; missing it twice leads to the **running out of money** ending (§9.2.2).

**University side tasks.** A book (from the bookstore, the peddler or the writer) sets a **technical task**, such as making a cup that stays cold. The player gets the materials, attempts it, and finishing it adds a **resume entry**. The resume is one of the three university requirements (§9.2.2).

**Stamina.** Stamina is the night's time budget, and it **replaces a separate night timer**: one budget that commissions and study both draw from.
- Its **upper limit reflects the night**: the cap is limited by the number of night hours before the next day.
- **A day that ends customer work earlier starts the night with more stamina.**
- **For the spike**, stamina is shown as a **yellow progress bar**. The final display is still open (Q15).

**Home projects.** Room builds are folded into practical inscribing (Q14). Personal home projects **upgrade certain things or unlock certain views**. The game stays very much **not stat-focused**.

**Memory aids.** The player keeps a **resume sheet** and a **letters drawer** that holds what people have said. Neither shows scores.

**Pacing.** Pressures come in **a season at a time**: commissions, time and rules first, rent from the second week, and side tasks from the second season.

## 10. Open questions

**Commissions and inspection**
1. Which specific test materials and tools exist, and what reaction does each one show for each material?
2. For the calendar pick: what limits the latest date you can choose (the customer's patience, a hard deadline, or both)?
3. Can you return or refuse an item *after* accepting, for example once you discover it's cursed? What does that cost?

**Rules and factions**
4. Which guilds and factions exist in the mentor's town, and which of them later lead to the university, the luxury shop and the guild?
5. How does the player learn the rules: from the mentor, guild notices or books?

**Story**
6. Is the main character's gift rare or unique, and who knows about it?
7. What is the mentor like? See the [story bible](../story/story-bible.md): a kind, honest mentor, Mr. Leywin (placeholder name), not related to the player.
8. Does the player choose a route, or does the game assign one from their results?
9. The mentor's-workshop chapter lasts one year. How are play days spread across it: spaced-out days, or inscribing jobs that take several days?

**Shop and enchanting**
10. How much does the player control the shop floor? Can they arrange displays and set prices, or only serve at the counter?
11. Is there time pressure during the shop day?
12. When does the mentor stop restocking, and how fast do catalogue orders arrive (next day, a few days)?
13. Disenchanting balance: how do we decide which runes a material puts on the edges it touches, and what it returns when freed?
14. Which practical inscriptions exist for inspections, the shop, the player's own items and home projects, and what does each upgrade or unlock?
15. How is stamina shown so the player can count it easily, and are night hours spent per action or do they run down in real time?

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
| 2026-10-15 | Edges **can't cross** (to be tested). Edges you draw can bend. An enchantment's own lines are fixed, with reshapeable variants as a later advanced mechanic. Map size and shape **vary per item**. |
| 2026-10-15 | Item maps are **handcrafted**, with silhouettes matching the item. Random generation is used only to produce candidates for playtesting. Nodes are 1 cell by default, with multi-cell shapes later. Macro enchantments made of micro enchantments come later. |
| 2026-10-15 | Item types have **variants** in both map shape and node arrangement. Selectable node arrangements (swap freely, or seal one) are to be tested. |
| 2026-10-15 | **Map silhouettes are fixed per item type** (no randomness, previewable in the shop). This replaces shape variants. Players choose and **seal** a magic node arrangement. A sealed arrangement persists, and unsealing costs. Higher-capacity arrangements (more nodes, finer grid) bring terrain or difficulty. |
| 2026-10-15 | Map terrain starts as **condition cells** (for example, a node placed there must use a fire material). Inspection can check the **silhouette** (damage) and whether the item is **already sealed** (accepting means working with an unknown map, or paying to unseal). |
| 2026-10-15 | Items can arrive **already enchanted**, and their enchantments take up map space. The disenchanting mechanic is undecided (ideas in §7.6). |
| 2026-10-15 | The enchanting day has a **fixed time limit**; time is the main pressure. Snapping your own edges is **free**. Items have **durability**, which removing activated enchantments can damage. Disenchanting leans toward **bomb defusal** (§7.6). |
| 2026-10-15 | Enchanting time is in **real seconds**. Inserted materials are **used up** (no recycling). **Lines are drawn during planning**, and you commit one or more connected enchantments together. Disenchanting means **cutting all lines, then pulling the enchantment out**. |
| 2026-10-15 | Disenchanting uses **planning**, with no waiting or quick-time mechanics. Lines are **cut in an order** found by calculation, possibly in one pass like Minesweeper. The exact system is to be experimented with. |
| 2026-10-15 | Six cut-order candidate systems are archived in Appendix A, with the load and capacity model elaborated, including lines that take several cuts. All are to be experimented with; none is decided. |
| 2026-10-15 | **Requirement:** every enchantment's disenchant board must be **solvable** for any player-made layout (§7.6). |
| 2026-10-15 | Disenchanting uses **plan, then commit to execute**. Materials can optionally influence disenchanting, and some disenchants may require materials. The system to build on is **runes**: cutting lines consumes and gives runes, materials can be dissolved for runes, and when you're blocked a material is needed (§7.6). |
| 2026-10-15 | Countdown nodes feel like just counting numbers. The **tension and scaffolding** idea for high-level enchantments is archived for when more difficulty is needed (Appendix A.7). |
| 2026-10-15 | The runes a line gives are **defined by the material inserted** (for example by the direction the line leaves the node), ~~and runes are an **inverse representation of the material**~~ (superseded 2026-10-17: no inverses) (§7.6). |
| 2026-10-15 | **First prototype is the enchanting part**: a player set up with materials and demo items, about 5 materials, 3 or 4 enchantment shapes and one item map. The playtest timer runs continuously, set to about an hour (§7, §7.7). |
| 2026-10-15 | **Done means the end of the day.** Finished items go to the inventory, and customers can evidently tell whether an enchantment works. |
| 2026-10-15 | You **can't commit an unactivated enchantment**, but can commit one and come back to add another. **Drafts are saved** (now if easy, otherwise eventually). |
| 2026-10-15 | Runes: start at **0**, dissolving a material gives starting runes, **4 rune types** for now, ~~a material gives **1 rune** for now~~ (superseded 2026-10-17: each material has its own dissolve result), deterministically. Dissolving happens only on commit. ~~A plan whose material was used elsewhere shows a **red commit** (continue, or undo).~~ (Superseded 2026-10-17: planned materials stay with the item.) **No durability for now**, since there are no mistakes (§7.6). |
| 2026-10-15 | **Enchantments can't share magic nodes** for now, and magic nodes are 1 cell. |
| 2026-10-15 | In the uncle's workshop, the end states are **running out of money** and **not having enough money for the next game stage**, each with different endings (§9.2.2). |
| 2026-10-15 | Players can draw **as many lines as they like**. Node acceptance uses the prototype's **tier and attribute** requirements. A **focus** limit on dangling lines is archived for later (A.8). |
| 2026-10-16 | An edge's runes come from **both ends**: the enchantment node's material and the magic node, which emits a fixed set. **Cutting costs the displayed runes.** Whether returns are deterministic or random is open. |
| 2026-10-16 | Rune returns are **deterministic**. Enchanting takes the form of **carving** (or inscribing). **Partial detachment** and **map-location wear** are archived (A.9, A.10). |
| 2026-10-16 | Who drew a line doesn't matter once committed (free snapping of your own lines is dropped). Cutting costs runes; **freed nodes return runes**: magic nodes a deterministic set fixed by the chosen arrangement, enchantment nodes what their material sets. Runes **don't carry over** between sessions or items. **No par.** Foreign-line effects and rune-pool materials are archived (A.11, A.12). |
| 2026-10-16 | First build is **carving only**, with **no condition cells** (condition nodes are fine). **Magic-to-magic lines** are drawn while enchanting to chain into enchantment nodes. Nodes that don't chain to an enchantment node are **dead** and ignored on commit (§7.7). |
| 2026-10-16 | **An edge costs whatever is connected to it, added together**, for every kind of edge (enchantment–enchantment, enchantment–magic, magic–magic). **A material puts the same cost on all its edges** (replacing direction-based runes). |
| 2026-10-17 | **Commit needs a clean board:** every planned enchantment must be fully active and every line must chain to an enchantment, so a half-done enchantment or a dead chain blocks the commit (§7.7, replacing "dead chains are ignored on commit"). Lines run **cell by cell** and fill their cells, including an enchantment's own lines. |
| 2026-10-17 | Disenchanting: runes are **water, fire, wind and stone** for now. **No inverses:** a material's runes are its own kind (1 per edge for now), replacing "runes are an inverse representation". **Each material has its own dissolve result** (1 or more runes of 1 or more types), replacing "1 for now". **Planned materials stay with the item**, for carving and disenchanting, so commits never clash across items (replacing the red-commit edge case). The lines to cut are the enchantment's **whole chain**. **A node pays out once**, when its last line is cut. **No order rule** beyond affording a cut. **No partial commits.** A **pre-carved demo sword** plus a **Disenchant mode** for any carved item. **Solvability** is checked with a dev tool for now. **Pulled-out cells are free again** (§7.6). |
| 2026-10-17 | **The uncle becomes the mentor** (Mr. Leywin, placeholder). He isn't related to the player. Story details live in the [story bible](../story/story-bible.md). Earlier log entries keep the old name. |
| 2026-10-17 | Location streams are the **shop**, then the **university**, the **luxury shop** (temporary name) or the **guild**. Reputation is the player's relationship with particular people. The player chooses if more than one route is open. The **Black Market** is archived (A.13). |
| 2026-10-18 | The mentor's-workshop chapter is a **one-year apprenticeship** with **four seasons**. How play days spread across the year is still open. Story details are in the [story bible](../story/story-bible.md). |
| 2026-10-18 | **End of the workshop year** (§9.2.2): application day costs money; the university needs money plus Mr. Leywin's recommendation; a closing letter decides the university; the patron and recruiter give business-card-like items; the fail state is no route out of the workshop. |
| 2026-10-20 | **Rent** is paid weekly from the allowance plus pay (§9.6). **University side tasks** from books add **resume entries**, and the resume becomes a **third university requirement**, judged in one place from the player's and Mr. Leywin's state (§9.2.2). Gifts are **not a system**: items to give back are added per storyline (§5.7). Stamina tonics from the potion maker are archived (A.14). |
| 2026-10-20 | **Stamina** is the night's time budget and replaces a separate night timer. Its cap is the night hours before the next day, and ending customer work earlier starts the night with more. **Room builds** fold into practical inscribing as **home projects** that upgrade things or unlock views, not stats. A **resume sheet** and **letters drawer** carry what the player must remember. Pressures are introduced **a season at a time** (§9.6). |
| 2026-10-20 | For the spike, stamina shows as a **yellow progress bar** (§9.6). |

## Appendix A: Idea archive
Ideas kept for reference when we need more. **Nothing here is decided.**

### A.1 Cut-order systems
Candidate systems for the calculated cut order in disenchanting.

| # | System | How it works | Mode |
|---|---|---|---|
| 1 | **Load and capacity** | Lines carry load. Cutting one passes its load onward, and overflow bursts. See A.2 | Planning (all visible) |
| 2 | **Minesweeper numbers** | Each node shows how many of its lines are **trapped**. Cutting a safe line reveals the numbers on nearby nodes, so you deduce the next safe cut. Cutting a trapped line costs durability | One pass |
| 3 | **Countdown nodes** | Each node shows a countdown. Every cut anywhere ticks down every node that still has lines attached, and a node that reaches 0 while attached sparks. It's a deadline schedule. See A.3 | Planning |
| 4 | **Pins** | Some lines are **pinned** by others and can only be cut after the lines pinning them. Pins may be hidden until inspected. The order is a dependency chain. See A.4 | Planning, or one pass if hidden |
| 5 | **Polarity balance** | Lines are **+** or **−**. Every node must stay within ±1 of balanced throughout, so cuts alternate around busy nodes | Planning |
| 6 | **Material release rules** | Each material sets its own rule (for example, "water: cut its lines clockwise", "fire: cut its longest line last"). Books teach the rules | Knowledge-based |

These can combine. For example, #1 with hidden capacities that are revealed as you cut gives a one-pass version of the load system.

### A.2 Load and capacity in detail
**Pieces**
- **Line:** has a **load** (current charge) and a **capacity** (maximum), shown as `load/capacity`, for example `4/6`.
- **Node:** has a **ground capacity**, the most load it can absorb once it has no lines left to pass load to. This could come from the node's material.

**Cutting a line**
1. You choose **which end** to cut nearer to.
2. The cut line's load flows to **that end's node**.
3. If that node still has other lines, the load is **split evenly** among them.
4. If the node has no other lines, the load **grounds** into the node.

**Overflow**
- A line pushed **above its capacity** bursts, which costs durability. *(Possibly its load cascades onward, as a chain reaction.)*
- A node grounding **more than its ground capacity** bursts, which costs durability.

**Goal:** cut every line with **no bursts**, then pull the enchantment out. The total load is conserved, so the puzzle is really **where the load ends up**.

**Worked example**
A star shape. Centre node **Q** has ground capacity 4. Outer nodes **P**, **R** and **S** each have ground capacity 2.

| Line | Between | Load/capacity |
|---|---|---|
| a | Q–P | 4/6 |
| b | Q–R | 2/4 |
| c | Q–S | 2/4 |

- **Bad order:** cut **a** first.
  - Toward P: 4 grounds into P, which only holds 2, so P bursts.
  - Toward Q: b and c each get +2 and become 4/4. Now each one either grounds 4 into an outer node (which only holds 2, so it bursts) or pushes 4 onto the other line (8/4, so it bursts). This is a dead end.
- **Good order:**
  1. Cut **b** toward R: 2 grounds into R, which holds 2. OK.
  2. Cut **c** toward S: 2 grounds into S. OK.
  3. Cut **a** toward Q: Q has no lines left, so 4 grounds into Q, which holds 4. Clean.
- **The lesson:** drain the branches first, then the trunk into the strongest node.

**Lines that take several cuts**
- **Thick lines:** a line needs **N cuts** to sever. Each cut sheds **1/N of its load** toward the end you choose, and the line stays in place with less load. This lets you **drain a heavy line gradually** and interleave it with other cuts.
  - In the example, if **a** were a 2-cut line, the first cut toward P sheds 2 into P (OK), leaving a at 2/6. That opens new orders.
- **Fraying:** each partial cut also lowers the line's **capacity** by 1, so a thick line gets riskier while it's half cut.
- **Re-fusing:** some materials **re-fuse** a cut line if load flows back into its node, so it has to be **cut again**.

**Tuning knobs**
| Knob | Options |
|---|---|
| **Direction** | The player chooses the end (current), or the load always flows toward the enchantment's centre |
| **Split rule** | Split evenly (current), all to the heaviest line, or all to the lightest |
| **Uneven splits** | Design numbers so they always divide evenly, round up (more tension), or let the remainder ground into the node |
| **Ground capacity** | Fixed per node, set by the node's material, or affected by terrain |
| **Burst cost** | Durability only, or durability plus a cascade of the burst load |
| **Visibility** | All numbers shown (planning), or capacities hidden until adjacent cuts reveal them (one pass) |

### A.3 Countdown nodes in detail
**Pieces**
- **Node:** shows a **countdown**, the number of cuts it can sit through while it still has lines attached.
- **Line:** just a connection, with no numbers of its own.

**Rule**
1. Each time you cut **any** line on the board, **every node that still has lines attached ticks down by 1**.
2. A node with no lines left is **freed** and stops counting.
3. A node that hits **0 while it still has lines attached** sparks, which costs durability.

**The puzzle** is a deadline schedule. A node showing 2 must have all its lines gone within the next 2 cuts, so you work through the most urgent nodes first, and a line shared by two urgent nodes is worth two birds with one stone.

**Worked example**
Nodes **A (2)**, **B (3)**, **C (5)**, **D (4)**. Lines: A–B, A–C, B–C, C–D.

- **Good order:**
  1. Cut **A–B**. A, B, C and D all still have lines, so they tick to A 1, B 2, C 4, D 3.
  2. Cut **A–C**. A is now freed (no lines), so it's safe. B 1, C 3, D 2.
  3. Cut **B–C**. B is freed. C 2, D 1.
  4. Cut **C–D**. C and D are freed. Clean.
- **Bad order:**
  1. Cut **C–D** first. D is freed. A 1, B 2, C 4.
  2. Cut **B–C**. A ticks to 0 while A–B and A–C are still attached, so it sparks.

**Variations**
- Countdowns come from the node's **material** (volatile materials have low counts).
- **Hidden countdowns** that are revealed by inspection or as neighbours are freed give a one-pass version.
- Cutting a line **resets** or **adds** to a neighbour's countdown, which gives you a way to buy time.
- **Solvability:** a clean order exists exactly when the nodes can be freed in deadline order. That's cheap to check, and countdowns can be set at weave time to guarantee it.

**Gavin's note:** countdown feels like just counting numbers.

### A.4 Pins in detail
**Pieces**
- **Pin:** where one line **holds down** another, shown as a clasp where they meet at a node.
- A **pinned** line can't be cut cleanly until every line pinning it is cut first. Cutting it early costs durability (or isn't allowed).

**Rule**
- Pins form a **dependency chain**, and any order that cuts pinning lines before the lines they pin works (a topological order).
- **Pins come from the weave order.** When a line is drawn into a node that already has lines, it pins them. Later lines therefore pin earlier ones. This means:
  - Pins can **never form a cycle**, so every board is **solvable by construction**.
  - **Undoing in reverse drawing order** always works, but often there are many other valid orders too.

**Worked example**
Lines drawn in the order **a, b, c, d**.
- **c** was drawn into node N, where **a** already was, so c pins a.
- **d** was drawn into node M, where **b** and **c** already were, so d pins b and c.

Valid orders all start with **d**, then **c** before **a**, and **b** at any point after d. So d, c, a, b works, and so do d, b, c, a and d, c, b, a.

**Where the puzzle comes from**
- **Hidden pins:** on someone else's enchantment, you don't know the weave order. Pins show only once inspected (with a tool or by zooming in), or are revealed as you cut. That gives a one-pass deduction version.
- **Double pins:** a line held by two others needs both cut first.
- **Node locks:** a node is pinned shut and frees all its lines at once once a key line is cut.
- **Combined with load (A.2):** pins limit which orders are allowed, and load decides which of those allowed orders is cheapest.

### A.5 Ways to guarantee solvability
The requirement that every board is solvable is in §7.6. Boards come from player layouts, so the numbers have to come from rules rather than being authored per board.

**Approaches to consider**
| Approach | How it works | Notes |
|---|---|---|
| **A. Always completable** | Mistakes cost durability but never block you. "Solvable" means you can always finish, and skill means **losing less**. The best possible result can be computed to grade the player | Removes dead ends entirely |
| **B. Safe by construction** | Numbers are assigned when the enchantment is **woven**, so that undoing it in **reverse weave order** is always clean. The game records the weave order. For someone else's enchantment, the order has to be deduced from inspection clues | A guaranteed solution exists, and it doubles as a story/inspection hook |
| **C. Solver check at commit** | When an enchantment is committed, the game runs a small solver to confirm a clean cut order exists. If none does, it adjusts (for example, raises a ground capacity) or marks the weave **unstable** (harder or impossible to remove cleanly) | Boards are small (tens of lines), so a search over cut orders is cheap |
| **D. Derive numbers from materials** | Loads, capacities and ground capacities come from the **materials and node types**, never per board. Designers balance materials, and A, B or C guarantee the result | Keeps authoring manageable |

**How each candidate system copes with arbitrary layouts**
| System | Arbitrary layouts | Notes |
|---|---|---|
| 1. Load and capacity | Good with A, B or C | Total ground capacity must be at least the total load |
| 2. Minesweeper numbers | Hard | Guaranteeing a board that never forces a guess is difficult on player-made layouts |
| 3. Countdown nodes | Good | Set counters from each node's number of lines plus slack |
| 4. Pins | Good with B | Pins taken from the weave order can't form a cycle |
| 5. Polarity balance | Risky | Some shapes can't stay balanced |
| 6. Material release rules | Risky | Two materials' rules can conflict |

### A.6 Earlier disenchanting ideas
Earlier suggestions, from before disenchanting became "cut all lines, then pull". Some may be superseded.

**Bomb framing.** An existing enchantment is **live**: its nodes are active and its materials hold their charge.

**Rule idea: never pull from a live node.**
- Taking a material out of an **active** node causes **backlash**, which costs durability.
- To remove a material safely, first make its node **go dark** by **breaking its activation conditions**. For example, cut an edge so it no longer has its 3 connections, or put a fire cell next to a "no adjacent fire" node.
- Once a node is dark, its material lifts out cleanly.
- This makes disenchanting the **reverse of enchanting**: enchanting satisfies conditions, and disenchanting un-satisfies them in a safe order.

**Layer ideas**
| Layer | How it works | Ties into |
|---|---|---|
| **Foreign lines** | Edges you didn't draw (someone else's work) aren't free to snap. They need a tool or cost a little durability | Free snapping applies only to your own lines |
| **Chain reactions** | Some materials have an **on-dark effect**. When their node goes dark, a neighbour flares or takes damage, so order matters, like cutting wires | Cursed and volatile items; harder commissions |
| **The manual** | Books and material guides say which materials are volatile and what they do when disarmed, like the bomb manual in *Keep Talking and Nobody Explodes* | Books and printed matter (§4.2) |
| **Scars** | Disarming badly (with backlash) leaves scar cells, while a clean defuse leaves the map intact | Rewards skill; item history visible at inspection |

The time limit keeps this tense without a separate countdown: careful defusing is safe but slow.

### A.7 Tension and scaffolding (for later)
Gavin's idea, kept for when we need something more difficult. It adds another constraint on top of what exists.

**Enchanting**
- Enchantments, or high-level ones, have **macro stability**. Lines pulled out of them **increase tension in that direction**.
- Think of it as a **truss bridge** with moment forces.
- The rule that **connected nodes are stable** still holds. So the player may need to **draw lines temporarily into empty space**, as scaffolding, to extend their actual line to a node, then remove the earlier line.
- Alternative: instead of a connection making things fully stable, it could just **cut the load by about 50%**.

**Disenchanting (the inverse)**
- Besides runes, there is **load** to consider.
- Lines are cut in **sequences**, and **pins** can be placed to do a kind of **semi-cut**.

### A.8 Focus (for later)
A possible future limit: **focus** is how many **incomplete lines** can be left dangling while the player does something else. It would be another limitation on the player, but not for now.

### A.9 Partial detachment (eventually)
The player may be able to **partially detach** an enchantment, for times when they want to **reroute for space** without wasting all their materials.

### A.10 Map location and wear
If we go the **inscribing** route rather than just enchanting, **where** on the map something sits could matter. For example, carvings **near the edges** of a sword's map may get **chipped** when the sword is used.

### A.11 Foreign line effects
Lines carved by someone else may come with **added effects** when you disenchant them.

### A.12 Rune-pool materials
Maybe some **stable materials** that are just **rune pools**, unlike live runes, which disperse.

### A.13 Black Market
Archived as a route. Something black-market in style could be reached from any route: the things you would do for money, knowledge or reputation.

### A.14 Stamina tonics
Buying extra stamina as tonics from the potion maker. Archived until stamina itself is decided (§9.6).
