#! /bin/bash -x

#Install the software that the kernel depends on 

sudo yum install gcc make ncurses-devel openssl automake openssl-devel 
sudo yum install bc gcc-c++ kernel-devel pkg-config glibc bison flex elfutils-libelf-devel

CURRENT_DIR="$( cd "$( dirname "$0" )" && pwd )"
ROCm_DIR=${CURRENT_DIR}/ROCm
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
cd ${ROCm_DIR}

#Compile ROCT
ROCT_DIR=ROCT-Thunk-Interface
while (!(test -d ${ROCT_DIR}) )
do
        git clone https://github.com/RadeonOpenCompute/ROCT-Thunk-Interface.git -b roc-4.2.x
done
cd ${ROCT_DIR}
mkdir build
cd build
cmake ..
make
sudo make install

#Test ROCT
sudo yum install libdrm-devel libdrm_amdgpu-devel libhsakmt-devel
cd ${ROCm_DIR}/${ROCT_DIR}/tests/kfdtest
mkdir build
cd build
cmake ..
make
./run_kfdtest.sh

#Compile llvm-project
cd ${ROCm_DIR} 
LLVM_PROJ=llvm-project
while (!(test -d ${LLVM_PROJ}))
do
	git clone git@github.com:RadeonOpenCompute/llvm-project.git -b rocm-4.2.x
done
cd ${LLVM_PROJ}
LLVM_PROJECT=${ROCM_INSTALL_PATH}/llvm
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${LLVM_PROJECT} -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=1 -DLLVM_TARGETS_TO_BUILD="AMDGPU;X86" -DLLVM_ENABLE_PROJECTS="clang;lld;compiler-rt;libclc;libcxx;libcxxabi;openmp;parallel-libs" ../llvm
make
sudo make install

#Compile ROCm-Device-Libs
cd ${ROCm_DIR} 
ROCM_DEV_LIBS=ROCm-Device-Libs
while (!(test -d ${ROCM_DEV_LIBS}))
do
	git clone https://github.com/RadeonOpenCompute/ROCm-Device-Libs.git -b rocm-4.2.x
done
cd ${ROCM_DEV_LIBS}
mkdir build && cd build
CC=${LLVM_PROJECT}/bin/clang CXX=${LLVM_PROJECT}/bin/clang++ cmake -DLLVM_DIR=${LLVM_PROJECT} -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_WERROR=1 -DLLVM_ENABLE_ASSERTIONS=1 -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_PATH} ..
make
sudo make install
DEVICE_LIBS=${ROCM_INSTALL_PATH}

#Compile ROCR
cd ${ROCm_DIR} 
ROCR=ROCR-Runtime
while (!(test -d ${ROCR}))
do
	git clone https://github.com/RadeonOpenCompute/ROCR-Runtime.git -b rocm-4.2.x
done
cd ${ROCR}
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_PATH} ..
make
sudo make install

#Compile and install ROCm-CompilerSupport
cd ${ROCm_DIR} 
CompilerSupport=ROCm-CompilerSupport
while (!(test -d ${ROCm-CompilerSupport}))
do
	git clone https://github.com/RadeonOpenCompute/ROCm-CompilerSupport.git  -b roc-4.2.x
done
cd ROCm-CompilerSupport/lib/comgr
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_PATH} -DCMAKE_PREFIX_PATH="${LLVM_PROJECT};${DEVICE_LIBS}" ..
make
sudo make install

#Compile and install ROCclr 
cd ${ROCm_DIR} 
sudo yum install mesa-libGL-devel mesa-libGLU-devel
while (!(test -d ROCclr))
do
        git clone https://github.com/ROCm-Developer-Tools/ROCclr -b rocm-4.2.x
done

while (!(test -d ROCm-OpenCL-Runtime))
do 
        git clone https://github.com/RadeonOpenCompute/ROCm-OpenCL-Runtime.git -b rocm-4.2.x
done

ROCclr_DIR="$(readlink -f ROCclr)"
OPENCL_DIR="$(readlink -f ROCm-OpenCL-Runtime)"
cd ${ROCclr_DIR}
mkdir -p build && cd build
cmake -DOPENCL_DIR=${OPENCL_DIR} -DCMAKE_PREFIX_PATH=${ROCM_INSTALL_PATH} -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_PATH}/rocclr ..
make 
sudo make install

#Compile hipcc
cd ${ROCm_DIR} 
while (!(test -d HIP))
do
        git clone https://github.com/ROCm-Developer-Tools/HIP -b rocm-4.2.x
done
export HIP_DIR="$(readlink -f HIP)"
cd ${HIP_DIR}
mkdir -p build && cd build
cmake -DCMAKE_PREFIX_PATH="${ROCclr_DIR}/build;${ROCM_INSTALL_PATH}" -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_PATH}/hip -DHIP_COMPILER=clang ..
make 
sudo make install

#Test APP rocminfo
cd ${ROCm_DIR}
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
cd ${ROCm_DIR}
ROCM_SMI_LIB_DIR=rocm_smi_lib
while (!(test -d ${ROCM_SMI_LIB_DIR}) )
do
        git clone https://github.com/RadeonOpenCompute/rocm_smi_lib.git -b roc-4.2.x
done
cd ${ROCM_SMI_LIB_DIR}
mkdir build
cd build
cmake ..
make 
sudo make install

cd ./tests/rocm_smi_test
mkdir build
cd build
cmake -DROCM_DIR=/opt/rocm ..
make
sudo ./rsmitst64

#Test bandwidth
cd ${ROCm_DIR}
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

cd ${ROCm_DIR}
ROCmValidationSuite_DIR=ROCmValidationSuite
while (!(test -d ${ROCmValidationSuite_DIR}) )
do
        git clone https://github.com/ROCm-Developer-Tools/ROCmValidationSuite.git -b rocm-4.2.x
done
cd ${ROCmValidationSuite_DIR}




