---
title:  "Use NPM outdated to get outdated package versions"
comments: true
categories: 
  - Tech
tags:
  - bash
  - tricks
  - awk
  - npm
---

A custom script built top on NPM outdated which can ignore package and version difference.

{% include base_path %}

{% include toc title="Index" %}

## Problem Statement

NPM outdated is a good command to get the packages which are outdated. However, it's doesn't support the functionality, I wanted.
For example, if you want to ignore certain packages for upgrade or if you want to consider upgrade only after few version difference.

## Solution

Script mentioned below can ignore certain packages for upgrade and also support version difference which you want to set. However, this script doesn't support patch versions but it can be modified to support that as well if needed.

<!-- script is in assets/scripts/npm_outdated.sh -->
```bash
#!/bin/bash
set -eu
MAX_VERSION_DIFF=${1:-3}

# space separated list of packages
readonly IGNORE_PACKAGES=( @types/node @aws )
OUTDATED_PACKAGES_COUNT=0

function get_version_diff_based_on_semantic_versioning(){
  latest=$1; current=$2; precision=$3
  current_precision=$(get_semantic_versioning_precision "$current")
  if [[ $current_precision -ne $precision ]]; then
    current=$(awk -v before_decimal="${current/.*/}" -v after_decimal="${current/*./}" -v precision="$precision" 'BEGIN { printf "%." precision "f", before_decimal + (after_decimal/10^precision)}')
  fi
  awk -v latest="$latest" -v current="$current" -v precision="$precision" 'BEGIN { printf "%." precision "f", latest - current}'
}

function get_max_version_diff_based_on_semantic_versioning_precision(){
  precision=$1
  awk -v max_version_diff="$MAX_VERSION_DIFF" -v precision="$precision" 'BEGIN { printf "%." precision "f", max_version_diff/10^precision}'
}

function is_update_required_for_package(){
  max_version_diff=$1; version_diff=$2; latest=$3; current=$4;
  major_latest_version="${latest/.*/}"
  major_current_version="${current/.*/}"
  if [[ $major_latest_version -gt $major_current_version ]]; then
    echo "1"
  else
    update_flag=$(awk -v max_version_diff="$max_version_diff" -v version_diff="$version_diff" 'BEGIN { printf "%s", max_version_diff < version_diff}')
    echo "$update_flag"
  fi
}

function get_semantic_versioning_precision(){
  version=$1
  # get precision used by semantic versioning e.g. 4.50.1 will give precision 2 and 4.5.1 will give precision 1
  digits_after_decimal=${version/*./}
  echo "${#digits_after_decimal}"
}

function check_outdated_package_versions(){
  package=$1
  current_version=$(echo "$package" | awk '{print $2}' | grep -o -E "[0-9]+.[0-9]+")
  latest_version=$(echo "$package" | awk '{print $4}' | grep -o -E "[0-9]+.[0-9]+")
  precision=$(get_semantic_versioning_precision "$latest_version")

  version_diff=$(get_version_diff_based_on_semantic_versioning "$latest_version" "$current_version" "$precision")
  max_version_diff=$(get_max_version_diff_based_on_semantic_versioning_precision "$precision")
  need_to_update_package=$(is_update_required_for_package "$max_version_diff" "$version_diff" "$latest_version" "$current_version")

  if [ "$need_to_update_package" -eq 1 ]; then
    ((OUTDATED_PACKAGES_COUNT=OUTDATED_PACKAGES_COUNT+1))
    printf '%b\n' "$package"
  fi
}

###############################################################

OUTDATED_PACKAGES="$(npm -s --verbose outdated | awk '$4 !~ "beta|rc|git"')"

printf '%b\n' "$(echo "$OUTDATED_PACKAGES" | head -n 1)"
ONLY_PACKAGES=$(echo "$OUTDATED_PACKAGES" | tail -n +2)
ignore_packages=$(printf "|%s" "${IGNORE_PACKAGES[@]}")

while read -r package; do
    package_name=$(echo "$package" | awk '{print $1}')
    if [[ ! "${package_name}" =~ ^(${ignore_packages:1}) ]]; then
      check_outdated_package_versions "$package"
    fi
done <<< "$ONLY_PACKAGES"

echo "Total outdated package: $OUTDATED_PACKAGES_COUNT"
exit "$OUTDATED_PACKAGES_COUNT"
```

**Pro Tip:** If your operating system supports `bc` command then `awk` command used for calculation can be replaced with `bc`
{: .notice--info}

**Note:** GNU `awk` is used in this script. Script might not work in OSX so `awk` can be replaced with `gawk`. You might have to install `gawk`.
{: .notice--warning}

### Example

```bash
# npm outdated
Package      Current   Wanted     Latest   Location
glob          5.0.15   5.0.15     6.0.1    project
nothingness    0.0.3      git       git    project
anythigness   2.43.0   2.43.0    2.50.0    project
anotherpack  3.287.0  3.287.0   3.293.0    project
otherpack20    5.0.0    5.0.0     5.5.0    project
anythigness   2.43.0   2.43.0    3.42.0    project
once           1.3.2    1.3.3     1.3.3    project
grab           4.5.0    4.5.0     5.0.0    project
twice          1.9.2    1.9.3    1.15.3    project
@types/node   10.9.2   10.9.2   12.10.3    project
@aws/node     10.9.2   10.9.2   12.10.3    project
@types/next   10.9.2   10.9.2   12.10.3    project
@aws/next     10.9.2   10.9.2   12.10.3    project

# ./npm_outdated.sh 5
Package      Current   Wanted     Latest   Location
glob          5.0.15   5.0.15     6.0.1    project
anythigness   2.43.0   2.43.0    2.50.0    project
anotherpack  3.287.0  3.287.0   3.293.0    project
anythigness   2.43.0   2.43.0    3.42.0    project
grab           4.5.0    4.5.0     5.0.0    project
twice          1.9.2    1.9.3    1.15.3    project
@types/next   10.9.2   10.9.2   12.10.3    project
Total outdated package: 7
```

### Explanation

- `MAX_VERSION_DIFF=${1:-3}` script takes one optional argument for minor version difference. By default, it allows 3 minor version difference.
  - `./npm-outdated.sh 5` will allow 5 minor version difference. e.g. if the current used version is 4.5.0 and latest available is 4.11.0 then the difference would be calculated as 6 version difference. However, it will always complain about major version difference.  
- `readonly IGNORE_PACKAGES=( @types/node @aws )` has list of packages to ignore for outdated. More packages can be added in that list if you do not want to upgrade those for any reason. e.g. `readonly IGNORE_PACKAGES=( @types/node @aws/node )`. Names are used as regular expression which means package name should start from whatever you mentioned in the list.

## Finally

You can use this script in your CI to make the build fail if the packages are outdated.

Let me know in comment section if you have used any other tool or have any better option.
