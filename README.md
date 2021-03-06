# venver

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/fgimian/venver/blob/master/LICENSE)

![venver Logo](https://raw.githubusercontent.com/fgimian/venver/master/images/venver-logo.png)

Artwork courtesy of
[Open Clip Art Library](https://openclipart.org/detail/110179/decorative-bird)

## Introduction

venver simplifies virtualenv management for the Bash shell.  It has various
similarities to virtualenvwrapper but attempts to be much simpler, not polute
the command line with various commands and provide auto-switching out of the
box.

venver supports bash, ZSH and fish shells fully, include completions for each.

## Why Another Tool?

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

## Installation

### Bash

```bash
curl -o /usr/local/bin/venver.sh https://raw.githubusercontent.com/fgimian/venver/master/venver.sh
echo "source /usr/local/bin/venver.sh" >> ~/.bash_profile
source ~/.bash_profile
```

### ZSH

```bash
curl -o /usr/local/bin/venver.sh https://raw.githubusercontent.com/fgimian/venver/master/venver.sh
echo "source /usr/local/bin/venver.sh" >> ~/.zshrc
source ~/.zshrc
```

### Fish

```bash
curl -o /usr/local/bin/venver.fish https://raw.githubusercontent.com/fgimian/venver/master/venver.fish
echo ". /usr/local/bin/venver.fish" >> ~/.config/fish/config.fish
. ~/.config/fish/config.fish
```

## Quick Start

```bash
# Source the venver script (add this to your .bash_profile too)
source venver.sh

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

# With the create and init commands, you may pass additional arguments
# to the virtualenv command
venv init -p python3.4
```

### Changing the Virtualenv Home Directory

By default, all virtualenvs are stored in **~/.virtualenvs**, but this may be
overriden.  Simply export **VIRTUAL_ENV_HOME** with your chosen location before
souring venver.

e.g.

```bash
export VIRTUAL_ENV_HOME=$HOME/projects/virtualenvs
source venver.sh
```

## License

venver is released under the **MIT** license. Please see the
[LICENSE](https://github.com/fgimian/venver/blob/master/LICENSE)
file for more details.

## TODO

* Auto-complete of virtualenvs with spaces doesn't work correctly
* Fish autocomplete is a little inaccurate
* Unit tests using bats
