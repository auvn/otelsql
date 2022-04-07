#!/usr/bin/env bash

set -Eeuo pipefail

NO_COLOR="\033[0m"
ERROR_COLOR="\033[31;01m"

function lastVersion() {
    git tag --sort=committerdate | tail -1 | tr -d 'v'
}

function toInt() {
    echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'
}

function setVersion() {
    local version=$1

    if [[ -z "$version" ]]; then
        echo -e "${ERROR_COLOR}No version specified${NO_COLOR}"
        exit 1
    fi

    if [[  ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "${ERROR_COLOR}Invalid version '${version}'${NO_COLOR}"
        exit 1
    fi

    # shellcheck disable=SC2155
    local last=$(lastVersion)

    if [[ -z "$last" ]]; then
        echo -e "${ERROR_COLOR}Could not get last version${NO_COLOR}"
        exit 1
    fi

    # Compare version and last version.
    if [[ $(toInt "$version") -le $(toInt "$last") ]]; then
        echo -e "${ERROR_COLOR}Version '${version}' is not greater than last version '${last}'${NO_COLOR}"
        exit 1
    fi

    echo "Last version: '${last}'"
    echo "New version '${version}'"

    # Update version in go file.
    cat <<EOF > version.go
package otelsql

// Version is the current release version of the otelsql instrumentation.
func Version() string {
	return "$version"
}

// SemVersion is the semantic version to be supplied to tracer/meter creation.
func SemVersion() string {
	return "semver:" + Version()
}
EOF

    # Send version to the next job.
    echo "VERSION=v${version}" >> "$GITHUB_ENV"
}

setVersion "$@"
