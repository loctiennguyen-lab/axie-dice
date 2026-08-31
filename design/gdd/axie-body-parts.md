# Axie Infinity — Body Part Database (nguồn chính thức, cập nhật 2026-09-01)

> **Nguồn**: file "Part name.xlsx" do product owner cung cấp (đã có quyền dùng tên/art từ Sky Mavis).
> Dữ liệu thô đầy đủ: docs/axiedice-source/economy/parts_full_source.json (588 dòng).
> **Thay thế hoàn toàn** bản cũ (nguồn community mirror agp-npm, chỉ có 192/273 part) — bản cũ thiếu ~93 part thật.

## Cấu trúc dữ liệu: 3 tầng theo cột "stage"

| stage | Ý nghĩa | Số lượng | Vai trò trong game (2026-09-01) |
|---|---|---|---|
| **1** | Part thường (base) — catalog **đầy đủ** | 285 (6 class × ~41-52) | Gắn với NFT thật — chỉ dùng được nếu sở hữu Axie NFT mang part đó (economy-progression.md §10.2b) |
| **2** | Part thường, dạng tên có hậu tố **"+"** (bản tiến hoá/max-stage) | 192 (32/class đều nhau) | Tập con của stage 1 (cùng part, tên hiển thị khi Axie ở stage cao — KHÔNG phải part khác). Bỏ hậu tố "+" khi map vào game — dùng chung 1 identity với bản stage 1 tương ứng |
| **0** | Part **Origin** (hậu tố "**α**") — hiếm nhất | 111 (6 class + phần class gốc) | Pool DUY NHẤT free player mua được bằng Gene Shard (economy-progression.md §10.2b) |

**dawn / dusk / mech** (36 part, secret class lai 2 class gốc — economy-progression.md D15): chỉ có stage 0 (α) và stage 1, KHÔNG có stage 2 — mỗi secret class chỉ 3-7 part (không đủ 6 slot × N), khớp đúng D15 "rút 3/6 slot từ mỗi bloodline gốc", dùng lại part đã có ở 6 class chính, không phải part hoàn toàn mới.

## BEAST

### BEAST — Mouth

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Axie Kiss |  | ✓ | ✓ |
| Confident |  | ✓ | ✓ |
| Cub | ✓ | ✓ |  |
| Foxy | ✓ | ✓ |  |
| Goda |  | ✓ | ✓ |
| Nut Cracker | ✓ | ✓ | ✓ |
| Platypus | ✓ | ✓ |  |
| Puff | ✓ | ✓ |  |
| Puppy | ✓ | ✓ |  |
| Shishi | ✓ | ✓ |  |
| Sniffle | ✓ | ✓ |  |

### BEAST — Horn

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Arco |  | ✓ | ✓ |
| Beast Bun | ✓ | ✓ |  |
| Dual Blade |  | ✓ | ✓ |
| Imp |  | ✓ | ✓ |
| Little Branch |  | ✓ | ✓ |
| Lump | ✓ | ✓ |  |
| Merry |  | ✓ | ✓ |
| Pocky |  | ✓ | ✓ |
| Rocky Skull | ✓ | ✓ |  |
| Small Yak | ✓ | ✓ |  |
| Toy Ball | ✓ | ✓ |  |

### BEAST — Back

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Furball |  | ✓ | ✓ |
| Hero |  | ✓ | ✓ |
| Jaguar |  | ✓ | ✓ |
| Pangolin Slayer | ✓ | ✓ |  |
| Risky Beast |  | ✓ | ✓ |
| Ronin |  | ✓ | ✓ |
| Timber |  | ✓ | ✓ |

### BEAST — Tail

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Buba Brush | ✓ | ✓ |  |
| Cottontail |  | ✓ | ✓ |
| Gerbil |  | ✓ | ✓ |
| Hare |  | ✓ | ✓ |
| Nut Cracker | ✓ | ✓ | ✓ |
| Pangolin | ✓ | ✓ |  |
| Rice |  | ✓ | ✓ |
| Shiba | ✓ | ✓ | ✓ |

### BEAST — Eyes

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Chubby |  | ✓ | ✓ |
| Daydreaming | ✓ | ✓ |  |
| Little Peas |  | ✓ | ✓ |
| Nut Cracker | ✓ | ✓ |  |
| Puppy | ✓ | ✓ | ✓ |
| Sobby | ✓ | ✓ |  |
| Sparky | ✓ | ✓ |  |
| Zeal |  | ✓ | ✓ |

