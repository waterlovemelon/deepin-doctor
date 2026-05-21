#include "common.h"
#include "dkfile.h"
#include "dkkey.h"
#include "dklog.h"

#include <errno.h>
#include <pwd.h>
#include <stdbool.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>
#include <gcrypt.h>

#define KEYRING_FILE_HEADER "GnomeKeyring\n\r\0\n"
#define KEYRING_FILE_HEADER_LEN 16

typedef struct {
    const uint8_t *data;
    size_t length;
    size_t offset;
} Buffer;

typedef struct {
    uint32_t iterations;
    uint8_t salt[8];
    const uint8_t *encrypted;
    size_t encrypted_len;
} CryptoInfo;

typedef enum {
    PASSWORD_MODE_WHITEBOX = 0,
    PASSWORD_MODE_USER,
} PasswordMode;

static void set_failure_detail(char **detail, const char *fmt, ...)
{
    if (detail == NULL) {
        return;
    }
    va_list ap;
    va_start(ap, fmt);
    char buffer[512];
    vsnprintf(buffer, sizeof(buffer), fmt, ap);
    va_end(ap);

    char *message = strdup(buffer);
    if (message == NULL) {
        return;
    }
    if (*detail != NULL) {
        free(*detail);
    }
    *detail = message;
}

static void print_usage(void)
{
    printf("Usage: wb-keyring-check [options]\n");
    printf("Options:\n");
    printf("  --help                 Show this help\n");
    printf("  --user=<name>          Specify user (default: current user)\n");
    printf("  --keyring-path=<path>  Full path to login.keyring\n");
    printf("  --print-masterkey      Print decrypted master key for debugging\n");
    printf("  --password-mode=<mode> Choose password source: whitebox (default) or user\n");
    printf("                          User mode reads the password from WB_USER_PASSWORD\n");
    printf("                          or from stdin.\n");
}

static bool read_line(FILE *stream, char **out)
{
    if (stream == NULL || out == NULL) {
        return false;
    }
    size_t capacity = 64;
    size_t length = 0;
    char *buffer = malloc(capacity);
    if (buffer == NULL) {
        return false;
    }
    int ch = 0;
    while ((ch = fgetc(stream)) != EOF) {
        if (ch == '\n') {
            break;
        }
        if (length + 1 >= capacity) {
            size_t new_capacity = capacity * 2;
            char *tmp = realloc(buffer, new_capacity);
            if (tmp == NULL) {
                free(buffer);
                return false;
            }
            capacity = new_capacity;
            buffer = tmp;
        }
        buffer[length++] = (char)ch;
    }
    if (ch == EOF && length == 0) {
        if (ferror(stream)) {
            free(buffer);
            return false;
        }
        buffer[0] = '\0';
        *out = buffer;
        return true;
    }
    buffer[length] = '\0';
    while (length > 0 && buffer[length - 1] == '\r') {
        buffer[--length] = '\0';
    }
    *out = buffer;
    return true;
}

static bool read_user_password(char **password)
{
    if (password == NULL) {
        return false;
    }
    const char *env_pw = getenv("WB_USER_PASSWORD");
    if (env_pw != NULL) {
        char *dup = strdup(env_pw);
        if (dup == NULL) {
            return false;
        }
        *password = dup;
        return true;
    }
    bool stdin_is_tty = isatty(STDIN_FILENO);
    if (stdin_is_tty) {
        fprintf(stderr, "Enter user password: ");
        fflush(stderr);
    }
    char *line = NULL;
    if (!read_line(stdin, &line)) {
        if (stdin_is_tty) {
            fprintf(stderr, "\n");
        }
        return false;
    }
    if (stdin_is_tty) {
        fprintf(stderr, "\n");
    }
    *password = line;
    return true;
}

static bool buffer_read(Buffer *buffer, void *dst, size_t len)
{
    if (buffer->offset > buffer->length || len > buffer->length - buffer->offset) {
        return false;
    }
    if (dst != NULL) {
        memcpy(dst, buffer->data + buffer->offset, len);
    }
    buffer->offset += len;
    return true;
}

