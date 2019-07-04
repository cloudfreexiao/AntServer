#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <openssl/conf.h>
#include <openssl/evp.h>
#include <openssl/err.h>


static int l_init(lua_State *L);
static int l_cleanup(lua_State *L);
static int l_encrypt(lua_State *L);
static int l_decrypt(lua_State *L);
static void init();
static void cleanup();
static int encrypt(unsigned char *plaintext, int plaintext_len, unsigned char *key,unsigned char *iv, unsigned char *ciphertext);
static int decrypt(unsigned char *ciphertext, int ciphertext_len, unsigned char *key,unsigned char *iv, unsigned char *plaintext);

static const struct luaL_Reg luaaes [] = {
	{"init", l_init},
	{"cleanup", l_cleanup},
	{"encrypt", l_encrypt},
	{"decrypt", l_decrypt},
    {NULL, NULL}
};

LUALIB_API int luaopen_aes_core(lua_State *L)
{
    luaL_Reg libs[] = {
        {"init", l_init},
        {"cleanup", l_cleanup},
        {"encrypt", l_encrypt},
        {"decrypt", l_decrypt},
        {NULL, NULL}
    };
    luaL_newlib(L, libs);
    return 1;
}


void init(void)
{

  /* Initialise the library */
    ERR_load_crypto_strings();
    OpenSSL_add_all_algorithms();
    OPENSSL_config(NULL);

}

void cleanup(void)
{

  /* Clean up */
    EVP_cleanup();
    ERR_free_strings();

}

int encrypt(unsigned char *plaintext, int plaintext_len, unsigned char *key,
  unsigned char *iv, unsigned char *ciphertext)
{
    EVP_CIPHER_CTX *ctx;

    int len;

    int ciphertext_len;

    /* Create and initialise the context */
    if(!(ctx = EVP_CIPHER_CTX_new())) return -1;

    if(1 != EVP_EncryptInit_ex(ctx, EVP_aes_128_cbc(), NULL, key, iv))
         return -1;

    if(1 != EVP_EncryptUpdate(ctx, ciphertext, &len, plaintext, plaintext_len))
         return -1;
    ciphertext_len = len;

    if(1 != EVP_EncryptFinal_ex(ctx, ciphertext + len, &len))
         return -1;

    ciphertext_len += len;

    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);

    return ciphertext_len;
}

int decrypt(unsigned char *ciphertext, int ciphertext_len, unsigned char *key,
  unsigned char *iv, unsigned char *plaintext)
{
    EVP_CIPHER_CTX *ctx;

    int len;

    int plaintext_len;
    /* Create and initialise the context */
    if(!(ctx = EVP_CIPHER_CTX_new()))
        return -1;

    if(1 != EVP_DecryptInit_ex(ctx, EVP_aes_128_cbc(), NULL, key, iv))
        return -1;

    if(1 != EVP_DecryptUpdate(ctx, plaintext, &len, ciphertext, ciphertext_len))
        return -1;
    plaintext_len = len;

    if(1 != EVP_DecryptFinal_ex(ctx, plaintext + len, &len))
        return -1;
    plaintext_len += len;

    EVP_CIPHER_CTX_free(ctx);

    return plaintext_len;
}

static int l_init(lua_State *L)
{

    init();
    return 0;
}

static int l_cleanup(lua_State *L)
{
    cleanup();
    return 0;
}

static int l_encrypt(lua_State *L)
{
    size_t pt_len=0;
    unsigned char* pt= (unsigned char*)lua_tolstring(L, 1,&pt_len);
    int ct_len=((pt_len&0xfffffffff80)+0x80);
    unsigned char* ct=(unsigned char*)malloc(ct_len);

    unsigned char* key= (unsigned char*)lua_tostring(L, 2);
    unsigned char* iv= (unsigned char*)lua_tostring(L, 3);
    ct_len=encrypt(pt,pt_len,key,iv,ct);
    if(ct_len>=0)
    {
        lua_pushnumber(L,0);
        lua_pushlstring(L,(const char*)ct,ct_len);
        free(ct);
        return 2;
    }
    else
    {
        free(ct);
        lua_pushnumber(L,-1);

        unsigned long l;
        char buf[256];
        l=ERR_get_error();
        ERR_error_string_n(l, buf, sizeof buf);
        lua_pushstring(L,buf);
        return 2;
    }
}

static int l_decrypt(lua_State *L)
{
    size_t ct_len=0;
    unsigned char* ct= (unsigned char*)lua_tolstring(L, 1,&ct_len);
    int pt_len=ct_len;
    unsigned char* pt=(unsigned char*)malloc(pt_len);


    unsigned char* key= (unsigned char*)lua_tostring(L, 2);
    unsigned char* iv= (unsigned char*)lua_tostring(L, 3);

    pt_len=decrypt(ct,ct_len,key,iv,pt);
    if(pt_len>=0)
    {
        lua_pushnumber(L,0);
        lua_pushlstring(L,(const char*)pt,pt_len);
        free(pt);
        return 2;
    }
    else
    {
        free(pt);
        lua_pushnumber(L,-1);

        unsigned long l;
        char buf[256];
        l=ERR_get_error();
        ERR_error_string_n(l, buf, sizeof buf);
        lua_pushstring(L,buf);
        return 2;
    }
}
