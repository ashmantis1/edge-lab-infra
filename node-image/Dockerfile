FROM quay.io/fedora/fedora-bootc:40

ARG K8S_VERSION=1.30.2
ENV K8S_VERSION=$K8S_VERSION
COPY ./files/kubernetes.repo /etc/yum.repos.d/kubernetes.repo
COPY ./files/cri-o.repo /etc/yum.repos.d/cri-o.repo
COPY ./files/kubernetes.conf /etc/sysctl.d/kubernetes.conf
COPY ./files/growroot /usr/libexec/growroot
COPY ./files/growroot.service /etc/systemd/system/growroot.service

VOLUME /var/lib/containers
RUN dnf install -y conntrack container-selinux ebtables ethtool iptables socat && \ 
		dnf install -y cri-o kubelet-$K8S_VERSION kubeadm-$K8S_VERSION kubectl-$K8S_VERSION --disableexcludes=kubernetes && \ 
		dnf install -y cloud-init nfs-utils && \
		# Longhorn Deps
		dnf --setopt=tsflags=noscripts install -y  iscsi-initiator-utils && \
		echo "InitiatorName=$(/sbin/iscsi-iname)" > /etc/iscsi/initiatorname.iscsi && \
		# Systemd Units
		systemctl enable iscsid && \
		systemctl enable growroot.service && \
		systemctl enable crio.service && \
		systemctl enable kubelet.service && \
		# Persistence
		mkdir -p /var/libexec/kubernetes && \ 
		ln -rs /var/libexec/kubernetes /usr/libexec/kubernetes && \
		mkdir -p /var/opt && \
		rm -rf /opt && \
		ln -rs /var/opt /opt 
		    
