#!/bin/bash
#
# ...~\ venver /~...
#
# Simple virtualenv management and auto-switching
# (https://github.com/fgimian/venver)
#
# The MIT License (MIT)
#
# Copyright (c) 2015 Fotis Gimian
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

# Disable virtualenv override by default
if [ -z "$VIRTUAL_ENV_OVERRIDE" ]
then
  export VIRTUAL_ENV_OVERRIDE=0
fi

# Set the virtualenv home if not set already
if [ -z "$VIRTUAL_ENV_HOME" ]
then
  export VIRTUAL_ENV_HOME=$HOME/.virtualenvs
fi

# Variables to enabled colored output
red='\033[0;31m'
green='\033[0;32m'
blue='\033[0;34m'
no_color='\033[0m'

###############################################################################
# The main entrypoint into venv which displays usage information or runs the
# appropriate function based on user input
#
# Globals:
#   VIRTUAL_ENV_HOME: the directory containing all virtualenvs
# Arguments:
#   command: the venv command to run
###############################################################################
venv()
{
  # Create the virtualenv home if it doesn't exist already
  if [ ! -d "$VIRTUAL_ENV_HOME" ]
  then
    mkdir -p "$VIRTUAL_ENV_HOME"
  fi

  # Display help if no command or an invalid command was provided
  if [ -z "$1" ] || [ "$(type -t _venv_"$1")" != "function" ]
  then
    cat << EOF

$(echo -e "$blue")usage: venv <command> [<args>]$(echo -e "$no_color")

Automatically managing projects:

    init        Initialise and create a virtualenv for the current project
    clean       Remove the virtualenv assigned to the current project

Manually managing virtaulenvs:

    create      Create a virtualenv
    activate    Activate a virtualenv
    deactivate  Deactivate a virtualenv
    remove      Remove a virtualenv

General:

    copy        Make a copy of a virtualenv
    list        List all available virtualenvs
    inspect     Change into the directory of a virtualenv

EOF
    if [ ! -z "$1" ]
    then
      echo -e "${red}venv: unsupported command $1${no_color}"
      echo ""
    fi
    return 1
  fi

  # Obtain the action and then remove it from the argument list
  action=$1
  shift

  # Call the requested command
  "_venv_$action" "$@"
}

