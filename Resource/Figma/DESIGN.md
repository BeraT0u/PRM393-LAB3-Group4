---
name: Warm Paper Academic
colors:
  surface: '#fff8f5'
  surface-dim: '#e0d8d5'
  surface-bright: '#fff8f5'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#faf2ee'
  surface-container: '#f4ece8'
  surface-container-high: '#eee7e3'
  surface-container-highest: '#e9e1dd'
  on-surface: '#1e1b19'
  on-surface-variant: '#434655'
  inverse-surface: '#33302d'
  inverse-on-surface: '#f7efeb'
  outline: '#737686'
  outline-variant: '#c3c6d7'
  surface-tint: '#0053db'
  primary: '#004ac6'
  on-primary: '#ffffff'
  primary-container: '#2563eb'
  on-primary-container: '#eeefff'
  inverse-primary: '#b4c5ff'
  secondary: '#855300'
  on-secondary: '#ffffff'
  secondary-container: '#fea619'
  on-secondary-container: '#684000'
  tertiary: '#88411a'
  on-tertiary: '#ffffff'
  tertiary-container: '#a65830'
  on-tertiary-container: '#ffede6'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#ffddb8'
  secondary-fixed-dim: '#ffb95f'
  on-secondary-fixed: '#2a1700'
  on-secondary-fixed-variant: '#653e00'
  tertiary-fixed: '#ffdbcc'
  tertiary-fixed-dim: '#ffb693'
  on-tertiary-fixed: '#351000'
  on-tertiary-fixed-variant: '#76330d'
  background: '#fff8f5'
  on-background: '#1e1b19'
  surface-variant: '#e9e1dd'
typography:
  display:
    fontFamily: Inter
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  display-mobile:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.015em
  headline-lg:
    fontFamily: Inter
    fontSize: 30px
    fontWeight: '600'
    lineHeight: 38px
    letterSpacing: -0.015em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 30px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: 0em
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
    letterSpacing: 0em
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: 0em
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0.005em
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  caption:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0.01em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1.5rem
  gutter-mobile: 1rem
  margin: 2rem
  margin-mobile: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
  space-2xl: 3rem
---

## Brand & Style

The design system is centered on the concept of tactile, analog study tools translated into modern digital architecture. Designed for focused students, educators, and researchers, the interface evokes the feeling of premium heavy-stock parchment, archival notebooks, and distraction-free study environments. 

The aesthetic fuses modern editorial clarity with subtle warm minimalism. By eschewing sterile, ultra-cold digital white space in favor of a comforting, sepia-adjacent paper canvas, the system lowers cognitive load and reduces eye fatigue during extended study sessions. Functional elements use crisp, deliberate hierarchy, grounded geometry, and tactile surface separation rather than aggressive digital effects or novelty visuals.

## Colors

The palette establishes an organic, warm-reading baseline anchored by high-contrast typographic clarity:

- **Canvas Background (`#FBF6EB`)**: A muted cream paper that sets the foundation for low-glare reading.
- **Surface Elevation (`#FFFDF7`)**: A soft warm ivory used for elevated cards and modals. Never use sterile pure white (`#FFFFFF`).
- **Primary Text (`#1C1917`)**: Deep espresso ink delivering WCAG AAA contrast (exceeding 12:1 against canvas and cards).
- **Secondary Text (`#78716C`)**: Warm stone muted brown-gray for metadata, captions, and structural hints (exceeding 4.5:1 against surfaces).
- **Primary Accent (`#2563EB`)**: Royal Blue for explicit interactive cues, primary calls-to-action, focus halos, and active navigation indicators.
- **Warning & Highlight (`#F59E0B` / `#FEF3C7`)**: Amber tones for status tags, reminders, and alerts, paired strictly with deep amber text (`#78350F`) for compliant readability.
- **Structural Border (`#EAE1D0`)**: A warm, sand-tinted line token applied at 1px thickness without dashed or dotted treatments.

## Typography

Inter provides clear, neutral letterforms engineered for dense informational layouts, timelines, and long-form study modules. 

All headings feature tightened letter-spacing (`-0.01em` to `-0.02em`) to maintain an authoritative, editorial density reminiscent of printed texts. Body copy uses relaxed, open line-heights (1.5x to 1.55x) to facilitate continuous reading on amber-tinted backdrops without visual crowding. Numeric data, schedules, and grade breakdowns should utilize tabular numbers (`font-variant-numeric: tabular-nums`) to ensure vertical alignment across data lists.

