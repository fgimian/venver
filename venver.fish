#!/usr/bin/env fish
#
# ...~\ venver /~...
#       (fish)
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
    export VIRTUAL_ENV_OVERRIDE=0
end

# Set the virtualenv home if not set already
if [ -z "$VIRTUAL_ENV_HOME" ]
    export VIRTUAL_ENV_HOME=$HOME/.virtualenvs
end

# Variables to enabled colored output
set red '\033[0;31m'
set green '\033[0;32m'
set blue '\033[0;34m'
set cyan '\033[0;36m'
set no_color '\033[0m'

# The main entrypoint into venv which displays usage information or runs the
# appropriate function based on user input
function venv
    # Create the virtualenv home if it doesn't exist already
    if [ ! -d "$VIRTUAL_ENV_HOME" ]
        mkdir -p "$VIRTUAL_ENV_HOME"
    end

    # Obtain the action and then remove it from the argument list
    set -l action $argv[1]
    set -e argv[1]

    # Display help if no command or an invalid command was provided
    if begin; [ -z "$action" ]; or \
              [ (type -t _venv_"$action") != "function" ]; end
        echo -e $blue"Usage: venv <command> [<args>]"$no_color"

"$cyan"Automatically manage virtualenvs for projects:"$no_color"

    init          Initialise and create a virtualenv for the current project
    clean         Remove the virtualenv assigned to the current project

"$cyan"Manually manage virtaulenvs:"$no_color"

    create        Create a virtualenv
    activate      Activate a virtualenv
    deactivate    Deactivate a virtualenv
    remove        Remove a virtualenv

"$cyan"General:"$no_color"

    copy          Make a copy of a virtualenv
    list          List all available virtualenvs
    base          Change into the base directory of a virtualenv
    site          Change into the site-packages directory of a virtualenv

Please see https://github.com/fgimian/venver for more information"

        if [ ! -z "$argv[1]" ]
            echo -e $red"venv: unsupported command $argv[1]"$no_color
            echo -e ""
        end
        return 1
    end

    # Call the requested command
    eval "_venv_$action" $argv
end

# Automatic activation and deactivation of virtualenvs with venver
function cd
    # Perform the regular cd
    builtin cd $argv

    # If the user is controlling their virtualenvs, we don't do anything
    if [ $VIRTUAL_ENV_OVERRIDE -eq 1 ]
        return
    end

    set -l virtualenv_dir
    set virtualenv_dir (__venv_find_virtualenv_file (pwd))

    # If the .virtualenv file was found, we ensure that the environment is
    # activated
    if [ ! -z "$virtualenv_dir" ]
        set virtualenv (cat "$virtualenv_dir/.virtualenv")

        if [ -f "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate.fish" ]
            source "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate.fish"
        else
            echo -e $red"venv: the virtualenv $virtualenv doesn't exist,"\
                    "use 'venv init' to create it"$no_color
            return 1
        end
    else
        # If no virtualenv was found and one is already activated, we
        # deactivate it for the user
        # TODO: re-instate the check for home directory
        if begin; [ ! -z "$VIRTUAL_ENV" ]; end
        #; and [[ $VIRTUAL_ENV == $VIRTUAL_ENV_HOME/* ]]; end
            deactivate
        end
    end
end

# Creates a new virtualenv (if required), activates it and enables the
function _venv_init
    set -l virtualenv
    set -l virtualenv_dir

    set virtualenv_dir (__venv_find_virtualenv_file (pwd))

    if [ ! -z "$argv[1]" ]
        set virtualenv $argv[1]
        set -e argv[1]
    else if  [ ! -z "$virtualenv_dir" ]
        set virtualenv (cat "$virtualenv_dir/.virtualenv")
    else
        set virtualenv (basename (pwd))
    end

    if [ -z "$virtualenv_dir" ]
        set virtualenv_dir (pwd)
    end

    # Create the virtualenv
    if [ ! -f "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate.fish" ]
        virtualenv $argv "$VIRTUAL_ENV_HOME/$virtualenv"
        if [ $status -ne 0 ]
            return $status
        end
    end

    # Add it to the project's .virtualenv file if necessary
    if begin; [ ! -f "$virtualenv_dir/.virtualenv" ]; or \
              [ (cat "$virtualenv_dir/.virtualenv") != "$virtualenv" ]; end
        echo "$virtualenv" > "$virtualenv_dir/.virtualenv"
    end

    # Activate the virtualenv
    if [ $VIRTUAL_ENV_OVERRIDE -eq 0 ]
        source "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate.fish"
    else
        echo -e $blue"venv: a virtualenv has been activated manually,"\
                "please deactivate it to enable $virtualenv"$no_color
        return 1
    end
