# 프로젝트 설정 — 스킬 · hook · 검증 스크립트가 모두 이 파일 하나를 읽는다(sh로 source).
# 프로젝트마다 다른 값은 여기에만 둔다. 스크립트 본체는 고치지 않는다.
# 처음 채우기: Claude Code에서 /project-setup

# 세션 시작 hook 출력 앞에 붙는 짧은 이름(영어 소문자)
PROJECT_TAG="wepli-ios"

# GitHub 저장소 owner/name. 비우면 `gh repo view`로 알아낸다.
GH_REPO="WePLi-Team/WePLi-iOS"

# 기본 브랜치
BASE_BRANCH="develop"

# 기획 원본 — /project-setup · /design-sync 가 읽는다. 둘 다 비면 대화로 기획 초안을 만든다.
# Claude Design 프로젝트 링크 (https://claude.ai/design/p/<id>)
# 특정 파일만이 아니라 프로젝트 안의 모든 파일(화면 · 이미지 · jsx · js)을 읽고 전체를 구현 범위로 본다.
DESIGN_URL="https://claude.ai/design/p/6a9c7a8f-8a94-4ccc-ac16-11d050f800e1"
# 로컬 기획 문서 경로(저장소 기준, 공백 구분). 예: "docs/spec"
SPEC_PATHS=""

# 브랜치 type (start.sh · check.sh 검사, ERE). 형식: <type>/<issue>-<slug> — DEC-003
BRANCH_TYPES="feat|fix|design|refactor|chore|docs|test|perf|setting"

# 커밋 요약 형식 (ERE). 이 저장소는 `[Feat]: 요약` 형식 — docs/git/commit.md · DEC-003
COMMIT_PATTERN='^\[(Feat|Fix|Design|Refactor|Docs|Test|Chore|Add|Del|Comment|Merge|Remove|Setting|Perf)\]: .+'

# 커밋 요약 언어: ko = 한글이 꼭 들어가야 함 · any = 검사 안 함
COMMIT_LANG="ko"

# 이슈 본문에서 뽑아 안내할 연결 ID (grep -E). 예: REQ-012 · DEC-003 · UI-IOS-10t
# 화면 ID는 Claude Design 화면 번호를 그대로 쓴다: UI-<차수><글자>[-하위] (예: UI-2c · UI-10f) — docs/design/screen-index.md
REF_PATTERN='(REQ-[0-9]{3}|DEC-[0-9]{3}|UI-[0-9]{1,2}[a-z](-[0-9a-z]+)?)'

# 연결 ID 접두어 → 찾을 문서 (공백으로 구분, "접두어=경로")
REF_DOCS="REQ=docs/requirements.md DEC=docs/decisions.md UI=docs/design/screen-index.md"

# 바뀐 경로 → 검증 영역. 한 줄에 "정규식(ERE, 공백 없이) 영역". 위에서부터 첫 일치.
# 아무 줄에도 안 맞으면 영역 other.
AREAS='
^Projects/        ios
^Tuist/           ios
^Configs/         ios
^Workspace\.swift  ios
^Tuist\.swift      ios
^\.swiftlint\.yml  ios
^\.swiftformat    ios
^\.claude/        claude
^\.github/        claude
^docs/            docs
\.md$             docs
'

# 영역별 검증 — verify_<영역> 함수가 있으면 실행, 없으면 SKIP으로 보고한다.
# 종료 코드 0 = PASS. 출력은 로그 파일로 간다. 없는 명령을 성공 처리하지 않는다.
# iOS: 린트 → 아키텍처 검사 → 단위 테스트. 워크스페이스는 `tuist install && tuist generate --no-open`으로 만든다.
#   시뮬레이터는 SIM 환경 변수로 바꾼다(병렬 작업마다 다르게). 기본 iPhone 17.
verify_ios() {
  [ -d WePLi.xcworkspace ] || { echo "WePLi.xcworkspace 없음 — tuist generate --no-open 먼저"; return 1; }
  swiftlint --quiet --config .swiftlint.yml || return 1
  verify_arch || return 1
  xcodebuild test -quiet -workspace WePLi.xcworkspace -scheme WePLi \
    -destination "platform=iOS Simulator,name=${SIM:-iPhone 17}" -parallel-testing-enabled NO
}

# 아키텍처 검사 (TCA 구조 유지 — docs/conventions/architecture.md · DEC-002)
# 1) View · Components 는 네트워크 · 저장 · 백엔드 SDK를 직접 쓰지 않는다
# 2) Reducer(*Feature.swift)는 외부 SDK를 직접 쓰지 않고 @Dependency Client를 거친다
verify_arch() {
  bad=0
  io='^import (Moya|Supabase|KeychainAccess|GoogleSignIn)|URLSession|UserDefaults\.standard|FileManager\.default'
  for f in $(find Projects -name '*.swift' -not -path '*/Derived/*' -not -path '*/Generated/*' \
      \( -name '*View.swift' -o -path '*/Components/*' -o -name '*Feature.swift' \)); do
    if grep -qE "$io" "$f"; then grep -nE "$io" "$f" | sed "s#^#$f:#"; bad=1; fi
  done
  [ $bad -eq 0 ]
}
