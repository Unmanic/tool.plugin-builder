#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
PROJECTS_DIR="${SCRIPT_DIR}/projects"

declare -A REPOS=(
    ["unmanic"]="https://github.com/Unmanic/unmanic.git"
    ["unmanic-frontend"]="https://github.com/Unmanic/unmanic-frontend.git"
    ["unmanic-plugins"]="https://github.com/Unmanic/unmanic-plugins.git"
    ["unmanic-documentation"]="https://github.com/Unmanic/unmanic-documentation.git"
)

declare -A BRANCHES=(
    ["unmanic"]="staging"
    ["unmanic-frontend"]="master"
    ["unmanic-plugins"]="official"
    ["unmanic-documentation"]="master"
)

mkdir -p \
    "${PROJECTS_DIR}" \
    "${BUILD_DIR}"

for repo in "${!REPOS[@]}"; do
    repo_dir="${PROJECTS_DIR}/${repo}"
    repo_url="${REPOS[${repo}]}"
    repo_branch="${BRANCHES[${repo}]}"

    if [[ -d "${repo_dir}/.git" ]]; then
        echo "Updating ${repo}..."
        git -C "${repo_dir}" fetch origin
        git -C "${repo_dir}" checkout -B "${repo_branch}" "origin/${repo_branch}"
        git -C "${repo_dir}" reset --hard "origin/${repo_branch}"
        git -C "${repo_dir}" clean -fd
    else
        echo "Cloning ${repo}..."
        git clone --branch "${repo_branch}" "${repo_url}" "${repo_dir}"
    fi
done
