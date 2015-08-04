# venver
*Simple virtualenv management and auto-switching*

**Please note that this project is a work in progress**

## Introduction ##

venver simplifies virtualenv management for the Bash shell.  It has various
similarities to virtualenvwrapper but attempts to be much simpler, not polute
the command line with various commands and provide auto-switching out of the
box.

## Quick Start ##

```bash
# Source the venver script (add this to your .bash_profile too)
soucre venver.sh

# Create a virtualenv for the current project (enabling auto-activation)
cd myproject
venv init
cat .virtualenv

# List the virtualenvs available
venv list

# Navigating out of and into the project directory will deactivate and activate
# the virtualenv respectively
cd ..
cd myproject
cd ..

# You may also create a virtualenv without binding it to a project
venv create my_venv
deactivate
venv activate myenv

# You may jump straight into a virtualenv root directory using cd
venv cd my_venv

# If a virtualenv is active, you may cd into it without specifying the name
venv cd

# You may also copy a virtualenv to a new name
venv my_venv new_venv

# Finally, you may remove any virtualenv you like
venv remove my_venv
```

## Current Plans ##

* A very robust and solid system for performing all actions above
* Full bash completion forthcoming
* Unit tests using bats
* Possibly support for zsh and fish in the near future
