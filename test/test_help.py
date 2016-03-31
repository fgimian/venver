from .helpers import run
from .helpers import venv_tempdir  # flake8: noqa


def test_help_is_shown(venv_tempdir):
    rv = run(args='', venv_dir=venv_tempdir, shell='bash')
    assert rv.returncode == 1
    assert 'Usage: venv <command> [<args>]' in rv.stdout


def test_invalid_argument(venv_tempdir):
    rv = run(args='booboo', venv_dir=venv_tempdir, shell='bash')
    assert rv.returncode == 1
    assert 'Usage: venv <command> [<args>]' in rv.stdout
    assert 'venv: unsupported command booboo' in rv.stdout
