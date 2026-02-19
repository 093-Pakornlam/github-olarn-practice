# INT142 Software Development Tools  
## Individual Practice – Source Control, Collaboration, and Automation Simulation

---

## Overview

This repository demonstrates a complete simulation of distributed software development  
performed by an individual developer.

Collaborative scenarios are reproduced through structured development workflows,  
task tracking, conflict handling, history recovery, and automated remote updates.

Automated processes behave as a simulated remote contributor, modifying repository  
content after updates are submitted. This ensures that local and remote states may  
diverge and must be synchronized and reconciled.

All activities reflect realistic repository management conditions in a collaborative  
environment.

---

## Repository Structure

- **index.html**  
  Main working file used for feature development, integration testing, conflict simulation,  
  and automated remote overwriting.

- **index-template.html**  
  Reference file used for file state management and restoration practice.

- **COLLABORATORS.md**  
  Records ownership and simulated collaborator information.

- **reflog/**  
  Contains repository activity records showing history movements, recovery events,  
  and integration changes.

- **.github/workflows/classroom.yml**  
  Defines automated repository behavior.

---

## General Branch Rules

* **Separate Branch for Every Task**: All work must be performed in specific branches.
* **Mandatory Pull Requests**: Complete the work in the branch first, then merge into `main` via a Pull Request.
* **No Direct Work on `main**`: All commits must happen within task branches.
* **Identity Configuration**: Set your Git identity to match these values before committing:
* **Name**: `FIRSTNAME LASTNAME (Github-Practice)`
* **Email**: `YOUR_PRIVATE_GITHUB_EMAIL@users.noreply.github.com`



---

# Task Workflow

### Part 1 – Repository Setup and Ownership

**Branch:** `task/01-collaborators` (Base: `main`)

1. Create branch `task/01-collaborators` from `main`.
2. Edit `COLLABORATORS.md`:
* Update the **Owner** section with your real name.


3. Commit message: `Feature: Setup collaborators`.
  push files to remote repo and run workflow
 
4. Create a Pull Request and merge into `main`.

### Part 2 – Feature Development

**Branch:** `task/02-feature-index` (Base: `main`)

1. Create branch `task/02-feature-index` from `main`.
2. **Modify `index.html**`: Add the following sections into the `<body>`:
* **Line 11**: Add `<h2>Feature Section</h2>`.
* **Line 12**: Add `<h2>Conflict Simulation</h2>`.
* **Line 13**: Add `<h2>Automated Update Section</h2>`.




3. Commit message: `Feature: Update index.html content`.
  push files to remote repo and run workflow
4. Create a Pull Request and merge into `main`.

### Part 3 – Conflict Simulation (Creation)

**Branches:** `task/03-conflict-create` and `task/03b-conflict-create-alt` (Base: `main`)

1. **Branch A**: Create `task/03-conflict-create`.
* **Modify Line 13**: Change the text under "Conflict Simulation".
* Commit message: `Conflict: Modify same line in index.html`.


2. **Branch B**: Create `task/03b-conflict-create-alt` from `main`.
* **Modify Line 13**: Change the text to something **different** than Branch A.
* Commit message: `Conflict: Modify same line in index.html`.


3. **Do not merge yet.**

### Part 4 – Conflict Resolution

**Branch:** `task/04-conflict-resolve` (Base: `task/03-conflict-create`)

1. Create branch `task/04-conflict-resolve` from `task/03-conflict-create`.
2. Merge `task/03b-conflict-create-alt` into this branch to trigger the conflict on **Line 13**.
3. Manually resolve the markers in `index.html`.
4. Commit message: `Merge: Resolve conflict on index.html`.
5. Create a Pull Request and merge into `main`.

### Part 5 – Change Recovery

**Branch:** `task/05-recovery` (Base: `main`)

1. Create branch `task/05-recovery` from `main`.
2. Delete content or corrupt `index.html`.
3. Restore the file to its previous state.
4. Commit message: `Recovery: Restore previous state`.
5. Create a Pull Request and merge into `main`.

### Part 6 – History Restructuring

**Branch:** `task/06-history` (Base: `main`)

1. Create branch `task/06-history` from `main`.
2. Reorganize your commit history for clarity.
3. Commit message: `History: Reorganize commits`.
4. Create a Pull Request and merge into `main`.

### Part 7 – Evidence Collection

**Branch:** `task/07-evidence-reflog` (Base: `main`)

1. Create branch `task/07-evidence-reflog` from `main`.
2. Create folder `reflog/` and add `reflog_HEAD.txt`.
3. Commit message: `Evidence: Add reflog records`.
4. Create a Pull Request and merge into `main`.

---

## Validation

Run the script to check your progress: `sh test.sh`

**Pass Criteria:**

* Final Score: **100/100**.
* All task branches must be merged into `main`.
* Commit identity must be exactly as specified in the rules.

---

## Submission Requirements

Your repository must include:

- All required task branches
- Correct commit message structure
- Valid commit identity
- Conflict resolution history
- Recovery operations
- Restructured history
- Activity log evidence

---

## Summary

This repository represents a full simulation of collaborative software development  
in a distributed environment performed individually.

The practice demonstrates:

- structured development workflow  
- controlled integration  
- conflict detection and resolution  
- repository recovery  
- history restructuring  
- remote synchronization  
- automated modification  
- activity verification  

All repository behavior reflects realistic multi-contributor development conditions.


