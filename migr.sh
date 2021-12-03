#/bin/bash

set -e

SOURCE_SERVER=$1

if [ '$1' == "" ]; then
    echo "Usage: $0 source_server";
    exit 1;
fi; 

ping -c 1 $SOURCE_SERVER

RSYNC_PARAMS="-aAHXviWD"

echo -e 'n\np\n1\n2048\n\nw' | fdisk /dev/sda
mkfs.ext4 /dev/sda1

mkdir /mnt/target
mount /dev/sda1 /mnt/target

# first sync
rsync -e 'ssh -c aes128-cbc' "$RSYNC_PARAMS" root@$SOURCE_SERVER:/ /mnt/target/ --exclude={/sys,/dev,/proc}

for i in proc sys dev; do
    mkdir /mnt/target/$i
    mount --rbind /$i /mnt/target/$i
done;

cp default_grub /mnt/target/etc/default/grub

uuid=$(blkid /dev/sda1 | awk '{print $2}')
mv /mnt/target/etc/{fstab,fstab.old}
echo "$uuid / ext4 defaults 0 1" > /mnt/target/etc/fstab

rm -f /mnt/target/etc/mdadm.conf

chroot /mnt/target/ yum remove -y lvm2 mdadm kernel
chroot /mnt/target/ yum install -y kernel
chroot /mnt/target/ grub2-install /dev/sda
chroot /mnt/target/ grub2-mkconfig -o /boot/grub2/grub.cfg

dirs=$(find /mnt/target -maxdepth 1 -mindepth 1 -type d | sed 's#/mnt/target/##g' | egrep -v '^(dev|proc|sys|etc|usr|boot)$')

for d in $dirs; do
    if [ "$d" == "var" ]; then
      X="--exclude=/lib/yum --exclude=/lib/rpm --exclude=/cache/yum"
    fi;
    rsync -e 'ssh -c aes128-cbc' "$RSYNC_PARAMS" root@$SOURCE_SERVER:/$d/ /mnt/target/$d/ $X
done;

stop_services="cron crond nginx apache2 httpd redis mongodb mysql postgresql supervisord elasticsearch logstash kibana exim4 postfix"

for svc in $stop_services; do
    ssh root@$SOURCE_SERVER "service $svc stop || true"
done;

for d in $dirs; do
    if [ "$d" == "var" ]; then
      X="--exclude=/lib/yum --exclude=/lib/rpm --exclude=/cache/yum"
    fi;
    rsync -e 'ssh -c aes128-cbc' "$RSYNC_PARAMS" root@$SOURCE_SERVER:/$d/ /mnt/target/$d/ $X
done;

# ssh root@$SOURCE_SERVER "shutdown -h now"
# shutdown -r now

echo "prepare done; shutdown old server and reboot this virtual"

