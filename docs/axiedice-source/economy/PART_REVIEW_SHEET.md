# PART REVIEW SHEET — 192 part, sinh bởi tools/gen_parts.py

> Bảng duyệt tay cho designer. Mỗi part đã được gán effect qua 36 template
> (design/gdd/part-tier-system.md §2a/§2c), không đọc card text Origins.
> Duyệt: kiểm tra effect có khớp *cảm giác* tên part không (chủ quan, không có
> đúng/sai tuyệt đối) — sửa bằng cách đổi rareChoice trong tools/gen_parts.py
> (ASSIGN_RAW), không sửa file JSON này bằng tay.

**Tổng**: 192 part, 6 class, 36 ô (class×slot).

## PLANT (BULWARK)

| Part | Slot | Rare (chọn) | Common | Rare | Epic | Legendary |
|---|---|---|---|---|---|---|
| Herbivore | mouth | alt (vital) | dmg 5 | dmg 8 +vital | dmg 10 +lifesteal+vital | dmg 15 +lifesteal+vital |
| Serious | mouth | primary (lifesteal) | dmg 5 | dmg 7 +lifesteal | dmg 10 +lifesteal+vital | dmg 15 +lifesteal+vital |
| Silence Whisper | mouth | alt (vital) | dmg 5 | dmg 8 +vital | dmg 10 +lifesteal+vital | dmg 15 +lifesteal+vital |
| Zigzag | mouth | primary (lifesteal) | dmg 5 | dmg 7 +lifesteal | dmg 10 +lifesteal+vital | dmg 15 +lifesteal+vital |
| Bamboo Shoot | horn | primary (pierce) | dmg 6 | dmg 7 +pierce | dmg 11 +pierce+heavy | dmg 16 +pierce+heavy |
| Beech | horn | alt (heavy) | dmg 6 | dmg 9 +heavy | dmg 11 +pierce+heavy | dmg 16 +pierce+heavy |
| Cactus | horn | primary (pierce) | dmg 6 | dmg 7 +pierce | dmg 11 +pierce+heavy | dmg 16 +pierce+heavy |
| Rose Bud | horn | primary (pierce) | dmg 6 | dmg 7 +pierce | dmg 11 +pierce+heavy | dmg 16 +pierce+heavy |
| Strawberry Shortcake | horn | alt (heavy) | dmg 6 | dmg 9 +heavy | dmg 11 +pierce+heavy | dmg 16 +pierce+heavy |
| Watermelon | horn | alt (heavy) | dmg 6 | dmg 9 +heavy | dmg 11 +pierce+heavy | dmg 16 +pierce+heavy |
| Bidens | back | alt (thorns) | shield 9 | shield 8 +thorns | shield 11 +shieldself+thorns | shield 16 +shieldself+thorns |
| Mint | back | primary (shieldself) | shield 9 | shield 8 +shieldself | shield 11 +shieldself+thorns | shield 16 +shieldself+thorns |
| Pumpkin | back | primary (shieldself) | shield 9 | shield 8 +shieldself | shield 11 +shieldself+thorns | shield 16 +shieldself+thorns |
| Shiitake | back | primary (shieldself) | shield 9 | shield 8 +shieldself | shield 11 +shieldself+thorns | shield 16 +shieldself+thorns |
| Turnip | back | alt (thorns) | shield 9 | shield 8 +thorns | shield 11 +shieldself+thorns | shield 16 +shieldself+thorns |
| Watering Can | back | alt (thorns) | shield 9 | shield 8 +thorns | shield 11 +shieldself+thorns | shield 16 +shieldself+thorns |
| Carrot | tail | alt (regen) | shield 6 | shield 8 +regen | shield 11 +shieldself+regen | shield 16 +shieldself+regen |
| Cattail | tail | primary (shieldself) | shield 6 | shield 8 +shieldself | shield 11 +shieldself+regen | shield 16 +shieldself+regen |
| Hatsune | tail | alt (regen) | shield 6 | shield 8 +regen | shield 11 +shieldself+regen | shield 16 +shieldself+regen |
| Hot Butt | tail | primary (shieldself) | shield 6 | shield 8 +shieldself | shield 11 +shieldself+regen | shield 16 +shieldself+regen |
| Potato Leaf | tail | primary (shieldself) | shield 6 | shield 8 +shieldself | shield 11 +shieldself+regen | shield 16 +shieldself+regen |
| Yam | tail | alt (regen) | shield 6 | shield 8 +regen | shield 11 +shieldself+regen | shield 16 +shieldself+regen |
| Blossom | eyes | primary (regen) | heal 7 | heal 9 +regen | heal 13 +regen+cantrip | heal 19 +regen+cantrip |
| Confused | eyes | alt (cantrip) | heal 7 | heal 10 +cantrip | heal 13 +regen+cantrip | heal 19 +regen+cantrip |
| Cucumber Slice | eyes | primary (regen) | heal 7 | heal 9 +regen | heal 13 +regen+cantrip | heal 19 +regen+cantrip |
| Papi | eyes | alt (cantrip) | heal 7 | heal 10 +cantrip | heal 13 +regen+cantrip | heal 19 +regen+cantrip |
| Clover | ears | alt (rerollup) | mana 2 | mana 9 +rerollup | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Hollow | ears | primary (mana) | mana 2 | mana 9 +mana | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Leafy | ears | primary (mana) | mana 2 | mana 9 +mana | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Lotus | ears | alt (rerollup) | mana 2 | mana 9 +rerollup | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Rosa | ears | primary (mana) | mana 2 | mana 9 +mana | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Sakura | ears | alt (rerollup) | mana 2 | mana 9 +rerollup | mana 12 +mana+rerollup | mana 18 +mana+rerollup |

