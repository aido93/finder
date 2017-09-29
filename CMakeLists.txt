cmake_minimum_required(VERSION 3.1.0)

project(finder)
set(CPACK_DEBIAN_PACKAGE_NAME "finder")
set(CPACK_DEBIAN_PACKAGE_VERSION "1.0.0")
set(CPACK_DEBIAN_PACKAGE_ARCHITECTURE "amd64")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Igor Diakonov <aidos.tanatos@gmail.com>")
set(CPACK_PACKAGE_CONTACT "Igor Diakonov <aidos.tanatos@gmail.com>")
set(CPACK_DEBIAN_PACKAGE_DESCRIPTION "c++-bicycle for 'find' utility")
set(PACK_DEBIAN_PACKAGE_SHLIBDEPS "ON")

set(CMAKE_EXE_LINKER_FLAGS "-static-libgcc -static-libstdc++")
set( CMAKE_CXX_FLAGS  "${CMAKE_CXX_FLAGS} ${GCC_COVERAGE_COMPILE_FLAGS} -std=c++11" )
set(CMAKE_INCLUDE_CURRENT_DIR ON)

find_package(Readline)
find_package(Boost COMPONENTS filesystem system REQUIRED)
if(NOT Boost_FOUND)
	message(SEND_ERROR "Failed to find boost::filesystem.")
	return()
else()
	include_directories(${Boost_INCLUDE_DIRS})
endif()

find_package(BISON)
find_package(FLEX)
BISON_TARGET(finderParser finder.y ${CMAKE_CURRENT_BINARY_DIR}/finder.tab.cpp)
FLEX_TARGET(finderScanner finder.l ${CMAKE_CURRENT_BINARY_DIR}/lex.yy.cpp)

set ( SOURCE_FILES
		predicate_abstract_factory.cpp
		)

add_executable(finder ${SOURCE_FILES} ${BISON_finderParser_OUTPUTS} ${FLEX_finderScanner_OUTPUTS})
target_link_libraries(finder readline ${Boost_LIBRARIES})
