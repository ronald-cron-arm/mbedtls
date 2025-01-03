# components-configuration-crypto.sh
#
# Copyright The Mbed TLS Contributors
# SPDX-License-Identifier: Apache-2.0 OR GPL-2.0-or-later

# This file contains test components that are executed by all.sh

################################################################
#### Configuration Testing - Crypto
################################################################

component_test_psa_assume_exclusive_buffers () {
    msg "build: full config + MBEDTLS_PSA_ASSUME_EXCLUSIVE_BUFFERS, cmake, gcc, ASan"
    scripts/config.py full
    scripts/config.py set MBEDTLS_PSA_ASSUME_EXCLUSIVE_BUFFERS

    CC=gcc cmake -D CMAKE_BUILD_TYPE:String=Asan .
    make

    msg "test: full config + MBEDTLS_PSA_ASSUME_EXCLUSIVE_BUFFERS, cmake, gcc, ASan"
    make test
}

component_test_crypto_with_static_key_slots() {
    msg "build: crypto full + MBEDTLS_PSA_STATIC_KEY_SLOTS"
    scripts/config.py crypto_full
    scripts/config.py set MBEDTLS_PSA_STATIC_KEY_SLOTS
    # Intentionally set MBEDTLS_PSA_STATIC_KEY_SLOT_BUFFER_SIZE to a value that
    # is enough to contain:
    # - all RSA public keys up to 4096 bits (max of PSA_VENDOR_RSA_MAX_KEY_BITS).
    # - RSA key pairs up to 1024 bits, but not 2048 or larger.
    # - all FFDH key pairs and public keys up to 8192 bits (max of PSA_VENDOR_FFDH_MAX_KEY_BITS).
    # - all EC key pairs and public keys up to 521 bits (max of PSA_VENDOR_ECC_MAX_CURVE_BITS).
    scripts/config.py set MBEDTLS_PSA_STATIC_KEY_SLOT_BUFFER_SIZE 1212
    # Disable the fully dynamic key store (default on) since it conflicts
    # with the static behavior that we're testing here.
    scripts/config.py unset MBEDTLS_PSA_KEY_STORE_DYNAMIC

    msg "test: crypto full + MBEDTLS_PSA_STATIC_KEY_SLOTS"
    CC=gcc cmake -D CMAKE_BUILD_TYPE:String=Asan .
    make
    ctest
}

# check_renamed_symbols HEADER LIB
# Check that if HEADER contains '#define MACRO ...' then MACRO is not a symbol
# name in LIB.
check_renamed_symbols () {
    ! nm "$2" | sed 's/.* //' |
      grep -x -F "$(sed -n 's/^ *# *define  *\([A-Z_a-z][0-9A-Z_a-z]*\)..*/\1/p' "$1")"
}

component_build_psa_crypto_spm () {
    msg "build: full config + PSA_CRYPTO_KEY_ID_ENCODES_OWNER + PSA_CRYPTO_SPM, make, gcc"
    scripts/config.py full
    scripts/config.py unset MBEDTLS_PSA_CRYPTO_BUILTIN_KEYS
    scripts/config.py set MBEDTLS_PSA_CRYPTO_KEY_ID_ENCODES_OWNER
    scripts/config.py set MBEDTLS_PSA_CRYPTO_SPM
    # We can only compile, not link, since our test and sample programs
    # aren't equipped for the modified names used when MBEDTLS_PSA_CRYPTO_SPM
    # is active.
    CC=gcc CFLAGS='-I./framework/tests/include/spe' cmake .
    make lib

    # Check that if a symbol is renamed by crypto_spe.h, the non-renamed
    # version is not present.
    echo "Checking for renamed symbols in the library"
    check_renamed_symbols framework/tests/include/spe/crypto_spe.h library/libmbedcrypto.a
}

component_test_no_rsa_key_pair_generation () {
    msg "build: default config minus PSA_WANT_KEY_TYPE_RSA_KEY_PAIR_GENERATE"
    scripts/config.py unset MBEDTLS_GENPRIME
    scripts/config.py unset PSA_WANT_KEY_TYPE_RSA_KEY_PAIR_GENERATE
    cmake .
    make

    msg "test: default config minus PSA_WANT_KEY_TYPE_RSA_KEY_PAIR_GENERATE"
    ctest
}