end

# Removes a project's virtualenv and related .virtualenv file
function _venv_clean
    set -l virtualenv_dir

    set virtualenv_dir (__venv_find_virtualenv_file (pwd))

    if [ -z "$virtualenv_dir" ]
        echo -e $red"venv: no virtualenv was found in a .virtualenv"\
                "file"$no_color
        return 1
    end

    set -l virtualenv (cat "$virtualenv_dir/.virtualenv")

    if begin; [ ! -z "$VIRTUAL_ENV" ]; and \
              [ "$VIRTUAL_ENV_HOME/$virtualenv" = "$VIRTUAL_ENV" ]; and \
              [ $VIRTUAL_ENV_OVERRIDE -eq 1 ]; end
        echo -e $red"venv: the project's virtualenv has been manually"\
                "activated, unable to continue"$no_color
        return 1
    end

    if begin; [ ! -z "$VIRTUAL_ENV" ]; and \
              [ "$VIRTUAL_ENV" = "$VIRTUAL_ENV_HOME/$virtualenv" ]; end
        deactivate
    end

    # TODO: make this safer (like bash)
    rm -rf "$VIRTUAL_ENV_HOME/$virtualenv"
    rm -f "$virtualenv_dir/.virtualenv"
end

# Creates a new self-managed virtualenv with the given name
function _venv_create
    if [ -z "$argv[1]" ]
        echo -e $blue"Usage: venv create <name>"$no_color
        return 1
    end

    set -l virtualenv $argv[1]
    set -e argv[1]

    if [ -d "$VIRTUAL_ENV_HOME/$virtualenv" ]
        echo -e $red"venv: the virtualenv $virtualenv already exists,"\
                "aborting"$no_color
        return 1
    end

    virtualenv $argv "$VIRTUAL_ENV_HOME/$virtualenv"
    if [ $status -eq 0 ]
        source "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate.fish"
        export VIRTUAL_ENV_OVERRIDE=1
    end
end

# Activates the nearest virtualenv or one provided
function _venv_activate
    if [ -z "$argv[1]" ]
        echo -e $blue"Usage: venv create <name>"$no_color
        return 1
    end

    set -l virtualenv $argv[1]

    if [ -f "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate.fish" ]
        source "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate.fish"
        export VIRTUAL_ENV_OVERRIDE=1
    else
        echo -e $red"venv: the virtualenv $virtualenv doesn't exist, unable"\
                "to activate"$no_color
        return 1
    end
end

# Deactivates a self-managed virtualenv
function _venv_deactivate
    if [ ! -z "$VIRTUAL_ENV" ]
        set -l virtualenv
        set -l virtualenv_dir
        set -l override 0

        set virtualenv_dir (__venv_find_virtualenv_file (pwd))

        if [ $VIRTUAL_ENV_OVERRIDE -eq 1 ]
            set override 1
            deactivate
            export VIRTUAL_ENV_OVERRIDE=0
        end

        # If the .virtualenv file was found, we ensure that environment stays
        # activated
        if [ ! -z "$virtualenv_dir" ]
            set virtualenv (cat "$virtualenv_dir/.virtualenv")
            if [ -f "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate.fish" ]
                source "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate.fish"
                if [ $override -eq 1 ]
                    echo -e $blue"venv: reverting to the virtualenv"\
                            "$virtualenv as defined in the .virtualenv"\
                            "file"$no_color
                else
                    echo -e $red"venv: a .virtualenv file was found; unable"\
                            "to deactivate"$no_color
                end
            else
                echo -e $red"venv: the virtualenv $virtualenv doesn't"\
                        "exist, unable to activate"$no_color
                return 1
            end
        end
    else
        echo -e $red"venv: no virtualenv is curretly activated"$no_color
        return 1
    end
