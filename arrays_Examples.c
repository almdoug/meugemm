#include <stdio.h>
#include <stdlib.h>


#define FSIZE 1024
#define ISIZE 32
#define STEP 32
#define NREP 5

int main( int argc, char** argv ){

    //Arrays 1D statis
    double x[ISIZE] = {.0};

    //ARRAY 2D static
    double A[ISIZE][ISIZE] = {{.0},{.0}};

    printf("Array 1D static.\n");
    printf("O Valor de x: ---------------------->%p \n", x);
    printf("O Endereço de x: ------------------->%p \n", &x);
    printf("O Valor de x[0]: ------------------->%.1lf \n", x[0]);
    printf("O  Endereço de x[0]: --------------->%p \n", &x[0]);
    printf("\n");

    printf("Array 2D static.\n");
    printf("O Valor de A: ---------------------->%p\n", A);
    printf("O Endereço de A: ------------------->%p\n", &A);
    printf("O Valor de A[0]: ------------------->%p \n", A[0]);
    printf("O Endereço de A[0]: ---------------->%p \n", &A[0]);
    printf("O Valor de A[0][0]: ---------------->%.1lf \n", A[0][0]);
    printf("O Endereço de A[0][0]: ------------->%p \n", &A[0][0]);
    printf("\n");

    // Qual o tamanho máximo que consigo usar para alocar uma matriz estatica?
    // Existelimite? Por que? 
    
    //ARRAY 2D Dynamic 1.0
    double **B;

    B = (double**)malloc(ISIZE*sizeof(double*));
    for(int i = 0; i < ISIZE; i++){
        B[i] = (double*) malloc(ISIZE*sizeof(double));
        for(int j = 0; j < ISIZE; j++){
            B[i][j] = .0;
        }
    }

    printf("Array 2D dynamic 1.0.\n");
    printf("O Valor de B: ---------------------->%p\n", B);
    printf("O Endereço de B: ------------------->%p\n", &B);
    printf("O Valor de B[0]: ------------------->%p \n", B[0]);
    printf("O Endereço de B[0]: ---------------->%p \n", &B[0]);
    printf("O Valor de B[0][0]: ---------------->%.1lf \n", B[0][0]);
    printf("O Endereço de B[0][0]: ------------->%p \n", &B[0][0]);
    printf("\n");

    for(int i = 0; i < ISIZE; i++){
        free(B[i]);
    }
    free(B);

    //ARRAY 2D Dynamic 2.0
    double *C;

    C = (double*)malloc(ISIZE*ISIZE*sizeof(double));
    for(int i = 0; i < ISIZE; i++){
        for(int j = 0; j < ISIZE; j++){
            C[i*ISIZE + j] = .0;    //por linhas
            //C[i + j*ISIZE] = .0;    //por colunas

        }
    }

    printf("Array 2D dynamic 2.0.\n");
    printf("O Valor de C: ---------------------->%p\n", C);
    printf("O Endereço de C: ------------------->%p\n", &C);
    printf("O Valor de C[0]: ------------------->%p \n", C[0]);
    printf("O Endereço de C[0]: ---------------->%p \n", &C[0]);
    printf("O Valor de C[1][1]: ---------------->%.1lf \n", C[1*ISIZE + 1]);
    printf("O Endereço de C[1][1]: ------------->%p \n", &C[1+ISIZE + 1]);
    printf("\n");
    
    free(C);

    return 0;
}