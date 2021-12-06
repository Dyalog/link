#!/bin/bash
# Link inject_version.sh
raw_version=`cat StartupSession/Link/Version.aplf | grep -o "^version\s\?←\s\?'[0-9]\+\.[0-9]\+\.0-\?\w\+\?" | grep -o "[0-9]\+\.[0-9]\+\.[0-9]\+-\?\w\+\?"`

major_minor=`echo ${raw_version} | grep -o "[0-9]\+\.[0-9]\+"`
special=`echo ${raw_version} | grep -o "\-\w\+$"`
patch=`git rev-list --count HEAD`
hash=`git rev-parse --short HEAD`
date=`git show -s --format=%ci | cut -c -10`
full_version=${major_minor}.${patch}${special}

echo ${full_version}

sed -i "s/^version\s\?←\s\?'[0-9]\+\.[0-9]\+\.[0-9]\+-\?\w\+\?/version←'${full_version}/" StartupSession/Link/Version.aplf

exit 0
