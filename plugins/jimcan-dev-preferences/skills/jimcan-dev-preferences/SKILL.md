---
name: jimcan-dev-preferences
description: Jimcan's (Jimboy Cantila) personal development preferences and stack standards. Use whenever scaffolding, writing, refactoring, or architecting frontend, backend, database, and authentication code across any project.
---

# Jimcan's Development Preferences & Stack Standards (`jimcan-dev-preferences`)

Always adhere to these personal preferences across all projects and tasks:

---

## 1. Communication & Language
- **User Preference**: Address the user as **Jimcan** (Jimboy Cantila).
- **Chat & Explanations**: Bisaya / Taglish. Keep it warm, direct, and concise.
- **Code, Comments & Git**: 100% English.
  - **Git Commits**: Conventional Commits format (`feat: ...`, `fix: ...`, `refactor: ...`, `chore: ...`). Direct commits on `main` for fast development; use feature branches (`feat/...`) for large/multi-step features.
  - **Comments**: Minimalist. Write self-documenting code. Never write comments that merely restate what obvious code does. Only comment non-obvious domain logic or critical workarounds.

---

## 2. Package Managers & Tooling
- **JavaScript / TypeScript**: Always use `pnpm` (`pnpm add`, `pnpm run`, `pnpm check`).
- **Python**: Always use `uv` (`uv pip`, `uv run`, `uv venv`).

---

## 3. Frontend Architecture & Svelte 5 Patterns
- **Framework**: Pure Svelte 5 + Strict TypeScript.
  - Use modern Svelte 5 Runes: `$state`, `$derived`, `$props`, `$effect`, `$bindable`.
  - Use Snippets (`{#snippet ...}`) instead of legacy slots.
  - Do NOT write legacy Svelte 3/4 stores or syntax unless dealing with unmigrated legacy dependencies.
- **State Management**:
  - Centralize reusable/shared application state in `$lib/states/<feature>-state.svelte.ts` files using Svelte 5 `.svelte.ts` universal runes (class-based state or module-level `$state` objects).
- **Helper Functions & Utilities**:
  - Whenever functions or utilities are used across multiple files or components, extract them into `$lib/utils/` to keep code clean and DRY.
- **Forms & Validation**:
  - Prefer **Native HTML5 forms + Svelte 5 Runes** (`$state` validation) for a lightweight, dependency-free approach. Avoid bloated form libraries unless explicitly requested.
- **Data Fetching & Actions**:
  - Use SvelteKit native `load` functions (`+page.server.ts`) for server-side loading and Form Actions (`actions` in `+page.server.ts`) for mutations.
- **UI Design System Policy (Strict Separation)**:
  - **Never mix shadcn-svelte and daisyUI in the same project!**
  - Use **EITHER** `shadcn-svelte` **OR** `daisyUI` based on the project's chosen design system.
  - Clarify with the user which UI system to use if starting from scratch.
- **Icons**:
  - Use **`lucide-svelte`** as the default icons library.
- **Toasts & Feedback**:
  - Use **`svelte-sonner`** for `shadcn-svelte` projects; use the semantic daisyUI toast system for `daisyUI` projects.
- **Theming & Dark Mode**:
  - Always support a Dark Mode toggle (using `mode-watcher` with shadcn-svelte or `data-theme` toggle with daisyUI).
- **Design Philosophy**:
  - **Mobile-First Always**: Structure layouts, spacing, and grids mobile-first (small screens first, progressively enhanced for desktop with `md:` and `lg:` classes).
- **Date Management & Formatting**:
  - Always use **`dayjs`** for all date parsing, manipulation, and formatting.
  - Centralize date helpers in `$lib/utils/date.ts`:
    ```typescript
    import dayjs from 'dayjs';
    import relativeTime from 'dayjs/plugin/relativeTime';
    dayjs.extend(relativeTime);

    export const formatDate = (d: Date | string | number, fmt = 'MMMM D, YYYY') => dayjs(d).format(fmt);
    export const formatTime = (d: Date | string | number) => dayjs(d).format('h:mm A');
    export const formatDateTime = (d: Date | string | number) => dayjs(d).format('MMM D, YYYY h:mm A');
    export const formatTimeAgo = (d: Date | string | number) => dayjs(d).fromNow();
    ```
