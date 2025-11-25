#!/bin/bash

# Script para executar benchmarks no SO nativo e no Docker
# Organiza os resultados em output/single/{native,docker}/{alternatives,direct_compilation}/{001,002,...}

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para obter o próximo número de execução
get_next_run_number() {
    local base_dir=$1
    mkdir -p "$base_dir" 2>/dev/null
    
    local max_num=0
    for dir in "$base_dir"/[0-9][0-9][0-9]; do
        if [ -d "$dir" ]; then
            num=$(basename "$dir")
            # Remove leading zeros for comparison
            num=$((10#$num))
            if [ "$num" -gt "$max_num" ]; then
                max_num=$num
            fi
        fi
    done
    
    printf "%03d" $((max_num + 1))
}

echo "=============================================="
echo "  meuGEMM - Benchmark Completo"
echo "  Nativo + Docker"
echo "=============================================="
echo ""

# Criar estrutura de diretórios base
echo -e "${CYAN}[SETUP]${NC} Criando estrutura de diretórios..."
mkdir -p output/single/native/alternatives
mkdir -p output/single/native/direct_compilation
mkdir -p output/single/docker/alternatives
mkdir -p output/single/docker/direct_compilation
mkdir -p logs/single/native/alternatives
mkdir -p logs/single/native/direct_compilation
mkdir -p logs/single/docker/alternatives
mkdir -p logs/single/docker/direct_compilation

# Obter números de execução para esta rodada
RUN_NUM_NATIVE_ALT=$(get_next_run_number "output/single/native/alternatives")
RUN_NUM_NATIVE_DIR=$(get_next_run_number "output/single/native/direct_compilation")
RUN_NUM_DOCKER_ALT=$(get_next_run_number "output/single/docker/alternatives")
RUN_NUM_DOCKER_DIR=$(get_next_run_number "output/single/docker/direct_compilation")

echo -e "${GREEN}✓${NC} Estrutura de diretórios criada"
echo -e "${CYAN}[INFO]${NC} Números de execução: Native Alt=${RUN_NUM_NATIVE_ALT}, Native Dir=${RUN_NUM_NATIVE_DIR}, Docker Alt=${RUN_NUM_DOCKER_ALT}, Docker Dir=${RUN_NUM_DOCKER_DIR}"
echo ""

# =============================================
# EXECUÇÃO NATIVA
# =============================================
echo "=============================================="
echo "  FASE 1: EXECUÇÃO NATIVA"
echo "=============================================="
echo ""

# Executar testes nativos com linkagem direta
echo -e "${BLUE}[NATIVE]${NC} Executando testes com linkagem direta..."
export OUTPUT_DIR="output/single/native/direct_compilation/$RUN_NUM_NATIVE_DIR"
export LOG_DIR="logs/single/native/direct_compilation/$RUN_NUM_NATIVE_DIR"
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"
./run_all_tests.sh

echo ""

# Executar testes nativos com alternatives
echo -e "${BLUE}[NATIVE]${NC} Executando testes com alternatives..."
export OUTPUT_DIR="output/single/native/alternatives/$RUN_NUM_NATIVE_ALT"
export LOG_DIR="logs/single/native/alternatives/$RUN_NUM_NATIVE_ALT"
mkdir -p "$OUTPUT_DIR" "$LOG_DIR"
./run_all_alternatives.sh

echo ""
echo -e "${GREEN}✓${NC} Testes nativos concluídos"
echo ""

# =============================================
# EXECUÇÃO NO DOCKER
# =============================================
echo "=============================================="
echo "  FASE 2: EXECUÇÃO NO DOCKER"
echo "=============================================="
echo ""

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[ERRO]${NC} Docker não está instalado!"
    echo "Pulando execução no Docker..."
else
    # Verificar se a imagem existe
    if ! docker image inspect meugemm:latest &> /dev/null; then
        echo -e "${YELLOW}[AVISO]${NC} Imagem 'meugemm:latest' não encontrada!"
        echo "Por favor, execute primeiro: ./docker-run.sh build"
        echo "Ou: docker build -t meugemm:latest ."
        echo ""
        echo "Pulando execução no Docker..."
    else
        echo -e "${GREEN}✓${NC} Imagem Docker encontrada"
        echo ""
        
        echo -e "${BLUE}[DOCKER]${NC} Executando testes com linkagem direta..."
        docker run --rm \
            -v $(pwd):/app \
            -e OUTPUT_DIR="output/single/docker/direct_compilation/$RUN_NUM_DOCKER_DIR" \
            -e LOG_DIR="logs/single/docker/direct_compilation/$RUN_NUM_DOCKER_DIR" \
            meugemm:latest bash -c "mkdir -p \$OUTPUT_DIR \$LOG_DIR && ./run_all_tests.sh"
        
        echo ""
        echo -e "${BLUE}[DOCKER]${NC} Executando testes com alternatives..."
        docker run --rm --privileged \
            -v $(pwd):/app \
            -e OUTPUT_DIR="output/single/docker/alternatives/$RUN_NUM_DOCKER_ALT" \
            -e LOG_DIR="logs/single/docker/alternatives/$RUN_NUM_DOCKER_ALT" \
            meugemm:latest bash -c "mkdir -p \$OUTPUT_DIR \$LOG_DIR && ./run_all_alternatives.sh"
        
        echo ""
        echo -e "${GREEN}✓${NC} Testes no Docker concluídos"
    fi
fi

echo ""
echo "=============================================="
echo "  RESUMO FINAL"
echo "=============================================="
echo ""

echo "Estrutura de arquivos criada:"
echo ""
echo "output/single/"
echo "├── native/"
echo "│   ├── alternatives/$RUN_NUM_NATIVE_ALT/"
for variant in BLAS64 OpenBLAS64 BLIS64 BLAS ATLAS BLIS; do
    if [ -f "output/single/native/alternatives/$RUN_NUM_NATIVE_ALT/output_${variant}.dat" ]; then
        echo "│   │   └── output_${variant}.dat ✓"
    fi
done
echo "│   └── direct_compilation/$RUN_NUM_NATIVE_DIR/"
for variant in BLAS64 OpenBLAS64 BLIS64 BLAS ATLAS BLIS; do
    if [ -f "output/single/native/direct_compilation/$RUN_NUM_NATIVE_DIR/output_${variant}.dat" ]; then
        echo "│       └── output_${variant}.dat ✓"
    fi
done
echo "└── docker/"
echo "    ├── alternatives/$RUN_NUM_DOCKER_ALT/"
for variant in BLAS64 OpenBLAS64 BLIS64 BLAS ATLAS BLIS; do
    if [ -f "output/single/docker/alternatives/$RUN_NUM_DOCKER_ALT/output_${variant}.dat" ]; then
        echo "    │   └── output_${variant}.dat ✓"
    fi
done
echo "    └── direct_compilation/$RUN_NUM_DOCKER_DIR/"
for variant in BLAS64 OpenBLAS64 BLIS64 BLAS ATLAS BLIS; do
    if [ -f "output/single/docker/direct_compilation/$RUN_NUM_DOCKER_DIR/output_${variant}.dat" ]; then
        echo "        └── output_${variant}.dat ✓"
    fi
done

echo ""
echo "logs/single/"
echo "├── native/"
echo "│   ├── alternatives/$RUN_NUM_NATIVE_ALT/"
echo "│   └── direct_compilation/$RUN_NUM_NATIVE_DIR/"
echo "└── docker/"
echo "    ├── alternatives/$RUN_NUM_DOCKER_ALT/"
echo "    └── direct_compilation/$RUN_NUM_DOCKER_DIR/"

echo ""

# =============================================
# EXECUÇÃO MULTITHREAD
# =============================================
echo "=============================================="
echo "  FASE 3: EXECUÇÃO MULTITHREAD"
echo "=============================================="
echo ""

echo -e "${CYAN}[INFO]${NC} Executando benchmarks multithread..."
./run_benchmarks_multithread.sh

echo ""
echo "=============================================="
echo "  BENCHMARK COMPLETO FINALIZADO"
echo "=============================================="
echo ""
echo "Estrutura completa de resultados:"
echo ""
echo "1. Single-thread (output/single/):"
echo "   - native/alternatives/$RUN_NUM_NATIVE_ALT/"
echo "   - native/direct_compilation/$RUN_NUM_NATIVE_DIR/"
echo "   - docker/alternatives/$RUN_NUM_DOCKER_ALT/"
echo "   - docker/direct_compilation/$RUN_NUM_DOCKER_DIR/"
echo ""
echo "2. Multithread (output/multi/):"
echo "   - native/alternatives/{run_number}/"
echo "   - native/direct_compilation/{run_number}/"
echo "   - docker/alternatives/{run_number}/"
echo "   - docker/direct_compilation/{run_number}/"
echo ""
echo -e "${GREEN}Todos os benchmarks finalizados com sucesso!${NC}"
echo ""

