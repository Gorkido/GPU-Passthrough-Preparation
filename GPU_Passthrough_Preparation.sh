if [ $EUID -ne 0 ]
	then
		echo "This program must run as root to function." 
		exit 1
fi

libvirt() {
    echo "This will install and configure libvirt, QEMU and Virt-Manager."
    sleep 1s
    sudo pacman -S --noconfirm virt-manager qemu vde2 ebtables iptables-nft nftables dnsmasq bridge-utils ovmf
    sleep 1s
    systemctl start libvirtd
    echo "libvirtd Started"
    sleep 1s
    systemctl enable libvirtd
    echo "Enabled libvirtd"
    sleep 1s
    sudo usermod -a -G libvirt $(whoami)
    echo "Added $(whoami) to kvm and libvirt groups."
    sleep 1s
    echo "libvirt has been successfully configured!"
    sleep 1s
    echo "Configuring QEMU!"
    sleep 1s
    systemctl restart libvirtd
    echo "Restarted libvirtd"
    echo "QEMU has been successfully configured!"
}

virsh_net() {
    sudo virsh net-autostart default
    echo "Enabled virtual machine default network"
}

configs() {
	cat >> /etc/libvirt/libvirtd.conf <<- _EOF_
        unix_sock_group = "libvirt"
        unix_sock_rw_perms = "0770"
        log_filters="1:qemu"
        log_outputs="1:file:/var/log/libvirt/libvirtd.log"
	_EOF_

	cat >> /etc/libvirt/qemu.conf <<- _EOF_
        user="root"
        group="wheel"
	_EOF_
}

## Main
libvirt()
virsh_net()
configs()