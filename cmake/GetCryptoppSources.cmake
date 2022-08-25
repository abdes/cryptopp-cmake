# ===-----------------------------------------------------------------------===#
# Distributed under the 3-Clause BSD License. See accompanying file LICENSE or
# copy at https://opensource.org/licenses/BSD-3-Clause).
# SPDX-License-Identifier: BSD-3-Clause
# ===-----------------------------------------------------------------------===#

function(use_gitclone)
  if(${CRYPTOPP_USE_MASTER_BRANCH})
    set(source_location GIT_BRANCH "master")
  else()
    set(source_location
        GIT_TAG
        "CRYPTOPP_${META_VERSION_MAJOR}_${META_VERSION_MINOR}_${META_VERSION_PATCH}"
    )
  endif()
  include(GitClone)
  git_clone(
    PROJECT_NAME
    ext_cryptopp
    GIT_URL
    ${META_GITHUB_REPO}
    ${source_location}
    DIRECTORY
    ${CMAKE_CURRENT_BINARY_DIR}/external
    QUIET)
  set(CRYPTOPP_PROJECT_DIR
      ${ext_cryptopp_SOURCE_DIR}
      PARENT_SCOPE)
endfunction()

function(use_fetch_content)
  find_package(Git QUIET)
  if(GIT_FOUND)
    if(${CRYPTOPP_USE_MASTER_BRANCH})
      set(source_location GIT_REPOSITORY "${META_GITHUB_REPO}" GIT_TAG "master")
    else()
      set(source_location
          GIT_REPOSITORY
          "${META_GITHUB_REPO}"
          GIT_TAG
          "CRYPTOPP_${META_VERSION_MAJOR}_${META_VERSION_MINOR}_${META_VERSION_PATCH}"
      )
    endif()
  elseif(NOT ${CRYPTOPP_USE_MASTER_BRANCH})
    set(source_location
        URL
        "${META_GITHUB_REPO}/releases/download/CRYPTOPP_${META_VERSION_MAJOR}_${META_VERSION_MINOR}_${META_VERSION_PATCH}/cryptopp${META_VERSION_MAJOR}${META_VERSION_MINOR}${META_VERSION_PATCH}.zip"
    )
  endif()
  # Use FetchContent
  include(FetchContent)
  set(FETCHCONTENT_BASE_DIR ${CMAKE_CURRENT_BINARY_DIR}/external)
  FetchContent_Declare(ext_cryptopp ${source_location})
  FetchContent_Populate(ext_cryptopp)
  FetchContent_GetProperties(ext_cryptopp SOURCE_DIR)
  set(CRYPTOPP_PROJECT_DIR
      ${ext_cryptopp_SOURCE_DIR}
      PARENT_SCOPE)
endfunction()
