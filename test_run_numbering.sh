#!/bin/bash

# Script de teste para validar a função get_next_run_number()

# Cores
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

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

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}Teste da função get_next_run_number()${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Criar diretório de teste
TEST_DIR="test_output_structure"
rm -rf "$TEST_DIR" 2>/dev/null
mkdir -p "$TEST_DIR"

echo -e "${CYAN}[TESTE 1]${NC} Diretório vazio - deve retornar 001"
result=$(get_next_run_number "$TEST_DIR")
if [ "$result" == "001" ]; then
    echo -e "${GREEN}✓ PASSOU${NC} - Resultado: $result"
else
    echo -e "${RED}✗ FALHOU${NC} - Esperado: 001, Obtido: $result"
fi
echo ""

echo -e "${CYAN}[TESTE 2]${NC} Criando pastas 001, 002, 003 - deve retornar 004"
mkdir -p "$TEST_DIR"/{001,002,003}
result=$(get_next_run_number "$TEST_DIR")
if [ "$result" == "004" ]; then
    echo -e "${GREEN}✓ PASSOU${NC} - Resultado: $result"
else
    echo -e "${RED}✗ FALHOU${NC} - Esperado: 004, Obtido: $result"
fi
echo ""

echo -e "${CYAN}[TESTE 3]${NC} Criando pastas não sequenciais 001, 005, 010 - deve retornar 011"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR"/{001,005,010}
result=$(get_next_run_number "$TEST_DIR")
if [ "$result" == "011" ]; then
    echo -e "${GREEN}✓ PASSOU${NC} - Resultado: $result"
else
    echo -e "${RED}✗ FALHOU${NC} - Esperado: 011, Obtido: $result"
fi
echo ""

echo -e "${CYAN}[TESTE 4]${NC} Testando estrutura completa"
rm -rf "$TEST_DIR"
mkdir -p "$TEST_DIR/single/native/alternatives"
mkdir -p "$TEST_DIR/single/native/direct_compilation"
mkdir -p "$TEST_DIR/single/docker/alternatives"
mkdir -p "$TEST_DIR/single/docker/direct_compilation"

num1=$(get_next_run_number "$TEST_DIR/single/native/alternatives")
num2=$(get_next_run_number "$TEST_DIR/single/native/direct_compilation")
num3=$(get_next_run_number "$TEST_DIR/single/docker/alternatives")
num4=$(get_next_run_number "$TEST_DIR/single/docker/direct_compilation")

if [ "$num1" == "001" ] && [ "$num2" == "001" ] && [ "$num3" == "001" ] && [ "$num4" == "001" ]; then
    echo -e "${GREEN}✓ PASSOU${NC} - Todos retornaram 001"
    echo "  Native Alt: $num1"
    echo "  Native Dir: $num2"
    echo "  Docker Alt: $num3"
    echo "  Docker Dir: $num4"
else
    echo -e "${RED}✗ FALHOU${NC} - Algum valor incorreto"
    echo "  Native Alt: $num1 (esperado: 001)"
    echo "  Native Dir: $num2 (esperado: 001)"
    echo "  Docker Alt: $num3 (esperado: 001)"
    echo "  Docker Dir: $num4 (esperado: 001)"
fi
echo ""

echo -e "${CYAN}[TESTE 5]${NC} Simulando múltiplas execuções"
mkdir -p "$TEST_DIR/single/native/alternatives/001"
mkdir -p "$TEST_DIR/single/native/alternatives/002"
result=$(get_next_run_number "$TEST_DIR/single/native/alternatives")
if [ "$result" == "003" ]; then
    echo -e "${GREEN}✓ PASSOU${NC} - Resultado: $result"
else
    echo -e "${RED}✗ FALHOU${NC} - Esperado: 003, Obtido: $result"
fi
echo ""

# Limpar
echo -e "${CYAN}[LIMPEZA]${NC} Removendo diretório de teste..."
rm -rf "$TEST_DIR"
echo -e "${GREEN}✓ Concluído${NC}"
echo ""

echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}Testes finalizados!${NC}"
echo -e "${CYAN}========================================${NC}"
