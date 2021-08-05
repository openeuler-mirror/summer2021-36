#!/usr/bin/env bash

# #################################################
# global variables
# #################################################
CURRENT_DIR="$( cd "$( dirname "$0" )" && pwd )"
ROCm_DIR=${CURRENT_DIR}/ROCm
ROCM_INSTALL_PATH=/opt/rocm
ROCm_VER=rocm-4.2.0
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
arch=x86_64

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
      --arch                     Set specific architecture (x86_64 or aarch64, default x86_64)
      --prefix                   Set specific install path to ROCm
      -v | --rocm-version        Set specific rocm version to build
EOF
}

# #################################################
# build and install functions
# #################################################
build_install_all()
{
        printf "Will build and install all\n"
}

build_install_roct()
{
        printf "Will build and install ROCT-Thunk-Interface\n"
}

build_install_llvm()
{
        printf "Will build and install llvm-project\n"
}

build_install_rocm_dev()
{
        printf "Will build and install rocm_device-Libs\n"
}

build_install_rocr()
{
        printf "Will build and install ROCR-Runtime\n"
}

build_install_rocm_cs()
{
        printf "Will build and install ROCm-CompilerSupport\n"
}

build_install_rocm_cmake()
{
        printf "Will build and install rocm_cmake\n"
}

build_install_rocclr()
{
        printf "Will build and install ROCclr\n"
}

build_install_hip()
{
        printf "Will build and install HIP\n"
}

build_install_rocminfo()
{
        printf "Will build and install rocminfo\n"
}

build_install_rocm_smi()
{
        printf "Will build and install rocm_smi_lib\n"
}

build_install_rocm_bw()
{
        printf "Will build and install rocm_bandwidth_test\n"
}

build_install_rocrand()
{
        printf "Will build and install rocRand\n"
}

build_install_rocblas()
{
        printf "Will build and install rocBLAS\n"
}

build_install_rocmvs()
{
        printf "Will build and install ROCmValidationSuite\n"
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