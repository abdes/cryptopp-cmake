# ===-----------------------------------------------------------------------===#
# Distributed under the 3-Clause BSD License. See accompanying file LICENSE or
# copy at https://opensource.org/licenses/BSD-3-Clause).
# SPDX-License-Identifier: BSD-3-Clause
# ===-----------------------------------------------------------------------===#

# Do sanity checks on the cryptopp-cmake installed files

if(NOT EXISTS ${CRYPTOPP_CMAKE_INSTALL_ROOT}/include/cryptopp)
  message(
    FATAL_ERROR
      "include files should be installed under 'cryptopp' subdirectory")
endif()

if(NOT EXISTS ${CRYPTOPP_CMAKE_INSTALL_ROOT}/lib/cryptopp.lib)
  message(FATAL_ERROR "library must b installed at lib/cryptopp.lib")
endif()

if(NOT EXISTS ${CRYPTOPP_CMAKE_INSTALL_ROOT}/share/pkgconfig/cryptopp.pc)
  message(
    FATAL_ERROR
      "pkgconfig file must be installed in share/pkgconfig/cryptopp.pc")
endif()

if(EXISTS ${CRYPTOPP_CMAKE_INSTALL_ROOT}/share/cmake/cryptopp)
  file(GLOB files ${CRYPTOPP_CMAKE_INSTALL_ROOT}/share/cmake/cryptopp/*)
  list(LENGTH files num_files)
  if(num_files EQUAL 0)
    message(
      FATAL_ERROR "cmake config files must be installed in share/cmake/cryptopp"
    )
  endif()
else()
  message(
    FATAL_ERROR "cmake config files must be installed in share/cmake/cryptopp")
endif()
