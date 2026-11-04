#include <stddef.h>
#include <stdint.h>
#include <sys/types.h>

/* Report no allocations: Android 8 media code only uses this for dumpsys. */
void get_malloc_leak_info(uint8_t** info, size_t* overall_size, size_t* info_size,
                          size_t* total_memory, size_t* backtrace_size) {
    *info = NULL;
    *overall_size = 0;
    *info_size = 0;
    *total_memory = 0;
    *backtrace_size = 0;
}

void free_malloc_leak_info(uint8_t* info) {
    (void)info;
}

/* Heap walking for libmemunreachable, which nothing here needs. */
int malloc_iterate(uintptr_t base, size_t size,
                   void (*callback)(uintptr_t base, size_t size, void* arg), void* arg) {
    (void)base, (void)size, (void)callback, (void)arg;
    return -1;
}

void malloc_disable(void) {}

void malloc_enable(void) {}

ssize_t malloc_backtrace(void* pointer, uintptr_t* frames, size_t frame_count) {
    (void)pointer, (void)frames, (void)frame_count;
    return 0;
}

/* Android 13 libc++ keeps its demangler internal. Callers only use it to
 * pretty-print symbols and keep the mangled name on failure. */
char* __cxa_demangle(const char* mangled_name, char* output_buffer, size_t* length, int* status) {
    (void)mangled_name, (void)output_buffer, (void)length;
    if (status)
        *status = -2;
    return NULL;
}