## BEAST (FERAL)

| Part | Slot | Rare (chọn) | Common | Rare | Epic | Legendary |
|---|---|---|---|---|---|---|
| Axie Kiss | mouth | primary (lifesteal) | dmg 7 | dmg 7 +lifesteal | dmg 9 +lifesteal+crit | dmg 14 +lifesteal+crit |
| Confident | mouth | alt (crit) | dmg 7 | dmg 7 +crit | dmg 9 +lifesteal+crit | dmg 14 +lifesteal+crit |
| Goda | mouth | alt (crit) | dmg 7 | dmg 7 +crit | dmg 9 +lifesteal+crit | dmg 14 +lifesteal+crit |
| Nut Cracker | mouth | primary (lifesteal) | dmg 7 | dmg 7 +lifesteal | dmg 9 +lifesteal+crit | dmg 14 +lifesteal+crit |
| Arco | horn | alt (pierce) | dmg 9 | dmg 7 +pierce | dmg 11 +heavy+pierce | dmg 16 +heavy+pierce |
| Dual Blade | horn | alt (pierce) | dmg 9 | dmg 7 +pierce | dmg 11 +heavy+pierce | dmg 16 +heavy+pierce |
| Imp | horn | primary (heavy) | dmg 9 | dmg 9 +heavy | dmg 11 +heavy+pierce | dmg 16 +heavy+pierce |
| Little Branch | horn | primary (heavy) | dmg 9 | dmg 9 +heavy | dmg 11 +heavy+pierce | dmg 16 +heavy+pierce |
| Merry | horn | primary (heavy) | dmg 9 | dmg 9 +heavy | dmg 11 +heavy+pierce | dmg 16 +heavy+pierce |
| Pocky | horn | alt (pierce) | dmg 9 | dmg 7 +pierce | dmg 11 +heavy+pierce | dmg 16 +heavy+pierce |
| Furball | back | primary (thorns) | dmg 6 | dmg 7 +thorns | dmg 9 +thorns+vulnerable | dmg 14 +thorns+vulnerable |
| Hero | back | alt (vulnerable) | dmg 6 | dmg 7 +vulnerable | dmg 9 +thorns+vulnerable | dmg 14 +thorns+vulnerable |
| Jaguar | back | alt (vulnerable) | dmg 6 | dmg 7 +vulnerable | dmg 9 +thorns+vulnerable | dmg 14 +thorns+vulnerable |
| Risky Beast | back | alt (vulnerable) | dmg 6 | dmg 7 +vulnerable | dmg 9 +thorns+vulnerable | dmg 14 +thorns+vulnerable |
| Ronin | back | primary (thorns) | dmg 6 | dmg 7 +thorns | dmg 9 +thorns+vulnerable | dmg 14 +thorns+vulnerable |
| Timber | back | primary (thorns) | dmg 6 | dmg 7 +thorns | dmg 9 +thorns+vulnerable | dmg 14 +thorns+vulnerable |
| Cottontail | tail | primary (multi) | dmg 6 | dmg 6 +multi | dmg 8 +multi+chain | dmg 13 +multi+chain |
| Gerbil | tail | alt (chain) | dmg 6 | dmg 7 +chain | dmg 8 +multi+chain | dmg 13 +multi+chain |
| Hare | tail | primary (multi) | dmg 6 | dmg 6 +multi | dmg 8 +multi+chain | dmg 13 +multi+chain |
| Nut Cracker | tail | primary (multi) | dmg 6 | dmg 6 +multi | dmg 8 +multi+chain | dmg 13 +multi+chain |
| Rice | tail | alt (chain) | dmg 6 | dmg 7 +chain | dmg 8 +multi+chain | dmg 13 +multi+chain |
| Shiba | tail | alt (chain) | dmg 6 | dmg 7 +chain | dmg 8 +multi+chain | dmg 13 +multi+chain |
| Chubby | eyes | alt (vulnerable) | dmg 5 | dmg 7 +vulnerable | dmg 10 +regen+vulnerable | dmg 15 +regen+vulnerable |
| Little Peas | eyes | alt (vulnerable) | dmg 5 | dmg 7 +vulnerable | dmg 10 +regen+vulnerable | dmg 15 +regen+vulnerable |
| Puppy | eyes | primary (regen) | dmg 5 | dmg 7 +regen | dmg 10 +regen+vulnerable | dmg 15 +regen+vulnerable |
| Zeal | eyes | primary (regen) | dmg 5 | dmg 7 +regen | dmg 10 +regen+vulnerable | dmg 15 +regen+vulnerable |
| Belieber | ears | alt (mana) | mana 2 | mana 9 +mana | mana 12 +rerollup+mana | mana 18 +rerollup+mana |
| Innocent Lamb | ears | alt (mana) | mana 2 | mana 9 +mana | mana 12 +rerollup+mana | mana 18 +rerollup+mana |
| Nut Cracker | ears | alt (mana) | mana 2 | mana 9 +mana | mana 12 +rerollup+mana | mana 18 +rerollup+mana |
| Nyan | ears | primary (rerollup) | mana 2 | mana 9 +rerollup | mana 12 +rerollup+mana | mana 18 +rerollup+mana |
| Puppy | ears | primary (rerollup) | mana 2 | mana 9 +rerollup | mana 12 +rerollup+mana | mana 18 +rerollup+mana |
| Zen | ears | primary (rerollup) | mana 2 | mana 9 +rerollup | mana 12 +rerollup+mana | mana 18 +rerollup+mana |

