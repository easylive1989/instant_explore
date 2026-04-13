# Midnight Kyoto Design System

### 1. Overview & Creative North Star
**Creative North Star: "The Neon Nocturne"**
Midnight Kyoto is a high-end editorial framework designed for immersive, location-based storytelling. It rejects the sterility of flat UI in favor of "Atmospheric Depth"—a digital experience that feels like walking through a mist-covered historic district at night. The system prioritizes texture, translucency, and vibrant "electric" accents against a deep, ink-black foundation. It breaks the traditional grid by treating the screen as a layered canvas where content floats over a living, textured background.

### 2. Colors
The palette is rooted in `#101922` (Midnight Blue-Black), providing a canvas that makes high-fidelity photography and the primary `#137fec` (Electric Blue) pop.

*   **The "No-Line" Rule:** Standard 1px solid borders are prohibited for layout sectioning. Separation is achieved through background color shifts (`surface` to `surface_container`) or through the use of glass-morphic cards. 
*   **Surface Hierarchy & Nesting:** Use `surface_container_low` for background areas and `surface_variant` (white at 8% opacity) for interactive cards. This creates a "nested" look where depth is perceived through cumulative opacity.
*   **The "Glass & Gradient" Rule:** All floating elements (cards, navigation bars) must utilize backdrop blurs (12px minimum) and semi-transparent fills. 
*   **Signature Textures:** Backgrounds should utilize a "Deep Overlay" technique: a base color, an image with 40% opacity in grayscale/mix-blend-overlay mode, and a top gradient wash to ensure text legibility.

### 3. Typography
Midnight Kyoto uses **Inter** as its sole typographic voice, relying on extreme weight contrast and letter-spacing to create an editorial feel.

*   **Display (2.25rem / 36px):** Bold, tracking-tight. Used for high-level navigation anchors like "Explore".
*   **Headlines (1.125rem / 18px):** Bold. The primary identifier for content pieces.
*   **Body (0.75rem / 12px):** Regular weight with relaxed leading for long-form snippets.
*   **Labels & Metadata (10px - 12px):** All-caps with wide tracking for categories, or bold for small status chips.
*   **The Rhythm:** The scale jumps from very small (10px) metadata directly to large titles (18px+), skipping the "middle-ground" sizes common in standard apps to create a more dramatic, magazine-like hierarchy.

### 4. Elevation & Depth
Depth is not simulated through light-source shadows, but through **Tonal Stacking**.

*   **The Layering Principle:** Content sits on "Glass Cards" (`rgba(255, 255, 255, 0.08)`).
*   **Ambient Shadows:** Use the `shadow-lg` preset, which features extra-diffused, low-opacity shadows (`shadow-black/20`) to ground floating elements without creating "dirt" on the dark background.
*   **The "Ghost Border" Fallback:** When a boundary is strictly necessary (e.g., active states), use `white/10` (a 10% white stroke) which creates a shimmering edge rather than a hard line.
*   **Glassmorphism:** Elements like the bottom navigation and content cards must use `backdrop-blur-xl` to pull the underlying background colors into the component's own palette.

### 5. Components
*   **Glass Cards:** The primary container. Must have a `0.75rem` to `1rem` corner radius, a subtle 10% white border, and a 12px backdrop blur.
*   **Primary Action Buttons:** Pill-shaped (rounded-full). Uses the seed color `#137fec` with a hover transition to a deeper blue (`#0f6bd0`) and a slight `active:scale-95` interaction.
*   **Status Chips:** Small, high-contrast labels. Use `primary/20` background with `primary` text for "active/near" states, and `white/10` for secondary metadata.
*   **Navigation Bar:** A blur-heavy (`backdrop-blur-xl`) dock that uses `opacity-60` for inactive states and a themed container (`primary/20`) for the active icon.

### 6. Do's and Don'ts
*   **Do:** Use high-quality photography as a structural element.
*   **Do:** Use subtle pulse animations on background decorative elements to simulate "life."
*   **Don't:** Use pure `#000000` or `#ffffff` for anything other than absolute highlights.
*   **Don't:** Add borders to the main layout sections; let the color transitions do the work.
*   **Do:** Ensure small 10px text maintains a high contrast ratio (minimum 4.5:1) against the dark glass surfaces.