- **Form Layouts (Dialog vs. Subpage)**:
  - **Few fields** (quick edits, create tag, login, short inputs): Use a **Dialog / Modal**.
  - **Many fields / Complex forms** (student enrollment, multi-section profiles): Use a **Dedicated Subpage route** (e.g. `/students/new`). Never cram long forms into cramped modals.
- **Custom Confirmation Dialogs (Strict Policy)**:
  - **NEVER use native browser alerts (`window.confirm()`, `window.alert()`)**.
  - Always use a styled **Confirmation Dialog** with a warning icon, clear descriptive message, Cancel button, and styled Destructive action button (e.g. red/danger).
- **Navigation & Hierarchy (Breadcrumbs)**:
  - On nested routes or subpages (e.g. `Dashboard > Students > Juan Dela Cruz > Edit`), always render a **Breadcrumbs** trail so users never get lost and have 1-click ancestor navigation.
- **Loading States (Skeleton Loaders)**:
  - Never display a blank screen or a lone spinner for page/data loads.
  - Always render **Skeleton Loaders** (daisyUI skeleton or shadcn skeleton) matching the layout of tables, cards, and detail panels.
- **Empty States (Zero Data Experience)**:
  - When tables or lists have zero records or no search results, render a friendly **Empty State**: an icon (e.g. `lucide-svelte` `SearchX` or `Inbox`), clear explanatory title/text, and an actionable CTA button (*"Add New Student"* or *"Clear Filters"*).
- **Mobile-Responsive Data Tables (Card View)**:
  - On desktop (`md:` and up): Render a clean `<table>`.
  - On mobile screens: Transform the table into **Stacked Cards** (`block md:hidden`) so mobile users scroll vertically without clunky horizontal overflow.
- **Debounced Search Inputs (300ms)**:
  - Add a **300ms debounce** to search inputs using Svelte 5 `$state` timers to prevent hammering the server/database on every single keystroke.
- **Button Loading & Double-Click Protection**:
  - On form submissions or async actions, automatically disable the submit button and display a loading indicator (*"Saving..."* / spinner) to prevent duplicate submissions.
- **Numbered Pagination**:
  - For data-heavy tables, prefer **Numbered Pagination** (Page X of Y) with an items-per-page selector (10, 25, 50) and total record counts over infinite scrolling.
- **Actionable Toast Feedback**:
  - Always display instant visual feedback on actions using **Toasts** (`svelte-sonner` for shadcn, daisyUI toast for daisyUI): green for success, red for errors.
- **Unsaved Changes Guard (Dirty Forms)**:
  - On extensive forms, track dirty state with `$state` and prompt a confirmation dialog using SvelteKit's `beforeNavigate` if the user attempts to leave with unsaved input.
- **Routing & Navigation Conventions**:
  - **Dashboard Route**: When building an app with a dashboard, map the main dashboard to the root `'/'` route, **NOT** `'/dashboard'`.
  - **Layout Clarification**: Always ask the user beforehand: Do they need a collapsible Sidebar (especially for admin dashboards), or just a Top AppBar with a Drawer?

---

## 4. Fullstack & Backend Architecture
- **Primary Fullstack Framework**: **SvelteKit Fullstack** (TypeScript + Drizzle ORM + Better Auth).
  - Server routes & Form Actions (`+page.server.ts`) handle mutations and business logic.
  - API Endpoints (`+server.ts`) for JSON APIs, webhooks, and PDF streams.
