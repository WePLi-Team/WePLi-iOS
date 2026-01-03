# GitHub 이슈 라벨 가이드

이 문서는 WePLi iOS 프로젝트에서 사용하는 GitHub 이슈 라벨을 정의합니다.

> 라벨 설정 파일: `.github/labels.yml`

## 라벨 카테고리

### 1. 타입 (Type) - 7개

이슈의 종류를 나타냅니다. **필수**로 하나 이상 선택합니다.

| 라벨            | 색상       | 설명                           | 예시                           |
| --------------- | ---------- | ------------------------------ | ------------------------------ |
| `bug`           | 🔴 #d73a4a | 버그, 오류 수정                | 로그인 실패, 데이터 미표시     |
| `enhancement`   | 🔵 #a2eeef | 새 기능 추가 또는 기능 개선    | 새 화면 구현, 기능 추가        |
| `documentation` | 🔵 #0075ca | 문서 작성 또는 수정            | README 업데이트, API 문서      |
| `refactor`      | 🟣 #9c27b0 | 코드 리팩토링 (기능 변경 없음) | 컴포넌트 분리, 코드 정리       |
| `chore`         | ⚪ #ededed | 빌드, 설정, 인프라 작업        | 패키지 업데이트, CI 설정       |
| `test`          | 🟢 #0e8a16 | 테스트 작성 또는 수정          | 유닛 테스트, UI 테스트         |
| `hotfix`        | 🔴 #ff0000 | 프로덕션 긴급 수정             | 크리티컬 버그 즉시 수정        |

### 2. 우선순위 (Priority) - 4개

작업의 긴급도를 나타냅니다. 가능하면 설정합니다.

| 라벨                 | 색상       | 설명           | SLA       |
| -------------------- | ---------- | -------------- | --------- |
| `priority: critical` | 🔴 #b60205 | 즉시 수정 필요 | 24시간 내 |
| `priority: high`     | 🟠 #d93f0b | 높은 우선순위  | 1주일 내  |
| `priority: medium`   | 🟡 #fbca04 | 중간 우선순위  | 2주일 내  |
| `priority: low`      | 🟢 #c2e0c6 | 낮은 우선순위  | 백로그    |

### 3. 상태 (Status) - 5개

이슈의 진행 상태를 나타냅니다.

| 라벨                      | 색상       | 설명                           |
| ------------------------- | ---------- | ------------------------------ |
| `status: in progress`     | 🔵 #1d76db | 작업 진행 중                   |
| `status: review needed`   | 🟠 #f9d0c4 | 코드 리뷰 필요                 |
| `status: blocked`         | 🔴 #e11d21 | 다른 이슈/외부 요인으로 블로킹 |
| `status: on hold`         | ⚪ #bfd4f2 | 일시적으로 보류                |
| `status: ready for merge` | 🟢 #0e8a16 | 승인 완료, 머지 대기           |

### 4. 모듈 (Module) - 3개

영향받는 Tuist 모듈을 나타냅니다.

| 라벨               | 색상       | 경로                         | 설명                 |
| ------------------ | ---------- | ---------------------------- | -------------------- |
| `module: app`      | 🔵 #006b75 | `Projects/App`               | 메인 앱 모듈         |
| `module: WePLiKit` | 🟣 #5319e7 | `Projects/Core/DesignSystem` | 공유 UI 컴포넌트     |
| `module: WePLiCore`| 🔴 #b60205 | `Projects/Core`              | 핵심 비즈니스 로직   |

### 5. TCA 아키텍처 (Architecture) - 4개

TCA 관련 작업 영역을 나타냅니다.

| 라벨              | 색상       | 설명                    |
| ----------------- | ---------- | ----------------------- |
| `tca: state`      | 🔵 #84b6eb | State 구조 관련         |
| `tca: action`     | 🟣 #7057ff | Action 정의 관련        |
| `tca: reducer`    | 🟢 #008672 | Reducer 로직 관련       |
| `tca: dependency` | 🟡 #ffd33d | Dependency 주입 관련    |

### 6. 기능 영역 (Feature Area) - 6개

특정 기능 영역을 나타냅니다.

| 라벨             | 색상       | 설명                |
| ---------------- | ---------- | ------------------- |
| `area: auth`     | 🟣 #d4c5f9 | 인증 및 권한 관리   |
| `area: playlist` | 🔵 #c5def5 | 플레이리스트 기능   |
| `area: voting`   | 🔵 #bfdadc | 투표 시스템 기능    |
| `area: ui/ux`    | 🟠 #f7c6c7 | UI/UX 개선          |
| `area: network`  | 🟡 #fef2c0 | 네트워크 & API      |
| `area: database` | 🟠 #e99695 | 데이터베이스 & 저장 |

### 7. iOS 플랫폼 (Platform) - 4개

iOS 개발 관련 세부 기술을 나타냅니다.

