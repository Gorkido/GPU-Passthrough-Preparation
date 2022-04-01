libvirt() {
    echo "This will install and configure libvirt, QEMU and Virt-Manager."
    sudo pacman -S virt-manager qemu vde2 ebtables iptables-nft nftables dnsmasq bridge-utils ovmf
    echo "Installed required packages"
    sudo systemctl start libvirtd
    echo "libvirtd Started"
    sudo systemctl enable libvirtd
    echo "Enabled libvirtd"
    sudo usermod -a -G libvirt $(whoami)
    echo "Added $(whoami) to kvm and libvirt groups."
    sudo systemctl restart libvirtd
    echo "Restarted libvirtd"
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
    echo "libvirt has been successfully configured!"

	cat >> /etc/libvirt/qemu.conf <<- _EOF_
    user="root"
    group="wheel"
	_EOF_
    echo "QEMU has been successfully configured!"
}

files() {
    cp -r $(pwd)/hooks/ /etc/libvirt/
}

uninstall() {
    sudo systemctl stop libvirtd
    sudo systemctl disable libvirtd
    sudo pacman -Rns --noconfirm virt-manager qemu vde2 ebtables iptables-nft nftables dnsmasq bridge-utils ovmf
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
    files
elif [[ "$1" == "--uninstall" ]]; then
	uninstall
else
	{ usage; exit 0; }
fi