#!/bin/sh
# finish-feature 검증: 바뀐 영역의 빌드 · 테스트를 실행한다. 로컬과 CI가 같은 스크립트를 쓴다.
# 사용: verify.sh <area>...   (check.sh가 출력한 areas 값)
#   claude → 자동화 파일 검사(스크립트 문법 · settings.json · hook 출력) — 기본 제공
#   그 외  → .claude/project.sh 의 verify_<area> 함수. 없으면 SKIP
# 출력: 영역마다 "PASS|FAIL|SKIP <area>", 실패 시 로그 끝 30줄. 전체 로그는 $TMPDIR.
# 종료 코드: 0 = FAIL 없음 · 1 = FAIL 있음.  ⚠ 다음 명령과 `;`로 잇지 말고 `&&`로 잇는다.
set -u
cd "$(git rev-parse --show-toplevel)" || exit 1
. ./.claude/lib.sh && load_project || exit 1
logdir=${TMPDIR:-/tmp}/$PROJECT_TAG-verify; mkdir -p "$logdir"
fail=0

run() { # run <area> <명령...>
  area=$1; shift
  log="$logdir/$area.log"
  if "$@" >"$log" 2>&1; then echo "PASS $area — $*"
  else echo "FAIL $area — $*"; echo "     로그: $log"; tail -30 "$log" | sed 's/^/     /'; fail=1; fi
}

# 자동화 파일 검사: 스크립트 문법 → settings.json 형식 → hook 출력.
verify_claude() {
  for f in .claude/*.sh .claude/hooks/*.sh .claude/skills/*/scripts/*.sh; do
    [ -f "$f" ] || continue; sh -n "$f" || { echo "문법 오류: $f"; return 1; }
  done
  jq empty .claude/settings.json || { echo "settings.json 형식 오류"; return 1; }
  echo '{}' | CLAUDE_PROJECT_DIR=$PWD sh .claude/hooks/session-start.sh | grep -q 'branch=' || { echo "hook 출력 없음"; return 1; }
}
# project.sh를 다시 읽어 프로젝트가 verify_claude를 덮어쓸 수 있게 한다
. ./.claude/project.sh

[ $# -eq 0 ] && { echo "사용: verify.sh <area>..."; exit 1; }
for a in "$@"; do
  if command -v "verify_$a" >/dev/null 2>&1; then run "$a" "verify_$a"
  else
    case "$a" in
      none|docs|other) echo "SKIP $a — 자동 검증 없음" ;;
      *) echo "SKIP $a — verify_$a 없음(.claude/project.sh에 추가)" ;;
    esac
  fi
done
exit $fail
