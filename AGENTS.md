# AGENTS.md — WePLi 공통 작업 규칙

WePLi는 테마별 릴레이리스트에 곡을 추천하고 투표해 플레이리스트를 함께 완성하는 소셜 음악 iOS 앱이다(SwiftUI · TCA).
이 파일이 모든 AI 도구의 기본 규칙 원본이다. 세부 규칙은 링크한 문서에 있다.

## 기준 문서 (충돌 시 위가 우선)

1. 사용자 결정 — `docs/decisions.md` (DEC-nnn)
2. 기획 · 디자인 원본 — Claude Design 「위플리 iOS UI 개선」 https://claude.ai/design/p/6a9c7a8f-8a94-4ccc-ac16-11d050f800e1 (claude_design MCP로 읽기만). 정리본 `docs/design/README.md`
3. 화면 — `docs/design/screen-index.md` (UI-1a … UI-11e)
4. 요구사항 — `docs/requirements.md` (REQ-nnn)
5. 이 저장소 규칙 — `docs/conventions/code.md`, `docs/conventions/git.md`, `CLAUDE.md`, `docs/git/`

## 기술 스택

| 영역 | 스택 | 위치 |
|---|---|---|
| 앱 | SwiftUI · TCA(ComposableArchitecture) · iOS 16.0+ · iPhone | `Projects/App/` |
| 의존성 · 프로젝트 | Tuist 4.71.0(mise) · SPM | `Tuist/Package.swift` · `Projects/App/Project.swift` |
| 네트워크 · 백엔드 | Moya · Supabase (계획 · 미설치, 지금은 목업 Client) | 기능별 `Client/` |
| 인증 · 저장 | Sign in with Apple · GoogleSignIn · KeychainAccess (GoogleSignIn · KeychainAccess는 계획 · 미설치) | `Features/Login` |
| 이미지 | Kingfisher (계획 · 미설치) | |
| 품질 | SwiftLint · SwiftFormat · XCTest(TestStore) · CI(GitHub Actions macOS) | `.swiftlint.yml` · `.github/workflows/ci.yml` |

아키텍처(계층 · 폴더 · Router · 에이전트 역할): `docs/conventions/architecture.md`. 폴더 · 이름 규칙: `docs/conventions/code.md`.

## 반드시

- **원문대로 만든다.** 디자인 · 문구 · 값은 기준 문서와 토큰 · 설정 값만 쓴다(하드코딩 금지). 다르게 만들어야 하면 멈추고 묻는다.
- **시간은 Asia/Seoul 기준**으로 계산한다 — 릴레이 마감 · 오늘의 한 곡 · 시즌 · 차트 갱신 시각(DEC-004).
- **개인정보 · 토큰을 로그에 남기지 않는다.** 소셜 토큰 · 세션은 Keychain에만 둔다. `print` 대신 `Logger`를 쓴다. public 저장소이므로 `Configs/Debug|Release.xcconfig`를 커밋하지 않는다.
- **투표 · 점수 · 순위는 서버 값이 원본이다.** 클라이언트는 낙관적으로 표시만 하고, 실패하면 되돌린다. 순위를 클라이언트에서 확정하지 않는다.
- **iOS 26 이상은 Claude Design 원본대로, iOS 16–25는 같은 레이아웃에 크롬만 UI-12d 규칙으로 바꾼다**(DEC-005). 12d에 없는 iOS 16 모양을 새로 만들어야 하면 멈추고 묻는다.
- **정한 아키텍처를 지킨다**(`docs/conventions/architecture.md`). 기존 패턴을 먼저 재사용하고, 새 구조 · 라이브러리는 임의로 들이지 않는다.
- **작업 단위는 이슈 하나.** 코드 · 커밋에 관련 REQ · DEC ID를 적는다.
- **완료 보고 전에 검증한다.** 실제로 실행한 빌드 · 테스트 명령과 결과를 적고, 실행하지 않았으면 "미실행"이라고 쓴다.
- 결과 보고 순서: 수행 / 검증 / 차단 / 내가 할 일 / 다음 단계.

## 금지

- 승인 없는 디자인 · 문구 변경, 요청과 무관한 리팩터링 · 이름 변경 · 포맷 일괄 변경
- 운영 데이터 수정 · 운영 배포 · 결제 · 권한 확대 — 사용자 확인 필수
- 비밀값 노출 — 키 · 토큰 · 비밀번호를 코드 · 로그 · 커밋 · 이슈에 쓰지 않는다. 변수 이름만 `.env.example`
- 검증 없는 "완료" 보고, 읽지 않은 자료를 읽었다고 하기
- `git push --force`, `git reset --hard`, 남의 미커밋 변경 삭제

## Git

develop 기준 PR(DEC-003). 브랜치 `<type>/<issue>-<slug>`, 커밋 `[Feat]: 한국어 요약`. 커밋 · PR에 Claude 생성 문구나 Co-Authored-By를 넣지 않는다. 상세: `docs/conventions/git.md` · `docs/git/`.

## 미결정 (정해지기 전에 임의로 정하지 않는다)

- 로그인 시안(UI-1a · 3f), 카카오 로그인 포함 여부
- 백엔드: 미정. Supabase 직접 사용인지, 자체 API(Moya, `API_BASE_URL`)인지, 실시간(순위 · SharePlay 방) 방식. 정해지기 전까지 Client는 목업 `liveValue`로 둔다
- **정책 · 문구 충돌은 사용자가 나중에 다시 묻기로 함** — 해당 기능 이슈를 시작할 때 아래 항목을 먼저 질문한다
  - 신고 · 차단 콘텐츠 정책(UI-5a · 7e · 11d), 이용 제한 단계, 탈퇴 유예 · 재가입 제한
  - 점수식: 취향 궁합(6d) · 시즌 랭킹 보상(8f) · 칭호 조건(8d)
  - 10e 게시글 삭제 후 「되돌리기」 유효 시간(「삭제 직후」가 몇 초인지)
- 디자인 토큰 생성 방식(Colors.xcassets · SwiftGen · 코드 상수)과 Core 모듈(DesignSystem · Network · Utils) 사용 시점
