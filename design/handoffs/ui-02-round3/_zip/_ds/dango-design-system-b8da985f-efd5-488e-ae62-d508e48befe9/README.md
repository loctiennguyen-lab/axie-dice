# Dango Design System

Reference previews for **`@axieinfinity/dango`** — the React UI component library for Axie Infinity products.

Every page on this board is generated from the library's own source. Tokens come from the compiled
`src/styles/index.scss` (`:root` custom properties, `--dg-*` prefix) and each component's styling comes
from its own `*.module.scss`, compiled with the same SCSS prelude the Rollup build uses. Icons come from
`@axieinfinity/dango-icons`. Nothing here is a redrawn approximation — the CSS and the glyphs are the
shipped CSS and the shipped glyphs.

## Foundations

| Page | Covers |
| --- | --- |
| Color | 6 ramps × 9 steps, 7 semantic intents, application colors |
| Typography | Heading 1–6, Text 1–4 (+bold), intents, transforms |
| Spacing & Radius | `Space` scale 1–5 and fractional steps, justification, corner radii |
| Surfaces | `Box` levels 1–5, intent surfaces, nesting |

## Icons

| Page | Covers |
| --- | --- |
| Icon Library | 1,329 icons from `@axieinfinity/dango-icons`, 24×24, searchable by name |
| Part Icons | 50 Axie body-part icons, 48×48, full colour |

General icons are monochrome and drawn with `currentColor`, so they inherit text colour and respond to
intent classes. Pass `size` (default 16) to scale:

```tsx
import { Search01Icon, ChevronDownIcon } from '@axieinfinity/dango-icons';

<Input prefixIcon={Search01Icon} />
<Search01Icon size={20} />
```

Part icons are artwork rather than glyphs — they keep their own colours and default to `size` 48.

**Every glyph on this board comes from the icon package.** Nothing is hand-drawn, and each `<svg>` carries
a `data-icon` attribute naming its export, so any specimen can be traced back to source. The component
previews use the same 14 icons the library's own components import:

`ArrowRightIcon` · `CheckmarkCircleIcon` · `ChevronDownIcon` · `ChevronRightIcon` · `DirectionLeftIcon` ·
`DirectionRightIcon` · `InformationCircle01Icon` · `Plus01Icon` · `Remove01Icon` · `Search01Icon` ·
`StarIcon` · `TickIcon` · `UserIcon` · `WarningCircleIcon`

`Remove01Icon` is the canonical close/remove glyph (used 16× across the library), `TickIcon` is the
checkbox and completed-step mark, and `ChevronDownIcon` is the dropdown and collapse affordance. Reach for
these before introducing a different icon for the same job.

The only non-icon `<svg>` on the board is `ProgressCircle`'s own arc, which the component draws itself; it
is marked `data-svg="component-native"`.

## Components

- **Actions** — Button (6 intents × 3 variants × 4 sizes), Icon Button (standard + floating)
- **Forms** — Input, Textarea, Checkbox, Radio, Switch, Slider, Dropdown
- **Data Display** — Badge, Tag, Table
- **Feedback** — Alert, Loaders (circle / dot / linear / skeleton), Progress (bar + circle)
- **Navigation** — Tabs, Menu, Breadcrumb, Pagination, Stepper
- **Overlay** — Dialog, Drawer, Tooltip & Popover, Collapse

## Conventions

**Dark-first, single theme.** The canvas is `--dg-color-background` (`#13161B`). There is no light mode.

**Intents, not colors.** Components take an `intent` (`primary` · `secondary` · `success` · `info` ·
`danger` · `default`), never a raw hex. Each intent resolves to a ramp step, so re-pointing one variable
re-themes every component that uses it. `primary` is the Kam ramp — the Axie orange, `#FF9345`.

**Sizes.** Most components use `x-small` · `small` · `default` · `large`. `default` is the base class and
carries no size modifier of its own.

## Reading these previews

- Captions under each specimen are the literal CSS-module class names, so a preview maps directly to source.
- Interactive states (`:hover`, `:focus`, `:active`) exist in the CSS but are not shown as static
  specimens — only `[disabled]` and explicitly-toggled states like `.activated` are pinned open.
- Portal-rendered components (Dialog, Drawer, Tooltip, Popover) are shown as their inner panel, lifted out
  of the portal and placed inline. Positioning in the real app is handled by `rc-dialog`, `rc-drawer`,
  and `react-laag`.
- The type specimens fall back to the system sans-serif: Work Sans is loaded by the host application, and
  these pages are self-contained with no external font requests. Metrics (size, line-height, weight) are
  the real token values.

## Installing

```bash
yarn add @axieinfinity/dango @axieinfinity/dango-icons
```

`@axieinfinity/dango-icons` is a peer dependency. Import the stylesheet once at your app root — required,
because Dango relies on CSS modules plus globally-loaded design tokens:

```ts
import { Button, Intent, Size } from '@axieinfinity/dango';
import '@axieinfinity/dango/dist/bundle.css';
```
