#!/bin/bash
set -eu
MAX_VERSION_DIFF=${1:-3}

# space seperated list of packages
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
    echo 1
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

function check_oudated_package_versions(){
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
      check_oudated_package_versions "$package"
    fi
done <<< "$ONLY_PACKAGES"

echo "Total outdated package: $OUTDATED_PACKAGES_COUNT"
exit "$OUTDATED_PACKAGES_COUNT"
