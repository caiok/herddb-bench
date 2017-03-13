#!/bin/bash

if [ -z "${SSH_KEY}" ]; then
	echo "=> Please pass your public key in the SSH_KEY environment variable"
	exit 1
fi

for MYHOME in /root ; do
	echo "=> Adding SSH key to ${MYHOME}"
	mkdir -p ${MYHOME}/.ssh
	chmod go-rwx ${MYHOME}/.ssh
	echo "${SSH_KEY}" > ${MYHOME}/.ssh/authorized_keys
	chmod go-rw ${MYHOME}/.ssh/authorized_keys
	echo "=> Done!"
done

#mkdir /var/lib/docker
#mkdir /var/lib/docker-var
#mount -t aufs -o br:/var/lib/docker-var:/var/lib/docker-ro=ro none /var/lib/docker

wrapdocker &
sleep 2
exec /usr/sbin/sshd -D
