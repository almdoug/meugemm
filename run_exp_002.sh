#!/bin/bash

#3
#echo "time log" > execution.log
#echo "gsl_dgemm_BLAS ATLAS" >> execution.log
#update-alternatives --config libblas.so.3 (ATLAS)
#sudo update-alternatives --config libblas.so.3 < setATLAS.in
#sudo update-alternatives --display libblas.so.3 > ATLASldd.log
#ldd gsl_dgemm_BLAS >> ATLASldd.log
#date >> execution.log
#./gsl_dgemm_BLAS ATLAS.dat 32  4096 32
#date >> execution.log
#4
#echo "gsl_dgemm_BLAS OpenBLAS" >> execution.log
#update-alternatives --config libblas.so.3 (OpenBLAS)
#sudo update-alternatives --config libblas.so.3 < setOpenBLAS.in
#sudo update-alternatives --display libblas.so.3 > OpenBLASldd.log
#ldd gsl_dgemm_BLAS >> OpenBLASldd.log
#date >> execution.log
#./gsl_dgemm_BLAS OpenBLAS.dat 32  4096 32
#date >> execution.log
#1
#echo "gsl_dgemm_BLAS BLAS" >> execution.log
#update-alternatives --config libblas.so.3 (BLAS)
#sudo update-alternatives --config libblas.so.3 < setBLAS.in
#sudo update-alternatives --display libblas.so.3 > BLASldd.log
#ldd gsl_dgemm_BLAS >> BLASldd.log
#date >> execution.log
#./gsl_dgemm_BLAS BLAS.dat 32  4096 32
#date >> execution.log
#2
#echo "gsl_dgemm_GSLCBLAS" >> execution.log
#ldd gsl_dgemm_GSLCBLAS > GSLCBLASldd.log
#date >> execution.log
#./gsl_dgemm_GSLCBLAS GSLCBLAS.dat 32 4096 32
#date >> execution.log
#5
echo "gsl_dgemm_BLAS OpenBLAS 2T" >> execution.log
#update-alternatives --config libblas.so.3 (OpenBLAS)
sudo update-alternatives --config libblas.so.3 < setOpenBLAS.in
sudo update-alternatives --display libblas.so.3 >> OpenBLASldd.log
export OPENBLAS_NUM_THREADS=2
ldd gsl_dgemm_BLAS >> OpenBLASldd.log
date >> execution.log
./gsl_dgemm_BLAS OpenBLAS.dat 32  4096 32
date >> execution.log
#6
echo "gsl_dgemm_BLAS OpenBLAS 4T" >> execution.log
#update-alternatives --config libblas.so.3 (OpenBLAS)
sudo update-alternatives --config libblas.so.3 < setOpenBLAS.in
sudo update-alternatives --display libblas.so.3 >> OpenBLASldd.log
export OPENBLAS_NUM_THREADS=4
ldd gsl_dgemm_BLAS >> OpenBLASldd.log
date >> execution.log
./gsl_dgemm_BLAS OpenBLAS.dat 32  4096 32
date >> execution.log
