# ===-----------------------------------------------------------------------===#
# Distributed under the 3-Clause BSD License. See accompanying file LICENSE or
# copy at https://opensource.org/licenses/BSD-3-Clause).
# SPDX-License-Identifier: BSD-3-Clause
# ===-----------------------------------------------------------------------===#

macro(use_gitclone)
  if(${CRYPTOPP_USE_MASTER_BRANCH})
    set(source_location GIT_BRANCH "master")
  else()
    set(source_location
        GIT_TAG
        "CRYPTOPP_${version_underscore}"
    )
  endif()
  file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/_deps)
  include(GitClone)
  git_clone(
    PROJECT_NAME
    "${CRYPTOPP_INCLUDE_PREFIX}"
    GIT_URL
    ${cryptopp-cmake_HOMEPAGE_URL}
    ${source_location}
    DIRECTORY
    ${CMAKE_CURRENT_BINARY_DIR}/_deps
    SOURCE_DIR_VARIABLE
    cryptopp_SOURCE_DIR)
  set(CRYPTOPP_PROJECT_DIR
      ${cryptopp_SOURCE_DIR}
      PARENT_SCOPE)
endmacro()

macro(use_url_download)
  cmake_policy(SET CMP0135 NEW)
  if(NOT ${CRYPTOPP_USE_MASTER_BRANCH})
    if(NOT DEFINED FETCHCONTENT_BASE_DIR)
      set(FETCHCONTENT_BASE_DIR ${CMAKE_CURRENT_BINARY_DIR}/_deps)
    endif()
    include(FetchContent)
    file(MAKE_DIRECTORY ${FETCHCONTENT_BASE_DIR})
    FetchContent_Declare(
      cryptopp
      URL "${cryptopp-cmake_HOMEPAGE_URL}/releases/download/CRYPTOPP_${version_underscore}/cryptopp${cryptopp-cmake_VERSION_MAJOR}${cryptopp-cmake_VERSION_MINOR}${cryptopp-cmake_VERSION_PATCH}.zip"
      QUIET
      SOURCE_DIR
        ${FETCHCONTENT_BASE_DIR}/cryptopp-src/${CRYPTOPP_INCLUDE_PREFIX}
      BINARY_DIR ${FETCHCONTENT_BASE_DIR}/cryptopp-build
      SUBBUILD_DIR ${FETCHCONTENT_BASE_DIR}/cryptopp-subbuild
    )
    FetchContent_Populate(cryptopp)
    FetchContent_GetProperties(cryptopp SOURCE_DIR)
    set(CRYPTOPP_PROJECT_DIR
        ${cryptopp_SOURCE_DIR}
        PARENT_SCOPE)
  endif()
endmacro()

function(get_cryptopp_sources)
  # If we have git on the system, prefer the basic git workflow, which is more
  # predictable and straightforward than the FetchContent.
  set (version_underscore "${cryptopp-cmake_VERSION_MAJOR}_${cryptopp-cmake_VERSION_MINOR}_${cryptopp-cmake_VERSION_PATCH}")
  if(GIT_FOUND)
    use_gitclone()
  else()
    message(STATUS "Downloading crypto++ from URL...")
    # We use FetchContent for its ability to download an archive from a URL and
    # unzip it.
    use_url_download()
  endif()
endfunction()
