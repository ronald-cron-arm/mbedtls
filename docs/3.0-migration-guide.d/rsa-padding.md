Remove the padding parameters from mbedtls_rsa_init()
-----------------------------------------------------

This affects all users who use the RSA encryption, decryption, sign and
verify APIs.

The function mbedtls_rsa_init() no longer supports selecting the PKCS#1 v2.1
encoding and its hash. It just selects the PKCS#1 v1.5 encoding by default. If
you were using the PKCS#1 v2.1 encoding you now need, subsequently to the call
to mbedtls_rsa_init(), to call mbedtls_rsa_set_padding() to set it.

Code migration examples:
```C
    mbedtls_rsa_init(ctx, padding, hash_id);
```
to
```C
    mbedtls_rsa_init(ctx);
    mbedtls_rsa_set_padding(ctx, padding, hash_id);
```
or
```C
    mbedtls_rsa_init(ctx, MBEDTLS_RSA_PKCS_V15, <ignored>);
```
to
```C
    mbedtls_rsa_init(ctx);
```

