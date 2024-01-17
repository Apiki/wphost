# wphost



## After update Dockerfile-8 this is a example of how to handle deploy on PHP
```sh

PREVIOUS_VERSION=8.2.3
VERSION=8.2.13
git commit -am  "update php from $PREVIOUS_VERSION to $VERSION"
git push origin master

docker buildx build --platform=linux/amd64,linux/arm64 --tag apiki/wphost:php-${VERSION} --push https://raw.githubusercontent.com/Apiki/wphost/master/php/Dockerfile-8
```