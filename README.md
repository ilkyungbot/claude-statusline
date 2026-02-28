# claude-statusline

Claude Code 터미널 상태줄 — 대화 컨텍스트 사용량을 한눈에.

```
대화  ███████████░░░░░░░░░ 55%   ↑85.2K ↓12.3K   Claude Opus 4.6
      90.0K 남음   OUT 누적 12.3K
```

## 기능

- **컨텍스트 바**: `█░` 두꺼운 프로그레스 바로 사용률 시각화
- **5단계 색상**: 초록(~25%) → 시안(~50%) → 파랑(~65%) → 주황(~80%) → 빨강(80%+)
- **남은 컨텍스트**: 절대값으로 남은 토큰 표시 (위험 시 색상 변경)
- **OUT 누적**: output 토큰 누적량 (쿼타 소비의 핵심 지표)
- **IN/OUT 토큰**: 이번 대화의 입출력 토큰 현황

## 설치

### 1. 스크립트 복사

```bash
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

### 2. Claude Code 설정

`~/.claude/settings.json`에 추가:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

의존성 없이 `jq`만 있으면 동작합니다.
