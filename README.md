# wphost

## Handling deploys
```sh

#Launch lightsail
https://lightsail.aws.amazon.com/ls/webapp/home/instances

#install docker
https://docs.docker.com/engine/install/ubuntu/

#prepare machine
docker buildx create --use --platform=linux/arm64,linux/amd64 --name multi-platform-builder
docker buildx inspect --bootstrap

#clone and edit as you need
https://github.com/Apiki/wphost

PREVIOUS_VERSION=1.21.4.2
VERSION=1.25.3.1-2
SERVICE=nginx
git commit -am  "update $SERVICE from $PREVIOUS_VERSION to $VERSION"
git push origin master

#log on docker to push the image
docker login
#build
docker buildx build --platform=linux/amd64,linux/arm64 --tag apiki/wphost:${SERVICE}-${VERSION} --push -f /home/ubuntu/wphost/${SERVICE}/all/Dockerfile .
```