## Layout & Spacing

The layout is built upon an 8pt rhythmic grid within a 12-column fluid framework on desktop (max width: 1280px) and a 4-column system on mobile viewports.

- **Desktop (>= 1024px)**: Uses 24px (`1.5rem`) gutters and 32px (`2rem`) outer canvas margins. Multi-column cards and schedules align to 12 columns with relaxed breathing room.
- **Tablet (768px - 1023px)**: Transitions to 8 columns with 16px gutters and 24px margins. Sidebar panels collapse into accessible off-canvas drawers.
- **Mobile (< 768px)**: 4 columns with 16px gutters and 16px margins. Cards span full width, with content-first stacking. All touch targets strictly maintain a minimum boundary of 48×48px.

## Elevation & Depth

Visual hierarchy does not use deep synthetic drop shadows or stark elevation scales. Instead, it relies on low-amplitude warm ambient depth paired with continuous border definitions.

- **Base Canvas (Level 0)**: `#FBF6EB`, non-elevated flat canvas.
- **Card / Surface (Level 1)**: `#FFFDF7`, framed by a solid `1px solid #EAE1D0` border and an ambient warm shadow: `0 2px 8px -2px rgba(120, 113, 108, 0.08), 0 1px 3px 0 rgba(120, 113, 108, 0.04)`.
- **Flyout / Dropdown (Level 2)**: `#FFFDF7`, bordered by `#EAE1D0`, elevated with `0 8px 16px -4px rgba(120, 113, 108, 0.12), 0 2px 6px -1px rgba(120, 113, 108, 0.06)`.
- **Modal / Overlay Dialog (Level 3)**: `#FFFDF7`, elevated with `0 16px 32px -8px rgba(28, 25, 23, 0.14)`, centered over a semi-translucent warm backdrop scrim: `rgba(28, 25, 23, 0.40)`.

## Shapes

The geometric signature uses a unified corner radius of 16px (`1rem`) on all primary containers, course blocks, and modal surfaces to evoke soft-bound notebook corners. 

Secondary interactive controls (buttons, input fields, selector chips) adopt an 8px (`0.5rem`) radius to preserve functional boundary precision. Status badges, tags, and small pill indicators employ fully rounded radiuses (9999px) to establish visual contrast against structural cards.

## Components

### Buttons
- **Primary**: Solid Royal Blue (`#2563EB`) fill with white (`#FFFFFF`) text. Height: 48px min. Padding: 0 20px. Border radius: 8px. Hover state: `#1D4ED8`. Focus outline: 2px solid `#2563EB` with 2px offset.
- **Secondary**: Surface fill (`#FFFDF7`) with 1px solid `#EAE1D0` border. Text color: `#1C1917`. Hover: `#FBF6EB`.
- **Tertiary / Ghost**: Transparent background, `#1C1917` text. Hover: `#F2EAD8` background.

### Cards
- Surface: `#FFFDF7`.
- Border: 1px solid `#EAE1D0` (continuous line; never dashed or broken).
- Border Radius: 16px.
- Internal Padding: 20px on mobile, 24px on desktop.
- Shadow: Level 1 warm ambient shadow.

### Form Inputs
- Height: 48px minimum.
- Background: `#FFFDF7`.
- Border: 1px solid `#EAE1D0`. Radius: 8px.
- Text: `#1C1917` (Inter 16px). Placeholder: `#78716C`.
- Focus: 1px solid `#2563EB` with an external `0 0 0 3px rgba(37, 99, 235, 0.15)` focus ring.

### Chips & Badges
- **Academic Tags / Chips**: Height: 32px. Radius: 9999px. Background: `#F2EAD8`, Text: `#1C1917`, Border: 1px solid `#EAE1D0`.
- **Warning / Alert Chip**: Background: `#FEF3C7`, Text: `#78350F`, Border: 1px solid `#FDE68A`.

### Selection Controls (Checkboxes & Radios)
- Dimensions: 20×20px inside a 48×48px interactive touch area.
- Unchecked: Background `#FFFDF7`, border 1.5px solid `#78716C`, radius 4px (checkbox) or 50% (radio).
- Checked: Background `#2563EB`, border `#2563EB`, checkmark/indicator in `#FFFFFF`.

### List Items & Schedule Cells
- Multi-row items bounded by 1px bottom border `#EAE1D0`.
- Padding: 16px vertical, 12px horizontal.
- Hover: Soft highlight tint `#F5EEDB`.