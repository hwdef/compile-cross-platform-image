## 多架构多平台镜像编译

### 背景 && 简介

多架构、多平台镜像编译是指通过一些方式，将程序编译成可以兼容 linux、windows 等平台，arm64、amd64 等架构的镜像，编译后，可将这些镜像通过相同的tag，储存在一个镜像仓库中，这样无论什么平台和架构拉取镜像时，都可以自动拉取适应本机的镜像版本。

无论什么语言编写的程序，要实现以上目标，大概分为几个步骤：

1. 将代码编译成多平台、多架构的可执行文件
2. 将可执行文件打包成镜像
3. 推送到镜像仓库
4. 创建混合的 manifest
5. 推送 manifest

### 关于 windows 和 Linux

windows 的镜像只能在 windows 系统下编译，Linux 镜像可以在 Linux、windows、mac OS 下编译。由于 windows 的特殊性，本文采用不同的脚本编译两个系统的镜像。

### 关于 manifest

manifest 具体描述了一个 tag 的镜像信息，通过合理生成 manifest，再推送到镜像仓库中，可以实现镜像仓库中一个 tag 储存多平台多架构的镜像

### 目录结构

```
├── Dockerfile.amd64    Linux amd64 使用的 Dockerfile
├── Dockerfile.arm64    Linux arm64 使用的 Dockerfile
├── Dockerfile.win      windows amd64 使用的 Dockerfile
├── Makefile             Linux 镜像编译脚本，混合 manifest 构建脚本
├── README.md            说明
├── VERSION              版本号
├── _output              输出文件夹
├── build.ps1            windows 镜像编译脚本
├── go.mod               go 语言依赖文件
└── main.go              go 语言源码
```

### linux 编译脚本使用说明

```
make    clean                        清理生成的文件
        bin                           编译源码，生成可执行文件
        images                        生成镜像
        push                          推送镜像
        release                       将镜像保存为 tar 文件
        create-multi-archimages     创建多架构 manifest
        push-multi-archimages       推送多架构 manifest
```

### windows 编译脚本使用说明

此脚本只能在 windows 下运行
```
./build.ps1    bin        编译源码，生成可执行文件
                image      生成镜像
                push       推送镜像
                release    将镜像保存为 tar 文件
                clean      清理生成的文件
```
### 多架构多平台可执行文件编译

本仓库用 go 语言举例，通过配置环境变量，分别编译出多个架构的可执行文件，此步骤每个语言都不同，所以不过多赘述，需要根据不同语言自行适配

在 linux 中
```go
for arch in ${REL_OSARCH}; do\
	CGO_ENABLED=0 GOOS=linux GOARCH=$$arch go build -o=${BIN_DIR}/$$arch/${REL_OS}/demo;\
done
```

在 Windows 中

```go
go build -o .\_output\bin\amd64\win\demo.exe
```

### 多架构多平台镜像构建

为每个架构分别准备 Dockfile 文件，将不同架构和平台的可执行文件添加到镜像中，具体可看此目录下的三个 `Dockerfile` 文件

编译 Linux 版本镜像时，选择 docker 官方的 `buildx` 工具，只需将架构作为参数传入即可编译出多架构的镜像，注意编译出的镜像 tag 应不一致，否则会覆盖，建议在 version 中附加上架构信息，例如 demo:v1.0-arm64

windows 版本的镜像只需使用普通的 `docker build` 命令即可，这里应注意的是，windows 的基础镜像一般都比较大，在编译镜像时，应在能运行程序的前提下，使用最小的镜像，节省空间。

编译完镜像后，应将镜像推送到镜像仓库，否则在下面生成 manifest 的步骤中会报错

### 创建、推送混合的 manifest

使用 docker 命令，生成混合架构和平台的 manifest

```shell
docker manifest create 主tag 其他架构和平台的tag...
```

* 主 tag 应不包括架构和平台信息，例如 `demo:v1.0`
* 其他架构和平台的 tag 可以是多个 tag，用空格分隔，这些 tag 需要是已经推送到镜像仓库中的 tag
* 如果是私有仓库，应加 `--insecure` 参数

推送 manifest

```shell
docker manifest push 主tag
```

如果是私有仓库，此处也应加 `--insecure` 参数

### 测试

可以在不同平台和架构的机器上，拉取`主tag`镜像，查看镜像信息，检查镜像能否正常运行

### 本仓库最佳实践

1. 编译 windows 镜像并推送
2. 运行 `make push-multi-archimages` 命令