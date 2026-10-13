#!/bin/sh
# finish-feature 사전 검사(읽기 전용): 브랜치 이름 · 미커밋 변경 · 커밋 메시지 · 비밀값 · 바뀐 영역.
# 사용: check.sh [base]   (기본 base = origin/<BASE_BRANCH>)
# 출력: 줄마다 OK|WARN|FAIL, 마지막 줄 "areas: …"
# 종료 코드: 0 = FAIL 없음 · 1 = FAIL 있음
set -u
cd "$(git rev-parse --show-toplevel)" || exit 1
. ./.claude/lib.sh && load_project || exit 1
base=${1:-origin/$BASE_BRANCH}
git fetch -q origin "$BASE_BRANCH" 2>/dev/null || echo "WARN origin fetch 실패 — 로컬 $base 기준으로 검사"
fail=0
ok()   { echo "OK   $*"; }
warn() { echo "WARN $*"; }
bad()  { echo "FAIL $*"; fail=1; }

# 1. 브랜치
br=$(git rev-parse --abbrev-ref HEAD)
if [ "$br" = "$BASE_BRANCH" ]; then warn "$BASE_BRANCH 브랜치 — 직접 push 예외(git.md)일 때만. PR 흐름이면 작업 브랜치에서 실행"
elif echo "$br" | grep -Eq "^($BRANCH_TYPES)/[0-9]+-[a-z0-9]+(-[a-z0-9]+)*\$"; then ok "브랜치 $br"
else bad "브랜치 이름 형식 아님: $br ($BRANCH_TYPES/<issue>-<slug>)"; fi
issue=$(echo "$br" | sed -nE 's#^[a-z]+/([0-9]+)-.*#\1#p')

# 2. 미커밋 변경 — push되는 것은 커밋뿐이라 막지 않는다. 이 작업의 파일이 빠졌는지만 알린다.
n=$(git status --porcelain | wc -l | tr -d ' ')
[ "$n" -eq 0 ] && ok "작업 트리 깨끗함" || warn "커밋하지 않은 변경 ${n}개 — push에 안 들어감. 이 작업 파일이 빠지지 않았는지 확인"

# 3. 커밋 메시지 (base..HEAD)
commits=$(git rev-list --no-merges "$base..HEAD" 2>/dev/null | wc -l | tr -d ' ')
if [ "$commits" -eq 0 ]; then bad "$base 이후 커밋 없음"
else
  msgs=$(git log --no-merges --format='%h%x09%s' "$base..HEAD" | while IFS="$(printf '\t')" read -r h s; do
    if ! echo "$s" | grep -Eq "$COMMIT_PATTERN"; then echo "FAIL 커밋 $h 형식 아님: $s"
    elif [ "$COMMIT_LANG" = ko ] && ! printf '%s' "$s" | perl -CS -ne 'exit(/\p{Hangul}/ ? 0 : 1)'; then echo "FAIL 커밋 $h 요약이 한국어 아님: $s"
    elif [ "$(printf '%s' "$s" | perl -CS -ne 'print length')" -gt 72 ]; then echo "FAIL 커밋 $h 요약 72자 초과"
    elif echo "$s" | grep -q '\.$'; then echo "FAIL 커밋 $h 요약 끝 마침표"
    fi
  done)
  if [ -n "$msgs" ]; then echo "$msgs"; fail=1; else ok "커밋 ${commits}개 형식 통과"; fi
  if [ -n "$issue" ] && ! git log --format=%B "$base..HEAD" | grep -Eq "(Refs|Close|Closes|Fixes) #$issue\b"; then
    warn "커밋 꼬리말에 Refs/Closes #$issue 없음(PR 본문에 넣어도 됨)"
  fi
fi

# 4. 비밀값 — 추가된 줄만 검사. 값은 출력하지 않고 파일:패턴만 알린다.
hits=$(git diff "$base...HEAD" --unified=0 --no-color | perl -ne '
  if (/^\+\+\+ b\/(.*)/) { $f=$1; next }
  next unless /^\+/;
  for my $p ("gh[pousr]_[A-Za-z0-9]{20,}", "sk-[A-Za-z0-9_-]{20,}", "AKIA[0-9A-Z]{16}", "AIza[0-9A-Za-z_-]{30,}",
             "xox[baprs]-[A-Za-z0-9-]{10,}", "-----BEGIN [A-Z ]*PRIVATE KEY", "eyJ[A-Za-z0-9_-]{10,}\\.eyJ",
             "(?i)(password|passwd|secret|api_?key|service_role)[\"'\'' ]*[:=][\"'\'' ]*[^\"'\'' ]{8,}") {
    if (/$p/) { print "$f: $p\n"; last }
  }' | sort -u)
[ -z "$hits" ] && ok "비밀값 패턴 없음" || { bad "비밀값 의심(값은 숨김):"; echo "$hits" | sed 's/^/     /'; }
envs=$(git diff --name-only "$base...HEAD" | grep -E '(^|/)\.env($|\.)' | grep -v '\.env\.example$')
[ -n "$envs" ] && { echo "$envs" | sed 's/^/FAIL .env 파일 포함: /'; fail=1; }

# 5. 바뀐 영역 → verify.sh 인자 (규칙은 .claude/project.sh AREAS)
areas=$(git diff --name-only "$base...HEAD" | areas_of)
echo "areas: ${areas:-none}"
exit $fail
