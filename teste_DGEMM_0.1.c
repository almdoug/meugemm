#include <stdio.h>
#include <stdlib.h>


#define FSIZE 1024
#define ISIZE 32
#define STEP 32
#define NREP 5


typedef struct{
    double * val;       // Endereo da matriz
    unsigned int ld;    // Tamanho da direção principal
    unsigned int m;     // número de linhas
    unsigned int n;     // número de colunas
    char type;          // por linhas True, por colunas False 
} matrix;

void matrixInit(matrix* M, unsigned int m, unsigned int n, unsigned int ldm, char type);
void onesInit(matrix* M, unsigned int m, unsigned int n, unsigned int ldm, char type);
void zerosInit(matrix* M, unsigned int m, unsigned int n, unsigned int ldm, char type);
void valInit(double val, matrix* M, unsigned int m, unsigned int n, unsigned int ldm, char type);
double numGenerator(double min, double max);
void randInit(double min, double max, matrix* M, unsigned int m, unsigned int n, unsigned int ldm, char type);


int main( int argc, char** argv ){

    matrix A;
    srand(1234567890);
    
    //matrixInit(&A, ISIZE, ISIZE, FSIZE, (char) 1);
    //zerosInit(&A, ISIZE, ISIZE, FSIZE, (char) 1);
    //onesInit(&A, ISIZE, ISIZE, FSIZE, (char) 1);
    //valInit(0.5, &A, ISIZE, ISIZE, FSIZE, (char) 1);
    randInit(0.0, 1.0, &A, ISIZE, ISIZE, FSIZE, (char) 1);

    printf("Array 2D dynamic 1.0.\n");
    printf("O Valor de A: ---------------------->%p\n", A.val);
    printf("O Endereço de A: ------------------->%p\n", &A.val);
    printf("O Valor de A[0]: ------------------->%p \n", A.val[0]);
    printf("O Endereço de A[0]: ---------------->%p \n", &A.val[0]);
    printf("O Valor de A[1][1]: ---------------->%.1lf \n", A.val[1*A.ld + 1]);
    printf("O Endereço de A[1][1]: ------------->%p \n", &A.val[1+A.ld + 1]);
    printf("\n");
    
    free(A.val);

    return 0;

}

void matrixInit(matrix* M, unsigned int m, unsigned int n, unsigned int ldm, char type){
    M->type = type;
    M->ld = ldm;
    M->m = m;
    M->n = n;

    if (type){
        M->val = (double*)malloc(M->m*M->ld*sizeof(double));
    }else{
        M->val = (double*)malloc(M->n*M->ld*sizeof(double));
    }

    return;
}

void onesInit(matrix* M, unsigned int m, unsigned int n, unsigned int ldm, char type){
    
    valInit(1.0, M, m, n, ldm, type);

    return;
}

void zerosInit(matrix* M, unsigned int m, unsigned int n, unsigned int ldm, char type){
    
    valInit(0.0, M, m, n, ldm, type);

    return;
}

void valInit(double val, matrix* M, unsigned int m, unsigned int n, unsigned int ldm, char type){
    
    matrixInit(M, m, n, ldm, type);

    if (type){
        for(int i = 0; i < m; i++){
            for(int j = 0; j < n; j++){
                M->val[i*ldm + j] = val;    //por linhas
            }
        }
    }else{
        for(int j = 0; j < n; j++){
            for(int i = 0; i < m; i++){
                M->val[i+ j*ldm] = val;    //por colunas
            }
        }
    }

    return;
}

double numGenerator(double min, double max){
	double number = min + ((double)rand()/RAND_MAX)*(max - min);
	return number;
}

void randInit(double min, double max, matrix* M, unsigned int m, unsigned int n, unsigned int ldm, char type){
    
    matrixInit(M, m, n, ldm, type);

    if (type){
        for(int i = 0; i < m; i++){
            for(int j = 0; j < n; j++){
                M->val[i*ldm + j] = numGenerator(min, max);    //por linhas
            }
        }
    }else{
        for(int j = 0; j < n; j++){
            for(int i = 0; i < m; i++){
                M->val[i+ j*ldm] = numGenerator(min, max);    //por colunas
            }
        }
    }

    return;
}