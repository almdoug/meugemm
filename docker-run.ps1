# Script para facilitar o uso do Docker no projeto meuGEMM
# Versão PowerShell para Windows

# Função para exibir mensagens coloridas
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-Host "==============================================" -ForegroundColor Cyan
Write-Host "  meuGEMM - Docker Helper Script (Windows)" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan
Write-Host ""

# Verificar se Docker está instalado
try {
    $null = docker --version
} catch {
    Write-ColorOutput "[ERRO] Docker não está instalado!" "Red"
    Write-ColorOutput "Instale o Docker: https://docs.docker.com/get-docker/" "Yellow"
    exit 1
}

# Verificar se Docker Compose está disponível
$DOCKER_COMPOSE = "docker compose"
try {
    $null = docker-compose --version 2>$null
    $DOCKER_COMPOSE = "docker-compose"
} catch {
    # Usa 'docker compose' por padrão
}

# Função para mostrar menu
function Show-Menu {
    Write-Host ""
    Write-Host "Escolha uma opção:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1) Build - Construir imagem Docker"
    Write-Host "  2) Run Tests - Executar testes padrão (run_all_tests.sh)"
    Write-Host "  3) Run Alternatives - Executar com update-alternatives (BLAS + BLAS64)"
    Write-Host "  4) Interactive - Entrar no container interativamente"
    Write-Host "  5) Clean - Limpar containers e imagens"
    Write-Host "  6) Logs - Ver logs dos containers"
    Write-Host "  7) Results - Ver resultados gerados"
    Write-Host "  0) Sair"
    Write-Host ""
    $option = Read-Host "Opção"
    return $option
}

# Função para construir imagem
function Build-Image {
    Write-ColorOutput "[BUILD] Construindo imagem Docker..." "Blue"
    docker build -t meugemm:latest .
    
    if ($LASTEXITCODE -eq 0) {
        Write-ColorOutput "Imagem construida com sucesso!" "Green"
    } else {
        Write-ColorOutput "Erro ao construir imagem" "Red"
        return 1
    }
}

# Função para executar testes padrão
function Run-Tests {
    Write-ColorOutput "[RUN] Executando testes padrão (linkagem direta)..." "Blue"
    $currentPath = (Get-Location).Path
    docker run --rm -v "$($currentPath)/output:/app/output" -v "$($currentPath)/logs:/app/logs" meugemm:latest
}

# Função para executar com alternatives (BLAS + BLAS64)
function Run-Alternatives {
    Write-ColorOutput "[RUN] Executando com update-alternatives (BLAS + BLAS64)..." "Blue"
    $currentPath = (Get-Location).Path
    docker run --rm --user root --privileged -v "$($currentPath)/output:/app/output" -v "$($currentPath)/logs:/app/logs" meugemm:latest ./run_all_alternatives.sh
}

# Função para entrar no container interativamente
function Run-Interactive {
    Write-ColorOutput "[INTERACTIVE] Entrando no container..." "Blue"
    $currentPath = (Get-Location).Path
    docker run --rm -it -v "$($currentPath)/output:/app/output" -v "$($currentPath)/logs:/app/logs" meugemm:latest /bin/bash
}

# Função para limpar containers e imagens
function Clean-Docker {
    Write-ColorOutput "[CLEAN] Limpando containers e imagens..." "Yellow"
    docker container prune -f
    docker image rm meugemm:latest 2>$null
    Write-ColorOutput "Limpeza concluida!" "Green"
}

# Função para ver logs
function View-Logs {
    Write-ColorOutput "[LOGS] Últimos logs:" "Blue"
    Write-Host ""
    docker ps -a | Select-String "meugemm"
}

# Função para ver resultados
function View-Results {
    Write-ColorOutput "[RESULTS] Arquivos gerados:" "Blue"
    Write-Host ""
    Write-Host "=== Output (*.dat) ===" -ForegroundColor Cyan
    if (Test-Path "output\*.dat") {
        Get-ChildItem "output\*.dat" | Format-Table Name, Length, LastWriteTime -AutoSize
    } else {
        Write-Host "Nenhum arquivo .dat encontrado"
    }
    Write-Host ""
    Write-Host "=== Logs (*_ldd.log) ===" -ForegroundColor Cyan
    if (Test-Path "logs\*_ldd.log") {
        Get-ChildItem "logs\*_ldd.log" | Format-Table Name, Length, LastWriteTime -AutoSize
    } else {
        Write-Host "Nenhum arquivo .log encontrado"
    }
}

# Menu principal
if ($args.Count -eq 0) {
    # Modo interativo
    while ($true) {
        $option = Show-Menu
        
        switch ($option) {
            "1" { Build-Image }
            "2" { Run-Tests }
            "3" { Run-Alternatives }
            "4" { Run-Interactive }
            "5" { Clean-Docker }
            "6" { View-Logs }
            "7" { View-Results }
            "0" {
                Write-Host "Saindo..."
                exit 0
            }
            default {
                Write-ColorOutput "Opcao invalida!" "Red"
            }
        }
        
        Write-Host ""
        Write-Host "Pressione Enter para continuar..." -ForegroundColor Yellow
        $null = Read-Host
    }
} else {
    # Modo comando direto
    switch ($args[0]) {
        "build" { Build-Image }
        "run" { Run-Tests }
        "tests" { Run-Tests }
        "alternatives" { Run-Alternatives }
        "alt" { Run-Alternatives }
        "interactive" { Run-Interactive }
        "bash" { Run-Interactive }
        "clean" { Clean-Docker }
        "logs" { View-Logs }
        "results" { View-Results }
        default {
            Write-Host "Uso: .\docker-run.ps1 [build|run|alternatives|interactive|clean|logs|results]"
            Write-Host ""
            Write-Host "Comandos:"
            Write-Host "  build        - Construir imagem Docker"
            Write-Host "  run|tests    - Executar testes padrão (linkagem direta)"
            Write-Host "  alternatives - Executar com update-alternatives"
            Write-Host "  interactive  - Modo interativo (bash)"
            Write-Host "  clean        - Limpar containers e imagens"
            Write-Host "  logs         - Ver logs"
            Write-Host "  results      - Ver resultados"
            Write-Host ""
            Write-Host "Ou execute sem argumentos para modo interativo"
            exit 1
        }
    }
}
