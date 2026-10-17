import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";

const dir = mkdtempSync(join(tmpdir(), "release-merge-"));
const releaseMerge = (pulls, sha) => {
  const file = join(dir, "pulls.json");
  writeFileSync(file, JSON.stringify(pulls));
  return execFileSync("node", ["scripts/release-merge.mjs", "--pulls", file, "--sha", sha], {
    stdio: "pipe",
  })
    .toString()
    .trim();
};
const pr = (sha, overrides = {}) => ({
  merged_at: "2026-10-16T00:00:00Z",
  base: { ref: "main" },
  labels: [{ name: "autorelease: pending" }],
  merge_commit_sha: sha,
  ...overrides,
});

test("allows the sole pending release merged as the validated commit", () => {
  assert.equal(releaseMerge([[pr("abc")]], "abc"), "is-release-merge=true");
  const tagged = pr("old", { labels: [{ name: "autorelease: tagged" }] });
  assert.equal(releaseMerge([[tagged], [pr("abc")]], "abc"), "is-release-merge=true");
});

test("refuses a stale pending merge on a later commit", () => {
  assert.equal(releaseMerge([[pr("abc")]], "later"), "is-release-merge=false");
});

test("refuses two pending merges, even when one matches", () => {
  assert.equal(releaseMerge([[pr("abc")], [pr("def")]], "abc"), "is-release-merge=false");
});

test("ignores unmerged, other-branch and unlabelled pull requests", () => {
  const noise = [pr("abc", { merged_at: null }), pr("abc", { base: { ref: "dev" } }), pr("abc", { labels: [] })];
  assert.equal(releaseMerge([noise], "abc"), "is-release-merge=false");
  assert.equal(releaseMerge([[...noise, pr("abc")]], "abc"), "is-release-merge=true");
});
