#! /bin/bash -x

#Install the software that the kernel depends on

sudo yum install gcc make ncurses-devel openssl automake openssl-devel
sudo yum install bc gcc-c++ kernel-devel pkg-config glibc bison flex elfutils-libelf-devel

#Compile the kernel
cd kernel
git submodule init
git submodule update
make mrproper
cp ../kernel-patch/x86_64/ROCm_kernel_x86_64.config .config
cpus=`grep '^processor' /proc/cpuinfo | sort -u | wc -l`
make -j${cpus}
sudo make modules_install
sudo make install
