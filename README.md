# jimcan-skills

> **Jimmy's Antigravity Agent Preferences & Automated Skills Toolkit**

This repository contains my personal development standards, behavioral agent rules, and an automated setup system to bootstrap any Google Antigravity / Gemini agent across any workstation in seconds.

To keep the repository lightweight, only personal preferences, system prompts, and installer scripts are version-controlled. All external and community-curated skills are dynamically fetched and installed upon setup.

---

## ⚡ Quickstart (1-Command Setup)

Whenever setting up on a new device or laptop:

### Windows (PowerShell)
```powershell
git clone https://github.com/jimcan/jimcan-skills.git
cd jimcan-skills
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

### macOS / Linux / WSL (Bash)
```bash
git clone https://github.com/jimcan/jimcan-skills.git
cd jimcan-skills
chmod +x setup.sh && ./setup.sh
```

The installer will:
1. Copy `jimcan-dev-preferences` (standards and rules) into `~/.gemini/config/plugins/`.
2. Clone and link `andrej-karpathy-skills` directly from upstream.
3. Fetch the latest `ui-design-skills` (Svelte 5 runes, daisyUI, shadcn-svelte).
4. Fetch the latest `backend-db-skills` (FastAPI, Drizzle ORM, MySQL, Better Auth).
5. Register all skills globally in `~/.gemini/config/skills/` for instant agent recognition.

---

## 📁 Repository Structure

```text
jimcan-skills/
├── plugins/
│   └── jimcan-dev-preferences/
│       ├── plugin.json                    # Plugin manifest
│       ├── rules/
│       │   └── AGENTS.md                  # Mandatory agent behavioral rules & stack standards
│       └── skills/
│           └── jimcan-dev-preferences/
│               └── SKILL.md               # Detailed stack preferences & conventions
├── prompts/
│   └── agent-system-prompt.md             # Universal agent system prompt (Cursor, Claude, etc.)
├── setup.ps1                              # Windows PowerShell automated installer
├── setup.sh                               # Linux / macOS Bash automated installer
├── .gitignore                             # OS and temporary file ignores
└── README.md                              # Documentation
```

---

## 🧠 Core Philosophy & Standards

### 1. Mandatory Behavioral Guidelines (Karpathy + Planning First)
- **Plan & Clarify First**: Never jump straight to code on non-trivial tasks. Surface trade-offs, ask questions, present a step-by-step verifiable plan, and wait for confirmation.
- **Think Before Coding**: State assumptions explicitly; don't hide ambiguity.
- **Simplicity First**: Write the minimum code needed to solve the problem. Nothing speculative.
- **Surgical Changes**: Only modify what is strictly required; clean up after yourself.
- **Goal-Driven Execution**: Define verifiable steps `[Step] -> verify: [check]`.

### 2. Jimmy's Tech Stack
- **Communication**: Bisaya / Taglish for chat & explanations; 100% English for code, comments, documentation, and Git commits.
- **Package Management**: Always `pnpm` for JavaScript/TypeScript; always `uv` for Python.
- **Frontend**: Svelte 5 with Runes (`$state`, `$derived`, `$props`, snippets).
  - State files centralized in `$lib/states/*.svelte.ts`.
  - Shared functions/helpers in `$lib/utils/`.
  - Forms: Native HTML5 forms + Svelte 5 runes (`$state` validation).
  - Icons: `lucide-svelte`.
  - Dark Mode: Supported via theme toggle.
  - Strict UI Separation: **Never mix `shadcn-svelte` and `daisyUI` in the same project**—choose one.
  - Dashboard route: Main dashboard mapped to `'/'`, never `'/dashboard'`.
  - Layout: Mobile-first responsive design.
- **Backend & Database**: FastAPI (modular routers/schemas/services) with MySQL (via Drizzle ORM).
- **Authentication**: Better Auth with Drizzle adapter.
- **DevOps**: Dockerfile + `docker-compose.yml` for local reproducibility and deployments.
- **Verification**: Run `pnpm check` (or build) / Python typecheck before declaring tasks complete.

---

## 🤖 Standalone Agent System Prompt

If using other AI assistants (such as Cursor, Windsurf, Claude Projects, or ChatGPT) that cannot directly mount Antigravity plugins, copy and paste the contents of:

👉 [`prompts/agent-system-prompt.md`](prompts/agent-system-prompt.md)

This gives any AI tool the exact same context, behavioral constraints, and stack preferences.

---

## 🔄 Updating or Adding Skills

- To modify your personal preferences, edit [`plugins/jimcan-dev-preferences/skills/jimcan-dev-preferences/SKILL.md`](plugins/jimcan-dev-preferences/skills/jimcan-dev-preferences/SKILL.md) and commit the changes.
- To re-sync changes to your local machine, simply rerun `.\setup.ps1` or `./setup.sh`.
