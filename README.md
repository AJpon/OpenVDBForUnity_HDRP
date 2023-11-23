# OpenVDBForUnity

Unity plugins for [OpenVDB](http://www.openvdb.org/).

## Build Status

| Bintray | Linux & Mac | Windows | 
|:--------:|:---------:|:-------------:|
|[ ![Download](https://api.bintray.com/packages/kazuki/conan/OpenVDBNativePlugin%3Akazuki/images/download.svg) ](https://bintray.com/kazuki/conan/OpenVDBNativePlugin%3Akazuki/_latestVersion)|[![Build Status](https://travis-ci.org/karasusan/OpenVDBForUnity.svg?branch=master)](https://travis-ci.org/karasusan/OpenVDBForUnity)|[![Build status](https://ci.appveyor.com/api/projects/status/fydwfy6dalw7hvic?svg=true)](https://ci.appveyor.com/project/karasusan/openvdbforunity)|

![gif](https://github.com/karasusan/OpenVDBForUnity/wiki/images/CloudSample.gif)

## Requirements

- Unity 2018.2 or later

## How to Use 

First, this project depends on some submodules. Check these commands below to checkout submodules.

```
git submodule init
git submodule update
```

Next, you need to download the final release version plugin from the package repository on [Bintray](https://bintray.com/kazuki/conan/OpenVDBNativePlugin%3Akazuki).  You can download from the menu bar.
( **Packages** -> **OpenVDB** -> **Download Library** )

![img](https://github.com/karasusan/OpenVDBForUnity/wiki/images/PackageInstall.png)

Finally, select your OpenVDB file (file extension is **.vdb**) in the project window and reimport from the cotext menu.

![img](https://github.com/karasusan/OpenVDBForUnity/wiki/images/ImportVDBFile.png)

## Build

##### Windows

Note that the following commands have only been tested for 64bit systems/libraries.
It is recommended to set the `VCPKG_DEFAULT_TRIPLET` environment variable to
`x64-windows` to use 64-bit libraries by default. You will also require
[Visual Studio](https://visualstudio.microsoft.com/downloads/) (for the MSVC C++
runtime and compiler toolchains), [CMake](https://cmake.org/download/) and optionally
[vcpkg](https://github.com/microsoft/vcpkg) for the installation of dependencies.

```bash
git clone git@github.com:kuyuri-iroha/OpenVDBForUnity_HDRP.git
cd OpenVDBForUnity_HDRP\Plugin
mkdir build
cd build
cmake -D CMAKE_TOOLCHAIN_FILE=<PATH_TO_VCPKG>\scripts\buildsystems\vcpkg.cmake -D VCPKG_TARGET_TRIPLET=x64-windows -A x64 -S .. -B .
cmake --build . --parallel 4 --config Release --target install
```
or
```bash
git clone git@github.com:kuyuri-iroha/OpenVDBForUnity_HDRP.git
cd OpenVDBForUnity_HDRP\Plugin
mkdir build
cd build
cmake -D VCPKG_TARGET_TRIPLET=x64-windows -A x64 -S .. -B .
cmake --build . --parallel 4 --config Release --target install
```