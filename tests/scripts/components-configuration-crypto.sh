# components-configuration-crypto.sh
#
# Copyright The Mbed TLS Contributors
# SPDX-License-Identifier: Apache-2.0 OR GPL-2.0-or-later

# This file contains test components that are executed by all.sh

################################################################
#### Configuration Testing - Crypto
################################################################

support_ubuntu_version() {
    version="$(cat /etc/os-release 2>/dev/null)" || return 1
    [[ "$version" == *$1* ]]
}

common_test_ctags() {
    ctags --version
    echo "==================="
    ctags --list-kinds=C
    echo "==================="
    ctags -x --language-force=C --c-kinds=defgpstuv ./library/debug.c
}

component_test_ctags_ubuntu_16() {
    msg "test_ctags_ubuntu_16"
    common_test_ctags
}
support_test_ctags_ubuntu_16() {
    support_ubuntu_version "Ubuntu 16"
}

component_test_ctags_ubuntu_18() {
    msg "test_ctags_ubuntu_18"
    common_test_ctags
}
support_test_ctags_ubuntu_18() {
    support_ubuntu_version "Ubuntu 18"
}

component_test_ctags_ubuntu_22() {
    msg "test_ctags_ubuntu_22"
    common_test_ctags
}
support_test_ctags_ubuntu_22() {
    support_ubuntu_version "Ubuntu 22"
}
