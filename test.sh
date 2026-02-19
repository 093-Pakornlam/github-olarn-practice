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
REQ_BRANCH_01="task/01-collaborators"
REQ_BRANCH_02="task/02-feature-index"
REQ_BRANCH_03="task/03-conflict-create"
REQ_BRANCH_03B="task/03b-conflict-create-alt"
REQ_BRANCH_04="task/04-conflict-resolve"
REQ_BRANCH_05="task/05-recovery"
REQ_BRANCH_06="task/06-history"
REQ_BRANCH_07="task/07-evidence-reflog"

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
  sep
  echo "Test 1: Branch workflow (exist + merged into main) (40 pts)"

  P=0

  for B in "$REQ_BRANCH_01" "$REQ_BRANCH_02" "$REQ_BRANCH_03" "$REQ_BRANCH_03B" "$REQ_BRANCH_04" "$REQ_BRANCH_05" "$REQ_BRANCH_06" "$REQ_BRANCH_07"
  do
    if branch_exists "$B"; then
      pass "Branch exists: $B"
      P=$((P + 2))
      if branch_merged_into_main "$B"; then
        pass "Merged into main: $B"
        P=$((P + 3))
      else
        fail "Not merged into main: $B (open PR and merge into main)"
      fi
    else
      fail "Missing branch: $B"
    fi
  done

  # Total possible: 8 branches * (2+3) = 40
  add "$P"
  echo "Score: $P/40"
}

# ------------------------------------------------
# Test 2: Commit keywords in correct branches (25)
# ------------------------------------------------
test2_keywords(){
  sep
  echo "Test 2: Commit keywords per task branch (25 pts)"

  P=0

  # Feature keyword must exist in task/02
  if branch_has_keyword "$REQ_BRANCH_02" "$KW_FEATURE" >/dev/null 2>&1; then
    pass "Found keyword on $REQ_BRANCH_02: $KW_FEATURE"
    P=$((P + 6))
  else
    fail "Missing keyword on $REQ_BRANCH_02: $KW_FEATURE"
  fi

  # Conflict keyword must exist in BOTH conflict branches (creation)
  if branch_has_keyword "$REQ_BRANCH_03" "$KW_CONFLICT" >/dev/null 2>&1; then
    pass "Found keyword on $REQ_BRANCH_03: $KW_CONFLICT"
    P=$((P + 4))
  else
    fail "Missing keyword on $REQ_BRANCH_03: $KW_CONFLICT"
  fi

  if branch_has_keyword "$REQ_BRANCH_03B" "$KW_CONFLICT" >/dev/null 2>&1; then
    pass "Found keyword on $REQ_BRANCH_03B: $KW_CONFLICT"
    P=$((P + 4))
  else
    fail "Missing keyword on $REQ_BRANCH_03B: $KW_CONFLICT"
  fi

  # Merge keyword must exist in task/04
  if branch_has_keyword "$REQ_BRANCH_04" "$KW_MERGE" >/dev/null 2>&1; then
    pass "Found keyword on $REQ_BRANCH_04: $KW_MERGE"
    P=$((P + 5))
  else
    fail "Missing keyword on $REQ_BRANCH_04: $KW_MERGE"
  fi

  # Recovery keyword must exist in task/05
  if branch_has_keyword "$REQ_BRANCH_05" "$KW_RECOVERY" >/dev/null 2>&1; then
    pass "Found keyword on $REQ_BRANCH_05: $KW_RECOVERY"
    P=$((P + 3))
  else
    fail "Missing keyword on $REQ_BRANCH_05: $KW_RECOVERY"
  fi

  # History keyword must exist in task/06
  if branch_has_keyword "$REQ_BRANCH_06" "$KW_HISTORY" >/dev/null 2>&1; then
    pass "Found keyword on $REQ_BRANCH_06: $KW_HISTORY"
    P=$((P + 2))
  else
    fail "Missing keyword on $REQ_BRANCH_06: $KW_HISTORY"
  fi

  # Evidence keyword must exist in task/07
  if branch_has_keyword "$REQ_BRANCH_07" "$KW_EVIDENCE" >/dev/null 2>&1; then
    pass "Found keyword on $REQ_BRANCH_07: $KW_EVIDENCE"
    P=$((P + 1))
  else
    fail "Missing keyword on $REQ_BRANCH_07: $KW_EVIDENCE"
  fi

  add "$P"
  echo "Score: $P/25"
}

# -----------------------------------------
# Test 3: index.html structure + markers (15)
# -----------------------------------------
test3_index(){
  sep
  echo "Test 3: index.html structure + markers (15 pts)"

  P=0

  if [ ! -f "index.html" ]; then
    fail "index.html missing; cannot check"
    add 0
    return
  fi

  if file_contains "index.html" "$INDEX_SEC_1"; then pass "Found: $INDEX_SEC_1"; P=$((P+4)); else fail "Missing: $INDEX_SEC_1"; fi
  if file_contains "index.html" "$INDEX_SEC_2"; then pass "Found: $INDEX_SEC_2"; P=$((P+4)); else fail "Missing: $INDEX_SEC_2"; fi
  if file_contains "index.html" "$INDEX_SEC_3"; then pass "Found: $INDEX_SEC_3"; P=$((P+4)); else fail "Missing: $INDEX_SEC_3"; fi

  # markers required so automation can safely update only that section
  if file_contains "index.html" "$MARKER_START" && file_contains "index.html" "$MARKER_END"; then
    pass "AUTO-UPDATE markers found"
    P=$((P+3))
  else
    fail "Missing AUTO-UPDATE markers in index.html"
    echo "   Required markers:"
    echo "   $MARKER_START"
    echo "   $MARKER_END"
  fi

  add "$P"
  echo "Score: $P/15"
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