## AQUA (CONDUIT)

| Part | Slot | Rare (chọn) | Common | Rare | Epic | Legendary |
|---|---|---|---|---|---|---|
| Catfish | mouth | alt (lifesteal) | dmg 6 | dmg 7 +lifesteal | dmg 10 +mana+lifesteal | dmg 15 +mana+lifesteal |
| Lam | mouth | primary (mana) | dmg 6 | dmg 8 +mana | dmg 10 +mana+lifesteal | dmg 15 +mana+lifesteal |
| Piranha | mouth | alt (lifesteal) | dmg 6 | dmg 7 +lifesteal | dmg 10 +mana+lifesteal | dmg 15 +mana+lifesteal |
| Risky Fish | mouth | primary (mana) | dmg 6 | dmg 8 +mana | dmg 10 +mana+lifesteal | dmg 15 +mana+lifesteal |
| Anemone | horn | alt (crit) | dmg 7 | dmg 7 +crit | dmg 8 +pierce+crit | dmg 14 +pierce+crit |
| Babylonia | horn | primary (pierce) | dmg 7 | dmg 7 +pierce | dmg 8 +pierce+crit | dmg 14 +pierce+crit |
| Clamshell | horn | primary (pierce) | dmg 7 | dmg 7 +pierce | dmg 8 +pierce+crit | dmg 14 +pierce+crit |
| Oranda | horn | primary (pierce) | dmg 7 | dmg 7 +pierce | dmg 8 +pierce+crit | dmg 14 +pierce+crit |
| Shoal Star | horn | alt (crit) | dmg 7 | dmg 7 +crit | dmg 8 +pierce+crit | dmg 14 +pierce+crit |
| Teal Shell | horn | alt (crit) | dmg 7 | dmg 7 +crit | dmg 8 +pierce+crit | dmg 14 +pierce+crit |
| Anemone | back | primary (shieldself) | shield 6 | shield 8 +shieldself | shield 11 +shieldself+mana | shield 16 +shieldself+mana |
| Blue Moon | back | alt (mana) | shield 6 | shield 8 +mana | shield 11 +shieldself+mana | shield 16 +shieldself+mana |
| Goldfish | back | alt (mana) | shield 6 | shield 8 +mana | shield 11 +shieldself+mana | shield 16 +shieldself+mana |
| Hermit | back | primary (shieldself) | shield 6 | shield 8 +shieldself | shield 11 +shieldself+mana | shield 16 +shieldself+mana |
| Perch | back | alt (mana) | shield 6 | shield 8 +mana | shield 11 +shieldself+mana | shield 16 +shieldself+mana |
| Sponge | back | primary (shieldself) | shield 6 | shield 8 +shieldself | shield 11 +shieldself+mana | shield 16 +shieldself+mana |
| Koi | tail | primary (chain) | dmg 5 | dmg 7 +chain | dmg 8 +chain+multi | dmg 13 +chain+multi |
| Navaga | tail | alt (multi) | dmg 5 | dmg 6 +multi | dmg 8 +chain+multi | dmg 13 +chain+multi |
| Nimo | tail | primary (chain) | dmg 5 | dmg 7 +chain | dmg 8 +chain+multi | dmg 13 +chain+multi |
| Ranchu | tail | primary (chain) | dmg 5 | dmg 7 +chain | dmg 8 +chain+multi | dmg 13 +chain+multi |
| Shrimp | tail | alt (multi) | dmg 5 | dmg 6 +multi | dmg 8 +chain+multi | dmg 13 +chain+multi |
| Tadpole | tail | alt (multi) | dmg 5 | dmg 6 +multi | dmg 8 +chain+multi | dmg 13 +chain+multi |
| Clear | eyes | primary (regen) | heal 7 | heal 9 +regen | heal 13 +regen+cantrip | heal 19 +regen+cantrip |
| Gero | eyes | alt (cantrip) | heal 7 | heal 10 +cantrip | heal 13 +regen+cantrip | heal 19 +regen+cantrip |
| Sleepless | eyes | primary (regen) | heal 7 | heal 9 +regen | heal 13 +regen+cantrip | heal 19 +regen+cantrip |
| Telescope | eyes | alt (cantrip) | heal 7 | heal 10 +cantrip | heal 13 +regen+cantrip | heal 19 +regen+cantrip |
| Bubblemaker | ears | primary (mana) | mana 3 | mana 9 +mana | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Gill | ears | primary (mana) | mana 3 | mana 9 +mana | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Inkling | ears | alt (rerollup) | mana 3 | mana 9 +rerollup | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Nimo | ears | primary (mana) | mana 3 | mana 9 +mana | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Seaslug | ears | alt (rerollup) | mana 3 | mana 9 +rerollup | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Tiny Fan | ears | alt (rerollup) | mana 3 | mana 9 +rerollup | mana 12 +mana+rerollup | mana 18 +mana+rerollup |

