# 실전 적용 테스트: research traceability

**적용일**: 2026-03-20
**대상**: 샘플 TypeScript 프로젝트 (`package.json`, `src/`만 있는 최소 구조)
**적용 모드**: `--skip-ai --all`

---

## 적용 목적

이번 테스트의 목적은 다음 3가지를 확인하는 것입니다.

1. `docs/research-notes.md`와 `docs/decisions.md`가 기본 생성되는지
2. 출처/확인일/참조 ID 형식이 템플릿 차원에서 충분히 안내되는지
3. `doctor`가 placeholder, 참조 형식, 링크 형식을 실제로 점검하는지

---

## 적용 결과

### 생성된 문서 ✅

| 파일 | 역할 |
|------|------|
| `docs/research-notes.md` | 공식 문서/외부 조사 근거 기록 |
| `docs/decisions.md` | 최종 기술 결정 기록 |
| `BEHAVIORAL_CORE.md` | 공통 행동 원칙 |
| `CLAUDE.md` / `AGENTS.md` | 프로젝트 규칙/컨텍스트 |

### research-notes 템플릿 확인 ✅

기본 템플릿에 아래 항목이 포함됨:

- `R-001` 형식의 조사 ID
- `확인일`
- `출처`
- `핵심 내용`
- `판단/메모`
- `관련 결정`

또한 아래 규칙이 문서에 명시됨:

- 출처는 `문서명 — URL`
- 결정으로 이어지면 `D-xxx`와 연결
- 요약은 짧게 남김

### decisions 템플릿 확인 ✅

기본 템플릿에 아래 항목이 포함됨:

- `D-001` 형식의 결정 ID
- `관련 조사`
- `확인일`
- `근거 문서`
- `이유`
- `트레이드오프`

즉, "무엇을 선택했는지"뿐 아니라 "무엇을 보고 그렇게 판단했는지"까지 기록하는 구조가 기본으로 제공됨.

---

## Doctor 결과

샘플 프로젝트에 `--skip-ai --all` 적용 후 `--doctor` 실행 결과:

- `docs/research-notes.md 존재`
- `docs/decisions.md 존재`
- `docs/decisions.md 관련 조사 형식 확인`
- `docs/decisions.md 확인일 형식 확인`
- `docs/decisions.md 근거 문서 링크 형식 확인`
- `docs/research-notes.md 조사 ID 형식 확인`
- `docs/research-notes.md 확인일 형식 확인`
- `docs/research-notes.md 출처 링크 형식 확인`
- `docs/research-notes.md 관련 결정 형식 확인`

즉, `doctor`는 이제 단순 파일 존재 여부가 아니라 아래도 함께 봄:

- placeholder 잔존 여부
- `R-xxx`, `D-xxx` 참조 형식
- `YYYY-MM-DD` 날짜 형식
- `문서명 — URL` 링크 형식

---

## 해석

### 좋아진 점

- 출처 기반 판단을 프로젝트 문서에 남길 기본 틀이 생김
- 기술 조사와 최종 결정을 분리해서 기록할 수 있음
- `doctor`가 형식 누락을 빠르게 잡아줌
- 사용자가 "이 결정이 어디서 왔는지"를 나중에 추적하기 쉬움

### 아직 남는 한계

- `--skip-ai` 기준에서는 템플릿 placeholder가 그대로 남는 것이 정상이라, 실제 값어치는 AI 채우기나 수동 작성 이후에 생김
- 현재는 형식 검증만 하고, URL의 실제 접근 가능 여부까지 검증하지는 않음
- 조사 결과가 정말 최신 공식 문서에 근거했는지는 작성자/에이전트의 성실성에 여전히 일부 의존함

---

## 결론

- `research-notes + decisions` 구조는 **신뢰성 향상에 실제로 도움이 되는 방향**임
- 특히 "출처 링크 + 확인일 + 참조 ID" 조합이 들어가면서 단순 의견 문서보다 검증 가능성이 높아짐
- `doctor`까지 연결되면서 운영 기능으로도 의미가 생김
- 다음 개선 포인트는 **AI 자동 채우기 결과가 실제로 이 문서를 얼마나 잘 채우는지**를 실제 프로젝트에서 추가 검증하는 것
