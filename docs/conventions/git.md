# Git 규칙 — develop 기준 PR (DEC-003)

저장소: WePLi-Team/WePLi-iOS (public) · 통합 브랜치 `develop` · 배포 브랜치 `main`
세부 원본: `docs/git/` (branch · commit · pull-request-template · release-workflow). 이 문서는 스크립트가 검사하는 부분만 요약한다.

## 흐름

1. 작업마다 GitHub 이슈를 먼저 만든다. 이슈 번호가 브랜치 이름에 들어간다. (`/start-feature`)
2. 최신 `develop`에서 브랜치를 만든다.
3. 작은 단위로 커밋한다(`docs/git/micro-strategy.md`).
4. 브랜치를 push하고 `develop`으로 PR을 연다. PR 템플릿(`.github/pull_request_template.md`)을 채운다. (`/finish-feature`)
5. 리뷰 · CI 통과 → 병합 → 브랜치 삭제.
6. `develop` → `main` 배포는 `docs/git/release-workflow.md`. `develop` · `main`에 직접 push하지 않는다.

## 브랜치 이름

`<type>/<issue>-<slug>` — type: `feat` · `fix` · `design` · `refactor` · `chore` · `docs` · `test` · `perf` · `setting` (`.claude/project.sh` `BRANCH_TYPES`)

| 예 | |
|---|---|
| `feat/12-playlist-voting-ui` | 기능 |
| `fix/31-login-crash` | 버그 |
| `design/40-tab-bar` | UI |

`<slug>`는 영어 소문자 · 숫자 · 하이픈, 2–5단어. 한 브랜치는 한 이슈만.

## 커밋 메시지

```
[Type]: 한국어 요약

- 세부 내용

Close #12
```

- Type: `[Feat]` `[Fix]` `[Design]` `[Refactor]` `[Docs]` `[Test]` `[Chore]` `[Add]` `[Del]` `[Comment]` `[Merge]` `[Remove]` `[Setting]` `[Perf]` (`COMMIT_PATTERN`)
- 요약은 한국어, 50자 이내 권장(검사는 72자), 마침표 없음.
- 이슈 연결: `Close #12` · `Refs #12`.
- 커밋 · PR에 `🤖 Generated with Claude Code` · `Co-Authored-By: Claude`를 넣지 않는다(CLAUDE.md).

## 금지

- `develop` · `main`에 `--force` / `--force-with-lease`, 직접 push.
- `git reset --hard`, `git clean -fd` 등으로 아직 커밋하지 않은 변경을 지우는 것.
- 비밀값 커밋(`Configs/Debug.xcconfig` · `Release.xcconfig`는 커밋하지 않는다). 실수로 커밋했다면 **지우기보다 먼저 그 값을 폐기 · 재발급**한다. public 저장소라 push된 순간 노출된 것으로 본다.

## 검증과 병합

- `verify.sh`의 종료 코드를 확인한 **뒤에만** PR 생성 · 병합한다. `;`로 잇지 말고 `&&`.
- CI(`.github/workflows/ci.yml`)가 macOS에서 린트 · 빌드 · 테스트를 돌린다. 로컬 `verify.sh ios` 결과도 PR 본문에 붙인다.
