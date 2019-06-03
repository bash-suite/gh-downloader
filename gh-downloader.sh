#!/bin/sh

#
# Simple utility to download files from GitHub Repository.
#

readonly progname=$(basename $0)

# Display help message
function getHelp() {
    cat << USAGE >&2

Usage: $progname [user repo] [OPTIONS]

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
    $progname -u bash-suite -r wait-host -t latest -f wait-host.sh -o /usr/sbin/wait-host

    * Download the latest version of wait-host.sh from the master branch of bash-suite/wait-host
    * and save the file to /usr/sbin/wait-host
    $progname -u bash-suite -r wait-host -p ./ -b master -f wait-host.sh -o /usr/sbin/wait-host

    If no file is specified when using the path option, the content of the folder will be downloaded

USAGE
}

# Get input parameters
while [ $# -gt 0 ]; do
    #echo $1 $2
    case "$1" in

        [!-]* )
            [ -n "$user" -a -z "$repo" ] && repo=$1
            [ -z "$user" ] && user=$1
            shift 1
        ;;

        -u|--user)
            user="$2"
            [ -z "$user" ] && break
            shift 2
        ;;

        -u=*|--user=*)
            user=$(printf "%s" "$1" | cut -d = -f 2)
            [ -z "$user" ] && break
            shift 1
        ;;

        -r|--repo)
            repo="$2"
            [ -z "$repo" ] && break
            shift 2
        ;;

        -r=*|--repo=*)
            repo=$(printf "%s" "$1" | cut -d = -f 2)
            [ -z "$repo" ] && break
            shift 1
        ;;

        -T|--token)
            token="$2"
            shift 2
        ;;

        -T=*|--token=*)
            token=$(printf "%s" "$1" | cut -d = -f 2)
            shift 1
        ;;

        -t|--tag)
            tag="$2"
            shift 2
        ;;

        -t=*|--tag=*)
            tag=$(printf "%s" "$1" | cut -d = -f 2)
            shift 1
        ;;

        -p|--path)
            path="$2"
            shift 2
        ;;

        -p=*|--path=*)
            path=$(printf "%s" "$1" | cut -d = -f 2)
            shift 1
        ;;

        -b|--branch)
            branch="$2"
            shift 2
        ;;

        -b=*|--branch=*)
            branch=$(printf "%s" "$1" | cut -d = -f 2)
            shift 1
        ;;

        -f|--file)
            file="$2"
            shift 2
        ;;

        -f=*|--file=*)
            file=$(printf "%s" "$1" | cut -d = -f 2)
            shift 1
        ;;

        -o|--output)
            output="$2"
            shift 2
        ;;

        -o=*|--output=*)
            output=$(printf "%s" "$1" | cut -d = -f 2)
            shift 1
        ;;

        --help)
            getHelp
            exit 0
        ;;

        *)
            echo "Invalid argument '$1'. Use --help to see the valid options"
            exit 1
        ;;

    esac
done

# check for user and repo
if [ -z "$user" -o -z "$repo" ]; then
    echo "Invalid user or repo. Use --help to see the valid options."
    exit 2
fi

# Check installed softwares
cmdCurl=$(command -v curl >/dev/null 2>&1; echo $?)
cmdJq=$(command -v jq >/dev/null 2>&1; echo $?)

# curl must be installed: https://curl.haxx.se/
if [ $cmdCurl -ne 0 ]; then
    echo "In order to use '$progname' curl must be installed" 1>&2
    exit 1
fi

# js must be installed: https://stedolan.github.io/jq/
if [ $cmdJq -ne 0 ]; then
    echo "In order to use '$progname' jq must be installed" >&2
    exit 1
fi


function updateOutput() {
    # Default output to current directory
    output=${output:='.'}
    # Remove multiple /
    output=$(echo $output | tr -s /)
    # Make sure folder exist
    if [ "${output: -1}" = "/" ]; then
        mkdir -p $output
    else
        # Make sure folder exist
        mkdir -p $(dirname $output)
    fi
    # if ouput is a folder
    if [ "${output: -1}" = "/" -a -n "$file" ]; then
        # 
        echo "$output$file"
    else
        #
        echo $output
    fi
}

