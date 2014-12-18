#!/bin/bash

##
# this is written by bluewind
##

set -e

newuser="flo"
disk=/dev/vda
server=192.168.123.1
pingcheckhost="mirror.server-speed.net"

die() {
  echo "$@"
  exit 1
}

get_url() {
  local url=$1
  local default=$2
  wget -q -O - "$url" || echo "$default"
}

cmdline_arg() {
  local name=$1
  local default=$2
  local param
  for param in $(< /proc/cmdline); do
    case "${param}" in
      $name=*) echo "${param##*=}" ; return 0 ;;
    esac
  done

  echo $default
}

grep -qE '^flags\s+: .* hypervisor( |$)' /proc/cpuinfo || die "Not running in hypervisor. aborting automatic setup"

# wait for host to be reachable (including dns query)
while ! ping -c1 -W0.3 "$pingcheckhost" >/dev/null; do
  sleep 0.2
done

parted -s -- $disk mklabel msdos mkpart primary 1 -0

mkfs.ext4 ${disk}1
mount ${disk}1 /mnt
cat <<EOF >/etc/pacman.d/mirrorlist
Server = http://mirror.server-speed.net/\$repo/os/\$arch
EOF

pacstrap /mnt base syslinux sudo openssh haveged htop git zsh screen dnsutils vim net-tools
genfstab -p /mnt >> /mnt/etc/fstab

mymac=$(ip addr show dev eth0 | sed -rn 's#^\s+link/ether ([0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}).*$#\1#p')

get_url "http://$server/hostnames/$mymac" "archvm" > /mnt/etc/hostname
hostname=$(cat /mnt/etc/hostname)

cat << EOF >/mnt/etc/systemd/network/10-static-ethernet.network
[Match]
Name=e*

[Network]
$(get_url "http://$server/network/$hostname")
EOF

ln -s /usr/share/zoneinfo/Europe/Vienna /mnt/etc/localtime
echo "en_US.UTF-8 UTF-8" > /mnt/etc/locale.gen
arch-chroot /mnt locale-gen

echo "LANG=en_US.UTF-8" > /mnt/etc/locale.conf
cat <<EOF > /mnt/etc/vconsole.conf
KEYMAP=de
FONT=
EOF

cat <<EOF >/mnt/boot/syslinux/syslinux.cfg
serial 0 115200
DEFAULT arch
PROMPT 0
TIMEOUT 30
UI menu.c32

LABEL arch
  MENU LABEL Arch Linux
  LINUX ../vmlinuz-linux
  APPEND root=${disk}1 rw logo.nologo elevator=deadline nomodeset
  INITRD ../initramfs-linux.img
EOF

cat <<EOF >/mnt/etc/ssh/sshd_config
Port 22
Protocol 2
PermitRootLogin yes
PubkeyAuthentication yes
AuthorizedKeysFile      .ssh/authorized_keys
PasswordAuthentication no
ChallengeResponseAuthentication no
UsePAM yes
GatewayPorts clientspecified
PrintMotd no # pam does that
UsePrivilegeSeparation sandbox          # Default for new installations.
Ciphers aes256-ctr,aes192-ctr,aes128-ctr
Subsystem       sftp    internal-sftp
Match Group "ssh-password"
        PasswordAuthentication yes
EOF

arch-chroot /mnt mkinitcpio -p linux
arch-chroot /mnt syslinux-install_update -aim
arch-chroot /mnt useradd -m -g users -G wheel $newuser
mkdir /mnt/root/.ssh
touch /mnt/root/.ssh/authorized_keys
chmod 700 /mnt/root/.ssh
chmod 600 /mnt/root/.ssh/authorized_keys
cat <<EOF > /mnt/root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAte43fgKVPKvmwhMQcQRYNm27i2cadOIJvpOFA3jPWHFN2YeqxHvgVbAESLOAO/sJ0MqXlQnBc9rr8PbQd67YP7teOBnXLOfX2mofxGEDtP2mtwneAxkMNJcYtxWjPeKL7LF5tknqPb6dXavm4+gJt27CQFFY6DJ+cD0tUUgh17HG6VGiTXF6AgB9aho/ToaMQZ4vCzztvf94kQK2uBYUXsvx4L62ZrEJbIzfB7fynBbl9+deBqsYmWRCbzaYV77YjwLhk9hI/GsUjLkTAB77WbeWJdk7fgJ/PgI69FRMhRlYASRVBqeek6NLcyQ9x54CrUkOFBC5Q+j4yjsDQN7NBw== flo@Marin
EOF

mkdir /mnt/home/$newuser/.ssh
chmod 700 /mnt/home/$newuser/.ssh
cp /mnt/root/.ssh/authorized_keys /mnt/home/$newuser/.ssh/authorized_keys
chmod 600 /mnt/home/$newuser/.ssh/authorized_keys
arch-chroot /mnt chown -R $newuser:users /home/$newuser/.ssh
arch-chroot /mnt passwd -d $newuser

curl https://git.server-speed.net/users/flo/bin/plain/init_new_user.sh | arch-chroot /mnt sudo -u $newuser bash
arch-chroot /mnt chsh -s /bin/zsh $newuser

arch-chroot /mnt systemctl enable multi-user.target sshd haveged systemd-networkd systemd-resolved
ln -sf /run/systemd/resolve/resolv.conf /mnt/etc/resolv.conf

sync
systemctl reboot
