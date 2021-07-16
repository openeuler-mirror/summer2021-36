#! /bin/bash -x

#Install the software that the kernel depends on 

sudo yum install gcc make ncurses-devel openssl automake openssl-devel 
sudo yum install bc gcc-c++ kernel-devel pkg-config glibc bison flex elfutils-libelf-devel

CURRENT_DIR="$( cd "$( dirname "$0" )" && pwd )"
#Compile the kernel 
cd kernel
make mrproper
cp ../ROCm_kernel.config .config
cpus=`grep '^processor' /proc/cpuinfo | sort -u | wc -l`
make -j${cpus}
sudo make modules_install
sudo make install
cd ${CURRENT_DIR}

#Install the software that the ROCT and ROCR depends on
sudo yum install cmake numactl-devel rpm-build clang

#Compile ROCT
ROCT_DIR=ROCT-Thunk-Interface
while (!(test -d ${ROCT_DIR}) )
do
        git clone https://github.com/RadeonOpenCompute/ROCT-Thunk-Interface.git
done
cd ${ROCT_DIR}
mkdir build
cd build
cmake ..
make
sudo make install

#Test ROCT
cd ${CURRENT_DIR}/${ROCT_DIR}/tests/kfdtest
mkdir build
cd build
cmake ..
make
./run_kfdtest.sh


