# Repository setup

One-time GitHub settings and the conventions every template repo keeps. The settings are not files, so
they cannot be reviewed in a pull request: do them before merging the first release PR. The conventions are
files, and the checks at the end prove them.

Each step is tagged:

- **[AGENT]**: a `gh` command that can run unattended. Nothing to replace: the commands already name `hasansezertasan/copier-infra`.
- **[HUMAN]**: browser-only work.
- **[CHECK]**: a scriptable verification, or an explicit "no scriptable check".

## Releases

Releases are automatic from Conventional Commits; nobody tags by hand.

1. Merge PRs to `main` with Conventional Commit titles (`feat:`, `fix:`, ...).
2. release-please keeps one release PR open and writes `CHANGELOG.md`.
3. Merging that PR tags the commit (`v0.1.0`, ...) and cuts a GitHub release.

The tags matter: they are what `copier update` walks in every project generated from this template, so a
hand-made or deleted tag breaks their updates.

## Squash-only merges

The PR title becomes the commit and the changelog line, so merge by squash only and make the squash commit take the
PR title: with the default, a one-commit PR lands its commit title instead, which may not be a Conventional Commit.

**[AGENT]**

```sh
gh api -X PATCH repos/hasansezertasan/copier-infra \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true -f squash_merge_commit_title=PR_TITLE
```

**[CHECK]**

```sh
gh api repos/hasansezertasan/copier-infra \
  --jq '.allow_squash_merge and (.allow_merge_commit | not) and (.allow_rebase_merge | not) and .squash_merge_commit_title == "PR_TITLE"' | grep -qx true
```

## Let Actions open the release PR

release-please runs as a GitHub Action and opens the release pull request.

**[AGENT]**

```sh
gh api -X PUT repos/hasansezertasan/copier-infra/actions/permissions/workflow \
  -F default_workflow_permissions=read \
  -F can_approve_pull_request_reviews=true
```

**[CHECK]**

```sh
gh api repos/hasansezertasan/copier-infra/actions/permissions/workflow \
  --jq '.can_approve_pull_request_reviews == true and .default_workflow_permissions == "read"' | grep -qx true
```

## Renovate

**[HUMAN]** Install the Renovate GitHub app on the repository. `.github/renovate.json` extends the shared preset.

**[CHECK]** No scriptable check: Renovate opens its onboarding or dependency dashboard issue after installation.

## Template conventions

A template repo is only useful if projects can keep updating from it, so these hold for every one. Each has a
check in the next section.

1. **The payload's README links back.** Once `template/` has a README, it ends with a `## Credits`
   section holding `Generated from [copier-infra](https://github.com/hasansezertasan/copier-infra).`, so a generated project says where
   it came from. The heading keeps the line from reading as part of the section above it.
2. **`_src_path` is a full git URL.** Usage commands say `copier copy https://github.com/hasansezertasan/copier-infra.git ...`, never the
   `gh:` shortcut: Renovate's copier manager looks `_src_path` up as a git remote and fails on the shortcut,
   so no update PR is opened. The same goes for the `_src_path` recorded in this repo's own `.copier-answers.yml`
   (the template it was generated from): if you generated from a local clone, edit it to the published URL.
3. **No `_tasks` in `copier.yml`.** A task makes the template unsafe and forces `--trust`, which Renovate's
   copier manager does not pass. Print next steps with `_message_after_copy` instead.
4. **The payload ships its answers file.** `template/.copier-answers.yml.jinja` (or, under custom
   delimiters, `template/[[ _copier_conf.answers_file ]].jinja`) is what lets generated projects run
   `copier update`.
5. **Files a project owns are listed in `_skip_if_exists`.** Anything the template must keep refreshing,
   such as workflows, stays out of it.
6. **Payloads full of `${{ ... }}` or bash `[[ ]]` use their own Jinja delimiters** (`_envops`), and only
   files with the `.jinja` suffix are rendered.

## Checking the conventions

Run from the repository root.

**[CHECK]**

