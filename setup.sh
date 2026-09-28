#!/usr/bin/env bash
# =============================================================================
# Automated Antigravity & Gemini Skills Setup for Jimmy's Environment (Linux/macOS)
# =============================================================================

set -e

echo ""
echo "========================================================"
echo "   Jimmy's Antigravity Skills & Preferences Installer   "
echo "========================================================"
echo ""

GEMINI_CONFIG_DIR="$HOME/.gemini/config"
PLUGINS_DIR="$GEMINI_CONFIG_DIR/plugins"
GLOBAL_SKILLS_DIR="$GEMINI_CONFIG_DIR/skills"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$PLUGINS_DIR"
mkdir -p "$GLOBAL_SKILLS_DIR"

download_skill() {
  local url="$1"
  local out_file="$2"
  mkdir -p "$(dirname "$out_file")"
  
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL -H "User-Agent: Mozilla/5.0" "$url" -o "$out_file"
  elif command -v wget >/dev/null 2>&1; then
    wget -q --user-agent="Mozilla/5.0" "$url" -O "$out_file"
  else
    echo "Error: Neither curl nor wget found."
    return 1
  fi
}

# -----------------------------------------------------------------------------
# 1. Install Jimmy's Personal Preferences & Rules
# -----------------------------------------------------------------------------
echo "[1/4] Installing jimcan-dev-preferences..."

SRC_PREF="$REPO_ROOT/plugins/jimcan-dev-preferences"
DEST_PREF="$PLUGINS_DIR/jimcan-dev-preferences"

if [ -d "$SRC_PREF" ]; then
  cp -R "$SRC_PREF" "$PLUGINS_DIR/"
  
  # Also sync skill to global skills folder
  SKILL_SRC="$SRC_PREF/skills/jimcan-dev-preferences"
  if [ -d "$SKILL_SRC" ]; then
    cp -R "$SKILL_SRC" "$GLOBAL_SKILLS_DIR/"
  fi
  echo "  -> Installed jimcan-dev-preferences (plugin & global skill)"
else
  echo "Warning: Source directory $SRC_PREF not found!"
fi

# -----------------------------------------------------------------------------
# 2. Download / Install Andrej Karpathy Skills
# -----------------------------------------------------------------------------
echo ""
echo "[2/4] Installing andrej-karpathy-skills..."

KARPATHY_DEST="$PLUGINS_DIR/andrej-karpathy-skills"

if command -v git >/dev/null 2>&1; then
  if [ -d "$KARPATHY_DEST/.git" ]; then
    echo "  -> Updating existing repo at $KARPATHY_DEST..."
    git -C "$KARPATHY_DEST" pull --quiet
  else
    rm -rf "$KARPATHY_DEST"
    echo "  -> Cloning https://github.com/multica-ai/andrej-karpathy-skills.git..."
    git clone --depth 1 https://github.com/multica-ai/andrej-karpathy-skills.git "$KARPATHY_DEST" --quiet
  fi
else
  echo "Warning: Git not found. Skipping clone of andrej-karpathy-skills."
fi