static bool buffer_read_uint32(Buffer *buffer, uint32_t *value)
{
    uint8_t tmp[4];
    if (!buffer_read(buffer, tmp, sizeof(tmp))) {
        return false;
    }
    if (value != NULL) {
        *value = ((uint32_t)tmp[0] << 24) | ((uint32_t)tmp[1] << 16) | ((uint32_t)tmp[2] << 8) | (uint32_t)tmp[3];
    }
    return true;
}

static bool buffer_skip(Buffer *buffer, size_t len)
{
    return buffer_read(buffer, NULL, len);
}

static bool buffer_skip_string(Buffer *buffer)
{
    uint32_t len = 0;
    if (!buffer_read_uint32(buffer, &len)) {
        return false;
    }
    if (len == 0xffffffff) {
        return true;
    }
    if (len >= 0x7fffffff) {
        return false;
    }
    return buffer_skip(buffer, len);
}

static bool buffer_skip_time(Buffer *buffer)
{
    return buffer_skip(buffer, 8);
}

static bool buffer_skip_attributes(Buffer *buffer, char **detail)
{
    uint32_t list_size = 0;
    if (!buffer_read_uint32(buffer, &list_size)) {
        set_failure_detail(detail, "parse error: truncated attribute list size");
        return false;
    }
    for (uint32_t i = 0; i < list_size; i++) {
        if (!buffer_skip_string(buffer)) {
            set_failure_detail(detail, "parse error: truncated attribute[%u] name", i);
            return false;
        }
        uint32_t type = 0;
        if (!buffer_read_uint32(buffer, &type)) {
            set_failure_detail(detail, "parse error: truncated attribute[%u] type", i);
            return false;
        }
        if (type == 0) {
            if (!buffer_skip_string(buffer)) {
                set_failure_detail(detail, "parse error: truncated attribute[%u] string value", i);
                return false;
            }
        } else if (type == 1) {
            if (!buffer_skip(buffer, 4)) {
                set_failure_detail(detail, "parse error: truncated attribute[%u] integer hash", i);
                return false;
            }
        } else {
            set_failure_detail(detail, "parse error: attribute[%u] type %u unsupported", i, type);
            return false;
        }
    }
    return true;
}

static bool buffer_skip_hashed_items(Buffer *buffer, uint32_t count, char **detail)
{
    for (uint32_t i = 0; i < count; i++) {
        if (!buffer_skip(buffer, 4)) { // id
            set_failure_detail(detail, "parse error: truncated hashed item[%u] id", i);
            return false;
        }
        if (!buffer_skip(buffer, 4)) { // type
            set_failure_detail(detail, "parse error: truncated hashed item[%u] type", i);
            return false;
        }
        if (!buffer_skip_attributes(buffer, detail)) {
            return false;
        }
    }
    return true;
}

static bool parse_crypto_info(const uint8_t *data, size_t length, CryptoInfo *info, char **detail)
{
    if (length < KEYRING_FILE_HEADER_LEN) {
        set_failure_detail(detail, "parse error: file shorter than header (%zu bytes)", length);
        return false;
    }
    if (memcmp(data, KEYRING_FILE_HEADER, KEYRING_FILE_HEADER_LEN) != 0) {
        set_failure_detail(detail, "parse error: invalid header magic");
        return false;
    }
    Buffer buffer = {
        .data = data,
        .length = length,
        .offset = KEYRING_FILE_HEADER_LEN,
    };

    if (!buffer_skip(&buffer, 4)) { // version/crypto/hash
        set_failure_detail(detail, "parse error: truncated version/crypto/hash fields");
        return false;
    }
    if (!buffer_skip_string(&buffer)) {
        set_failure_detail(detail, "parse error: truncated keyring name");
        return false;
    }
    if (!buffer_skip_time(&buffer)) {
        set_failure_detail(detail, "parse error: truncated creation time");
        return false;
    }
    if (!buffer_skip_time(&buffer)) {
        set_failure_detail(detail, "parse error: truncated modification time");
        return false;
    }
    if (!buffer_skip(&buffer, 4)) { // flags
        set_failure_detail(detail, "parse error: truncated flags");
        return false;
    }
    if (!buffer_skip(&buffer, 4)) { // lock timeout
        set_failure_detail(detail, "parse error: truncated lock timeout");
        return false;
    }
    if (!buffer_read_uint32(&buffer, &info->iterations)) {
        set_failure_detail(detail, "parse error: truncated iteration count");
        return false;
    }
    if (info->iterations == 0) {
        set_failure_detail(detail, "parse error: invalid iteration count 0");
        return false;
    }
    if (!buffer_read(&buffer, info->salt, sizeof(info->salt))) {
        set_failure_detail(detail, "parse error: truncated salt");
        return false;
    }
    if (!buffer_skip(&buffer, 16)) { // reserved
        set_failure_detail(detail, "parse error: truncated reserved block");
        return false;
    }
    uint32_t num_items = 0;
    if (!buffer_read_uint32(&buffer, &num_items)) {
        set_failure_detail(detail, "parse error: truncated item count");
        return false;
    }
    if (!buffer_skip_hashed_items(&buffer, num_items, detail)) {
        return false;
    }
    uint32_t crypto_size = 0;
    if (!buffer_read_uint32(&buffer, &crypto_size)) {
        set_failure_detail(detail, "parse error: truncated encrypted payload size");
        return false;
    }
    if (crypto_size == 0 || crypto_size % 16 != 0) {
        set_failure_detail(detail, "parse error: invalid encrypted size %u", crypto_size);
        return false;
    }
    if (crypto_size > buffer.length - buffer.offset) {
        set_failure_detail(detail, "parse error: truncated encrypted payload, need %u bytes have %zu", crypto_size, buffer.length - buffer.offset);
        return false;
    }
    info->encrypted = buffer.data + buffer.offset;
    info->encrypted_len = crypto_size;
    return true;
}