## REPTILE (SCALES)

| Part | Slot | Rare (chọn) | Common | Rare | Epic | Legendary |
|---|---|---|---|---|---|---|
| Kotaro | mouth | alt (poison) | dmg 6 | dmg 7 +poison | dmg 9 +lifesteal+poison | dmg 14 +lifesteal+poison |
| Razor Bite | mouth | primary (lifesteal) | dmg 6 | dmg 7 +lifesteal | dmg 9 +lifesteal+poison | dmg 14 +lifesteal+poison |
| Tiny Turtle | mouth | alt (poison) | dmg 6 | dmg 7 +poison | dmg 9 +lifesteal+poison | dmg 14 +lifesteal+poison |
| Toothless Bite | mouth | primary (lifesteal) | dmg 6 | dmg 7 +lifesteal | dmg 9 +lifesteal+poison | dmg 14 +lifesteal+poison |
| Bumpy | horn | alt (heavy) | dmg 7 | dmg 9 +heavy | dmg 11 +pierce+heavy | dmg 16 +pierce+heavy |
| Cerastes | horn | primary (pierce) | dmg 7 | dmg 7 +pierce | dmg 11 +pierce+heavy | dmg 16 +pierce+heavy |
| Incisor | horn | primary (pierce) | dmg 7 | dmg 7 +pierce | dmg 11 +pierce+heavy | dmg 16 +pierce+heavy |
| Scaly Spear | horn | primary (pierce) | dmg 7 | dmg 7 +pierce | dmg 11 +pierce+heavy | dmg 16 +pierce+heavy |
| Scaly Spoon | horn | alt (heavy) | dmg 7 | dmg 9 +heavy | dmg 11 +pierce+heavy | dmg 16 +pierce+heavy |
| Unko | horn | alt (heavy) | dmg 7 | dmg 9 +heavy | dmg 11 +pierce+heavy | dmg 16 +pierce+heavy |
| Bone Sail | back | alt (shieldself) | shield 8 | shield 8 +shieldself | shield 11 +thorns+shieldself | shield 16 +thorns+shieldself |
| Croc | back | alt (shieldself) | shield 8 | shield 8 +shieldself | shield 11 +thorns+shieldself | shield 16 +thorns+shieldself |
| Green Thorns | back | primary (thorns) | shield 8 | shield 8 +thorns | shield 11 +thorns+shieldself | shield 16 +thorns+shieldself |
| Indian Star | back | primary (thorns) | shield 8 | shield 8 +thorns | shield 11 +thorns+shieldself | shield 16 +thorns+shieldself |
| Red Ear | back | alt (shieldself) | shield 8 | shield 8 +shieldself | shield 11 +thorns+shieldself | shield 16 +thorns+shieldself |
| Tri Spikes | back | primary (thorns) | shield 8 | shield 8 +thorns | shield 11 +thorns+shieldself | shield 16 +thorns+shieldself |
| Gila | tail | primary (poison) | poison 4 | poison 8 +poison | poison 10 +poison+aoe | poison 16 +poison+aoe |
| Grass Snake | tail | primary (poison) | poison 4 | poison 8 +poison | poison 10 +poison+aoe | poison 16 +poison+aoe |
| Iguana | tail | alt (aoe) | poison 4 | poison 7 +aoe | poison 10 +poison+aoe | poison 16 +poison+aoe |
| Snake Jar | tail | alt (aoe) | poison 4 | poison 7 +aoe | poison 10 +poison+aoe | poison 16 +poison+aoe |
| Tiny Dino | tail | primary (poison) | poison 4 | poison 8 +poison | poison 10 +poison+aoe | poison 16 +poison+aoe |
| Wall Gecko | tail | alt (aoe) | poison 4 | poison 7 +aoe | poison 10 +poison+aoe | poison 16 +poison+aoe |
| Gecko | eyes | primary (regen) | heal 5 | heal 9 +regen | heal 12 +regen+weaken | heal 18 +regen+weaken |
| Scar | eyes | alt (weaken) | heal 5 | heal 9 +weaken | heal 12 +regen+weaken | heal 18 +regen+weaken |
| Topaz | eyes | alt (weaken) | heal 5 | heal 9 +weaken | heal 12 +regen+weaken | heal 18 +regen+weaken |
| Tricky | eyes | primary (regen) | heal 5 | heal 9 +regen | heal 12 +regen+weaken | heal 18 +regen+weaken |
| Curved Spine | ears | alt (rerollup) | mana 2 | mana 9 +rerollup | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Friezard | ears | primary (mana) | mana 2 | mana 9 +mana | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Pogona | ears | alt (rerollup) | mana 2 | mana 9 +rerollup | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Sidebarb | ears | primary (mana) | mana 2 | mana 9 +mana | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Small Frill | ears | primary (mana) | mana 2 | mana 9 +mana | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Swirl | ears | alt (rerollup) | mana 2 | mana 9 +rerollup | mana 12 +mana+rerollup | mana 18 +mana+rerollup |

