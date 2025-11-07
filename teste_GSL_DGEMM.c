#include <stdio.h>
#include <stdlib.h>
#include <gsl/gsl_blas.h>
#include <gsl/gsl_rstat.h>
#include <omp.h>

#define FSIZE 1024
#define ISIZE 32
#define STEP 32
#define NREP 5


double numGenerator(double min, double max);
void printTime(double sec);

int main( int argc, char** argv ){

	int i,j,k;

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
		nrep = atoi(argv[5]);
	else
		nrep = NREP;
	// define first matSize
	matSize = iSize;
	// Intro
	printf("GSL_DGEMM test: %d, %d, ... (+%d)..., %d, %d \n", iSize, iSize + step, step, fSize - step, fSize);
	// Set constants
	alpha = 1.0;
	beta = 0.5;
	// Set random seed
	srand(1234567890);
	// Main loop (for all mat sizes)
	while (matSize <= fSize){
		// alloc matrix
		gsl_matrix *A = gsl_matrix_alloc(matSize, matSize);
		gsl_matrix *B = gsl_matrix_alloc(matSize, matSize);
		gsl_matrix *C = gsl_matrix_alloc(matSize, matSize);
		// init matrix
		for (i = 0; i < matSize; i++) {
			for (j = 0; j < matSize; j++) {
				gsl_matrix_set(A, i, j, numGenerator(-1.0, 1.0));
				gsl_matrix_set(B, i, j, numGenerator(-4.0, 4.0));
				gsl_matrix_set(C, i, j, numGenerator(0.0, 1.0));
			}
		}
		// init stst
		gsl_rstat_workspace *rstat_t = gsl_rstat_alloc();
		// test loop 
		for(k = 0; k < nrep; k++){
			start = omp_get_wtime(); // start crono
			// make gemm operation
			gsl_blas_dgemm(CblasNoTrans, CblasNoTrans, alpha, A, B, beta, C); 
			stop = omp_get_wtime();  // syop crono
			dt = stop - start; // calc dt
			gsl_rstat_add(dt, rstat_t); // stat dt
		}
		// calc problem size in GFLOP
		gflop = (2.0*matSize + 2)*matSize*matSize*0.000000001;
		// output
		printf("_______________________________________\n");
		printf("Matrix Size: %d\n", matSize);
		printf("_______________________________________\n");
		// corners of the matrix C
		printf("%lf \t %lf\n", gsl_matrix_get (C, 0, 0			),	gsl_matrix_get (C, 0		, matSize-1));
		printf("%lf \t %lf\n", gsl_matrix_get (C, 0, matSize - 1), 	gsl_matrix_get (C, matSize-1, matSize-1));
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
		gsl_matrix_free(A);
		gsl_matrix_free(B);
		gsl_matrix_free(C);
		gsl_rstat_free(rstat_t);
		matSize += step;
	}
	fclose(desemp);
	return 0;
}

double numGenerator(double min, double max){
	double number = min + ((double)rand()/RAND_MAX)*(max - min);
	return number;
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

	 

//$(CC) $(CFLAGS) -o dgemm_GSL -fopenmp -lgsl -lopenblas example_001.c
