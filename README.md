# ![](https://github.com/docker-suite/artwork/raw/master/logo/png/logo_32.png) gh-downloader
![License: MIT](https://img.shields.io/github/license/docker-suite/goss.svg?color=green&style=flat-square)

Simple utility to download files from GitHub Repository

## ![](https://github.com/docker-suite/artwork/raw/master/various/pin/png/pin_16.png) Usage

```sh
Usage: gh-downloader.sh [user repo] [OPTIONS]

    -u | --user         Github user olding the repository
    -r | --repo         Github repository
    -T | --token        Github token
    -t | --tag          tag to download (Use latest to download the latest tag)
    -p | --path         Path containing the file to download
    -b | --branch       Branch containing the file to download
    -f | --file         File from tag or path to download
    -o | --output       Output file or folder

Alternatively, you can specify the user and the repo in the right order.

Examples:
    * Download the latest version of wait-host.sh from bash-suite/wait-host and save the file to /usr/sbin/wait-host
    gh-downloader.sh -u bash-suite -r wait-host -t latest -f wait-host.sh -o /usr/sbin/wait-host

    * Download the latest version of wait-host.sh from the master branch of bash-suite/wait-host
    * and save the file to /usr/sbin/wait-host
    gh-downloader.sh -u bash-suite -r wait-host -p ./ -b master -f wait-host.sh -o /usr/sbin/wait-host

    If no file is specified when using the path option, the content of the folder will be downloaded
```

## ![](https://github.com/docker-suite/artwork/raw/master/various/pin/png/pin_16.png) GitHub token

If you don't want to face a [Github rate limit](https://developer.github.com/v3/rate_limit/) use a personnal token:

```sh
export MYTOKEN="13546843257517438573"

./gh-downloader.sh -t $MYTOKEN -u bash-suite -r wait-host -t latest -f wait-host.sh -o /usr/sbin/wait-host
```

Get a GitHub personal token from here:  [github.com/settings/tokens](github.com/settings/tokens)
