FROM debian:stable-slim

ENV CS_BOUNCER_VERSION 0.0.17-rc5

RUN apt update -y && apt install -y wget gettext systemctl
RUN wget https://github.com/crowdsecurity/cs-custom-bouncer/releases/download/v${CS_BOUNCER_VERSION}/crowdsec-custom-bouncer.tgz && \
tar -xzf crowdsec-custom-bouncer.tgz && \
cd crowdsec-custom-bouncer-v*

RUN echo '#!/bin/bash' > /opt/crowdsec-custom.sh && chmod +x /opt/crowdsec-custom.sh
RUN cd /crowdsec-custom-bouncer-v* && echo /opt/crowdsec-custom.sh | ./install.sh --binary /opt/crowdsec-custom.sh

WORKDIR /etc/crowdsec/bouncers
CMD ["/usr/local/bin/crowdsec-custom-bouncer", "-c", "/etc/crowdsec/bouncers/crowdsec-custom-bouncer.yaml"]