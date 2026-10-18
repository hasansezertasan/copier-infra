import pytest
import yaml
from conftest import copier, git

# The infra template has required questions without defaults; this is the gcs scenario
# from scripts/test-template.sh.
ANSWERS = [
    "--data=github_org=example-org",
    "--data=apex_domain=example.com",
    "--data=cloudflare_account_id=0123456789abcdef0123456789abcdef",
    "--data=cloudflare_zone_id=fedcba9876543210fedcba9876543210",
    "--data=backend=object-storage",
    "--data=state_backend=gcs",
    "--data=state_bucket=example-state",
]


def test_template_renders_with_defaults(tmp_path, versioned_template):
    dest = tmp_path / "project"
    result = copier("copy", "--defaults", *ANSWERS, str(versioned_template), str(dest), cwd=tmp_path)
    assert result.returncode == 0, result.stderr
    assert (dest / ".copier-answers.yml").exists()


def test_update_to_a_new_version_only_moves_the_answers_commit(tmp_path, versioned_template):
    dest = tmp_path / "project"
    copier("copy", "--defaults", *ANSWERS, str(versioned_template), str(dest), cwd=tmp_path)
    git("init", "-q", "-b", "main", cwd=dest)
    git("add", "-A", cwd=dest)
    git("commit", "-q", "-m", "chore: render", cwd=dest)

    git("commit", "-q", "--allow-empty", "-m", "chore: release", cwd=versioned_template)
    git("tag", "v0.0.1", cwd=versioned_template)

    result = copier("update", "--defaults", "--skip-answered", cwd=dest)
    assert result.returncode == 0, result.stderr
    changed = {line[3:] for line in git("status", "--porcelain", cwd=dest).stdout.splitlines()}
    assert changed == {".copier-answers.yml"}
    answers = yaml.safe_load((dest / ".copier-answers.yml").read_text())
    assert answers["_commit"] == "v0.0.1"


HCP = ["--data=backend=hcp", "--data=hcp_org=example-org"]
OBJECT_STORAGE = ANSWERS[4:]
COMMON = ANSWERS[:4]

CUSTOMIZATION_START = "# infra:customization start"
CUSTOMIZATION_END = "# infra:customization end"


def render(tmp_path, template, backend_answers, name="project"):
    dest = tmp_path / name
    result = copier("copy", "--defaults", *COMMON, *backend_answers, str(template), str(dest), cwd=tmp_path)
    assert result.returncode == 0, result.stderr
    return dest


def section(text, heading, start, end):
    """The lines under `heading`, from the start marker through the end marker."""
    lines = text.splitlines()
    assert lines.count(heading) == 1, f"expected exactly one {heading!r} heading"
    after = lines[lines.index(heading) + 1 :]
    assert lines.count(start) == 1 and lines.count(end) == 1
    assert start in after and end in after
    body = after[after.index(start) + 1 : after.index(end)]
    assert after.index(start) < after.index(end)
    return body


def config_block(readme):
    body = section(readme, "## Config", "<!-- infra:config start -->", "<!-- infra:config end -->")
    assert body[0] == "```yaml" and body[-1] == "```", "the Config block is one fenced YAML block"
    assert body.count("```yaml") == 1 and body.count("```") == 1
    return body[1:-1]


BACKENDS = pytest.param(HCP, id="hcp"), pytest.param(OBJECT_STORAGE, id="object-storage")


@pytest.mark.parametrize("backend_answers", BACKENDS)
def test_readme_config_block_has_answers_outside_and_attestations_inside_the_markers(
    tmp_path, versioned_template, backend_answers
):
    dest = render(tmp_path, versioned_template, backend_answers)
    block = config_block((dest / "README.md").read_text())

    assert block.count(CUSTOMIZATION_START) == 1 and block.count(CUSTOMIZATION_END) == 1
    start, end = block.index(CUSTOMIZATION_START), block.index(CUSTOMIZATION_END)
    assert start < end

    config = yaml.safe_load("\n".join(block))
    inside = yaml.safe_load("\n".join(block[start:end]))
    outside = yaml.safe_load("\n".join(block[:start] + block[end:]))

    # Template answers stay outside the markers, so a Template update owns them.
    assert outside["backend"] == config["backend"]
    assert outside["github_org"] == "example-org"
    assert outside["managed_repos"] == ["example-org/infra"]
    assert "backend" not in inside

    # Everything the Skills and humans write is inside, so a Template update keeps it.
    expected = {"leaf_backends", "state_transfers", "github_apps", "additional_providers"}
    if config["backend"] == "hcp":
        expected.add("hcp_status_check_id")
    assert expected <= inside.keys()
    assert set(inside) == expected
    assert inside["github_apps"]["reviewed_at"] == ""
    assert inside["additional_providers"] == []


def test_readme_config_block_keeps_the_backend_specific_answers(tmp_path, versioned_template):
    hcp = config_block((render(tmp_path, versioned_template, HCP, "hcp") / "README.md").read_text())
    assert yaml.safe_load("\n".join(hcp))["hcp_org"] == "example-org"

    storage = config_block(
        (render(tmp_path, versioned_template, OBJECT_STORAGE, "storage") / "README.md").read_text()
    )
    parsed = yaml.safe_load("\n".join(storage))
    assert (parsed["backend"], parsed["state_backend"], parsed["state_bucket"]) == (
        "object-storage",
        "gcs",
        "example-state",
    )
    assert "hcp_org" not in parsed


@pytest.mark.parametrize("backend_answers", BACKENDS)
def test_readme_decisions_table_is_a_fixed_section(tmp_path, versioned_template, backend_answers):
    dest = render(tmp_path, versioned_template, backend_answers)
    body = section(
        (dest / "README.md").read_text(),
        "## Decisions",
        "<!-- infra:decisions start -->",
        "<!-- infra:decisions end -->",
    )
    table = [line for line in body if line.startswith("|")]
    assert table[0] == "| Decision | Choice | Status | Rationale |"
    assert table[1] == "|---|---|---|---|"
    rows = [[cell.strip() for cell in line.strip("|").split("|")] for line in table[2:]]
    assert rows and all(len(row) == 4 for row in rows)
    assert {row[2] for row in rows} == {"locked"}
    assert any(row[0] == "Apply policy" for row in rows)


@pytest.mark.parametrize("backend_answers", BACKENDS)
def test_no_old_state_directory_or_legacy_settings_file_is_rendered(
    tmp_path, versioned_template, backend_answers
):
    dest = render(tmp_path, versioned_template, backend_answers)
    assert not (dest / ".infra-copilot").exists()
    assert not (dest / ".claude" / "infra-copilot.local.md").exists()
    leftovers = [
        str(path.relative_to(dest))
        for path in dest.rglob("*")
        if path.is_file() and b"infra-copilot" in path.read_bytes()
    ]
    assert leftovers == []
