#!/bin/bash

# Script para testar bibliotecas multithread usando update-alternatives

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

# Diretórios de saída (com fallback para valores padrão)
: "${OUTPUT_DIR:=output/multi/native/alternatives/001}"
: "${LOG_DIR:=logs/multi/native/alternatives/001}"

# Número de threads (pode ser ajustado via variável de ambiente)
: "${NUM_THREADS:=4}"

echo "=============================================="
echo "  Testes Multithread - update-alternatives"
echo "=============================================="
echo "Parâmetros: $INITIAL_SIZE $FINAL_SIZE $STEP"
echo "Threads: $NUM_THREADS"
echo "Output: $OUTPUT_DIR | Logs: $LOG_DIR"
echo "=============================================="

compile_object_64() {
    gcc -c -O2 -Wall -fopenmp $SOURCE_FILE -o $OUTPUT_DIR/dgemm_test64.o 2>/dev/null
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}[ERRO]${NC} Falha na compilação do objeto 64 bits"
        return 1
    fi
    return 0
}

link_executable_64() {
    local LIB_PATH=$1
    gcc -o $OUTPUT_DIR/dgemm_test64 $OUTPUT_DIR/dgemm_test64.o -lgsl -lgslcblas -lm $LIB_PATH -fopenmp -export-dynamic 2>/dev/null
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}[ERRO]${NC} Falha no link do executável 64 bits"
        return 1
    fi
    return 0
}

run_test_blas64() {
    local VARIANT_NAME=$1
    local SEARCH_PATTERN=$2
    local OUTPUT_FILE="$OUTPUT_DIR/output_${VARIANT_NAME}.dat"
    local LDD_FILE="$LOG_DIR/${VARIANT_NAME}_ldd.log"
    
    echo -ne "${CYAN}►${NC} ${VARIANT_NAME}... "
    
    # Find alternative directory
    ALT_PATH=$(update-alternatives --list libblas64.so.3-x86_64-linux-gnu 2>/dev/null | grep "$SEARCH_PATTERN")
    
    if [ -z "$ALT_PATH" ]; then
        echo -e "${RED}ERRO (alternativa não encontrada)${NC}"
        return 1
    fi
    
    # Extract directory and build path to the full OpenBLAS library
    ALT_DIR=$(dirname "$ALT_PATH")
    
    # For OpenBLAS, use libopenblas64.so.0; for BLIS, use libblis64.so.4
    if [[ "$SEARCH_PATTERN" == *"openblas"* ]]; then
        LIB_PATH="$ALT_DIR/libopenblas64.so.0"
    else
        LIB_PATH="$ALT_DIR/libblis64.so.4"
    fi
    
    # Pequeno delay para garantir que o symlink foi atualizado
    sleep 0.1
    
    # Linkar com nova biblioteca usando caminho completo
    link_executable_64 "$LIB_PATH"
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERRO (link)${NC}"
        return 1
    fi

    # Save information
    echo "Configuração para $VARIANT_NAME (64 bits, $NUM_THREADS threads)" > $LDD_FILE
    echo "========================================" >> $LDD_FILE
    echo "Biblioteca: $LIB_PATH" >> $LDD_FILE
    echo "" >> $LDD_FILE
    echo "LDD Output:" >> $LDD_FILE
    echo "========================================" >> $LDD_FILE
    ldd $OUTPUT_DIR/dgemm_test64 >> $LDD_FILE 2>&1
    
    # Executar teste (suprimir output)
    $OUTPUT_DIR/dgemm_test64 $OUTPUT_FILE $INITIAL_SIZE $FINAL_SIZE $STEP > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC}"
        return 0
    else
        echo -e "${RED}ERRO (execução)${NC}"
        return 1
    fi
}

# Verificar se update-alternatives está disponível
if ! command -v update-alternatives &> /dev/null; then
    echo -e "${RED}[ERRO]${NC} update-alternatives não encontrado"
    exit 1
fi

# Criar diretórios se não existirem (para execução direta do script)
mkdir -p "$OUTPUT_DIR" "$LOG_DIR" 2>/dev/null

echo ""

# Verificar alternativas BLAS64 disponíveis
if update-alternatives --list libblas64.so.3-x86_64-linux-gnu > /dev/null 2>&1; then
    compile_object_64
    
    if [ $? -eq 0 ]; then
        link_executable_64
        
        if [ $? -eq 0 ]; then
            echo ""
            
            # TESTE 1: OpenBLAS64 Pthread
            export OPENBLAS_NUM_THREADS=$NUM_THREADS
            run_test_blas64 "OpenBLAS64Pth" "openblas64-pthread"
            
            # TESTE 2: OpenBLAS64 OpenMP
            export OPENBLAS_NUM_THREADS=$NUM_THREADS
            run_test_blas64 "OpenBLAS64Omp" "openblas64-openmp"
            
            # TESTE 3: BLIS64 Pthread
            export BLIS_NUM_THREADS=$NUM_THREADS
            run_test_blas64 "BLIS64Pth" "blis64-pthread"
            
            # TESTE 4: BLIS64 OpenMP
            export BLIS_NUM_THREADS=$NUM_THREADS
            run_test_blas64 "BLIS64Omp" "blis64-openmp"
        fi
    fi
else
    echo -e "${YELLOW}⚠${NC} Alternativas BLAS64 não disponíveis"
fi

echo ""
echo "=============================================="
echo "  RESUMO GERAL DOS TESTES"
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
