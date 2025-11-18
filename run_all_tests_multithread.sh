#!/bin/bash

# Script para testar bibliotecas multithread com linkagem direta

# colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # no color

# parameters
INITIAL_SIZE=128
FINAL_SIZE=1024
STEP=128

# source file
SOURCE_FILE="teste_GSL_DGEMM.c"

# compilation flags
CFLAGS="-O2 -Wall -fopenmp"
LDFLAGS="-lgsl -lgslcblas -lm -fopenmp -export-dynamic"

# Diretórios de saída (com fallback para valores padrão)
: "${OUTPUT_DIR:=output_multi/direct_compilation}"
: "${LOG_DIR:=logs_multi/direct_compilation}"

# Número de threads (pode ser ajustado via variável de ambiente)
: "${NUM_THREADS:=4}"

echo "=============================================="
echo "  Testes Multithread - Direct Compilation"
echo "=============================================="
echo "Tamanho inicial: $INITIAL_SIZE"
echo "Tamanho final: $FINAL_SIZE"
echo "Incremento: $STEP"
echo "Threads: $NUM_THREADS"
echo "Output: $OUTPUT_DIR | Logs: $LOG_DIR"
echo "=============================================="
echo ""

# function to compile and test BLAS64 multithread
test_blas_variant_64() {
    local VARIANT_NAME=$1
    local LIB_FLAG=$2
    local OUTPUT_FILE="$OUTPUT_DIR/output_${VARIANT_NAME}.dat"
    local EXEC_NAME="$OUTPUT_DIR/dgemm_test_${VARIANT_NAME}"
    local OBJ_NAME="$OUTPUT_DIR/dgemm_test_${VARIANT_NAME}.o"
    local LDD_FILE="$LOG_DIR/${VARIANT_NAME}_ldd.log"
    
    echo -ne "${CYAN}►${NC} ${VARIANT_NAME}... "
    
    # compile object
    gcc -c $CFLAGS $SOURCE_FILE -o $OBJ_NAME 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERRO (compilação)${NC}"
        return 1
    fi
    
    # link with specific library
    gcc -o $EXEC_NAME $OBJ_NAME $LDFLAGS $LIB_FLAG 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERRO (link)${NC}"
        return 1
    fi
    
    # save ldd info
    echo "Configuração para $VARIANT_NAME ($NUM_THREADS threads)" > $LDD_FILE
    echo "========================================" >> $LDD_FILE
    ldd $EXEC_NAME >> $LDD_FILE 2>&1
    
    # execute test (redirect output to suppress messages)
    $EXEC_NAME $OUTPUT_FILE $INITIAL_SIZE $FINAL_SIZE $STEP > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC}"
    else
        echo -e "${RED}ERRO (execução)${NC}"
        return 1
    fi
    
    return 0
}

# create output and logs directories
mkdir -p $OUTPUT_DIR $LOG_DIR 2>/dev/null

# TESTE 1: OpenBLAS64 Pthread
export OPENBLAS_NUM_THREADS=$NUM_THREADS
test_blas_variant_64 "OpenBLAS64Pth" "-L/usr/lib/x86_64-linux-gnu/openblas64-pthread -lopenblas64"

# TESTE 2: OpenBLAS64 OpenMP
export OPENBLAS_NUM_THREADS=$NUM_THREADS
test_blas_variant_64 "OpenBLAS64Omp" "-L/usr/lib/x86_64-linux-gnu/openblas64-openmp -lopenblas64"

# TESTE 3: BLIS64 Pthread
export BLIS_NUM_THREADS=$NUM_THREADS
test_blas_variant_64 "BLIS64Pth" "-L/usr/lib/x86_64-linux-gnu/blis64-pthread -lblis64"

# TESTE 4: BLIS64 OpenMP
export BLIS_NUM_THREADS=$NUM_THREADS
test_blas_variant_64 "BLIS64Omp" "-L/usr/lib/x86_64-linux-gnu/blis64-openmp -lblis64"

echo ""
echo "=============================================="
echo "  RESUMO DOS TESTES"
echo "=============================================="
echo ""

for variant in OpenBLAS64Pth OpenBLAS64Omp BLIS64Pth BLIS64Omp; do
    DAT_FILE="$OUTPUT_DIR/output_${variant}.dat"
    if [ -f "$DAT_FILE" ]; then
        LINES=$(wc -l < "$DAT_FILE")
        SIZE=$(du -h "$DAT_FILE" | cut -f1)
        FIRST_PERF=$(tail -n 1 "$DAT_FILE" | awk -F',' '{print $3}' | xargs)
        echo -e "  ${GREEN}✓${NC} $variant: $DAT_FILE ($LINES linhas, $SIZE)"
        echo "    Tempo médio (última matriz): ${FIRST_PERF}s"
    else
        echo -e "  ${RED}✗${NC} $variant: Arquivo não gerado"
    fi
done

echo ""
echo "Arquivos salvos em: $LOG_DIR/ e $OUTPUT_DIR/"
