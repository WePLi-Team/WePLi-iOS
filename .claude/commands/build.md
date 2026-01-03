# 프로젝트 빌드

WePLi iOS 프로젝트를 빌드합니다.

## 빌드 명령어

```bash
# Tuist로 프로젝트 생성 (의존성 변경 시)
tuist install && tuist generate

# Debug 빌드
xcodebuild -workspace WePLi.xcworkspace -scheme WePLi \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  build

# 또는 Fastlane 사용
bundle exec fastlane ios build_debug
```

## 빌드 실패 시

1. 의존성 재설치: `tuist clean && tuist install && tuist generate`
2. DerivedData 정리: `rm -rf ~/Library/Developer/Xcode/DerivedData`
3. 캐시 정리: `tuist cache clean`

빌드 결과를 확인하고 에러가 있으면 수정 방법을 제안해주세요.