end

# Deletes a self-managed virtualenv
function _venv_remove
    if [ -z "$argv[1]" ]
        echo -e $blue"Usage: venv remove <name>"$no_color
        return 1
    end

    set -l return_code 0
    set -l virtualenv
    set -l virtualenv_dir

    # Remove the virtualenv and all its related files
    for virtualenv in $argv
        if [ -f "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate.fish" ]
            if begin; [ ! -z "$VIRTUAL_ENV" ]; and \
                      [ "$VIRTUAL_ENV" = "$VIRTUAL_ENV_HOME/$virtualenv" ]; end
                if [ $VIRTUAL_ENV_OVERRIDE -eq 1 ]
                    export VIRTUAL_ENV_OVERRIDE=0
                end
                deactivate
            end

            set virtualenv_dir (__venv_find_virtualenv_file (pwd))

            if [ ! -z "$virtualenv_dir" ]
                echo -e $blue"venv: removing virtualenv which was specified"\
                        "in a .virtualenv file, use 'venv init' to"\
                        "recreate"$no_color
            end

            rm -rf "$VIRTUAL_ENV_HOME/$virtualenv"
        else
            echo -e $red"venv: the virtualenv $virtualenv doesn't exist,"\
                    "unable to remove"$no_color
            set -l return_code 1
        end
    end

    return $return_code
end

# Makes a copy of a virtualenv
function _venv_copy
    hash virtualenv-clone 2> /dev/null
    if [ $status -ne 0 ]
        echo -e $red"Error: virtualenv-clone is required for the copy"\
                "command to work"$no_color
        return 1
    end

    if begin; [ -z "$argv[1]" ]; or [ -z "$argv[2]" ]; end
        echo -e $blue"Usage: venv copy <source_name>"\
                "<destination_name>"$no_color
        return 1
    end

    set -l virtualenv $argv[1]
    set -l destination $argv[2]

    if [ -d "$VIRTUAL_ENV_HOME/$destination" ]
        echo -e $red"venv: he destination virtualenv $destination already"\
                "exists, aborting"$no_color
        return 1
    else if  [ -f "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate.fish" ]
        virtualenv-clone \
            "$VIRTUAL_ENV_HOME/$virtualenv" "$VIRTUAL_ENV_HOME/$destination"
    else
        echo -e $red"venv: the virtualenv $virtualenv doesn't exist, unable"\
                "to change directory"$no_color
        return 1
    end
end

# Provides a plain listing of virtualenvs
function __venv_simple_list
    set -l virtualenv_name

    for dir in (find "$VIRTUAL_ENV_HOME" -mindepth 1 -maxdepth 1 -type d)
        if [ -f "$dir/bin/activate.fish" ]
            set virtualenv_name (basename "$dir")
            echo "$virtualenv_name"
        end
    end
end

# Lists all virtualenvs that are available
function _venv_list
    set -l virtualenv_dir

    set virtualenvs (__venv_simple_list)
    if [ -z "$virtualenvs" ]
        echo -e $blue"venv: no virtualenvs were found in"\
                "$VIRTUAL_ENV_HOME"$no_color
        return 1
    end

    echo -e $cyan"virtualenvs found in $VIRTUAL_ENV_HOME"$no_color
    for virtualenv in (__venv_simple_list)
        if begin; [ ! -z "$VIRTUAL_ENV" ]; and \
                  [ "$VIRTUAL_ENV_HOME/$virtualenv" = "$VIRTUAL_ENV" ]; end
            echo -e -n $green"* $virtualenv "
            if [ $VIRTUAL_ENV_OVERRIDE -eq 1 ]
                echo -e -n "(manually managed)"
            else
                set virtualenv_dir (__venv_find_virtualenv_file (pwd))
                set virtualenv_dir (echo $virtualenv_dir | sed s:$HOME:~:)
                echo -e -n "(as defined in $virtualenv_dir/.virtualenv)"
            end
            echo -e ""$no_color
        else
            echo -e "  $virtualenv"
        end
    end
end