### BEAST — Ears

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Belieber | ✓ | ✓ | ✓ |
| Foxy | ✓ | ✓ |  |
| Innocent Lamb | ✓ | ✓ | ✓ |
| Nut Cracker | ✓ | ✓ | ✓ |
| Nyan |  | ✓ | ✓ |
| Puppy | ✓ | ✓ | ✓ |
| Zen |  | ✓ | ✓ |

## AQUATIC

### AQUATIC — Mouth

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Catfish |  | ✓ | ✓ |
| Lam |  | ✓ | ✓ |
| Piranha |  | ✓ | ✓ |
| Ranchu | ✓ | ✓ |  |
| Risky Fish |  | ✓ | ✓ |

### AQUATIC — Horn

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Anemone |  | ✓ | ✓ |
| Babylonia |  | ✓ | ✓ |
| Clamshell |  | ✓ | ✓ |
| Darksea Jellyfish | ✓ | ✓ |  |
| Jellytacle | ✓ | ✓ |  |
| Oranda |  | ✓ | ✓ |
| Shoal Star |  | ✓ | ✓ |
| Teal Shell |  | ✓ | ✓ |

### AQUATIC — Back

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Anemone |  | ✓ | ✓ |
| Blue Moon |  | ✓ | ✓ |
| Goldfish |  | ✓ | ✓ |
| Hermit |  | ✓ | ✓ |
| Perch |  | ✓ | ✓ |
| Sponge | ✓ | ✓ | ✓ |

### AQUATIC — Tail

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Koi |  | ✓ | ✓ |
| Navaga |  | ✓ | ✓ |
| Nimo |  | ✓ | ✓ |
| Oranda | ✓ | ✓ |  |
| Puff | ✓ | ✓ |  |
| Ranchu |  | ✓ | ✓ |
| Shrimp |  | ✓ | ✓ |
| Tadpole | ✓ | ✓ | ✓ |

### AQUATIC — Eyes

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Baby | ✓ | ✓ |  |
| Clear |  | ✓ | ✓ |
| Cold Fish | ✓ | ✓ |  |
| Gero |  | ✓ | ✓ |
| Kind Fish | ✓ | ✓ |  |
| Sleepless |  | ✓ | ✓ |
| Telescope |  | ✓ | ✓ |

### AQUATIC — Ears

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Bubblemaker |  | ✓ | ✓ |
| Gill | ✓ | ✓ | ✓ |
| Inkling |  | ✓ | ✓ |
| Little Crab | ✓ | ✓ |  |
| Nimo |  | ✓ | ✓ |
| Seaslug |  | ✓ | ✓ |
| Tiny Fan |  | ✓ | ✓ |

## PLANT

### PLANT — Mouth

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Beetroot | ✓ | ✓ |  |
| Hazelnut | ✓ | ✓ |  |
| Herbivore |  | ✓ | ✓ |
| Kidney Bean | ✓ | ✓ |  |
| Serious |  | ✓ | ✓ |
| Silence Whisper |  | ✓ | ✓ |
| Zigzag |  | ✓ | ✓ |

### PLANT — Horn

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Acorn Cap | ✓ | ✓ |  |
| Ballad Of The Shore | ✓ | ✓ |  |
| Bamboo Spear |  | ✓ | ✓ |
| Beech |  | ✓ | ✓ |
| Cactus |  | ✓ | ✓ |
| Lotus | ✓ | ✓ |  |
| Mandarine | ✓ | ✓ |  |
| Persimmon | ✓ | ✓ |  |
| Rose Bud |  | ✓ | ✓ |
| Strawberry Shortcake |  | ✓ | ✓ |
| Watermelon |  | ✓ | ✓ |

### PLANT — Back

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Bidens |  | ✓ | ✓ |
| Cone Shell | ✓ | ✓ |  |
| Death Shroom | ✓ | ✓ |  |
| Forest Hero | ✓ | ✓ |  |
| Meadow Blanket | ✓ | ✓ |  |
| Mint |  | ✓ | ✓ |
| Pumpkin |  | ✓ | ✓ |
| Shiitake |  | ✓ | ✓ |
| Succulent | ✓ | ✓ |  |
| Turnip |  | ✓ | ✓ |
| Watering Can |  | ✓ | ✓ |

### PLANT — Tail

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Carrot |  | ✓ | ✓ |
| Cattail |  | ✓ | ✓ |
| Drowsy Moss | ✓ | ✓ |  |
| Hatsune |  | ✓ | ✓ |
| Hot Butt |  | ✓ | ✓ |
| Potato Leaf |  | ✓ | ✓ |
| Sprout | ✓ | ✓ |  |
| Tropical Guardian | ✓ | ✓ |  |
| Yam |  | ✓ | ✓ |

