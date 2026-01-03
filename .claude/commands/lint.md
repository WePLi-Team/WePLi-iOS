# 린트 및 포맷 검사

SwiftLint와 SwiftFormat을 실행하여 코드 품질을 검사합니다.

## 실행할 명령어

```bash
# SwiftLint 검사
swiftlint --config .swiftlint.yml

# SwiftFormat 검사 (lint 모드)
swiftformat --lint . --config .swiftformat
```

## 자동 수정 (요청 시)

```bash
# SwiftLint 자동 수정
swiftlint --fix --config .swiftlint.yml

# SwiftFormat 자동 수정
swiftformat . --config .swiftformat
```

## 주요 규칙

### SwiftLint
- Line length: warning at 120, error at 140
- `print()` 사용 금지 (Logger/OSLog 사용)
- force_unwrapping, force_cast, force_try는 warning

### SwiftFormat
- 2-space indentation
- Max width 120
- `--self insert` 적용

실행 결과를 확인하고 경고나 에러가 있으면 수정 방법을 안내해주세요.
