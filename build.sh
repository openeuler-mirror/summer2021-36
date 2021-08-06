#!/usr/bin/env bash

# #################################################
# global variables
# #################################################
PROJECT_DIR="$( cd "$( dirname "$0" )" && pwd )"
ROCm_DIR=${PROJECT_DIR}/ROCm
ROCM_INSTALL_PATH=/opt/rocm
ROCT_DIR=${ROCm_DIR}/ROCT-Thunk-Interface
LLVM_DIR=${ROCm_DIR}/llvm-project
ROCM_DEV_LIBS_DIR=${ROCm_DIR}/ROCm-Device-Libs
ROCR_DIR=${ROCm_DIR}/ROCR-Runtime
ROCM_CS_DIR=${ROCm_DIR}/ROCm-CompilerSupport
ROCM_CMAKE_DIR=${ROCm_DIR}/rocm-cmake
ROCCLR_DIR=${ROCm_DIR}/ROCclr
HIP_DIR=${ROCm_DIR}/HIP
rocminfo_dir=${ROCm_DIR}/rocminfo
rocm_smi_lib_dir=${ROCm_DIR}/rocm_smi_lib
rocm_bandwidth_dir=${ROCm_DIR}/rocm_bandwidth_test
rocRand_dir=${ROCm_DIR}/rocRAND
rocBLAS_dir=${ROCm_DIR}/rocBLAS
ROCmValidationSuite_DIR=${ROCm_DIR}/ROCmValidationSuite
ROCm_VER=rocm-4.2.0
ROCm_BRANCH=
ROCm_NUMS=
build_roct=false
build_llvm=false
build_rocm_dev=false
build_rocr=false
build_rocm_cs=false
build_rocm_cmake=false
build_rocclr=false
build_hip=false
build_rocminfo=false
build_rocm_smi=false
build_rocm_bw=false
build_rocrand=false
build_rocblas=false
build_rocmvs=false
build_all=true
download_rocm=false
arch=X86
gpu_arch=gfx803

# #################################################
# helper functions
# #################################################
function display_help()
{
cat <<EOF
rocBLAS build & installation helper script
  $0 <options>
      -h | --help                Print this help message
      -a | --all                 Build and install all rocm software (default)
      -d | --download            Download ROCm
      --roct                     Build and install ROCT-Thunk-Interface
      --llvm                     Build and install llvm-project
      --rocm_dev                 Build and install rocm_device-Libs
      --rocr                     Build and install ROCR-Runtime
      --rocm_cs                  Build and install ROCm-CompilerSupport
      --rocm_cmake               Build and install rocm_cmake
      --rocclr                   Build and install ROCclr
      --hip                      Build and install HIP
      --rocminfo                 Build and install rocminfo
      --rocm_smi                 Build and install rocm_smi_lib
      --rocm_bw                  Build and install rocm_bandwidth_test
      --rocrand                  Build and install rocRand
      --rocblas                  Build and install rocBLAS
      --rocmvs                   Build and install ROCmValidationSuite
      --arch                     Set specific architecture (X86 or aarch64, default x86_64)
      --gpu_arch                 Set specific gpu architecture (default gfx803)                      
      --prefix                   Set specific install path to ROCm
      -v | --rocm-version        Set specific rocm version to build
EOF
}

# #################################################
# build and install functions
# #################################################
build_install_roct()
{
        printf "Will build and install ROCT-Thunk-Interface\n"
        sudo yum install cmake numactl-devel rpm-build 
        cd ${ROCT_DIR}
        mkdir -p build && cd build
        cmake ..
        make
        sudo make install
        if [[ ! -e ${ROCM_INSTALL_PATH}/lib/libhsakmt.so ]]; then
                sudo mkdir -p ${ROCM_INSTALL_PATH}/lib
                sudo cp ${ROCM_INSTALL_PATH}/lib64/libhsakmt.so ${ROCM_INSTALL_PATH}/lib/
	fi

        if [[ $LD_LIBRARY_PATH != *${ROCM_INSTALL_PATH}/lib* ]]; then
                sed -i '$a export LD_LIBRARY_PATH='${ROCM_INSTALL_PATH}'/lib:$LD_LIBRARY_PATH' ~/.bash_profile
                sed -i '$a export LD_LIBRARY_PATH='${ROCM_INSTALL_PATH}'/lib64:$LD_LIBRARY_PATH' ~/.bash_profile
                sed -i '$a export PATH='${ROCM_INSTALL_PATH}'/bin:$PATH' ~/.bash_profile
                source ~/.bash_profile
        fi
}

