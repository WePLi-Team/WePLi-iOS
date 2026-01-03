# 테스트 실행

WePLi iOS 프로젝트의 테스트를 실행합니다.

## 테스트 명령어

```bash
# xcodebuild로 테스트
xcodebuild -workspace WePLi.xcworkspace -scheme WePLi \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test

# 또는 Fastlane 사용
bundle exec fastlane ios test
```

## 특정 테스트만 실행

```bash
# 특정 테스트 클래스
xcodebuild -workspace WePLi.xcworkspace -scheme WePLi \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -only-testing:WePLiTests/{TestClassName} \
  test
```

## 테스트 실패 시

1. 실패한 테스트 케이스 확인
2. 실패 원인 분석 (State 변경, Effect 누락 등)
3. 수정 후 재실행

테스트 결과를 분석하고 실패한 테스트가 있으면 수정 방안을 제안해주세요.