# Sync Karpathy skills to global skills directory
if [ -d "$KARPATHY_DEST/skills" ]; then
  for s in "$KARPATHY_DEST/skills"/*; do
    if [ -d "$s" ]; then
      cp -R "$s" "$GLOBAL_SKILLS_DIR/"
    fi
  done
  echo "  -> Synced karpathy skills to global directory"
fi

# -----------------------------------------------------------------------------
# 3. Download & Install UI Design Skills (Svelte 5, daisyUI, shadcn)
# -----------------------------------------------------------------------------
echo ""
echo "[3/4] Downloading UI Design Skills..."

UI_PLUGIN_DIR="$PLUGINS_DIR/ui-design-skills"
mkdir -p "$UI_PLUGIN_DIR"

cat << 'EOF' > "$UI_PLUGIN_DIR/plugin.json"
{
  "name": "ui-design-skills",
  "displayName": "UI Design System Skills",
  "version": "1.0.0",
  "description": "Svelte, Svelte 5, shadcn-svelte, and daisyUI skills"
}
EOF

declare -A UI_SKILLS=(
  ["shadcn-svelte"]="https://raw.githubusercontent.com/huntabyte/shadcn-svelte/main/skills/shadcn-svelte/SKILL.md"
  ["svelte-core-bestpractices"]="https://raw.githubusercontent.com/sveltejs/ai-tools/main/tools/skills/svelte-core-bestpractices/SKILL.md"
  ["svelte-code-writer"]="https://raw.githubusercontent.com/sveltejs/ai-tools/main/tools/skills/svelte-code-writer/SKILL.md"
  ["svelte5-best-practices"]="https://raw.githubusercontent.com/ejirocodes/agent-skills/main/svelte/skills/svelte5-best-practices/SKILL.md"
  ["daisyui"]="https://raw.githubusercontent.com/saadeghi/daisyui/master/skills/daisyui/SKILL.md"
)

for sname in "${!UI_SKILLS[@]}"; do
  surl="${UI_SKILLS[$sname]}"
  plugin_skill="$UI_PLUGIN_DIR/skills/$sname/SKILL.md"
  global_skill="$GLOBAL_SKILLS_DIR/$sname/SKILL.md"
  
  if download_skill "$surl" "$plugin_skill"; then
    mkdir -p "$(dirname "$global_skill")"
    cp "$plugin_skill" "$global_skill"
    echo "  -> Downloaded: $sname"
  fi
done

# -----------------------------------------------------------------------------
# 4. Download & Install Backend & Database Skills
# -----------------------------------------------------------------------------
echo ""
echo "[4/4] Downloading Backend & Database Skills..."

BACKEND_PLUGIN_DIR="$PLUGINS_DIR/backend-db-skills"
mkdir -p "$BACKEND_PLUGIN_DIR"

cat << 'EOF' > "$BACKEND_PLUGIN_DIR/plugin.json"
{
  "name": "backend-db-skills",
  "displayName": "Backend & Database Skills",
  "version": "1.0.0",
  "description": "FastAPI, Drizzle ORM, Better Auth, PostgreSQL, and MySQL skills"
}
EOF

declare -A BACKEND_SKILLS=(
  ["fastapi-patterns"]="https://raw.githubusercontent.com/affaan-m/ecc/main/skills/fastapi-patterns/SKILL.md"
  ["drizzle-best-practices"]="https://raw.githubusercontent.com/honra-io/drizzle-best-practices/main/SKILL.md"
  ["better-auth-best-practices"]="https://raw.githubusercontent.com/better-auth/skills/main/better-auth/best-practices/SKILL.md"
  ["postgres-patterns"]="https://raw.githubusercontent.com/affaan-m/ecc/main/skills/postgres-patterns/SKILL.md"
  ["supabase-postgres-best-practices"]="https://raw.githubusercontent.com/supabase/agent-skills/main/skills/supabase-postgres-best-practices/SKILL.md"
  ["mysql-patterns"]="https://raw.githubusercontent.com/affaan-m/ecc/main/skills/mysql-patterns/SKILL.md"
  ["planetscale-mysql"]="https://raw.githubusercontent.com/planetscale/database-skills/main/skills/mysql/SKILL.md"
)

for sname in "${!BACKEND_SKILLS[@]}"; do
  surl="${BACKEND_SKILLS[$sname]}"
  plugin_skill="$BACKEND_PLUGIN_DIR/skills/$sname/SKILL.md"
  global_skill="$GLOBAL_SKILLS_DIR/$sname/SKILL.md"

  if download_skill "$surl" "$plugin_skill"; then
    mkdir -p "$(dirname "$global_skill")"
    cp "$plugin_skill" "$global_skill"
    echo "  -> Downloaded: $sname"
  fi
done

echo ""
echo "========================================================"
echo "   Setup Completed Successfully!                        "
echo "========================================================"
echo "Installed in: $GEMINI_CONFIG_DIR"
echo "Your Antigravity agent is now configured with Jimmy's preferences."
echo ""
