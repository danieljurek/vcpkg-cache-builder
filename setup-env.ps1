
if ($IsLinux) {

    # Mostly copied from https://github.com/microsoft/vcpkg/blob/master/scripts/azure-pipelines/linux/provision-image.sh
    $env:DEBIAN_FRONTEND='noninteractive'

    ## CUDA
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
    mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/3bf863cc.pub
    add-apt-repository "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/ /"

    $aptPackages = @(
        "git",
        "curl",
        "zip",
        "unzip",
        "tar",
        "at",
        "libxt-dev",
        "gperf",
        "libxaw7-dev",
        "cifs-utils",
        "build-essential",
        "g++",
        "gfortran",
        "libx11-dev",
        "libxkbcommon-x11-dev",
        "libxi-dev",
        "libgl1-mesa-dev",
        "libglu1-mesa-dev",
        "mesa-common-dev",
        "libxinerama-dev",
        "libxxf86vm-dev",
        "libxcursor-dev",
        "yasm",
        "libnuma1",
        "libnuma-dev",
        "libtool-bin",
        "flex",
        "bison",
        "libbison-dev",
        "autoconf",
        "libudev-dev",
        "libncurses5-dev",
        "libtool",
        "libxrandr-dev",
        "xutils-dev",
        "dh-autoreconf",
        "autoconf-archive",
        "libgles2-mesa-dev",
        "ruby-full",
        "pkg-config",
        "meson",
        "nasm",
        "cmake",
        "ninja-build",
        "libxext-dev",
        "libxfixes-dev",
        "libxrender-dev",
        "libxcb1-dev",
        "libx11-xcb-dev",
        "libxcb-glx0-dev",
        "libxcb-util0-dev",
        "libxkbcommon-dev",
        "libxcb-keysyms1-dev",
        "libxcb-image0-dev",
        "libxcb-shm0-dev",
        "libxcb-icccm4-dev",
        "libxcb-sync-dev",
        "libxcb-xfixes0-dev",
        "libxcb-shape0-dev",
        "libxcb-randr0-dev",
        "libxcb-render-util0-dev",
        "libxcb-xinerama0-dev",
        "libxcb-xkb-dev",
        "libxcb-xinput-dev",
        "libxcb-cursor-dev",
        "libkrb5-dev",
        "libxcb-res0-dev",
        "libxcb-keysyms1-dev",
        "libxcb-xkb-dev",
        "libxcb-record0-dev",
        "python3-setuptools",
        "python3-mako",
        "python3-pip",
        "python3-venv",
        "nodejs",
        "libwayland-dev",
        "python-is-python3",
        "guile-2.2-dev",
        "libxdamage-dev",
        "libdbus-1-dev",
        "libxtst-dev",
        "haskell-stack",
        "golang-go",
        "wayland-protocols",
        "cuda-compiler-12-1",
        "cuda-libraries-dev-12-1",
        "cuda-driver-dev-12-1",
        "cuda-cudart-dev-12-1",
        "libcublas-12-1",
        "libcurand-dev-12-1",
        "cuda-nvml-dev-12-1",
        "libcudnn8-dev",
        "libnccl2",
        "libnccl-dev",
        "powershell"
    )

    sudo apt update 
    sudo apt install -y @aptPackages


    $pipPackages = @(
        'jinja2'
    )

    pip install @pipPackages
}
