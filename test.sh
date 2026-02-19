#!/bin/sh
# ============================================================
# INT142 - Contributor Submission Checker (Branch-based)
# Total: 100 points
#
# What this checks:
# - Branch workflow: task/* branches exist + merged into main
# - Commit keywords exist in correct branches
# - index.html has required sections + AUTO-UPDATE markers
# - COLLABORATORS.md format
# - Reflog evidence committed (optional but recommended)
# - Commit author identity: strict name + GitHub private email
#
# Note:
# - Does NOT check required files list (by request)
# - Ignores GitHub Actions bot commits
# ============================================================
# ---------------- CONFIG ----------------
EXPECTED_NAME="FIRSTNAME LASTNAME (Github-Practice)"
EXPECTED_EMAIL="YOUR_PRIVATE_GITHUB_EMAIL@users.noreply.github.com"

# If 1, require reflog evidence folder checks
REQUIRE_REFLOG=1

# Required task branches (as per README)
REQ_BRANCHES="task/01-collaborators task/02-feature-index task/03-conflict-create task/03b-conflict-create-alt task/04-conflict-resolve task/05-recovery task/06-history task/07-evidence-reflog"

# Commit keywords (must exist in correct task branch history)
KW_FEATURE="Feature: Update index.html content"
KW_CONFLICT="Conflict: Modify same line in index.html"
KW_MERGE="Merge: Resolve conflict on index.html"
KW_RECOVERY="Recovery: Restore previous state"
KW_HISTORY="History: Reorganize commits"
KW_EVIDENCE="Evidence: Add reflog records"

# index.html content requirements
INDEX_SEC_1="Feature Section"
INDEX_SEC_2="Conflict Simulation"
INDEX_SEC_3="Automated Update Section"
MARKER_START="<!-- AUTO-UPDATE-START -->"
MARKER_END="<!-- AUTO-UPDATE-END -->"

# collaborators requirements
COLLAB_H1="# Collaborators"
COLLAB_OWNER="## Owner"
COLLAB_COLLAB="## Collaborator"
# ---------------------------------------

TOTAL=0
FAILED=0

sep(){ printf "\n---------------------------------------------------\n"; }
pass(){ echo "✅ $1"; }
fail(){ echo "❌ $1"; FAILED=1; }

add(){ TOTAL=$((TOTAL + $1)); }

require_repo_root(){
  if [ ! -d ".git" ]; then
    fail "Not a git repository (missing .git). Run this script at repo root."
    exit 1
  fi
}

is_bot_commit(){
  # $1 = commit hash
  AN=$(git show -s --format='%an' "$1" 2>/dev/null)
  AE=$(git show -s --format='%ae' "$1" 2>/dev/null)
  echo "$AN|$AE" | grep -Eq "github-actions\\[bot\\]|github-classroom\\[bot\\]" && return 0
  return 1
}

branch_exists(){
  # $1 = branch name
  git show-ref --verify --quiet "refs/heads/$1"
}

branch_merged_into_main(){
  # $1 = branch name
  # true if all commits on branch are reachable from main
  git merge-base --is-ancestor "$1" main 2>/dev/null
}

branch_has_keyword(){
  # $1 = branch, $2 = keyword
  # search commit subject in that branch, excluding bots (heuristic: ignore commits authored by bots)
  # Approach: iterate commits and check subject + author not bot
  git rev-list "$1" 2>/dev/null | while read -r H
  do
    if is_bot_commit "$H"; then
      continue
    fi
    SUBJECT=$(git show -s --format='%s' "$H" 2>/dev/null)
    if [ "$SUBJECT" = "$2" ]; then
      echo "$H"
      exit 0
    fi
  done
  exit 1
}

file_contains(){
  # $1 file, $2 fixed string
  grep -Fq "$2" "$1" 2>/dev/null
}

# -------------------------
# Test 0: Config sanity (0)
# -------------------------
test0_config(){
  sep
  echo "Test 0: Config sanity (0 pts)"

  echo "$EXPECTED_NAME" | grep -Eq "^[^()]+ [^()]+ \\(Github-Practice\\)$"
  if [ $? -ne 0 ]; then
    fail "EXPECTED_NAME invalid. Must be: Firstname Lastname (Github-Practice)"
  else
    pass "EXPECTED_NAME format ok"
  fi

  echo "$EXPECTED_EMAIL" | grep -Eq "^[0-9]+\\+.+@users\\.noreply\\.github\\.com$|^.+@users\\.noreply\\.github\\.com$"
  if [ $? -ne 0 ]; then
    fail "EXPECTED_EMAIL format looks wrong (should be GitHub private noreply email)"
  else
    pass "EXPECTED_EMAIL format ok"
  fi
}

