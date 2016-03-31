import shutil
import subprocess
import tempfile

import pytest


class CommandOutput(object):
    def __init__(self, stdout, stderr, returncode):
        self.stdout = stdout
        self.stderr = stderr
        self.returncode = returncode


def run(args, venv_dir, shell):
    """
    Runs venver with the args and shell provided and returns a basic
    CommandOutput object containing stdout, stderr and the return code
    for the call.
    """
    commands = [
        'export VIRTUAL_ENV_HOME={venv_dir}'.format(venv_dir=venv_dir),
        'source venver.{extension}'.format(
            extension='fish' if shell == 'fish' else 'sh', args=args
        ),
        'venv{args}'.format(args=args if args.startswith(' ') else ' ' + args)
    ]

    venver = subprocess.Popen(
        "{shell} -c '{command}'".format(
            shell=shell, command='; '.join(commands)
        ),
        stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True
    )
    stdout, stderr = venver.communicate()

    return CommandOutput(stdout, stderr, venver.returncode)


@pytest.fixture
def venv_tempdir():
    venv_dir = tempfile.mkdtemp()

    def fin():
        shutil.rmtree(venv_dir)
    return venv_dir


def test_help_is_shown(venv_tempdir):
    rv = run(args='', venv_dir=venv_tempdir, shell='bash')
    assert rv.returncode == 1
    assert 'Usage: venv <command> [<args>]' in rv.stdout
