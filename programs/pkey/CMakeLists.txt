set(executables_1
    dh_client
    dh_server
)

foreach(exe IN LISTS executables_1)
    add_executable(${exe} ${exe}.c)
    target_link_libraries(${exe} mbedtls)
endforeach()

set(executables_2
    dh_genprime
    ecdh_curve25519
    ecdsa
    gen_key
    key_app
    key_app_writer
    mpi_demo
    pk_encrypt
    pk_decrypt
    pk_sign
    pk_verify
    rsa_decrypt
    rsa_encrypt
    rsa_genkey
    rsa_sign
    rsa_sign_pss
    rsa_verify
    rsa_verify_pss
)

foreach(exe IN LISTS executables_2)
    add_executable(${exe} ${exe}.c)
    target_link_libraries(${exe} mbedcrypto)
endforeach()

install(TARGETS ${executables_1} ${executables_2}
        DESTINATION "bin"
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE)
