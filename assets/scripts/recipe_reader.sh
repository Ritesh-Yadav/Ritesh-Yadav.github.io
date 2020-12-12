#!/bin/bash

print_command=''

setup_color() {
	# Only use colors if connected to a terminal
	if [ -t 1 ]; then
        RED=$(printf '\033[31m')
		GREEN=$(printf '\033[32m')
		YELLOW=$(printf '\033[33m')
		RESET=$(printf '\033[m')
	else
        RED=""
		GREEN=""
		YELLOW=""
		RESET=""
	fi
}

function set_output_command(){
    set +e
    _=$(say -v Daniel '') 
    retval=$?
    if [[ $retval -eq 0 ]]; then 
        print_command='bash -c "echo ${GREEN} $1 ${RESET}; say -v Daniel $1"'
    else
        print_command='bash -c "echo ${GREEN} $1 ${RESET}"'
    fi
}

function print_step() {
    echo ""
    if [[ -z "$1" ]]; then
        echo "$1"
    else
        eval "$print_command '$*'"
        read -p "(Press enter key to continue...) " -r
    fi
    echo ""
}

function read_recipe_file(){
    file="$1"
    is_step=false
    while read -u 3 -r line; do
        if [[ "$line" != "## Steps" && "$line" =~ ^\#.* ]]; then
            is_step=false
        elif [[ "$line" == "## Steps" ]]; then
            is_step=true
            read -p "(Press enter when you are ready to continue...) " -r
            echo ""
        fi

        if [[ "$is_step" == "false" || -z "$line" || "$line" == "## Steps" ]]; then
            echo "${YELLOW} $line ${RESET}"
        else
            step_number=$((step_number+1))
            print_step "$(printf 'STEP %d %s' "$step_number" "$line")"
        fi
    done 3< "$file"  
}

setup_color
if [[ ! -e "$1" ]]; then
    echo ""
    echo "${RED} Recipe file $1 does not exists. Please check that path of the file.${RESET}"
    echo ""
    exit 1
fi

set_output_command
read_recipe_file "$1"