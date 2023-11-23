
if ($IsLinux) {
    # A non-exhaustive list of ports and their linux requirements:
    # numactl - autoconf libtool
    # python3 - autoconf-archive
    # dpdk - python3-venv doxygen 

    sudo apt update 
    sudo apt install -y autoconf libtool autoconf-archive python3-venv doxygen

}
