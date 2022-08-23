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

This repository contains CMake files for Wei Dai's Crypto++
(<https://github.com/weidai11/cryptopp>)for those who want to use CMake. CMake
is officialy unsupported by the crypto++ maintainers, so use it at your own
risk.

The purpose of Crypto++ CMake is three-fold:

1. better support Linux distributions, like Gentoo
2. provide users with centrally maintained CMake project files to easily
   integrate crypto++ in projects that use cmake as their build system
3. beter support package maintainers for depency management tools such as conan,
   etc.

This project releases track the [crypto++](https://github.com/weidai11/cryptopp)
releases. In other words, everytime a new release of *crypto++* happens, this
project gets updated to take into account changes in source files, compiler
options etc, and will see a new release with the same number than *cryupto++*.

At times, bug fixes in this project will happen before a new *crypto++* release
is published. If you want to get the latest and greatest, always track the
master branch.

## Standard Usage

* Get this project using your favorite method (clone as submodule, get with
  [FetchContent](https://cmake.org/cmake/help/latest/module/FetchContent.html),
  get with [CPM](https://github.com/cpm-cmake/CPM.cmake)...)

* In your master CMakeLists.txt, add the following:

  ```cmake
  add_subdirectory(xxxx) # where xxx is the location where you put the cryptopp-cmake files
  ```

  That's it pretty much it. You'll be able to link against `cryptopp-shared` or
  `cryptopp-static` and have cmake handle everything else for you.

An example is located in the test/standard-cpm directory.

## Using a local copy of crypto++

Certain users would prefer to have a fully disconnected project, and in such
scenario both the cypto++ source package and the cryptopp-cmake source package
would be pre-downloaded and then unpacked somewhere.

You would still need to add cryptopp-cmake as a subdirectory in your master
`CMakeLists.txt`, and you can set it up in such a way to use your local copy of
crypto++ via the option `CRYPTOPP_SOURCES`. Just set that option in the cmake
command line or in your CMakeLists.txt to point to the crypto++ source
directory. The rest will be taken care of for you.

## Using the latest crypto++ from the master branch

If you want to test the bleeding edge of crypto++ with cmake, simply set the
option `CRYPTOPP_USE_MASTER_BRANCH` in your CMakeLists.txt or the cmake command
line and as usual, add the cryptopp-cmake as a subdirectory.

## Other ways

There are many other ways to use this project, including by directly picking the
files you need and adding them to your own project, by getting the package via
conan, etc... Take some time to read the source code, and make suggestions if
you need a new usage scenario via a new issue.

## Documentation

Additional (historical) documenation is located on the [Crypto++ wiki |
CMake](https://www.cryptopp.com/wiki/CMake). If there is an error or ommission
in the wiki article, then please fix it or open a bug report.

## Testing

Testing is integrated into the project and is automated via `ctest`.

## Collaboration

We would like all distro maintainers to be collaborators on this repo. If you
are a distro maintainer then please contact us so we can send you an invite.

If you are a collaborator then make changes as you see fit. You don't need to
ask for permission to make a change. Noloader is not an CMake expert so there
are probably lots of opportunities for improvement.

Keep in mind other distros may be using the files, so try not to break things
for the other guy. We have to be mindful of lesser-used platforms and compilers,
like AIX, Solaris, IBM xlC and Oracle's SunCC.

## Conventional commits/changelog

The project is setup for husky and [conventional
commits](https://www.conventionalcommits.org/en/v1.0.0/) to keep some standard
for the commit messages and [conventional
changelog](https://github.com/conventional-changelog/standard-version) to
automatically generate change logs.

 In order to be able to use that, have `nodejs` and `npm` installed in your
environment and run the following just one time after you clone this project:

```shell
npx husky install
npm install -g @commitlint/cli @commitlint/config-conventional standard-version
```

Commit message are linted automatically.

## New release process

For changelog generation, when the project is ready for a new release, run the
following command in the project root, where M.m.p is version number to be
released:

```shell
npx standard-version --skip.commit --skip.tag -r M.m.p
```

The version number will be automatically bumped in the `CMakeLists.txt` and the
`CHANGELOG.md` file will be automatically updated. Open both of them, check the
changes, lint and format the `CHANGELOG.md` and write any additional notes, then
commit.

Create a new tag for the release by using the following command:

```shell
git tag -a CRYPTOPP_M_m_p -m "Blah blah blah..."
```

> :warning: **Pay attention to the format of the tag**: the version uses `_` and
> not `.`!

Push with the following command:

```shell
git push --follow-tags
```

The automatic GitHub actions will take care of the rest, including the
multi-platform builds, the testings, and when everything is successful, the
creation of a release and its associated artifacts.

Check the page at [GitHub
Actions](https://github.com/noloader/cryptopp-cmake/actions) for the details,
and the page at [GitHub
Releases](https://github.com/noloader/cryptopp-cmake/releases) for the newly
created release.

[build-matrix]: https://github.com/noloader/cryptopp-cmake/actions/workflows/cmake-build.yml?branch=develop
[build-status-develop-badge]: https://github.com/noloader/cryptopp-cmake/actions/workflows/cmake-build.yml/badge.svg?branch=develop
[build-status-master-badge]: https://github.com/noloader/cryptopp-cmake/actions/workflows/cmake-build.yml/badge.svg?branch=master
[commits]: https://github.com/noloader/cryptopp-cmake/commits
[last-commit-badge]: https://img.shields.io/github/last-commit/noloader/cryptopp-cmake
[latest-release]: https://github.com/noloader/cryptopp-cmake/releases/latest
[license-badge]: https://img.shields.io/github/license/noloader/cryptopp-cmake
[license]: https://opensource.org/licenses/BSD-3-Clause
[linux-badge]: https://img.shields.io/badge/OS-linux-blue
[macos-badge]: https://img.shields.io/badge/OS-macOS-blue
[release-badge]: https://img.shields.io/github/v/release/noloader/cryptopp-cmake
[windows-badge]: https://img.shields.io/badge/OS-windows-blue
