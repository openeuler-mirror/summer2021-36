#! /bin/bash -x

#Install the software that the kernel depends on 

sudo yum install gcc make ncurses-devel openssl automake openssl-devel 
sudo yum install bc gcc-c++ kernel-devel pkg-config glibc bison flex elfutils-libelf-devel

CURRENT_DIR="$( cd "$( dirname "$0" )" && pwd )"
ROCm_DIR=ROCm
ROCM_INSTALL_PATH=/opt/rocm
#Compile the kernel 
cd kernel
make mrproper
cp ../ROCm_kernel.config .config
cpus=`grep '^processor' /proc/cpuinfo | sort -u | wc -l`
make -j${cpus}
sudo make modules_install
sudo make install

#Install the software that the ROCT and ROCR depends on
sudo yum install cmake numactl-devel rpm-build
test -d ${ROCm_DIR} || mkdir -p ${ROCm_DIR}
cd ${CURRENT_DIR}/${ROCm_DIR}

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
cd ${CURRENT_DIR}/${ROCm_DIR}/${ROCT_DIR}/tests/kfdtest
mkdir build
cd build
cmake ..
make
./run_kfdtest.sh

#Compile llvm-project 



#Compile ROCm-Device-Libs


#Compile ROCR


#Test APP rocminfo
cd ${CURRENT_DIR}/${ROCm_DIR}
ROCMINFO_DIR=rocminfo
while (!(test -d ${ROCMINFO_DIR}) )
do
        git clone https://github.com/RadeonOpenCompute/rocminfo.git
done
cd ${ROCMINFO_DIR}
mkdir build
cd build
cmake -DCMAKE_PREFIX_PATH=${ROCM_INSTALL_PATH} ..
make
./rocminfo

#Test APP rocm_smi_lib
cd ${CURRENT_DIR}/${ROCm_DIR}
ROCM_SMI_LIB_DIR=rocm_smi_lib
while (!(test -d ${ROCM_SMI_LIB_DIR}) )
do
        git clone https://github.com/RadeonOpenCompute/rocm_smi_lib.git
done
cd ${ROCM_SMI_LIB_DIR}
mkdir build
cd build
cmake ..
make 
sudo make install
cd ${CURRENT_DIR}/${ROCm_DIR}/${ROCM_SMI_LIB_DIR}
sudo cp -r include/* ${ROCM_INSTALL_PATH}/include/

cd ./tests/rocm_smi_test
mkdir build
cd build
cmake -DROCM_DIR=/opt/rocm ..
make
sudo ./rsmitst64

#Test bandwidth
cd ${CURRENT_DIR}/${ROCm_DIR}
ROCM_BANDWIDTH_DIR=rocm_bandwidth_test
while (!(test -d ${ROCM_BANDWIDTH_DIR}) )
do
        git clone https://github.com/RadeonOpenCompute/rocm_bandwidth_test.git
done
cd ${ROCM_BANDWIDTH_DIR}
mkdir build
cd build
cmake ..
make
./rocm-bandwidth-test

#Test ROCmValidationSuite
sudo yum install doxygen pciutils-devel

cd ${CURRENT_DIR}/${ROCm_DIR}
ROCmValidationSuite_DIR=ROCmValidationSuite
while (!(test -d ${ROCmValidationSuite_DIR}) )
do
        git clone https://github.com/RadeonOpenCompute/ROCmValidationSuite.git
done
cd ${ROCmValidationSuite_DIR}





