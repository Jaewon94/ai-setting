## Frontend Rules
- Components follow the single responsibility principle (separate UI logic from business logic)
- State management at minimum scope -- if local state is sufficient, don't put it in global store
- CSS/styles are scoped to the component (CSS Modules, Tailwind, styled-components, etc.)
- Images/fonts must be optimized before use (next/image, webp, font-display: swap)
- Be conscious of build artifact size -- check bundle size impact before adding unnecessary dependencies
- Accessibility (a11y) defaults: semantic HTML, aria-label, keyboard navigation
- Testing: component unit tests + E2E tests for key user flows