| 라벨                | 색상       | 설명                |
| ------------------- | ---------- | ------------------- |
| `ios: swiftui`      | 🟠 #fa7343 | SwiftUI 관련        |
| `ios: performance`  | 🟠 #ff9800 | 성능 최적화         |
| `ios: memory`       | 🟤 #795548 | 메모리 관리 이슈    |
| `ios: accessibility`| 🟢 #4caf50 | 접근성 개선         |

### 8. 기기/OS (Device/OS) - 4개

특정 기기나 OS 버전 관련 이슈입니다.

| 라벨           | 색상       | 설명                |
| -------------- | ---------- | ------------------- |
| `device: iPhone` | ⚪ #e7e7e7 | iPhone 전용 이슈   |
| `device: iPad`   | ⚪ #d3d3d3 | iPad 전용 이슈     |
| `os: iOS 17+`    | ⚪ #c0c0c0 | iOS 17 이상 전용   |
| `os: iOS 18+`    | ⚪ #a8a8a8 | iOS 18 이상 전용   |

### 9. 빌드 & 인프라 (Build & Infra) - 5개

빌드, 배포, CI/CD 관련 라벨입니다.

| 라벨             | 색상       | 설명                      |
| ---------------- | ---------- | ------------------------- |
| `build: tuist`   | 🔵 #3f51b5 | Tuist 설정                |
| `build: spm`     | 🟠 #ff5722 | Swift Package Manager     |
| `ci/cd`          | 🔵 #106ba3 | CI/CD 파이프라인          |
| `github-actions` | 🟣 #6f42c1 | GitHub Actions 워크플로우 |
| `dependencies`   | 🔵 #0366d6 | 의존성 업데이트           |

### 10. 보안/기술부채 (Security/Tech Debt) - 4개

| 라벨              | 색상       | 설명                                |
| ----------------- | ---------- | ----------------------------------- |
| `security`        | 🔴 #ee0701 | 보안 취약점 또는 개선               |
| `privacy`         | 🟠 #ff5722 | 개인정보보호 관련                   |
| `tech debt`       | ⚪ #607d8b | 기술 부채 해결 필요                 |
| `breaking change` | 🔴 #d73a4a | 마이그레이션 필요한 Breaking Change |

### 11. 릴리즈 & 기타 (Release & Misc) - 8개

| 라벨               | 색상       | 설명                 |
| ------------------ | ---------- | -------------------- |
| `release`          | 🔵 #00bcd4 | 릴리즈 관련          |
| `discussion`       | 🟢 #98d8c8 | 논의 필요            |
| `good first issue` | 🟣 #7057ff | 신규 기여자에게 적합 |
| `help wanted`      | 🟢 #008672 | 추가 도움 필요       |
| `question`         | 🟣 #d876e3 | 추가 정보 요청       |
| `duplicate`        | ⚪ #cfd3d7 | 중복 이슈            |
| `invalid`          | 🟡 #e4e669 | 유효하지 않은 이슈   |
| `wontfix`          | ⚪ #ffffff | 수정하지 않을 이슈   |

### 12. 외부 연동 (External) - 2개

| 라벨                  | 색상       | 설명            |
| --------------------- | ---------- | --------------- |
| `external: api`       | 🔵 #0052cc | 외부 API 연동   |
| `external: analytics` | 🔵 #172b4d | 분석 서비스     |

---

## 라벨 사용 가이드

### 이슈 생성 시

1. **타입 라벨 필수**: 최소 1개의 타입 라벨 선택
2. **영역 라벨 권장**: 관련 기능 영역이 명확하면 선택
3. **모듈 라벨 권장**: 영향받는 모듈이 명확하면 선택
4. **우선순위**: 긴급도가 있으면 설정

```
예시: 로그인 버그 수정 이슈
라벨: bug, priority: high, module: app, area: auth
```

### 작업 진행 시

1. 작업 시작 → `status: in progress` 추가
2. PR 생성 → `status: review needed` 추가
3. 블로킹 발생 → `status: blocked` 추가 (코멘트로 사유 명시)
4. 승인 완료 → `status: ready for merge` 추가

### 라벨 조합 예시

| 상황                   | 라벨 조합                                                   |
| ---------------------- | ----------------------------------------------------------- |
| 새 기능 개발           | `enhancement` + `area: playlist` + `module: app`            |
| 긴급 버그 수정         | `bug` + `priority: critical` + `hotfix`                     |
| UI 컴포넌트 추가       | `enhancement` + `module: WePLiKit` + `area: ui/ux`          |
| TCA Reducer 구현       | `enhancement` + `tca: reducer` + `area: voting`             |
| SwiftUI 성능 개선      | `refactor` + `ios: swiftui` + `ios: performance`            |
| Tuist 설정 변경        | `chore` + `build: tuist`                                    |
| 보안 취약점 수정       | `bug` + `security` + `priority: critical`                   |

---

## 라벨 관리

### 라벨 동기화

```bash
# labels.yml 파일로 라벨 동기화 (CI에서 자동 실행됨)
gh label list --limit 100
```

---

## 관련 문서

- [이슈 템플릿](./issue-template.md)
- [브랜치 컨벤션](./branch.md)
- [커밋 컨벤션](./commit.md)
