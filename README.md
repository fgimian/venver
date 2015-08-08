# venver
*Simple virtualenv management and auto-switching*

**Please note that this project is a work in progress**

## Introduction ##

venver simplifies virtualenv management for the Bash shell.  It has various
similarities to virtualenvwrapper but attempts to be much simpler, not polute
the command line with various commands and provide auto-switching out of the
box.

## Why Another Tool? ##

Both [virtualenvwrapper](https://bitbucket.org/dhellmann/virtualenvwrapper) and
[pyenv-virtualenv](https://github.com/yyuu/pyenv-virtualenv) greatly inspired 
this tool.  I highly encourage everyone to try all these tools and chose the one
that best fits their needs.  I'm particularly fond of all the pyenv projects.

However, there are reasons that I wanted to develop my own library.

* **virtualenvwrapper** doesn't centralise its commands and pollutes your 
  shell with a huge number of bash functions.  It also doesn't offer auto-
  switching out of the box.
* **pyenv-virtualenv** was much much closer to what I was after and is a really
  awesome project as is pyenv.  However, I do find that I often use system
  provided Python in most cases in my work and the fact that pyenv-virtualenv
  is a plugin to pyenv means that help is not as easy to get to.  venver is a
  more focused tool on this particular task.

## Quick Start ##

```bash
# Source the venver script (add this to your .bash_profile too)
soucre venver.sh

# Create a virtualenv for the current project (enabling auto-activation)
mkdir myproject
cd myproject
venv init
cat .virtualenv  # contains 'myproject'

# List the virtualenvs available
venv list

# Navigating out of and into the project directory will deactivate and activate
# the virtualenv respectively
cd ..         # deactivates the my project virtualenv
cd myproject  # activates the myproject virtualenv
cd ..         # deactivates the my project virtualenv

# You may also create a virtualenv without binding it to a project, this will
# always override your current project virtualenv until you deactiavte it
venv create my_venv
cd myproject           # the my_venv virtualenv will continue to be activated
venv deactivate        # my_env is deactivated and the project virtualenv is activated
venv activate my_venv  # re-activate your non-project virtualenv to force override again

# You may jump straight into a virtualenv base or site-packages directory
# using respective command below
venv base my_venv
venv site my_venv

# If a virtualenv is active, you may use base or site without specifying
# the virtualenv name
cd -
venv base

# You may also copy a virtualenv to a new name
venv copy my_venv new_venv

# Finally, you may remove any virtualenv you like (if active, it will be 
# deactivated for you)
venv remove my_venv

# You may also remove a project virtualenv and its binding
mkdir myproject_subdir
cd myproject_subdir
venv clean  # while in the myproject directory, this will delete the myproject 
            # virtualenv and the related .virtualenv file (venver is smart 
            # enough to deal with being in a sub-directory of the project 
            # while doing this)
```

## Bugs ##

* Auto-complete of virtualenvs with spaces doesn't work correctly
* Initialising a virtualenv without a name doesn't allow you to send options
  to virtualenv
* Fish autocomplete is a little inaccurate

## Current Plans ##

* Unit tests using bats
* Support for zsh
* Autocomplete for virtualenv options (if possible)
