#
# venver: Simple virtualenv management and auto-switching
#

# Set the virtualenv home if not set already
if [ -z $VIRTUALENV_HOME ]
then
  VIRTUALENV_HOME=$HOME/.virtualenvs
fi

# Automatic activation and deactivation of virtualenvs with venver
function cd
{
  # Perform the regular cd
  builtin cd "$@"

  # Iterate through the current directory, heading into each parent directory
  # until we find a .virtualenv file or land in the top directory (/)
  test_directory=$(pwd)
  while [ "$test_directory" != "/" ]
  do
    # The .virtualenv definition was found
    if [ -f $test_directory/.virtualenv ]
    then
      virtualenv=$(cat $test_directory/.virtualenv)

      # The virtualenv is not yet activated
      if [ -z $VIRTUAL_ENV ] || [ $VIRTUAL_ENV != $VIRTUALENV_HOME/$virtualenv ]
      then
        _venv_activate $virtualenv
      fi
      break
    else
      test_directory=$(dirname "$test_directory")
    fi
  done

  # If no virtualenv was found and one is already activated, we deactivate
  # it for the user
  if [ "$test_directory" == "/" ] && [ ! -z $VIRTUAL_ENV ] && \
     [[ $VIRTUAL_ENV == $VIRTUALENV_HOME/* ]]
  then
    deactivate
  fi
}

function venv
{
  if [ -d $VIRTUALENV_HOME ]
  then
    mkdir -p "$VIRTUALENV_HOME"
  fi

  if [ -z $1 ] || [ "$(type -t _venv_$1)" != "function" ]
  then
    cat << EOF
usage: venv <command> [<args>]

The commands available are as follows:

    init        Initialise and create a virtualenv for the current project
    create      Create a virtualenv
    activate    Activate a virtualenv
    copy        Make a copy of a virtualenv
    list        List all available virtualenvs
    cd          Change into the directory of a virtualenv
    remove      Remove a virtualenv

EOF
    return
  fi

  action=$1
  shift
  _venv_$action $@
}

function _venv_init
{
  virtualenv=$(basename $(pwd))

  _venv_create $virtualenv $@

  if [ $? -eq 0 ]
  then
    echo $virtualenv > .virtualenv
  fi
}

function _venv_create
{
  virtualenv=$1
  shift
  virtualenv $@ $VIRTUALENV_HOME/$virtualenv
  if [ $? -eq 0 ]
  then
    _venv_activate $virtualenv
  fi
}

function _venv_activate
{
  if [ -z $1 ] && [ -f .virtualenv ]
  then
    virtualenv=$(cat .virtualenv)
  fi
  virtualenv=$1

  if [ -f $VIRTUALENV_HOME/$virtualenv/bin/activate ]
  then
    source $VIRTUALENV_HOME/$virtualenv/bin/activate
  else
    echo "The virtualenv $virtualenv doesn't exist, unable to activate"
    return 1
  fi
}

function _venv_copy
{
  virtualenv=$1
  destination=$2

  if [ -d $VIRTUALENV_HOME/$destination ]
  then
    echo "The destination virtualenv ${destination} already exists, aborting"
    return 1
  elif [ -f $VIRTUALENV_HOME/$virtualenv/bin/activate ]
  then
    cp -r $VIRTUALENV_HOME/$virtualenv $VIRTUALENV_HOME/$destination
  else
    echo "The virtualenv $virtualenv doesn't exist, unable to change directory"
    return 1
  fi
}

function _venv_list
{
  ls $VIRTUALENV_HOME
}

function _venv_cd
{
  virtualenv=$1

  if [ -f $VIRTUALENV_HOME/$virtualenv/bin/activate ]
  then
    cd $VIRTUALENV_HOME/$virtualenv
  else
    echo "The virtualenv $virtualenv doesn't exist, unable to change directory"
    return 1
  fi
}

function _venv_remove
{
  virtualenv=$1

  if [ -f $VIRTUALENV_HOME/$virtualenv/bin/activate ]
  then
    rm -rf $VIRTUALENV_HOME/$virtualenv
  else
    echo "The virtualenv $virtualenv doesn't exist, unable to remove"
    return 1
  fi
}
