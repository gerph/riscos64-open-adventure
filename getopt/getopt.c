/*
**  GETOPT LIBRARY
**
**  AT&T wrote getopt()
**      August 10, 1986
**
*/

/* Use :
  while ((c = getopt(argc, argv, "<flags>")) != EOF) {
    switch (c) {
      case 'x':
        // Argument is in optarg
    }
  }
*/

#include <stdio.h>
#include <string.h>

/*
**  This is the public-domain AT&T getopt(3) code.  I added the
**  #ifndef stuff because I include <stdio.h> for the program;
**  getopt, per se, doesn't need it.  I also added the INDEX/index
**  hack (the original used strchr, of course).  And, note that
**  technically the casts in the write(2) calls shouldn't be there.
*/

#ifndef NULL
#define NULL    0
#endif
#ifndef EOF
#define EOF     (-1)
#endif
#ifndef INDEX
#define INDEX strchr
#endif


#define ERR(sx, cx)       if(opterr){\
        (void) printf("%s %s %c\n",argv[0],sx,cx);}

int     opterr = 1;
int     optind = 1;
int     optopt;
char    *optarg;

int getopt(int argc, char **argv, char *opts)
{
        static int sp = 1;
        register int c;
        register char *cp;

        if(sp == 1) {
                if(optind >= argc ||
                   argv[optind][0] != '-' || argv[optind][1] == '\0')
                        return(EOF);
                else if(strcmp(argv[optind], "--") == 0) {
                        optind++;
                        return(EOF);
                }
        }
        optopt = c = argv[optind][sp];
        if(c == ':' || (cp=INDEX(opts, c)) == NULL) {
                ERR(": illegal option -- ", c);
                if(argv[optind][++sp] == '\0') {
                        optind++;
                        sp = 1;
                }
                return('?');
        }
        if(*++cp == ':') {
                if(argv[optind][sp+1] != '\0')
                        optarg = &argv[optind++][sp+1];
                else if(++optind >= argc) {
                        ERR(": option requires an argument --", c);
                        sp = 1;
                        return('?');
                } else
                        optarg = argv[optind++];
                sp = 1;
        } else {
                if(argv[optind][++sp] == '\0') {
                        sp = 1;
                        optind++;
                }
                optarg = NULL;
        }
        return(c);
}

