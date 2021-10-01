#!/usr/bin/env bash

# #################################################
# global variables
# #################################################
PROJECT_DIR="$( cd "$( dirname "$0" )" && pwd )"
KERNEL_BRANCH=
KERNEL_VER=5.10
arch=x86_64
download_kernel=true

# #################################################
# helper functions
# #################################################
function display_help()
{
cat <<EOF
Linux kernel build & installation helper script
  $0 <options>
      -h | --help                Print this help message
      -d | --download            Download openEuler kernel
      --arch                     Set specific architecture (x86_64, ARM64 or Phytium, default x86_64)
      -v | --kernel-version      Set specific rocm version to build (4.19 or 5.10, default 5.10)
EOF
}

# #################################################
# Parameter parsing
# #################################################

getopt -T
if [[ $? -eq 4 ]]; then
  GETOPT_PARSE=$(getopt --name "${0}" --longoptions help,download,arch:,kernel-version:, --options hdv: -- "$@")
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
    -d|--download)
        download_kernel=true
        shift ;;
    --arch)
        arch=${2}
        shift 2 ;;
    -v|--kernel-version)
        KERNEL_VER=${2}
        shift 2;;
    --) shift ; break ;;
    *)  echo "Unexpected command line parameter received; aborting";
        exit 1
        ;;
  esac
done

set -x

#Install the software that the kernel depends on

sudo yum install gcc make ncurses-devel openssl automake openssl-devel
sudo yum install bc gcc-c++ kernel-devel pkg-config glibc bison flex elfutils-libelf-devel

#Compile the kernel

if [[ "${download_kernel}" == true ]]; then
    cd ${PROJECT_DIR}/kernel
    git submodule init
    git submodule update
fi

if [[ "${KERNEL_VER}" == 5.10 ]]; then
    KERNEL_BRANCH=openEuler-21.03
fi

if [[ "${KERNEL_VER}" == 4.19 ]]; then
    KERNEL_BRANCH=kernel-4.19
fi

<< EOF
echo ${KERNEL_BRANCH}
echo ${arch}
ls ${PROJECT_DIR}/kernel-patch/${KERNEL_VER}/ROCm_kernel_${arch}.config
EOF

git pull
make mrproper
cp ${PROJECT_DIR}/kernel-patch/${KERNEL_VER}/ROCm_kernel_${arch}.config .config

cpus=`grep '^processor' /proc/cpuinfo | sort -u | wc -l`
make -j${cpus}
sudo make modules_install
sudo make install
