#!/bin/bash

# colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

echo "=============================================="
echo "  Testes de Desempenho DGEMM - BLAS Variants"
echo "=============================================="
echo "Tamanho inicial: $INITIAL_SIZE"
echo "Tamanho final: $FINAL_SIZE"
echo "Incremento: $STEP"
echo "=============================================="
echo ""

# function to compile and test BLAS64
test_blas_variant_64() {
    local VARIANT_NAME=$1
    local LIB_FLAG=$2
    local OUTPUT_FILE="output/output_${VARIANT_NAME}.dat"
    local EXEC_NAME="output/dgemm_test_${VARIANT_NAME}"
    local OBJ_NAME="output/dgemm_test_${VARIANT_NAME}.o"
    local LDD_FILE="logs/${VARIANT_NAME}_ldd.log"
    
    echo -ne "${YELLOW}►${NC} ${VARIANT_NAME}... "
    
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
    ldd $EXEC_NAME > $LDD_FILE 2>&1
    
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

# function to compile and test BLAS (32-bit)
test_blas_variant() {
    local VARIANT_NAME=$1
    local LIB_FLAG=$2
    local OUTPUT_FILE="output/output_${VARIANT_NAME}.dat"
    local EXEC_NAME="output/dgemm_test_${VARIANT_NAME}"
    local OBJ_NAME="output/dgemm_test_${VARIANT_NAME}.o"
    local LDD_FILE="logs/${VARIANT_NAME}_ldd.log"
    
    echo -ne "${YELLOW}►${NC} ${VARIANT_NAME}... "
    
    # compile object
    gcc -c $CFLAGS $SOURCE_FILE -o $OBJ_NAME 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERRO (compilação)${NC}"
        return 1
    fi
    
    # link with specific library
    gcc -o $EXEC_NAME $OBJ_NAME -lgsl -lgslcblas -lm -fopenmp -export-dynamic $LIB_FLAG 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERRO (link)${NC}"
        return 1
    fi
    
    # save ldd info
    ldd $EXEC_NAME > $LDD_FILE 2>&1
    
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
mkdir -p output logs 2>/dev/null

test_blas_variant_64 "BLAS64" "-lblas64"

export OPENBLAS_NUM_THREADS=1
test_blas_variant_64 "OpenBLAS64" "-lopenblas64"

# TEST 3: BLIS64 (Serial - 1 thread)
export BLIS_NUM_THREADS=1
test_blas_variant_64 "BLIS64" "-lblis64"

echo ""

test_blas_variant "BLAS" "-lblas"

test_blas_variant "ATLAS" "-latlas"

# TEST 6: BLIS (Serial - 1 thread)
export BLIS_NUM_THREADS=1
test_blas_variant "BLIS" "-lblis"

echo ""
echo "=============================================="
echo "  RESUMO DOS TESTES"
echo "=============================================="
echo ""
for variant in BLAS64 OpenBLAS64 BLIS64; do
    DAT_FILE="output/output_${variant}.dat"
    if [ -f "$DAT_FILE" ]; then
        LINES=$(wc -l < "$DAT_FILE")
        SIZE=$(du -h "$DAT_FILE" | cut -f1)
        echo -e "${GREEN}✓${NC} $variant: $DAT_FILE ($LINES linhas, $SIZE)"
    else
        echo -e "${RED}✗${NC} $variant: Arquivo não gerado"
    fi
done

echo ""
for variant in BLAS ATLAS BLIS; do
    DAT_FILE="output/output_${variant}.dat"
    if [ -f "$DAT_FILE" ]; then
        LINES=$(wc -l < "$DAT_FILE")
        SIZE=$(du -h "$DAT_FILE" | cut -f1)
        echo -e "${GREEN}✓${NC} $variant: $DAT_FILE ($LINES linhas, $SIZE)"
    else
        echo -e "${RED}✗${NC} $variant: Arquivo não gerado"
    fi
done

echo ""
echo "Arquivos salvos em: logs/ e output/"
