CMAKE_MINIMUM_REQUIRED(VERSION 3.16)

# VCPKG integration
if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
    message(WARNING "CMAKE_TOOLCHAIN_FILE variable is not defined. Please set it to the appropriate directory.")

    if(WIN32)
        # Try to find the vcpkg directory automatically
        set(VCPKG_PATH_PATTERN "C:/Program Files/Microsoft Visual Studio/*/Community/VC/vcpkg")

        file(GLOB VCPKG_INSTALL_DIR ${VCPKG_PATH_PATTERN})
        list(SORT VCPKG_INSTALL_DIR)
        list(REVERSE VCPKG_INSTALL_DIR)
        list(GET VCPKG_INSTALL_DIR 0 VCPKG_INSTALL_DIR)

        if(EXISTS ${VCPKG_INSTALL_DIR})
            message(STATUS "Found vcpkg at: ${VCPKG_INSTALL_DIR}")
            set(CMAKE_TOOLCHAIN_FILE "${VCPKG_INSTALL_DIR}/scripts/buildsystems/vcpkg.cmake" CACHE FILEPATH "VCPKG Toolchain File")
        else()
            message(WARNING "vcpkg not found. Please set CMAKE_TOOLCHAIN_FILE manually.")
        endif()
    endif()
endif()

PROJECT(OpenVDBNativePlugin)

# Set default to build Dynamic libraries
OPTION(BUILD_SHARED_LIBS "Build Shared Libraries" ON)

# Use C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++17")
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(AddPlugin)

ADD_SUBDIRECTORY(openvdbi)