## BUG (VIRULENT)

| Part | Slot | Rare (chọn) | Common | Rare | Epic | Legendary |
|---|---|---|---|---|---|---|
| Cute Bunny | mouth | alt (lifesteal) | dmg 5 | dmg 7 +lifesteal | dmg 9 +poison+lifesteal | dmg 14 +poison+lifesteal |
| Mosquito | mouth | alt (lifesteal) | dmg 5 | dmg 7 +lifesteal | dmg 9 +poison+lifesteal | dmg 14 +poison+lifesteal |
| Pincer | mouth | primary (poison) | dmg 5 | dmg 7 +poison | dmg 9 +poison+lifesteal | dmg 14 +poison+lifesteal |
| Square Teeth | mouth | primary (poison) | dmg 5 | dmg 7 +poison | dmg 9 +poison+lifesteal | dmg 14 +poison+lifesteal |
| Antenna | horn | alt (pierce) | dmg 6 | dmg 7 +pierce | dmg 9 +weaken+pierce | dmg 14 +weaken+pierce |
| Caterpillars | horn | primary (weaken) | dmg 6 | dmg 7 +weaken | dmg 9 +weaken+pierce | dmg 14 +weaken+pierce |
| Lagging | horn | primary (weaken) | dmg 6 | dmg 7 +weaken | dmg 9 +weaken+pierce | dmg 14 +weaken+pierce |
| Leaf Bug | horn | alt (pierce) | dmg 6 | dmg 7 +pierce | dmg 9 +weaken+pierce | dmg 14 +weaken+pierce |
| Parasite | horn | primary (weaken) | dmg 6 | dmg 7 +weaken | dmg 9 +weaken+pierce | dmg 14 +weaken+pierce |
| Pliers | horn | alt (pierce) | dmg 6 | dmg 7 +pierce | dmg 9 +weaken+pierce | dmg 14 +weaken+pierce |
| Buzz Buzz | back | primary (poison) | shield 6 | shield 8 +poison | shield 10 +poison+shieldself | shield 16 +poison+shieldself |
| Garish Worm | back | primary (poison) | shield 6 | shield 8 +poison | shield 10 +poison+shieldself | shield 16 +poison+shieldself |
| Sandal | back | alt (shieldself) | shield 6 | shield 8 +shieldself | shield 10 +poison+shieldself | shield 16 +poison+shieldself |
| Scarab | back | alt (shieldself) | shield 6 | shield 8 +shieldself | shield 10 +poison+shieldself | shield 16 +poison+shieldself |
| Snail Shell | back | alt (shieldself) | shield 6 | shield 8 +shieldself | shield 10 +poison+shieldself | shield 16 +poison+shieldself |
| Spiky Wing | back | primary (poison) | shield 6 | shield 8 +poison | shield 10 +poison+shieldself | shield 16 +poison+shieldself |
| Ant | tail | alt (aoe) | poison 5 | poison 7 +aoe | poison 10 +poison+aoe | poison 16 +poison+aoe |
| Fish Snack | tail | primary (poison) | poison 5 | poison 8 +poison | poison 10 +poison+aoe | poison 16 +poison+aoe |
| Gravel Ant | tail | alt (aoe) | poison 5 | poison 7 +aoe | poison 10 +poison+aoe | poison 16 +poison+aoe |
| Pupae | tail | primary (poison) | poison 5 | poison 8 +poison | poison 10 +poison+aoe | poison 16 +poison+aoe |
| Thorny Caterpillar | tail | primary (poison) | poison 5 | poison 8 +poison | poison 10 +poison+aoe | poison 16 +poison+aoe |
| Twin Tail | tail | alt (aoe) | poison 5 | poison 7 +aoe | poison 10 +poison+aoe | poison 16 +poison+aoe |
| Bookworm | eyes | alt (blind) | poison 3 | poison 8 +blind | poison 11 +poison+blind | poison 17 +poison+blind |
| Kotaro? | eyes | primary (poison) | poison 3 | poison 8 +poison | poison 11 +poison+blind | poison 17 +poison+blind |
| Neo | eyes | primary (poison) | poison 3 | poison 8 +poison | poison 11 +poison+blind | poison 17 +poison+blind |
| Nerdy | eyes | alt (blind) | poison 3 | poison 8 +blind | poison 11 +poison+blind | poison 17 +poison+blind |
| Beetle Spike | ears | primary (mana) | mana 2 | mana 9 +mana | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Ear Breathing | ears | alt (rerollup) | mana 2 | mana 9 +rerollup | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Earwing | ears | alt (rerollup) | mana 2 | mana 9 +rerollup | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Larva | ears | primary (mana) | mana 2 | mana 9 +mana | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Leaf Bug | ears | primary (mana) | mana 2 | mana 9 +mana | mana 12 +mana+rerollup | mana 18 +mana+rerollup |
| Tassels | ears | alt (rerollup) | mana 2 | mana 9 +rerollup | mana 12 +mana+rerollup | mana 18 +mana+rerollup |

