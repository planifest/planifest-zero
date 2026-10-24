#!/usr/bin/env bash
set -euo pipefail

# RAVINTIO Setup - Configures skills for your agentic coding tool.
#
# Usage:  ./ravintio-zero/setup.sh <tool>
#
# Tools:  claude-code
#
# Each tool's specific config lives in setup/<tool>.sh
# This script handles shared logic only.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILLS_SRC="$SCRIPT_DIR/skills"
WORKFLOWS_SRC="$SCRIPT_DIR/workflows"
SETUP_DIR="$SCRIPT_DIR/setup"

VALID_TOOLS="claude-code"
STRICT_ORCHESTRATOR=false

# Prepended to every node script that writes settings.json (0000034 ADR-002).
# Writes a temporary file in the same folder, then renames it over the target,
# so settings.json is always the old file or the new one. The temporary file
# keeps the original's mode. A failed write removes the temporary file and
# prints one fixed error line, leaving the original untouched.
RAVINTIO_WRITE_SETTINGS_JS='
function writeSettings(sf, text) {
  // Any write fault ends in one fixed line and exit 1, with no absolute path,
  // error code, or stack trace (0000151 req-005). The inner function removes
  // its temporary file before the error reaches this catch.
  try {
    writeSettingsFile(sf, text);
  } catch (_) {
    process.stderr.write("! Error: " + (process.env.RAVINTIO_SETTINGS_REL || "settings.json") +
      " could not be written. Fix its permissions and rerun setup.\n");
    process.exit(1);
  }
}
function writeSettingsFile(sf, text) {
  const fs = require("fs");
  // Write through a symlinked settings.json to its real file, as before.
  let target = sf;
  try { target = fs.realpathSync(sf); } catch (_) {}
  let mode;
  try {
    mode = fs.statSync(target).mode & 0o7777;
    // A read-only settings.json stays unchanged, as it did before the rename.
    fs.accessSync(target, fs.constants.W_OK);
  } catch (err) {
    if (err.code !== "ENOENT") throw err;
  }
  const tmp = target + ".ravintio-tmp";
  // Remove any leftover first, then create the file exclusively, so a
  // planted symlink at the temporary path is never followed.
  try { fs.rmSync(tmp, { force: true }); } catch (_) {}
  let created = false;
  try {
    fs.writeFileSync(tmp, text, { flag: "wx", mode: mode === undefined ? 0o666 : mode });
    created = true;
    if (mode !== undefined) fs.chmodSync(tmp, mode);
    fs.renameSync(tmp, target);
  } catch (err) {
    if (created) { try { fs.unlinkSync(tmp); } catch (_) {} }
    throw err;
  }
}
'

# Prepended to every node script that reads settings.json before it acts on
# the hooks (0000040 req-001, ADR-002). A settings object is a plain object
# whose hooks value is absent, null, or a plain object. The hook install step
# applies the same rule.
RAVINTIO_SETTINGS_SHAPE_JS='
const isPlainObject = v => v !== null && typeof v === "object" && !Array.isArray(v);
const isSettingsObject = s => isPlainObject(s) && (s.hooks == null || isPlainObject(s.hooks));
'

# --- Shared functions ---

copy_skills() {
  local target_dir="$1"

  for skill_dir in "$SKILLS_SRC"/*; do
    if [ -d "$skill_dir" ] && [ -f "$skill_dir/SKILL.md" ]; then
      local skill_name
      skill_name="$(basename "$skill_dir")"
      local dest_dir="$target_dir/$skill_name"
      
      mkdir -p "$dest_dir"
      cp "$skill_dir/SKILL.md" "$dest_dir/SKILL.md"

      # Rewrite relative paths to match bundled directory structure
      sed -i.bak \
        -e 's|\.\./templates/|./assets/templates/|g' \
        -e 's|\.\./standards/|./references/|g' \
        -e 's|\.\./standards/reference/|./references/reference/|g' \
        -e 's|\.\./schemas/|./assets/schemas/|g' \
        "$dest_dir/SKILL.md" && rm -f "$dest_dir/SKILL.md.bak"

      echo "  + $skill_name/SKILL.md"
      
      for opt_dir in scripts assets references; do
        if [ -d "$skill_dir/$opt_dir" ]; then
          cp -r "$skill_dir/$opt_dir" "$dest_dir/"
        fi
      done
      
      # Selective bundling: read bundle_templates and bundle_standards from SKILL.md frontmatter
      local skill_md="$skill_dir/SKILL.md"
      
      # Parse frontmatter: awk handles identical start/end --- delimiters correctly
      local frontmatter
      frontmatter=$(awk '/^---$/{c++; if(c==2) exit; next} c==1{print}' "$skill_md")

      # Parse bundle_templates from frontmatter
      local bundle_templates
      bundle_templates=$(echo "$frontmatter" | grep '^bundle_templates:' | sed 's/bundle_templates: *\[//;s/\]//;s/,/ /g;s/^ *//;s/ *$//' || true)

      # Parse bundle_standards from frontmatter
      local bundle_standards
      bundle_standards=$(echo "$frontmatter" | grep '^bundle_standards:' | sed 's/bundle_standards: *\[//;s/\]//;s/,/ /g;s/^ *//;s/ *$//' || true)
      
      # Bundle only declared templates (or all if no manifest found)
      if [ -d "$SCRIPT_DIR/templates" ]; then
        mkdir -p "$dest_dir/assets/templates"
        if [ -n "$bundle_templates" ]; then
          for tpl in $bundle_templates; do
            local tpl_path="$SCRIPT_DIR/templates/$tpl"
            if [ -f "$tpl_path" ]; then
              cp "$tpl_path" "$dest_dir/assets/templates/"
            fi
          done
          echo "    templates: selective ($(echo $bundle_templates | wc -w | tr -d ' ') files)"
        else
          cp -r "$SCRIPT_DIR/templates"/* "$dest_dir/assets/templates/"
          echo "    templates: all (no manifest)"
        fi
      fi
      
      # Always bundle schemas (small, universally needed)
      if [ -d "$SCRIPT_DIR/schemas" ]; then
        mkdir -p "$dest_dir/assets/schemas"
        cp -r "$SCRIPT_DIR/schemas"/* "$dest_dir/assets/schemas/"
      fi
      
      # Bundle only declared standards (or all if no manifest found)
      if [ -d "$SCRIPT_DIR/standards" ]; then
        mkdir -p "$dest_dir/references"
        if [ -n "$bundle_standards" ]; then
          for std in $bundle_standards; do
            local std_path="$SCRIPT_DIR/standards/$std"
            if [ -f "$std_path" ]; then
              cp "$std_path" "$dest_dir/references/"
            fi
          done
          echo "    standards: selective ($(echo $bundle_standards | wc -w | tr -d ' ') files)"
        else
          # No manifest - copy all top-level standards (skip reference/ subdirectory)
          find "$SCRIPT_DIR/standards" -maxdepth 1 -type f -exec cp {} "$dest_dir/references/" \;
          echo "    standards: all top-level (no manifest)"
        fi
      fi
    fi
  done
}

prune_retired_skills() {
  # Removes any folder in the tool's skills directory whose name is absent
  # from the skills/ source set, so retired skills vanish on regeneration.
  # Scoped to subfolders of the skills directory only. Capability skills from
  # ravintio-overrides/ are copied back in after this prune runs.
  local target_dir="$1"

  [ -d "$target_dir" ] || return 0

  for dest_dir in "$target_dir"/*/; do
    [ -d "$dest_dir" ] || continue
    # Never follow a planted symlink: deleting through it would reach outside
    # the skills directory.
    [ -L "${dest_dir%/}" ] && continue
    local name
    name="$(basename "$dest_dir")"
    if [ ! -d "$SKILLS_SRC/$name" ]; then
      rm -rf "$dest_dir"
      echo "  - pruned retired skill: $name"
    fi
  done
}

