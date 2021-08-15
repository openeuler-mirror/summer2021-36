#!/usr/bin/env bash

# #################################################
# global variables
# #################################################
PROJECT_DIR="$( cd "$( dirname "$0" )" && pwd )"
kfdtest_dir=${PROJECT_DIR}/ROCm/ROCT-Thunk-Interface/tests/kfdtest
rocm_smi_test_dir=${PROJECT_DIR}/ROCm/rocm_smi_lib/tests/rocm_smi_test
rocm_bw_test_dir=${PROJECT_DIR}/ROCm/rocm_bandwidth_test
tests_dir=${PROJECT_DIR}/tests
kfdtest=false
rocm_smi_test=false
rocm_bw_test=false
hiptest=false
cudatest=false
all=false


# #################################################
# helper functions
# #################################################
function display_help()
{
cat <<EOF
Test helper script
  $0 <options>
      -h | --help                Print this help message
      -a | --all                 Test all
      --kfdtest                  Test kfd driver and ROCT
      --rocm_smi_test            Test rocm smi lib
      --rocm_bw_test             Test rocm bandwidth
      --hiptest                  Test HIP
      --cudatest                 Test CUDA
EOF
}

# #################################################
# test functions
# #################################################
function func_kfdtest()
{
    printf "Will test KFD driver and ROCT\n"
    cd ${kfdtest_dir}
    mkdir -p build && cd build
    rm -rf *
    cmake ..
    make
    ./run_kfdtest.sh
}

function func_rocm_smi_test()
{
    printf "Will test rocm smi lib\n"
    cd ${rocm_smi_test_dir}
    mkdir -p build && cd build
    rm -rf *
    cmake -DROCM_DIR=/opt/rocm/rocm_smi ..
    make
    sudo ./rsmitst64
}

function func_rocm_bw_test()
{
    printf "Will test rocm bandwdith\n"
    cd ${rocm_bw_test_dir}
    mkdir -p build && cd build
    rm -rf *
    CXX=hipcc CXXFLAGS=--rocm-path=/opt/rocm cmake -DBUILD_BENCHMARK=ON -D AMDGPU_TARGETS=gfx803 -DCMAKE_INSTALL_PATH=/opt/rocm ..
    make
    ./rocm-bandwidth-test
}

function func_hiptest()
{
    printf "Will test HIP\n"
    cd ${tests_dir}
    git clone https://github.com.cnpmjs.org/ROCm-Developer-Tools/HIP-Examples.git
    cd HIP-Examples
    ./test_all.sh
}

function func_cudatest()
{
    printf "Will test CUDA\n"
}

# #################################################
# Parameter parsing
# #################################################

getopt -T
if [[ $? -eq 4 ]]; then
  GETOPT_PARSE=$(getopt --name "${0}" --longoptions help,all,kfdtest,rocm_smi_test,rocm_bw_test,hiptest,cudatest --options ha -- "$@")
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
        all=true
        shift ;;
    --kfdtest)
        kfdtest=true
        shift ;;
    --rocm_smi_test)
        rocm_smi_test=true
        shift ;;
    --rocm_bw_test)
        rocm_bw_test=true
        shift ;;
    --hiptest)
        hiptest=true
        shift ;;
    --cudatest)
        cudatest=true
        shift ;;
    --) shift ; break ;;
    *)  echo "Unexpected command line parameter received; aborting";
        exit 1
        ;;
  esac
done

# Begin test
printf "Will begin test\n"
set -x
mkdir -p ${tests_dir}

if [[ "${all}" == true ]]; then
    kfdtest=true
    rocm_smi_test=true
    rocm_bw_test=true
    hiptest=true
    cudatest=true
fi

if [[ "${kfdtest}" == true ]]; then
    func_kfdtest
fi

if [[ "${rocm_smi_test}" == true ]]; then
    func_rocm_smi_test
fi

if [[ "${rocm_bw_test}" == true ]]; then
    func_rocm_bw_test
fi

if [[ "${hiptest}" == true ]]; then
    func_hiptest
fi

if [[ "${cudatest}" == true ]]; then
    func_cudatest
fi


