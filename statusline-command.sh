#!/usr/bin/env bash
# Claude Code status line: 2-line symmetric layout
# ─────────────────────────────────────────────────────────────────
# 가중 토큰 (Anthropic 가격 비율 기반):
#   input       ×1.0   ($3.00/M)
#   output      ×5.0   ($15.00/M)
#   cache write ×1.25  ($3.75/M)
#   cache read  ×0.1   ($0.30/M)
# ─────────────────────────────────────────────────────────────────
SESSION_WEIGHTED_LIMIT=3000000   # 3M 가중 토큰 (Max 5x 기준, 조정 가능)

input=$(cat)

# --- Parse Claude Code JSON ---
eval "$(echo "$input" | jq -r '
  @sh "model=\(.model.display_name // "Unknown")",
  @sh "used_pct=\(.context_window.used_percentage // "")",
  @sh "total_in=\(.context_window.total_input_tokens // 0)",
  @sh "total_out=\(.context_window.total_output_tokens // 0)"
' 2>/dev/null)"

# --- Fetch 5h billing block from ccusage ---
block_json=""
if command -v ccusage &>/dev/null; then
  block_json=$(ccusage blocks --active --json 2>/dev/null)
fi

block_weighted="0"
block_remaining=""
if [ -n "$block_json" ]; then
  eval "$(echo "$block_json" | jq -r '
    .blocks[0] // empty |
    @sh "b_in=\(.tokenCounts.inputTokens // 0)",
    @sh "b_out=\(.tokenCounts.outputTokens // 0)",
    @sh "b_cw=\(.tokenCounts.cacheCreationInputTokens // 0)",
    @sh "b_cr=\(.tokenCounts.cacheReadInputTokens // 0)",
    @sh "block_remaining=\(.projection.remainingMinutes // 0)"
  ' 2>/dev/null)"

  # 가중 토큰 계산
  block_weighted=$(awk "BEGIN { printf \"%d\", $b_in*1.0 + $b_out*5.0 + $b_cw*1.25 + $b_cr*0.1 }")
fi

# --- Color palette ---
RST='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'
W='\033[38;5;255m'
G1='\033[38;5;245m'
G2='\033[38;5;239m'
BLUE='\033[38;5;75m'
ORANGE='\033[38;5;215m'
RED='\033[38;5;203m'
GREEN='\033[38;5;114m'
TEAL='\033[38;5;109m'
LAVENDER='\033[38;5;141m'

# --- Helpers ---
fmt_k() {
  echo "$1" | awk '{
    v = ($1=="" ? 0 : $1+0)
    if      (v >= 1000000) printf "%.1fM", v/1000000
    else if (v >= 1000)    printf "%.1fK", v/1000
    else                   print  v
  }'
}

make_bar() {
  local pct_int="$1" width="$2"
  local fc="${BLUE}"
  [ "$pct_int" -ge 60 ] && fc="${ORANGE}"
  [ "$pct_int" -ge 80 ] && fc="${RED}"
  read f e <<< "$(awk "BEGIN { f=int($pct_int/100*$width+0.5); if(f>$width)f=$width; if(f<0)f=0; print f, $width-f }")"
  local bf="" be=""
  for i in $(seq 1 "$f"); do bf="${bf}━"; done
  for i in $(seq 1 "$e"); do be="${be}─"; done
  printf '%b' "${fc}${bf}${G2}${be}${RST}"
}

# --- Pre-format ---
total_in_fmt=$(fmt_k "$total_in")
total_out_fmt=$(fmt_k "$total_out")
block_weighted_fmt=$(fmt_k "$block_weighted")
limit_fmt=$(fmt_k "$SESSION_WEIGHTED_LIMIT")

# ════════════════════════════════════════
# Line 1: 대화
# ════════════════════════════════════════
pct1=0
[ -n "$used_pct" ] && pct1=$(echo "$used_pct" | awk '{printf "%d", $1+0.5}')

line1="${W}${BOLD}대화${RST}  "
line1="${line1}$(make_bar "$pct1" 20) ${W}${pct1}%${RST}"
line1="${line1}   ${GREEN}↑${total_in_fmt}${RST} ${ORANGE}↓${total_out_fmt}${RST}"
line1="${line1}   ${LAVENDER}${model}${RST}"

# ════════════════════════════════════════
# Line 2: 세션
# ════════════════════════════════════════
line2=""
if [ "$block_weighted" != "0" ]; then
  block_pct=$(awk "BEGIN { p=$block_weighted/$SESSION_WEIGHTED_LIMIT*100; if(p>100)p=100; printf \"%d\",p }")

  remain_str=""
  if [ -n "$block_remaining" ] && [ "$block_remaining" != "0" ]; then
    remain_str=$(echo "$block_remaining" | awk '{
      m = int($1+0.5)
      if (m >= 60) printf "%dh%dm", int(m/60), m%60
      else printf "%dm", m
    }')
  fi

  line2="${W}${BOLD}세션${RST}  "
  line2="${line2}$(make_bar "$block_pct" 20) ${W}${block_pct}%${RST}"
  line2="${line2}   ${W}${BOLD}${block_weighted_fmt}${RST} ${G1}/ ${limit_fmt}${RST}"
  if [ -n "$remain_str" ]; then
    line2="${line2}   ${TEAL}${remain_str} 남음${RST}"
  fi
fi

# --- Output ---
if [ -n "$line2" ]; then
  printf '%b\n%b' "$line1" "$line2"
else
  printf '%b' "$line1"
fi
