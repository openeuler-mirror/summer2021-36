# Summer2021-No.36 将AMD ROCm开源软件栈逐步引入openEuler实现GPU加速计算

# 介绍
https://gitee.com/openeuler-competition/summer-2021/issues/I3EEN1
AMD ROCm™ 开放式生态系统是AMD为加速计算打造的开放式软件生态系统。它能帮助开发人员使用统一的编程框架对CPU/GPU进行开发。

# 软件架构
ROCm由多个Project组成, 本项目逐步将这些Project引入到openEuler中，当前已引入了如下Project中的软件包：
## 1. ROCm Project

### ROCT-Thunk-Interface 
ROCT-Thunk-Interface是ROC kernel driver的用户模式API接口。主要依赖DRM driver和KFD driver，并从用户层通过系统调用进入内核调用driver。  

### ROCR-Runtime
ROCR-Runtime是ROCm的运行时库。它包含了用户模式API接口。并提供支持Host端配置设备端计算核心进行HSA (Heterogeneous System Architecture) 计算所必须的软件库。当前支持的设备包括：  

CPU: Intel Haswell or newer, Core i5, Core i7, Xeon E3 v4 & v5; Xeon E5 v3;  
GPU: Fiji ASIC (AMD R9 Nano, R9 Fury and R9 Fury X); Polaris ASIC (AMD RX480); 

### rocminfo
ROCm的应用，用于报告HSA系统的信息，包括HSA系统属性，所支持的CPU、GPU设备信息等。

### rocm_smi_lib
rocm_smi_lib是ROCm系统管理接口库，它是一个Linux C库，为应用监控和管理GPU提供用户层接口。当前rocm-smi已经作为一个应用被移入rocm_smi_lib。

## 2. AMDGPU Compiler
### llvm-project
llvm-project是在up-stream llvm项目的基础上专门为AMD GPU开发的ROCm llvm-project分支，是HIP Project的基础。

### ROCm-Device-Libs
ROCm-Device-Libs是GPU设备的微码库。它是依赖llvm-project，并被一系列设备端语言运行时库依赖，主要有oclc*、ocml、ockl、opencl、hip、hc等。

### ROCm-CompilerSupport
ROCm-CompilerSupport是编译器支持库，提供各种编译器相关服务，是HIP的依赖库。

### rocm_bandwidth_test
rocm_bandwidth_test是测试内存拷贝和内核读写操作的基准测试程序。它支持多种数据大小的copy、write、read操作的测试。还可以根据内存池及其代理查询系统的拓扑结构。

## 3. HIP Project

### ROCclr
ROCclr 是一个虚拟设备接口，计算运行时与不同的后端（如 ROCr 或 PAL）交互。此抽象允许运行时在 Windows 和 Linux 上运行。 

### HIP
HIP 是一种 C++ 运行时 API 和内核语言，允许开发人员从单一源代码为 AMD 和 NVIDIA GPU 创建便携式应用程序。HIP提供HIPCC编译器用于编译HIP C++代码，类似于NVIDIA的NVCC编译器。HIP可以等效支持有限的CUDA API，并可以通过工具hipify-perl将CUDA代码转换为HIP代码。

## 4. ROCm Libraries
### rocRand
rocRand是ROCm的随机数库。它是利用HIP语言实现，并运行ROCm runtime之上。它能够等效支持cuRand库的函数

以移植的ROCm Project和其中的软件包的对应依赖关系如图：

#### 安装教程

1.  xxxx
2.  xxxx
3.  xxxx

#### 使用说明

1.  xxxx
2.  xxxx
3.  xxxx

#### 参与贡献

1.  Fork 本仓库
2.  新建 Feat_xxx 分支
3.  提交代码
4.  新建 Pull Request


#### 特技

1.  使用 Readme\_XXX.md 来支持不同的语言，例如 Readme\_en.md, Readme\_zh.md
2.  Gitee 官方博客 [blog.gitee.com](https://blog.gitee.com)
3.  你可以 [https://gitee.com/explore](https://gitee.com/explore) 这个地址来了解 Gitee 上的优秀开源项目
4.  [GVP](https://gitee.com/gvp) 全称是 Gitee 最有价值开源项目，是综合评定出的优秀开源项目
5.  Gitee 官方提供的使用手册 [https://gitee.com/help](https://gitee.com/help)
6.  Gitee 封面人物是一档用来展示 Gitee 会员风采的栏目 [https://gitee.com/gitee-stars/](https://gitee.com/gitee-stars/)