function updateTag() {
    if [ "$tag" = "latest" ]; then
        echo $(fromApi "releases/latest" | jq -r ".tag_name")
    else
        echo $tag
    fi
}

function updateBranch() {
    if [ -z "$branch" ]; then
        echo $(fromApi "" | jq -r ".default_branch")
    else
        echo $branch
    fi
}

function fromApi() {
    # Github API
    api='https://api.github.com'
    #
    curl    ${token:+ -H "Authorization: token $token"} \
            ${HTTP_PROXY:+ -x $HTTP_PROXY} \
            -s \
            $api/repos/$user/$repo${1:+/"$1"}
}

# ##############################################################################
# Download file from url
#   $1: url of the file
#   $2: output of the file
# If the output is a directory, the filename is extracted from the url
# ##############################################################################
function downloadFile() {
    # Get the url file to download
    # and the output
    if [ $# -ne 2 ]; then
        return 1
    fi

    _url=$1     # Temporary url
    _out=$2     # Temporary output

    if [ "${_out: -1}" = "/" ]; then
        _out=$(echo $_out/${_url##*/} | tr -s /)
    fi

    echo "Downloading ${_out#$output}..."
    curl    "$_url" \
            ${HTTP_PROXY:+ -x $HTTP_PROXY} \
            -s \
            -L \
            --output "$_out"
}

# Update tag version
[ -n "$tag" ] && tag=$(updateTag)

# Update Branch
[ -z "$tag" ] && branch=$(updateBranch)

# Download file from tag/release
if [ -n "$tag" -a -n "$file" ]; then
    echo "Download $file from $tag"
    # Output
    out=$(updateOutput)
    # Url to downloadFile
    url=$(fromApi "releases" | jq -r ". | map(select(.tag_name == \"$tag\"))[0].assets | map(select(.name == \"$file\"))[0] | .browser_download_url")
    # Download
    downloadFile "$url" "$out"

# Download all files from tag/release
elif [ -n "$tag" ]; then
    echo "Download all files from $tag"
    # Output
    out=$(updateOutput)
    # Url to download
    urls=$(fromApi "releases" | jq -r ". | map(select(.tag_name == \"$tag\"))[0].assets | map(.browser_download_url)[]")
    # Download
    for _url in $urls; do
        downloadFile "$_url" "$out" &
    done
    wait

# Download file from branch
elif [ -n "$file" ]; then
    echo "Download $file from $branch"
    # Output
    out=$(updateOutput)
    # Url to downloadFile
    url="https://raw.githubusercontent.com/$user/$repo/$branch/${path:+"$path"/}$file"
    # Download
    downloadFile "$url" "$out"

# Download all files from branch
else
    [ -n "$path" ] && echo "Download all files from $branch/$path" || echo "Download all files from $branch"
    # Output
    out=$(updateOutput)
    # json data from github API
    json=$(fromApi "git/trees/$branch?recursive=1")
    # Create folder structure
    dirs=$(echo $json | jq -r ". | .tree | map(select(.type == \"tree\"))[] | select(.path | startswith(\"$path\")) | .path")
    for _dir in $dirs; do
        # remove path from dir
        _dir=$(echo $out/${_dir#$path} | tr -s /)
        #create folders
        mkdir -p "$_dir" &
    done
    wait
    # Download files
    files=$(echo $json | jq -r ". | .tree | map(select(.type != \"tree\"))[] | select(.path | startswith(\"$path\")) | .path")
    for _file in $files; do
        # Get file name and url
        url="https://raw.githubusercontent.com/$user/$repo/$branch/$_file"
        # remove path from file
        _file=$(echo $out/${_file#$path} | tr -s /)
        # Download
        downloadFile "$url" "$_file" &
    done
    wait
fi
