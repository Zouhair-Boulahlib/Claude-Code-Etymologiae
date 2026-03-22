# CLAUDE.md — Frontend Project

## Project
[PROJECT_NAME] — [React / Next.js / Vue] frontend application.
[Brief description.]

## Tech Stack
- Framework: [React 18 + Vite / Next.js 14 / Vue 3 + Nuxt]
- Language: TypeScript (strict mode)
- Styling: [Tailwind CSS / CSS Modules / styled-components]
- State: [Zustand / Redux Toolkit / Pinia]
- Testing: [Vitest + Testing Library / Playwright for E2E]

## Commands
- `npm run dev` — start dev server
- `npm run build` — production build
- `npm run test` — run unit tests
- `npm run test:e2e` — run E2E tests
- `npm run lint` — ESLint + Prettier check
- `npm run typecheck` — tsc --noEmit

## Architecture
- Feature-based folder structure: src/features/[feature]/
- Each feature contains: components/, hooks/, api/, types/, __tests__/
- Shared components in src/components/ui/
- API layer in src/lib/api/ — all HTTP calls go through here
- No direct fetch() calls in components

## Code Conventions
- Functional components only, no class components
- Custom hooks for any reusable stateful logic
- Named exports only, no default exports
- Props interfaces defined in the same file as the component
- Use `satisfies` over `as` for type assertions
- Never use `any` — use `unknown` and narrow

## Styling
- Tailwind utility classes for layout and spacing
- Component-specific styles for complex animations
- Design tokens in tailwind.config.ts
- Mobile-first responsive design

## Do NOT
- Install new UI component libraries without asking
- Use inline styles except for dynamic values
- Put API calls directly in components — use the api layer
- Create god components over 200 lines — split them
- Use useEffect for data fetching — use [React Query / SWR / useFetch]
