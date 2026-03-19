## Frontend 규칙
- 컴포넌트는 단일 책임 원칙을 따른다 (UI 로직과 비즈니스 로직 분리)
- 상태 관리는 최소 범위에서 — 로컬 state로 충분하면 전역 store에 넣지 않는다
- CSS/스타일은 컴포넌트 스코프로 제한 (CSS Modules, Tailwind, styled-components 등)
- 이미지/폰트는 최적화 후 사용 (next/image, webp, font-display: swap)
- 빌드 산출물 크기를 의식한다 — 불필요한 의존성 추가 전 번들 사이즈 영향 확인
- 접근성(a11y) 기본값: 시맨틱 HTML, aria-label, 키보드 네비게이션
- 테스트: 컴포넌트 단위 테스트 + 주요 사용자 플로우 E2E 테스트
