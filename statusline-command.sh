#!/usr/bin/env bash
# Claude Code status line: 2-line conversation focused
# Line 1: 대화  ████████░░░░░░░░░░░░ 42%   ↑85.2K ↓12.3K   Opus 4.6
# Line 2:       116.0K 남음   OUT 누적 12.3K

input=$(cat)

# --- Parse Claude Code JSON ---
eval "$(echo "$input" | jq -r '
  @sh "model=\(.model.display_name // "Unknown")",
  @sh "used_pct=\(.context_window.used_percentage // "")",
  @sh "ctx_size=\(.context_window.context_window_size // 200000)",
  @sh "total_in=\(.context_window.total_input_tokens // 0)",
  @sh "total_out=\(.context_window.total_output_tokens // 0)"
' 2>/dev/null)"

# --- Colors ---
RST='\033[0m'
BOLD='\033[1m'
W='\033[38;5;255m'
G1='\033[38;5;245m'
G2='\033[38;5;238m'
GREEN='\033[38;5;114m'
BLUE='\033[38;5;75m'
CYAN='\033[38;5;80m'
YELLOW='\033[38;5;228m'
ORANGE='\033[38;5;215m'
RED='\033[38;5;203m'
LAVENDER='\033[38;5;141m'
TEAL='\033[38;5;109m'

# --- Helpers ---
fmt_k() {
  echo "$1" | awk '{
    v = ($1=="" ? 0 : $1+0)
    if      (v >= 1000000) printf "%.1fM", v/1000000
    else if (v >= 1000)    printf "%.1fK", v/1000
    else                   print  v
  }'
}

# Color by percentage (gradient)
pct_color() {
  local p="$1"
  if   [ "$p" -lt 25 ]; then printf '%b' "${GREEN}"
  elif [ "$p" -lt 50 ]; then printf '%b' "${CYAN}"
  elif [ "$p" -lt 65 ]; then printf '%b' "${BLUE}"
  elif [ "$p" -lt 80 ]; then printf '%b' "${ORANGE}"
  else                        printf '%b' "${RED}"
  fi
}

make_bar() {
  local pct_int="$1" width="$2"
  local fc
  fc=$(pct_color "$pct_int")

  read f e <<< "$(awk "BEGIN { f=int($pct_int/100*$width+0.5); if(f>$width)f=$width; if(f<0)f=0; print f, $width-f }")"
  local bf="" be=""
  for i in $(seq 1 "$f"); do bf="${bf}█"; done
  for i in $(seq 1 "$e"); do be="${be}░"; done
  printf '%b' "${fc}${bf}${G2}${be}${RST}"
}

# --- Pre-format ---
total_in_fmt=$(fmt_k "$total_in")
total_out_fmt=$(fmt_k "$total_out")

pct1=0
[ -n "$used_pct" ] && pct1=$(echo "$used_pct" | awk '{printf "%d", $1+0.5}')

cs=${ctx_size:-200000}
remaining=$(awk "BEGIN { printf \"%d\", $cs - ($cs * $pct1 / 100) }")
remaining_fmt=$(fmt_k "$remaining")

C_PCT=$(pct_color "$pct1")

# ════════════════════════════════════════
# Line 1: 바 + % + IN/OUT + 모델
# ════════════════════════════════════════
line1="${W}${BOLD}대화${RST}  "
line1="${line1}$(make_bar "$pct1" 20) ${C_PCT}${BOLD}${pct1}%${RST}"
line1="${line1}   ${GREEN}↑${total_in_fmt}${RST} ${ORANGE}↓${total_out_fmt}${RST}"
line1="${line1}   ${LAVENDER}${model}${RST}"

# ════════════════════════════════════════
# Line 2: 남은 컨텍스트 + OUT 누적
# ════════════════════════════════════════
C_REM="${TEAL}"
[ "$pct1" -ge 60 ] && C_REM="${ORANGE}"
[ "$pct1" -ge 80 ] && C_REM="${RED}"

line2="      "
line2="${line2}${C_REM}${BOLD}${remaining_fmt}${RST} ${G1}남음${RST}"
line2="${line2}   ${G1}OUT 누적${RST} ${ORANGE}${BOLD}${total_out_fmt}${RST}"

# --- Output ---
printf '%b\n%b' "$line1" "$line2"
