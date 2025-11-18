#!/bin/bash

# Script para executar benchmarks multithread no SO nativo e no Docker
# Organiza os resultados em output_multi/{native,docker}/{alternatives,direct_compilation}

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Número de threads (pode ser personalizado)
: "${NUM_THREADS:=4}"

echo "=============================================="
echo "  meuGEMM - Benchmark Multithread"
echo "  Nativo + Docker ($NUM_THREADS threads)"
echo "=============================================="
echo ""

# Criar estrutura de diretórios
echo -e "${CYAN}[SETUP]${NC} Criando estrutura de diretórios..."
mkdir -p output_multi/native/alternatives
mkdir -p output_multi/native/direct_compilation
mkdir -p output_multi/docker/alternatives
mkdir -p output_multi/docker/direct_compilation
mkdir -p logs_multi/native/alternatives
mkdir -p logs_multi/native/direct_compilation
mkdir -p logs_multi/docker/alternatives
mkdir -p logs_multi/docker/direct_compilation

echo -e "${GREEN}✓${NC} Estrutura de diretórios criada"
echo ""

# =============================================
# EXECUÇÃO NATIVA
# =============================================
echo "=============================================="
echo "  FASE 1: EXECUÇÃO NATIVA (MULTITHREAD)"
echo "=============================================="
echo ""

# Executar testes nativos com linkagem direta
echo -e "${BLUE}[NATIVE]${NC} Executando testes com linkagem direta..."
export OUTPUT_DIR="output_multi/native/direct_compilation"
export LOG_DIR="logs_multi/native/direct_compilation"
export NUM_THREADS=$NUM_THREADS
./run_all_tests_multithread.sh

echo ""

# Executar testes nativos com alternatives
echo -e "${BLUE}[NATIVE]${NC} Executando testes com alternatives..."
export OUTPUT_DIR="output_multi/native/alternatives"
export LOG_DIR="logs_multi/native/alternatives"
export NUM_THREADS=$NUM_THREADS
./run_all_alternatives_multithread.sh

echo ""
echo -e "${GREEN}✓${NC} Testes nativos multithread concluídos"
echo ""

# =============================================
# EXECUÇÃO NO DOCKER
# =============================================
echo "=============================================="
echo "  FASE 2: EXECUÇÃO NO DOCKER (MULTITHREAD)"
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
            -e OUTPUT_DIR="output_multi/docker/direct_compilation" \
            -e LOG_DIR="logs_multi/docker/direct_compilation" \
            -e NUM_THREADS=$NUM_THREADS \
            meugemm:latest ./run_all_tests_multithread.sh
        
        echo ""
        echo -e "${BLUE}[DOCKER]${NC} Executando testes com alternatives..."
        docker run --rm --privileged \
            -v $(pwd):/app \
            -e OUTPUT_DIR="output_multi/docker/alternatives" \
            -e LOG_DIR="logs_multi/docker/alternatives" \
            -e NUM_THREADS=$NUM_THREADS \
            meugemm:latest ./run_all_alternatives_multithread.sh
        
        echo ""
        echo -e "${GREEN}✓${NC} Testes no Docker multithread concluídos"
    fi
fi

echo ""
echo "=============================================="
echo "  RESUMO FINAL (MULTITHREAD)"
echo "=============================================="
echo ""

echo "Estrutura de arquivos criada:"
echo ""
echo "output_multi/"
echo "├── native/"
echo "│   ├── alternatives/"
for variant in OpenBLAS64Pth OpenBLAS64Omp BLIS64Pth BLIS64Omp; do
    if [ -f "output_multi/native/alternatives/output_${variant}.dat" ]; then
        echo "│   │   └── output_${variant}.dat ✓"
    fi
done
echo "│   └── direct_compilation/"
for variant in OpenBLAS64Pth OpenBLAS64Omp BLIS64Pth BLIS64Omp; do
    if [ -f "output_multi/native/direct_compilation/output_${variant}.dat" ]; then
        echo "│       └── output_${variant}.dat ✓"
    fi
done
echo "└── docker/"
echo "    ├── alternatives/"
for variant in OpenBLAS64Pth OpenBLAS64Omp BLIS64Pth BLIS64Omp; do
    if [ -f "output_multi/docker/alternatives/output_${variant}.dat" ]; then
        echo "    │   └── output_${variant}.dat ✓"
    fi
done
echo "    └── direct_compilation/"
for variant in OpenBLAS64Pth OpenBLAS64Omp BLIS64Pth BLIS64Omp; do
    if [ -f "output_multi/docker/direct_compilation/output_${variant}.dat" ]; then
        echo "        └── output_${variant}.dat ✓"
    fi
done

echo ""
echo "logs_multi/"
echo "├── native/"
echo "│   ├── alternatives/"
echo "│   └── direct_compilation/"
echo "└── docker/"
echo "    ├── alternatives/"
echo "    └── direct_compilation/"

echo ""
echo -e "${GREEN}Benchmark multithread finalizado!${NC}"
echo ""
