#!/bin/bash

print_command=''

function set_output_command(){
    set +e
    _=$(say -v Daniel --progress '') 
    retval=$?
    if [[ $retval -eq 0 ]]; then 
        echo "$@"
        print_command='bash -c "echo $1; say -v Daniel $1"'
    else
        print_command='echo '
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
            echo "$line"
        else
            step_number=$((step_number+1))
            print_step "$(printf 'STEP %d %s' "$step_number" "$line")"
        fi
    done 3< "$file"  
}

set_output_command
read_recipe_file "$1"