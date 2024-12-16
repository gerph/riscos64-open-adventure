#include <stdlib.h>
#include <stdio.h>
#include "swis.h"

/*************************************************** Gerph *********
 Function:      os_readline
 Description:   Call OS_ReadLine for input
 Parameters:    line-> line to read
                len = max length including terminator
 Returns:       1 for success, 0 for failure
 ******************************************************************/
static int os_readline(char *line, int len)
{
    _kernel_oserror *err;
    int read;
    uint32_t flags = 0;
#ifdef __riscos64
    err = _swix(OS_ReadLine32, _INR(0, 4)|_OUTR(0, 1), line, len, 32, 128, 0, &flags, &read);
    if (err)
        return 0;
    if (flags)
        goto escape;
    line[read] = '\0';
    return 1;
#else
    err = _swix(OS_ReadLine32, _INR(0, 4)|_OUT(1)|_OUT(_FLAGS), line, len, 32, 128, 0, &read, &flags);
#ifndef ErrorNumber_ModuleBadSWI
#define ErrorNumber_ModuleBadSWI          0x110 /*  Token for internationalised message */
#endif
    if (err && err->errnum == ErrorNumber_ModuleBadSWI)
    {
        err = _swix(OS_ReadLine, _INR(0, 4)|_OUT(1)|_OUT(_FLAGS), line, len, 32, 128, 0, &read, &flags);
    }
    if (err)
        return 0;
    if (flags & _C)
        goto escape;
    line[read] = '\0';
    return 1;
#endif

escape:
    return 0;
}

static char readline_buffer[512];

char *readline(const char *prompt)
{
    int success;
    if (prompt)
        printf("%s", prompt);

    success = os_readline(readline_buffer, sizeof(readline_buffer));
    if (!success)
        return NULL;

    char *new_block = malloc(strlen(readline_buffer) + 1);
    strcpy(new_block, readline_buffer);
    return new_block;
}


void add_history(const char *line)
{
    /* Nothing needed, as we're using the OS implementation of ReadLine which has history. */
}
