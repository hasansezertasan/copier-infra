import shutil
import subprocess
import sys
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parent.parent
IGNORE = shutil.ignore_patterns(".git", ".venv", "__pycache__", ".pytest_cache")


def run(*args: str, cwd: Path) -> subprocess.CompletedProcess:
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=False)


def copier(*args: str, cwd: Path) -> subprocess.CompletedProcess:
    return run(sys.executable, "-m", "copier", *args, cwd=cwd)


def git(*args: str, cwd: Path) -> subprocess.CompletedProcess:
    return run(
        "git", "-c", "user.name=test", "-c", "user.email=test@example.com", *args, cwd=cwd
    )


@pytest.fixture
def versioned_template(tmp_path) -> Path:
    """A throwaway git copy of this repo, tagged v0.0.0, so `copier update` has history."""
    src = tmp_path / "template-src"
    shutil.copytree(REPO, src, ignore=IGNORE)
    git("init", "-q", "-b", "main", cwd=src)
    git("add", "-A", cwd=src)
    git("commit", "-q", "-m", "chore: initial", cwd=src)
    git("tag", "v0.0.0", cwd=src)
    return src
