# jimcan-skills

> **Jimcan's (Jimboy Cantila) Universal AI Agent Preferences, Skills & Grill-Me Toolkit**  
> *Compatible with any AI coding agent: Claude Code, Cursor, Windsurf, Antigravity, Codex, etc.*

This repository contains my personal development standards, behavioral agent rules, and an automated setup system to bootstrap **any AI coding agent** on any device or workspace in seconds.

To keep the repository clean and lightweight, only personal preferences, system prompts, and installer scripts are version-controlled. All external and community-curated skills are dynamically fetched and installed upon setup.

---

## 🚀 The AI Agent Bootstrap Prompt

Whenever opening a project on a new computer or starting a fresh AI assistant session (even if this repo hasn't been downloaded yet), simply copy-paste this prompt directly into your AI agent:

```markdown
You are my expert AI pair programmer. Before doing any development work or touching project files, complete the following onboarding sequence:

1. Clone & Install Skills:
   - Check if my skills repo exists. If not, clone it:
     git clone https://github.com/jimcan92/jimcan-skills.git "$HOME/.jimcan-skills"
   - Run the automated installer:
     - On Windows PowerShell:
       powershell -ExecutionPolicy Bypass -File "$HOME\.jimcan-skills\setup.ps1"
     - On macOS / Linux / WSL:
       chmod +x "$HOME/.jimcan-skills/setup.sh" && "$HOME/.jimcan-skills/setup.sh"
   - Verify that jimcan-dev-preferences and all curated skills are properly installed.

2. Adopt My Guidelines & Conventions:
   - Read and strictly adhere to the guidelines in "$HOME/.jimcan-skills/prompts/agent-system-prompt.md" and "$HOME/.jimcan-skills/plugins/jimcan-dev-preferences/rules/AGENTS.md".
   - Address me as Jimcan (Jimboy Cantila).
   - Chat & explanations in Bisaya / Taglish; code, comments, documentation, and Git commits in 100% English.
   - My stack: SvelteKit Fullstack (Svelte 5 runes, daisyUI or shadcn-svelte exclusively, Drizzle ORM + MySQL, Better Auth), pdf-lib campus PDF engine, ESP32 PlatformIO embedded, pnpm, uv.

3. Grill Me (Mandatory Before Coding):
   - Once setup is complete, inspect my current workspace/project.
   - If starting a new project, feature, or if requirements/architecture are underspecified:
     - DO NOT start coding immediately.
     - Relentlessly grill me: Ask probing questions about edge cases, architectural tradeoffs, database models, and UI layout (Sidebar vs Top AppBar/Drawer).
     - Surface your recommended choices first, explain the tradeoffs briefly, present a verifiable step-by-step plan ([Step] -> verify: [check]), and wait for my confirmation before modifying or creating any code files.

Confirm when setup is finished and ask your first set of questions to grill me.
```

*(You can also find this prompt in [`prompts/bootstrap-prompt.md`](prompts/bootstrap-prompt.md))*

---

## ⚡ Quickstart (Manual 1-Command Setup)

If you prefer to run the setup command yourself:

### Windows (PowerShell)
```powershell
git clone https://github.com/jimcan92/jimcan-skills.git
cd jimcan-skills
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

### macOS / Linux / WSL (Bash)
```bash
git clone https://github.com/jimcan92/jimcan-skills.git
cd jimcan-skills
chmod +x setup.sh && ./setup.sh
```

**What the setup script does:**
1. Installs `jimcan-dev-preferences` (standards and rules) into the global configuration directory.
2. Clones and links `andrej-karpathy-skills` from upstream.
3. Downloads the latest **UI Design skills** (`svelte5-best-practices`, `shadcn-svelte`, `daisyui`, `svelte-core-bestpractices`, `svelte-code-writer`).
4. Downloads the latest **Backend & Database skills** (`fastapi-patterns`, `drizzle-best-practices`, `better-auth-best-practices`, `mysql-patterns`, `planetscale-mysql`, `postgres-patterns`, `supabase-postgres-best-practices`).
5. Registers all skills and rules globally so any agent tool instantly recognizes them.

---

## 📁 Repository Structure

```text
jimcan-skills/
├── plugins/
│   ├── jimcan-dev-preferences/
│   │   ├── plugin.json               # Plugin manifest
│   │   ├── rules/
│   │   │   └── AGENTS.md             # Mandatory rules & Grill-Me protocol
│   │   └── skills/
│   │       └── jimcan-dev-preferences/
│   │           └── SKILL.md          # Personal dev standards & stack conventions
│   ├── embedded-esp32-skills/
│   │   ├── plugin.json               # ESP32 plugin manifest
│   │   └── skills/
│   │       └── esp32-embedded-patterns/
│   │           └── SKILL.md          # Production FreeRTOS, PlatformIO, WebServer & OTA patterns
│   └── campus-pdf-patterns/
│       ├── plugin.json               # Campus PDF plugin manifest
│       └── skills/
│           └── campus-pdf-patterns/
│               └── SKILL.md          # CTU Letterhead, alignment helpers, tables, watermarks, QR codes
├── prompts/
│   ├── bootstrap-prompt.md           # 1-copy onboarding prompt for fresh AI sessions (auto-cloning)
│   └── agent-system-prompt.md        # Complete universal AI agent system prompt
├── setup.ps1                         # Windows PowerShell automated installer
├── setup.sh                          # Linux / macOS Bash automated installer
├── .gitignore                        # Git ignores
└── README.md                         # Documentation & Quickstart
```

---

## 🧠 Core Philosophy & Standards

### 1. Mandatory Behavioral Guidelines (Karpathy + Planning First)
- **Plan & Clarify First**: Never jump straight to code on non-trivial tasks. Surface trade-offs, ask questions, present a step-by-step verifiable plan, and wait for confirmation.
- **The Grill-Me Protocol**: If requirements or architecture have ambiguities, the agent must aggressively interview Jimcan with targeted questions and recommendations before proposing a plan.
- **Think Before Coding**: State assumptions explicitly; don't hide confusion.
- **Simplicity First**: Write the minimum code needed to solve the problem. Nothing speculative.
- **Surgical Changes**: Only modify what is strictly required; clean up after yourself.
- **Goal-Driven Execution**: Define verifiable steps `[Step] -> verify: [check]`.

### 2. Jimcan's Tech Stack
- **Communication**: Bisaya / Taglish for chat & explanations; 100% English for code, comments, documentation, and Git commits. Address the user as **Jimcan** (Jimboy Cantila).
- **Package Management**: Always `pnpm` for JavaScript/TypeScript; always `uv` for Python.
- **Frontend**: Svelte 5 with Runes (`$state`, `$derived`, `$props`, snippets).
  - State files centralized in `$lib/states/*.svelte.ts`.
  - Shared functions/helpers in `$lib/utils/`.
  - Forms: Native HTML5 forms + Svelte 5 runes (`$state` validation). Modal/Dialog for short forms; dedicated subpage for complex forms.
  - Confirmations: Styled confirmation dialogs only (strictly no native `confirm()`/`alert()`).
  - Navigation & Hierarchy: Breadcrumbs on nested routes.
  - Loading & Empty States: Skeleton loaders matching component layout; descriptive empty states with CTA.
  - Dates: Standardize on `dayjs` (`$lib/utils/date.ts`).
  - UX Polish: Responsive mobile card tables (`block md:hidden`), 300ms debounced search, submit button loading states, numbered pagination, and unsaved changes dirty form guard.
  - Icons: `lucide-svelte`.
  - Strict UI Separation & Component Priority: **Never mix `shadcn-svelte` and `daisyUI`** in one project. Always check catalog first; exhaustively use built-in components instead of hand-crafted elements.
  - Theming & Aura: Curated 3–5 themes for daisyUI with **Color Swatches Preview** in the selector; custom accent color for shadcn-svelte (`mode-watcher`). Apply daisyUI **`.aura`** / `.aura-glow` to primary CTAs and highlighted elements.
  - Dashboard route: Main dashboard mapped to `'/'`, never `'/dashboard'`.
  - Layout: Mobile-first responsive design; clarify Sidebar vs Drawer/TopBar.
- **Fullstack & Backend**: **SvelteKit Fullstack** (TypeScript + Drizzle ORM + MySQL + Better Auth) as primary stack; FastAPI (Python) for AI microservices.
- **Campus Document & PDF Generation**: Always use **`pdf-lib`** + `@pdf-lib/fontkit` for institutional systems (10ms generation, no Chromium). Standardized CTU letterhead (`renderCtuHeader`), alignment helpers (`renderText`, `renderCenteredText`, `renderRightText`), `renderTable`, watermarks, and verification QR codes.
- **Embedded & IoT (ESP32)**: PlatformIO with Arduino Framework (C++). FreeRTOS multi-core tasks (Core 0: Network/Web/OTA; Core 1: Sensors/Real-time). Strict NO `delay()` standard. WebUI built with **SvelteKit (`@sveltejs/adapter-static`)** precompressed into LittleFS; onboard `ESPAsyncWebServer` for config dashboard (persisting to `Preferences` / `LittleFS`) and Web OTA (`ElegantOTA` on `/update`). RAM ring buffer for offline telemetry resilience.
- **DevOps**: Dockerfile + `docker-compose.yml` for local reproducibility and deployments.
- **Verification**: Run `pnpm check` (or build) / Python typecheck before declaring tasks complete.

---

## 🔄 Updating or Adding Skills

- To modify personal preferences, edit [`plugins/jimcan-dev-preferences/skills/jimcan-dev-preferences/SKILL.md`](plugins/jimcan-dev-preferences/skills/jimcan-dev-preferences/SKILL.md) and commit.
- To re-sync to your local machine, run `.\setup.ps1` or `./setup.sh`.
