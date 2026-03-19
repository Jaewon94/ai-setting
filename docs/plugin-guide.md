# 플러그인 작성 가이드

ai-setting 플러그인은 Claude Code용 hooks, agents, skills를 패키지로 묶어 배포하는 단위입니다.

## 디렉토리 구조

```
plugins/my-plugin/
├── .claude-plugin/
│   └── plugin.json          # 플러그인 메타데이터 (필수)
├── hooks/
│   └── hooks.json           # hook 등록 (선택)
├── scripts/
│   └── my-hook.sh           # hook 스크립트 (선택)
├── agents/
│   └── my-agent.md          # 에이전트 정의 (선택)
└── skills/
    └── my-skill/
        └── SKILL.md          # 스킬 정의 (선택)
```

## plugin.json (필수)

```json
{
  "name": "my-plugin",
  "version": "0.1.0",
  "description": "플러그인 설명",
  "author": {
    "name": "작성자"
  },
  "keywords": ["claude-code", "hooks"]
}
```

## hooks.json (선택)

hooks.json은 Claude Code의 settings.json hook 형식을 따릅니다.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/scripts/my-hook.sh\""
          }
        ]
      }
    ]
  }
}
```

지원 hook 시점: `PreToolUse`, `PostToolUse`, `Notification`, `Stop`, `SessionStart`

## 설치/제거

```bash
# marketplace에 등록된 플러그인 목록
ai-setting plugin list

# 설치 (hook 스크립트 복사 + settings.json merge)
ai-setting plugin install my-plugin /path/to/project

# 제거
ai-setting plugin uninstall my-plugin /path/to/project

# 업데이트 확인
ai-setting plugin check-update /path/to/project
```

## marketplace.json에 등록

`.claude-plugin/marketplace.json`에 플러그인 엔트리를 추가합니다:

```json
{
  "plugins": [
    {
      "name": "my-plugin",
      "source": "./plugins/my-plugin",
      "description": "플러그인 설명",
      "version": "0.1.0",
      "category": "development",
      "tags": ["claude-code", "hooks"]
    }
  ]
}
```

## 검증

```bash
npm run plugin:validate
```

## 기존 플러그인 참고

- `plugins/ai-setting-core/` — hooks, agents, skills, MCP 포함
- `plugins/ai-setting-strict/` — branch protection hook
- `plugins/ai-setting-team/` — webhook notification hook
