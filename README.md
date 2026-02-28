# claude-statusline

Claude Code 터미널 상태줄 — 대화 컨텍스트 + 5시간 세션 사용량을 한눈에.

```
대화  ━━━━━━━━──────────── 42%   ↑85.2K ↓12.3K   Claude Opus 4.6
세션  ━━━━━━━━━━━━━━━───── 77%   11.7M / 15.0M   1h16m 남음
```

## 기능

- **대화**: 컨텍스트 윈도우 사용률 바 + IN/OUT 토큰 + 모델명
- **세션**: 5시간 블록 토큰 사용량 바 + 토큰/한도 + 남은 시간
- 사용량 단계별 색상 변화 (파랑 → 주황 → 빨강)
- [ccusage](https://github.com/ryoppippi/ccusage) 연동으로 세션 쿼타 실시간 확인

## 설치

### 1. 의존성

```bash
# ccusage (세션 사용량 조회용)
npm install -g ccusage
```

### 2. 스크립트 복사

```bash
cp statusline-command.sh ~/.claude/statusline-command.sh
chmod +x ~/.claude/statusline-command.sh
```

### 3. Claude Code 설정

`~/.claude/settings.json`에 추가:

```json
{
  "statusLine": {
    "type": "command",
    "command": "bash ~/.claude/statusline-command.sh"
  }
}
```

## 설정

`statusline-command.sh` 상단에서 토큰 한도를 플랜에 맞게 조정:

```bash
SESSION_TOKEN_LIMIT=15000000   # Max 5x 기준 (15M)
```

| 플랜 | 권장값 |
|------|--------|
| Pro | `5000000` |
| Max 5x | `15000000` |
| Max 20x | `60000000` |
