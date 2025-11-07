#!/usr/bin/env python3
"""
Análise Rigorosa de Benchmarks DGEMM para HPC
==============================================

Análise detalhada com foco em overhead mínimo para computação de alto desempenho.
Desenvolvido para usuários céticos quanto ao uso de Docker em HPC.

Métricas calculadas:
- Overhead absoluto (segundos) e relativo (%)
- Análise estatística completa (média, mediana, desvio, percentis 95/99)
- Impacto em GFLOPS e eficiência computacional  
- Análise de escalabilidade com tamanho de matriz
- Comparação rigorosa entre métodos (alternatives vs direta)

Autor: Douglas
Data: 7 de Novembro de 2025
"""

import pandas as pd
import numpy as np
import sys
from pathlib import Path

# Cores para output
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'
    END = '\033[0m'

# Limites de aceitação rigorosos para HPC
class HPCThresholds:
    OVERHEAD_NEGLIGIBLE = 1.0   # < 1% considerado desprezível
    OVERHEAD_ACCEPTABLE = 3.0   # < 3% considerado aceitável
    OVERHEAD_SIGNIFICANT = 5.0  # < 5% considerado significativo
    OVERHEAD_CRITICAL = 10.0    # ≥ 10% considerado crítico
    
    METHOD_DIFF_NEGLIGIBLE = 2.0  # < 2% diferença entre métodos
    METHOD_DIFF_ACCEPTABLE = 5.0  # < 5% diferença aceitável

def load_data(base_path, environment, method, variant):
    """Carrega dados de benchmark"""
    file_path = f"{base_path}/{environment}/{method}/output_{variant}.dat"
    try:
        df = pd.read_csv(file_path)
        df.columns = df.columns.str.strip()
        return df
    except FileNotFoundError:
        return None

def calculate_overhead(native_time, docker_time):
    """Calcula overhead percentual e absoluto"""
    if native_time == 0:
        return 0.0, 0.0
    overhead_pct = ((docker_time - native_time) / native_time) * 100
    overhead_abs = docker_time - native_time
    return overhead_pct, overhead_abs

def calculate_gflops(matrix_size, time_seconds):
    """
    Calcula GFLOPS para operação DGEMM
    DGEMM: C = A * B (matrizes N x N)
    Operações: 2 * N^3 (N^3 multiplicações + N^3 adições)
    """
    if time_seconds == 0 or time_seconds < 0:
        return 0.0
    n = matrix_size
    operations = 2.0 * (n ** 3)
    flops = operations / time_seconds
    gflops = flops / 1e9
    return gflops

def calculate_efficiency_loss(native_gflops, docker_gflops):
    """Calcula perda de eficiência em GFLOPS"""
    if native_gflops == 0:
        return 0.0
    return ((native_gflops - docker_gflops) / native_gflops) * 100

def get_overhead_classification(overhead_pct):
    """Classifica overhead para usuários de HPC (rigoroso)"""
    abs_overhead = abs(overhead_pct)
    
    if abs_overhead < HPCThresholds.OVERHEAD_NEGLIGIBLE:
        return "DESPREZÍVEL", Colors.GREEN, "✓"
    elif abs_overhead < HPCThresholds.OVERHEAD_ACCEPTABLE:
        return "ACEITÁVEL", Colors.GREEN, "○"
    elif abs_overhead < HPCThresholds.OVERHEAD_SIGNIFICANT:
        return "PEQUENO", Colors.YELLOW, "△"
    elif abs_overhead < HPCThresholds.OVERHEAD_CRITICAL:
        return "SIGNIFICATIVO", Colors.YELLOW, "⚠"
    else:
        return "CRÍTICO", Colors.RED, "✗"

def print_header(text):
    """Imprime cabeçalho formatado"""
    print(f"\n{Colors.BOLD}{Colors.BLUE}{'='*100}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{text.center(100)}{Colors.END}")
    print(f"{Colors.BOLD}{Colors.BLUE}{'='*100}{Colors.END}\n")

