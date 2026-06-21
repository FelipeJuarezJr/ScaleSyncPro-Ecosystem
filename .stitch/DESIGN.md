# Design System: ScaleSync Social Dashboard

## 1. Visual Theme & Atmosphere
A futuristic, nocturnal analytics cockpit with a glassmorphic layer aesthetic. The interface uses a clean, high-density obsidian-dark canvas overlaid with semi-transparent charcoal cards, neon accents, and subtle backdrop-blur (20px) depth. It aims for a "Daily App Balanced" (density 6) layout with confident asymmetric cards (variance 5) and perpetual micro-animations (motion 6) for interactive telemetry feed items.

## 2. Color Palette & Roles
- **Obsidian Dark Canvas** (`#1A1A1A` / `var(--bg-primary)`) — Base canvas background.
- **Deep Charcoal Card Surface** (`#2C2C2C` / `var(--bg-secondary)`) — Semi-transparent glass containers.
- **Neon Green Accent** (`#00FF00` / `var(--primary-color)`) — Primary interactive highlights, successful states, and toggles.
- **Cyan Blue Highlight** (`#00D4FF` / `var(--primary-light)`) — Secondary active telemetry metrics, graph lines, and links.
- **Cyber Orange Notice** (`#FFA500` / `var(--accent-color)`) — Warnings, pending alerts, and specialized metrics.
- **Muted Platinum** (`#CCCCCC` / `var(--text-secondary)`) — Body copy and descriptions.
- **Whisper Border** (`rgba(74, 74, 74, 0.3)` / `var(--border-color)`) — Sleek 1px structural dividing lines.

## 3. Typography Rules
- **Display & Headlines:** Hanken Grotesk or standard Sans-serif — Track-tight letter-spacing, weight-driven hierarchy, never screamingly oversized.
- **Body & Labels:** Work Sans or standard Sans-serif — Relaxed leading, maximum 65 characters per line (65ch) for optimal legibility.
- **Mono / Numbers:** Geist Mono / JetBrains Mono — For statistics, counts, timestamps, and metadata tags to enforce telemetry vibe.
- **Banned:** Generic system serifs, default raw Inter (use customized variants or System stacks if needed).

## 4. Component Stylings
* **Telemetry Metric Cards:** Rounded corners (12px), border 1px solid whisper border, background deep charcoal. Layout shows icon left, metric number middle-right, trend indicator bottom.
* **Buttons:** Flat, tactile `-1px` vertical offset translate on active press. Accent fill for primary buttons, transparent border-outline for secondary actions. Glow shadows are banned.
* **Social Feed Posts:** Glassmorphic card container. Rounded user avatars with status indicator. Heart/Like button turns Neon Green on tap with subtle micro-scale bump.
* **Charts/Graphs:** Minimal SVGs with gradient fills (Cyan-to-transparent) and sharp vector lines. Gridlines are thin Whisper Borders.

## 5. Layout Principles
- **No Overlapping Elements:** Spatially clean separation. No absolute overlay content stacking that hinders responsive flow.
- **Three-Column Dashboard Grid:** 
  - Column 1: "Telemetry Feed" (social posts, updates, interactive user activities).
  - Column 2: "Analytics Terminal" (growth curves, engagement metrics, charts).
  - Column 3: "Control Center & Alerts" (publishing console, quick actions, system notifications).
- **Responsive Cascade:** At mobile resolutions (`< 768px`), all three columns collapse into a single-column sequence. Touch targets must be at least `44px`.

## 6. Motion & Interaction
- **Spring Physics:** Stiffness: 100, Damping: 20 for standard animations.
- **Waterfall Entrance:** Telemetry items fade and slide up using a staggered `animation-delay`.
- **Perpetual Shimmer:** Telemetry loader skeletons utilize CSS keyframe shimmers instead of simple opacity pulse.
- **GPU-Accelerated Transforms:** Strictly use `transform` and `opacity` for interaction transitions (hover zoom, tap click).

## 7. Anti-Patterns (Banned)
- No emojis anywhere in system labels or titles.
- No pure black (`#000000`) for surfaces or boundaries.
- No oversaturated accents or generic AI gradient purple glows.
- No fabricated telemetry stats or fake response times — use clear `[metric]` tags or retrieve real database fields.
- No centered hero containers.
- No broken Unsplash links — always use local assets or standard SVG inline illustrations.
