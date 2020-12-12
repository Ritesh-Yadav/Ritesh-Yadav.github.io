#!/bin/bash

command_exists() {
	command -v "$@" >/dev/null 2>&1
}

command_exists curls && {
    curl -fsSL https://raw.githubusercontent.com/Ritesh-Yadav/Ritesh-Yadav.github.io/master/assets/scripts/recipe_reader.sh -O
    curl -fsSL "https://raw.githubusercontent.com/Ritesh-Yadav/Ritesh-Yadav.github.io/master/_includes/recipes/$1" -O
    bash recipe_reader.sh "$1"
    exit 0
}

command_exists wget && {
    wget -O- https://raw.githubusercontent.com/Ritesh-Yadav/Ritesh-Yadav.github.io/master/assets/scripts/recipe_reader.sh
    wget -O- "https://raw.githubusercontent.com/Ritesh-Yadav/Ritesh-Yadav.github.io/master/_includes/recipes/$1"
    bash recipe_reader.sh "$1"
    exit 0
}