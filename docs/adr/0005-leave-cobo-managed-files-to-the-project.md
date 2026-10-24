# Leave the cobo-managed boilerplate files to the project

## Context and Problem Statement

The template ships a hand-written `.gitignore` and `.editorconfig`. Rendered repositories
are free to replace them with [cobo](https://github.com/hasansezertasan/cobo) output,
tracked in `cobo.lock` and refreshed by cobo's weekly workflow. A cobo-managed file has a
sealed block that `copier update` would try to three-way merge against the template's
copy, so the next change to the template's `.gitignore` would conflict.

## Considered Options

* Keep both files updated by `copier update`: rejected, it conflicts with cobo-managed
  files as soon as the template's copy changes.
* Drop the files from the template: rejected, a fresh render would start without the
  Terraform state, plan and secrets ignores this template exists to provide.
* Seed them once with `_skip_if_exists`, as copier-copier does: chosen.

## Decision Outcome

`.gitignore` and `.editorconfig` are listed in `_skip_if_exists`. A new repository gets
the template's copies; after that they belong to the project and `copier update` never
touches them. `.gitattributes` is not rendered by this template, so it needs no entry.
