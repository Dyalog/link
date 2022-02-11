#!/bin/bash
# Link inject_version.sh

set -e

# The default grep on AIX does not support the -o flag; so prepend /opt/freeware/bin to $PATH

case $(uname) in
        AIX)    PATH=/opt/freeware/bin:$PATH ;;
esac

# A local or jenkins builder will call this script from the root of the checked out git repo
# Another build mechanism might copy files to another directory before modifying them
if [ $# -eq 0 ];
# $D is root directory of files to be injected, assuming they have the same relative structure as the original repository
    then
        D=$PWD   # Assume we are in project root calling "./CI/inject_version.sh"
    else
        D=$1     # If argument given, that is new root dir of file to be injected. 
fi

REPO_DIR="$(dirname $0)/../"

VERSION_SOURCE="${D}/StartupSession/Link/Version.aplf"
INJECT_FILES="${D}/StartupSession/Link/Version.aplf"

FILES="$VERSION_SOURCE $INJECT_FILES"
MISSING=""

for FILE in $FILES
do
    if [ ! -f $FILE ]; then
        echo "File not found: $FILE";
        MISSING="$MISSING $FILE";
    fi
done

raw_version=`cat $VERSION_SOURCE | grep -o "^version\s\?←\s\?'[0-9]\+\.[0-9]\+\.[0-9]\+-\?\w\+\?" | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+-\?\w\+\?"`

major_minor=`echo ${raw_version} | grep -o "[0-9]\+\.[0-9]\+"`
special=""
if n=$(echo ${raw_version} | grep -wic "\-\w+$"); then
    special=`echo ${raw_version} | grep -o "\-\w\+$"`
fi
patch=`git -C $REPO_DIR rev-list --count HEAD`
hash=`git -C $REPO_DIR rev-parse --short HEAD`
date=`git -C $REPO_DIR show -s --format=%ci | cut -c -10`

full_version=${major_minor}.${patch}${special}

echo ${full_version}

sed -i "s/^version\s\?←\s\?'[0-9]\+\.[0-9]\+\.[0-9]\+-\?\w\+\?/version←'${full_version}/" ${D}/StartupSession/Link/Version.aplf

