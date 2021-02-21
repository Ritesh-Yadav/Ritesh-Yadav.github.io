---
title:  "Bash Tips, Tricks and Resources"
comments: true
categories: 
  - Tech
tags:
  - bash
  - tricks
---

A curated list of tips, tricks and resources.

{% include base_path %}

{% include toc title="Index" %}

## Tips and Tricks

### Get arguments in bash alias

Alias to search for a abbreviation in wikipedia:

```bash
alias wga="bash -c '\
 curl -s https://en.wikipedia.org/wiki/List_of_abbreviations_in_oil_and_gas_exploration_and_production \
 | egrep -o \">\$0 .*<\" ' "
```

Sets story number in your .gitmessage file, so that you don't have to do it every time you commit

```bash
alias start_story='bash -c '\''printf "%s" "$0"\
 > $(git rev-parse --show-toplevel)/.git/.gitmessage'\' 
```

### Download a single file from a repo

Using ssh:

```bash
git archive --remote=ssh://git@code.atwork.com/my/my-scripts-repo.git HEAD tool.sh | tar –xv 
```

Using https, go to raw file view and get the url of the file to download:

```bash
wget -O- https://raw.githubusercontent.com/Ritesh-Yadav/Ritesh-Yadav.github.io/master/assets/scripts/install_recipe_reader.sh
```

### Pull all git repositories

Following command pull down all the repository available in a folder:

```bash
ls -R -d */.git \
| sed 's/\/.git//' \
| xargs -I% sh -c 'echo  \"\033[0;32m-- Project: % --\033[0m\"; git -C % pull -r --autostash --all'
```

### Static analysis of shell scripts

Use [shellcheck](https://github.com/koalaman/shellcheck) to perform static analysis of your shell scripts. This can be integrated in lots of IDEs as well.

### Testing bash scripts

[BATS](https://github.com/bats-core/bats-core) is a good testing framework if you are looking for writing tests for your bash scripts or even trying to test things using bash.

## Resources

* **Cheatsheet:** [https://devhints.io/bash](https://devhints.io/bash) [[PDF](/assets/docs/bash/DevHints.io.pdf)]
* **Google Styleguide:** [https://google.github.io/styleguide/shellguide.html](https://google.github.io/styleguide/shellguide.html) [[PDF](/assets/docs/bash/GoogleStyleGuide.pdf)]
* **Static Analysis:** [https://github.com/koalaman/shellcheck](https://github.com/koalaman/shellcheck)
* **Pure Bash Bible:** [https://github.com/dylanaraps/pure-bash-bible](https://github.com/dylanaraps/pure-bash-bible) [[FORK](https://github.com/Ritesh-Yadav/pure-bash-bible)]
* **Bash Automated Testing System:** [https://github.com/bats-core/bats-core](https://github.com/bats-core/bats-core)
