#!/bin/bash

# Script unificado para testar BLAS e BLAS64 usando update-alternatives

# colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # no color

# parameters
INITIAL_SIZE=32
FINAL_SIZE=1024
STEP=32

# source file
SOURCE_FILE="teste_GSL_DGEMM.c"

# Diretórios de saída (com fallback para valores padrão)
: "${OUTPUT_DIR:=output/alternatives}"
: "${LOG_DIR:=logs/alternatives}"

echo "=============================================="
echo "Parâmetros: $INITIAL_SIZE $FINAL_SIZE $STEP"
echo "Output: $OUTPUT_DIR | Logs: $LOG_DIR"
echo "=============================================="

# function to find alternative number for BLAS64
find_alternative_number_64() {
    local search_string=$1
    local result=$(update-alternatives --list libblas64.so.3-x86_64-linux-gnu 2>/dev/null | grep -n "$search_string" | cut -d: -f1)
    echo "$result"
}

# function to find alternative number for BLAS
find_alternative_number() {
    local search_string=$1
    local result=$(update-alternatives --list libblas.so.3-x86_64-linux-gnu 2>/dev/null | grep -n "$search_string" | cut -d: -f1)
    echo "$result"
}

compile_object_64() {
    gcc -c -O2 -Wall -fopenmp $SOURCE_FILE -o $OUTPUT_DIR/dgemm_test64.o 2>/dev/null
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}[ERRO]${NC} Falha na compilação do objeto 64 bits"
        return 1
    fi
    return 0
}

link_executable_64() {
    gcc -o $OUTPUT_DIR/dgemm_test64 $OUTPUT_DIR/dgemm_test64.o -lgsl -lgslcblas -lm -lblas64 -fopenmp -export-dynamic 2>/dev/null
    
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
    
    # Find alternative number
    ALT_NUMBER=$(find_alternative_number_64 "$SEARCH_PATTERN")
    
    if [ -z "$ALT_NUMBER" ]; then
        echo -e "${RED}ERRO (alternativa não encontrada)${NC}"
        return 1
    fi
    
    # Configurar alternativa
    echo "$ALT_NUMBER" | update-alternatives --config libblas64.so.3-x86_64-linux-gnu > /dev/null 2>&1

    # Save information
    echo "Configuração para $VARIANT_NAME (64 bits)" > $LDD_FILE
    echo "========================================" >> $LDD_FILE
    update-alternatives --display libblas64.so.3-x86_64-linux-gnu >> $LDD_FILE 2>&1
    echo "" >> $LDD_FILE
    echo "LDD Output:" >> $LDD_FILE
    echo "========================================" >> $LDD_FILE
    ldd $OUTPUT_DIR/dgemm_test64 >> $LDD_FILE 2>&1
    
    # Linkar com nova biblioteca
    link_executable_64
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERRO (link)${NC}"
        return 1
    fi
    
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

compile_object() {
    gcc -c -O2 -Wall -fopenmp $SOURCE_FILE -o $OUTPUT_DIR/dgemm_test.o 2>/dev/null
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}[ERRO]${NC} Falha na compilação do objeto"
        return 1
    fi
    return 0
}

link_executable() {
    gcc -o $OUTPUT_DIR/dgemm_test $OUTPUT_DIR/dgemm_test.o -lgsl -lgslcblas -lm -lblas -fopenmp -export-dynamic 2>/dev/null
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}[ERRO]${NC} Falha no link do executável"
        return 1
    fi
    return 0
}

run_test_blas() {
    local VARIANT_NAME=$1
    local SEARCH_PATTERN=$2
    local OUTPUT_FILE="$OUTPUT_DIR/output_${VARIANT_NAME}.dat"
    local LDD_FILE="$LOG_DIR/${VARIANT_NAME}_ldd.log"
    
    echo -ne "${CYAN}►${NC} ${VARIANT_NAME}... "
    
    # Find alternative number
    ALT_NUMBER=$(find_alternative_number "$SEARCH_PATTERN")
    
    if [ -z "$ALT_NUMBER" ]; then
        echo -e "${RED}ERRO (alternativa não encontrada)${NC}"
        return 1
    fi
    
    # Configurar alternativa
    echo "$ALT_NUMBER" | update-alternatives --config libblas.so.3-x86_64-linux-gnu > /dev/null 2>&1

    # Save information
    echo "Configuração para $VARIANT_NAME" > $LDD_FILE
    echo "========================================" >> $LDD_FILE
    update-alternatives --display libblas.so.3-x86_64-linux-gnu >> $LDD_FILE 2>&1
    echo "" >> $LDD_FILE
    echo "LDD Output:" >> $LDD_FILE
    echo "========================================" >> $LDD_FILE
    ldd $OUTPUT_DIR/dgemm_test >> $LDD_FILE 2>&1
    
    # Linkar com nova biblioteca
    link_executable
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERRO (link)${NC}"
        return 1
    fi
    
    # Executar teste (suprimir output)
    $OUTPUT_DIR/dgemm_test $OUTPUT_FILE $INITIAL_SIZE $FINAL_SIZE $STEP > /dev/null 2>&1
    
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

# Criar diretórios se não existirem
mkdir -p $OUTPUT_DIR $LOG_DIR 2>/dev/null

echo ""

# Verificar alternativas BLAS64 disponíveis
if update-alternatives --list libblas64.so.3-x86_64-linux-gnu > /dev/null 2>&1; then
    compile_object_64
    
    if [ $? -eq 0 ]; then
        link_executable_64
        
        if [ $? -eq 0 ]; then
            echo ""
            
            # TESTE 1: BLAS64 Referência
            run_test_blas64 "BLAS64" "blas64/libblas64"
            
            # TESTE 2: OpenBLAS64 Serial
            export OPENBLAS_NUM_THREADS=1
            run_test_blas64 "OpenBLAS64" "openblas64-serial"
            
            # TESTE 3: BLIS64
            export BLIS_NUM_THREADS=1
            run_test_blas64 "BLIS64" "blis64-openmp"
        fi
    fi
else
    echo -e "${YELLOW}⚠${NC} Alternativas BLAS64 não disponíveis, pulando testes 64 bits"
fi

# Verificar alternativas BLAS disponíveis
if update-alternatives --list libblas.so.3-x86_64-linux-gnu > /dev/null 2>&1; then
    compile_object
    
    if [ $? -eq 0 ]; then
        link_executable
        
        if [ $? -eq 0 ]; then
            echo ""
            
            # TESTE 1: BLAS Referência
            run_test_blas "BLAS" "blas/libblas"
            
            # TESTE 2: ATLAS
            run_test_blas "ATLAS" "atlas/libblas"
            
            # TESTE 3: BLIS
            export BLIS_NUM_THREADS=1
            run_test_blas "BLIS" "blis-openmp"
        fi
    fi
else
    echo -e "${YELLOW}⚠${NC} Alternativas BLAS não disponíveis, pulando testes"
fi

echo ""
echo "=============================================="
echo "  RESUMO GERAL DOS TESTES"
echo "=============================================="
echo ""

for variant in BLAS64 OpenBLAS64 BLIS64; do
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

for variant in BLAS ATLAS BLIS; do
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