static bool derive_key_iv(const char *password, const uint8_t *salt, size_t salt_len, uint32_t iterations, uint8_t key[16], uint8_t iv[16])
{
    gcry_md_hd_t md;
    if (gcry_md_open(&md, GCRY_MD_SHA256, 0) != 0) {
        return false;
    }

    uint8_t digest[32];
    uint8_t prev[32];
    size_t needed_key = 16;
    size_t needed_iv = 16;
    size_t key_pos = 0;
    size_t iv_pos = 0;
    size_t password_len = password ? strlen(password) : 0;

    memset(prev, 0, sizeof(prev));
    while (needed_key > 0 || needed_iv > 0) {
        gcry_md_reset(md);
        if (key_pos + iv_pos > 0) {
            gcry_md_write(md, prev, sizeof(prev));
        }
        if (password_len > 0) {
            gcry_md_write(md, password, password_len);
        }
        if (salt && salt_len > 0) {
            gcry_md_write(md, salt, salt_len);
        }
        gcry_md_final(md);
        const uint8_t *result = gcry_md_read(md, 0);
        memcpy(prev, result, sizeof(prev));

        for (uint32_t i = 1; i < iterations; i++) {
            gcry_md_reset(md);
            gcry_md_write(md, prev, sizeof(prev));
            gcry_md_final(md);
            result = gcry_md_read(md, 0);
            memcpy(prev, result, sizeof(prev));
        }
        memcpy(digest, prev, sizeof(digest));

        size_t idx = 0;
        while (needed_key > 0 && idx < sizeof(digest)) {
            key[key_pos++] = digest[idx++];
            needed_key--;
        }
        while (needed_iv > 0 && idx < sizeof(digest)) {
            iv[iv_pos++] = digest[idx++];
            needed_iv--;
        }
    }
    gcry_md_close(md);
    return true;
}