write_boot_file() {
  # Boot files are disposable build outputs (0000029 ADR-001): always
  # regenerate from the current template so template fixes propagate on every
  # run. Durable local customization lives in ravintio-overrides/instructions/
  # and is re-applied by append_override_instructions after this write.
  local path="$1"
  local content="$2"

  mkdir -p "$(dirname "$path")"
  if [ ! -f "$path" ]; then
    echo "$content" > "$path"
    echo "  + $(basename "$path") (created)"
  else
    echo "$content" > "$path"
    echo "  ~ $(basename "$path") (regenerated from template)"
  fi
}

copy_capability_skills() {
  # Copies permanent capability skills from ravintio-overrides/capability-skills/
  # to the tool's skills directory (REQ-008, parity with setup.ps1 Copy-CapabilitySkills).
  local target_dir="$1"
  local cap_skills_dir="$PROJECT_ROOT/ravintio-overrides/capability-skills"

  if [ ! -d "$cap_skills_dir" ]; then
    return
  fi

  local found=false
  for skill_dir in "$cap_skills_dir"/*/; do
    [ -d "$skill_dir" ] || continue
    local skill_name
    skill_name="$(basename "$skill_dir")"
    local skill_md="$skill_dir/SKILL.md"

    if [ ! -f "$skill_md" ]; then
      echo "  ! Warning: capability skill '$skill_name' missing SKILL.md — skipping"
      continue
    fi

    local dest_dir="$target_dir/$skill_name"
    mkdir -p "$dest_dir"
    cp "$skill_md" "$dest_dir/SKILL.md"
    echo "  + capability-skill: $skill_name"
    found=true
  done

  if [ "$found" = true ]; then
    echo "  Syncing capability skills from ravintio-overrides/capability-skills/"
  fi
}

append_override_instructions() {
  # Appends project-specific instructions from ravintio-overrides/instructions/
  # into the boot file between sentinel markers (idempotent). (REQ-006, REQ-007,
  # parity with setup.ps1 Append-OverrideInstructions).
  local boot_file="$PROJECT_ROOT/$1"
  local instr_dir="$PROJECT_ROOT/ravintio-overrides/instructions"
  local start_marker="<!-- ravintio-overrides:instructions:start -->"
  local end_marker="<!-- ravintio-overrides:instructions:end -->"

  if [ ! -d "$instr_dir" ]; then
    return
  fi

  # Collect .md files (sorted)
  local files=()
  while IFS= read -r f; do
    files+=("$f")
  done < <(find "$instr_dir" -maxdepth 1 -name "*.md" 2>/dev/null | sort)

  if [ "${#files[@]}" -eq 0 ]; then
    return
  fi

  # Idempotent: strip existing override block before re-appending
  if [ -f "$boot_file" ] && command -v node >/dev/null 2>&1; then
    RAVINTIO_BOOT="$boot_file" node -e '
      const fs = require("fs");
      const b = process.env.RAVINTIO_BOOT;
      if (!fs.existsSync(b)) process.exit(0);
      let c = fs.readFileSync(b, "utf8");
      const s = "<!-- ravintio-overrides:instructions:start -->";
      const e = "<!-- ravintio-overrides:instructions:end -->";
      const re = new RegExp("\\n?" + s.replace(/[.*+?^${}()|[\\]\\\\]/g,"\\\\$&") +
        "[\\s\\S]*?" + e.replace(/[.*+?^${}()|[\\]\\\\]/g,"\\\\$&") + "\\n?", "g");
      fs.writeFileSync(b, c.replace(re, ""), "utf8");
    '
  fi

  # Append fresh block
  {
    echo ""
    echo "$start_marker"
    for f in "${files[@]}"; do
      echo ""
      cat "$f"
    done
    echo ""
    echo "$end_marker"
  } >> "$boot_file"

  echo "  Appending override instructions from ravintio-overrides/instructions/"
}


copy_workflow() {
  local workflow_file="$1"
  local target_dir="$2"
  local name
  name="$(basename "$workflow_file" .md)"
  local dest_file="$target_dir/${name}.md"

  mkdir -p "$target_dir"
  cp "$workflow_file" "$dest_file"
  echo "  + workflows/${name}.md"
}

remove_leftover_settings_tmp() {
  # Remove the temporary file a hard stop left between the write and the
  # rename (0000035 ADR-003, backlog 0000104). Runs before the first
  # settings.json writer, and needs no node. rm -f removes a link, not its
  # target, and the file test skips a folder.
  local tmp="$PROJECT_ROOT/$1.ravintio-tmp"
  if [ -L "$tmp" ] || [ -f "$tmp" ]; then
    rm -f "$tmp" 2>/dev/null || true
  fi
}

# The retired-hooks list (0000151 ADR-007). install_enforcement_hooks deletes an
# installed hook named here and never one absent from it. Retiring a hook means
# adding its name here and in setup.ps1.
RETIRED_HOOK_NAMES="emit-phase-start emit-phase-end emit-event-receipt emit-event context-pressure resolve-phase record-telemetry-failure check-telemetry-failures check-telemetry-receipts phase-enum"

prune_retired_hooks() {
  # Delete each installed hook whose base name is on RETIRED_HOOK_NAMES
  # (0000151 req-004, ADR-007). Checks the whole hooks tree, enforcement/
  # included, prints one line per removal, and prints nothing otherwise.
  local hooks_root_rel="$1"   # e.g. .claude/hooks
  local root="$PROJECT_ROOT/$hooks_root_rel"
  [ -d "$root" ] || return 0
  local name file
  for name in $RETIRED_HOOK_NAMES; do
    while IFS= read -r file; do
      [ -n "$file" ] || continue
      if rm -f "$file" 2>/dev/null; then
        echo "  - removed ${file#"$PROJECT_ROOT"/}"
      fi
    done < <(find "$root" -type f -name "$name.mjs" 2>/dev/null)
  done
}

install_enforcement_hooks() {
  # Copy enforcement hooks and wire PreToolUse/UserPromptSubmit (REQ-002, REQ-006, REQ-008).
  # Includes auto-trigger-orchestrator.mjs (REQ-002), gate-write.mjs, check-design.mjs,
  # check-orchestrator-presence.mjs, ratchet-check.mjs, merge-guard.mjs (0000043 req-006),
  # and em-dash-guard.mjs
  # (req-006, feature 0000028, ADR-003 — rejects U+2014 in scoped RAVINTIO prose
  # paths at write time, sibling to gate-write.mjs and ratchet-check.mjs).
  # Always installed: enforcement applies to every RAVINTIO-enabled project.
  local hooks_src_rel="$1"   # e.g. hooks/enforcement
  local hooks_dir_rel="$2"   # e.g. .claude/hooks/enforcement
  local settings_rel="$3"    # e.g. .claude/settings.json

  local src="$SCRIPT_DIR/$hooks_src_rel"
  local dest="$PROJECT_ROOT/$hooks_dir_rel"
  local settings="$PROJECT_ROOT/$settings_rel"

  if [ ! -d "$src" ]; then
    echo "  ! Warning: enforcement hook scripts not found at $src — skipping"
    return
  fi

  echo ""
  echo "  Installing RAVINTIO enforcement hooks"

  mkdir -p "$dest"
  for script in "$src"/*.mjs; do
    [ -f "$script" ] || continue
    local script_name
    script_name="$(basename "$script")"
    cp "$script" "$dest/$script_name"
    echo "  + $hooks_dir_rel/$script_name"
  done

  prune_retired_hooks "$(dirname "$hooks_dir_rel")"

  # Wire into settings.json (requires node; jq fallback not needed, node is always available)
  #
  # 0000028 (P5, SEC-001): every command below is prefixed with `node`. These
  # were previously wired as bare .mjs paths relying on the shebang plus an
  # executable bit. The bit is a committed file mode, and 9 of the 10 hook
  # files are mode 100644, so the shell could not exec them: the wired command
  # exited 126 (permission denied) and the hook silently never ran. Because a
  # PreToolUse hook that fails to start is indistinguishable from one that
  # passed, gate-write, em-dash-guard, check-design,
  # auto-trigger-orchestrator and check-orchestrator-presence were all dead on
  # every bash install, while ratchet-check worked purely because it happened
  # to be committed executable.
  #
  # Invoking through `node` removes the dependency on file mode entirely. This
  # matches what setup.ps1 already did, which is why the PowerShell install
  # kept working throughout.
  local gate_cmd="node \"$hooks_dir_rel/gate-write.mjs\""
  local ratchet_cmd="node \"$hooks_dir_rel/ratchet-check.mjs\""
  local em_dash_cmd="node \"$hooks_dir_rel/em-dash-guard.mjs\""
  local trigger_cmd="node \"$hooks_dir_rel/auto-trigger-orchestrator.mjs\""
  local presence_cmd="node \"$hooks_dir_rel/check-orchestrator-presence.mjs\""
  local design_cmd="node \"$hooks_dir_rel/check-design.mjs\""
  local merge_guard_cmd="node \"$hooks_dir_rel/merge-guard.mjs\""

  if command -v node >/dev/null 2>&1; then
    RAVINTIO_GATE="$gate_cmd" RAVINTIO_RATCHET="$ratchet_cmd" RAVINTIO_EM_DASH="$em_dash_cmd" RAVINTIO_TRIGGER="$trigger_cmd" RAVINTIO_PRESENCE="$presence_cmd" RAVINTIO_DESIGN="$design_cmd" RAVINTIO_MERGE_GUARD="$merge_guard_cmd" RAVINTIO_RETIRED="$RETIRED_HOOK_NAMES" RAVINTIO_SETTINGS="$settings" RAVINTIO_SETTINGS_REL="$settings_rel" node -e "$RAVINTIO_WRITE_SETTINGS_JS$RAVINTIO_SETTINGS_SHAPE_JS"'
      const fs = require("fs"), path = require("path");
      const gate     = process.env.RAVINTIO_GATE;
      const ratchet  = process.env.RAVINTIO_RATCHET;
      const emDash   = process.env.RAVINTIO_EM_DASH;
      const trigger  = process.env.RAVINTIO_TRIGGER;
      const presence = process.env.RAVINTIO_PRESENCE;
      const design   = process.env.RAVINTIO_DESIGN;
      const mergeGuard = process.env.RAVINTIO_MERGE_GUARD;
      const sf       = process.env.RAVINTIO_SETTINGS;
      let s = {};
      // On invalid JSON, print one fixed line that names the file, write
      // nothing, and exit 1 (0000039 req-001, ADR-002). The parser message
      // can quote file content, so it never reaches the output.
      if (fs.existsSync(sf)) {
        const raw = fs.readFileSync(sf,"utf8").replace(/^\uFEFF/,"");
        try { s = JSON.parse(raw); } catch (_) {
          process.stderr.write("! Error: " + process.env.RAVINTIO_SETTINGS_REL +
            " is not valid JSON. Fix it and rerun setup.\n");
          process.exit(1);
        }
      }
      // Valid JSON that is not a settings object stops setup before any write
      // (0000040 req-001, ADR-002). The top level must be a plain object. A
      // hooks value must be absent, null, or a plain object. The line never
      // includes file content.
      if (!isSettingsObject(s)) {
        process.stderr.write("! Error: " + process.env.RAVINTIO_SETTINGS_REL +
          " is valid JSON but not a settings object setup can read. Fix it and rerun setup.\n");
        process.exit(1);
      }
      s.hooks = s.hooks || {};
      // A present value that is not an array is non-array (0000037 ADR-003).
      // Warn and replace it with the RAVINTIO entries. The warning names the
      // event and the file, never the old value, which can hold a secret
      // (0000041 ADR-003). An absent or null value gets the entries with no
      // warning. setup.ps1 prints the same text.
      for (const ev of ["PreToolUse", "UserPromptSubmit"]) {
        const v = s.hooks[ev];
        if (v === undefined || v === null || Array.isArray(v)) continue;
        process.stderr.write("  ! Warning: hooks." + ev + " in " + process.env.RAVINTIO_SETTINGS_REL +
          " is not an array. Setup replaced it with the RAVINTIO entries.\n");
        s.hooks[ev] = [];
      }
      // Per-command filter (0000038 ADR-002). For each hook entry, remove each
      // RAVINTIO command of that event. Drop the entry if it had commands and
      // none remain. Otherwise keep it with its user commands in their order.
      // A hooks value that is one object counts as a one-item array, and a
      // kept one stays an object (0000039 req-002, ADR-003). Any other
      // non-array value, or an empty array, stays as it was. The fresh
      // RAVINTIO entries are appended afterwards. The match is
      // case-sensitive, and only <module>.mjs at a path boundary counts
      // (0000035 S-004). The rule matches setup.ps1.
      const keepUserCommands = (entries, moduleRe, onDrop) => {
        const kept = [];
        for (const entry of entries) {
          const v = entry && entry.hooks;
          const single = v !== null && typeof v === "object" && !Array.isArray(v);
          const cmds = single ? [v] : v;
          if (!Array.isArray(cmds) || cmds.length === 0) { kept.push(entry); continue; }
          const userCmds = cmds.filter(h => {
            const m = moduleRe.exec(String((h && h.command) || ""));
            if (m && onDrop) onDrop(m[2]);
            return !m;
          });
          if (userCmds.length === 0) continue;
          if (!single && userCmds.length !== cmds.length) entry.hooks = userCmds;
          kept.push(entry);
        }
        return kept;
      };
      // Drop each settings entry that runs a retired hook, on every event
      // (0000151 ADR-007), so no entry names a pruned file. The match is the
      // same path-boundary rule. A non-array event value stays as it was.
      // One line per removed entry names it (0000164 S-005).
      const retired = (process.env.RAVINTIO_RETIRED || "").split(" ").filter(Boolean);
      if (retired.length > 0) {
        const retiredModule = new RegExp("(^|[\\s\"\\x27/\\\\])(" + retired.join("|") + ")\\.mjs\\b");
        for (const ev of Object.keys(s.hooks)) {
          if (Array.isArray(s.hooks[ev])) s.hooks[ev] = keepUserCommands(s.hooks[ev], retiredModule, name =>
            console.log("  - removed retired hook entry " + name + " from " + process.env.RAVINTIO_SETTINGS_REL));
        }
      }
      // PreToolUse: gate-write + ratchet-check + em-dash-guard for Write and Edit,
      // then merge-guard for Bash (0000043 req-006)
      // (idempotent: remove then re-add). Remove the three modules on any
      // matcher, so an old Write|Edit entry goes too (0000037 ADR-003).
      const preToolModule = /(^|[\s"\x27\/\\])(gate-write|ratchet-check|em-dash-guard|merge-guard)\.mjs\b/;
      s.hooks.PreToolUse = keepUserCommands(s.hooks.PreToolUse || [], preToolModule);
      s.hooks.PreToolUse.push(
        {matcher:"Write", hooks:[{type:"command",command:gate}]},
        {matcher:"Edit",  hooks:[{type:"command",command:gate}]},
        {matcher:"Write", hooks:[{type:"command",command:ratchet}]},
        {matcher:"Edit",  hooks:[{type:"command",command:ratchet}]},
        {matcher:"Write", hooks:[{type:"command",command:emDash}]},
        {matcher:"Edit",  hooks:[{type:"command",command:emDash}]},
        {matcher:"Bash",  hooks:[{type:"command",command:mergeGuard}]}
      );
      // UserPromptSubmit: auto-trigger first, then presence check, then check-design
      // (REQ-002, REQ-008, idempotent). The same path-boundary match as
      // PreToolUse replaces the old bare substring test (0000038 req-002).
      const promptModule = /(^|[\s"\x27\/\\])(auto-trigger-orchestrator|check-orchestrator-presence|check-design)\.mjs\b/;
      s.hooks.UserPromptSubmit = keepUserCommands(s.hooks.UserPromptSubmit || [], promptModule);
      s.hooks.UserPromptSubmit.push(
        {matcher:".*", hooks:[{type:"command",command:trigger}]},
        {matcher:".*", hooks:[{type:"command",command:presence}]},
        {matcher:".*", hooks:[{type:"command",command:design}]}
      );
      fs.mkdirSync(path.dirname(sf),{recursive:true});
      writeSettings(sf, JSON.stringify(s,null,2)+"\n");
    ' || exit 1
    echo "  ~ $settings_rel (enforcement hooks wired)"
  else
    echo "  ! Warning: node not found — skipping settings.json enforcement hook wiring"
    echo "  ! Manually add gate-write, ratchet-check, em-dash-guard (Write/Edit PreToolUse), merge-guard (Bash PreToolUse), auto-trigger-orchestrator, check-orchestrator-presence and check-design (UserPromptSubmit) to $settings_rel"
  fi
}

merge_allowed_tools() {
  # Idempotently add "Agent" to allowedTools in .claude/settings.json (REQ-002).
  # Preserves existing allowedTools entries — additive merge only.
  # Requires node (always available for Claude Code targets).
  local settings_file="$1"
  # The path relative to the project root, for the error line (0000039 req-001).
  local settings_rel="${settings_file#"$PROJECT_ROOT"/}"

  if command -v node >/dev/null 2>&1; then
    RAVINTIO_SETTINGS="$settings_file" RAVINTIO_SETTINGS_REL="$settings_rel" node -e "$RAVINTIO_WRITE_SETTINGS_JS"'
      const fs = require("fs"), path = require("path");
      const sf = process.env.RAVINTIO_SETTINGS;
      let s = {};
      // The same fixed line and exit 1 as the hook install step, with no file
      // content in the output (0000039 req-001).
      if (fs.existsSync(sf)) {
        const raw = fs.readFileSync(sf,"utf8").replace(/^﻿/,"");
        try { s = JSON.parse(raw); } catch (_) {
          process.stderr.write("! Error: " + process.env.RAVINTIO_SETTINGS_REL +
            " is not valid JSON. Fix it and rerun setup.\n");
          process.exit(1);
        }
      }
      const existing = Array.isArray(s.allowedTools) ? s.allowedTools : [];
      if (!existing.includes("Agent")) {
        s.allowedTools = existing.concat(["Agent"]);
        fs.mkdirSync(path.dirname(sf),{recursive:true});
        writeSettings(sf, JSON.stringify(s,null,2)+"\n");
        console.log("  ~ .claude/settings.json (Agent added to allowedTools)");
      } else {
        console.log("  - .claude/settings.json (Agent already in allowedTools)");
      }
    ' || exit 1
  else
    echo "  ! Warning: node not found — skipping allowedTools update"
    echo "  ! Manually add \"Agent\" to allowedTools in .claude/settings.json"
  fi
}

activate_guardrails() {
  echo ""
  echo "  Activating RAVINTIO Git Guardrails"

  # Point Git to the version-controlled hooks directory
  # Degrade gracefully when not inside a git repository (e.g. test workspaces).
  if git config core.hooksPath ravintio-zero/hooks 2>/dev/null; then
    echo "  + git config core.hooksPath ravintio-zero/hooks"
  else
    echo "  ! Warning: not in a git repository — skipping core.hooksPath config"
  fi

  # Ensure hook scripts are executable (critical for Unix systems)
  chmod +x "$SCRIPT_DIR/hooks/pre-commit"
  chmod +x "$SCRIPT_DIR/hooks/pre-push"
  [ -f "$SCRIPT_DIR/hooks/commit-msg" ] && chmod +x "$SCRIPT_DIR/hooks/commit-msg"
  echo "  + hooks/pre-commit (executable)"
  echo "  + hooks/pre-push (executable)"
  [ -f "$SCRIPT_DIR/hooks/commit-msg" ] && echo "  + hooks/commit-msg (executable)"

  # Deploy the CI/CD pipeline workflow
  local github_workflows="$PROJECT_ROOT/.github/workflows"
  local workflow_src="$SCRIPT_DIR/hooks/ravintio.yml"
  if [ -f "$workflow_src" ]; then
    mkdir -p "$github_workflows"
    if [ ! -f "$github_workflows/ravintio.yml" ]; then
      cp "$workflow_src" "$github_workflows/ravintio.yml"
      echo "  + .github/workflows/ravintio.yml (created)"
    else
      echo "  - .github/workflows/ravintio.yml (already exists, skipped)"
    fi
  fi

  # Deploy .gitattributes to enforce LF endings on hook scripts
  # Without this, Git for Windows re-adds CRLF on checkout, breaking the bash shebang.
  local gitattributes_src="$SCRIPT_DIR/.gitattributes"
  local gitattributes_dest="$PROJECT_ROOT/.gitattributes"
  if [ -f "$gitattributes_src" ]; then
    if [ ! -f "$gitattributes_dest" ]; then
      cp "$gitattributes_src" "$gitattributes_dest"
      echo "  + .gitattributes (created - enforces LF on hook scripts)"
    else
      echo "  - .gitattributes (already exists, skipped)"
    fi
  fi

  echo "  ✅ Git guardrails activated."
}

initialize_repo() {
  echo ""
  echo "  Initializing Repository Structure"

  local gitignore_src="$SCRIPT_DIR/.gitignore"
  local gitignore_dest="$PROJECT_ROOT/.gitignore"
  
  if [ -f "$gitignore_src" ]; then
    if [ ! -f "$gitignore_dest" ]; then
      cp "$gitignore_src" "$gitignore_dest"
      echo "  + .gitignore (copied)"
    else
      echo "  - .gitignore (already exists at root, skipped)"
    fi
  else
    echo "  ! Warning: .gitignore not found in the ravintio-zero directory ($gitignore_src)"
  fi

  local src_dir="$PROJECT_ROOT/src"
  if [ ! -d "$src_dir" ]; then
    mkdir -p "$src_dir"
    echo "  + src/ (created)"
  fi
  
  if [ ! -f "$src_dir/README.md" ]; then
    cat << 'EOF' > "$src_dir/README.md"
# src/

Components live here. Each component is a subfolder with a `component.yml` manifest.

See [plan/feature-structure.md](../plan/feature-structure.md) for the canonical layout.
EOF
    echo "  + src/README.md (created)"
  fi

  local plan_dir="$PROJECT_ROOT/plan"
  if [ ! -d "$plan_dir" ]; then
    mkdir -p "$plan_dir"
    echo "  + plan/ (created)"
  fi

  if [ ! -f "$plan_dir/README.md" ]; then
    cat << 'EOF' > "$plan_dir/README.md"
# plan/

Feature specifications live here. Each feature gets a subfolder.

See [plan/feature-structure.md](feature-structure.md) for the canonical layout.
EOF
    echo "  + plan/README.md (created)"
  fi

  if [ ! -f "$plan_dir/feature-structure.md" ]; then
    cat << 'EOF' > "$plan_dir/feature-structure.md"
# RAVINTIO Ã¢â‚¬â€ Repository Structure

> The canonical layout for a RAVINTIO-managed repository. Three top-level folders, three concerns.

---

## The Three Folders

```
repo/
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ ravintio-zero/        Ã¢â€ Â The pack (skills, templates, schemas, standards)
Ã¢â€â€š                                 Drop this in. Don't modify it per-project.
Ã¢â€â€š
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ plan/                       Ã¢â€ Â The specifications (organized by feature)
Ã¢â€â€š                                 Plans, briefs, specs, ADRs, risk, scope, glossary.
Ã¢â€â€š                                 Everything that describes WHAT to build and WHY.
Ã¢â€â€š
Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ src/                        Ã¢â€ Â The code (organized by component)
                                  Implementation, tests, config, manifests.
                                  Everything that IS the built thing.
```

---

## `ravintio-zero/` Ã¢â‚¬â€ The pack

This folder is RAVINTIO Zero itself. It is the same across every project. You do not modify it per-feature Ã¢â‚¬â€ you update it when RAVINTIO Zero evolves.

```
ravintio-zero/
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ skills/           Ã¢â€ Â Agent instructions (orchestrator + phase skills)
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ templates/        Ã¢â€ Â File format templates for every artifact
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ schemas/          Ã¢â€ Â JSON Schema validation definitions
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ standards/        Ã¢â€ Â Code quality standards
Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ spec/             Ã¢â€ Â This file Ã¢â‚¬â€ the canonical structure definition
```

---

## `plan/` Ã¢â‚¬â€ The Plan/Specifications

Organized by feature. Each feature gets a subfolder. This is where humans write briefs and agents write specs. No code lives here.

```
plan/
Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ {feature-id}/
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ feature-brief.md          Ã¢â€ Â Human input (start here)
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ design.md                 Ã¢â€ Â Validated plan (orchestrator output)
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ pipeline-run.md              Ã¢â€ Â Audit trail (per run)
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ pipeline-run-phase-2.md      Ã¢â€ Â Phase 2 audit (if phased)
    Ã¢â€â€š
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ design-requirements.md               Ã¢â€ Â Functional & non-functional requirements
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ design-spec-phase-2.md       Ã¢â€ Â Phase 2 spec (if phased)
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ openapi-spec.yaml            Ã¢â€ Â API contract
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ scope.md                     Ã¢â€ Â In / Out / Deferred
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ risk-register.md             Ã¢â€ Â Risk items with likelihood & impact
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ domain-glossary.md           Ã¢â€ Â Ubiquitous language
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ security-report.md           Ã¢â€ Â Security review findings
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ quirks.md                    Ã¢â€ Â Quirks and workarounds
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ recommendations.md           Ã¢â€ Â Improvement suggestions
    Ã¢â€â€š
    Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ adr/
        Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ ADR-001-{title}.md       Ã¢â€ Â Architecture decision records
        Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ ADR-002-{title}.md
        Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ ...
```

### Path Rules Ã¢â‚¬â€ plan/

1. **Feature ID** follows the format `{0000000}-{kebab-case-name}` - a 7-digit zero-padded number prefix for chronological ordering, followed by a human-chosen kebab-case name.
2. **No nesting** Ã¢â‚¬â€ specs, ADRs, and supporting docs are flat within the feature folder. One level of subfolders only (adr/).
3. **No code** Ã¢â‚¬â€ nothing executable lives in `plan/`. If it runs, it belongs in `src/`.
4. **Phased features** append the phase number: `design-spec-phase-2.md`, `pipeline-run-phase-2.md`. The `design.md` is updated per phase, not duplicated.
5. **ADRs** are numbered sequentially. Never renumber. Superseded ADRs stay with `status: superseded`.

---

## `src/` Ã¢â‚¬â€ The Code

Organized by component. Each component is a subfolder at the top level of `src/`. The component manifest lives with the code, not with the plan.

```
src/
Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ {component-id}/
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ component.yml               Ã¢â€ Â Component manifest (from template)
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ package.json                  Ã¢â€ Â (or equivalent for the stack)
    Ã¢â€â€š
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ src/                          Ã¢â€ Â Implementation (structure varies by stack)
    Ã¢â€â€š   Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ ...
    Ã¢â€â€š
    Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ tests/                        Ã¢â€ Â Tests
    Ã¢â€â€š   Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ ...
    Ã¢â€â€š
    Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ docs/
        Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ data-contract.md          Ã¢â€ Â Schema ownership & invariants
        Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ migrations/
            Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ proposed-{desc}.md    Ã¢â€ Â Migration proposals
```

### Path Rules Ã¢â‚¬â€ src/

1. **Component ID** is kebab-case, matches the `id` in `component.yml`.
2. **component.yml is mandatory** Ã¢â‚¬â€ every component has one. Read it before any work; update it after every build.
3. **Component-specific docs** live with the component at `src/{component-id}/docs/`. These describe the component's data contract, migrations, and technical specifics.
4. **Feature-level docs** live in `plan/`. The component's `component.yml` references the feature via the `feature` field.
5. **Existing components** that predate RAVINTIO are retrofitted by adding a `component.yml` at their root.

---

## How the Three Folders Connect

```
plan/current/design.md
    Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ lists component IDs Ã¢â€ â€™ src/{component-id}/component.yml
                                    Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ references feature Ã¢â€ â€™ plan/

plan/current/design-requirements.md
    Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ functional requirements Ã¢â€ â€™ implemented in Ã¢â€ â€™ src/{component-id}/src/

plan/current/adr/ADR-001-*.md
    Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ decisions Ã¢â€ â€™ followed by Ã¢â€ â€™ src/{component-id}/src/

plan/current/openapi-spec.yaml
    Ã¢â€â€Ã¢â€â‚¬Ã¢â€â‚¬ API contract Ã¢â€ â€™ implemented in Ã¢â€ â€™ src/{component-id}/src/
```

The relationship is bidirectional:
- `design.md` lists all component IDs
- Each `component.yml` references its feature ID
- The plan describes WHAT; the code IS the WHAT

---

## Retrofit Ã¢â‚¬â€ Adding RAVINTIO to an Existing Repo

If the repo already has code:

1. Drop `ravintio-zero/` into the repo root
2. Create `plan/` for the first feature
3. Move existing components under `src/` (or leave them if they're already there)
4. Add a `component.yml` to each existing component
5. The orchestrator's retrofit mode will read the codebase and infer the existing architecture

---

*Templates for each file are in [ravintio-zero/templates/](../ravintio-zero/templates/). Skills reference these paths.*
EOF
    echo "  + plan/feature-structure.md (created)"
  fi

  # Add tool ignore rules to keep context windows lean
  local ignore_content="
# RAVINTIO - Token Reduction (keeps agent semantic search from bloating context)
plan/_archive/
node_modules/
dist/
build/
out/
.next/
"
  local ignore_file=".claudeignore"
  if [ ! -f "$PROJECT_ROOT/$ignore_file" ]; then
    echo "$ignore_content" > "$PROJECT_ROOT/$ignore_file"
    echo "  + $ignore_file (created)"
  elif ! grep -q "RAVINTIO - Token Reduction" "$PROJECT_ROOT/$ignore_file"; then
    echo "$ignore_content" >> "$PROJECT_ROOT/$ignore_file"
    echo "  + $ignore_file (appended RAVINTIO ignore rules)"
  fi
}

setup_tool() {
  local tool="$1"
  local tool_config="$SETUP_DIR/${tool}.sh"

  if [ ! -f "$tool_config" ]; then
    echo "Error: no config file at setup/${tool}.sh"
    exit 1
  fi

  # Load tool-specific config
  source "$tool_config"

  local skills_dir="$PROJECT_ROOT/$TOOL_SKILLS_DIR"

  echo ""
  echo "  Setting up $tool"
  echo "  Skills directory: $TOOL_SKILLS_DIR/"

  # Manifest cleanup — remove only previously installed directories on re-run
  local manifest="$skills_dir/.ravintio-manifest"
  if [ -f "$manifest" ]; then
    echo "  Re-run detected — removing previously installed directories"
    while IFS= read -r dir_path; do
      if [ -n "$dir_path" ] && [ -d "$dir_path" ]; then
        rm -rf "$dir_path"
        echo "  - removed: $(basename "$dir_path")"
      fi
    done < "$manifest"
    rm -f "$manifest"
  fi

  # Copy skills (now automatically bundles supporting files)
  copy_skills "$skills_dir"

  # Prune folders that no longer exist in the skills/ source set
  prune_retired_skills "$skills_dir"

  # Copy permanent capability skills from ravintio-overrides/ (REQ-008)
  copy_capability_skills "$skills_dir"

  # Copy workflows (if tool defines a workflow dir)
  if [ -n "${TOOL_WORKFLOWS_DIR:-}" ] && [ -d "$WORKFLOWS_SRC" ]; then
    local workflows_dir="$PROJECT_ROOT/$TOOL_WORKFLOWS_DIR"
    for wf in "$WORKFLOWS_SRC"/*.md; do
      [ -f "$wf" ] && copy_workflow "$wf" "$workflows_dir"
    done
  fi

  # Create boot file (if tool defines one)
  if [ -n "${TOOL_BOOT_FILE:-}" ]; then
    if [ -z "${TOOL_BOOT_CONTENT:-}" ] && [ -n "${TOOL_BOOT_TEMPLATE:-}" ]; then
      TOOL_BOOT_CONTENT=$(cat "$SCRIPT_DIR/../$TOOL_BOOT_TEMPLATE")
    fi
    write_boot_file "$PROJECT_ROOT/$TOOL_BOOT_FILE" "$TOOL_BOOT_CONTENT"
  fi

  # Append project-specific override instructions to boot file (REQ-006, REQ-007)
  if [ -n "${TOOL_BOOT_FILE:-}" ]; then
    append_override_instructions "$TOOL_BOOT_FILE"
  fi

  # Ordered BEFORE the enforcement hook install so that install is the last
  # writer of settings.json this run.
  if [ -n "${TOOL_SETTINGS_FILE:-}" ]; then
    remove_leftover_settings_tmp "$TOOL_SETTINGS_FILE"
  fi

  # Install RAVINTIO enforcement hooks unconditionally (REQ-008)
  # Not gated on MCP flags — enforcement applies to all RAVINTIO-enabled projects.
  if [ -n "${TOOL_SETTINGS_FILE:-}" ]; then
    install_enforcement_hooks "hooks/enforcement" ".claude/hooks/enforcement" "$TOOL_SETTINGS_FILE"
  fi

  # Add Agent to allowedTools so sub-agent dispatch works without per-use confirmation (REQ-002)
  if [ -n "${TOOL_SETTINGS_FILE:-}" ]; then
    merge_allowed_tools "$PROJECT_ROOT/$TOOL_SETTINGS_FILE"
  fi

  # Write manifest listing all installed skill directories (enables safe re-run cleanup)
  local installed_dirs=()
  for dir in "$skills_dir"/*/; do
    [ -d "$dir" ] && installed_dirs+=("${dir%/}")
  done
  if [ ${#installed_dirs[@]} -gt 0 ]; then
    printf '%s\n' "${installed_dirs[@]}" > "$manifest"
    echo "  + .ravintio-manifest (${#installed_dirs[@]} entries)"
  fi

  echo "  Done."
}

# Write plan/state/{tool}.md — the tracked, git-versioned source of truth for
# active setup flags (0000032 req-001, ADR-001 decision 1). The record holds
# tool, flags and writtenAt; 0000033 ADR-001 decision 6 narrowed it to those
# three. This is
# additive: it does not replace write_setup_flags_marker, and it is called BEFORE
# it so the gitignored marker is always (re)written to match this file's values
# for the current run, satisfying ADR-001 decision 5's reconciliation rule. If
# the write fails (e.g. permissions), warns and returns non-zero so the caller
# falls back to existing marker-only behavior instead of aborting setup
# (req-001 acceptance criteria, sad path).
write_setup_config_override() {
  local tool="$1"

  local config_dir="$PROJECT_ROOT/plan/state"
  local config_file="$config_dir/${tool}.md"

  local flags=()
  [ "$STRICT_ORCHESTRATOR" = true ] && flags+=("--strict-orchestrator")

  local flags_json="[]"
  if [ ${#flags[@]} -gt 0 ]; then
    flags_json=$(printf '"%s",' "${flags[@]}")
    flags_json="[${flags_json%,}]"
  fi

  local written_at
  written_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  if ! mkdir -p "$config_dir" 2>/dev/null; then
    echo "  ! Warning: could not create plan/state/ — continuing with .ravintio-setup-flags-only behavior" >&2
    return 1
  fi

  if ! cat > "$config_file" << CONFIG_EOF
# Setup config: $tool

> Tracked source of truth for active setup flags for **$tool**
> (0000032 ADR-001). The gitignored \`.ravintio-setup-flags\` marker in
> this tool's config directory is a local completion-status cache, reconciled to
> match this file on every \`setup.sh\`/\`setup.ps1\` run.

\`\`\`json
{
  "tool": "$tool",
  "flags": $flags_json,
  "writtenAt": "$written_at"
}
\`\`\`
CONFIG_EOF
  then
    echo "  ! Warning: failed to write plan/state/${tool}.md — continuing with .ravintio-setup-flags-only behavior" >&2
    return 1
  fi

  echo "  + plan/state/${tool}.md"
  return 0
}

# Remove the stale ravintio-overrides/setup-config/{tool}.md left by setup
# runs before 0000032 ADR-001 moved the record to plan/state/ (0000032
# req-003, ADR-003 decisions 1-2). Called only after a successful write of
# plan/state/{tool}.md; a failed write leaves the old file alone since the
# record it depends on isn't in place yet. Removal failure warns and returns
# 0 so the caller continues (ADR-003 decision 4).
remove_legacy_setup_config() {
  local tool="$1"

  local legacy_dir="$PROJECT_ROOT/ravintio-overrides/setup-config"
  local legacy_file="$legacy_dir/${tool}.md"

  if [ -e "$legacy_file" ]; then
    if rm -f "$legacy_file" 2>/dev/null; then
      echo "  - removed ravintio-overrides/setup-config/${tool}.md"
    else
      echo "  ! Warning: could not remove ravintio-overrides/setup-config/${tool}.md" >&2
    fi
  fi

  if [ -d "$legacy_dir" ]; then
    if [ -z "$(ls -A "$legacy_dir" 2>/dev/null)" ]; then
      if rmdir "$legacy_dir" 2>/dev/null; then
        echo "  - removed ravintio-overrides/setup-config/"
      else
        echo "  ! Warning: could not remove ravintio-overrides/setup-config/" >&2
      fi
    fi
  fi

  return 0
}

# Remove the marker files the pre-rename setup wrote (0000160 REQ-002).
# A symlink is skipped, never followed. Legacy, remove at 2.0.0 (ADR-002).
remove_old_markers() {
  local tool_dir="$1" skills_dir="$2" rel
  for rel in "$tool_dir/.planifest-setup-flags" "$skills_dir/.planifest-manifest"; do
    local path="$PROJECT_ROOT/$rel"
    if [ -L "$PROJECT_ROOT/$tool_dir" ] || [ -L "$PROJECT_ROOT/${rel%/*}" ]; then
      # A linked parent folder would send the removal outside the project.
      echo "  ! Warning: skipped $rel under a symlinked folder" >&2
    elif [ -L "$path" ]; then
      echo "  ! Warning: skipped symlink $rel" >&2
    elif [ -f "$path" ]; then
      if rm -f "$path" 2>/dev/null; then
        echo "  - removed $rel"
      else
        echo "  ! Warning: could not remove $rel" >&2
      fi
    fi
  done
}

# Write the flags-used marker recording what was applied at install time (REQ-008, ADR-002).
# Called only after a tool's setup completes successfully. set -euo pipefail means a failed
# setup_tool call aborts the script before this function is ever reached, satisfying
# REQ-008's "a failed install does not write the marker" requirement without extra bookkeeping.
write_setup_flags_marker() {
  local tool="$1"
  local tool_dir="$2"

  mkdir -p "$PROJECT_ROOT/$tool_dir"
  local marker="$PROJECT_ROOT/$tool_dir/.ravintio-setup-flags"

  local flags=()
  [ "$STRICT_ORCHESTRATOR" = true ] && flags+=("--strict-orchestrator")

  local flags_json="[]"
  if [ ${#flags[@]} -gt 0 ]; then
    flags_json=$(printf '"%s",' "${flags[@]}")
    flags_json="[${flags_json%,}]"
  fi

  local written_at
  written_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  cat > "$marker" << MARKER_EOF
{
  "tool": "$tool",
  "flags": $flags_json,
  "writtenAt": "$written_at",
  "attemptStatus": "completed"
}
MARKER_EOF

  echo "  + $tool_dir/.ravintio-setup-flags"
}

# --- Main ---

# Flags that earlier releases removed (0000034 ADR-001). An older install's
# flags marker can still list them, so setup warns and skips each one instead
# of failing the refresh. --backend-url also took a value: skip the next
# argument unless it is another flag or a tool name, and never print or
# store it.
retired_flag_warning() {
  echo "  ! Warning: ignoring retired flag $1 (removed in an earlier release)" >&2
}

TOOL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict-orchestrator) STRICT_ORCHESTRATOR=true; shift ;;
    --structured-telemetry-mcp|--context-mode-mcp|--include-full-skill-library)
      retired_flag_warning "$1"; shift ;;
    --backend-url)
      retired_flag_warning "$1"; shift
      if [[ $# -gt 0 && "$1" != --* && " $VALID_TOOLS " != *" $1 "* ]]; then shift; fi ;;
    --backend-url=*)
      retired_flag_warning "--backend-url"; shift ;;
    # Print only the part before "=", so a value never reaches the log.
    -*) echo "Unknown flag: ${1%%=*}"; exit 1 ;;
    *) TOOL="$1"; shift ;;
  esac
done

if [ -z "$TOOL" ]; then
  echo ""
  echo "RAVINTIO Setup"
  echo ""
  echo "Usage: ./ravintio-zero/setup.sh claude-code [flags]"
  echo ""
  echo "Tools:"
  for t in $VALID_TOOLS; do
    echo "  $t"
  done
  echo ""
  echo "Flags:"
  echo "  --strict-orchestrator        Write plan/.orchestrator-strict to enable strict mode."
  echo "                               The check-orchestrator-presence hook will require the"
  echo "                               orchestrator to ack each new session before proceeding."
  echo ""
  echo "Run from the repository root."
  echo "Each tool's config: ravintio-zero/setup/<tool>.sh"
  exit 0
fi

# Stop before installing anything if an old-brand folder is still present
# (0000160 REQ-002, ADR-003). The migration renames it first.
for old_folder in "planifest-zero" "planifest-overrides"; do
  if [ -e "$PROJECT_ROOT/$old_folder" ] || [ -L "$PROJECT_ROOT/$old_folder" ]; then
    echo "! Error: found the old folder $old_folder/ in this project." >&2
    echo "  Run ravintio-zero/migrations/migrate-ravintio-rename.sh first, then rerun setup." >&2
    exit 1
  fi
done

echo "RAVINTIO Setup"
echo "Ã¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢ÂÃ¢â€¢Â"

initialize_repo
activate_guardrails

# Write strict-mode sentinel if --strict-orchestrator flag was passed (REQ-008)
if [ "$STRICT_ORCHESTRATOR" = true ]; then
  mkdir -p "$PROJECT_ROOT/plan"
  touch "$PROJECT_ROOT/plan/.orchestrator-strict"
  echo "  + plan/.orchestrator-strict (strict orchestrator mode enabled)"
fi

run_tool_setup() {
  local t="$1"
  setup_tool "$t"
  remove_old_markers "$(dirname "$TOOL_SKILLS_DIR")" "$TOOL_SKILLS_DIR"
  if write_setup_config_override "$t"; then
    remove_legacy_setup_config "$t"
  fi
  # TOOL_SKILLS_DIR is set globally by the tool config sourced inside setup_tool
  # (e.g. ".claude/skills"); its parent is the tool's own config directory (REQ-008).
  write_setup_flags_marker "$t" "$(dirname "$TOOL_SKILLS_DIR")"
}

# Exact match only, the same as setup.ps1's -contains check (0000034 req-002).
tool_is_valid=false
for t in $VALID_TOOLS; do
  if [ "$t" = "$TOOL" ]; then tool_is_valid=true; fi
done

if [ "$tool_is_valid" = true ]; then
  run_tool_setup "$TOOL"
else
  echo "Unknown tool: $TOOL"
  echo "Valid tools: $VALID_TOOLS"
  exit 1
fi

echo ""
echo "Setup complete."
echo "  Source of truth: ravintio-zero/"
echo "  Re-run after you update the pack."