### PLANT — Eyes

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Blossom |  | ✓ | ✓ |
| Confusion |  | ✓ | ✓ |
| Cucumber Slice |  | ✓ | ✓ |
| Papi | ✓ | ✓ | ✓ |
| Risky Trunk | ✓ | ✓ |  |

### PLANT — Ears

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Clover |  | ✓ | ✓ |
| Greenwood Rhythm | ✓ | ✓ |  |
| Hollow |  | ✓ | ✓ |
| Leafy |  | ✓ | ✓ |
| Lotus |  | ✓ | ✓ |
| Rosa |  | ✓ | ✓ |
| Sakura | ✓ | ✓ | ✓ |
| Turnip | ✓ | ✓ |  |

## BIRD

### BIRD — Mouth

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Doubletalk |  | ✓ | ✓ |
| Feathery Dart | ✓ | ✓ |  |
| Hungry Bird |  | ✓ | ✓ |
| Little Owl |  | ✓ | ✓ |
| Peace Maker |  | ✓ | ✓ |

### BIRD — Horn

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Big Sister | ✓ | ✓ |  |
| Cuckoo |  | ✓ | ✓ |
| Eggshell |  | ✓ | ✓ |
| Feather Spear |  | ✓ | ✓ |
| Kestrel |  | ✓ | ✓ |
| Trump |  | ✓ | ✓ |
| Wing Horn |  | ✓ | ✓ |

### BIRD — Back

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Balloon |  | ✓ | ✓ |
| Cupid |  | ✓ | ✓ |
| Feather Melody | ✓ | ✓ |  |
| Kingfisher |  | ✓ | ✓ |
| Lil Bro | ✓ | ✓ |  |
| Paper Wing | ✓ | ✓ |  |
| Pigeon Post |  | ✓ | ✓ |
| Raven |  | ✓ | ✓ |
| Rubber Duckling | ✓ | ✓ |  |
| Tri Feather |  | ✓ | ✓ |

### BIRD — Tail

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Cloud |  | ✓ | ✓ |
| Death Shower | ✓ | ✓ |  |
| Feather Fan |  | ✓ | ✓ |
| Granma's Fan |  | ✓ | ✓ |
| Post Fight |  | ✓ | ✓ |
| Swallow |  | ✓ | ✓ |
| The Last One |  | ✓ | ✓ |

### BIRD — Eyes

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Concentrate | ✓ | ✓ |  |
| Little Owl |  | ✓ | ✓ |
| Lucas |  | ✓ | ✓ |
| Mavis |  | ✓ | ✓ |
| Passion | ✓ | ✓ |  |
| Robin |  | ✓ | ✓ |

### BIRD — Ears

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Curly |  | ✓ | ✓ |
| Early Bird |  | ✓ | ✓ |
| Little Owl |  | ✓ | ✓ |
| Peace Maker |  | ✓ | ✓ |
| Pink Cheek |  | ✓ | ✓ |
| Risky Bird |  | ✓ | ✓ |

## BUG

### BUG — Mouth

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Cute Bunny |  | ✓ | ✓ |
| Maggot | ✓ | ✓ |  |
| Mosquito |  | ✓ | ✓ |
| Nose Drill | ✓ | ✓ |  |
| Pincer |  | ✓ | ✓ |
| Square Teeth |  | ✓ | ✓ |

### BUG — Horn

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Antenna |  | ✓ | ✓ |
| Caterpillars |  | ✓ | ✓ |
| Lagging |  | ✓ | ✓ |
| Leaf Bug |  | ✓ | ✓ |
| Parasite |  | ✓ | ✓ |
| Pliers |  | ✓ | ✓ |

### BUG — Back

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Buzz Buzz |  | ✓ | ✓ |
| Garish Worm |  | ✓ | ✓ |
| Sandal |  | ✓ | ✓ |
| Scarab |  | ✓ | ✓ |
| Snail Shell |  | ✓ | ✓ |
| Spiky Wing |  | ✓ | ✓ |

### BUG — Tail

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Ant |  | ✓ | ✓ |
| Centipede | ✓ | ✓ |  |
| Eye Wing | ✓ | ✓ |  |
| Fish Snack |  | ✓ | ✓ |
| Gravel Ant |  | ✓ | ✓ |
| Leaf Bug | ✓ | ✓ |  |
| Pupae |  | ✓ | ✓ |
| Shield Shattering | ✓ | ✓ |  |
| Thorny Caterpillar |  | ✓ | ✓ |
| Twin Tail |  | ✓ | ✓ |

