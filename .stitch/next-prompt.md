# ScaleSync Social: Campaign & Post Scheduler Sub-Dashboard

An interactive content calendar, post scheduler, and live campaign manager for reptile breeders to automate their social presence.

**DESIGN SYSTEM (REQUIRED):**
- Platform: Web, Desktop-first
- Theme: Nocturnal, dark theme with glassmorphic layers
- Background: Obsidian Dark Canvas (#1A1A1A)
- Card Surface: Deep Charcoal Card Surface (#2C2C2C) at 40% opacity
- Primary Accent: Cyan Blue Highlight (#00D4FF) for telemetry indicators
- Accent Success: Neon Green (#00FF00) for active schedule statuses
- Text Primary: Muted Platinum (#CCCCCC)
- Typography: Work Sans (Sans-serif) and Geist Mono for dates/times

**Page Structure:**
1. **Header Navigation:** Breadcrumbs ("Social Hub / Campaign Scheduler"), back button to dashboard, and active time-zone indicator.
2. **Scheduler Control Board:**
   - Interactive calendar grid showing scheduled posts.
   - Slot composer: Click a date cell to write a post content, attach photo URL, set scheduled date/time, and select target channel (ReptiGram, Marketplace).
3. **Active Campaigns List:**
   - Horizontal list of current campaigns (e.g., "Albino Piebald Project Launch", "Summer Expo Clearout").
   - Telemetry gauges displaying Campaign Goal progress (e.g., Target Reach vs Actual Reach).
4. **Queue Logs Terminal:**
   - High-density list showing upcoming scheduled post items with status (e.g., `QUEUED`, `PENDING_MEDIA_SYNC`, `PUBLISHED`).
   - Trigger buttons to "Publish Now", "Pause Queue", or "Reschedule".
