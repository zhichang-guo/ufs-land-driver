# (C) Copyright 2009-2016 ECMWF.
#
# This software is licensed under the terms of the Apache Licence Version 2.0
# which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
# In applying this licence, ECMWF does not waive the privileges and immunities
# granted to it by virtue of its status as an intergovernmental organisation nor
# does it submit to any jurisdiction.

################################################################################
# driver
################################################################################

cmake_minimum_required( VERSION 3.12 )
project( driver VERSION 1.0.0 LANGUAGES CXX Fortran )

## Ecbuild integration
find_package( ecbuild 3.3.2 REQUIRED )
include( ecbuild_system NO_POLICY_SCOPE )
ecbuild_declare_project()
list( APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR}/cmake )
set( CMAKE_DIRECTORY_LABELS ${PROJECT_NAME} )

include( GNUInstallDirs )

find_package( OpenMP COMPONENTS CXX Fortran )
find_package( MPI REQUIRED COMPONENTS CXX Fortran )
find_package( NetCDF REQUIRED COMPONENTS Fortran )

## Sources
add_subdirectory( driver )

set(INSTALL_TARGETS_PATH lib/cmake/${PROJECT_NAME})
get_filename_component(TARGETS_FILE "${PROJECT_TARGETS_FILE}" NAME)

#Export package config for build and install trees
set( BINDIR_BUILD_EXPORT ${CMAKE_BINARY_DIR}/bin ) #Exported binary (tools) directory locations for build-tree
file( MAKE_DIRECTORY ${BINDIR_BUILD_EXPORT} )
set( BINDIR_INSTALL_EXPORT ${CMAKE_INSTALL_FULL_BINDIR} ) #Exported binary (tools) directory locations for install-tree
ecbuild_generate_project_config(${PROJECT_NAME}-config.cmake.in PATH_VARS BINDIR_BUILD_EXPORT BINDIR_INSTALL_EXPORT )

ecbuild_print_summary()
