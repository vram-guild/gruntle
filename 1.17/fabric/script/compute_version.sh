compute_minor_version () {
    # Update index
    git update-index -q --ignore-submodules --refresh
    ver=$(git rev-list HEAD --count)
    inc=0

    # Look for unstaged changes in the working tree
    if ! git diff-files --quiet --ignore-submodules --
    then
        inc=1
    fi

    # Look for uncommitted changes in the index
    if ! git diff-index --cached --quiet HEAD --ignore-submodules --
    then
        int=1
    fi

    ((ver=ver+inc))
    return "$ver"
}

compute_minor_version
minor_version=$?
echo ${minor_version}
