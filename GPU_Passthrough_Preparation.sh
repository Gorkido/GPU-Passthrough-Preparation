libvirt() {
    echo "This will install and configure libvirt, QEMU and Virt-Manager."
    pacman -S --noconfirm virt-manager qemu vde2 ebtables iptables-nft nftables dnsmasq bridge-utils ovmf
    sleep 2
    echo "Installed required packages"
    systemctl start libvirtd
    sleep 2
    echo "libvirtd Started"
    systemctl enable libvirtd
    sleep 2
    echo "Enabled libvirtd"
    usermod -a -G libvirt $(whoami)
    sleep 2
    echo "Added $(whoami) to kvm and libvirt groups."
    systemctl restart libvirtd
    echo "Restarted libvirtd"
    sleep 2
}

virsh_net() {
    virsh net-autostart default
    echo "Enabled virtual machine default network"
    sleep 2
}

list=('unix_sock_rw_perms = "0770"' 'unix_sock_group = "libvirt"')

configs() {
    for string in "${list[@]}"; do
    if grep -Fxq /etc/libvirt/libvirtd.conf $string then
        sed -i '/unix_sock_rw_perms = "0770"/s/^#//g' /etc/libvirt/libvirtd.conf
        sed -i '/unix_sock_group = "libvirt"/s/^#//g' /etc/libvirt/libvirtd.conf
    else
    cat >> /etc/libvirt/libvirtd.conf <<- _EOF_
unix_sock_group = "libvirt"
unix_sock_rw_perms = "0770"
	_EOF_
    fi
    done

    cat >> /etc/libvirt/libvirtd.conf <<- _EOF_
    
log_filters="1:qemu"
log_outputs="1:file:/var/log/libvirt/libvirtd.log"
	_EOF_

    echo "libvirt has been successfully configured!"
    
    sed -i '/user = "root"/s/^#//g' /etc/libvirt/qemu.conf
    sed -i 's/#group = "root"/group = "wheel"/' /etc/libvirt/qemu.conf

    echo "QEMU has been successfully configured!"
    sleep 2
}

files() {
    cp -r $(pwd)/hooks/ /etc/libvirt/
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
    files
elif [[ "$1" == "--uninstall" ]]; then
	uninstall
else
	{ usage; exit 0; }
fi