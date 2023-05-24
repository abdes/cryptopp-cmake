# ===-----------------------------------------------------------------------===#
# Distributed under the 3-Clause BSD License. See accompanying file LICENSE or
# copy at https://opensource.org/licenses/BSD-3-Clause).
# SPDX-License-Identifier: BSD-3-Clause
# ===-----------------------------------------------------------------------===#

function(get_cryptopp_sources)
  # If we have git on the system, prefer the basic git workflow, which is more
  # predictable and straightforward than the FetchContent.
  include(FetchContent)
  set (version_underscore "${cryptopp-cmake_VERSION_MAJOR}_${cryptopp-cmake_VERSION_MINOR}_${cryptopp-cmake_VERSION_PATCH}")
  if(GIT_FOUND)
    if(${CRYPTOPP_USE_MASTER_BRANCH})
      set(source_location "master")
    else()
      set(source_location
          "CRYPTOPP_${version_underscore}"
      )
    endif()
    FetchContent_Declare(
      cryptopp
      GIT_REPOSITORY ${cryptopp-cmake_HOMEPAGE_URL}
      GIT_TAG ${source_location}
      QUIET
      SOURCE_DIR ${CRYPTOPP_INCLUDE_PREFIX}
  )
  else()
    message(STATUS "Downloading crypto++ from URL...")
    # We use FetchContent for its ability to download an archive from a URL and
    # unzip it.
    cmake_policy(SET CMP0135 NEW)
    if(NOT ${CRYPTOPP_USE_MASTER_BRANCH})
      FetchContent_Declare(
        cryptopp
          URL "${cryptopp-cmake_HOMEPAGE_URL}/releases/download/CRYPTOPP_${version_underscore}/cryptopp${cryptopp-cmake_VERSION_MAJOR}${cryptopp-cmake_VERSION_MINOR}${cryptopp-cmake_VERSION_PATCH}.zip"
          QUIET
          SOURCE_DIR ${CRYPTOPP_INCLUDE_PREFIX}
      )
    endif()
  endif()
  FetchContent_Populate(cryptopp)
  set(CRYPTOPP_PROJECT_DIR
      ${cryptopp_SOURCE_DIR}
      PARENT_SCOPE)
endfunction()
