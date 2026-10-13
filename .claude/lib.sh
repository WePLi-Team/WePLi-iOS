# 공통 함수 — 스크립트가 source 한다. 수정 대신 .claude/project.sh를 고친다.
# 사용 전 현재 디렉터리가 저장소 루트여야 한다.

load_project() {
  [ -f .claude/project.sh ] || { echo "중단: .claude/project.sh 없음" >&2; return 1; }
  PROJECT_TAG=proj GH_REPO="" BASE_BRANCH=main COMMIT_LANG=ko
  REF_PATTERN='(REQ-[0-9]{3}|DEC-[0-9]{3})' REF_DOCS="" AREAS="" DESIGN_URL="" SPEC_PATHS=""
  BRANCH_TYPES="feat|fix|docs|chore"
  COMMIT_PATTERN='^(feat|fix|docs|refactor|test|chore|ci|perf|style|build|revert)(\([a-z0-9-]+\))?!?: .+'
  . ./.claude/project.sh
  case "$GH_REPO" in ""|"{{"*) GH_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true);; esac
  case "$DESIGN_URL" in "{{"*) DESIGN_URL="";; esac
  case "$SPEC_PATHS" in "{{"*) SPEC_PATHS="";; esac
  case "$PROJECT_TAG" in ""|"{{"*) PROJECT_TAG=$(basename "$PWD" | tr 'A-Z' 'a-z');; esac
}

# 파일 경로(표준 입력, 줄마다) → 영역 이름(공백 구분, 중복 없음)
areas_of() {
  printf '%s\n' "$AREAS" | awk 'NF==2 { print }' > "${TMPDIR:-/tmp}/areas.$$"
  awk -v rules="${TMPDIR:-/tmp}/areas.$$" '
    BEGIN { while ((getline l < rules) > 0) { split(l, p, /[ \t]+/); n++; re[n]=p[1]; ar[n]=p[2] } }
    NF { hit="other"; for (i=1; i<=n; i++) if ($0 ~ re[i]) { hit=ar[i]; break } a[hit]=1 }
    END { for (k in a) printf "%s ", k }'
  rm -f "${TMPDIR:-/tmp}/areas.$$"
}
