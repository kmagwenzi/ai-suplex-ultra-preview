# Design: AI-Suplex Ultra (Sales & Front Door)

The locked system for AI-Suplex Ultra front door and sales surfaces. Every page build reads this first and adheres to it. Change it only on purpose; the file is the rule.

## System
- **Genre:** Atmospheric & Editorial (Instrument-Grade Technical)
- **Shape of page:** Long Document / Sales Landing with Interactive Instrument Showcase
- **Theme:** Navy Ground & Warm Gold / Precision Data
- **Posture:** Asymmetric, authoritative, deterministic-first, honest metrics

## Palette & Ground
- Ground: Navy-950 (`#080e1a`)
- Ground Elev 1: Navy-900 (`#0d172a`)
- Ground Elev 2: Navy-800 (`#121e35`)
- Ground Elev 3: Navy-700 (`#1a2947`)
- Gold Base: `#b8862e`
- Gold High (Active / Delta / Highlights): `#d4a94f`
- Cream Accent: `#e8d5a8`
- Ink Primary: `#f1f5f9`
- Ink Muted: `#94a3b8`
- Ink Sub-Muted: `rgba(148, 163, 184, 0.6)`
- Hairline Border: `rgba(255, 255, 255, 0.08)`
- Hairline Strong: `rgba(255, 255, 255, 0.14)`

## Typography
- **Display / Heading:** `IBM Plex Serif`, `Instrument Serif`, or Georgia, serif
- **Body / Interface:** `Inter`, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif
- **Data / Monospace / Badges:** `IBM Plex Mono`, `JetBrains Mono`, SFMono-Regular, monospace
- Contrast ratio floor: >= 4.5:1 on all text, links, and badges against backgrounds.

## Controls & Buttons
- **Primary Action (Waitlist / Submit):**
  - Fill: Gold (`#d4a94f`), text: Navy-950 (`#080e1a`), weight: 600
  - Padding: `0.75rem 1.5rem`
  - Radius: `6px`
  - State: Focus visible with `2px solid #d4a94f`, hover slight glow/brightness
- **Secondary Action (See Gap Live / 777 Free):**
  - Outline: `1px solid rgba(255, 255, 255, 0.16)`, background: `rgba(18, 30, 53, 0.5)`, text: `#f1f5f9`
  - Hover: border `#b8862e`, text `#d4a94f`
- **Interactive Inputs:**
  - Background: `rgba(13, 23, 42, 0.7)`, border: `1px solid rgba(255, 255, 255, 0.12)`
  - Focus: `outline: 2px solid #d4a94f`, border-color: `#d4a94f`

## Hallmark Floor Guarantees
1. Every color, font, spacing, and radius declared via CSS variables in `:root` or Tailwind theme tokens.
2. No `transition: all`. Animate only opacity and transform.
3. No single italic word in a roman heading.
4. `overflow-x: clip` on `html` and `body`.
5. Full focus-visible accessibility on all buttons, links, inputs.
6. Full `prefers-reduced-motion: reduce` support.
7. Zero invented metrics or testimonials: numbers must trace to measured commands (654 assertions, 30 test files, 1,642 entities, 4,865 edges).
8. No eyebrow kickers or tracked capitals.
9. No purple/blue gradients or card-inside-card slop.
