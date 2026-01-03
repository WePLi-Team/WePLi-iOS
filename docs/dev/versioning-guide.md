# iOS 버전 관리 가이드

이 문서는 WePLi iOS 앱의 버전 관리 방법을 설명합니다.

## 버전 체계

### iOS 앱 버전 구성

iOS 앱은 두 가지 버전 정보를 관리합니다:

| 키 | 설명 | 예시 | 위치 |
| --- | --- | --- | --- |
| `CFBundleShortVersionString` | 마케팅 버전 (사용자에게 표시) | `1.2.0` | App Store |
| `CFBundleVersion` | 빌드 번호 (내부 식별용) | `42` | TestFlight |

### Semantic Versioning

마케팅 버전은 [SemVer](https://semver.org/lang/ko/)를 따릅니다:

```
MAJOR.MINOR.PATCH

예: 1.2.3
```

| 버전 | 변경 시점 | 예시 |
| ---- | --------- | ---- |
| **MAJOR** | 대규모 UI/UX 변경, Breaking changes | 1.0.0 → 2.0.0 |
| **MINOR** | 새로운 기능 추가 | 1.0.0 → 1.1.0 |
| **PATCH** | 버그 수정, 성능 개선 | 1.0.0 → 1.0.1 |

---

## 버전 업데이트 방법

### 1. Tuist를 통한 버전 관리

`Projects/App/Project.swift`에서 버전을 관리합니다:

```swift
let project = Project(
  name: "WePLi",
  settings: .settings(
    base: [
      "MARKETING_VERSION": "1.2.0",
      "CURRENT_PROJECT_VERSION": "42",
      // ...
    ]
  ),
  // ...
)
```

### 2. Fastlane을 통한 빌드 번호 증가

```bash
# TestFlight 최신 빌드 번호 기준으로 자동 증가
bundle exec fastlane ios bump_build
```

### 3. 수동 업데이트

Xcode에서 직접 수정:
1. 프로젝트 선택 → General 탭
2. Identity 섹션에서 Version, Build 수정

---

## 버전 업데이트 시점

### MAJOR 버전 (1.x.x → 2.0.0)

- 앱 전체 UI/UX 리디자인
- 핵심 기능의 근본적인 변경
- 기존 데이터 마이그레이션 필요
- 최소 지원 iOS 버전 변경

### MINOR 버전 (1.0.x → 1.1.0)

- 새로운 화면/기능 추가
- 기존 기능 개선
- 새로운 API 연동

### PATCH 버전 (1.0.0 → 1.0.1)

- 버그 수정
- 성능 최적화
- 텍스트/번역 수정
- 긴급 핫픽스

---

## 빌드 번호 관리

### 규칙

- 빌드 번호는 **단조 증가**해야 함 (App Store 요구사항)
- 같은 마케팅 버전이라도 빌드 번호는 달라야 함
- TestFlight 업로드마다 빌드 번호 증가

### 자동화

```bash
# Fastlane에서 최신 TestFlight 빌드 번호 + 1
bundle exec fastlane ios bump_build

# 또는 CI에서 자동 증가 (GitHub Actions run_number 활용)
CURRENT_PROJECT_VERSION=${{ github.run_number }}
```

---

## 릴리즈 워크플로우

### 1. 개발 완료

```bash
# 버전 업데이트 (Project.swift 수정)
MARKETING_VERSION = "1.2.0"

# 커밋
git commit -m "[Chore]: v1.2.0 릴리즈 준비"
```

### 2. TestFlight 베타 배포

```bash
# 빌드 번호 증가 및 TestFlight 업로드
bundle exec fastlane ios beta_api_key
```

### 3. App Store 제출

```bash
# 최종 아카이브 생성
bundle exec fastlane ios archive_release
```

### 4. 릴리즈 태그

```bash
git tag -a v1.2.0 -m "Release v1.2.0"
git push origin v1.2.0
```

---

## 버전 확인 방법

### 코드에서 버전 읽기

```swift
// 마케팅 버전
let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

// 빌드 번호
let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String

// 전체 버전 문자열
let fullVersion = "\(version ?? "0") (\(build ?? "0"))"  // "1.2.0 (42)"
```

### Xcode에서 확인

1. 프로젝트 설정 → General → Identity
2. Version (마케팅 버전)
3. Build (빌드 번호)

### CLI에서 확인

```bash
# Info.plist에서 직접 읽기
/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" \
  Projects/App/Derived/InfoPlists/WePLi-Info.plist
```

---

## 버전 히스토리 관리

### Git 태그 규칙

```bash
# 정식 릴리즈
git tag -a v1.2.0 -m "Release v1.2.0"

# 베타 릴리즈 (선택)
git tag -a v1.2.0-beta.1 -m "Beta release v1.2.0-beta.1"
```

### GitHub Releases

각 릴리즈에 변경사항 기록:

```bash
gh release create v1.2.0 \
  --title "v1.2.0" \
  --notes "## What's Changed
- 플레이리스트 투표 기능 추가
- 로그인 버그 수정
- 성능 개선"
```

---

## 참고 자료

- [Apple - Versioning](https://developer.apple.com/documentation/bundleresources/information_property_list/cfbundleversion)
- [Semantic Versioning](https://semver.org/lang/ko/)
- [릴리즈 워크플로우](../git/release-workflow.md)