### BUG — Eyes

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Bookworm |  | ✓ | ✓ |
| Kotaro? |  | ✓ | ✓ |
| Ladybug Goggles | ✓ | ✓ |  |
| Neo |  | ✓ | ✓ |
| Nerdy |  | ✓ | ✓ |

### BUG — Ears

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Beetle Spike |  | ✓ | ✓ |
| Brimstone | ✓ | ✓ |  |
| Ear Breathing |  | ✓ | ✓ |
| Earwing |  | ✓ | ✓ |
| Larva |  | ✓ | ✓ |
| Leaf Bug | ✓ | ✓ | ✓ |
| Maggot | ✓ | ✓ |  |
| Tassels |  | ✓ | ✓ |
| Termites | ✓ | ✓ |  |

## REPTILE

### REPTILE — Mouth

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Chemical Fang | ✓ | ✓ |  |
| Kotaro |  | ✓ | ✓ |
| Razor Bite |  | ✓ | ✓ |
| Tiny Dino | ✓ | ✓ |  |
| Tiny Turtle |  | ✓ | ✓ |
| Toothless Bite |  | ✓ | ✓ |

### REPTILE — Horn

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Bumpy | ✓ | ✓ | ✓ |
| Cerastes |  | ✓ | ✓ |
| Incisor |  | ✓ | ✓ |
| Poison Tube | ✓ | ✓ |  |
| Scaly Spear |  | ✓ | ✓ |
| Scaly Spoon |  | ✓ | ✓ |
| Unko |  | ✓ | ✓ |

### REPTILE — Back

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Bone Sail |  | ✓ | ✓ |
| Croc | ✓ | ✓ | ✓ |
| Green Thorns |  | ✓ | ✓ |
| Indian Star |  | ✓ | ✓ |
| Red Ear |  | ✓ | ✓ |
| Tiny Dino | ✓ | ✓ |  |
| Tri Spikes |  | ✓ | ✓ |

### REPTILE — Tail

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Gila |  | ✓ | ✓ |
| Grass Snake |  | ✓ | ✓ |
| Iguana |  | ✓ | ✓ |
| Snake Jar |  | ✓ | ✓ |
| Tiny Dino |  | ✓ | ✓ |
| Wall Gecko |  | ✓ | ✓ |

### REPTILE — Eyes

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Gecko |  | ✓ | ✓ |
| Hard-boiled | ✓ | ✓ |  |
| Punky | ✓ | ✓ |  |
| Scar | ✓ | ✓ | ✓ |
| Topaz |  | ✓ | ✓ |
| Tricky |  | ✓ | ✓ |

### REPTILE — Ears

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Curved Spine | ✓ | ✓ | ✓ |
| Friezard |  | ✓ | ✓ |
| Hidden Ears | ✓ | ✓ |  |
| Pogona |  | ✓ | ✓ |
| Sidebarb |  | ✓ | ✓ |
| Small Frill |  | ✓ | ✓ |
| Swirl |  | ✓ | ✓ |
| Venom Nail | ✓ | ✓ |  |

## DAWN (secret class)

### DAWN — Mouth

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Buddy Chorus | ✓ | ✓ |  |

### DAWN — Back

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Magic Sack | ✓ | ✓ |  |
| Nutdha Statue | ✓ | ✓ |  |
| White Gourd | ✓ | ✓ |  |

### DAWN — Tail

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Aegis Talisman | ✓ | ✓ |  |

### DAWN — Eyes

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Radiant Darkness | ✓ | ✓ |  |

### DAWN — Ears

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Harmonious Silence | ✓ | ✓ |  |

## DUSK (secret class)

### DUSK — Horn

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Dream Eater | ✓ | ✓ |  |

### DUSK — Back

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Greedy Urn | ✓ | ✓ |  |

### DUSK — Tail

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Black Gourd | ✓ | ✓ |  |
| Maraca | ✓ | ✓ |  |

### DUSK — Eyes

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Fulu | ✓ | ✓ |  |
| Grand Finale | ✓ | ✓ |  |

## MECH (secret class)

### MECH — Horn

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Lost Dream | ✓ | ✓ |  |
| Rusty Helm | ✓ | ✓ |  |
| Shocker | ✓ | ✓ |  |

### MECH — Back

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Village Hero | ✓ | ✓ |  |

### MECH — Tail

| Part | stage 0 (α, Origin) | stage 1 (base) | stage 2 (+, tiến hoá) |
|---|---|---|---|
| Mainspring | ✓ | ✓ |  |