## BIRD (TALON)

| Part | Slot | Rare (chọn) | Common | Rare | Epic | Legendary |
|---|---|---|---|---|---|---|
| Doubletalk | mouth | alt (lifesteal) | dmg 6 | dmg 7 +lifesteal | dmg 9 +pierce+lifesteal | dmg 14 +pierce+lifesteal |
| Hungry Bird | mouth | alt (lifesteal) | dmg 6 | dmg 7 +lifesteal | dmg 9 +pierce+lifesteal | dmg 14 +pierce+lifesteal |
| Little Owl | mouth | primary (pierce) | dmg 6 | dmg 7 +pierce | dmg 9 +pierce+lifesteal | dmg 14 +pierce+lifesteal |
| Peace Maker | mouth | primary (pierce) | dmg 6 | dmg 7 +pierce | dmg 9 +pierce+lifesteal | dmg 14 +pierce+lifesteal |
| Cuckoo | horn | alt (crit) | dmg 7 | dmg 7 +crit | dmg 8 +pierce+crit | dmg 14 +pierce+crit |
| Eggshell | horn | primary (pierce) | dmg 7 | dmg 7 +pierce | dmg 8 +pierce+crit | dmg 14 +pierce+crit |
| Feather Spear | horn | primary (pierce) | dmg 7 | dmg 7 +pierce | dmg 8 +pierce+crit | dmg 14 +pierce+crit |
| Kestrel | horn | alt (crit) | dmg 7 | dmg 7 +crit | dmg 8 +pierce+crit | dmg 14 +pierce+crit |
| Trump | horn | alt (crit) | dmg 7 | dmg 7 +crit | dmg 8 +pierce+crit | dmg 14 +pierce+crit |
| Wing Horn | horn | primary (pierce) | dmg 7 | dmg 7 +pierce | dmg 8 +pierce+crit | dmg 14 +pierce+crit |
| Balloon | back | primary (vulnerable) | dmg 5 | dmg 7 +vulnerable | dmg 9 +vulnerable+blind | dmg 14 +vulnerable+blind |
| Cupid | back | primary (vulnerable) | dmg 5 | dmg 7 +vulnerable | dmg 9 +vulnerable+blind | dmg 14 +vulnerable+blind |
| Kingfisher | back | primary (vulnerable) | dmg 5 | dmg 7 +vulnerable | dmg 9 +vulnerable+blind | dmg 14 +vulnerable+blind |
| Pigeon Post | back | alt (blind) | dmg 5 | dmg 7 +blind | dmg 9 +vulnerable+blind | dmg 14 +vulnerable+blind |
| Raven | back | alt (blind) | dmg 5 | dmg 7 +blind | dmg 9 +vulnerable+blind | dmg 14 +vulnerable+blind |
| Tri Feather | back | alt (blind) | dmg 5 | dmg 7 +blind | dmg 9 +vulnerable+blind | dmg 14 +vulnerable+blind |
| Cloud | tail | primary (chain) | dmg 5 | dmg 7 +chain | dmg 8 +chain+multi | dmg 13 +chain+multi |
| Feather Fan | tail | alt (multi) | dmg 5 | dmg 6 +multi | dmg 8 +chain+multi | dmg 13 +chain+multi |
| Granma's Fan | tail | primary (chain) | dmg 5 | dmg 7 +chain | dmg 8 +chain+multi | dmg 13 +chain+multi |
| Post Fight | tail | alt (multi) | dmg 5 | dmg 6 +multi | dmg 8 +chain+multi | dmg 13 +chain+multi |
| Swallow | tail | alt (multi) | dmg 5 | dmg 6 +multi | dmg 8 +chain+multi | dmg 13 +chain+multi |
| The Last One | tail | primary (chain) | dmg 5 | dmg 7 +chain | dmg 8 +chain+multi | dmg 13 +chain+multi |
| Little Owl | eyes | primary (blind) | dmg 5 | dmg 7 +blind | dmg 9 +blind+vulnerable | dmg 14 +blind+vulnerable |
| Lucas | eyes | alt (vulnerable) | dmg 5 | dmg 7 +vulnerable | dmg 9 +blind+vulnerable | dmg 14 +blind+vulnerable |
| Mavis | eyes | primary (blind) | dmg 5 | dmg 7 +blind | dmg 9 +blind+vulnerable | dmg 14 +blind+vulnerable |
| Robin | eyes | alt (vulnerable) | dmg 5 | dmg 7 +vulnerable | dmg 9 +blind+vulnerable | dmg 14 +blind+vulnerable |
| Curly | ears | primary (rerollup) | mana 2 | mana 9 +rerollup | mana 12 +rerollup+mana | mana 18 +rerollup+mana |
| Early Bird | ears | primary (rerollup) | mana 2 | mana 9 +rerollup | mana 12 +rerollup+mana | mana 18 +rerollup+mana |
| Owl | ears | alt (mana) | mana 2 | mana 9 +mana | mana 12 +rerollup+mana | mana 18 +rerollup+mana |
| Peace Maker | ears | alt (mana) | mana 2 | mana 9 +mana | mana 12 +rerollup+mana | mana 18 +rerollup+mana |
| Pink Cheek | ears | primary (rerollup) | mana 2 | mana 9 +rerollup | mana 12 +rerollup+mana | mana 18 +rerollup+mana |
| Risky Bird | ears | alt (mana) | mana 2 | mana 9 +mana | mana 12 +rerollup+mana | mana 18 +rerollup+mana |

