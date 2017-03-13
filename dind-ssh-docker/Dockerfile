FROM jpetazzo/dind

# Derived from https://github.com/krlmlr/debian-ssh

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get -y install openssh-server \
 && mkdir -p /var/run/sshd \
 && sed -i "s/UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g" /etc/ssh/sshd_config \
 && sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
 && touch /root/.Xauthority \
 && rm -rf /var/cache/apt

COPY run.sh /local/

ENTRYPOINT [ "/bin/bash", "/local/run.sh" ]
