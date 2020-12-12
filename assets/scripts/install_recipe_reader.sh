#!/bin/bash

command_exists() {
	command -v "$@" >/dev/null 2>&1
}

rm -f recipe_reader.sh "$0"

command_exists curl && {
    curl -fsSL https://raw.githubusercontent.com/Ritesh-Yadav/Ritesh-Yadav.github.io/master/assets/scripts/recipe_reader.sh -o recipe_reader.sh
    curl -fsSL "https://raw.githubusercontent.com/Ritesh-Yadav/Ritesh-Yadav.github.io/master/_includes/recipes/$0" -o "$0"
    bash recipe_reader.sh "$0"
    exit 0
}

command_exists wget && {
    wget https://raw.githubusercontent.com/Ritesh-Yadav/Ritesh-Yadav.github.io/master/assets/scripts/recipe_reader.sh -o recipe_reader.sh
    wget "https://raw.githubusercontent.com/Ritesh-Yadav/Ritesh-Yadav.github.io/master/_includes/recipes/$0" -o "$0"
    bash recipe_reader.sh "$0"
    exit 0
}