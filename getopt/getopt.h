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

  flags followed by :'s require arguments
*/

#ifndef __GETOPT_H
#define __GETOPT_H
  extern int       opterr;
  extern int       optind;
  extern char     *optarg;
  extern int       optopt;
  int getopt(int argc, char *const *argv, const char *opts);
#endif
