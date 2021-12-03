#!/bin/bash
# set -e

WORKSPACE=${WORKSPACE-$PWD}
cd ${WORKSPACE}

REPO_URL=`git ls-remote --get-url origin`
REPO=`echo $REPO_URL | grep -o "github.com:\?/\?\w\+/\w\+" | cut -c 12-`
ORG=`echo $REPO | grep -o "\w\+/" | rev | cut -c 2- | rev`
LENGTH=`echo $ORG | awk '{print length}'`
PROJECT=`echo $REPO | cut -c $((2+${LENGTH}))-`

echo $REPO_URL
echo $GIT_USER
echo $REPO
echo $LENGTH
echo $PROJECT

echo "Running from ${REPO_URL}"

GIT_BRANCH=${JOB_NAME#*/*/}
MAIN_BRANCH=`git remote show $REPO_URL | grep "HEAD branch" | sed "s/  HEAD branch: //"`
GIT_COMMIT=`git rev-parse HEAD`

DELETE_DRAFTS=0   # If it is not the main branch, do not delete previous draft releases

# Compare git branch
case $GIT_BRANCH in
	PR*)
		echo skipping creating draft release for pull request
		exit 0
	;;
	$MAIN_BRANCH)   # Add support branches explicitly to case list e.g. $MAIN_BRANCH|3.2-SUPPORT)
		echo "Creating ${GIT_BRANCH} release"
		if [ $GIT_BRANCH = $MAIN_BRANCH ]; then
			DELETE_DRAFTS=1
		fi
	;;
	**)
		echo "skipping creating release for ${GIT_BRANCH}"
esac

# --- Create JSON release notes ---
TMP_JSON=/tmp/GH-Publish.${PROJECT}.$$.json
GH_RELEASES=/tmp/GH-Releases.${PROJECT}.$$.json

# --- Inject full version number, has side effects in copied source ---

VERSION=`./CI/inject_version.sh`   # inject_version.sh returns full patch version number
VERSION_AB=`echo $VERSION | grep -o "[0-9]\+\.[0-9]\+"`
echo "Creating draft release for ${VERSION}"

# VERSION_ND: No decimals e.g. 3.5.10 → 3510
# VERSION_AB: major.minor e.g. 3.5.10 → 3.5

if ! [ "$GHTOKEN" ]; then
  echo 'Please put your GitHub API Token in an environment variable named GHTOKEN'
  exit 1
fi

# Delete all the old draft releases, otherwise this gets filled up pretty fast as we create for every commit:
# but only if jq is available
if which jq >/dev/null 2>&1 && [ 1 = $DELETE_DRAFTS ]; then
	DRAFT=true
	C=0
	# Get the json from Github API
	curl -o $GH_RELEASES \
	--silent -H "Authorization: token $GHTOKEN" \
	https://api.github.com/repos/${REPO}/releases

	echo $GH_RELEASES

	RELEASE_COUNT=`cat $GH_RELEASES | jq ". | length"`
	echo "Release Count: ${RELEASE_COUNT}"

	GH_VERSION_ND_LAST=0
	while [ $C -le $RELEASE_COUNT ] ; do
		DRAFT=`cat $GH_RELEASES | jq -r ".[$C].draft"`
		ID=`cat $GH_RELEASES | jq -r ".[$C].id"`
		GH_VERSION=$(cat $GH_RELEASES | jq -r ".[$C].name" | sed 's/^v//' | sed 's/-.*//')
		GH_VERSION_ND=$(cat $GH_RELEASES | jq -r ".[$C].name" | sed 's/^v//;s/\.//g' | sed 's/-.*//')
		GH_VERSION_AB=${GH_VERSION%.*}
		if [ "${GH_VERSION_AB}" = "${VERSION_AB}" ] ; then
		# If same minor version and there is an unpublished draft release of a previous patch, delete that draft
			if [ "$DRAFT" = "true" ]; then
				echo -e -n "*** $(cat $GH_RELEASES | jq -r ".[$C].name") with id: $(cat $GH_RELEASES | jq -r ".[$C].id") is a draft - Deleting.\n"
				curl -X "DELETE" -H "Authorization: token $GHTOKEN" https://api.github.com/repos/${REPO}/releases/${ID}
			else
				if [ $GH_VERSION_ND -gt $GH_VERSION_ND_LAST ]; then
					echo getting sha for latest release
					COMMIT_SHA=`cat $GH_RELEASES | jq -r ".[$C].target_commitish"`
					GH_VERSION_ND_LAST=$GH_VERSION_ND
					#PRERELEASE=`cat $GH_RELEASES | jq -r ".[$C].prerelease"`
				fi
			fi
		fi

		let C=$C+1
	done
	rm -f $GH_RELEASES

else
	echo not removing draft releases
fi


echo "SHA: ${COMMIT_SHA}"

if [ $GH_VERSION_ND_LAST = 0 ]; then   # New minor or major version
	echo "No releases of ${VERSION_AB} found, not populating changelog"
	JSON_BODY=$( ( echo -e "Pre-Release of $PROJECT $VERSION_AB\n\nWARNING: This is a pre-release version of $PROJECT $VERSION_AB: it is possible that functionality may be added, removed or altered; we do not recommend using pre-release versions of $PROJECT in production environment." | python -c 'import json,sys; print(json.dumps(sys.stdin.read()))' ) )
	PRELEASE=true
else                                     # New patch version
	echo using log from $COMMIT_SHA from $GH_VERSION_ND_LAST
	echo "Is Pre-Release: ${PRERELEASE}"
	if [ "{$PRERELEASE}" = "false" ]; then
		MSG_TEXT="Release ${PROJECT} ${VERSION_AB}\n\n"
	else
		MSG_TEXT="Pre-Release of $PROJECT ${VERSION_AB}\n\nWARNING: This is a pre-release version of RIDE ${VERSION_AB}: it is possible that functionality may be added, removed or altered; we do not recommend using pre-release versions of $PROJECT in production environments.\n\n"
	fi
	JSON_BODY=$( ( echo -e "${MSG_TEXT}Changelog:"; git log --format='%s' ${COMMIT_SHA}.. ) | grep -v -i todo | python -c 'import json,sys; print(json.dumps(sys.stdin.read()))')
fi

cat >$TMP_JSON <<.
{
  "tag_name": "v$VERSION",
  "target_commitish": "${GIT_COMMIT}",
  "name": "v$VERSION",
  "body": $JSON_BODY,
  "draft": true,
  "prerelease": true
}
.

cat $TMP_JSON

TMP_RESPONSE=/tmp/GH-Response.${PROJECT}.$$.json
curl -o $TMP_RESPONSE --data @$TMP_JSON -H "Authorization: token $GHTOKEN" -i https://api.github.com/repos/$REPO/releases

RELEASE_ID=`grep '"id"' $TMP_RESPONSE | head -1 | sed 's/.*: //;s/,//'`

zip ./Link-${VERSION}.zip -r SALT StartupSession

echo "Created release with id: $RELEASE_ID"

F=${PROJECT}-${VERSION}.zip
echo "Uploading $F to GitHub"
url=https://uploads.github.com/repos/$REPO/releases/$RELEASE_ID/assets?name=$F
echo $url
curl -i /dev/null -H "Authorization: token $GHTOKEN" \
	-H 'Accept: application/vnd.github.manifold-preview' \
	-H 'Content-Type: text/json' \
	--data-binary @"./$F" \
	url
rm -f $TMP_RESPONSE $TMP_JSON
