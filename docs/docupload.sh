#!/usr/bin/env bash
## @file
## @brief  Upload the generated documentation to the github pages doc site
## for the author
##
## @author Johan Persson <johan162@gmail.com>
## @copyright MIT License. See LICENSE file.
set -u

## @brief Specifies the user for github.
##
## This user name dictates the path
## to the repo as well as the github pages site. The default value here `johan162`
## corresponds to the authors github account and as such this script will not work
## without modification for anyone else since the github repos do not have world write
## permissions.
declare -r GITHUB_USER="johan162"

## @brief Specifies the package name. Used to construct the PDF name for the manual.
declare -r PACKAGE_NAME="mptools"

## @brief Defines the version number.
declare -r VERSION=$(grep DIST_VERSION ../Makefile | head -1 | awk '{printf "v" $3 }')

## @brief The variant of the version number used for documentation
declare -r DOCVERSION="${VERSION}"

## @brief The full PDF name.
declare -r PDFNAME="${PACKAGE_NAME}_manual.pdf"

## @brief The git commit message for the doc update.
declare -r COMMIT_MESSAGE="Documentation update for ${PACKAGE_NAME} ${DOCVERSION}"

## @brief The full URL for the github pages.
declare -r GITHUB_PAGES_URL="git@github.com:${GITHUB_USER}/${GITHUB_USER}.github.io.git"

## @brief The repo that corresponds to these pages.
declare -r GITHUB_PAGES_REPO="${GITHUB_USER}.github.io"

## @brief The directory of HTML files to copy to the github pages.
declare -r HTMLDIR_COPY="/docs/out/html"

## @brief The PDF file to copy to the github pages.
##
## Note that the name is fixed by Doxygen to `refman.pdf`
## and is renamed to PDFNAME in the copying process.
declare -r PDFFILE_COPY="/docs/out/latex/refman.pdf"

## The original directory from where this script is run.
declare -r ORIG_DIR="${PWD}"

# Don't make modifications beyond this point

## @brief Suppress output
declare -i quiet_flag=0
# User information
# Arg 1: Info text to display
infolog() {
    [ $quiet_flag -eq 0 ] && printf "Info: %s\n" "$1"
}

# User information
# Arg 1: Info text to display
errlog() {
    [ $quiet_flag -eq 0 ] && printf "***ERROR***: %s\n" "$1" >&2
}

# Print usage
# Arg 1: name of script
usage() {
    declare name
    name=$(basename "$0")
    cat <<EOT
    NAME
       $name - Update documentation on github pages for mptools
    USAGE
       $name [-v] [-h] [-q]
    SYNOPSIS
          -v        : Print version and exit
          -h        : Print help and exit
          -q        : Quiet, no output
EOT
}

# Upload documentation
docupload() {

    # Sanity check to check if script is rung from top directory or one below
    [ -d "docs" ] && PACKAGE_BASEDIR="${PWD}"
    [ -d "../docs" ] && PACKAGE_BASEDIR="${PWD}/.."
    [ -z $PACKAGE_BASEDIR ] && errlog "Please run from package top directory" && exit 1

    # Seed with current process-id and create a random named directory for checkout
    RANDOM=$$
    co_dir="/tmp/io${RANDOM}${RANDOM}"
    echo $co_dir
    mkdir "${co_dir}"
    cd "${co_dir}" || exit 1

    # Checkout a copy of the wiki pages in this directory
    git clone "${GITHUB_PAGES_URL}"
    cd "${GITHUB_PAGES_REPO}/${PACKAGE_NAME}" || exit 1

    # Replace the documentation. Start by deleting the old docs
    for f in ${HTMLDIR_COPY}; do
        # Delete the basename of HTML dirs
        rm -rf "${f##*/}"
    done

    cp -r ${PACKAGE_BASEDIR}${HTMLDIR_COPY} .
    if [ $? -eq 0 ]; then
        infolog "Copied ${PACKAGE_BASEDIR}${HTMLDIR_COPY} to ${PWD}"
    else
        errlog "Could NOT copy ${PACKAGE_BASEDIR}${HTMLDIR_COPY} to ${PWD}"
        exit 1
    fi

    cp -r ${PACKAGE_BASEDIR}${PDFFILE_COPY} ${PDFNAME}
    if [ $? -eq 0 ]; then
        infolog "Copied ${PACKAGE_BASEDIR}${PDFFILE_COPY} to ${PWD}/${PDFNAME}"
    else
        errlog "Could NOT copy ${PACKAGE_BASEDIR}${PDFFILE_COPY} to ${PWD}/${PDFNAME}"
        exit 1
    fi

    # Update and push
    # infolog "git add \"${HTMLDIR_COPY##*/}\" \"${PDFNAME}\""
    # infolog "git commit -m \"${COMMIT_MESSAGE}\""
    git add "${HTMLDIR_COPY##*/}" "${PDFNAME}"
    if git commit -m "${COMMIT_MESSAGE}"; then
        git push && infolog "Pushed docs to origin" || errlog "Failed to push to origin"
    else
        errlog "Failed to commit new docs"
    fi

    # Clean up temp directory
    cd "${ORIG_DIR}" || exit 1
    rm -rf "${co_dir}" && infolog "Deleted ${co_dir}"
}

# Parse options and run program
while [[ $OPTIND -le "$#" ]]; do
    if getopts qvh option; then
        case $option in
            h)
                usage "$(basename $0)"
                exit 0
                ;;
            q)
                quiet_flag=1
                ;;
            v)
                echo "${VERSION}"
                exit 0
                ;;
            [?])
                usage "$(basename $0)"
                exit 1
                ;;
        esac
    fi
done

# Do the work
docupload

# EOF
