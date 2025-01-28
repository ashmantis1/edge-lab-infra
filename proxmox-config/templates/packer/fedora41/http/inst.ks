#version=Rocky Linux 9
#documentation: https://docs.fedoraproject.org/en-US/fedora/f36/install-guide/appendixes/Kickstart_Syntax_Reference/

# PRE-INSTALLATION SCRIPT
%pre --interpreter=/usr/bin/bash --log=/root/anaconda-ks-pre.log
%end

# INSTALL USING TEXT MODE
text

# KEYBOARDS, LANGUAGES, TIMEZONE
keyboard --vckeymap=us --xlayouts=us
lang en_US.UTF-8
timezone Australia/Sydney --utc

# NETWORK, SELINUX, FIREWALL
# Hostname must be separate from link config, in either 'host' or 'host.domain.tld' form.
#network --hostname='host.domain.tld'
network --device=link --bootproto=dhcp --onboot=on --noipv6 --activate
selinux --enforcing
firewall --enabled --ssh

# DISKS, PARTITIONS, VOLUME GROUPS, LOGICAL VOLUMES
# Install target is usually sda, vda, or nvme0n1; adjust all references below accordingly.
# The EFI & /boot partitions are explicitly set here, but some people just use `reqpart`.
#ignoredisk --only-use=sda
zerombr
clearpart --all --initlabel
bootloader
##part /boot/efi --label=FIRMWARE --size=1024         --asprimary --fstype=efi
#part /boot     --label=BOOT     --size=1024         --asprimary --fstype=ext4
#part pv.01     --label=VOLUMES  --size=1024  --grow --asprimary
#volgroup volgroup0 pv.01
#logvol swap    --label=SWAP     --size=8192         --vgname=volgroup0 --name=swap
#logvol /       --label=ROOT     --size=1024  --grow --vgname=volgroup0 --name=root --fstype=xfs
autopart
# INSTALLATION SOURCE, EXTRA REPOSITOROIES, PACKAGE GROUPS, PACKAGES
url --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-41&arch=x86_64"
repo --name=fedora-updates --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f41&arch=x86_64" --cost=0
repo --name=fedora-cisco-openh264 --mirrorlist="https://mirrors.fedoraproject.org/mirrorlist?repo=fedora-cisco-openh264-41&arch=x86_64" --install
repo --name=rpmfusion-free --mirrorlist="https://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-41&arch=x86_64"
repo --name=rpmfusion-free-updates --mirrorlist="https://mirrors.rpmfusion.org/mirrorlist?repo=free-fedora-updates-released-41&arch=x86_64" --cost=0
repo --name=rpmfusion-nonfree --mirrorlist="https://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-41&arch=x86_64"
repo --name=rpmfusion-nonfree-updates --mirrorlist="https://mirrors.rpmfusion.org/mirrorlist?repo=nonfree-fedora-updates-released-41&arch=x86_64" --cost=0
# Extras repository is needed to install `epel-release` package.
# Remove `@guest-agents` group if this is not a VM.
%packages --retries=5 --timeout=20 --inst-langs=en
@guest-agents
kernel-devel
openssh-server
cloud-init
ansible
ipa-client
cloud-utils-growpart-0.33-9.fc41.noarch
%end

# GROUPS, USERS, ENABLE SSH, FINISH INSTALL
rootpw --lock
# Create user 'myuser' and group 'mygroup' (with GID 3000), make it myuser's primary group, and add myuser to administrative 'wheel' group.
user --name=cloud-user --plaintext --gecos='Cloud User' --groups='wheel,sudo' --gid=3000
sshkey --username=cloud-user 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF6leLiXjd46rW2/bKTyFtEBXv8A47Ti0kd49CcexgLy'
services --enabled='sshd.service'
reboot --eject

# ENABLE EMERGENCY KERNEL DUMPS FOR DEBUGGING
%addon com_redhat_kdump --reserve-mb=auto --enable
%end

# POST-INSTALLATION SCRIPT
%post --interpreter=/usr/bin/bash --log=/root/anaconda-ks-post.log --erroronfail
# Enable CodeReady Builder repo (requires `epel-release` package).
/usr/bin/dnf config-manager --set-enabled crb
# Install Ansible
/usr/bin/dnf install -y ansible
authselect enable-feature with-mkhomedir
systemctl enable --now oddjobd.service
install \
    -o root -g root -m400 \
    <(echo -e '%cloud-user\tALL=(ALL)\tNOPASSWD: ALL') \
    /etc/sudoers.d/freewheelers
%end
