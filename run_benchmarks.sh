#!/bin/bash

# Script para executar benchmarks no SO nativo e no Docker
# Organiza os resultados em output/{native,docker}/{alternatives,direct_compilation}

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo "=============================================="
echo "  meuGEMM - Benchmark Completo"
echo "  Nativo + Docker"
echo "=============================================="
echo ""

# Criar estrutura de diretórios
echo -e "${CYAN}[SETUP]${NC} Criando estrutura de diretórios..."
mkdir -p output/native/alternatives
mkdir -p output/native/direct_compilation
mkdir -p output/docker/alternatives
mkdir -p output/docker/direct_compilation
mkdir -p logs/native/alternatives
mkdir -p logs/native/direct_compilation
mkdir -p logs/docker/alternatives
mkdir -p logs/docker/direct_compilation

echo -e "${GREEN}✓${NC} Estrutura de diretórios criada"
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
export OUTPUT_DIR="output/native/direct_compilation"
export LOG_DIR="logs/native/direct_compilation"
./run_all_tests.sh

echo ""

# Executar testes nativos com alternatives
echo -e "${BLUE}[NATIVE]${NC} Executando testes com alternatives..."
export OUTPUT_DIR="output/native/alternatives"
export LOG_DIR="logs/native/alternatives"
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
            -e OUTPUT_DIR="output/docker/direct_compilation" \
            -e LOG_DIR="logs/docker/direct_compilation" \
            meugemm:latest ./run_all_tests.sh
        
        echo ""
        echo -e "${BLUE}[DOCKER]${NC} Executando testes com alternatives..."
        docker run --rm --privileged \
            -v $(pwd):/app \
            -e OUTPUT_DIR="output/docker/alternatives" \
            -e LOG_DIR="logs/docker/alternatives" \
            meugemm:latest ./run_all_alternatives.sh
        
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
echo "output/"
echo "├── native/"
echo "│   ├── alternatives/"
for variant in BLAS64 OpenBLAS64 BLIS64 BLAS ATLAS BLIS; do
    if [ -f "output/native/alternatives/output_${variant}.dat" ]; then
        echo "│   │   └── output_${variant}.dat ✓"
    fi
done
echo "│   └── direct_compilation/"
for variant in BLAS64 OpenBLAS64 BLIS64 BLAS ATLAS BLIS; do
    if [ -f "output/native/direct_compilation/output_${variant}.dat" ]; then
        echo "│       └── output_${variant}.dat ✓"
    fi
done
echo "└── docker/"
echo "    ├── alternatives/"
for variant in BLAS64 OpenBLAS64 BLIS64 BLAS ATLAS BLIS; do
    if [ -f "output/docker/alternatives/output_${variant}.dat" ]; then
        echo "    │   └── output_${variant}.dat ✓"
    fi
done
echo "    └── direct_compilation/"
for variant in BLAS64 OpenBLAS64 BLIS64 BLAS ATLAS BLIS; do
    if [ -f "output/docker/direct_compilation/output_${variant}.dat" ]; then
        echo "        └── output_${variant}.dat ✓"
    fi
done

echo ""
echo "logs/"
echo "├── native/"
echo "│   ├── alternatives/"
echo "│   └── direct_compilation/"
echo "└── docker/"
echo "    ├── alternatives/"
echo "    └── direct_compilation/"

echo ""
echo -e "${GREEN}Benchmark completo finalizado!${NC}"
echo ""

