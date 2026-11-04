#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

struct android_namespace_t;

/* Android 8 libraries use linker namespaces to reach the "sphal" libraries
 * and updatable drivers. With no namespaces they fall back to a plain dlopen,
 * which already searches /vendor in a vendor process. */

struct android_namespace_t* android_get_exported_namespace(const char* name) {
    (void)name;
    return NULL;
}

struct android_namespace_t* android_create_namespace(const char* name, const char* ld_library_path,
                                                     const char* default_library_path, uint64_t type,
                                                     const char* permitted_when_isolated_path,
                                                     struct android_namespace_t* parent) {
    (void)name, (void)ld_library_path, (void)default_library_path, (void)type;
    (void)permitted_when_isolated_path, (void)parent;
    return NULL;
}

bool android_link_namespaces(struct android_namespace_t* from, struct android_namespace_t* to,
                             const char* shared_libs_sonames) {
    (void)from, (void)to, (void)shared_libs_sonames;
    return false;
}

bool android_init_anonymous_namespace(const char* shared_libs_sonames, const char* library_search_path) {
    (void)shared_libs_sonames, (void)library_search_path;
    return false;
}