static bool decrypt_payload(const CryptoInfo *info, const char *password, char **detail)
{
    if (info->encrypted_len == 0 || info->encrypted_len % 16 != 0) {
        set_failure_detail(detail, "decrypt error: invalid payload length %zu", info->encrypted_len);
        return false;
    }
    uint8_t *buffer = malloc(info->encrypted_len);
    if (buffer == NULL) {
        set_failure_detail(detail, "decrypt error: out of memory for %zu bytes", info->encrypted_len);
        return false;
    }
    memcpy(buffer, info->encrypted, info->encrypted_len);

    uint8_t key[16];
    uint8_t iv[16];
    if (!derive_key_iv(password, info->salt, sizeof(info->salt), info->iterations, key, iv)) {
        free(buffer);
        set_failure_detail(detail, "decrypt error: failed to derive key/iv");
        return false;
    }

    gcry_cipher_hd_t cih;
    gcry_error_t gerr = gcry_cipher_open(&cih, GCRY_CIPHER_AES128, GCRY_CIPHER_MODE_CBC, 0);
    if (gerr) {
        free(buffer);
        set_failure_detail(detail, "decrypt error: %s", gcry_strerror(gerr));
        return false;
    }
    gerr = gcry_cipher_setkey(cih, key, sizeof(key));
    if (gerr) {
        gcry_cipher_close(cih);
        free(buffer);
        set_failure_detail(detail, "decrypt error: setkey failed: %s", gcry_strerror(gerr));
        return false;
    }
    gerr = gcry_cipher_setiv(cih, iv, sizeof(iv));
    if (gerr) {
        gcry_cipher_close(cih);
        free(buffer);
        set_failure_detail(detail, "decrypt error: setiv failed: %s", gcry_strerror(gerr));
        return false;
    }
    gerr = gcry_cipher_decrypt(cih, buffer, info->encrypted_len, NULL, 0);
    gcry_cipher_close(cih);
    if (gerr) {
        free(buffer);
        set_failure_detail(detail, "decrypt error: %s", gcry_strerror(gerr));
        return false;
    }

    uint8_t digest[16];
    if (info->encrypted_len > 16) {
        gcry_md_hash_buffer(GCRY_MD_MD5, digest, buffer + 16, info->encrypted_len - 16);
    } else {
        /* Empty payload: hash of zero bytes */
        gcry_md_hash_buffer(GCRY_MD_MD5, digest, NULL, 0);
    }
    bool ok = (memcmp(buffer, digest, 16) == 0);
    if (!ok) {
        set_failure_detail(detail, "decrypt error: md5 mismatch after decrypt (iterations=%u)", info->iterations);
    }
    free(buffer);
    return ok;
}

static bool check_keyring(const char *path, const char *password, char **detail)
{
    FILE *fp = fopen(path, "rb");
    if (!fp) {
        DK_LOG(LOG_ERR, "failed to open %s: %s", path, strerror(errno));
        set_failure_detail(detail, "io error: open %s: %s", path, strerror(errno));
        return false;
    }
    if (fseek(fp, 0, SEEK_END) != 0) {
        fclose(fp);
        DK_LOG(LOG_ERR, "failed to seek %s", path);
        set_failure_detail(detail, "io error: seek %s failed", path);
        return false;
    }
    long size = ftell(fp);
    if (size <= 0) {
        fclose(fp);
        DK_LOG(LOG_ERR, "invalid keyring size");
        set_failure_detail(detail, "io error: keyring empty or invalid size (%ld)", size);
        return false;
    }
    if (fseek(fp, 0, SEEK_SET) != 0) {
        fclose(fp);
        DK_LOG(LOG_ERR, "failed to rewind file");
        set_failure_detail(detail, "io error: rewind %s failed", path);
        return false;
    }
    uint8_t *data = malloc(size);
    if (!data) {
        fclose(fp);
        set_failure_detail(detail, "io error: out of memory allocating %ld bytes", size);
        return false;
    }
    size_t read_len = fread(data, 1, size, fp);
    fclose(fp);
    if (read_len != (size_t)size) {
        free(data);
        DK_LOG(LOG_ERR, "failed to read full file");
        set_failure_detail(detail, "io error: read %s expected %ld bytes got %zu", path, size, read_len);
        return false;
    }
    CryptoInfo info = { 0 };
    bool ok = false;
    if (parse_crypto_info(data, read_len, &info, detail)) {
        ok = decrypt_payload(&info, password, detail);
    } else {
        DK_LOG(LOG_ERR, "invalid keyring format");
        if (detail != NULL && *detail == NULL) {
            set_failure_detail(detail, "parse error: invalid keyring format");
        }
    }
    free(data);
    return ok;
}

static int exit_error(const char *msg)
{
    if (msg != NULL) {
        fprintf(stderr, "WB_CHECK_ERROR %s\n", msg);
    } else {
        fprintf(stderr, "WB_CHECK_ERROR\n");
    }
    return 2;
}

