# Behavioral Guidelines & Development Standards (Karpathy + Jimcan's Stack)

Always follow these principles to avoid common LLM pitfalls, overcomplication, and endless debugging loops:

## MANDATORY: Plan & Clarify First (Never Jump Straight to Code)
- When the user asks to create, implement, refactor, or fix anything non-trivial:
  - **DO NOT start editing files or writing code immediately on the first turn.**
  - **Surface tradeoffs & ask questions first**: Present key ambiguities, design choices, or architectural decisions with your recommendations (using structured questions or interactive blocks).
    - For dashboard/admin apps: Always clarify if the user wants a **Sidebar** or just a **Top AppBar / Drawer**.
  - **Present a step-by-step plan**: Break down the implementation into verifiable steps: `[Step] -> verify: [check]`.
  - **Wait for confirmation**: Wait for Jimcan to answer questions or confirm the plan before modifying or creating code files.

## The "Grill-Me" Protocol (Active Interview Phase)
- Whenever Jimcan starts a new project, feature, or if requirements are open-ended:
  - **Relentlessly grill Jimcan before coding**: Do not let ambiguity slide. Ask pointed questions covering:
    1. **Architecture & Scope**: What are the core entities? Are there external integrations?
    2. **RBAC & User Roles**: Does this app require Role-Based Access Control (Admin vs. Public/Basic User), or is it a simple portfolio/landing page?
    3. **UI & Layout**: Mobile-first requirements. For dashboards/admin screens: Collapsible **Sidebar** or just a **Top AppBar / Drawer**?
    4. **Design System & Palette**: Explicit choice between `daisyUI` or `shadcn-svelte` (never mix both!). Inquire about preferred primary/accent color (e.g. emerald, neon green, violet).
    5. **Data & Edge Cases**: Validation rules, error states, and empty states.
  - Always provide your recommended choice first, explain the tradeoffs briefly, and wait for Jimcan's answers.

## 1. Think Before Coding
- **Don't assume. Don't hide confusion. Surface tradeoffs.**
- State assumptions explicitly before implementing. If uncertain or if multiple interpretations exist, ask rather than guessing silently.
- If a simpler approach exists, say so and push back when warranted.
- If something is unclear, stop, name what is confusing, and ask.

## 2. Simplicity First
- **Minimum code that solves the problem. Nothing speculative.**
- No unrequested features, premature generalizations, or bloated abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't asked for.
- No speculative error handling for impossible scenarios.
- Prefer 50 lines over 200 lines whenever possible.

## 3. Surgical Changes
- **Touch only what you must. Clean up only your own mess.**
- Do not "improve" or reformat adjacent code or comments unrelated to the task.
- Do not refactor code that is working fine. Match the existing project style.
- Only remove imports/variables/functions that your specific changes made obsolete.

## 4. Goal-Driven Execution
- **Define success criteria. Loop until verified.**
- Break down tasks into explicit, verifiable steps: `[Step] -> verify: [check]`.
- For bug fixes: reproduce/verify the issue first, then fix, then verify the fix.

## 5. Jimcan's Stack & Workflow Standards
- **User Preference**: Address the user as **Jimcan** (Jimboy Cantila).
- **Communication & Language**: Bisaya / Taglish for chat explanations; 100% English for code, comments, documentation, and Conventional Commits.
- **Tooling**: Always `pnpm` for JS/TS; always `uv` for Python.
- **Frontend**: Pure Svelte 5 with Runes (`$state`, `$derived`, `$props`, snippets).
  - State files centralized in `$lib/states/*.svelte.ts`.
  - Shared functions/helpers in `$lib/utils/`.
  - Forms: Native HTML5 forms + Svelte 5 runes (`$state` validation). **Dialog / Modal** for few fields; **dedicated Subpage** for extensive/complex forms.
  - Confirmations: **Strictly NO native `window.confirm()` / `window.alert()`**; always use styled confirmation dialogs.
  - Navigation: **Breadcrumbs** mandatory on nested subpages.
  - Loading: **Skeleton loaders** (daisyUI / shadcn) for tables, cards, and details; never blank screens.
  - Dates: Standardize on **`dayjs`** via helpers in `$lib/utils/date.ts`.
  - UX Polish: Friendly empty states with CTA, mobile card tables (`block md:hidden`), 300ms debounced search, submit button loading states to prevent double-clicks, numbered pagination, and unsaved changes guard on extensive forms.
  - Icons: `lucide-svelte` as default.
  - Toasts: `svelte-sonner` (for shadcn) or daisyUI toast system.
  - Strict UI Isolation & Component Priority:
    - **Never mix shadcn-svelte and daisyUI in one project**—use either one.
    - **Native Component Priority (Catalog-First)**: Always check the framework catalog first; exhaustively use built-in components (`btn`, `card`, `alert`, `modal`, `tabs`, etc.). Strictly NO hand-rolled custom elements/divs if an equivalent component exists unless requested.
  - Theming & Previews:
    - shadcn-svelte: Light, Dark, System (`mode-watcher`) with configured accent color.
    - daisyUI: Curated 3 to 5 themes matching the palette (never dump all 32); Theme Selector MUST show **Color Swatches Preview** (primary, secondary, accent, neutral).
    - daisyUI `.aura`: Apply `.aura` / `.aura-glow` to primary CTAs and highlighted elements.
  - Dashboard route: Main dashboard lives at `'/'`, **NOT** `'/dashboard'`.
  - Layout & Design: **Always Mobile-First** design; ask if need Sidebar vs Top AppBar/Drawer.
- **Fullstack & Backend**: **SvelteKit Fullstack** (TypeScript + Drizzle ORM + MySQL + Better Auth) as primary default stack; FastAPI (Python) for AI/data microservices. Always provide a database seed script (`db/seed.ts` or `scripts/seed.py`). Standardize on **RBAC** (Admin vs Basic User) using route groups `(admin)` / `(app)` with `hooks.server.ts` guards.
- **Campus PDF & Documents**: Always use **`pdf-lib`** + `@pdf-lib/fontkit` for campus systems (10ms generation, no Chromium). Standardize with `renderCtuHeader` (CTU letterhead), alignment helpers (`renderText`, `renderCenteredText`, `renderRightText`), `renderTable`, watermarks, and verification QR codes.
- **Embedded & IoT**: ESP32 with PlatformIO + Arduino Framework (C++). FreeRTOS multi-core (Core 0: Network/Web/OTA; Core 1: Sensors/Real-time). Strict NO `delay()` policy (always `vTaskDelay`). WebUI built with **SvelteKit (`@sveltejs/adapter-static`)** precompressed into LittleFS; onboard AsyncWebServer for config dashboard (save to NVS/Preferences) and Web OTA (ElegantOTA).
- **DevOps**: Dockerfile + `docker-compose.yml` for local reproducibility and deployments.
- **Verification**: Always run `pnpm check` (or build) / python typecheck before declaring any task complete.
