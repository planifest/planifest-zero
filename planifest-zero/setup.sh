#!/usr/bin/env bash
set -euo pipefail

# Planifest Setup - Configures skills for your agentic coding tool.
#
# Usage:  ./planifest-zero/setup.sh <tool>
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
STRUCTURED_TELEMETRY_MCP=false
BACKEND_URL="http://localhost:3741"
STRICT_ORCHESTRATOR=false

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
  # planifest-overrides/ are copied back in after this prune runs.
  local target_dir="$1"

  [ -d "$target_dir" ] || return 0

  for dest_dir in "$target_dir"/*/; do
    [ -d "$dest_dir" ] || continue
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
  # run. Durable local customization lives in planifest-overrides/instructions/
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
  # Copies permanent capability skills from planifest-overrides/capability-skills/
  # to the tool's skills directory (REQ-008, parity with setup.ps1 Copy-CapabilitySkills).
  local target_dir="$1"
  local cap_skills_dir="$PROJECT_ROOT/planifest-overrides/capability-skills"

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
    echo "  Syncing capability skills from planifest-overrides/capability-skills/"
  fi
}

append_override_instructions() {
  # Appends project-specific instructions from planifest-overrides/instructions/
  # into the boot file between sentinel markers (idempotent). (REQ-006, REQ-007,
  # parity with setup.ps1 Append-OverrideInstructions).
  local boot_file="$PROJECT_ROOT/$1"
  local instr_dir="$PROJECT_ROOT/planifest-overrides/instructions"
  local start_marker="<!-- planifest-overrides:instructions:start -->"
  local end_marker="<!-- planifest-overrides:instructions:end -->"

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
    PLANIFEST_BOOT="$boot_file" node -e '
      const fs = require("fs");
      const b = process.env.PLANIFEST_BOOT;
      if (!fs.existsSync(b)) process.exit(0);
      let c = fs.readFileSync(b, "utf8");
      const s = "<!-- planifest-overrides:instructions:start -->";
      const e = "<!-- planifest-overrides:instructions:end -->";
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

  echo "  Appending override instructions from planifest-overrides/instructions/"
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

install_enforcement_hooks() {
  # Copy enforcement hooks and wire PreToolUse/UserPromptSubmit (REQ-002, REQ-006, REQ-008).
  # Includes auto-trigger-orchestrator.mjs (REQ-002), gate-write.mjs, check-design.mjs,
  # check-telemetry-failures.mjs (0000026, backlog 0000044 — deterministic backstop for
  # the orchestrator's ADR-002 phase-start telemetry-failure-marker check),
  # check-telemetry-receipts.mjs (req-004, feature 0000027, ADR-001 — cross-references
  # build-log.md's per-phase Telemetry claims against plan/.telemetry-receipts/), and
  # em-dash-guard.mjs (req-006, feature 0000028, ADR-003 — rejects U+2014 in scoped
  # Planifest prose paths at write time, sibling to gate-write.mjs and ratchet-check.mjs).
  # Always installed, regardless of MCP flags — both telemetry checks are
  # UserPromptSubmit-shaped like the other enforcement hooks, not PostToolUse like
  # context-pressure.mjs, and read plan/ state rather than requiring the telemetry
  # hooks themselves to be active, so neither belongs behind
  # --structured-telemetry-mcp — when telemetry is off, build-log.md's Telemetry field reads
  # "confirmed-disabled" and check-telemetry-receipts.mjs correctly has nothing to flag.
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
  echo "  Installing Planifest enforcement hooks"

  mkdir -p "$dest"
  for script in "$src"/*.mjs; do
    [ -f "$script" ] || continue
    local script_name
    script_name="$(basename "$script")"
    cp "$script" "$dest/$script_name"
    echo "  + $hooks_dir_rel/$script_name"
  done

  # Wire into settings.json (requires node; jq fallback not needed, node is always available)
  #
  # 0000028 (P5, SEC-001): every command below is prefixed with `node`. These
  # were previously wired as bare .mjs paths relying on the shebang plus an
  # executable bit. The bit is a committed file mode, and 9 of the 10 hook
  # files are mode 100644, so the shell could not exec them: the wired command
  # exited 126 (permission denied) and the hook silently never ran. Because a
  # PreToolUse hook that fails to start is indistinguishable from one that
  # passed, gate-write, em-dash-guard, check-design, both telemetry backstops,
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
  local telemetry_failures_cmd="node \"$hooks_dir_rel/check-telemetry-failures.mjs\""
  local telemetry_receipts_cmd="node \"$hooks_dir_rel/check-telemetry-receipts.mjs\""

  if command -v node >/dev/null 2>&1; then
    PLANIFEST_GATE="$gate_cmd" PLANIFEST_RATCHET="$ratchet_cmd" PLANIFEST_EM_DASH="$em_dash_cmd" PLANIFEST_TRIGGER="$trigger_cmd" PLANIFEST_PRESENCE="$presence_cmd" PLANIFEST_DESIGN="$design_cmd" PLANIFEST_TELEMETRY_FAILURES="$telemetry_failures_cmd" PLANIFEST_TELEMETRY_RECEIPTS="$telemetry_receipts_cmd" PLANIFEST_SETTINGS="$settings" node -e '
      const fs = require("fs"), path = require("path");
      const gate     = process.env.PLANIFEST_GATE;
      const ratchet  = process.env.PLANIFEST_RATCHET;
      const emDash   = process.env.PLANIFEST_EM_DASH;
      const trigger  = process.env.PLANIFEST_TRIGGER;
      const presence = process.env.PLANIFEST_PRESENCE;
      const design   = process.env.PLANIFEST_DESIGN;
      const telemetryFailures = process.env.PLANIFEST_TELEMETRY_FAILURES;
      const telemetryReceipts = process.env.PLANIFEST_TELEMETRY_RECEIPTS;
      const sf       = process.env.PLANIFEST_SETTINGS;
      let s = {};
      if (fs.existsSync(sf)) s = JSON.parse(fs.readFileSync(sf,"utf8").replace(/^\uFEFF/,""));
      s.hooks = s.hooks || {};
      // PreToolUse: gate-write + ratchet-check + em-dash-guard for Write and Edit
      // (idempotent: remove then re-add)
      s.hooks.PreToolUse = (s.hooks.PreToolUse || [])
        .filter(h => !["Write","Edit"].includes(h.matcher) ||
                     !(h.hooks||[]).some(e => (e.command||"").includes("gate-write") ||
                                              (e.command||"").includes("ratchet-check") ||
                                              (e.command||"").includes("em-dash-guard")));
      s.hooks.PreToolUse.push(
        {matcher:"Write", hooks:[{type:"command",command:gate}]},
        {matcher:"Edit",  hooks:[{type:"command",command:gate}]},
        {matcher:"Write", hooks:[{type:"command",command:ratchet}]},
        {matcher:"Edit",  hooks:[{type:"command",command:ratchet}]},
        {matcher:"Write", hooks:[{type:"command",command:emDash}]},
        {matcher:"Edit",  hooks:[{type:"command",command:emDash}]}
      );
      // UserPromptSubmit: auto-trigger first, then presence check, then check-design,
      // then check-telemetry-failures, then check-telemetry-receipts
      // (REQ-002, REQ-008, 0000026, req-004/0000027, idempotent)
      s.hooks.UserPromptSubmit = (s.hooks.UserPromptSubmit || [])
        .filter(h => !(h.hooks||[]).some(e =>
          (e.command||"").includes("auto-trigger-orchestrator") ||
          (e.command||"").includes("check-orchestrator-presence") ||
          (e.command||"").includes("check-design") ||
          (e.command||"").includes("check-telemetry-failures") ||
          (e.command||"").includes("check-telemetry-receipts")));
      s.hooks.UserPromptSubmit.push(
        {matcher:".*", hooks:[{type:"command",command:trigger}]},
        {matcher:".*", hooks:[{type:"command",command:presence}]},
        {matcher:".*", hooks:[{type:"command",command:design}]},
        {matcher:".*", hooks:[{type:"command",command:telemetryFailures}]},
        {matcher:".*", hooks:[{type:"command",command:telemetryReceipts}]}
      );
      fs.mkdirSync(path.dirname(sf),{recursive:true});
      fs.writeFileSync(sf, JSON.stringify(s,null,2)+"\n");
    '
    echo "  ~ $settings_rel (enforcement hooks wired)"
  else
    echo "  ! Warning: node not found — skipping settings.json enforcement hook wiring"
    echo "  ! Manually add gate-write, ratchet-check, em-dash-guard (Write/Edit PreToolUse), auto-trigger-orchestrator, check-orchestrator-presence, check-design, check-telemetry-failures and check-telemetry-receipts (UserPromptSubmit) to $settings_rel"
  fi
}

merge_telemetry_hook_settings() {
  # Merge context-pressure (PostToolUse), emit-phase-start (PreToolUse), and
  # emit-phase-end (Stop) hook entries into .claude/settings.json, plus the
  # emit_event receipt hook (PostToolUse, req-004/ADR-001).
  # Idempotent: each script's prior entry is removed before being re-added.
  #
  # Wiring design decision (req-001, feature 0000027): emit-phase-start.mjs
  # (documented in its own header as a PreToolUse hook) and emit-phase-end.mjs
  # (documented as a Stop hook) each require a positional <phase> CLI
  # argument. A single hook entry is one fixed `command` string -- it cannot
  # vary that argument as the pipeline moves through phases over the life of
  # a session. Rather than modifying either telemetry script, both entries
  # below route through hooks/telemetry/resolve-phase.mjs, which infers the
  # active phase from an observable tool-lifecycle signal (which phase-agent
  # Skill the orchestrator invoked) and re-execs the real script with that
  # phase supplied. See resolve-phase.mjs's own header for the full mechanism
  # and its documented limitation for multi-turn phases.
  local settings_file="$1"
  local hooks_dir="$2"   # relative path used in the command value
  local backend_url="$3"

  local pressure_cmd="PLANIFEST_TELEMETRY_URL=$backend_url node $hooks_dir/context-pressure.mjs"
  local start_cmd="PLANIFEST_TELEMETRY_URL=$backend_url node $hooks_dir/resolve-phase.mjs start $hooks_dir/emit-phase-start.mjs"
  local end_cmd="PLANIFEST_TELEMETRY_URL=$backend_url node $hooks_dir/resolve-phase.mjs end $hooks_dir/emit-phase-end.mjs"
  local receipt_cmd="node $hooks_dir/emit-event-receipt.mjs"

  if command -v jq >/dev/null 2>&1; then
    local merged
    if [ -f "$settings_file" ]; then
      merged=$(jq \
        --arg pressure "$pressure_cmd" \
        --arg start "$start_cmd" \
        --arg end "$end_cmd" \
        --arg receipt "$receipt_cmd" \
        '
          .hooks //= {} |
          .hooks.PostToolUse //= [] |
          .hooks.PreToolUse //= [] |
          .hooks.Stop //= [] |
          .hooks.PostToolUse |= (
            map(select(
              (.hooks // []) | map(.command // "") |
              (any(test("context-pressure")) or any(test("emit-event-receipt"))) | not
            ))
            + [
              {"matcher":".*","hooks":[{"type":"command","command":$pressure,"async":true,"timeout":5000}]},
              {"matcher":"mcp__structured-telemetry-mcp__emit_event","hooks":[{"type":"command","command":$receipt,"async":true,"timeout":5000}]}
            ]
          ) |
          .hooks.PreToolUse |= (
            map(select(
              (.hooks // []) | map(.command // "") | any(test("resolve-phase.*emit-phase-start")) | not
            ))
            + [{"matcher":"Skill","hooks":[{"type":"command","command":$start}]}]
          ) |
          .hooks.Stop |= (
            map(select(
              (.hooks // []) | map(.command // "") | any(test("resolve-phase.*emit-phase-end")) | not
            ))
            + [{"matcher":".*","hooks":[{"type":"command","command":$end}]}]
          )
        ' "$settings_file")
    else
      merged=$(jq -n \
        --arg pressure "$pressure_cmd" \
        --arg start "$start_cmd" \
        --arg end "$end_cmd" \
        --arg receipt "$receipt_cmd" \
        '{
          "hooks": {
            "PostToolUse": [
              {"matcher":".*","hooks":[{"type":"command","command":$pressure,"async":true,"timeout":5000}]},
              {"matcher":"mcp__structured-telemetry-mcp__emit_event","hooks":[{"type":"command","command":$receipt,"async":true,"timeout":5000}]}
            ],
            "PreToolUse": [{"matcher":"Skill","hooks":[{"type":"command","command":$start}]}],
            "Stop": [{"matcher":".*","hooks":[{"type":"command","command":$end}]}]
          }
        }')
    fi
    mkdir -p "$(dirname "$settings_file")"
    printf '%s\n' "$merged" > "$settings_file"
    echo "  ~ .claude/settings.json (telemetry hooks merged: context-pressure, emit-phase-start, emit-phase-end, emit-event-receipt)"
  elif command -v node >/dev/null 2>&1; then
    PLANIFEST_PRESSURE_CMD="$pressure_cmd" PLANIFEST_START_CMD="$start_cmd" PLANIFEST_END_CMD="$end_cmd" PLANIFEST_RECEIPT_CMD="$receipt_cmd" PLANIFEST_SETTINGS="$settings_file" node -e '
      const fs = require("fs"), path = require("path");
      const pressureCmd = process.env.PLANIFEST_PRESSURE_CMD;
      const startCmd    = process.env.PLANIFEST_START_CMD;
      const endCmd      = process.env.PLANIFEST_END_CMD;
      const receiptCmd  = process.env.PLANIFEST_RECEIPT_CMD;
      const sf  = process.env.PLANIFEST_SETTINGS;
      let s = {};
      if (fs.existsSync(sf)) s = JSON.parse(fs.readFileSync(sf,"utf8").replace(/^\uFEFF/,""));
      s.hooks = s.hooks || {};
      s.hooks.PostToolUse = (s.hooks.PostToolUse || [])
        .filter(h => !(h.hooks||[]).some(e => (e.command||"").includes("context-pressure") || (e.command||"").includes("emit-event-receipt")))
        .concat([
          {matcher:".*",hooks:[{type:"command",command:pressureCmd,async:true,timeout:5000}]},
          {matcher:"mcp__structured-telemetry-mcp__emit_event",hooks:[{type:"command",command:receiptCmd,async:true,timeout:5000}]}
        ]);
      s.hooks.PreToolUse = (s.hooks.PreToolUse || [])
        .filter(h => !(h.hooks||[]).some(e => (e.command||"").includes("resolve-phase.mjs") && (e.command||"").includes("emit-phase-start")))
        .concat([{matcher:"Skill",hooks:[{type:"command",command:startCmd}]}]);
      s.hooks.Stop = (s.hooks.Stop || [])
        .filter(h => !(h.hooks||[]).some(e => (e.command||"").includes("resolve-phase.mjs") && (e.command||"").includes("emit-phase-end")))
        .concat([{matcher:".*",hooks:[{type:"command",command:endCmd}]}]);
      fs.mkdirSync(path.dirname(sf),{recursive:true});
      fs.writeFileSync(sf, JSON.stringify(s,null,2)+"\n");
    '
    echo "  ~ .claude/settings.json (telemetry hooks merged: context-pressure, emit-phase-start, emit-phase-end, emit-event-receipt)"
  else
    echo "  ! Warning: neither jq nor node found -- skipping telemetry settings.json wiring"
  fi
}

verify_telemetry_hooks_installed() {
  # Positive-presence check (req-001, acceptance criterion): fails loudly if
  # any telemetry hook was copied to disk but never actually registered in
  # the target tool's settings -- the exact partial-wiring regression this
  # requirement exists to prevent from recurring silently.
  local settings_file="$1"
  local script_dir="$2"

  if ! command -v node >/dev/null 2>&1; then
    echo "  ! Warning: node not found -- skipping telemetry hook presence verification"
    return 0
  fi

  node "$script_dir/scripts/verify-telemetry-hooks.mjs" "$settings_file" --with-receipt
}

install_telemetry_hooks() {
  # Copy context-pressure hook script and wire PostToolUse in settings.json (REQ-008, REQ-010)
  # Only called when --structured-telemetry-mcp is active (0000018 req-001).
  local hooks_src_rel="$1"   # relative to SCRIPT_DIR  e.g. hooks/telemetry
  local hooks_dir_rel="$2"   # relative to PROJECT_ROOT e.g. .claude/hooks/telemetry
  local settings_rel="$3"    # relative to PROJECT_ROOT e.g. .claude/settings.json
  local backend_url="$4"

  local src="$SCRIPT_DIR/$hooks_src_rel"
  local dest="$PROJECT_ROOT/$hooks_dir_rel"
  local settings="$PROJECT_ROOT/$settings_rel"

  if [ ! -d "$src" ]; then
    echo "  ! Warning: telemetry hook scripts not found at $src — skipping"
    return
  fi

  echo ""
  echo "  Installing structured telemetry hooks"

  mkdir -p "$dest"

  for script in "$src"/*.mjs; do
    [ -f "$script" ] || continue
    local script_name
    script_name="$(basename "$script")"
    cp "$script" "$dest/$script_name"
    echo "  + $hooks_dir_rel/$script_name"
  done

  merge_telemetry_hook_settings "$settings" "$hooks_dir_rel" "$backend_url"
}

merge_allowed_tools() {
  # Idempotently add "Agent" to allowedTools in .claude/settings.json (REQ-002).
  # Preserves existing allowedTools entries — additive merge only.
  # Requires node (always available for Claude Code targets).
  local settings_file="$1"

  if command -v node >/dev/null 2>&1; then
    PLANIFEST_SETTINGS="$settings_file" node -e '
      const fs = require("fs"), path = require("path");
      const sf = process.env.PLANIFEST_SETTINGS;
      let s = {};
      if (fs.existsSync(sf)) s = JSON.parse(fs.readFileSync(sf,"utf8").replace(/^﻿/,""));
      const existing = Array.isArray(s.allowedTools) ? s.allowedTools : [];
      if (!existing.includes("Agent")) {
        s.allowedTools = existing.concat(["Agent"]);
        fs.mkdirSync(path.dirname(sf),{recursive:true});
        fs.writeFileSync(sf, JSON.stringify(s,null,2)+"\n");
        console.log("  ~ .claude/settings.json (Agent added to allowedTools)");
      } else {
        console.log("  - .claude/settings.json (Agent already in allowedTools)");
      }
    '
  else
    echo "  ! Warning: node not found — skipping allowedTools update"
    echo "  ! Manually add \"Agent\" to allowedTools in .claude/settings.json"
  fi
}

activate_guardrails() {
  echo ""
  echo "  Activating Planifest Git Guardrails"

  # Point Git to the version-controlled hooks directory
  # Degrade gracefully when not inside a git repository (e.g. test workspaces).
  if git config core.hooksPath planifest-zero/hooks 2>/dev/null; then
    echo "  + git config core.hooksPath planifest-zero/hooks"
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
  local workflow_src="$SCRIPT_DIR/hooks/planifest.yml"
  if [ -f "$workflow_src" ]; then
    mkdir -p "$github_workflows"
    if [ ! -f "$github_workflows/planifest.yml" ]; then
      cp "$workflow_src" "$github_workflows/planifest.yml"
      echo "  + .github/workflows/planifest.yml (created)"
    else
      echo "  - .github/workflows/planifest.yml (already exists, skipped)"
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
    echo "  ! Warning: .gitignore not found in framework directory ($gitignore_src)"
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
# Planifest Ã¢â‚¬â€ Repository Structure

> The canonical layout for a Planifest-managed repository. Three top-level folders, three concerns.

---

## The Three Folders

```
repo/
Ã¢â€Å“Ã¢â€â‚¬Ã¢â€â‚¬ planifest-zero/        Ã¢â€ Â The framework (skills, templates, schemas, standards)
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

## `planifest-zero/` Ã¢â‚¬â€ The Framework

This folder is the Planifest framework itself. It is the same across every project. You do not modify it per-feature Ã¢â‚¬â€ you update it when the framework evolves.

```
planifest-zero/
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
5. **Existing components** that predate Planifest are retrofitted by adding a `component.yml` at their root.

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

## Retrofit Ã¢â‚¬â€ Adding Planifest to an Existing Repo

If the repo already has code:

1. Drop `planifest-zero/` into the repo root
2. Create `plan/` for the first feature
3. Move existing components under `src/` (or leave them if they're already there)
4. Add a `component.yml` to each existing component
5. The orchestrator's retrofit mode will read the codebase and infer the existing architecture

---

*Templates for each file are in [planifest-zero/templates/](../planifest-zero/templates/). Skills reference these paths.*
EOF
    echo "  + plan/feature-structure.md (created)"
  fi

  # Add tool ignore rules to keep context windows lean
  local ignore_content="
# Planifest - Token Reduction (keeps agent semantic search from bloating context)
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
  elif ! grep -q "Planifest - Token Reduction" "$PROJECT_ROOT/$ignore_file"; then
    echo "$ignore_content" >> "$PROJECT_ROOT/$ignore_file"
    echo "  + $ignore_file (appended Planifest ignore rules)"
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
  local manifest="$skills_dir/.planifest-manifest"
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

  # Copy permanent capability skills from planifest-overrides/ (REQ-008)
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

  # Install Planifest enforcement hooks unconditionally (REQ-008)
  # Not gated on MCP flags — enforcement applies to all Planifest-enabled projects.
  if [ -n "${TOOL_SETTINGS_FILE:-}" ]; then
    install_enforcement_hooks "hooks/enforcement" ".claude/hooks/enforcement" "$TOOL_SETTINGS_FILE"
  fi

  # Add Agent to allowedTools so sub-agent dispatch works without per-use confirmation (REQ-002)
  if [ -n "${TOOL_SETTINGS_FILE:-}" ]; then
    merge_allowed_tools "$PROJECT_ROOT/$TOOL_SETTINGS_FILE"
  fi

  # Write telemetry opt-in sentinel so skills know emission is authorised (REQ-004)
  if [ "$STRUCTURED_TELEMETRY_MCP" = true ]; then
    local sentinel="$PROJECT_ROOT/.claude/telemetry-enabled"
    mkdir -p "$(dirname "$sentinel")"
    if [ ! -f "$sentinel" ]; then
      touch "$sentinel"
      echo "  + .claude/telemetry-enabled (telemetry opt-in sentinel)"
    else
      echo "  - .claude/telemetry-enabled (already exists)"
    fi
  fi

  # Install telemetry hooks whenever --structured-telemetry-mcp is active (0000018 req-001)
  if [ "$STRUCTURED_TELEMETRY_MCP" = true ] && \
     [ -n "${TOOL_TELEMETRY_HOOKS_SRC:-}" ] && [ -n "${TOOL_TELEMETRY_HOOKS_DIR:-}" ] && \
     [ -n "${TOOL_SETTINGS_FILE:-}" ]; then
    install_telemetry_hooks "$TOOL_TELEMETRY_HOOKS_SRC" "$TOOL_TELEMETRY_HOOKS_DIR" "$TOOL_SETTINGS_FILE" "$BACKEND_URL"
    verify_telemetry_hooks_installed "$PROJECT_ROOT/$TOOL_SETTINGS_FILE" "$SCRIPT_DIR"
  fi

  # Write manifest listing all installed skill directories (enables safe re-run cleanup)
  local installed_dirs=()
  for dir in "$skills_dir"/*/; do
    [ -d "$dir" ] && installed_dirs+=("${dir%/}")
  done
  if [ ${#installed_dirs[@]} -gt 0 ]; then
    printf '%s\n' "${installed_dirs[@]}" > "$manifest"
    echo "  + .planifest-manifest (${#installed_dirs[@]} entries)"
  fi

  echo "  Done."
}

# Write planifest-overrides/setup-config/{tool}.md — the tracked, git-versioned source
# of truth for active setup flags/backendUrl (0000025 req-004, ADR-002 decision 1). This
# is additive: it does not replace write_setup_flags_marker, and it is called BEFORE it so
# the gitignored marker is always (re)written to match this file's values for the current
# run, satisfying ADR-002 decision 3's reconciliation rule. If the write fails (e.g.
# permissions), warns and returns non-zero so the caller falls back to existing
# marker-only behavior instead of aborting setup (req-004 acceptance criteria, sad path).
write_setup_config_override() {
  local tool="$1"

  local config_dir="$PROJECT_ROOT/planifest-overrides/setup-config"
  local config_file="$config_dir/${tool}.md"

  local flags=()
  [ "$STRUCTURED_TELEMETRY_MCP" = true ] && flags+=("--structured-telemetry-mcp")
  [ "$STRICT_ORCHESTRATOR" = true ] && flags+=("--strict-orchestrator")

  local flags_json="[]"
  if [ ${#flags[@]} -gt 0 ]; then
    flags_json=$(printf '"%s",' "${flags[@]}")
    flags_json="[${flags_json%,}]"
  fi

  local backend_url_json="null"
  [ "$STRUCTURED_TELEMETRY_MCP" = true ] && backend_url_json="\"$BACKEND_URL\""

  local written_at
  written_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  if ! mkdir -p "$config_dir" 2>/dev/null; then
    echo "  ! Warning: could not create planifest-overrides/setup-config/ — continuing with .planifest-setup-flags-only behavior" >&2
    return 1
  fi

  if ! cat > "$config_file" << CONFIG_EOF
# Setup config: $tool

> Tracked source of truth for active setup flags/backend-url for **$tool**
> (0000025 req-004, ADR-002). The gitignored \`.planifest-setup-flags\` marker in
> this tool's config directory is a local completion-status cache, reconciled to
> match this file on every \`setup.sh\`/\`setup.ps1\` run.

\`\`\`json
{
  "tool": "$tool",
  "flags": $flags_json,
  "backendUrl": $backend_url_json,
  "writtenAt": "$written_at"
}
\`\`\`
CONFIG_EOF
  then
    echo "  ! Warning: failed to write planifest-overrides/setup-config/${tool}.md — continuing with .planifest-setup-flags-only behavior" >&2
    return 1
  fi

  echo "  + planifest-overrides/setup-config/${tool}.md"
  return 0
}

# Write the flags-used marker recording what was applied at install time (REQ-008, ADR-002).
# Called only after a tool's setup completes successfully. set -euo pipefail means a failed
# setup_tool call aborts the script before this function is ever reached, satisfying
# REQ-008's "a failed install does not write the marker" requirement without extra bookkeeping.
write_setup_flags_marker() {
  local tool="$1"
  local tool_dir="$2"

  mkdir -p "$PROJECT_ROOT/$tool_dir"
  local marker="$PROJECT_ROOT/$tool_dir/.planifest-setup-flags"

  local flags=()
  [ "$STRUCTURED_TELEMETRY_MCP" = true ] && flags+=("--structured-telemetry-mcp")
  [ "$STRICT_ORCHESTRATOR" = true ] && flags+=("--strict-orchestrator")

  local flags_json="[]"
  if [ ${#flags[@]} -gt 0 ]; then
    flags_json=$(printf '"%s",' "${flags[@]}")
    flags_json="[${flags_json%,}]"
  fi

  local backend_url_json="null"
  [ "$STRUCTURED_TELEMETRY_MCP" = true ] && backend_url_json="\"$BACKEND_URL\""

  local written_at
  written_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

  cat > "$marker" << MARKER_EOF
{
  "tool": "$tool",
  "flags": $flags_json,
  "backendUrl": $backend_url_json,
  "writtenAt": "$written_at",
  "attemptStatus": "completed"
}
MARKER_EOF

  echo "  + $tool_dir/.planifest-setup-flags"
}

# --- Main ---

TOOL=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --structured-telemetry-mcp) STRUCTURED_TELEMETRY_MCP=true; shift ;;
    --strict-orchestrator) STRICT_ORCHESTRATOR=true; shift ;;
    --backend-url)
      if [[ -z "${2:-}" ]] || [[ "${2:-}" == -* ]]; then
        echo "Error: --backend-url requires a value"; exit 1
      fi
      # Validated here, once, at parse time, rather than at each of its several
      # downstream uses -- merge_telemetry_hook_settings() interpolates this
      # value directly into a shell command string written into the target
      # tool's hook config (backlog 0000055, found during 0000027's P5 review).
      # Reject anything outside a plain http(s) URL shape before it can reach
      # that interpolation; fail loudly (setup-time check, not a runtime hook --
      # ADR-005's fail-open precedent does not apply here).
      if ! [[ "$2" =~ ^https?://[A-Za-z0-9.-]+(:[0-9]+)?(/[A-Za-z0-9._/-]*)?$ ]]; then
        echo "Error: --backend-url must be a plain http(s) URL (host[:port][/path]), got: $2"
        exit 1
      fi
      BACKEND_URL="$2"; shift 2 ;;
    -*) echo "Unknown flag: $1"; exit 1 ;;
    *) TOOL="$1"; shift ;;
  esac
done

if [ -z "$TOOL" ]; then
  echo ""
  echo "Planifest Setup"
  echo ""
  echo "Usage: ./planifest-zero/setup.sh claude-code [flags]"
  echo ""
  echo "Tools:"
  for t in $VALID_TOOLS; do
    echo "  $t"
  done
  echo ""
  echo "Flags:"
  echo "  --structured-telemetry-mcp   Install structured telemetry hooks."
  echo "  --backend-url <url>          Override telemetry backend URL (default: http://localhost:3741)"
  echo "  --strict-orchestrator        Write plan/.orchestrator-strict to enable strict mode."
  echo "                               The check-orchestrator-presence hook will require the"
  echo "                               orchestrator to ack each new session before proceeding."
  echo ""
  echo "Run from the repository root."
  echo "Each tool's config: planifest-zero/setup/<tool>.sh"
  exit 0
fi

echo "Planifest Setup"
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
  write_setup_config_override "$t" || true
  # TOOL_SKILLS_DIR is set globally by the tool config sourced inside setup_tool
  # (e.g. ".claude/skills"); its parent is the tool's own config directory (REQ-008).
  write_setup_flags_marker "$t" "$(dirname "$TOOL_SKILLS_DIR")"
}

if echo "$VALID_TOOLS" | grep -qw "$TOOL"; then
  run_tool_setup "$TOOL"
else
  echo "Unknown tool: $TOOL"
  echo "Valid tools: $VALID_TOOLS"
  exit 1
fi

echo ""
echo "Setup complete."
echo "  Source of truth: planifest-zero/"
echo "  Re-run after updating framework files."

