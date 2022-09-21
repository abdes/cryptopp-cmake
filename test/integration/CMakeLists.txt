# ===-----------------------------------------------------------------------===#
# Distributed under the 3-Clause BSD License. See accompanying file LICENSE or
# copy at https://opensource.org/licenses/BSD-3-Clause).
# SPDX-License-Identifier: BSD-3-Clause
# ===-----------------------------------------------------------------------===#

set(INT_TEST_CMAKE_FILES_DIR ${CMAKE_CURRENT_SOURCE_DIR}/cmake)
set(CRYPTOPP_CMAKE_INSTALL_ROOT
    "${CMAKE_CURRENT_BINARY_DIR}/cryptopp-cmake-install")

file(GLOB tests "${CMAKE_CURRENT_SOURCE_DIR}/int-install-*")
foreach(test ${tests})
  cmake_path(GET test FILENAME test_name)
  message(STATUS "Adding install integration test: ${test_name}")
  # Configure
  add_test(
    NAME ${test_name}-configure
    COMMAND
      ${CMAKE_COMMAND}
      # Always use ninja, never the visual studio generator (bugged)
      -G${CMAKE_GENERATOR}
      # Pass the locations for common cmake test files
      -D "TEST_CMAKE_FILES_DIR=${TEST_CMAKE_FILES_DIR}" -D
      "INT_TEST_CMAKE_FILES_DIR=${INT_TEST_CMAKE_FILES_DIR}"
      # Pass the locations for common test source files
      -D "TEST_EXAMPLE_SOURCES_DIR=${TEST_EXAMPLE_SOURCES_DIR}"
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
      -D "CMAKE_VERBOSE_MAKEFILE=ON"
      # Throw the version in
      -D CRYPTOPP_MINIMUM_CMAKE_VERSION=${CRYPTOPP_MINIMUM_CMAKE_VERSION})

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
  set_tests_properties(${test_name}-install PROPERTIES DEPENDS
                                                       ${test_name}-build)

  # Check installed files
  add_test(
    NAME ${test_name}-checks
    COMMAND ${CMAKE_COMMAND} --build
            "${CMAKE_CURRENT_BINARY_DIR}/${test_name}-test" --target do-checks)
  set_tests_properties(${test_name}-checks PROPERTIES DEPENDS
                                                      ${test_name}-install)
endforeach()

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
    -G${CMAKE_GENERATOR}
    # Pass the locations for common test source files
    -D "TEST_EXAMPLE_SOURCES_DIR=${TEST_EXAMPLE_SOURCES_DIR}"
    # Set the install prefix
    -D "CRYPTOPP_CMAKE_INSTALL_ROOT=${CRYPTOPP_CMAKE_INSTALL_ROOT}"
    # Setup cmake source/build dirs
    -S "${CMAKE_CURRENT_SOURCE_DIR}/${test_name}" -B
    "${CMAKE_CURRENT_BINARY_DIR}/${test_name}-test"
    # Enable verbose makefiles so we can see the full compile command line
    -D "CMAKE_VERBOSE_MAKEFILE=ON"
    # Throw the version in
    -D CRYPTOPP_MINIMUM_CMAKE_VERSION=${CRYPTOPP_MINIMUM_CMAKE_VERSION})

set_tests_properties(${test_name}-configure
                     PROPERTIES DEPENDS "int-install-default-install")

# Build
add_test(NAME ${test_name}-build
         COMMAND ${CMAKE_COMMAND} --build
                 "${CMAKE_CURRENT_BINARY_DIR}/${test_name}-test")
set_tests_properties(${test_name}-build PROPERTIES DEPENDS
                                                   ${test_name}-configure)

set_tests_properties(int-install-prefix-configure
                     PROPERTIES DEPENDS "int-find-package-build")