```sh
(
  set -e
  fail() { echo "$1"; exit 1; }
  # 1. The payload README, if there is one, ends with the Credits section and the back reference.
  for readme in template/README.md template/README.md.jinja; do
    [ -f "$readme" ] || continue
    [ "$(tail -n 3 "$readme" | head -n 1)" = '## Credits' ] || fail "$readme: no ## Credits heading before the last line"
    tail -n 1 "$readme" | grep -qF 'Generated from [copier-infra](https://github.com/hasansezertasan/copier-infra).' || fail "$readme: last line is not the back reference"
  done
  # 2. Usage commands and the recorded _src_path (where this repo was generated from) use a full git URL.
  grep -qF 'copier copy https://github.com/hasansezertasan/copier-infra.git' README.md || fail "README.md: usage must say copier copy https://github.com/hasansezertasan/copier-infra.git"
  if grep -q 'gh:' README.md; then fail "README.md: uses the gh: shortcut"; fi
  [ -f .copier-answers.yml ] || fail ".copier-answers.yml is missing: copier update needs it to know which release generated this repo"
  grep -Eq "^['\"]?_src_path['\"]?:[[:space:]]*['\"]?https://[^/[:space:]]+/[^[:space:]]+" .copier-answers.yml \
    || fail ".copier-answers.yml: _src_path must be a full https git URL, not gh: or a local path"
  # 3. No tasks, quoted or not.
  if grep -Eq "^[[:space:]]*['\"]?_tasks['\"]?[[:space:]]*:" copier.yml; then fail "copier.yml: has _tasks"; fi
  # 4. The answers-file template is in the payload, under exactly this name. A payload that is itself
  #    a template repo (it has its own template/copier.yml, as in copier-copier) holds it one level down,
  #    with a doubled suffix.
  if [ -f template/copier.yml ]; then
    answers=template/template/.copier-answers.yml.jinja.jinja
    delimited='template/template/[[ _copier_conf.answers_file ]].jinja.jinja'
    config=template/copier.yml
  else
    answers=template/.copier-answers.yml.jinja
    delimited='template/[[ _copier_conf.answers_file ]].jinja'
    config=copier.yml
  fi
  #    A payload with its own Jinja delimiters (convention 6) spells the same file with them, but only
  #    when that copier.yml really configures `[[` and `]]` as the variable delimiters.
  if grep -Eq "^[[:space:]]*['\"]?variable_start_string['\"]?[[:space:]]*:[[:space:]]*(\"\[\[\"|'\[\[')[[:space:]]*(#.*)?$" "$config" \
    && grep -Eq "^[[:space:]]*['\"]?variable_end_string['\"]?[[:space:]]*:[[:space:]]*(\"\]\]\"|'\]\]')[[:space:]]*(#.*)?$" "$config" \
    && [ -f "$delimited" ]; then answers=$delimited; fi
  [ -f "$answers" ] || fail "$answers is missing"
)
```

These are text checks, on purpose. They do not parse YAML, so an exotic spelling of a key can slip through, and
they only require an `https://` `_src_path` with a host and a path; they cannot tell whether it names the right repository. The
custom-delimiter fallback for convention 4 likewise matches the two `_envops` lines as text: it does not check that they sit
under the top-level `_envops` mapping. A stricter check would need a YAML parser in this block, which the guide deliberately
does not assume.

Conventions 5 and 6 have no scriptable check. `mise run test` renders the template and walks a
`copier update`, which catches a payload that does not render, but not a project-owned file that is missing
from `_skip_if_exists`: the update test tags an empty commit, so both versions render the same bytes. Review
`_skip_if_exists` by hand whenever you add a payload file the project will edit.

## Known limitations

- When release-please opens a release PR or updates its branch with `GITHUB_TOKEN`, the `pull_request` workflows
  start in an approval-required state (`action_required`) and run once a user with write access approves them.
  The `pull_request_target` checks (`Validate PR title`, `Validate branch name`) do not run when release-please
  creates or updates the PR with `GITHUB_TOKEN`. Reopening it by hand starts both, and editing its title starts the
  title check, because those events come from you and not from the token. No ruleset here requires them, so the release PR merges after
  approval; if you add a ruleset that requires them, trigger them that way or give repository admins a bypass
  through a pull request.