component_test_psa_inject_entropy () {
    msg "build: full + MBEDTLS_PSA_INJECT_ENTROPY"
    scripts/config.py full
    scripts/config.py set MBEDTLS_PSA_INJECT_ENTROPY
    scripts/config.py set MBEDTLS_ENTROPY_NV_SEED
    scripts/config.py set MBEDTLS_NO_DEFAULT_ENTROPY_SOURCES
    scripts/config.py unset MBEDTLS_PLATFORM_NV_SEED_ALT
    scripts/config.py unset MBEDTLS_PLATFORM_STD_NV_SEED_READ
    scripts/config.py unset MBEDTLS_PLATFORM_STD_NV_SEED_WRITE
    CC=$ASAN_CC cmake -D TF_PSA_CRYPTO_USER_CONFIG_FILE=../tests/configs/user-config-for-test.h -D CMAKE_BUILD_TYPE:String=Asan .
    make

    msg "test: full + MBEDTLS_PSA_INJECT_ENTROPY"
    make test
}

component_full_no_pkparse_pkwrite () {
    msg "build: full without pkparse and pkwrite"

    scripts/config.py crypto_full
    scripts/config.py unset MBEDTLS_PK_PARSE_C
    scripts/config.py unset MBEDTLS_PK_WRITE_C

    make CFLAGS="$ASAN_CFLAGS" LDFLAGS="$ASAN_CFLAGS"

    # Ensure that PK_[PARSE|WRITE]_C were not re-enabled accidentally (additive config).
    not grep mbedtls_pk_parse_key ${BUILTIN_SRC_PATH}/pkparse.o
    not grep mbedtls_pk_write_key_der ${BUILTIN_SRC_PATH}/pkwrite.o

    msg "test: full without pkparse and pkwrite"
    make test
}

component_test_crypto_full_md_light_only () {
    msg "build: crypto_full with only the light subset of MD"
    scripts/config.py crypto_full

    # Disable MD
    scripts/config.py unset MBEDTLS_MD_C
    # Disable direct dependencies of MD_C
    scripts/config.py unset MBEDTLS_HKDF_C
    scripts/config.py unset MBEDTLS_HMAC_DRBG_C
    scripts/config.py unset MBEDTLS_PKCS7_C
    # Disable indirect dependencies of MD_C
    scripts/config.py unset MBEDTLS_ECDSA_DETERMINISTIC # needs HMAC_DRBG
    scripts/config.py unset PSA_WANT_ALG_DETERMINISTIC_ECDSA
    # Disable things that would auto-enable MD_C
    scripts/config.py unset MBEDTLS_PKCS5_C

    # Note: MD-light is auto-enabled in build_info.h by modules that need it,
    # which we haven't disabled, so no need to explicitly enable it.
    make CC=$ASAN_CC CFLAGS="$ASAN_CFLAGS" LDFLAGS="$ASAN_CFLAGS"

    # Make sure we don't have the HMAC functions, but the hashing functions
    not grep mbedtls_md_hmac ${BUILTIN_SRC_PATH}/md.o
    grep mbedtls_md ${BUILTIN_SRC_PATH}/md.o

    msg "test: crypto_full with only the light subset of MD"
    make test
}

component_test_full_no_cipher () {
    msg "build: full no CIPHER"

    scripts/config.py full
    scripts/config.py unset MBEDTLS_CIPHER_C

    # The built-in implementation of the following algs/key-types depends
    # on CIPHER_C so we disable them.
    # This does not hold for KEY_TYPE_CHACHA20 and ALG_CHACHA20_POLY1305
    # so we keep them enabled.
    scripts/config.py unset PSA_WANT_ALG_CCM_STAR_NO_TAG
    scripts/config.py unset PSA_WANT_ALG_CMAC
    scripts/config.py unset PSA_WANT_ALG_CBC_NO_PADDING
    scripts/config.py unset PSA_WANT_ALG_CBC_PKCS7
    scripts/config.py unset PSA_WANT_ALG_CFB
    scripts/config.py unset PSA_WANT_ALG_CTR
    scripts/config.py unset PSA_WANT_ALG_ECB_NO_PADDING
    scripts/config.py unset PSA_WANT_ALG_OFB
    scripts/config.py unset PSA_WANT_ALG_PBKDF2_AES_CMAC_PRF_128
    scripts/config.py unset PSA_WANT_ALG_STREAM_CIPHER
    scripts/config.py unset PSA_WANT_KEY_TYPE_DES

    # The following modules directly depends on CIPHER_C
    scripts/config.py unset MBEDTLS_CMAC_C
    scripts/config.py unset MBEDTLS_NIST_KW_C

    make

    # Ensure that CIPHER_C was not re-enabled
    not grep mbedtls_cipher_init ${BUILTIN_SRC_PATH}/cipher.o

    msg "test: full no CIPHER"
    make test
}

