### Web — TypeScript · React (Next.js · Vite) (후보 B 구현)

| 구성 | 구현 |
|---|---|
| View | 컴포넌트(`<Screen>Page.tsx` · 기능 컴포넌트) — props · 훅 결과로 그리기만 |
| ViewModel | 화면 훅 `use<Screen>ViewModel()` — 화면 상태 · 행동 함수 반환. 서버 상태는 기존 도구(TanStack Query 등)가 있으면 그것을 훅 안에서 사용 |
| UseCase | `src/features/<f>/domain/<verb><Noun>.ts` 순수 함수 · 클래스 — React · fetch · 브라우저 API import 금지 |
| Repository | Domain: `interface <Name>Repository`. Data: `create<Name>Repository(httpClient)` · 테스트: `createInMemory<Name>Repository()` |
| DI | `src/app/container.ts`에서 조립, React Context(`<AppProvider>`)로 내려준다. 테스트는 Provider에 가짜 구현 |
| Router | 프레임워크 라우터(Next App Router · React Router) 위에 `src/app/routes.ts`의 타입 있는 목적지(`routes.feature.detail(id)`)와 `useAppRouter().navigate(...)`. 컴포넌트에 URL 문자열을 직접 쓰지 않는다 |
| State Machine | `type <Name>State` 유니온 + `transition(state, event)` 순수 함수(필요하면 XState는 DEC로 결정) |
| 테스트 | Domain · 훅: Vitest · Jest. 컴포넌트: Testing Library. E2E: Playwright(핵심 흐름만) |

Next.js 서버 컴포넌트 · Route Handler는 Data 계층 역할(서버에서 Repository 호출)로 보고 `features/<f>/data/`를 부른다. 페이지 파일(`app/**/page.tsx`)은 얇게 두고 기능 폴더의 View를 렌더링만 한다.

경로 예: `src/features/<f>/presentation/…` · `src/features/<f>/domain/…` · `src/features/<f>/data/…`

아키텍처 검사(`verify_arch`):

```sh
verify_arch() {
  bad=0
  grep -rlE "from ['\"](react|next/|axios)|fetch\(" --include=*.ts --include=*.tsx src 2>/dev/null | grep '/domain/' && bad=1
  grep -rlE "from ['\"].*/data/|fetch\(" --include=*.tsx src 2>/dev/null | grep '/presentation/' && bad=1
  [ $bad -eq 0 ]
}
```
