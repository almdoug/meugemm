#!/bin/bash

#sudo systemctl set-default multi-user.target

#source /opt/intel/mkl/bin/mklvars.sh intel64
#1
# ldd gsl_dgemm_BLAS > BLASldd.log
# ./gsl_dgemm_BLAS BLAS.dat 32 4096 32
#2
# ldd gsl_dgemm_BLAS64 > BLAS64ldd.log
# ./gsl_dgemm_BLAS64 BLAS64.dat 32 4096 32
#3
# ldd gsl_dgemm_GSLCBLAS > GSLCBLASldd.log
# ./gsl_dgemm_GSLCBLAS GSLCBLAS.dat 32 4096 32
#4
# ldd gsl_dgemm_PSBLAS > PSBLASldd.log
# ./gsl_dgemm_PSBLAS PSBLAS.dat 32 4096 32
#5
# export MEU_LD=$LD_LIBRARY_PATH
# export LD_LIBRARY_PATH=/usr/lib64/atlas:$LD_LIBRARY_PATH
# ldd gsl_dgemm_ATLAS > ATLASldd.log
# ./gsl_dgemm_ATLAS ATLAS.dat 32 4096 32
#6
# export LD_LIBRARY_PATH=$MEU_LD
# ldd gsl_dgemm_ATLASi2 > ATLASi2ldd.log
# ./gsl_dgemm_ATLASi2  ATLASi2.dat 32 4096 32
#7
# ldd gsl_dgemm_OpenBLAS > OpenBLASldd.log
# ./gsl_dgemm_OpenBLAS OpenBLAS.dat 32 4096 32
#8
# ldd gsl_dgemm_OpenBLAS64 > OpenBLAS64ldd.log
# ./gsl_dgemm_OpenBLAS64 OpenBLAS64.dat 32 4096 32
#9
ldd gsl_dgemm_BLIS > BLISldd.out
./gsl_dgemm_BLIS BLIS.dat 32 4096 32
#10
ldd gsl_dgemm_BLIS64 > BLIS64ldd.out
./gsl_dgemm_BLIS64 > BLIS64.dat




#ldd gsl_dgemm_MKL > MKLldd.log
#./gsl_dgemm_MKL MKL.dat 32 4096 32
#11
# export LD_LIBRARY_PATH=/usr/lib64/atlas:$LD_LIBRARY_PATH
# ldd gsl_dgemm_ATLASt > ATLAStldd.log
# ./gsl_dgemm_ATLASt ATLASt.dat 32 4096 32
#12
#export LD_LIBRARY_PATH=$MEU_LD
# ldd gsl_dgemm_ATLASi2t > ATLASi2tldd.log
# ./gsl_dgemm_ATLASi2t  ATLASi2t.dat 32 4096 32
#13
#export OPENBLAS_NUM_THREADS=4
#export OMP_NUM_THREADS=4
# ldd gsl_dgemm_OpenBLASomp > OpenBLASompldd.log
# ./gsl_dgemm_OpenBLASomp OpenBLASomp.dat 32 4096 32
#14
# ldd gsl_dgemm_OpenBLAS64omp > OpenBLAS64ompldd.log
# ./gsl_dgemm_OpenBLAS64omp OpenBLAS64omp.dat 32 4096 32
#15
# ldd gsl_dgemm_OpenBLASpth > OpenBLASpthldd.log
# ./gsl_dgemm_OpenBLASpth OpenBLASpth.dat 32 4096 32
#16
# ldd gsl_dgemm_OpenBLAS64pth > OpenBLAS64pthldd.log
# ./gsl_dgemm_OpenBLAS64pth OpenBLAS64pth.dat 32 4096 32
#17
# export LD_LIBRARY_PATH=/opt/BLIS/oblis/lib:$LD_LIBRARY_PATH
# export BLIS_NUM_THREADS=4
# ldd gsl_dgemm_BLISomp > BLISompldd.out
# ./gsl_dgemm_BLISomp BLISomp.dat 32 4096 32
# export LD_LIBRARY_PATH=$MEU_LD
#18
# export LD_LIBRARY_PATH=/opt/BLIS/pblis/lib:$LD_LIBRARY_PATH
# ldd gsl_dgemm_BLISpth > BLISpthldd.out
# ./gsl_dgemm_BLISpth BLISpth.dat 32 4096 32
# export LD_LIBRARY_PATH=$MEU_LD
#19
#ldd gsl_dgemm_MKLt > MKLtldd.log
#./gsl_dgemm_MKLt MKLt.dat 32 4096 32
#20
#export LD_LIBRARY_PATH=/usr/lib64/sblis/lib:$LD_LIBRARY_PATH
#ldd gsl_dgemm_BLISMPI > BLISMPIldd.out
#mpirun -np 4 ./gsl_dgemm_BLISMPI BLISMPI.dat 32 4096 32
#export LD_LIBRARY_PATH=$MEU_LD
#21
#ldd gsl_dgemm_MKLMPI > MKLMPIldd.log
#mpirun -np 4 ./gsl_dgemm_MKLMPI MKLMPI.dat 32 4096 32
#sudo systemctl set-default graphical.target

#export LD_LIBRARY_PATH=/opt/BLIS/sblis/lib:$LD_LIBRARY_PATH
#./dgemm_BLAS desempenhoBLAS_d.dat >> stdoutBLAS_d.log
#./dgemm_ATLAS desempenhoATLAS_d.dat >> stdoutATLAS_d.log
#./dgemm_OpenBLAS desempenhoOpenBLAS_d.dat >> stdoutOpenBLAS_d.log
#./dgemm_BLIS desempenhoBLIS_d.dat >> stdoutBLIS_d.log

#./sgemm_BLAS desempenhoBLAS_s.dat >> stdoutBLAS_s.log
#./sgemm_ATLAS desempenhoATLAS_s.dat >> stdoutATLAS_s.log
#./sgemm_OpenBLAS desempenhoOpenBLAS_s.dat >> stdoutOpenBLAS_s.log
#./sgemm_BLIS desempenhoBLIS_s.dat >> stdoutBLIS_s.log
