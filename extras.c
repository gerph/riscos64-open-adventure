#include <stdlib.h>
#include <stdint.h>
#include "kernel.h"
#include "swis_os.h"

#define attribute_relro __attribute__ ((section (".data.rel.ro")))

uintptr_t __stack_chk_guard attribute_relro = 0xFF88211445fe2211ll;

void __attribute__ ((__noreturn__))
     __stack_chk_fail(void)
{
    os_write0("Stack smash detected");
    os_newline();
    os_newline();

    _kernel_backtrace();

    _Exit(1);
}


#include <stdarg.h>
#include <stdio.h>

int __attribute__ ((__optimize__ ("-fno-stack-protector")))
    __printf_chk (int flag, const char *format, ...)
{
  va_list ap;
  int wrote;

  va_start(ap, format);
  wrote = vprintf(format, ap);
  va_end(ap);

  return wrote;
}

int __attribute__ ((__optimize__ ("-fno-stack-protector")))
    __snprintf_chk (char *s, size_t maxlen, int flag, size_t slen, const char *format, ...)
{
  va_list ap;
  int wrote;

  va_start(ap, format);
  wrote = vsnprintf(s, slen, format, ap);
  va_end(ap);

  return wrote;
}

int __attribute__ ((__optimize__ ("-fno-stack-protector")))
    __fprintf_chk (FILE *fh, int flag, const char *format, ...)
{
  va_list ap;
  int wrote;

  va_start(ap, format);
  wrote = vfprintf(fh, format, ap);
  va_end(ap);

  return wrote;
}

int __attribute__ ((__optimize__ ("-fno-stack-protector")))
    __vfprintf_chk (FILE *fh, int flag, const char *format, va_list ap)
{
  int wrote;

  wrote = vfprintf(fh, format, ap);

  return wrote;
}

int __attribute__ ((__optimize__ ("-fno-stack-protector")))
    __vprintf_chk(int flag, const char *format, va_list ap)
{
  int wrote;

  wrote = vprintf(format, ap);

  return wrote;
}

int __attribute__ ((__optimize__ ("-fno-stack-protector")))
    __vsnprintf_chk (char *s, size_t maxlen, int flag, size_t slen, const char *format, va_list ap)
{
  int wrote;

  wrote = vsnprintf(s, slen, format, ap);

  return wrote;
}



#include <stdio.h>
#include <string.h>

int fputs(const char *str, FILE *fh)
{
    if (!fh)
        return -1;

    int len = strlen(str ? str : "<NULL>");

    return fwrite(str, 1, len, fh);
}

int puts(const char *ptr)
{
    int total = strlen(ptr ? ptr : "<NULL>");
    int wrote = 0;

    while (total)
    {
        const char *next_nl = memchr(ptr, '\n', total);
        if (next_nl == NULL)
        {
            os_writen(ptr, total);
            wrote += total;
            break;
        }
        int to_nl = (next_nl - (const char *)ptr);
        os_writen(ptr, to_nl);
        os_newline();
        wrote += to_nl + 1;
        total -= to_nl + 1;
        ptr = ((const char *)ptr) + to_nl + 1;
    }
    os_newline();
    wrote += 1;

    return wrote;
}

int fileno(FILE *fh)
{
    if (!fh)
        return -1;

    if (fh == stdin || fh == stdout || fh == stderr)
        return -2;

    // CHECK_MAGIC(fh, -1);

    return fh->_fileno;
}

int isatty(int fd)
{
    if (fd == -2)
        return 1;
    return 0;
}



/* From: https://github.com/freebsd/freebsd-src/blob/74ecdf86d8d2a94a4bfcf094a2e21b4747e4907f/sys/libkern/strcasecmp.c#L41 */
#include <ctype.h>

int
strcasecmp(const char *s1, const char *s2)
{
    const u_char *us1 = (const u_char *)s1, *us2 = (const u_char *)s2;

    while (tolower(*us1) == tolower(*us2)) {
        if (*us1++ == '\0')
            return (0);
        us2++;
    }
    return (tolower(*us1) - tolower(*us2));
}

int
strncasecmp(const char *s1, const char *s2, size_t n)
{

    if (n != 0) {
        const u_char *us1 = (const u_char *)s1;
        const u_char *us2 = (const u_char *)s2;

        do {
            if (tolower(*us1) != tolower(*us2))
                return (tolower(*us1) - tolower(*us2));
            if (*us1++ == '\0')
                break;
            us2++;
        } while (--n != 0);
    }
    return (0);
}
