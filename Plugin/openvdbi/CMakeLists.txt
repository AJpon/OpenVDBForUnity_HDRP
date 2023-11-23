file(GLOB sources *.cpp *.h Importer/*.h Importer/*.cpp Foundation/*.h Foundation/*.cpp)

IF(BUILD_SHARED_LIBS)
    set(ENABLE_DEPLOY OFF)
    add_plugin(openvdbi SOURCES ${sources})
ELSE()
    add_library(openvdbi STATIC ${sources})
ENDIF()

install(TARGETS openvdbi DESTINATION lib)

target_include_directories(openvdbi PUBLIC .)

find_package(OpenVDB CONFIG REQUIRED)
target_link_libraries(openvdbi PRIVATE OpenVDB::openvdb)