- **Primary Database**: **MySQL** by default (via Drizzle ORM / mysql2). Use PostgreSQL only if explicitly requested.
- **Secondary Backend (Microservices)**: **FastAPI** with Python for AI models, computer vision, or data science workloads.
- **ORM & Migrations**:
  - Use **Drizzle ORM** with clean relational queries (`db.query`).
  - Prototyping: Use `drizzle-kit push` for fast local iterations.
  - Production: Use `drizzle-kit generate` to inspect and apply SQL migration files.
- **Database Seeding**:
  - Always provide a seed script (`db/seed.ts` for Node/TS or `scripts/seed.py` for Python) with realistic dummy/mock data for quick testing.
- **Authentication**:
  - Use **Better Auth** with the Drizzle MySQL adapter. Standard baseline: Email & Password + OAuth (Google/GitHub).

---

## 5. Campus Document & PDF Generation
- **Engine**: Always use **`pdf-lib`** + **`@pdf-lib/fontkit`** for campus documents (COR, Grade Slip, DTR, Certificates).
- **Core Standard**:
  - Avoid heavy headless browsers (Puppeteer); `pdf-lib` renders in 10ms with <15MB RAM.
  - Standardize official documents with **`renderCtuHeader`** (CTU letterhead with configurable department, website, and tel. no.).
  - Use alignment helpers: `renderText` (left), `renderCenteredText` (center), `renderRightText` (right).
  - Use `renderTable` for dynamic tabular grids (grades, enrolled courses, assessment fees).
  - Watermarks: Render translucent official CTU seal (`0.08` opacity) clipped to the document canvas.
  - Verification: Include dynamic QR codes (`qrcode` package) for authenticating document validity.

---

## 6. Embedded Systems & IoT (ESP32)
- **Toolchain**: **PlatformIO** with the **Arduino Framework (C++)**.
- **Architecture**: **FreeRTOS** dual-core task pinning.
  - Core 0: Wi-Fi, MQTT, AsyncWebServer, ElegantOTA.
  - Core 1: High-priority sensor sampling, hardware control loops.
- **Strict Zero-`delay()` Standard**: Never use blocking `delay()`; always use `vTaskDelay(pdMS_TO_TICKS(...))` or non-blocking timer loops.
- **WebUI & Configuration Dashboard**: Build the frontend with **SvelteKit (`@sveltejs/adapter-static` with `precompress: true`)** exporting directly into PlatformIO's `data/www` LittleFS partition (<20KB gzipped bundle). Serve via **`ESPAsyncWebServer`** with REST endpoints (`/api/config`, `/api/status`, `/api/restart`) persisting settings to **`Preferences` (NVS)** or **`LittleFS`**.
- **Web Browser OTA**: Integrate **`ElegantOTA`** on `/update` for drag-and-drop browser firmware flashing.
- **Network Resilience**: Implement non-blocking Wi-Fi reconnection + a circular **RAM ring buffer** so sensor telemetry is preserved during outages and flushed upon reconnect.
- **Logging**: Use ESP-IDF tagged logging (`ESP_LOGI`, `ESP_LOGW`, `ESP_LOGE`).

---

## 7. DevOps & Containerization
- **Docker**: Provide a production-ready `Dockerfile` and `docker-compose.yml` for reproducible local environments and easy deployment to VPS / self-hosted servers.

---

## 8. Coding Style & Clean Code
- **Simplicity First**: Write the simplest, cleanest code that solves the problem. No bloated abstractions or premature generalizations.
- **Early Returns**: Use guard clauses to exit early and avoid deep nesting.
- **Surgical Edits**: Touch only the lines directly related to the user's task.

---

## 9. Verification Protocol (Never Declare Done Blindly)
Before reporting that any task or feature is complete:
1. Run the project's type-checker / linter / test command:
   - For TS/Svelte: `pnpm check` (or build)
   - For Python: `uv run pyright` or syntax check / tests
2. Verify that there are zero regression errors.
3. Only declare complete once verified.
