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
- **Routing & Navigation Conventions**:
  - **Dashboard Route**: When building an app with a dashboard, map the main dashboard to the root `'/'` route, **NOT** `'/dashboard'`.
  - **Layout Clarification**: Always ask the user beforehand: Do they need a collapsible Sidebar (especially for admin dashboards), or just a Top AppBar with a Drawer?

---

## 4. Backend & Database Architecture
- **Primary Database**: **MySQL** by default (via Drizzle ORM / PlanetScale driver or mysql2). Use PostgreSQL only if explicitly requested for that project.
- **Backend Framework**: **FastAPI** with Python.
  - **Layered Modular Layout**:
    ```text
    backend/
    ├── core/          # config.py, security, database session
    ├── routers/       # APIRouter modules for each endpoint group
    ├── schemas/       # Pydantic v2 schemas for request/response validation
    ├── services/      # Business logic & transactional operations
    ├── models/        # Database tables & Drizzle/ORM schema definitions
    └── main.py        # App entrypoint & middleware configuration
    ```
- **ORM & Migrations**:
  - Use **Drizzle ORM** with clean relational queries (`db.query`).
  - Prototyping: Use `drizzle-kit push` for fast local iterations.
  - Production: Use `drizzle-kit generate` to inspect and apply SQL migration files.
- **Database Seeding**:
  - Always provide a seed script (`db/seed.ts` for Node/TS or `scripts/seed.py` for Python) with realistic dummy/mock data for quick testing.
- **Authentication**:
  - Use **Better Auth** with the Drizzle MySQL adapter.
  - Standard baseline: Email & Password + OAuth (Google/GitHub).

---

## 5. Embedded Systems & IoT (ESP32)
- **Toolchain**: **PlatformIO** with the **Arduino Framework (C++)**.
- **Architecture**: **FreeRTOS** dual-core task pinning.
  - Core 0: Wi-Fi, MQTT, AsyncWebServer, ElegantOTA.
  - Core 1: High-priority sensor sampling, hardware control loops.
- **Strict Zero-`delay()` Standard**: Never use blocking `delay()`; always use `vTaskDelay(pdMS_TO_TICKS(...))` or non-blocking timer loops.
- **Configuration Dashboard**: Build an onboard **`ESPAsyncWebServer`** with REST endpoints (`/api/config`, `/api/status`, `/api/restart`) persisting settings to **`Preferences` (NVS)** or **`LittleFS`** to avoid re-flashing.
- **Web Browser OTA**: Integrate **`ElegantOTA`** on `/update` for drag-and-drop browser firmware flashing.
- **Network Resilience**: Implement non-blocking Wi-Fi reconnection + a circular **RAM ring buffer** so sensor telemetry is preserved during outages and flushed upon reconnect.
- **Logging**: Use ESP-IDF tagged logging (`ESP_LOGI`, `ESP_LOGW`, `ESP_LOGE`).

---

## 6. DevOps & Containerization
- **Docker**: Provide a production-ready `Dockerfile` and `docker-compose.yml` for reproducible local environments and easy deployment to VPS / self-hosted servers.

---

## 7. Coding Style & Clean Code
- **Simplicity First**: Write the simplest, cleanest code that solves the problem. No bloated abstractions or premature generalizations.
- **Early Returns**: Use guard clauses to exit early and avoid deep nesting.
- **Surgical Edits**: Touch only the lines directly related to the user's task.

---

## 8. Verification Protocol (Never Declare Done Blindly)
Before reporting that any task or feature is complete:
1. Run the project's type-checker / linter / test command:
   - For TS/Svelte: `pnpm check` (or build)
   - For Python: `uv run pyright` or syntax check / tests
2. Verify that there are zero regression errors.
3. Only declare complete once verified.
