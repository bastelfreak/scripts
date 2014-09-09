#!/bin/bash

# change centos repo baseurl to local ftp mirror
cat <<'EOF' >/etc/yum.repos.d/CentOS-Base.repo
[base]
name=CentOS-$releasever - Base
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os
#baseurl=http://mirror.centos.org/centos/$releasever/os/$basearch/
baseurl=ftp://user:password@mein-mirror/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates 
[updates]
name=CentOS-$releasever - Updates
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates
#baseurl=http://mirror.centos.org/centos/$releasever/updates/$basearch/
baseurl=ftp://user:password!@mein-mirror/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras
#baseurl=http://mirror.centos.org/centos/$releasever/extras/$basearch/
baseurl=ftp://use:password@mein-mirror/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus
#mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus
#baseurl=http://mirror.centos.org/centos/$releasever/centosplus/$basearch/
baseurl=ftp://user:password@mein-mirror/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF

# add EPEL repo
cat <<'EOF' >/etc/yum.repos.d/epel.repo
[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
baseurl=ftp://user:password@mein-mirror/epel/$releasever/$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=ftp://user:password@mein-mirror/epel/RPM-GPG-KEY-EPEL-7
EOF


# disable yum fastmirror to force using local ftp mirror
yum erase yum-fastestmirror.noarch

# add ceph reipo (release: firefly)
yum install http://ceph.com/rpm/el7/noarch/ceph-release-1-0.el7.centos.noarch.rpm
# disable requiretty in sudoers
chmod 660 /etc/sudoers
sed -i 's/^Defaults.*requiretty/#Defaults requiretty/g' /etc/sudoers
chmod 0440 /etc/sudoers

# add ceph user
useradd -d /home/ceph -p $(date | sha512sum |cut -c1-20) -m ceph
echo "ceph ALL = (root) NOPASSWD:ALL" > /etc/sudoers.d/ceph
chmod 0440 /etc/sudoers.d/ceph

# generate ssh-key for ceph user
mkdir -p /home/ceph/.ssh
touch /home/ceph/.ssh/authorized_keys
touch /home/ceph/.ssh/config
chown ceph:ceph -R /home/ceph
chmod 775 /home/ceph/.ssh
chmod 666 /home/ceph/.ssh/authorized_keys
chmod 666 /home/ceph/.ssh/config
su -c 'ssh-keygen -b 8192 -t rsa -N "" -f "/home/ceph/.ssh/id_rsa"' - ceph
cat <<'EOF' >/home/ceph/.ssh/config
host *
	Protocol 2

host ceph01
	hostname 10.0.0.196
	user ceph
	port 22

host ceph02
	hostname 10.0.0.197
	user ceph
	port 22

host ceph03
	hostname 10.0.0.198
	user ceph
	port 22
EOF
chown ceph:ceph -R /home/ceph
chmod 700 /home/ceph/.ssh
chmod 600 /home/ceph/.ssh/authorized_keys
chmod 600 /home/ceph/.ssh/config

# set hosts entries
cat <<'EOF' >>/etc/hosts
10.0.0.196	ceph01.seometrie.local	ceph01
10.0.0.197	ceph02.seometrie.local	ceph02
10.0.0.198	ceph03.seometrie.local	ceph03
EOF
