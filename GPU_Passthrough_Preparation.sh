#!/bin/sh

username=$(whoami)

libvirt() {
    echo "This will install and configure libvirt, QEMU and Virt-Manager."
    pacman -S --noconfirm virt-manager qemu vde2 ebtables iptables-nft nftables dnsmasq bridge-utils ovmf wget
    sleep 2
    echo "Installed required packages"
    usermod -a -G libvirt $username
    echo "Added $username to kvm and libvirt groups."
    sleep 2
    systemctl start libvirtd
    sleep 2
    echo "libvirtd Started"
    systemctl enable libvirtd
    sleep 2
    echo "Enabled libvirtd"
    systemctl restart libvirtd
    echo "Restarted libvirtd"
    sleep 2
}

virsh_net() {
    virsh net-autostart default
    echo "Enabled virtual machine default network"
    sleep 2
}

configs() {
    cp -r $(pwd)/hooks/ /etc/libvirt/
    sleep 1
    chmod +x /etc/libvirt/hooks/qemu
    chmod +x /etc/libvirt/hooks/qemu.d/win10/prepare/begin/start.sh
    chmod +x /etc/libvirt/hooks/qemu.d/win10/release/end/revert.sh
    echo "Uncommented required lines from '/etc/libvirt/libvirtd.conf'"
    sed -i '/unix_sock_rw_perms = "0770"/s/^#//g' /etc/libvirt/libvirtd.conf
    sed -i '/unix_sock_group = "libvirt"/s/^#//g' /etc/libvirt/libvirtd.conf

    cat >> /etc/libvirt/libvirtd.conf <<- _EOF_
    
log_filters="1:qemu"
log_outputs="1:file:/var/log/libvirt/libvirtd.log"
	_EOF_
    
    echo "libvirt has been successfully configured!"
    
    sed -i "s/^user = \"root\".*$/user = \"$username\"/" /etc/libvirt/qemu.conf
    sed -i "s/^#group = \"root\".*$/group = \"$username\"/" /etc/libvirt/qemu.conf
    echo "QEMU has been successfully configured!"
    sleep 2
    wget -O $HOME/Documents/iommu_viewer.sh https://raw.githubusercontent.com/Gorkido/IOMMU-viewer/master/iommu_viewer.sh
    sh $HOME/Documents/iommu_viewer.sh
    echo "Find your Video Card's PCI number from above, then type it(Start writing the numbers after 0000: For example: 29_00_0):"
    read GraphicsD
    sed -i  's/VIRSH_GPU_VIDEO=pci_0000_/VIRSH_GPU_VIDEO=pci_0000_$GraphicsD/'  /etc/libvirt/hooks/kvm.conf
    echo "Find your Audio Card's PCI number from above, then type it(Start writing the number after 0000: For example: 29_00_1)"
    read AudioD
    sed -i  's/VIRSH_GPU_AUDIO=pci_0000_/VIRSH_GPU_AUDIO=pci_0000_$AudioD/'  /etc/libvirt/hooks/kvm.conf
    systemctl restart libvirtd
    echo "Restarted libvirtd"   
    echo -e "
    Placing the ROM:
    FEDORA (like other systems with selinux)

    sudo mkdir /var/lib/libvirt/vbios
    place the rom in above directory with
    cd /var/lib/libvirt/vbios
    sudo chmod -R 660 <ROMFILE>rom
    sudo chown username:username <ROMFILE>.rom
    sudo semanage fcontext -a -t virt_image_t /var/lib/libvirt/vbios/<ROMFILE>.rom
    sudo restorecon -v /var/lib/libvirt/vbios/<ROMFILE>.rom

    GENERAL (like other systems with apparmor)

    sudo mkdir /usr/share/vgabios
    place the rom in above directory with
    cd /usr/share/vgabios
    sudo chmod -R 660 <ROMFILE>.rom
    sudo chown username:username <ROMFILE>.rom

    OpenSuse
    optional: sudo groupadd your username
    The result has to be like:
    ls -tlr total 256 -rw-rw---- 1 username username 260096 15 nov 00:43 <romfile>.rom
    
    Source: https://gitlab.com/risingprismtv/single-gpu-passthrough/-/wikis/6)-Preparation-and-placing-of-ROM-file"
}

uninstall() {
    pacman -Rns --noconfirm virt-manager qemu vde2 dnsmasq bridge-utils
    systemctl stop libvirtd
    systemctl disable libvirtd
    rm -rf /etc/libvirt
    exit 0
}

## Show usages
usage() {
	echo -e "Usages : $(basename $0) --install | --uninstall \n"
}

## Main
if [[ "$1" == "--install" ]]; then
	libvirt
    virsh_net
    configs
elif [[ "$1" == "--uninstall" ]]; then
	uninstall
else
	{ usage; exit 0; }
fi