# Changes into the base directory of a virtualenv
function _venv_base
    set -l virtualenv
    set -l virtualenv_dir

    set virtualenv_dir (__venv_find_virtualenv_file (pwd))

    if [ ! -z "$argv[1]" ]
        set virtualenv $argv[1]
        set -e argv[1]
    else if  [ ! -z "$virtualenv_dir" ]
        set virtualenv (cat "$virtualenv_dir/.virtualenv")
    else
        echo -e $red"venv: no virtualenv specified or found in a"\
                ".virtualenv file"$no_color
        return 1
    end

    # Change into the virtualenv directory
    if [ -f "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate.fish" ]
        cd "$VIRTUAL_ENV_HOME/$virtualenv"
    else
        echo -e $red"venv: the virtualenv $virtualenv doesn't exist, unable"\
                "to change directory"$no_color
        return 1
    end
end

# Changes into the site-packages directory of a virtualenv
function _venv_site
    set -l virtualenv
    set -l virtualenv_dir

    set virtualenv_dir (__venv_find_virtualenv_file (pwd))

    if [ ! -z "$argv[1]" ]
        set virtualenv $argv[1]
        set -e argv[1]
    else if  [ ! -z "$virtualenv_dir" ]
        set virtualenv (cat "$virtualenv_dir/.virtualenv")
    else
        echo -e $red"venv: no virtualenv specified or found in a"\
                ".virtualenv file"$no_color
        return 1
    end

    # Change into the virtualenv directory
    if [ -f "$VIRTUAL_ENV_HOME/$virtualenv/bin/activate.fish" ]
        set site_packages_dir (eval "$VIRTUAL_ENV_HOME/$virtualenv/bin/python -c \"import distutils; print(distutils.sysconfig.get_python_lib())\"")
        cd "$site_packages_dir"
    else
        echo -e $red"venv: the virtualenv $virtualenv doesn't exist, unable"\
                "to change directory"$no_color
        return 1
    end
end

# Attempts to find the nearest .virtualenv file
function __venv_find_virtualenv_file
    set -l test_directory $argv[1]
    while [ "$test_directory" != "/" ]
        if [ -f "$test_directory/.virtualenv" ]
            set virtualenv (cat "$test_directory/.virtualenv")
            break
        else
            set test_directory (dirname "$test_directory")
        end
    end

    if [ "$test_directory" != "/" ]
        echo "$test_directory"
    end
end

function __venv_fish_needs_command
    set cmd (commandline -opc)
    if [ (count $cmd) -eq 1 -a $cmd[1] = 'venv' ]
        return 0
    end
    return 1
end

function __venv_fish_using_command
    set cmd (commandline -opc)
    echo "argv is: $argv" >> abc.txt
    echo "cmd is: $cmd" >> abc.txt
    if [ (count $cmd) -gt 1 ]
        echo "comparing $argv[1] with $cmd[2]" >> abc.txt
        echo "" >> abc.txt
        if [ $argv[1] = $cmd[2] ]
            return 0
        end
    end
    return 1
end

# Fish completion for venver
complete -f -c venv -n '__venv_fish_needs_command' \
    -a init -d 'Initialise and create a virtualenv for the current project'
complete -f -c venv -n '__venv_fish_needs_command' \
    -a clean -d 'Remove the virtualenv assigned to the current project'
complete -f -c venv -n '__venv_fish_needs_command' \
    -a create -d 'Create a virtualenv'
complete -f -c venv -n '__venv_fish_needs_command' \
    -a activate -d 'Activate a virtualenv'
complete -f -c venv -n '__venv_fish_needs_command' \
    -a deactivate -d 'Deactivate a virtualenv'
complete -f -c venv -n '__venv_fish_needs_command' \
    -a remove -d 'Remove a virtualenv'
complete -f -c venv -n '__venv_fish_needs_command' \
    -a copy -d 'Make a copy of a virtualenv'
complete -f -c venv -n '__venv_fish_needs_command' \
    -a list -d 'List all available virtualenvs'
complete -f -c venv -n '__venv_fish_needs_command' \
    -a base -d 'Change into the base directory of a virtualenv'
complete -f -c venv -n '__venv_fish_needs_command' \
    -a site -d 'Change into the site-packages directory of a virtualenv'

for command in init clean create activate deactivate remove copy list base site
    complete -f -c venv \
        -n "__venv_fish_using_command $command" \
        -a '(__venv_simple_list)' -d "virtualenv"
end
