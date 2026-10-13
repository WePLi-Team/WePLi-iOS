#!/bin/sh
# SessionStart hook — 세션 시작 시 git 상태를 두세 줄로 알린다. 읽기 전용 · 네트워크 없음.
# 어떤 경우에도 exit 0 (세션 시작을 막지 않는다). 끄는 법: docs/conventions/automation.md
cat >/dev/null 2>&1 || :   # hook 입력(JSON)은 쓰지 않음
cd "${CLAUDE_PROJECT_DIR:-.}" 2>/dev/null || exit 0
git rev-parse --git-dir >/dev/null 2>&1 || exit 0
tag=$(sed -nE 's/^PROJECT_TAG="([a-z0-9-]+)".*/\1/p' .claude/project.sh 2>/dev/null)
tag=${tag:-$(basename "$PWD" | tr 'A-Z' 'a-z')}
base=$(sed -nE 's/^BASE_BRANCH="([^"]+)".*/\1/p' .claude/project.sh 2>/dev/null)
base=${base:-main}

br=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
st=$(git status --porcelain 2>/dev/null)
staged=$(printf '%s\n' "$st" | grep -c '^[AMDRC]')
unstaged=$(printf '%s\n' "$st" | grep -c '^.[MD]')
untracked=$(printf '%s\n' "$st" | grep -c '^??')

echo "[$tag] branch=$br staged=$staged unstaged=$unstaged untracked=$untracked"
if [ "$br" = "$base" ] && [ -n "$st" ]; then
  echo "[$tag] $base에 커밋하지 않은 변경이 있다. 사용자 작업일 수 있으니 되돌리거나 stash하지 말 것. 새 작업은 /start-feature."
fi
issue=$(echo "$br" | sed -nE 's#^[a-z]+/([0-9]+)-.*#\1#p')
[ -n "$issue" ] && echo "[$tag] 이슈 #$issue 작업 중. 마무리는 /finish-feature."
grep -q 'TODO(setup)' AGENTS.md 2>/dev/null && echo "[$tag] 프로젝트 설정이 덜 채워졌다(AGENTS.md TODO). /project-setup 으로 채운다."
exit 0
