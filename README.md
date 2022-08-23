# Crypto++ CMake

<div align="center">

-+- Build Status -+-

[![Build status - master][build-status-master-badge]][build-matrix]

-+-

[![Latest release][release-badge]][latest-release]
[![Commits][last-commit-badge]][commits]
[![Linux][linux-badge]][latest-release]
[![Windows][windows-badge]][latest-release]
[![Mac OS][macos-badge]][latest-release]
[![License][license-badge]][license]

</div>

## Introduction

This repository contains CMake files for Wei Dai's Crypto++
(<https://github.com/weidai11/cryptopp>) for those who use the library in
[**Modern CMake**](https://cliutils.gitlab.io/modern-cmake/) projects.

The emphasis on *Modern* here is very important. In 2022, we have some really
good solutions to many of the build problems developers used to waste a lot of
time on. CMake in particular has made so much progress to become one of the most
widely used build systems for C++. But, we're not talking about CMake 2.x here.
We're talking about CMake 3.11+ and maybe even CMake 3.24+.

For more details on this topic, see down below...

## Table of Contents

- [Versioning principles](#versioning-principles)
- [Standard usage](#standard-usage)
- [Using a local copy of crypto++](#using-a-local-copy-of-crypto)
- [Requesting the master branch of cryptopp](#requesting-the-master-branch-of-cryptopp)
- [Other ways](#other-ways)
- [Why Modern CMake?](#why-modern-cmake)

## Versioning principles

This project releases track the [crypto++](https://github.com/weidai11/cryptopp)
releases. In other words, every time a new release of *crypto++* happens, this
project gets updated to take into account changes in source files, compiler
options etc, and will see a new release with the same number than *crypto++*.

At times, bug fixes in this project will happen before a new *crypto++* release
is published. When a certain number of fixes have been added, and depending on
the criticality of the defects, an additional release tag may be made. These
*patch tags* will never introduce any additional changes in `crypto++` itself.

Main release tags will have the format: `CRYPTOPP_M_m_p`, while *patch tags*
will have the format `CRYPTOPP_M_m_p_l`, where `M.m.p` represents the `crypto++`
version and `l` is a suffix letter incremented each time a *patch tag* is
created.

> As always, if you want to get the latest and greatest, always track the
master branch.

## Standard usage

- Get this project using your favorite method (clone as submodule, get with
  [FetchContent](https://cmake.org/cmake/help/latest/module/FetchContent.html),
  get with [CPM](https://github.com/cpm-cmake/CPM.cmake)...)

- In your master CMakeLists.txt, add the following:

  ```cmake
  add_subdirectory(xxxx)
  # where xxx is the location where you put the cryptopp-cmake files
  ```

  That's pretty much it. You'll be able to link against `cryptopp-shared` or
  `cryptopp-static` and have cmake handle everything else for you.

An example is located in the
[test/standard-cpm](https://github.com/abdes/cryptopp-cmake/tree/master/test)
directory.

## Using a local copy of crypto++

Certain users would prefer to have a fully disconnected project, and in such
scenario both the crypto++ source package and the cryptopp-cmake source package
would be pre-downloaded and then unpacked somewhere.

You would still need to add cryptopp-cmake as a subdirectory in your master
`CMakeLists.txt`, and you can set it up in such a way to use your local copy of
crypto++ via the option `CRYPTOPP_SOURCES`. Just set that option in the cmake
command line or in your CMakeLists.txt to point to the crypto++ source
directory. The rest will be taken care of for you.

## Requesting the master branch of cryptopp

If you want to test the bleeding edge of crypto++ with cmake, simply set the
option `CRYPTOPP_USE_MASTER_BRANCH` in your CMakeLists.txt or the cmake command
line and as usual, add the cryptopp-cmake as a subdirectory.

## Other ways

There are many other ways to use this project, including by directly picking the
files you need and adding them to your own project, by getting the package via
conan, etc... Take some time to read the source code, and make suggestions if
you need a new usage scenario via a new issue.

## Why Modern CMake?

Have a look at [Installing
CMake](https://cliutils.gitlab.io/modern-cmake/chapters/intro/installing.html)
from the online 'Modern CMake' book, to see a recent snapshot of which version
of CMake is being installed by default on Linux distributions.

![Packaging Status](https://repology.org/badge/vertical-allrepos/cmake.svg?columns=3&minversion=3.10.0)

And more than that, it's so easy to install a modern version of CMake on
Linux/MacOS/Windows, and many other OSes.

Looking at the release notes of CMake versions from 3.0 till now, a minimum
version requirement of
[3.21](https://cmake.org/cmake/help/latest/release/3.21.html) is a good starting
point. That release brings in particular presets and some nice quality of life
features that will make the maintenance and the use of this project much simpler
and pleasant. After all, there is no justification for doing free Open Source
without pleasure :smiley:

[build-matrix]: https://github.com/abdes/cryptopp-cmake/actions/workflows/cmake-build.yml?branch=develop
[build-status-develop-badge]: https://github.com/abdes/cryptopp-cmake/actions/workflows/cmake-build.yml/badge.svg?branch=develop
[build-status-master-badge]: https://github.com/abdes/cryptopp-cmake/actions/workflows/cmake-build.yml/badge.svg?branch=master
[commits]: https://github.com/abdes/cryptopp-cmake/commits
[last-commit-badge]: https://img.shields.io/github/last-commit/abdes/cryptopp-cmake
[latest-release]: https://github.com/abdes/cryptopp-cmake/releases/latest
[license-badge]: https://img.shields.io/github/license/abdes/cryptopp-cmake
[license]: https://opensource.org/licenses/BSD-3-Clause
[linux-badge]: https://img.shields.io/badge/OS-linux-blue
[macos-badge]: https://img.shields.io/badge/OS-macOS-blue
[release-badge]: https://img.shields.io/github/v/release/abdes/cryptopp-cmake
[windows-badge]: https://img.shields.io/badge/OS-windows-blue