build_install_llvm()
{
        printf "Will build and install llvm-project\n"
        cd ${LLVM_DIR}
        mkdir -p build && cd build
        cmake -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_PATH}/llvm -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=1 -DLLVM_TARGETS_TO_BUILD="AMDGPU;${arch}" -DLLVM_ENABLE_PROJECTS="clang;lld;compiler-rt;libclc;libcxx;libcxxabi;openmp;parallel-libs" ../llvm
        make
        sudo make install

        if [[ $LD_LIBRARY_PATH != *${ROCM_INSTALL_PATH}/llvm/lib* ]]; then
                sed -i '$a export LD_LIBRARY_PATH='${ROCM_INSTALL_PATH}'/llvm/lib:$LD_LIBRARY_PATH' ~/.bash_profile
                sed -i '$a export PATH='${ROCM_INSTALL_PATH}'/llvm/bin:$PATH' ~/.bash_profile
                source ~/.bash_profile
        fi
}

build_install_rocm_dev()
{
        printf "Will build and install rocm_device-Libs\n"
        cd ${ROCM_DEV_LIBS_DIR}
        mkdir -p build && cd build
        CC=${ROCM_INSTALL_PATH}/llvm/bin/clang CXX=${ROCM_INSTALL_PATH}/llvm/bin/clang++ cmake -DLLVM_DIR=${ROCM_INSTALL_PATH}/llvm -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_WERROR=1 -DLLVM_ENABLE_ASSERTIONS=1 -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_PATH} ..
        make
        sudo make install
}

build_install_rocr()
{
        printf "Will build and install ROCR-Runtime\n"
        cd ${ROCR_DIR}/src
        mkdir -p build && cd build
        cmake -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_PATH} ..
        make
        sudo make install

        if [[ $LD_LIBRARY_PATH != *${ROCM_INSTALL_PATH}/hsa/lib* ]]; then
                sed -i '$a export LD_LIBRARY_PATH='${ROCM_INSTALL_PATH}'/hsa/lib:$LD_LIBRARY_PATH' ~/.bash_profile
                source ~/.bash_profile
        fi
}

build_install_rocm_cs()
{
        printf "Will build and install ROCm-CompilerSupport\n"
        cd ${ROCM_CS_DIR}/lib/comgr
        mkdir -p build && cd build
        export LLVM_PROJECT=${ROCM_INSTALL_PATH}/llvm
        export DEVICE_LIBS=${ROCM_INSTALL_PATH}
        cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_PATH} -DCMAKE_PREFIX_PATH="$LLVM_PROJECT;$DEVICE_LIBS" ..
        make
        sudo make install
}

build_install_rocm_cmake()
{
        printf "Will build and install rocm_cmake\n"
        cd ${ROCM_CMAKE_DIR}
        mkdir -p build && cd build
        cmake ..
        sudo cmake --build . --target install
}

build_install_rocclr()
{
        printf "Will build and install ROCclr\n"
        sudo yum install mesa-libGL-devel mesa-libGLU-devel
        cd ${ROCm_DIR}
        export ROCclr_DIR="$(readlink -f ROCclr)"
        export OPENCL_DIR="$(readlink -f ROCm-OpenCL-Runtime)"
        cd "$ROCclr_DIR"
        mkdir -p build && cd build
        cmake -DOPENCL_DIR="$OPENCL_DIR" -DCMAKE_PREFIX_PATH=${ROCM_INSTALL_PATH} -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_PATH}/rocclr ..
        make
        sudo make install        
}

