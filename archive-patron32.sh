#!/bin/bash

MOUNT=/mnt
PREFIX=/sbin
VG=vgpatron64
#nom_machine=patron64
nom_machine=patron32
#LV=lvpat64squeeze
LV=lvpatron32sq
LVSNAPNAME=lv32snapsyst
LSNAPSIZE=2G

rewrited_name=$(echo $nom_machine | sed 's/\(-\)/\1\1/g')
rewritedsnap_name=$(echo $LVSNAPNAME |  sed 's/\(-\)/\1\1/g')
#/usr/sbin/xm pause $nom_machine

#Creation du snapshot
$PREFIX/lvcreate -s -L $LSNAPSIZE -n $LVSNAPNAME /dev/$VG/$LV && sleep 5
if [ $? -eq 0 ] ; then 
    #decouverte des VG de la machine
    $PREFIX/kpartx -a /dev/mapper/$VG-$rewritedsnap_name
    $PREFIX/vgchange -a y $nom_machine 2>&1 1> /dev/null
    #Montage des FS du snapshot du disque systeme de la machine
    [ ! -d "$MOUNT/$nom_machine" ] && mkdir $MOUNT/$nom_machine
    /bin/mount /dev/mapper/$nom_machine-root $MOUNT/$nom_machine
    echo $rewritedsnap_name | grep -q "^.*[0-9]$"
    #si le nom du snapshot se termine par un chiffre alors rajouter p1
    if [ $? -eq 0 ] ; then
        /bin/mount /dev/mapper/$VG-"$rewritedsnap_name"p1 $MOUNT/$nom_machine/boot
    #sinon rajouter juste "1"
    else
        /bin/mount /dev/mapper/$VG-"$rewritedsnap_name"1 $MOUNT/$nom_machine/boot
    fi
    /bin/mount /dev/mapper/$nom_machine-var $MOUNT/$nom_machine/var
    /bin/mount /dev/mapper/$nom_machine-usr $MOUNT/$nom_machine/usr
    /bin/mount /dev/mapper/$nom_machine-tmp $MOUNT/$nom_machine/tmp
    /bin/mount /dev/mapper/$nom_machine-home $MOUNT/$nom_machine/home
    /bin/tar cfz /usr/local/share/${nom_machine}.tar.gz --exclude "proc/*" --exclude "sys/*" --exclude "tmp/*" --exclude "home/*"  --exclude "dev/*" -C /$MOUNT/$nom_machine .
    
    /bin/umount /$MOUNT/$nom_machine/{boot,var,tmp,usr,home}
    /bin/umount /$MOUNT/$nom_machine/
    $PREFIX/vgchange -a n $nom_machine 2>&1 1>/dev/null
    $PREFIX/kpartx -d /dev/mapper/$VG-$rewritedsnap_name
    #suppression du snapshot de la machine virtuelle
    $PREFIX/lvremove -f /dev/mapper/$VG-$rewritedsnap_name
        
else
    echo "Unable to create $nom_machine's snapshot "
    exit 1
fi
