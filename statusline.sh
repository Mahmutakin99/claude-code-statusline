#!/bin/bash
# Claude Code statusline
#
# dir ⎇branch · model effort · ctx% · $cost · session% →resets_at · week%
#
# Color thresholds: green <60, yellow 60-84, red >=85
# rate_limits fields are only sent for Claude.ai subscribers, and only after
# the first API response of the session — until then those segments are
# silently skipped.

input=$(cat)
j() { printf '%s' "$input" | jq -r "$1" 2>/dev/null; }

dir=$(j '.workspace.current_dir // .cwd // ""')
model=$(j '.model.display_name // .model.id // ""')
effort=$(j '.effort.level // empty')
fast=$(j '.fast_mode // false')
ctx=$(j '.context_window.used_percentage // empty')
cost=$(j '.cost.total_cost_usd // empty')
s_pct=$(j '.rate_limits.five_hour.used_percentage // empty')
s_at=$(j '.rate_limits.five_hour.resets_at // empty')
w_pct=$(j '.rate_limits.seven_day.used_percentage // empty')

R=$'\033[0m'; DIM=$'\033[2m'; BLU=$'\033[34m'; GRN=$'\033[32m'
YEL=$'\033[33m'; RED=$'\033[31m'; MAG=$'\033[35m'; CYN=$'\033[36m'

# pick a color for a percentage
hue() { [ "$1" -ge 85 ] && printf '%s' "$RED" || { [ "$1" -ge 60 ] && printf '%s' "$YEL" || printf '%s' "$GRN"; }; }
# truncate a decimal percentage to an integer
num() { awk -v v="$1" 'BEGIN{ printf "%d", (v<0?0:v) }'; }

out=""

# working directory (strip up to the last / or \, since Windows paths use \)
[ -n "$dir" ] && out="${BLU}${dir##*[/\\]}${R}"

# git branch
if [ -n "$dir" ] && b=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null); then
  out="${out} ${DIM}⎇${b}${R}"
fi

# model + effort (+ fast mode)
if [ -n "$model" ]; then
  out="${out}  ${MAG}${model}${R}"
  [ -n "$effort" ] && out="${out} ${DIM}${effort}${R}"
  [ "$fast" = "true" ] && out="${out} ${CYN}fast${R}"
fi

# context window usage
if [ -n "$ctx" ]; then
  v=$(num "$ctx")
  out="${out}  ${DIM}ctx${R} $(hue "$v")${v}%${R}"
fi

# session cost
[ -n "$cost" ] && out="${out}  ${DIM}$(awk -v v="$cost" 'BEGIN{ printf "$%.2f", v }')${R}"

# 5-hour session rate limit + reset time
if [ -n "$s_pct" ]; then
  v=$(num "$s_pct")
  out="${out}  ${DIM}session${R} $(hue "$v")${v}%${R}"
  if [ -n "$s_at" ]; then
    # GNU date (Linux, Git Bash) wants -d @epoch; BSD date (macOS) wants -r epoch
    t=$(date -d "@$(num "$s_at")" +%H:%M 2>/dev/null) || t=$(date -r "$(num "$s_at")" +%H:%M 2>/dev/null)
    [ -n "$t" ] && out="${out}${DIM}→${t}${R}"
  fi
fi

# 7-day rate limit
if [ -n "$w_pct" ]; then
  v=$(num "$w_pct")
  out="${out}  ${DIM}week${R} $(hue "$v")${v}%${R}"
fi

printf '%s' "$out"
