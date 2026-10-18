# 31-reward-types · Reward types (Must) · NEW in round 2

**Source:** A4 R2 Run.dc.html → 31 (click cards) + gallery

**Purpose:** Every card the generator can offer: Relic, Gene Vitality, Reroll +1, Level up, Ascension, Chaos Deal, Curse Pact.

**Base:** 1920×1080, canvas_items / expand, uniform scale.

**Data:** reward_generator.gd (titles and desc copied verbatim). Chaos: rarity ≥ 2 relic, party −20% Max HP for the run. Curse: enemies +18% HP and +12% damage, +1 max Reroll.

## Container tree
- Same shell as 07-reward. Card 416 w pad 24 VBox gap 16: [type tag 32 h · rarity] · art 144 · title Rowdies 24 · body OR TradeBox (Gain green-2 + Gamble/Curse red-2).
- Actions: Skip secondary · Take primary L.

## Strings
| Label | Max chars | Width budget | Overflow |
|---|---|---|---|
| Title | 40 | 368 | wrap |
| Body | 178 | 368 | wrap |
| Trade text | 100 | 336 | wrap |

## States
- mixed offer
- each type (gallery)
- chaos / curse picked: inline confirm "This lasts the whole run. Take it?"
- slots full → 32

## Focus and Esc
- Focus: Cards ←→ → Take → Skip.
- Esc: In-run menu.

## Checklist
1 primary · ≤ 2 secondary · ≤ 7 groups · text 16/18/24/32 · Rowdies 700 + Work Sans 400 · text on plates · plates hug content · focus order + Esc stated.

## Flags
- Inline confirm copy is mine.