## Mythic (36 ô, phá luật — xem part-tier-system.md §2c)

| Class | Slot | Rule-break |
|---|---|---|
| plant | mouth | Overheal từ Lifesteal chuyển thành max-HP vĩnh viễn thay vì mất |
| plant | horn | Damage Pierce của mặt này cũng tạo Shield bằng đúng số damage |
| plant | back | Shield mặt này không decay đầu lượt, tồn tại tới khi bị tiêu |
| plant | tail | Mỗi 10 Shield tích luỹ cũng hồi 1 HP, không chỉ cho Thorns |
| plant | eyes | Heal vào mục tiêu đã đầy máu chuyển thành Shield thay vì mất |
| plant | ears | Mana từ mặt này cũng tạo Shield bằng đúng giá trị mana |
| beast | mouth | Lifesteal hồi máu cả trên phần damage bonus +60% của FERAL |
| beast | horn | Mặt này luôn được bonus FERAL +60%, bất kể HP% mục tiêu |
| beast | back | Thorns phản đòn của mặt này scale theo % HP mất của địch |
| beast | tail | Mỗi đòn trong multi-strike kiểm tra lại ngưỡng FERAL theo HP hiện tại giữa chuỗi đòn |
| beast | eyes | Hồi máu cho bản thân bằng damage gây cho mục tiêu <50% HP, không giới hạn theo HP thiếu của chính mình |
| beast | ears | Reroll charge từ mặt này không tính vào cap nâng cấp Max Reroll (3) |
| aquatic | mouth | Mana mặt này kích hoạt quy đổi reroll của CONDUIT ngay, không cần gom đủ bội số 4 |
| aquatic | horn | Damage Pierce của mặt này cũng tạo Mana bằng đúng số damage |
| aquatic | back | Shield mặt này cũng tạo Mana bằng đúng giá trị shield |
| aquatic | tail | Chain của mặt này không bao giờ trúng lại mục tiêu đã trúng khi còn địch chưa bị chọn |
| aquatic | eyes | Chuỗi cantrip của mặt này không giới hạn 6 lần lặp như bình thường |
| aquatic | ears | Overheal từ mặt Eyes đồng minh trong lượt được quy đổi thành Mana bonus trên mặt này |
| reptile | mouth | Lifesteal mặt này cũng hồi máu theo damage Poison-tick đã gây trong lượt |
| reptile | horn | Damage Pierce mặt này áp Poison-qua-Thorns ngay, không cần địch tấn công trước |
| reptile | back | Thorns mặt này không có trần stack và không reset đầu lượt |
| reptile | tail | Poison mặt này không giảm 1 stack mỗi lượt như bình thường (khớp rule-break plague) |
| reptile | eyes | Regen tick mặt này cũng cộng Thorns bằng đúng lượng hồi |
| reptile | ears | Mana mặt này cũng cho 1 stack Thorns tồn tại sang trận sau (không reset cuối wave) |
| bug | mouth | Lifesteal mặt này đọc cả damage Poison-tick vừa áp trong lượt |
| bug | horn | Weaken mặt này stack nhân thay vì cộng như bình thường |
| bug | back | Shield mặt này gây Poison cho địch phá giáp dù không có keyword Thorns |
| bug | tail | Bonus +2-stack của VIRULENT áp dụng 2 lần trên chính mặt này |
| bug | eyes | Poison mặt này không giảm stack mỗi lượt, chỉ khi VIRULENT đang active trong trận (khớp rule-break plague) |
| bug | ears | Mana mặt này áp Poison 1 lên một địch ngẫu nhiên theo mỗi điểm mana |
| bird | mouth | Luật "mặt aoe cũng có Pierce" của TALON áp cho cả mặt này dù không gắn aoe |
| bird | horn | Pierce mặt này bỏ qua hoàn toàn phản đòn Thorns của địch |
| bird | back | Mặt này tạo Shield — phá luật "Bird không bao giờ có mặt shield" ở mọi bậc khác |
| bird | tail | Đòn Chain của mặt này tính là Pierce cho bonus TALON, dù Chain thường không mang Pierce |
| bird | eyes | Mặt này tạo Heal — phá luật "Bird không bao giờ có mặt heal" ở mọi bậc khác |
| bird | ears | Bonus TALON áp cho mỗi lần kích hoạt cantrip-chain của mặt này, không chỉ lần đầu |