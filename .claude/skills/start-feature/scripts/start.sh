#!/bin/sh
# start-feature: 이슈 확인 → 기본 브랜치 최신화 → 작업 브랜치 생성.
# 사용: start.sh <type> <issue> <slug>
#   type  = .claude/project.sh BRANCH_TYPES 중 하나 (기본 feat | fix | docs | chore)
#   issue = GitHub 이슈 번호(숫자)
#   slug  = 영어 소문자·숫자·하이픈, 2–5단어 (예: clock-in-qr)
# 종료 코드: 0 성공 · 1 입력 오류 · 2 작업 트리 변경 있음 · 3 이슈 문제 · 4 git 실패
set -u
cd "$(git rev-parse --show-toplevel)" || exit 4
. ./.claude/lib.sh && load_project || exit 1

if [ $# -ne 3 ]; then
  echo "사용: start.sh <$BRANCH_TYPES> <issue> <slug>" >&2; exit 1
fi
type=$1 issue=$2 slug=$3

echo "$type" | grep -Eq "^($BRANCH_TYPES)$" || { echo "type은 $BRANCH_TYPES 중 하나: $type" >&2; exit 1; }
echo "$issue" | grep -Eq '^[1-9][0-9]*$' || { echo "issue는 숫자: $issue" >&2; exit 1; }
echo "$slug" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+){1,4}$' || { echo "slug는 소문자·숫자·하이픈 2–5단어: $slug" >&2; exit 1; }
[ -n "$GH_REPO" ] || { echo "중단: GitHub 저장소를 모름 — .claude/project.sh GH_REPO" >&2; exit 3; }

branch="$type/$issue-$slug"

# 1. 커밋하지 않은 변경이 있으면 멈춘다(브랜치 전환 시 변경이 따라가거나 충돌하므로).
dirty=$(git status --porcelain)
if [ -n "$dirty" ]; then
  echo "중단: 커밋하지 않은 변경이 있다. 정리 방법은 사용자가 정한다(커밋 · stash · 그대로 두기)." >&2
  echo "$dirty" | head -20 >&2
  exit 2
fi

# 2. 이슈가 있고 열려 있는지
info=$(gh issue view "$issue" -R "$GH_REPO" --json number,title,state,labels,body 2>&1) || {
  echo "중단: 이슈 #$issue 조회 실패 — $info" >&2; exit 3; }
state=$(printf '%s' "$info" | jq -r .state)
[ "$state" = "OPEN" ] || { echo "중단: 이슈 #$issue 상태가 $state" >&2; exit 3; }

# 3. 같은 이름 브랜치가 이미 있으면 멈춘다
if git show-ref --verify --quiet "refs/heads/$branch"; then
  echo "중단: 브랜치 $branch 가 이미 있다. 이어서 하려면 git switch $branch" >&2; exit 4
fi

# 4. 최신 기본 브랜치에서 브랜치 생성
git switch "$BASE_BRANCH" >/dev/null 2>&1 || { echo "중단: $BASE_BRANCH 전환 실패" >&2; exit 4; }
git pull --ff-only --quiet || { echo "중단: $BASE_BRANCH pull --ff-only 실패(로컬이 갈라졌을 수 있음)" >&2; exit 4; }
git switch -c "$branch" >/dev/null || exit 4

# 5. 결과 출력(짧게): 브랜치 · 이슈 제목 · 본문에 적힌 연결 ID
echo "branch: $branch (base: $BASE_BRANCH @ $(git rev-parse --short HEAD))"
printf '%s' "$info" | jq -r '"issue: #\(.number) \(.title)  labels: \([.labels[].name] | join(",") | if . == "" then "-" else . end)"'
ids=$(printf '%s' "$info" | jq -r .body | grep -Eo "$REF_PATTERN" | sort -u | tr '\n' ' ')
echo "refs: ${ids:--(이슈 본문에 연결 ID 없음)}"
[ -n "$REF_DOCS" ] && echo "ref-docs: $REF_DOCS"
exit 0
