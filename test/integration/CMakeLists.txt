# ===-----------------------------------------------------------------------===#
# Distributed under the 3-Clause BSD License. See accompanying file LICENSE or
# copy at https://opensource.org/licenses/BSD-3-Clause).
# SPDX-License-Identifier: BSD-3-Clause
# ===-----------------------------------------------------------------------===#

set(CRYPTOPP_CMAKE_INSTALL_ROOT
    "${CMAKE_CURRENT_BINARY_DIR}/cryptopp-cmake-install")

# ------------------------------------------------------------------------------
# Basic install tests
# ------------------------------------------------------------------------------

set(test_name "int-install")
message(STATUS "Adding base integration test: ${test_name}")

set(FETCHCONTENT_BASE_DIR ${CMAKE_CURRENT_BINARY_DIR})
cmake_path(GET FETCHCONTENT_BASE_DIR PARENT_PATH FETCHCONTENT_BASE_DIR)
cmake_path(APPEND FETCHCONTENT_BASE_DIR _deps)

# Configure
add_test(
  NAME ${test_name}-configure
  COMMAND
    ${CMAKE_COMMAND}
    # Always use ninja, never the visual studio generator (bugged)
    -GNinja
    # Pass the locations for common cmake test files
    -D "TEST_CMAKE_FILES_DIR=${TEST_CMAKE_FILES_DIR}"
    # Pass the locations for common test source files
    -D "TEST_EXAMPLE_SOURCES_DIR=${TEST_EXAMPLE_SOURCES_DIR}"
    # Share the cryptopp fetched sources among all tests
    -D "FETCHCONTENT_BASE_DIR=${FETCHCONTENT_BASE_DIR}"
    # Use ccache
    -D "USE_CCACHE=TRUE"
    # Override cmake compiler flags for ccache/MSVC
    -D
    "CMAKE_USER_MAKE_RULES_OVERRIDE=${TEST_CMAKE_FILES_DIR}/ResetInitialCompilerOptions.cmake"
    # Set the install prefix
    -D "CMAKE_INSTALL_PREFIX=${CRYPTOPP_CMAKE_INSTALL_ROOT}"
    # Setup cmake source/build dirs
    -S "${CMAKE_CURRENT_SOURCE_DIR}/${test_name}" -B
    "${CMAKE_CURRENT_BINARY_DIR}/${test_name}-test"
    # Use local source code for cryptopp-cmake
    -D "CPM_cryptopp-cmake_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/../.."
    # Enable verbose makefiles so we can see the full compile command line
    -D "CMAKE_VERBOSE_MAKEFILE=ON")

# Build
add_test(NAME ${test_name}-build
         COMMAND ${CMAKE_COMMAND} --build
                 "${CMAKE_CURRENT_BINARY_DIR}/${test_name}-test")
set_tests_properties(${test_name}-build PROPERTIES DEPENDS
                                                   ${test_name}-configure)

# Install
add_test(
  NAME ${test_name}-install
  COMMAND ${CMAKE_COMMAND} --build
          "${CMAKE_CURRENT_BINARY_DIR}/${test_name}-test" --target install)
set_tests_properties(${test_name}-install PROPERTIES DEPENDS ${test_name}-build)

# Check installed files
add_test(
  NAME ${test_name}-checks
  COMMAND ${CMAKE_COMMAND} --build
          "${CMAKE_CURRENT_BINARY_DIR}/${test_name}-test" --target do-checks)
set_tests_properties(${test_name}-checks PROPERTIES DEPENDS
                                                    ${test_name}-install)

# ------------------------------------------------------------------------------
# Use cryptopp via find_package
# ------------------------------------------------------------------------------

set(test_name "int-find-package")

# Configure
add_test(
  NAME ${test_name}-configure
  COMMAND
    ${CMAKE_COMMAND}
    # Always use ninja, never the visual studio generator (bugged)
    -GNinja
    # Pass the locations for common cmake test files
    -D TEST_CMAKE_FILES_DIR=${TEST_CMAKE_FILES_DIR}
    # Pass the locations for common test source files
    -D TEST_EXAMPLE_SOURCES_DIR=${TEST_EXAMPLE_SOURCES_DIR}
    # Set the install prefix
    -D "CRYPTOPP_CMAKE_INSTALL_ROOT=${CRYPTOPP_CMAKE_INSTALL_ROOT}"
    # Setup cmake source/build dirs
    -S "${CMAKE_CURRENT_SOURCE_DIR}/${test_name}" -B
    "${CMAKE_CURRENT_BINARY_DIR}/${test_name}-test"
    # Use local source code for cryptopp-cmake
    -D "CPM_cryptopp-cmake_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/../.."
    # Enable verbose makefiles so we can see the full compile command line
    -D "CMAKE_VERBOSE_MAKEFILE=ON")

set_tests_properties(${test_name}-configure PROPERTIES DEPENDS
                                                       "int-install-install")

# Build
add_test(NAME ${test_name}-build
         COMMAND ${CMAKE_COMMAND} --build
                 "${CMAKE_CURRENT_BINARY_DIR}/${test_name}-test")
set_tests_properties(${test_name}-build PROPERTIES DEPENDS
                                                   ${test_name}-configure)