def print_section(text):
    """Imprime seção formatada"""
    print(f"\n{Colors.CYAN}{Colors.BOLD}{text}{Colors.END}")
    print(f"{Colors.CYAN}{'-'*100}{Colors.END}")

def analyze_variant(base_path, variant, matrix_size):
    """Analisa uma variante específica em um tamanho de matriz"""
    results = {}
    
    for env in ['native', 'docker']:
        for method in ['alternatives', 'direct_compilation']:
            df = load_data(base_path, env, method, variant)
            if df is not None and not df.empty:
                row = df[df['matSize'] == matrix_size]
                if not row.empty:
                    results[f"{env}_{method}"] = row['Mean'].values[0]
    
    return results

def hpc_analysis(base_path='output'):
    """Análise rigorosa para HPC"""
    
    print_header("ANÁLISE RIGOROSA PARA HPC: OVERHEAD DOCKER vs NATIVO")
    
    print(f"{Colors.BOLD}Critérios de Aceitação para Computação de Alto Desempenho:{Colors.END}")
    print(f"  {Colors.GREEN}✓{Colors.END} Desprezível:   overhead < {HPCThresholds.OVERHEAD_NEGLIGIBLE:>4.1f}%  (impacto insignificante)")
    print(f"  {Colors.GREEN}○{Colors.END} Aceitável:     overhead < {HPCThresholds.OVERHEAD_ACCEPTABLE:>4.1f}%  (aceitável para desenvolvimento/testes)")
    print(f"  {Colors.YELLOW}△{Colors.END} Pequeno:       overhead < {HPCThresholds.OVERHEAD_SIGNIFICANT:>4.1f}%  (requer justificativa)")
    print(f"  {Colors.YELLOW}⚠{Colors.END} Significativo: overhead < {HPCThresholds.OVERHEAD_CRITICAL:>4.1f}%  (uso não recomendado)")
    print(f"  {Colors.RED}✗{Colors.END} Crítico:       overhead ≥ {HPCThresholds.OVERHEAD_CRITICAL:>4.1f}%  (inaceitável para HPC)")
    
    # Variantes relevantes (excluindo BLAS64 de referência com problema conhecido)
    variants = ['OpenBLAS64', 'BLIS64']
    
    # Tamanhos de matriz para análise
    matrix_sizes_all = [128, 256, 384, 512, 640, 768, 896, 1024]
    matrix_sizes_key = [512, 768, 1024]  # Tamanhos mais relevantes para HPC
    
    # ========================================================================
    # ANÁLISE 1: OVERHEAD DETALHADO POR TAMANHO DE MATRIZ
    # ========================================================================
    print_section("1. OVERHEAD DO DOCKER: Análise Detalhada por Tamanho de Matriz")
    
    for method in ['alternatives', 'direct_compilation']:
        method_name = "ALTERNATIVES" if method == 'alternatives' else "COMPILAÇÃO DIRETA"
        print(f"\n{Colors.YELLOW}{'='*100}{Colors.END}")
        print(f"{Colors.BOLD}{Colors.YELLOW}MÉTODO: {method_name}{Colors.END}")
        print(f"{Colors.YELLOW}{'='*100}{Colors.END}\n")
        
        for variant in variants:
            print(f"{Colors.CYAN}■ Biblioteca: {variant}{Colors.END}")
            print(f"{'Matriz':<8} {'Nativo(s)':>13} {'Docker(s)':>13} {'Δ Abs(s)':>13} "
                  f"{'Overhead%':>11} {'GFLOPS-N':>12} {'GFLOPS-D':>12} {'Δ Perf%':>11} {'Classificação':>30}")
            print("-" * 135)
            
            for size in matrix_sizes_all:
                results = analyze_variant(base_path, variant, size)
                
                native_key = f"native_{method}"
                docker_key = f"docker_{method}"
                
                if native_key in results and docker_key in results:
                    native_time = results[native_key]
                    docker_time = results[docker_key]
                    overhead_pct, overhead_abs = calculate_overhead(native_time, docker_time)
                    
                    native_gflops = calculate_gflops(size, native_time)
                    docker_gflops = calculate_gflops(size, docker_time)
                    perf_loss = calculate_efficiency_loss(native_gflops, docker_gflops)
                    
                    classification, color, symbol = get_overhead_classification(overhead_pct)
                    
                    print(f"{size:<8} {native_time:>13.6f} {docker_time:>13.6f} {overhead_abs:>+13.6f} "
                          f"{overhead_pct:>+10.3f}% {native_gflops:>12.2f} {docker_gflops:>12.2f} "
                          f"{perf_loss:>+10.2f}% {color}{symbol} {classification:>20}{Colors.END}")
            print()
    
    # ========================================================================
    # ANÁLISE 2: ESTATÍSTICAS RIGOROSAS
    # ========================================================================
    print_section("2. ESTATÍSTICAS RIGOROSAS DE OVERHEAD")
    
    overhead_data = {
        'alternatives': {'pct': [], 'abs': [], 'gflops_loss': []},
        'direct_compilation': {'pct': [], 'abs': [], 'gflops_loss': []}
    }
    
    # Coletar dados
    for variant in variants:
        for size in matrix_sizes_all:
            results = analyze_variant(base_path, variant, size)
            
            for method in ['alternatives', 'direct_compilation']:
                native_key = f"native_{method}"
                docker_key = f"docker_{method}"
                
                if native_key in results and docker_key in results:
                    native_time = results[native_key]
                    docker_time = results[docker_key]
                    overhead_pct, overhead_abs = calculate_overhead(native_time, docker_time)
                    
                    native_gflops = calculate_gflops(size, native_time)
                    docker_gflops = calculate_gflops(size, docker_time)
                    gflops_loss = calculate_efficiency_loss(native_gflops, docker_gflops)
                    
                    overhead_data[method]['pct'].append(overhead_pct)
                    overhead_data[method]['abs'].append(overhead_abs)
                    overhead_data[method]['gflops_loss'].append(gflops_loss)
    
    # Estatísticas de Overhead Percentual
    print(f"\n{Colors.BOLD}A) OVERHEAD PERCENTUAL (%) - Docker vs Nativo{Colors.END}")
    print(f"{'Método':<25} {'N':>6} {'Média':>10} {'Mediana':>10} {'P90':>10} {'P95':>10} "
          f"{'P99':>10} {'Min':>10} {'Max':>10} {'σ':>10} {'Status':>25}")
    print("-" * 145)
    
    for method, data in overhead_data.items():
        if data['pct']:
            method_name = "Alternatives" if method == 'alternatives' else "Compilação Direta"
            pct_data = np.array(data['pct'])
            
            n = len(pct_data)
            mean = np.mean(pct_data)
            median = np.median(pct_data)
            p90 = np.percentile(pct_data, 90)
            p95 = np.percentile(pct_data, 95)
            p99 = np.percentile(pct_data, 99)
            min_val = np.min(pct_data)
            max_val = np.max(pct_data)
            std = np.std(pct_data, ddof=1)  # Sample std
            
            classification, color, symbol = get_overhead_classification(mean)
            
            print(f"{method_name:<25} {n:>6} {mean:>+9.3f}% {median:>+9.3f}% {p90:>+9.3f}% {p95:>+9.3f}% "
                  f"{p99:>+9.3f}% {min_val:>+9.3f}% {max_val:>+9.3f}% {std:>9.3f}% "
                  f"{color}{symbol} {classification}{Colors.END}")
    
    # Estatísticas de Overhead Absoluto
    print(f"\n{Colors.BOLD}B) OVERHEAD ABSOLUTO (segundos) - Docker vs Nativo{Colors.END}")
    print(f"{'Método':<25} {'N':>6} {'Média':>13} {'Mediana':>13} {'P95':>13} {'P99':>13} "
          f"{'Min':>13} {'Max':>13} {'σ':>13}")
    print("-" * 125)
    
    for method, data in overhead_data.items():
        if data['abs']:
            method_name = "Alternatives" if method == 'alternatives' else "Compilação Direta"
            abs_data = np.array(data['abs'])
            
            n = len(abs_data)
            
            print(f"{method_name:<25} {n:>6} {np.mean(abs_data):>+12.6f}s {np.median(abs_data):>+12.6f}s "
                  f"{np.percentile(abs_data, 95):>+12.6f}s {np.percentile(abs_data, 99):>+12.6f}s "
                  f"{np.min(abs_data):>+12.6f}s {np.max(abs_data):>+12.6f}s {np.std(abs_data, ddof=1):>12.6f}s")
    
    # Estatísticas de Perda de Desempenho
    print(f"\n{Colors.BOLD}C) PERDA DE EFICIÊNCIA COMPUTACIONAL (%) - Docker vs Nativo{Colors.END}")
    print(f"{'Método':<25} {'N':>6} {'Média':>10} {'Mediana':>10} {'P95':>10} {'P99':>10} "
          f"{'Min':>10} {'Max':>10} {'σ':>10}")
    print("-" * 110)
    
    for method, data in overhead_data.items():
        if data['gflops_loss']:
            method_name = "Alternatives" if method == 'alternatives' else "Compilação Direta"
            gflops_data = np.array(data['gflops_loss'])
            
            n = len(gflops_data)
            
            print(f"{method_name:<25} {n:>6} {np.mean(gflops_data):>+9.3f}% {np.median(gflops_data):>+9.3f}% "
                  f"{np.percentile(gflops_data, 95):>+9.3f}% {np.percentile(gflops_data, 99):>+9.3f}% "
                  f"{np.min(gflops_data):>+9.3f}% {np.max(gflops_data):>+9.3f}% {np.std(gflops_data, ddof=1):>9.3f}%")
    
    # ========================================================================
    # ANÁLISE 3: COMPARAÇÃO ALTERNATIVES VS COMPILAÇÃO DIRETA
    # ========================================================================
    print_section("3. COMPARAÇÃO: ALTERNATIVES vs COMPILAÇÃO DIRETA")
    
    method_comparison = {'native': [], 'docker': []}
    
    print(f"\n{Colors.BOLD}Diferença de Desempenho entre Métodos (Direta - Alternatives){Colors.END}\n")
    
    for env in ['native', 'docker']:
        env_name = "NATIVO" if env == 'native' else "DOCKER"
        print(f"{Colors.YELLOW}Ambiente: {env_name}{Colors.END}")
        print(f"{'Biblioteca':<15} {'Matriz':<8} {'Alternatives':>13} {'Direta':>13} {'Δ Abs':>13} {'Δ %':>10} {'Status':>25}")
        print("-" * 105)
        
        for variant in variants:
            for size in matrix_sizes_key:
                results = analyze_variant(base_path, variant, size)
                
                alt_key = f"{env}_alternatives"
                dir_key = f"{env}_direct_compilation"
                
                if alt_key in results and dir_key in results:
                    alt_time = results[alt_key]
                    dir_time = results[dir_key]
                    diff_abs = dir_time - alt_time
                    diff_pct = (diff_abs / alt_time) * 100
                    
                    method_comparison[env].append(diff_pct)
                    
                    # Classificação
                    if abs(diff_pct) < HPCThresholds.METHOD_DIFF_NEGLIGIBLE:
                        color, symbol, status = Colors.GREEN, "≈", "EQUIVALENTE"
                    elif abs(diff_pct) < HPCThresholds.METHOD_DIFF_ACCEPTABLE:
                        color, symbol, status = Colors.YELLOW, "~", "PEQUENA DIFERENÇA"
                    else:
                        color, symbol, status = Colors.RED, "≠", "DIFERENÇA SIGNIFICATIVA"
                    
                    print(f"{variant:<15} {size:<8} {alt_time:>13.6f} {dir_time:>13.6f} {diff_abs:>+13.6f} "
                          f"{diff_pct:>+9.3f}% {color}{symbol} {status}{Colors.END}")
        print()
    
    # Estatísticas de comparação
    print(f"{Colors.BOLD}Estatísticas: Diferença Direta - Alternatives (%){Colors.END}")
    print(f"{'Ambiente':<15} {'N':>6} {'Média':>10} {'Mediana':>10} {'σ':>10} {'Min':>10} {'Max':>10} {'Conclusão':>35}")
    print("-" * 115)
    
    for env, diffs in method_comparison.items():
        if diffs:
            env_name = "Nativo" if env == 'native' else "Docker"
            diffs_arr = np.array(diffs)
            
            mean = np.mean(diffs_arr)
            median = np.median(diffs_arr)
            std = np.std(diffs_arr, ddof=1)
            min_val = np.min(diffs_arr)
            max_val = np.max(diffs_arr)
            
            if abs(mean) < HPCThresholds.METHOD_DIFF_NEGLIGIBLE:
                color, conclusion = Colors.GREEN, "✓ Métodos equivalentes"
            elif abs(mean) < HPCThresholds.METHOD_DIFF_ACCEPTABLE:
                color, conclusion = Colors.YELLOW, "○ Pequena diferença aceitável"
            else:
                color, conclusion = Colors.RED, "⚠ Diferença significativa"
            
            print(f"{env_name:<15} {len(diffs_arr):>6} {mean:>+9.3f}% {median:>+9.3f}% {std:>9.3f}% "
                  f"{min_val:>+9.3f}% {max_val:>+9.3f}% {color}{conclusion}{Colors.END}")
    
    # ========================================================================
    # ANÁLISE 4: CASOS DE USO TÍPICOS EM HPC
    # ========================================================================
    print_section("4. ANÁLISE PARA CASOS DE USO TÍPICOS EM HPC")
    
    print(f"\n{Colors.BOLD}Matrizes Grandes (1024x1024) - Cenário HPC Típico{Colors.END}\n")
    print(f"{'Biblioteca':<15} {'Método':<20} {'Nativo(s)':>13} {'Docker(s)':>13} "
          f"{'Overhead':>11} {'GFLOPS-N':>12} {'GFLOPS-D':>12} {'Status':>25}")
    print("-" * 140)
    
    size = 1024
    for variant in variants:
        results = analyze_variant(base_path, variant, size)
        
        for method in ['alternatives', 'direct_compilation']:
            method_name = "Alternatives" if method == 'alternatives' else "Compilação Direta"
            
            native_key = f"native_{method}"
            docker_key = f"docker_{method}"
            
            if native_key in results and docker_key in results:
                native_time = results[native_key]
                docker_time = results[docker_key]
                overhead_pct, _ = calculate_overhead(native_time, docker_time)
                
                native_gflops = calculate_gflops(size, native_time)
                docker_gflops = calculate_gflops(size, docker_time)
                
                classification, color, symbol = get_overhead_classification(overhead_pct)
                
                print(f"{variant:<15} {method_name:<20} {native_time:>13.6f} {docker_time:>13.6f} "
                      f"{overhead_pct:>+10.3f}% {native_gflops:>12.2f} {docker_gflops:>12.2f} "
                      f"{color}{symbol} {classification}{Colors.END}")
    
    # ========================================================================
    # CONCLUSÕES E RECOMENDAÇÕES PARA HPC
    # ========================================================================
    print_section("5. CONCLUSÕES E RECOMENDAÇÕES PARA HPC")
    
    # Calcular médias finais
    alt_overhead_mean = np.mean(overhead_data['alternatives']['pct']) if overhead_data['alternatives']['pct'] else 0
    dir_overhead_mean = np.mean(overhead_data['direct_compilation']['pct']) if overhead_data['direct_compilation']['pct'] else 0
    
    native_method_diff = np.mean(method_comparison['native']) if method_comparison['native'] else 0
    docker_method_diff = np.mean(method_comparison['docker']) if method_comparison['docker'] else 0
    
    print(f"\n{Colors.BOLD}A) OVERHEAD DO DOCKER:{Colors.END}\n")
    
    print(f"  Método Alternatives:")
    print(f"    • Overhead médio: {alt_overhead_mean:+.3f}%")
    classification, color, symbol = get_overhead_classification(alt_overhead_mean)
    print(f"    • Classificação: {color}{symbol} {classification}{Colors.END}")
    
    print(f"\n  Método Compilação Direta:")
    print(f"    • Overhead médio: {dir_overhead_mean:+.3f}%")
    classification, color, symbol = get_overhead_classification(dir_overhead_mean)
    print(f"    • Classificação: {color}{symbol} {classification}{Colors.END}")
    
    # Recomendação sobre Docker
    print(f"\n  {Colors.BOLD}Recomendação sobre uso de Docker:{Colors.END}")
    max_overhead = max(abs(alt_overhead_mean), abs(dir_overhead_mean))
    
    if max_overhead < HPCThresholds.OVERHEAD_NEGLIGIBLE:
        print(f"    {Colors.GREEN}✓ RECOMENDADO{Colors.END} - Overhead desprezível (< {HPCThresholds.OVERHEAD_NEGLIGIBLE}%)")
        print(f"      Docker pode ser usado sem impacto perceptível no desempenho")
        print(f"      Ideal para desenvolvimento, testes e até produção")
    elif max_overhead < HPCThresholds.OVERHEAD_ACCEPTABLE:
        print(f"    {Colors.GREEN}○ ACEITÁVEL{Colors.END} - Overhead pequeno (< {HPCThresholds.OVERHEAD_ACCEPTABLE}%)")
        print(f"      Docker é aceitável para desenvolvimento e testes")
        print(f"      Para produção HPC, preferir ambiente nativo")
    elif max_overhead < HPCThresholds.OVERHEAD_SIGNIFICANT:
        print(f"    {Colors.YELLOW}△ USO CAUTELOSO{Colors.END} - Overhead mensurável (< {HPCThresholds.OVERHEAD_SIGNIFICANT}%)")
        print(f"      Docker deve ser usado apenas para desenvolvimento")
        print(f"      Produção HPC requer ambiente nativo")
    else:
        print(f"    {Colors.RED}✗ NÃO RECOMENDADO{Colors.END} - Overhead significativo (≥ {HPCThresholds.OVERHEAD_SIGNIFICANT}%)")
        print(f"      Docker introduz overhead inaceitável para HPC")
        print(f"      Use apenas ambiente nativo")
    
    print(f"\n{Colors.BOLD}B) ALTERNATIVES vs COMPILAÇÃO DIRETA:{Colors.END}\n")
    
    avg_method_diff = (abs(native_method_diff) + abs(docker_method_diff)) / 2
    
    print(f"  Diferença média entre métodos:")
    print(f"    • Nativo: {native_method_diff:+.3f}%")
    print(f"    • Docker: {docker_method_diff:+.3f}%")
    print(f"    • Média:  {avg_method_diff:.3f}%")
    
    print(f"\n  {Colors.BOLD}Recomendação sobre método:{Colors.END}")
    
    if avg_method_diff < HPCThresholds.METHOD_DIFF_NEGLIGIBLE:
        print(f"    {Colors.GREEN}✓ USE ALTERNATIVES{Colors.END} - Diferença desprezível (< {HPCThresholds.METHOD_DIFF_NEGLIGIBLE}%)")
        print(f"      Mesma precisão que compilação direta")
        print(f"      Muito mais prático para comparar bibliotecas")
        print(f"      Ideal para desenvolvimento e benchmarking")
    elif avg_method_diff < HPCThresholds.METHOD_DIFF_ACCEPTABLE:
        print(f"    {Colors.YELLOW}○ ALTERNATIVES OU DIRETA{Colors.END} - Pequena diferença (< {HPCThresholds.METHOD_DIFF_ACCEPTABLE}%)")
        print(f"      Alternatives: Mais prático, overhead aceitável")
        print(f"      Direta: Mais controle, sem indireção")
        print(f"      Escolha baseada em prioridades do projeto")
    else:
        print(f"    {Colors.RED}⚠ PREFIRA COMPILAÇÃO DIRETA{Colors.END} - Diferença significativa")
        print(f"      Alternatives introduz overhead mensurável")
        print(f"      Para máxima precisão, use compilação direta")
    
    print(f"\n{Colors.BOLD}C) RESUMO EXECUTIVO PARA HPC:{Colors.END}\n")
    
    print(f"  {Colors.BOLD}1. Docker vs Nativo:{Colors.END}")
    if max_overhead < HPCThresholds.OVERHEAD_ACCEPTABLE:
        print(f"     • Overhead médio: {max_overhead:.3f}% {Colors.GREEN}✓{Colors.END}")
        print(f"     • Docker é viável para HPC com overhead desprezível")
        print(f"     • Benefícios: reprodutibilidade, isolamento, portabilidade")
    else:
        print(f"     • Overhead médio: {max_overhead:.3f}% {Colors.YELLOW}⚠{Colors.END}")
        print(f"     • Docker tem overhead mensurável para HPC")
        print(f"     • Recomendação: ambiente nativo para produção")
    
    print(f"\n  {Colors.BOLD}2. Alternatives vs Compilação Direta:{Colors.END}")
    if avg_method_diff < HPCThresholds.METHOD_DIFF_ACCEPTABLE:
        print(f"     • Diferença média: {avg_method_diff:.3f}% {Colors.GREEN}✓{Colors.END}")
        print(f"     • Métodos são equivalentes para fins práticos")
        print(f"     • Recomendação: Alternatives (mais prático)")
    else:
        print(f"     • Diferença média: {avg_method_diff:.3f}% {Colors.YELLOW}⚠{Colors.END}")
        print(f"     • Há diferença mensurável entre métodos")
        print(f"     • Recomendação: Compilação Direta (mais preciso)")
    
    print(f"\n  {Colors.BOLD}3. Recomendação Final:{Colors.END}")
    
    if max_overhead < HPCThresholds.OVERHEAD_ACCEPTABLE and avg_method_diff < HPCThresholds.METHOD_DIFF_ACCEPTABLE:
        print(f"     {Colors.GREEN}✓ AMBIENTE: DOCKER ou NATIVO{Colors.END} (overhead desprezível)")
        print(f"     {Colors.GREEN}✓ MÉTODO: ALTERNATIVES{Colors.END} (prático e preciso)")
        print(f"     {Colors.BOLD}→ Ideal para desenvolvimento e produção HPC{Colors.END}")
    elif max_overhead < HPCThresholds.OVERHEAD_ACCEPTABLE:
        print(f"     {Colors.GREEN}✓ AMBIENTE: DOCKER ou NATIVO{Colors.END} (overhead desprezível)")
        print(f"     {Colors.YELLOW}○ MÉTODO: COMPILAÇÃO DIRETA{Colors.END} (maior precisão)")
        print(f"     {Colors.BOLD}→ Docker viável, mas prefira compilação direta{Colors.END}")
    else:
        print(f"     {Colors.YELLOW}△ AMBIENTE: NATIVO{Colors.END} (overhead significativo no Docker)")
        print(f"     {Colors.YELLOW}○ MÉTODO: COMPILAÇÃO DIRETA{Colors.END} (controle total)")
        print(f"     {Colors.BOLD}→ Para HPC de produção, use nativo com compilação direta{Colors.END}")
    
    print("\n" + "="*100 + "\n")
    
    # Retornar métricas para uso programático
    return {
        'docker_overhead': {
            'alternatives': alt_overhead_mean,
            'direct': dir_overhead_mean,
            'max': max_overhead
        },
        'method_difference': {
            'native': native_method_diff,
            'docker': docker_method_diff,
            'avg': avg_method_diff
        }
    }

if __name__ == "__main__":
    metrics = hpc_analysis()
    
    # Exit code baseado em critérios HPC
    max_overhead = metrics['docker_overhead']['max']
    
    if max_overhead < HPCThresholds.OVERHEAD_ACCEPTABLE:
        sys.exit(0)  # Sucesso - overhead aceitável
    elif max_overhead < HPCThresholds.OVERHEAD_SIGNIFICANT:
        sys.exit(1)  # Warning - overhead mensurável
    else:
        sys.exit(2)  # Error - overhead crítico