component_test_config_symmetric_only () {
    msg "build: configs/config-symmetric-only.h"
    MBEDTLS_CONFIG="configs/config-symmetric-only.h"
    CRYPTO_CONFIG="configs/crypto-config-symmetric-only.h"
    CC=$ASAN_CC cmake -DMBEDTLS_CONFIG_FILE="$MBEDTLS_CONFIG" -DTF_PSA_CRYPTO_CONFIG_FILE="$CRYPTO_CONFIG" -D CMAKE_BUILD_TYPE:String=Asan .
    make

    msg "test: configs/config-symmetric-only.h - unit tests"
    make test
}

component_test_crypto_for_psa_service () {
  msg "build: make, config for PSA crypto service"
  scripts/config.py crypto
  scripts/config.py set MBEDTLS_PSA_CRYPTO_KEY_ID_ENCODES_OWNER
  # Disable things that are not needed for just cryptography, to
  # reach a configuration that would be typical for a PSA cryptography
  # service providing all implemented PSA algorithms.
  # System stuff
  scripts/config.py unset MBEDTLS_ERROR_C
  scripts/config.py unset MBEDTLS_TIMING_C
  scripts/config.py unset MBEDTLS_VERSION_FEATURES
  # Crypto stuff with no PSA interface
  scripts/config.py unset MBEDTLS_BASE64_C
  # Keep MBEDTLS_CIPHER_C because psa_crypto_cipher, CCM and GCM need it.
  scripts/config.py unset MBEDTLS_HKDF_C # PSA's HKDF is independent
  # Keep MBEDTLS_MD_C because deterministic ECDSA needs it for HMAC_DRBG.
  scripts/config.py unset MBEDTLS_NIST_KW_C
  scripts/config.py unset MBEDTLS_PEM_PARSE_C
  scripts/config.py unset MBEDTLS_PEM_WRITE_C
  scripts/config.py unset MBEDTLS_PKCS12_C
  scripts/config.py unset MBEDTLS_PKCS5_C
  # MBEDTLS_PK_PARSE_C and MBEDTLS_PK_WRITE_C are actually currently needed
  # in PSA code to work with RSA keys. We don't require users to set those:
  # they will be reenabled in build_info.h.
  scripts/config.py unset MBEDTLS_PK_C
  scripts/config.py unset MBEDTLS_PK_PARSE_C
  scripts/config.py unset MBEDTLS_PK_WRITE_C
  make CFLAGS='-O1 -Werror' all test
  are_empty_libraries library/libmbedx509.* library/libmbedtls.*
}

# This is an helper used by:
# - component_test_psa_ecc_key_pair_no_derive
# - component_test_psa_ecc_key_pair_no_generate
# The goal is to test with all PSA_WANT_KEY_TYPE_xxx_KEY_PAIR_yyy symbols
# enabled, but one. Input arguments are as follows:
# - $1 is the configuration to start from
# - $2 is the key type under test, i.e. ECC/RSA/DH
# - $3 is the key option to be unset (i.e. generate, derive, etc)
build_and_test_psa_want_key_pair_partial () {
    base_config=$1
    key_type=$2
    unset_option=$3
    disabled_psa_want="PSA_WANT_KEY_TYPE_${key_type}_KEY_PAIR_${unset_option}"

    msg "build: $base_config - ${disabled_psa_want}"
    scripts/config.py "$base_config"

    # All the PSA_WANT_KEY_TYPE_xxx_KEY_PAIR_yyy are enabled by default in
    # crypto_config.h so we just disable the one we don't want.
    scripts/config.py unset "$disabled_psa_want"

    make CC=$ASAN_CC CFLAGS="$ASAN_CFLAGS" LDFLAGS="$ASAN_CFLAGS"

    msg "test: $base_config - ${disabled_psa_want}"
    make test
}

component_test_psa_ecc_key_pair_no_derive () {
    build_and_test_psa_want_key_pair_partial full "ECC" "DERIVE"
}

component_test_psa_ecc_key_pair_no_generate () {
    # TLS needs ECC key generation whenever ephemeral ECDH is enabled.
    # We don't have proper guards for configurations with ECC key generation
    # disabled (https://github.com/Mbed-TLS/mbedtls/issues/9481). Until
    # then (if ever), just test the crypto part of the library.
    build_and_test_psa_want_key_pair_partial crypto_full "ECC" "GENERATE"
}