build_install_hip()
{
        printf "Will build and install HIP\n"
        cd ${HIP_DIR}
        mkdir -p build && cd build
        cmake -DCMAKE_PREFIX_PATH="${ROCCLR_DIR}/build;${ROCM_INSTALL_PATH}/" -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_PATH}/hip -DHIP_COMPILER=clang ..
        make
        sudo make install

        if [[ $LD_LIBRARY_PATH != *${ROCM_INSTALL_PATH}/hip/lib* ]]; then     
                sed -i '$a export LD_LIBRARY_PATH='${ROCM_INSTALL_PATH}'/hip/lib:$LD_LIBRARY_PATH' ~/.bash_profile
                sed -i '$a export PATH='${ROCM_INSTALL_PATH}'/hip/bin:$PATH' ~/.bash_profile
                source ~/.bash_profile
                sudo sed -i '$a $HIPCXXFLAGS .= " --rocm-path='${ROCM_INSTALL_PATH}' ";' ${ROCM_INSTALL_PATH}/hip/bin/hipcc
                sudo sed -i '$a $HIPCFLAGS .= " --rocm-path='${ROCM_INSTALL_PATH}' ";' ${ROCM_INSTALL_PATH}/hip/bin/hipcc
                sudo sed -i '$a $HIPCFLAGS .= " --rocm-path='${ROCM_INSTALL_PATH}' ";' ${ROCM_INSTALL_PATH}/hip/bin/hipcc 
        fi
}

build_install_rocminfo()
{
        printf "Will build and install rocminfo\n"
        cd ${rocminfo_dir}
        mkdir -p build
        cd build
        cmake -DCMAKE_PREFIX_PATH=${ROCM_INSTALL_PATH} -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_PATH} ..
        make
        sudo make install
}

build_install_rocm_smi()
{
        printf "Will build and install rocm_smi_lib\n"
        cd ${rocm_smi_lib_dir}
        mkdir -p build
        cd build
        cmake ..
        make
        sudo make install
}

build_install_rocm_bw()
{
        printf "Will build and install rocm_bandwidth_test\n"
        cd ${rocm_bandwidth_dir}
        mkdir -p build
        cd build
        cmake ..
        make
}

build_install_rocrand()
{
        printf "Will build and install rocRand\n"
        cd ${rocRand_dir}
        mkdir -p build && cd build
        CXX=hipcc CXXFLAGS=--rocm-path=${ROCM_INSTALL_PATH} cmake -DBUILD_BENCHMARK=ON -D AMDGPU_TARGETS=${gpu_arch} -DCMAKE_INSTALL_PATH=${ROCM_INSTALL_PATH} ..
        make
        sudo make install
        if [[ $LD_LIBRARY_PATH != *${ROCM_INSTALL_PATH}/hiprand/lib* ]]; then
                sed -i '$a export LD_LIBRARY_PATH='${ROCM_INSTALL_PATH}'/hiprand/lib:$LD_LIBRARY_PATH' ~/.bash_profile
                sed -i '$a export LD_LIBRARY_PATH='${ROCM_INSTALL_PATH}'/rocrand/lib:$LD_LIBRARY_PATH' ~/.bash_profile
                source ~/.bash_profile
        fi
}

