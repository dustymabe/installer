#!/bin/sh

set -ex

# shellcheck disable=SC2068
version() { IFS="."; printf "%03d%03d%03d\\n" $@; unset IFS;}

minimum_go_version=1.10
current_go_version=$(go version | cut -d " " -f 3)

if [ "$(version "${current_go_version#go}")" -lt "$(version "$minimum_go_version")" ]; then
     echo "Go version should be greater or equal to $minimum_go_version"
     exit 1
fi

LAUNCH_PATH="${PWD}"
cd "$(dirname "$0")/.."

PACKAGE_PATH="$(go list -e -f '{{.Dir}}' github.com/openshift/installer)"
if test -z "${PACKAGE_PATH}"
then
	echo "build from your \${GOPATH} (${LAUNCH_PATH} is not in $(go env GOPATH))" 2>&1
	exit 1
fi

LOCAL_PATH="${PWD}"
if test "${PACKAGE_PATH}" != "${LOCAL_PATH}"
then
	echo "build from your \${GOPATH} (${PACKAGE_PATH}, not ${LAUNCH_PATH})" 2>&1
	exit 1
fi

MODE="${MODE:-release}"
LDFLAGS="${LDFLAGS} -X main.version=$(git describe --always --abbrev=40 --dirty)"
TAGS="${TAGS:-}"
OUTPUT="${OUTPUT:-bin/openshift-install}"
export CGO_ENABLED=0

case "${MODE}" in
release)
	TAGS="${TAGS} release"
	if test "${SKIP_GENERATION}" != y
	then
		if ! $(go list github.com/shurcooL/vfsgen &> /dev/null);
		then
			echo "cannot find github.com/shurcooL/vfsgen, needed by 'go generate ./data'"
			echo "maybe run 'go get github.com/shurcooL/vfsgen' and retry"
			exit 1
		fi
		go generate ./data
	fi
	;;
dev)
	;;
*)
	echo "unrecognized mode: ${MODE}" >&2
	exit 1
esac

if (echo "${TAGS}" | grep -q 'libvirt_destroy')
then
	export CGO_ENABLED=1
fi

go build -ldflags "${LDFLAGS}" -tags "${TAGS}" -o "${OUTPUT}" ./cmd/openshift-install
