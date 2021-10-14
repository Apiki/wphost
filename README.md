# wphost



## After update Dockerfile this is a example of how to handle deploy 
```sh

PREVIOUS_VERSION=7.4.21
VERSION=7.4.24
git commit -am  "update php from $PREVIOUS_VERSION to $VERSION"
git tag -a php-${VERSION} -m "update php from $PREVIOUS_VERSION to $VERSION"
git push origin php-${VERSION}
```