int main(int argc, char *argv[])
{
    dk_log_init(LOG_DAEMON, "wb-keyring-check");

    if (!gcry_check_version(NULL)) {
        DK_LOG(LOG_ERR, "failed to initialize libgcrypt");
        return exit_error("gcrypt_version");
    }
    gcry_control(GCRYCTL_DISABLE_SECMEM_WARN);
    gcry_control(GCRYCTL_INITIALIZATION_FINISHED, 0);

    const char *user_name = NULL;
    char *keyring_path_arg = NULL;
    bool print_masterkey = false;
    PasswordMode password_mode = PASSWORD_MODE_WHITEBOX;

    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--help") == 0) {
            print_usage();
            return 0;
        } else if (strncmp(argv[i], "--user=", 7) == 0) {
            user_name = argv[i] + 7;
        } else if (strncmp(argv[i], "--keyring-path=", 15) == 0) {
            keyring_path_arg = argv[i] + 15;
#if 0
        } else if (strcmp(argv[i], "--print-masterkey") == 0) {
            print_masterkey = true;
#endif
        } else if (strncmp(argv[i], "--password-mode=", 16) == 0) {
            const char *mode = argv[i] + 16;
            if (strcmp(mode, "whitebox") == 0) {
                password_mode = PASSWORD_MODE_WHITEBOX;
            } else if (strcmp(mode, "user") == 0) {
                password_mode = PASSWORD_MODE_USER;
            } else {
                DK_LOG(LOG_ERR, "invalid password mode: %s", mode);
                return exit_error("invalid_password_mode");
            }
        } else {
            DK_LOG(LOG_WARNING, "unknown argument: %s", argv[i]);
        }
    }

    struct passwd *pwd = NULL;
    if (user_name != NULL && user_name[0] != '\0') {
        pwd = getpwnam(user_name);
    } else {
        pwd = getpwuid(getuid());
    }
    if (pwd == NULL) {
        DK_LOG(LOG_ERR, "failed to resolve user");
        return exit_error("resolve_user");
    }

    char *workDir = NULL;
    if (!dk_file_workdir_init(pwd->pw_dir, pwd->pw_uid, pwd->pw_gid, &workDir) || workDir == NULL) {
        DK_LOG(LOG_ERR, "failed to init workdir");
        return exit_error("init_workdir");
    }

    char *masterkey = NULL;
    char *user_password = NULL;
    const char *password = NULL;
    if (password_mode == PASSWORD_MODE_WHITEBOX) {
        if (!dk_key_get_masterkey(workDir, &masterkey) || masterkey == NULL) {
            DK_LOG(LOG_ERR, "failed to read masterkey");
            free(workDir);
            return exit_error("load_masterkey");
        }
        password = masterkey;
        if (print_masterkey) {
            fprintf(stderr, "WB_MASTERKEY %s\n", masterkey);
        }
    } else {
        if (!read_user_password(&user_password)) {
            DK_LOG(LOG_ERR, "failed to read user password");
            free(workDir);
            return exit_error("user_password");
        }
        password = user_password;
    }

    char defaultPath[MAX_FILENAME_LENGTH] = { 0 };
    if (keyring_path_arg == NULL) {
        if (snprintf(defaultPath, sizeof(defaultPath), "%s/login.keyring", workDir) < 0) {
            DK_LOG(LOG_ERR, "failed to compose default keyring path");
            free(masterkey);
            free(workDir);
            return exit_error("compose_path");
        }
    }
    const char *keyring_path = keyring_path_arg ? keyring_path_arg : defaultPath;
    struct stat st;
    if (stat(keyring_path, &st) != 0) {
        DK_LOG(LOG_ERR, "keyring file %s not found", keyring_path);
        free(masterkey);
        free(workDir);
        return exit_error("file_not_found");
    }

    char *detail_msg = NULL;
    bool ok = check_keyring(keyring_path, password, &detail_msg);
    if (password_mode == PASSWORD_MODE_WHITEBOX) {
        free(masterkey);
    } else if (user_password != NULL) {
        memset(user_password, 0, strlen(user_password));
        free(user_password);
    }
    free(workDir);

    if (ok) {
        printf("WB_CHECK_OK %s\n",
             keyring_path);
        free(detail_msg);
        return 0;
    }
    if (detail_msg != NULL) {
        fprintf(stderr, "WB_CHECK_DETAIL %s\n", detail_msg);
        free(detail_msg);
    }
    printf("WB_CHECK_FAIL %s\n", keyring_path);
    return 1;
}
