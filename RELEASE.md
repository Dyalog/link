# Making Link releases

Link releases are handled via a [GitHub Action](https://docs.github.com/en/actions); see `.github/workflows/make-link-release.yml` for the details. It will create a new release upon detecting a new tag beginning with the letter "v". For example, if you want to create a new release `v4.0.18`, do the following:
```
git tag v4.0.18
git push origin v4.0.18
```
and the release should get baked. A release will contain two assets, one for Dyalog version `18.2`, and one for version `19` and later.

Note that the action does NOT validate the release sequence in any way. It is up to the person making the release to compose the tag appropriately.
