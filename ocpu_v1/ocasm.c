#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int parse(line)
char* line;
{
    char insts[4];
    int i = 0;
    int t = 0;
    
    int word;
    
    while (t <= 4) {
        
        word = "";
        
        printf("ps wd");
        
        while (1) {
            if (i < strlen(line)) {
                if (line[i] != " ") {
                    printf("%s",line[i]);
                    strcat(word,line[i]);
                    ++i;
                    printf("inc i");
                }
                else {
                    printf("br");
                    break;
                }
            }
            else {
                printf("br");
                break;
            }
        }
        ++i;
        printf("inc i");
        printf("add wd %s",word);
        insts[t] = word;
        ++t;
        printf("inc t");
    }
    printf("rtn");
    return(insts, t);
}


int parseasm(char* line) {
    printf("ps ln %s", line);
    char* code = parse(line);
    char ln[4];
    
    int C = code[0];
    
    printf("ps inst %s", C);
    if (C == "ld") {
        strcat(ln, "00");
    }
    
    if (C == "ldm") {
        strcat(ln, "01");
    }
    
    if (C == "ldr") {
        strcat(ln, "02");
    }
    
    if (C == "st") {
        strcat(ln, "10");
    }
    
    if (C == "std") {
        strcat(ln, "11");
    }
    
    if (C == "noop") {
        strcat(ln, "FE");
    }
    
    if (C == "halt") {
        strcat(ln, "FF");
    }
    
    printf("asm ln");
    strcat(ln, " "); strcat(ln,code[1]); strcat(ln," "); strcat(ln,code[2]);
    strcat(ln," "); strcat(ln,code[3]);
    
    printf("got %s", ln);
    
    printf("rtn");
    return(ln);
}


int main(int argc, char **argv) {
    printf("init");
    FILE *fptr; /* Not sure what this does, but it's necessary */
    
    if (argc != 2) { /* If there is no [FILE] argument */
        printf("Usage: ocasm [FILE]"); /* Print usage */
        exit(0); /* Exit */
    }
    
    printf("open files");

    int infile = fopen(argv[1],"r"); /* Open the input file */
    int outfile = fopen("out.oca","w"); /* Open the output file */
    
    char lines[65535]; /* File probably won't be this long, but
        a single file should not be longer than 65535 lines. */
    char line[16]; /* Lines should only be about 16 characters max */
    
    int i = 0;
    
    printf("read");

    while (fgets(line, sizeof(line), infile)) { /* Magic */
        lines[i] = line;
        printf("get ln %d", i);
    }
    
    printf("close");

    fclose(infile);
    
    int file_len = i;
    
    printf("parse");

    for (int ln=0; ln == i; ++i) {
        fprintf(outfile, parseasm(lines[ln]));
    }
    
    fclose(outfile);
    
    printf("done.");
}