# ---------------------------------------------
# Test 1: Branches exist + merged into main (40)
# ---------------------------------------------
test1_branches(){
  printf "\nTest 1: Branch & Merge Workflow (40 pts)\n"
  P=0
  # ดึงรายชื่อ branch ที่ถูก merge เข้า main แล้วจริงๆ
  MERGED_BRANCHES=$(git branch -a --merged main | sed 's/.* //')

  for B in $REQ_BRANCHES; do
    # 1. เช็คว่ามี Branch ในเครื่องไหม
    if git show-ref --verify --quiet "refs/heads/$B" || git show-ref --verify --quiet "refs/remotes/origin/$B"; then
      P=$((P + 2))
      # 2. เช็คว่าถูก Merge เข้า main หรือยัง
      if echo "$MERGED_BRANCHES" | grep -q "$B"; then
        pass "$B: Merged into main"
        P=$((P + 3))
      else
        fail "$B: Exists but NOT merged into main (Check your PR)"
      fi
    else
      fail "$B: Branch missing"
    fi
  done
  add "$P"; echo "Score: $P/40"
}

# ------------------------------------------------
# Test 2: Commit keywords in correct branches (25)
# ------------------------------------------------
test2_keywords(){
  printf "\nTest 2: Commit Keywords in Main History (25 pts)\n"
  P=0
  check_kw(){
    if git log main --format='%s' | grep -Fxq "$1"; then
      pass "Found Keyword: $1"; return 0
    else
      fail "Missing Keyword in main: $1"; return 1
    fi
  }

  check_kw "$KW_FEATURE" && P=$((P+6))
  # Conflict keyword must appear at least twice (from 03 and 03b)
  CONF_COUNT=$(git log main --format='%s' | grep -Fx "$KW_CONFLICT" | wc -l)
  if [ "$CONF_COUNT" -ge 2 ]; then pass "Conflict Keywords OK ($CONF_COUNT/2)"; P=$((P+8)); else fail "Need 2 Conflict commits in main (found $CONF_COUNT)"; fi
  
  check_kw "$KW_MERGE" && P=$((P+5))
  check_kw "$KW_RECOVERY" && P=$((P+3))
  check_kw "$KW_HISTORY" && P=$((P+2))
  check_kw "$KW_EVIDENCE" && P=$((P+1))

  add "$P"; echo "Score: $P/25"
}

# -----------------------------------------
# Test 3: index.html structure + markers (15)
# -----------------------------------------
test_index(){
  printf "\nTest 3: index.html Structure (15 pts)\n"
  P=0
  grep -Fq "Feature Section" index.html && P=$((P+4)) || fail "Missing Feature Section"
  grep -Fq "Conflict Simulation" index.html && P=$((P+4)) || fail "Missing Conflict Simulation"
  grep -Fq "Automated Update Section" index.html && P=$((P+4)) || fail "Missing Auto-Update Section"
  if grep -Fq "" index.html && grep -Fq "" index.html; then
    pass "Markers OK"; P=$((P+3))
  else fail "Markers Missing"; fi
  add "$P"; echo "Score: $P/15"
}

