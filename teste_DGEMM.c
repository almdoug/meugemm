#include <stdio.h>
#include <stdlib.h>
#include <gsl/gsl_blas.h>
#include <gsl/gsl_rstat.h>
#include <omp.h>

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
int my_blas_dgemm(double alpha, matrix *A, matrix *B, double beta, matrix *C);
void printTime(double sec);

int main( int argc, char** argv ){

    int k;

	int matSize;
	double start, stop, dt;
	double gflop;

	double alpha, beta;

	FILE *desemp;
	int fSize, iSize, step, nrep;
	// First arg fileName
	if(argc > 1)
		desemp = fopen(argv[1], "a");
	else
		desemp = fopen("./desempenho.dat", "w");
	// next arg iSize
	if(argc > 2)
		iSize = atoi(argv[2]);
	else
		iSize = ISIZE;
	// next arg fSize
	if(argc > 3)
		fSize = atoi(argv[3]);
	else
		fSize = FSIZE;
	// next arg step
	if(argc > 4)
		step = atoi(argv[4]);
	else
		step = STEP;
	// next arg nrep
	if(argc > 5)
		nrep = atoi(argv[4]);
	else
		nrep = NREP;
	// define first matSize
	matSize = iSize;
	// Intro
	printf("DGEMM test: %d, %d, ... (+%d)..., %d, %d \n", iSize, iSize + step, step, fSize - step, fSize);
	// Set constants
	alpha = 1.0;
	beta = 0.5;
	// Set random seed
	srand(1234567890);
	// Main loop (for all mat sizes)
    matrix A, B, C;
	while (matSize <= fSize){
		// alloc and init matrix
		randInit(-1.0, 1.0, &A, matSize, matSize, matSize, (char) 1);
		randInit(-4.0, 4.0, &B, matSize, matSize, matSize, (char) 1);
        randInit(0.0, 1.0, &C, matSize, matSize, matSize, (char) 1);
		// init stst
		gsl_rstat_workspace *rstat_t = gsl_rstat_alloc();
		// test loop 
		for(k = 0; k < nrep; k++){
			start = omp_get_wtime(); // start crono
			// make gemm operation
			my_blas_dgemm(alpha, &A, &B, beta, &C); 
			stop = omp_get_wtime();  // stop crono
			dt = stop - start; // calc dt
			gsl_rstat_add(dt, rstat_t); // stat dt
		}
		// calc problem size in GFLOP
		gflop = (2.0*matSize + 2)*matSize*matSize*0.000000001;
		// output
		printf("_______________________________________\n");
		printf("Matrix Size: %d\n", matSize);
		printf("_______________________________________\n");	
		// print dt
		printTime(gsl_rstat_mean(rstat_t));
		printf("Size in GFLOP: %.4lf\n", gflop);
		printf("Performance in GFLOPS\n");
		printf("mean: %.4lf\n", gflop/gsl_rstat_mean(rstat_t));
		printf("largest: %.4lf\n",  gflop/gsl_rstat_min(rstat_t));
		printf("smallest: %.4lf\n", gflop/gsl_rstat_max(rstat_t));
		printf("median: %.4lf\n", gflop/gsl_rstat_median(rstat_t));
		printf("rms: %.4lf\n", gflop/gsl_rstat_rms(rstat_t));
		if (matSize == iSize) //print dataframe head
			fprintf(desemp, "matSize,Size,Mean,Variance,Largest,Smallest,Median,SD,SD_Mean,Skew,RMS,Kurtosis\n");
		
		// col 0
		fprintf(desemp, "%d, ", matSize);
		// col 1
		fprintf(desemp, " %.4lf, ", gflop);
		// col 2
		fprintf(desemp, " %.4lf,", gsl_rstat_mean(rstat_t));
		// col 3
		fprintf(desemp, " %.4lf,", gsl_rstat_variance(rstat_t));
		// col 4
		fprintf(desemp, " %.4lf,", gsl_rstat_min(rstat_t));
		// col 5
		fprintf(desemp, " %.4lf, ", gsl_rstat_max(rstat_t));
		// col 6
		fprintf(desemp, " %.4lf,", gsl_rstat_median(rstat_t));
		// col 7
		fprintf(desemp, " %.4lf,", gsl_rstat_sd(rstat_t));
		// col 8
		fprintf(desemp, " %.4lf,", gsl_rstat_sd_mean(rstat_t));
		// col 9
		fprintf(desemp, " %.4lf,", gsl_rstat_skew(rstat_t));
		// col 10
		fprintf(desemp, " %.4lf,", gsl_rstat_rms(rstat_t));
		// col 11
		fprintf(desemp, " %.4lf \n", gsl_rstat_kurtosis(rstat_t));

		fflush(stdout);
		fflush(desemp);
		free(A.val);
		free(B.val);
		free(C.val);
		gsl_rstat_free(rstat_t);
		matSize += step;
	}
	fclose(desemp);

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

int my_blas_dgemm(double alpha, matrix *A, matrix *B, double beta, matrix *C){
    if (A->n != B->m) return 1;
    if (C->m != A->m) return 2;
    if (C->n != B->n) return 3;
    register double cvalue;
    if ((C->type) && (A->type) && (B->type)){ // all by rows
        for(int i = 0; i < A->m ; i++){
            for(int j = 0; j < B->n; j++){
                cvalue = 0.0;
                for(int k = 0; k < A->n; k++){
                    cvalue+= A->val[i*A->ld + k] * B->val[k*B->ld + j];
                }
                C->val[i*C->ld + j] = alpha*cvalue + beta*C->val[i*C->ld + j];
            }
        }
    }else{ 
        if (!(C->type) && !(A->type) && !(B->type)){ // all by col
            for(int j = 0; j < B->n ; j++){
                for(int i = 0; i < A->m; i++){
                    cvalue = 0.0;
                    for(int k = 0; k < A->n; k++){
                        cvalue+= A->val[i + k*A->ld] * B->val[k + j*B->ld];
                    }
                    C->val[i + j*C->ld] = alpha*cvalue + beta*C->val[i + j*C->ld];
                }
            }
        }else return 4;
    }
    return 0;
}

void printTime(double sec){
	int hh,mm, ss;
	hh = mm = ss = 0;
	if (sec > 1){
		hh = (int)(sec/3600);
		mm = (int)((sec - hh*3600)/60);
		ss = (int)(sec - hh*3600 - mm*60);
	}
	printf("%d:%d:%d\n", hh, mm, ss);
}
