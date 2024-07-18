add_subdirectory(src)

set(builtin_target ${MBEDTLS_TARGET_PREFIX}builtin)

add_library(${builtin_target}
    src/aes.c
    src/aesni.c
    src/aesce.c
    src/aria.c
    src/asn1parse.c
    src/asn1write.c
    src/base64.c
    src/bignum.c
    src/bignum_core.c
    src/bignum_mod.c
    src/bignum_mod_raw.c
    src/block_cipher.c
    src/camellia.c
    src/ccm.c
    src/chacha20.c
    src/chachapoly.c
    src/cipher.c
    src/cipher_wrap.c
    src/constant_time.c
    src/cmac.c
    src/ctr_drbg.c
    src/des.c
    src/dhm.c
    src/ecdh.c
    src/ecdsa.c
    src/ecjpake.c
    src/ecp.c
    src/ecp_curves.c
    src/ecp_curves_new.c
    src/entropy.c
    src/entropy_poll.c
    src/error.c
    src/gcm.c
    src/hkdf.c
    src/hmac_drbg.c
    src/lmots.c
    src/lms.c
    src/md.c
    src/md5.c
    src/memory_buffer_alloc.c
    src/nist_kw.c
    src/oid.c
    src/pem.c
    src/pk.c
    src/pk_ecc.c
    src/pk_wrap.c
    src/pkcs12.c
    src/pkcs5.c
    src/pkparse.c
    src/pkwrite.c
    src/platform.c
    src/platform_util.c
    src/poly1305.c
    src/ripemd160.c
    src/rsa.c
    src/rsa_alt_helpers.c
    src/sha1.c
    src/sha256.c
    src/sha512.c
    src/sha3.c
    src/threading.c
    src/timing.c
    src/version.c
    src/version_features.c
)

if(GEN_FILES)
    find_package(Perl REQUIRED)

    file(GLOB crypto_error_headers ${CMAKE_CURRENT_SOURCE_DIR}/include/mbedtls/*.h)
    file(GLOB tls_error_headers ${MBEDTLS_DIR}/include/mbedtls/*.h)
    add_custom_command(
        OUTPUT
            ${CMAKE_CURRENT_BINARY_DIR}/src/error.c
        COMMAND
            ${PERL_EXECUTABLE}
                ${MBEDTLS_DIR}/scripts/generate_errors.pl
                ${CMAKE_CURRENT_SOURCE_DIR}/include/mbedtls
                ${MBEDTLS_DIR}/include/mbedtls
                ${MBEDTLS_DIR}/scripts/data_files
                ${CMAKE_CURRENT_BINARY_DIR}/src/error.c
        DEPENDS
            ${MBEDTLS_DIR}/scripts/generate_errors.pl
            ${crypto_error_headers}
            ${tls_error_headers}
            ${MBEDTLS_DIR}/scripts/data_files/error.fmt
    )

    add_custom_command(
        OUTPUT
            ${CMAKE_CURRENT_BINARY_DIR}/src/version_features.c
        COMMAND
            ${PERL_EXECUTABLE}
                ${MBEDTLS_DIR}/scripts/generate_features.pl
                ${MBEDTLS_DIR}/include/mbedtls
                ${MBEDTLS_DIR}/scripts/data_files
                ${CMAKE_CURRENT_BINARY_DIR}/src/version_features.c
        DEPENDS
            ${MBEDTLS_DIR}/scripts/generate_features.pl
            ${MBEDTLS_DIR}/include/mbedtls/mbedtls_config.h
            ${MBEDTLS_DIR}/scripts/data_files/version_features.fmt
    )
else()
    link_to_source(src/error.c)
    link_to_source(src/version_features.c)
endif()

target_include_directories(${builtin_target}
  PUBLIC $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
         $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
         $<BUILD_INTERFACE:${MBEDTLS_DIR}/include>
         $<BUILD_INTERFACE:${MBEDTLS_DIR}/tf-psa-crypto/include>
  PRIVATE ${MBEDTLS_DIR}/tf-psa-crypto/core)

install(TARGETS ${builtin_target}
EXPORT MbedTLSTargets
DESTINATION ${CMAKE_INSTALL_LIBDIR}
PERMISSIONS OWNER_READ OWNER_WRITE GROUP_READ WORLD_READ)