# This is a temporary test to verify that full RSA support is present even when
# only one single new symbols (PSA_WANT_KEY_TYPE_RSA_KEY_PAIR_BASIC) is defined.
component_test_new_psa_want_key_pair_symbol () {
    msg "Build: crypto config - MBEDTLS_RSA_C + PSA_WANT_KEY_TYPE_RSA_KEY_PAIR_BASIC"

    # Create a temporary output file unless there is already one set
    if [ "$MBEDTLS_TEST_OUTCOME_FILE" ]; then
        REMOVE_OUTCOME_ON_EXIT="no"
    else
        REMOVE_OUTCOME_ON_EXIT="yes"
        MBEDTLS_TEST_OUTCOME_FILE="$PWD/out.csv"
        export MBEDTLS_TEST_OUTCOME_FILE
    fi

    # Start from crypto configuration
    scripts/config.py crypto

    # Remove RSA support and its dependencies
    scripts/config.py unset MBEDTLS_PKCS1_V15
    scripts/config.py unset MBEDTLS_PKCS1_V21
    scripts/config.py unset MBEDTLS_KEY_EXCHANGE_DHE_RSA_ENABLED
    scripts/config.py unset MBEDTLS_KEY_EXCHANGE_ECDH_RSA_ENABLED
    scripts/config.py unset MBEDTLS_KEY_EXCHANGE_ECDHE_RSA_ENABLED
    scripts/config.py unset MBEDTLS_KEY_EXCHANGE_RSA_ENABLED
    scripts/config.py unset MBEDTLS_RSA_C
    scripts/config.py unset MBEDTLS_X509_RSASSA_PSS_SUPPORT

    # Keep only PSA_WANT_KEY_TYPE_RSA_KEY_PAIR_BASIC enabled in order to ensure
    # that proper translations is done in crypto_legacy.h.
    scripts/config.py unset PSA_WANT_KEY_TYPE_RSA_KEY_PAIR_IMPORT
    scripts/config.py unset PSA_WANT_KEY_TYPE_RSA_KEY_PAIR_EXPORT
    scripts/config.py unset PSA_WANT_KEY_TYPE_RSA_KEY_PAIR_GENERATE

    make

    msg "Test: crypto config - MBEDTLS_RSA_C + PSA_WANT_KEY_TYPE_RSA_KEY_PAIR_BASIC"
    make test

    # Parse only 1 relevant line from the outcome file, i.e. a test which is
    # performing RSA signature.
    msg "Verify that 'RSA PKCS1 Sign #1 (SHA512, 1536 bits RSA)' is PASS"
    cat $MBEDTLS_TEST_OUTCOME_FILE | grep 'RSA PKCS1 Sign #1 (SHA512, 1536 bits RSA)' | grep -q "PASS"

    if [ "$REMOVE_OUTCOME_ON_EXIT" == "yes" ]; then
        rm $MBEDTLS_TEST_OUTCOME_FILE
    fi
}

component_test_gcm_largetable () {
    msg "build: default config + GCM_LARGE_TABLE - AESNI_C - AESCE_C"
    scripts/config.py set MBEDTLS_GCM_LARGE_TABLE
    scripts/config.py unset MBEDTLS_AESNI_C
    scripts/config.py unset MBEDTLS_AESCE_C

    make CFLAGS='-O2 -Werror -Wall -Wextra'

    msg "test: default config - GCM_LARGE_TABLE - AESNI_C - AESCE_C"
    make test
}

component_test_aes_fewer_tables () {
    msg "build: default config with AES_FEWER_TABLES enabled"
    scripts/config.py set MBEDTLS_AES_FEWER_TABLES
    make CFLAGS='-O2 -Werror -Wall -Wextra'

    msg "test: AES_FEWER_TABLES"
    make test
}

component_test_aes_rom_tables () {
    msg "build: default config with AES_ROM_TABLES enabled"
    scripts/config.py set MBEDTLS_AES_ROM_TABLES
    make CFLAGS='-O2 -Werror -Wall -Wextra'

    msg "test: AES_ROM_TABLES"
    make test
}

component_test_aes_fewer_tables_and_rom_tables () {
    msg "build: default config with AES_ROM_TABLES and AES_FEWER_TABLES enabled"
    scripts/config.py set MBEDTLS_AES_FEWER_TABLES
    scripts/config.py set MBEDTLS_AES_ROM_TABLES
    make CFLAGS='-O2 -Werror -Wall -Wextra'

    msg "test: AES_FEWER_TABLES + AES_ROM_TABLES"
    make test
}

