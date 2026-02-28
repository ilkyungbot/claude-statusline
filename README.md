# claude-statusline

Claude Code 터미널 상태줄 — 대화 컨텍스트 + 5시간 세션 사용량을 한눈에.

```
대화  ━━━━━━━━──────────── 42%   ↑85.2K ↓12.3K   Claude Opus 4.6
세션  ━━━━━━━━━━━━━━━━──── 79%   2.4M / 3.0M     59m 남음
```

## 기능

- **대화**: 컨텍스트 윈도우 사용률 바 + IN/OUT 토큰 + 모델명
- **세션**: 5시간 블록 가중 토큰 사용량 바 + 토큰/한도 + 남은 시간
- 사용량 단계별 색상 변화 (파랑 → 주황 → 빨강)
- [ccusage](https://github.com/ryoppippi/ccusage) 연동으로 세션 쿼타 실시간 확인

## 가중 토큰

Anthropic은 토큰 타입별로 쿼타 비용이 다릅니다. 단순 합산하면 실제 사용량과 크게 차이나므로, 가격 비율 기반 가중치를 적용합니다:

| 토큰 타입 | 가중치 | 가격 기준 |
|---|---|---|
| input | ×1.0 | $3.00/M |
| output | ×5.0 | $15.00/M |
| cache write | ×1.25 | $3.75/M |
| cache read | ×0.1 | $0.30/M |

예시: cache read 1,400만 + output 4만 토큰
- 단순 합산: ~14.8M (실제와 큰 차이)
- 가중 계산: ~1.6M (실제 쿼타에 근접)

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

`statusline-command.sh` 상단에서 가중 토큰 한도를 플랜에 맞게 조정:

```bash
SESSION_WEIGHTED_LIMIT=3000000   # 3M 가중 토큰 (Max 5x 기준)
```

| 플랜 | 권장값 | 설명 |
|------|--------|------|
| Pro | `1000000` | 1M 가중 토큰 |
| Max 5x | `3000000` | 3M 가중 토큰 |
| Max 20x | `12000000` | 12M 가중 토큰 |

> 권장값은 추정치입니다. Claude 앱에서 실제 쿼타를 확인하면서 값을 조정하세요.
