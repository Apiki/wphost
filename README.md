📦 Apiki Wphost Builder (Lightsail Setup)
Este repositório/documentação automatiza o processo de build multi-plataforma (amd64 + arm64) para imagens Docker do projeto apiki/wphost.

🚀 Requisitos
- Instância AWS Lightsail rodando Ubuntu 22.04 LTS
- Docker e Docker Buildx instalados
- Permissões de push para o repositório DockerHub (apiki/wphost)

⚙️ Configuração da máquina
Após conectar via SSH:

```bash
# Instale o Docker:
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
# Dê permissão ao seu usuário:
sudo usermod -aG docker $USER
newgrp docker
# Ative suporte a multi-plataforma (QEMU):
docker run --privileged --rm tonistiigi/binfmt --install all
# Crie um builder com o Buildx:
docker buildx create --use
```

🔐 Faça login no DockerHub
Antes de iniciar o build, autentique-se com sua conta DockerHub:

```bash
docker login
# Importante: É necessário fazer login para que o comando --push funcione corretamente e envie as imagens para o DockerHub.
```

📜 Script de Build
Crie um arquivo build.sh com o seguinte conteúdo:

```bash
#!/bin/bash

# Defina as variáveis de versão e serviço
PREVIOUS_VERSION=3.3.4
VERSION=4.13.0
SERVICE=waf

# Execute o comando build multi-plataforma e envie para o DockerHub
nohup docker buildx build \
    --platform=linux/amd64,linux/arm64 \
    --tag apiki/wphost:${SERVICE}-${VERSION} \
    --push \
    -f ${SERVICE}/Dockerfile . > build.log 2>&1 &

```

🖥️ Monitorando o Progresso
Para acompanhar o progresso do build, use o comando:

```bash
tail -f build.log
# Se você quiser verificar se o processo ainda está rodando, use:

ps aux | grep buildx
```

# Crie uma tag no Git para a versão
```
git tag -a ${SERVICE}-${VERSION} -m "Versão ${SERVICE} ${VERSION}"
git push origin ${SERVICE}-${VERSION}
```

✅ Resultado Esperado
A imagem apiki/wphost:waf-4.13.0 será construída para as plataformas amd64 e arm64.

A imagem será enviada automaticamente para o repositório DockerHub.
