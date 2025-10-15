#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=============================================="
echo "  meuGEMM - Docker Helper Script"
echo "=============================================="
echo ""

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}[ERRO]${NC} Docker não está instalado!"
    echo "Instale o Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Verificar se Docker Compose está instalado
if ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}[AVISO]${NC} Docker Compose não encontrado, tentando 'docker compose'..."
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Função para mostrar menu
show_menu() {
    echo ""
    echo "Escolha uma opção:"
    echo ""
    echo "  1) Build - Construir imagem Docker"
    echo "  2) Run Tests - Executar testes padrão (run_all_tests.sh)"
    echo "  3) Run Alternatives - Executar com update-alternatives (BLAS + BLAS64)"
    echo "  4) Interactive - Entrar no container interativamente"
    echo "  5) Clean - Limpar containers e imagens"
    echo "  6) Logs - Ver logs dos containers"
    echo "  7) Results - Ver resultados gerados"
    echo "  0) Sair"
    echo ""
    echo -n "Opção: "
}

# Função para construir imagem
build_image() {
    echo -e "${BLUE}[BUILD]${NC} Construindo imagem Docker..."
    docker build -t meugemm:latest .
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} Imagem construída com sucesso!"
    else
        echo -e "${RED}✗${NC} Erro ao construir imagem"
        return 1
    fi
}

# Função para executar testes padrão
run_tests() {
    echo -e "${BLUE}[RUN]${NC} Executando testes padrão (linkagem direta)..."
    docker run --rm -v $(pwd)/output:/app/output -v $(pwd)/logs:/app/logs meugemm:latest
}

# Função para executar com alternatives (BLAS + BLAS64)
run_alternatives() {
    echo -e "${BLUE}[RUN]${NC} Executando com update-alternatives (BLAS + BLAS64)..."
    docker run --rm --privileged -v $(pwd)/output:/app/output -v $(pwd)/logs:/app/logs meugemm:latest ./run_all_alternatives.sh
}

# Função para entrar no container interativamente
run_interactive() {
    echo -e "${BLUE}[INTERACTIVE]${NC} Entrando no container..."
    docker run --rm -it -v $(pwd)/output:/app/output -v $(pwd)/logs:/app/logs meugemm:latest /bin/bash
}

# Função para limpar containers e imagens
clean() {
    echo -e "${YELLOW}[CLEAN]${NC} Limpando containers e imagens..."
    docker container prune -f
    docker image rm meugemm:latest 2>/dev/null
    echo -e "${GREEN}✓${NC} Limpeza concluída!"
}

# Função para ver logs
view_logs() {
    echo -e "${BLUE}[LOGS]${NC} Últimos logs:"
    echo ""
    docker ps -a | grep meugemm
}

# Função para ver resultados
view_results() {
    echo -e "${BLUE}[RESULTS]${NC} Arquivos gerados:"
    echo ""
    echo "=== Output (*.dat) ==="
    ls -lh output/*.dat 2>/dev/null || echo "Nenhum arquivo .dat encontrado"
    echo ""
    echo "=== Logs (*_ldd.log) ==="
    ls -lh logs/*_ldd.log 2>/dev/null || echo "Nenhum arquivo .log encontrado"
}

# Menu principal
if [ $# -eq 0 ]; then
    # Modo interativo
    while true; do
        show_menu
        read option
        
        case $option in
            1) build_image ;;
            2) run_tests ;;
            3) run_alternatives ;;
            4) run_interactive ;;
            5) clean ;;
            6) view_logs ;;
            7) view_results ;;
            0) 
                echo "Saindo..."
                exit 0
                ;;
            *)
                echo -e "${RED}Opção inválida!${NC}"
                ;;
        esac
        
        echo ""
        echo "Pressione Enter para continuar..."
        read
    done
else
    # Modo comando direto
    case $1 in
        build) build_image ;;
        run|tests) run_tests ;;
        alternatives|alt) run_alternatives ;;
        interactive|bash) run_interactive ;;
        clean) clean ;;
        logs) view_logs ;;
        results) view_results ;;
        *)
            echo "Uso: $0 [build|run|alternatives|interactive|clean|logs|results]"
            echo ""
            echo "Comandos:"
            echo "  build        - Construir imagem Docker"
            echo "  run|tests    - Executar testes padrão (linkagem direta)"
            echo "  alternatives - Executar com update-alternatives"
            echo "  interactive  - Modo interativo (bash)"
            echo "  clean        - Limpar containers e imagens"
            echo "  logs         - Ver logs"
            echo "  results      - Ver resultados"
            echo ""
            echo "Ou execute sem argumentos para modo interativo"
            exit 1
            ;;
    esac
fi
