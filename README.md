# wphost



## After update Dockerfile this is a example of how to handle deploy on PHP
```sh

PREVIOUS_VERSION=7.4.24
VERSION=7.4.26
git commit -am  "update php from $PREVIOUS_VERSION to $VERSION"
git tag -a php-${VERSION} -m "update php from $PREVIOUS_VERSION to $VERSION"
git push origin php-${VERSION}
```

## handle deploy on NGINX
```sh

PREVIOUS_VERSION=1.19.3.2
VERSION=1.19.9.1
git commit -am  "update nginx from $PREVIOUS_VERSION to $VERSION"
git tag -a nginx-${VERSION} -m "update nginx from $PREVIOUS_VERSION to $VERSION"
git push origin nginx-${VERSION}
```