###############################################################################
# Automatic activation and deactivation of virtualenvs with venver
#
# Globals:
#   VIRTUAL_ENV: the currently activated virtualenv
#   VIRTUAL_ENV_HOME: the directory containing all virtualenvs
# Arguments:
#   accepts all arguments that the regular builtin cd command accepts
###############################################################################
cd()
{
  # Perform the regular cd
  builtin cd "$@"

  # If the user is controlling their virtualenvs, we don't do anything
  if [ $VIRTUAL_ENV_OVERRIDE -eq 1 ]
  then
    return
  fi

  local virtualenv_dir
  virtualenv_dir=$(__venv_find_virtualenv_file "$(pwd)")

  # If the .virtualenv file was found, we ensure that the environment is activated
  if [ ! -z "$virtualenv_dir" ]
  then
    virtualenv=$(cat "$virtualenv_dir/.virtualenv")

    if [ -f "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate" ]
    then
      source "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate"
    else
      echo -e "${red}venv: the virtualenv $virtualenv doesn't exist, use 'venv init' to create it${no_color}"
      return 1
    fi
  else
    # If no virtualenv was found and one is already activated, we deactivate
    # it for the user
    if [ ! -z "$VIRTUAL_ENV" ] && [[ $VIRTUAL_ENV == $VIRTUAL_ENV_HOME/* ]]
    then
      deactivate
    fi
  fi
}

###############################################################################
# Creates a new virtualenv (if required), activates it and enables the
# virtualenv to be used by this directory
#
# Globals:
#   VIRTUAL_ENV_HOME: the directory containing all virtualenvs
# Arguments:
#   virtualenv (optional): a virtualenv to activate if one hasn't been defined
#                          in a .virtualenv file
###############################################################################
_venv_init()
{
  local virtualenv
  local virtualenv_dir

  virtualenv_dir=$(__venv_find_virtualenv_file "$(pwd)")

  if [ ! -z "$1" ]
  then
    virtualenv=$1
    shift
  elif [ ! -z "$virtualenv_dir" ]
  then
    virtualenv=$(cat "$virtualenv_dir/.virtualenv")
  else
    virtualenv=$(basename "$(pwd)")
  fi

  if [ -z "$virtualenv_dir" ]
  then
    virtualenv_dir="$(pwd)"
  fi

  # Create the virtualenv
  if [ ! -f "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate" ]
  then
    virtualenv "$@" "$VIRTUAL_ENV_HOME/$virtualenv"
    if [ $? -ne 0 ]
    then
      return $?
    fi
  fi

  # Add it to the project's .virtualenv file if necessary
  if [ ! -f "$virtualenv_dir/.virtualenv" ] || \
     [ "$(cat "$virtualenv_dir/.virtualenv")" != "$virtualenv" ]
  then
    echo "$virtualenv" > "${virtualenv_dir}/.virtualenv"
  fi

  # Activate the virtualenv
  if [ $VIRTUAL_ENV_OVERRIDE -eq 0 ]
  then
    source "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate"
  else
    echo "${blue}venv: a virtualenv has been activated manually, please deactivate it to enable $virtualenv${no_color}"
    return 1
  fi
}

_venv_clean()
{
  local virtualenv_dir

  virtualenv_dir=$(__venv_find_virtualenv_file "$(pwd)")

  if [ -z "$virtualenv_dir" ]
  then
    echo -e "${red}venv: no virtualenv was found in a .virtualenv file${no_color}"
    return 1
  fi

  virtualenv=$(cat "$virtualenv_dir/.virtualenv")

  if [ ! -z "$VIRTUAL_ENV" ] && \
     [ "$VIRTUAL_ENV_HOME/$virtualenv" = "$VIRTUAL_ENV" ] && \
     [ $VIRTUAL_ENV_OVERRIDE -eq 1 ]
  then
    echo -e "${red}venv: the project's virtualenv has been manually activated, unable to continue${no_color}"
    return 1
  fi

  if [ ! -z "$VIRTUAL_ENV" ] && \
     [ "$VIRTUAL_ENV" = "$VIRTUAL_ENV_HOME/$virtualenv" ]
  then
    deactivate
  fi

  _venv_remove "$virtualenv"
  rm -f "$virtualenv_dir/.virtualenv"
}

_venv_create()
{
  if [ -z "$1" ]
  then
    echo -e "${blue}usage: venv create <name>${no_color}"
    return 1
  fi

  virtualenv=$1
  shift

  if [ -d "$VIRTUAL_ENV_HOME/$virtualenv" ]
  then
    echo -e "${red}venv: the virtualenv $virtualenv already exists, aborting${no_color}"
    return 1
  fi

  virtualenv "$@" "$VIRTUAL_ENV_HOME/$virtualenv"
  if [ $? -eq 0 ]
  then
    _venv_activate "$virtualenv"
  fi
}

###############################################################################
# Activates the nearest virtualenv or one provided
#
# Globals:
#   VIRTUAL_ENV_HOME: the directory containing all virtualenvs
# Arguments:
#   virtualenv: a virtualenv to manually activate
###############################################################################
_venv_activate()
{
  if [ -z "$1" ]
  then
    echo -e "${blue}usage: venv create <name>${no_color}"
    return 1
  fi

  local virtualenv
  virtualenv=$1

  if [ -f "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate" ]
  then
    source "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate"
    export VIRTUAL_ENV_OVERRIDE=1
  else
    echo -e "${red}venv: the virtualenv $virtualenv doesn't exist, unable to activate${no_color}"
    return 1
  fi
}

_venv_deactivate()
{
  if [ ! -z "$VIRTUAL_ENV" ]
  then
    local virtualenv
    local virtualenv_dir
    local override=0

    virtualenv_dir=$(__venv_find_virtualenv_file "$(pwd)")

    if [ $VIRTUAL_ENV_OVERRIDE -eq 1 ]
    then
      override=1
      deactivate
      export VIRTUAL_ENV_OVERRIDE=0
    fi

    # If the .virtualenv file was found, we ensure that environment stays activated
    if [ ! -z "$virtualenv_dir" ]
    then
      virtualenv=$(cat "$virtualenv_dir/.virtualenv")
      if [ -f "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate" ]
      then
        source "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate"
        if [ $override -eq 1 ]
        then
          echo -e "${blue}venv: reverting to the virtualenv $virtualenv as defined in the .virtualenv file${no_color}"
        else
          echo -e "${red}venv: a .virtualenv file was found; unable to deactivate${no_color}"
        fi
      else
        echo -e "${red}venv: the virtualenv $virtualenv doesn't exist, unable to activate${no_color}"
        return 1
      fi
    fi
  else
    echo -e "${red}venv: no virtualenv is curretly activated${no_color}"
    return 1
  fi
}

_venv_remove()
{
  if [ -z "$1" ]
  then
    echo -e "${blue}usage: venv remove <name>${no_color}"
    return 1
  fi

  local return_code
  local virtualenv

  # Remove the virtualenv and all its related files
  return_code=0
  for virtualenv in "$@"
  do
    if [ -f "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate" ]
    then
      if [ ! -z "$VIRTUAL_ENV" ] && \
         [ "$VIRTUAL_ENV" = "$VIRTUAL_ENV_HOME/$virtualenv" ]
      then
        if [ $VIRTUAL_ENV_OVERRIDE -eq 1 ]
        then
          export VIRTUAL_ENV_OVERRIDE=0
        fi
        deactivate
      fi

      rm -rf "${VIRTUAL_ENV_HOME:?}/$virtualenv"
    else
      echo -e "${red}venv: the virtualenv $virtualenv doesn't exist, unable to remove${no_color}"
      return_code=1
    fi
  done

  return $return_code
}

_venv_copy()
{
  if [ -z "$1" ] || [ -z "$2" ]
  then
    echo -e "${blue}usage: venv copy <source_name> <destination_name>${no_color}"
    return 1
  fi

  local virtualenv=$1
  local destination=$2

  if [ -d "$VIRTUAL_ENV_HOME/$destination" ]
  then
    echo -e "${red}venv: he destination virtualenv $destination already exists, aborting${no_color}"
    return 1
  elif [ -f "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate" ]
  then
    virtualenv-clone "$VIRTUAL_ENV_HOME/$virtualenv" "$VIRTUAL_ENV_HOME/$destination"
  else
    echo -e "${red}venv: the virtualenv $virtualenv doesn't exist, unable to change directory${no_color}"
    return 1
  fi
}

__venv_simple_list()
{
  local virtualenv_name

  while IFS= read -r -d '' dir
  do
    if [ -f "$dir/bin/activate" ]
    then
      virtualenv_name=$(basename "$dir")
      echo "$virtualenv_name"
    fi
  done < <(find "$VIRTUAL_ENV_HOME" -mindepth 1 -maxdepth 1 -type d -print0)
}

_venv_list()
{
  virtualenvs=$(__venv_simple_list)
  if [ -z "$virtualenvs" ]
  then
    echo -e "${blue}venv: no virtualenvs were found in $VIRTUAL_ENV_HOME${no_color}"
    return  1
  fi

  echo -e "${green}virtualenvs found in $VIRTUAL_ENV_HOME${no_color}"
  IFS=$'\n'
  for virtualenv in $(__venv_simple_list)
  do
    echo "* $virtualenv"
  done
  unset IFS
}

_venv_inspect()
{
  local virtualenv
  local virtualenv_dir

  virtualenv_dir=$(__venv_find_virtualenv_file "$(pwd)")

  if [ ! -z "$1" ]
  then
    virtualenv=$1
    shift
  elif [ ! -z "$virtualenv_dir" ]
  then
    virtualenv=$(cat "$virtualenv_dir/.virtualenv")
  else
    echo -e "${red}venv: no virtualenv specified or found in a .virtualenv file${no_color}"
    return 1
  fi

  # Change into the virtualenv directory
  if [ -f "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate" ]
  then
    cd "$VIRTUAL_ENV_HOME/$virtualenv"
  else
    echo -e "${red}venv: the virtualenv $virtualenv doesn't exist, unable to change directory${no_color}"
    return 1
  fi
}

###############################################################################
# Attempts to find the nearest .virtualenv file
#
# Arguments:
#   dir: the directory to search
# Returns:
#   the directory containing the .virtualenv file or nothing if a suitable
#   location was not found
###############################################################################
__venv_find_virtualenv_file()
{
  local test_directory=$1
  while [ "$test_directory" != "/" ]
  do
    if [ -f "$test_directory/.virtualenv" ]
    then
      virtualenv=$(cat "$test_directory/.virtualenv")
      break
    else
      test_directory=$(dirname "$test_directory")
    fi
  done

  if [ "$test_directory" != "/" ]
  then
    echo "$test_directory"
  fi
}

_venv_completion()
{
  local cur prev opts
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  command="${COMP_WORDS[1]}"

  case $prev in
    venv)
      opts="init clean create activate deactivate remove copy list inspect"
      ;;
    activate|inspect|remove|init|copy)
      opts=$(__venv_simple_list)
      ;;
    *)
      # Support deletion of multiple virtualenvs at the same time
      if [ "$command" = "remove" ]
      then
        opts=$(__venv_simple_list)
      else
        opts=""
      fi
      ;;
  esac

  COMPREPLY=($(compgen -W "$opts" -- "$cur"))
}

# Enable bash completion for the venv command
complete -F _venv_completion venv
