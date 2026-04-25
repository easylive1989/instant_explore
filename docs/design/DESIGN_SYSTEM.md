---
name: Chronos Guide
colors:
  surface: '#f9f9ff'
  surface-dim: '#d7dae3'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f3fd'
  surface-container: '#ebedf7'
  surface-container-high: '#e6e8f1'
  surface-container-highest: '#e0e2ec'
  on-surface: '#181c22'
  on-surface-variant: '#414753'
  inverse-surface: '#2d3038'
  inverse-on-surface: '#eef0fa'
  outline: '#717785'
  outline-variant: '#c1c6d5'
  surface-tint: '#005eb4'
  primary: '#005baf'
  on-primary: '#ffffff'
  primary-container: '#0074db'
  on-primary-container: '#fefcff'
  inverse-primary: '#a8c8ff'
  secondary: '#555f6b'
  on-secondary: '#ffffff'
  secondary-container: '#d6e1ee'
  on-secondary-container: '#59646f'
  tertiary: '#964400'
  on-tertiary: '#ffffff'
  tertiary-container: '#bc5700'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d5e3ff'
  primary-fixed-dim: '#a8c8ff'
  on-primary-fixed: '#001b3c'
  on-primary-fixed-variant: '#004689'
  secondary-fixed: '#d9e3f1'
  secondary-fixed-dim: '#bdc7d5'
  on-secondary-fixed: '#121c26'
  on-secondary-fixed-variant: '#3e4853'
  tertiary-fixed: '#ffdbc9'
  tertiary-fixed-dim: '#ffb68c'
  on-tertiary-fixed: '#321200'
  on-tertiary-fixed-variant: '#753400'
  background: '#f9f9ff'
  on-background: '#181c22'
  surface-variant: '#e0e2ec'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 28px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  label-caps:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.1em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  container-padding: 1.25rem
  stack-gap: 1rem
  section-top: 3rem
  nav-height: 84px
---

## Brand & Style
The brand identity is "The Modern Historian"—a blend of deep historical reverence and cutting-edge augmented reality. The visual style is **Glassmorphic** and **Atmospheric**, utilizing high-contrast typography and semi-transparent layers to create a sense of depth and mystery.

The UI now utilizes a clean **Light Mode** aesthetic, shifting from an "after-hours" feel to a "daylight expedition" vibe. It maintains a premium feel by using a bright, crisp background with vibrant primary accents to highlight critical navigational information. It balances technical precision (GPS/Audio indicators) with editorial elegance (large headlines and sans-serif clarity).

## Colors
The palette is centered on a clean, light foundation that emphasizes clarity and readability. 

- **Primary (#137fec):** A vibrant Neon Azure used for focus states, icons, and critical semantic indicators (e.g., proximity).
- **Secondary (#1c2630):** A deep charcoal used for high-contrast text and structural elements against light surfaces.
- **Surface:** The interface relies on light-themed glassmorphism. The primary surface is a highly transparent white container with a 12px backdrop blur, providing a modern "frosted" look that maintains legibility over photographic content.

## Typography
The system uses **Plus Jakarta Sans** for headlines to provide a modern, approachable character. **Inter** is used for body copy and UI labels to ensure maximum legibility at small sizes.

- **Hierarchical Emphasis:** Use uppercase tracking for functional metadata (status, tags).
- **Content Blocks:** Descriptive text uses a left-accented border (2px) in the primary color to tie the narrative to the brand identity.
- **Shadows:** In this light mode configuration, headlines use subtle, crisp positioning rather than heavy shadows to maintain a clean editorial look.

## Layout & Spacing
The layout follows a **Fixed Mobile-First Container** (max-width: 448px) centered on the screen. 

- **Margins:** Consistent 20px (1.25rem) horizontal margins for all interactive elements.
- **Vertical Rhythm:** A heavy top-safe area (48px) for status indicators, followed by a generous display title area. 
- **Navigation:** A fixed bottom navigation bar with a heavy backdrop blur (20px+) ensures the UI remains usable over varied background imagery.

## Elevation & Depth
In Light Mode, depth is achieved through **Optical Layering** and subtle tonal shifts:

1.  **Background Layer:** High-brightness map textures or photography with a subtle white-to-transparent gradient overlay.
2.  **Glow Layer:** Soft, light blue diffused radial gradients that provide a "halo" effect behind active cards.
3.  **Glass Layer:** The "Glass-Card" effect uses `backdrop-filter: blur(12px)` and a 1px white border at 40% opacity to define boundaries against light backgrounds.
4.  **Interactive Layer:** Active states use a slight scale-down effect (98%) and subtle inner shadows to simulate physical interaction.

## Shapes
The shape language is modern and "Large-Radius."

- **Cards:** Use `1rem` (rounded-2xl) corners to soften the tech-heavy aesthetic.
- **Indicators/Tags:** Small badges use `0.25rem` (rounded) or `9999px` (full-pill) depending on context.
- **Icons:** Enclosed in circular backgrounds with 10-15% opacity of the icon color to ensure visibility on light surfaces.

## Components

### Glass Cards
The primary container for content. In light mode, these feature a semi-transparent white background (`white/60`), a 1px border (`white/80`), and backdrop blur. Title and distance metadata should be justified-between at the top.

### Status Pills
Small, semi-transparent white capsules with a dark border used for system statuses (GPS, Audio). They use high-tracking uppercase text and dark icons for contrast.

### Distance Badges
Small rectangular tags with `primary/15` background and `primary` text. Used to indicate proximity. Should always include the "near_me" material symbol.

### Bottom Navigation
A high-blur, light-themed bar. Active items use the primary blue for both icon and label, while inactive items use the secondary charcoal with 50% opacity.

### List Items (Historical Sites)
Each item is an interactive button. Features include a primary-colored left border (accent) for the description text to guide the eye.