build_install_rocblas()
{
        printf "Will build and install rocBLAS\n"
        sudo yum install boost-devel
        cd ~/
        git clone https://github.com.cnpmjs.org/msgpack/msgpack-c.git
        cd msgpack-c
        git checkout c_master
        cmake .
        make
        sudo make install
        
        git checkout cpp_master
        cmake -DMSGPACK_CXX11=ON .
        make 
        sudo make install
        
        cp ${PROJECT_DIR}/${ROCm_VER}-patch/rocBLAS/install.sh ${rocBLAS_dir}
        cp ${PROJECT_DIR}/${ROCm_VER}-patch/rocBLAS/CMakeLists.txt ${rocBLAS_dir}
        cd ${rocBLAS_dir}
        ./install.sh
        sudo cp -rf build/release/rocblas-install/rocblas/include/* ${ROCM_INSTALL_PATH}/include
        sudo cp -rf build/release/rocblas-install/rocblas/lib/* ${ROCM_INSTALL_PATH}/lib
}

build_install_rocmvs()
{
        printf "Will build and install ROCmValidationSuite\n"
        sudo yum install doxygen pciutils-devel
        cp ${PROJECT_DIR}/${ROCm_VER}-patch/ROCmValidationSuite/CMakeLists.txt ${ROCmValidationSuite_DIR}
        cp ${PROJECT_DIR}/${ROCm_VER}-patch/ROCmValidationSuite/CMakeYamlDownload.cmake ${ROCmValidationSuite_DIR}
        cp ${PROJECT_DIR}/${ROCm_VER}-patch/ROCmValidationSuite/CMakeGtestDownload.cmake ${ROCmValidationSuite_DIR}
        cd ${ROCmValidationSuite_DIR}

        if [[ "${ROCm_VER}" == rocm-4.2.0 ]]; then
                mv rvs/conf/deviceid.sh.in rvs/conf/deviceid.sh
        fi

        mkdir -p build && cd build
        cmake -DROCM_PATH=${ROCM_INSTALL_PATH} -DCMAKE_INSTALL_PREFIX=${ROCM_INSTALL_PATH} -DCMAKE_PACKAGING_INSTALL_PREFIX=${ROCM_INSTALL_PATH} ..
        make
        sudo make install
        make package   
}

build_install_all()
{
        printf "Will build and install all\n"
        build_install_roct
        build_install_llvm
        build_install_rocm_dev
        build_install_rocr
        build_install_rocm_cs
        build_install_rocm_cmake
        build_install_rocclr
        build_install_hip
        build_install_rocminfo
        build_install_rocm_smi
        build_install_rocm_bw
        build_install_rocrand
        build_install_rocblas
        build_install_rocmvs
}

# #################################################
# Parameter parsing
# #################################################

# check if we have a modern version of getopt that can handle whitespace and long parameters
getopt -T
if [[ $? -eq 4 ]]; then
  GETOPT_PARSE=$(getopt --name "${0}" --longoptions help,all,download,roct,llvm,rocm_dev,rocr,rocm_cs,rocm_cmake,rocclr,hip,rocminfo,rocm_smi,rocm_bw,rocrand,rocblas,rocmvs,arch:,prefix:,rocm-version:, --options hdav: -- "$@")
else
  echo "Need a new version of getopt"
  exit 1
fi

if [[ $? -ne 0 ]]; then
  echo "getopt invocation failed; could not parse the command line";
  exit 1
fi

eval set -- "${GETOPT_PARSE}"

while true; do
  case "${1}" in
    -h|--help)
        display_help
        exit 0
        ;;
    -a|--all)
        build_all=true
        shift ;;
    -d|--download)
        download_rocm=true
        shift ;;
    --roct)
        build_roct=true
        shift ;;
    --llvm)
        build_llvm=true
        shift ;;
    --rocm_dev)
        build_rocm_dev=true
        shift ;;
    --rocr)
        build_rocr=true
        shift ;;
    --rocm_cs)
        build_rocm_cs=true
        shift ;;
    --rocm_cmake)
        build_rocm_cmake=true
        shift ;;
    --rocclr)
        build_rocclr=true
        shift ;;
    --hip)
        build_hip=true
        shift ;;
    --rocminfo)
        build_rocminfo=true
        shift ;;
    --rocm_smi)
        build_rocm_smi=true
        shift ;;
    --rocm_bw)
        build_rocm_bw=true
        shift ;;
    --rocrand)
        build_rocrand=true
        shift ;;
    --rocblas)
        build_rocblas=true
        shift ;;
    --rocmvs)
        build_rocmvs=true
        shift ;;
    -v|--rocm-version)
        ROCm_VER=${2}
        shift 2;;
    --prefix)
        ROCM_INSTALL_PATH=${2}
        shift 2 ;;
    --arch)
        arch=${2}
        shift 2 ;;
    --) shift ; break ;;
    *)  echo "Unexpected command line parameter received; aborting";
        exit 1
        ;;
  esac
done

set -x

if (!(test -e /usr/bin/python)); then
        ln -s /usr/bin/python3 /usr/bin/python
fi

if (!(test -e ~/.bin/repo)); then
        mkdir -p ~/.bin/
        curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.bin/repo
        chmod a+x ~/.bin/repo
fi

if [[ "${ROCm_VER}" == rocm-4.2.0 ]]; then
        ROCm_BRANCH=roc-4.2.x
        ROCm_NUMS=15
        echo "Build and install rocm-4.2.0"
fi

if [[ "${ROCm_VER}" == rocm-4.3.0 ]]; then
        ROCm_BRANCH=roc-4.3.x
        ROCm_NUMS=15
        echo "Build and install rocm-4.3.0"
fi

if (!(test -d ${ROCm_DIR})); then
        mkdir -p ${ROCm_DIR}   
fi

cd ${ROCm_DIR}
CURRENT_ROCm_NUMS=`ls -l |grep "^d"|wc -l`
if [[ "${CURRENT_ROCm_NUMS}" != ${ROCm_NUMS} ]] || [[ "${download_rocm}" == true ]]; then
        echo "Need download ROCm!"
#        ~/.bin/repo init -u https://gitee.com/huangyizhitt/ROCm.git -b ${ROCm_BRANCH} --repo-url=https://gerrit-googlesource.lug.ustc.edu.cn/git-repo
        ~/.bin/repo init -u https://gitee.com/openeuler-competition/summer2021-36.git -m ${ROCm_VER}.xml --repo-url=https://gerrit-googlesource.lug.ustc.edu.cn/git-repo
        ~/.bin/repo sync
        git clone git@github.com:RadeonOpenCompute/llvm-project.git -b ${ROCm_VER}
fi

if [[ "${build_roct}" == true ]]; then
        build_all=false
        build_install_roct
fi

if [[ "${build_llvm}" == true ]]; then
        build_all=false
        build_install_llvm
fi

if [[ "${build_rocm_dev}" == true ]]; then
        build_all=false
        build_install_rocm_dev
fi

if [[ "${build_rocr}" == true ]]; then
        build_all=false
        build_install_rocr
fi

if [[ "${build_rocm_cs}" == true ]]; then
        build_all=false
        build_install_rocm_cs
fi

if [[ "${build_rocm_cmake}" == true ]]; then
        build_all=false
        build_install_rocm_cmake
fi

if [[ "${build_rocclr}" == true ]]; then
        build_all=false
        build_install_rocclr
fi

if [[ "${build_hip}" == true ]]; then
        build_all=false
        build_install_hip
fi

if [[ "${build_rocminfo}" == true ]]; then
        build_all=false
        build_install_rocminfo
fi

if [[ "${build_rocm_smi}" == true ]]; then
        build_all=false
        build_install_rocm_smi
fi

if [[ "${build_rocm_bw}" == true ]]; then
        build_all=false
        build_install_rocm_bw
fi

if [[ "${build_rocrand}" == true ]]; then
        build_all=false
        build_install_rocrand
fi

if [[ "${build_rocblas}" == true ]]; then
        build_all=false
        build_install_rocblas
fi

if [[ "${build_rocmvs}" == true ]]; then
        build_all=false
        build_install_rocmvs
fi

if [[ "${build_all}" == true ]]; then
        build_install_all
fi