component_test_ctr_drbg_aes_256_sha_256 () {
    msg "build: full + MBEDTLS_ENTROPY_FORCE_SHA256 (ASan build)"
    scripts/config.py full
    scripts/config.py unset MBEDTLS_MEMORY_BUFFER_ALLOC_C
    scripts/config.py set MBEDTLS_ENTROPY_FORCE_SHA256
    CC=$ASAN_CC cmake -D CMAKE_BUILD_TYPE:String=Asan .
    make

    msg "test: full + MBEDTLS_ENTROPY_FORCE_SHA256 (ASan build)"
    make test
}

component_test_ctr_drbg_aes_128_sha_512 () {
    msg "build: full + MBEDTLS_CTR_DRBG_USE_128_BIT_KEY (ASan build)"
    scripts/config.py full
    scripts/config.py unset MBEDTLS_MEMORY_BUFFER_ALLOC_C
    scripts/config.py set MBEDTLS_CTR_DRBG_USE_128_BIT_KEY
    CC=$ASAN_CC cmake -D CMAKE_BUILD_TYPE:String=Asan .
    make

    msg "test: full + MBEDTLS_CTR_DRBG_USE_128_BIT_KEY (ASan build)"
    make test
}

component_test_ctr_drbg_aes_128_sha_256 () {
    msg "build: full + MBEDTLS_CTR_DRBG_USE_128_BIT_KEY + MBEDTLS_ENTROPY_FORCE_SHA256 (ASan build)"
    scripts/config.py full
    scripts/config.py unset MBEDTLS_MEMORY_BUFFER_ALLOC_C
    scripts/config.py set MBEDTLS_CTR_DRBG_USE_128_BIT_KEY
    scripts/config.py set MBEDTLS_ENTROPY_FORCE_SHA256
    CC=$ASAN_CC cmake -D CMAKE_BUILD_TYPE:String=Asan .
    make

    msg "test: full + MBEDTLS_CTR_DRBG_USE_128_BIT_KEY + MBEDTLS_ENTROPY_FORCE_SHA256 (ASan build)"
    make test
}

component_test_full_static_keystore () {
    msg "build: full config - MBEDTLS_PSA_KEY_STORE_DYNAMIC"
    scripts/config.py full
    scripts/config.py unset MBEDTLS_PSA_KEY_STORE_DYNAMIC
    make CC=clang CFLAGS="$ASAN_CFLAGS -Os" LDFLAGS="$ASAN_CFLAGS"

    msg "test: full config - MBEDTLS_PSA_KEY_STORE_DYNAMIC"
    make test
}

component_build_psa_config_file () {
    msg "build: make with TF_PSA_CRYPTO_CONFIG_FILE" # ~40s
    cp "$CRYPTO_CONFIG_H" psa_test_config.h
    echo '#error "TF_PSA_CRYPTO_CONFIG_FILE is not working"' >"$CRYPTO_CONFIG_H"
    make CFLAGS="-I '$PWD' -DTF_PSA_CRYPTO_CONFIG_FILE='\"psa_test_config.h\"'"
    # Make sure this feature is enabled. We'll disable it in the next phase.
    programs/test/query_compile_time_config MBEDTLS_CMAC_C
    make clean

    msg "build: make with TF_PSA_CRYPTO_CONFIG_FILE + TF_PSA_CRYPTO_USER_CONFIG_FILE" # ~40s
    # In the user config, disable one feature and its dependencies, which will
    # reflect on the mbedtls configuration so we can query it with
    # query_compile_time_config.
    echo '#undef PSA_WANT_ALG_CMAC' >psa_user_config.h
    echo '#undef PSA_WANT_ALG_PBKDF2_AES_CMAC_PRF_128' >> psa_user_config.h
    echo '#undef MBEDTLS_CMAC_C' >> psa_user_config.h
    make CFLAGS="-I '$PWD' -DTF_PSA_CRYPTO_CONFIG_FILE='\"psa_test_config.h\"' -DTF_PSA_CRYPTO_USER_CONFIG_FILE='\"psa_user_config.h\"'"
    not programs/test/query_compile_time_config MBEDTLS_CMAC_C

    rm -f psa_test_config.h psa_user_config.h
}

component_test_min_mpi_window_size () {
    msg "build: Default + MBEDTLS_MPI_WINDOW_SIZE=1 (ASan build)" # ~ 10s
    scripts/config.py set MBEDTLS_MPI_WINDOW_SIZE 1
    CC=$ASAN_CC cmake -D CMAKE_BUILD_TYPE:String=Asan .
    make

    msg "test: MBEDTLS_MPI_WINDOW_SIZE=1 - main suites (inc. selftests) (ASan build)" # ~ 10s
    make test
}