# -----------------------------------------
# Test 4: COLLABORATORS.md format (10)
# -----------------------------------------
test4_collaborators(){
  sep
  echo "Test 4: COLLABORATORS.md format (10 pts)"

  P=0

  if [ ! -f "COLLABORATORS.md" ]; then
    fail "COLLABORATORS.md missing; cannot check"
    add 0
    return
  fi

  if file_contains "COLLABORATORS.md" "$COLLAB_H1"; then pass "Found header: $COLLAB_H1"; P=$((P+3)); else fail "Missing header: $COLLAB_H1"; fi
  if file_contains "COLLABORATORS.md" "$COLLAB_OWNER"; then pass "Found section: $COLLAB_OWNER"; P=$((P+3)); else fail "Missing section: $COLLAB_OWNER"; fi
  if file_contains "COLLABORATORS.md" "$COLLAB_COLLAB"; then pass "Found section: $COLLAB_COLLAB"; P=$((P+2)); else fail "Missing section: $COLLAB_COLLAB"; fi

  # Owner line should not remain placeholder (basic heuristic)
  if grep -Eq "Full Name:[[:space:]]*YOUR REAL NAME|Full Name:[[:space:]]*YOUR_NAME_HERE" COLLABORATORS.md 2>/dev/null; then
    fail "Owner name still looks like a placeholder. Replace with your real full name."
  else
    pass "Owner name does not look like placeholder"
    P=$((P+2))
  fi

  add "$P"
  echo "Score: $P/10"
}

# -----------------------------------------
# Test 5: Reflog evidence (10)
# -----------------------------------------
test5_reflog(){
  sep
  echo "Test 5: Reflog evidence (10 pts)"

  if [ "$REQUIRE_REFLOG" -ne 1 ]; then
    pass "Reflog evidence not required"
    add 10
    echo "Score: 10/10"
    return
  fi

  P=0

  if [ -d "reflog" ]; then
    pass "reflog/ directory exists"
    P=$((P+2))
  else
    fail "reflog/ directory missing"
    add 0
    return
  fi

  if [ -f "reflog/reflog_HEAD.txt" ]; then pass "reflog_HEAD.txt exists"; P=$((P+4)); else fail "Missing reflog/reflog_HEAD.txt"; fi
  if [ -f "reflog/README.md" ]; then pass "reflog/README.md exists"; P=$((P+2)); else fail "Missing reflog/README.md"; fi

  # at least one branch reflog
  BRCOUNT=$(ls reflog 2>/dev/null | grep -E "^reflog_.*\.txt$" | grep -v "reflog_HEAD\.txt" | wc -l | tr -d ' ')
  if [ "$BRCOUNT" -ge 1 ]; then
    pass "Branch reflog files found: $BRCOUNT"
    P=$((P+2))
  else
    fail "No branch reflog files found (expected at least 1)"
  fi

  add "$P"
  echo "Score: $P/10"
}

# -----------------------------------------
# Test 6: Commit author identity (strict) (0 pts but fail-hard)
# -----------------------------------------
test6_identity(){
  sep
  echo "Test 6: Commit author identity (fail-hard)"

  # Check all non-bot commits reachable from main
  # (If branches are merged, their commits are in main history.)
  BAD=0

  git rev-list main 2>/dev/null | while read -r H
  do
    if is_bot_commit "$H"; then
      continue
    fi

    AN=$(git show -s --format='%an' "$H" 2>/dev/null)
    AE=$(git show -s --format='%ae' "$H" 2>/dev/null)

    if [ "$AN" != "$EXPECTED_NAME" ] || [ "$AE" != "$EXPECTED_EMAIL" ]; then
      echo "❌ Wrong author on commit $H"
      echo "   Name : $AN"
      echo "   Email: $AE"
      BAD=1
      break
    fi
  done

  # subshell issue workaround: re-check using grep on formatted list
  git log main --format='%an|%ae' 2>/dev/null \
    | grep -v "github-actions\\[bot\\]" \
    | grep -v "github-classroom\\[bot\\]" \
    | grep -Fv "$EXPECTED_NAME|$EXPECTED_EMAIL" >/dev/null 2>&1

  if [ $? -eq 0 ]; then
    fail "Commit identity check failed. All non-bot commits must use EXPECTED_NAME + EXPECTED_EMAIL."
  else
    pass "All non-bot commits match EXPECTED_NAME + EXPECTED_EMAIL"
  fi
}

# ---------------- MAIN ----------------
require_repo_root

echo "INT142 Submission Checker (Contributor-side)"
echo "Branch-based workflow + PR-to-main requirement enforced by merge checks."

test0_config
test1_branches
test2_keywords
test3_index
test4_collaborators
test5_reflog
test6_identity

sep
echo "Final Score: $TOTAL/100"

if [ "$FAILED" -eq 1 ]; then
  echo "RESULT: ❌ FAIL"
  exit 1
else
  echo "RESULT: ✅ PASS"
  exit 0
fi
