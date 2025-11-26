#!/usr/bin/env python3
"""
Implementação dos TODOs do notebook_overhead_dgemm_docker.ipynb

Este script pode ser executado standalone ou copiado célula por célula para o notebook Jupyter.
"""

# =============================================================================
# TODO 1: Carregar e inspecionar dados brutos
# =============================================================================

import pandas as pd
import numpy as np
import sys
from pathlib import Path

# Adicionar caminho do script de análise
sys.path.append('..')
from analysis_benchmark_hpc import load_data, calculate_overhead, calculate_gflops

# Configuração
base_path = '../output'
threading_mode = 'single'  # single-thread
run_number = '001'

# Variantes BLAS para análise
variants = ['OpenBLAS64', 'BLIS64']
environments = ['native', 'docker']
methods = ['alternatives', 'direct_compilation']

# Carregar dados de todas as combinações
all_data = []
for variant in variants:
    for env in environments:
        for method in methods:
            df = load_data(base_path, threading_mode, env, method, variant, run_number)
            if df is not None:
                df['variant'] = variant
                df['environment'] = env
                df['method'] = method
                all_data.append(df)

# Combinar todos os dados
df_combined = pd.concat(all_data, ignore_index=True)

print("=" * 80)
print("TODO 1: DADOS CARREGADOS")
print("=" * 80)
print(f'Total de registros carregados: {len(df_combined)}')
print(f'Colunas disponíveis: {list(df_combined.columns)}')
print('\nPrimeiras 20 linhas:')
print(df_combined.head(20))


# =============================================================================
# TODO 2: Implementar leitura e organização dos resultados experimentais
# =============================================================================

print("\n" + "=" * 80)
print("TODO 2: ORGANIZAÇÃO DOS RESULTADOS EXPERIMENTAIS")
print("=" * 80)

# Agrupar dados por (BLAS, método, tamanho da matriz, ambiente)
group_cols = ['variant', 'method', 'matSize', 'environment']
df_grouped = df_combined.groupby(group_cols)

# Estatísticas descritivas
stats_summary = df_grouped['Mean'].describe()
print("\nEstatísticas descritivas do tempo médio de execução:")
print(stats_summary)

# Análise por grupo
print("\nNúmero de observações por grupo:")
print(df_grouped.size())


# =============================================================================
# TODO 3: Calcular overhead de tempo e GFLOPS
# =============================================================================

print("\n" + "=" * 80)
print("TODO 3: CÁLCULO DE OVERHEAD")
print("=" * 80)

# Pivot para comparar native vs docker
df_pivot = df_combined.pivot_table(
    index=['variant', 'method', 'matSize'],
    columns='environment',
    values='Mean',
    aggfunc='first'
).reset_index()

# Calcular overhead usando função existente
df_pivot['overhead_tempo_percent'] = df_pivot.apply(
    lambda row: calculate_overhead(row['native'], row['docker'])[0], axis=1
)
df_pivot['overhead_tempo_abs'] = df_pivot.apply(
    lambda row: calculate_overhead(row['native'], row['docker'])[1], axis=1
)
df_pivot['slowdown'] = df_pivot['docker'] / df_pivot['native']

# Calcular GFLOPS
df_pivot['gflops_native'] = df_pivot.apply(
    lambda row: calculate_gflops(row['matSize'], row['native']), axis=1
)
df_pivot['gflops_docker'] = df_pivot.apply(
    lambda row: calculate_gflops(row['matSize'], row['docker']), axis=1
)
df_pivot['overhead_gflops_percent'] = (
    (df_pivot['gflops_native'] - df_pivot['gflops_docker']) / df_pivot['gflops_native'] * 100
)

print("\nOverhead calculado (primeiras 15 linhas):")
print(df_pivot[['variant', 'method', 'matSize', 'overhead_tempo_percent', 
                'overhead_gflops_percent', 'slowdown']].head(15))


# =============================================================================
# TODO 4: Implementar cálculos estatísticos
# =============================================================================

print("\n" + "=" * 80)
print("TODO 4: ANÁLISE ESTATÍSTICA")
print("=" * 80)

from scipy import stats

# Estatísticas resumidas por variante e método
overhead_stats = df_pivot.groupby(['variant', 'method']).agg({
    'overhead_tempo_percent': ['mean', 'std', 'median', 'min', 'max'],
    'overhead_gflops_percent': ['mean', 'std', 'median', 'min', 'max'],
    'slowdown': ['mean', 'std', 'median', 'min', 'max']
})

print("\nEstatísticas de Overhead por Biblioteca e Método:")
print(overhead_stats.round(4))

# Função para calcular intervalo de confiança
def calculate_ci(data, confidence=0.95):
    """Calcula intervalo de confiança usando distribuição t de Student"""
    n = len(data)
    if n < 2:
        return None, None
    mean = np.mean(data)
    stderr = stats.sem(data)
    ci = stderr * stats.t.ppf((1 + confidence) / 2, n - 1)
    return mean - ci, mean + ci

# Intervalos de confiança (95%)
print("\n" + "-" * 80)
print("Intervalos de Confiança 95% - Overhead de Tempo:")
print("-" * 80)
for variant in variants:
    for method in methods:
        mask = (df_pivot['variant'] == variant) & (df_pivot['method'] == method)
        data = df_pivot[mask]['overhead_tempo_percent'].values
        if len(data) > 1:
            ci_lower, ci_upper = calculate_ci(data)
            mean = np.mean(data)
            print(f"{variant:15} - {method:20}: μ = {mean:6.3f}%, "
                  f"IC 95% = [{ci_lower:6.3f}%, {ci_upper:6.3f}%]")

# Testes de hipótese: teste t pareado (Native vs Docker)
print("\n" + "-" * 80)
print("Testes de Significância (Native vs Docker) - Teste t Pareado:")
print("-" * 80)
print(f"{'Biblioteca':<15} {'Método':<20} {'t-statistic':>12} {'p-value':>12} {'Significativo':>15}")
print("-" * 80)

for variant in variants:
    for method in methods:
        mask = (df_combined['variant'] == variant) & (df_combined['method'] == method)
        native_data = df_combined[mask & (df_combined['environment'] == 'native')].sort_values('matSize')
        docker_data = df_combined[mask & (df_combined['environment'] == 'docker')].sort_values('matSize')
        
        native_times = native_data['Mean'].values
        docker_times = docker_data['Mean'].values
        
        if len(native_times) > 1 and len(docker_times) > 1 and len(native_times) == len(docker_times):
            t_stat, p_value = stats.ttest_rel(native_times, docker_times)
            significant = "Sim (p<0.05)" if p_value < 0.05 else "Não"
            print(f"{variant:<15} {method:<20} {t_stat:12.4f} {p_value:12.6f} {significant:>15}")


# =============================================================================
# TODO 5: Gerar tabelas e gráficos para visualização
# =============================================================================

print("\n" + "=" * 80)
print("TODO 5: VISUALIZAÇÕES E TABELAS")
print("=" * 80)

import matplotlib.pyplot as plt
import seaborn as sns

# Configurar matplotlib para headless execution
import matplotlib
matplotlib.use('Agg')

# Configurar estilo para publicação
plt.style.use('seaborn-v0_8-paper')
sns.set_palette("husl")

# Criar diretório para salvar figuras
Path('../figuras').mkdir(exist_ok=True)
Path('../tabelas').mkdir(exist_ok=True)

# FIGURA 1: Overhead vs Tamanho da Matriz
fig, axes = plt.subplots(2, 2, figsize=(14, 10))
fig.suptitle('Análise de Overhead: Docker vs Nativo', fontsize=16, fontweight='bold')

# Overhead de tempo - Alternatives
ax = axes[0, 0]
for variant in variants:
    mask = (df_pivot['variant'] == variant) & (df_pivot['method'] == 'alternatives')
    data = df_pivot[mask].sort_values('matSize')
    ax.plot(data['matSize'], data['overhead_tempo_percent'], 
            marker='o', label=variant, linewidth=2, markersize=6)
ax.set_xlabel('Tamanho da Matriz N', fontsize=11)
ax.set_ylabel('Overhead de Tempo (%)', fontsize=11)
ax.set_title('Overhead Tempo - Alternatives', fontsize=12, fontweight='bold')
ax.grid(True, alpha=0.3)
ax.legend()
ax.axhline(y=0, color='black', linestyle='--', alpha=0.5, linewidth=1)

# Overhead de tempo - Direct Compilation
ax = axes[0, 1]
for variant in variants:
    mask = (df_pivot['variant'] == variant) & (df_pivot['method'] == 'direct_compilation')
    data = df_pivot[mask].sort_values('matSize')
    ax.plot(data['matSize'], data['overhead_tempo_percent'], 
            marker='s', label=variant, linewidth=2, markersize=6)
ax.set_xlabel('Tamanho da Matriz N', fontsize=11)
ax.set_ylabel('Overhead de Tempo (%)', fontsize=11)
ax.set_title('Overhead Tempo - Compilação Direta', fontsize=12, fontweight='bold')
ax.grid(True, alpha=0.3)
ax.legend()
ax.axhline(y=0, color='black', linestyle='--', alpha=0.5, linewidth=1)

# Overhead GFLOPS - Alternatives
ax = axes[1, 0]
for variant in variants:
    mask = (df_pivot['variant'] == variant) & (df_pivot['method'] == 'alternatives')
    data = df_pivot[mask].sort_values('matSize')
    ax.plot(data['matSize'], data['overhead_gflops_percent'], 
            marker='o', label=variant, linewidth=2, markersize=6)
ax.set_xlabel('Tamanho da Matriz N', fontsize=11)
ax.set_ylabel('Perda de Desempenho (%)', fontsize=11)
ax.set_title('Overhead GFLOPS - Alternatives', fontsize=12, fontweight='bold')
ax.grid(True, alpha=0.3)
ax.legend()
ax.axhline(y=0, color='black', linestyle='--', alpha=0.5, linewidth=1)

# Overhead GFLOPS - Direct Compilation
ax = axes[1, 1]
for variant in variants:
    mask = (df_pivot['variant'] == variant) & (df_pivot['method'] == 'direct_compilation')
    data = df_pivot[mask].sort_values('matSize')
    ax.plot(data['matSize'], data['overhead_gflops_percent'], 
            marker='s', label=variant, linewidth=2, markersize=6)
ax.set_xlabel('Tamanho da Matriz N', fontsize=11)
ax.set_ylabel('Perda de Desempenho (%)', fontsize=11)
ax.set_title('Overhead GFLOPS - Compilação Direta', fontsize=12, fontweight='bold')
ax.grid(True, alpha=0.3)
ax.legend()
ax.axhline(y=0, color='black', linestyle='--', alpha=0.5, linewidth=1)

plt.tight_layout()
plt.savefig('../figuras/overhead_vs_tamanho_matriz.png', dpi=300, bbox_inches='tight')
print("✓ Figura salva: overhead_vs_tamanho_matriz.png")
plt.show()

# FIGURA 2: Box plots de distribuição de overhead
fig, axes = plt.subplots(1, 2, figsize=(14, 6))
fig.suptitle('Distribuição de Overhead', fontsize=16, fontweight='bold')

# Preparar dados para boxplot
for idx, metric in enumerate(['overhead_tempo_percent', 'overhead_gflops_percent']):
    ax = axes[idx]
    data_to_plot = []
    labels = []
    positions = []
    pos = 1
    
    for variant in variants:
        for method in methods:
            mask = (df_pivot['variant'] == variant) & (df_pivot['method'] == method)
            values = df_pivot[mask][metric].values
            if len(values) > 0:
                data_to_plot.append(values)
                method_short = 'Alt' if method == 'alternatives' else 'Dir'
                labels.append(f"{variant}\n{method_short}")
                positions.append(pos)
                pos += 1
    
    bp = ax.boxplot(data_to_plot, positions=positions, labels=labels, patch_artist=True)
    
    # Colorir boxes
    colors = ['lightblue', 'lightgreen'] * (len(data_to_plot) // 2 + 1)
    for patch, color in zip(bp['boxes'], colors[:len(bp['boxes'])]):
        patch.set_facecolor(color)
    
    ylabel = 'Overhead de Tempo (%)' if idx == 0 else 'Overhead GFLOPS (%)'
    ax.set_ylabel(ylabel, fontsize=12)
    ax.grid(True, alpha=0.3, axis='y')
    ax.axhline(y=0, color='red', linestyle='--', alpha=0.5, linewidth=1.5)
    plt.setp(ax.xaxis.get_majorticklabels(), rotation=0, ha='center')

plt.tight_layout()
plt.savefig('../figuras/overhead_distribuicao_boxplot.png', dpi=300, bbox_inches='tight')
print("✓ Figura salva: overhead_distribuicao_boxplot.png")
plt.show()

# FIGURA 3: Comparação de desempenho (GFLOPS)
fig, axes = plt.subplots(1, 2, figsize=(14, 6))
fig.suptitle('Comparação de Desempenho em GFLOPS', fontsize=16, fontweight='bold')

for idx, method in enumerate(methods):
    ax = axes[idx]
    for variant in variants:
        mask = (df_pivot['variant'] == variant) & (df_pivot['method'] == method)
        data = df_pivot[mask].sort_values('matSize')
        
        # Plot native
        ax.plot(data['matSize'], data['gflops_native'], 
                marker='o', label=f'{variant} Native', linewidth=2, 
                linestyle='-', markersize=6)
        # Plot docker
        ax.plot(data['matSize'], data['gflops_docker'], 
                marker='s', label=f'{variant} Docker', linewidth=2, 
                linestyle='--', markersize=6, alpha=0.7)
    
    method_title = 'Alternatives' if method == 'alternatives' else 'Compilação Direta'
    ax.set_xlabel('Tamanho da Matriz N', fontsize=11)
    ax.set_ylabel('Desempenho (GFLOPS)', fontsize=11)
    ax.set_title(f'{method_title}', fontsize=12, fontweight='bold')
    ax.grid(True, alpha=0.3)
    ax.legend(fontsize=9)

plt.tight_layout()
plt.savefig('../figuras/comparacao_desempenho_gflops.png', dpi=300, bbox_inches='tight')
print("✓ Figura salva: comparacao_desempenho_gflops.png")
plt.show()

# TABELA 1: Resumo de overhead por biblioteca e método
summary_table = df_pivot.groupby(['variant', 'method']).agg({
    'native': 'mean',
    'docker': 'mean',
    'overhead_tempo_percent': 'mean',
    'gflops_native': 'mean',
    'gflops_docker': 'mean',
    'overhead_gflops_percent': 'mean',
    'slowdown': 'mean'
}).round(4)

summary_table.columns = ['T_native (s)', 'T_docker (s)', 'Overhead_tempo (%)', 
                          'GFLOPS_native', 'GFLOPS_docker', 'Overhead_GFLOPS (%)', 'Slowdown']

print("\n" + "=" * 80)
print("TABELA RESUMO: Overhead Docker vs Nativo")
print("=" * 80)
print(summary_table)

# Salvar tabela
summary_table.to_csv('../tabelas/resumo_overhead.csv')
summary_table.to_latex('../tabelas/resumo_overhead.tex', float_format="%.4f")
print("\n✓ Tabelas salvas: resumo_overhead.csv e resumo_overhead.tex")


# =============================================================================
# TODO 6: Sumarizar resultados e gerar artefatos finais para o TCC
# =============================================================================

print("\n" + "=" * 80)
print("TODO 6: ARTEFATOS FINAIS PARA TCC")
print("=" * 80)

# Tabela detalhada com todas as métricas
detailed_table = df_pivot[['variant', 'method', 'matSize', 'native', 'docker',
                           'overhead_tempo_percent', 'overhead_tempo_abs',
                           'gflops_native', 'gflops_docker', 'overhead_gflops_percent',
                           'slowdown']].copy()

detailed_table.columns = ['BLAS', 'Método', 'N', 'T_host (s)', 'T_dock (s)',
                          'OH_tempo (%)', 'OH_abs (s)', 'P_host (GFLOPS)', 
                          'P_dock (GFLOPS)', 'OH_GFLOPS (%)', 'Slowdown']

detailed_table.to_csv('../tabelas/resultados_detalhados.csv', index=False, float_format='%.6f')
detailed_table.to_latex('../tabelas/resultados_detalhados.tex', index=False, float_format="%.6f")
print("✓ Tabela detalhada salva: resultados_detalhados.csv e .tex")

# Estatísticas completas
overhead_stats.to_csv('../tabelas/estatisticas_overhead.csv')
overhead_stats.to_latex('../tabelas/estatisticas_overhead.tex', float_format="%.4f")
print("✓ Estatísticas salvas: estatisticas_overhead.csv e .tex")

# Relatório em Markdown
with open('../relatorio_overhead_docker.md', 'w', encoding='utf-8') as f:
    f.write("# Relatório de Análise: Overhead Docker vs Nativo em HPC\n\n")
    f.write("## Resumo Executivo\n\n")
    
    # Calcular métricas gerais
    overall_time_overhead = df_pivot['overhead_tempo_percent'].mean()
    overall_gflops_overhead = df_pivot['overhead_gflops_percent'].mean()
    overall_slowdown = df_pivot['slowdown'].mean()
    
    f.write(f"- **Overhead médio de tempo**: {overall_time_overhead:.3f}%\n")
    f.write(f"- **Overhead médio de GFLOPS**: {overall_gflops_overhead:.3f}%\n")
    f.write(f"- **Slowdown médio**: {overall_slowdown:.4f}x\n")
    f.write(f"- **Bibliotecas analisadas**: {', '.join(variants)}\n")
    f.write(f"- **Métodos comparados**: Alternatives vs Compilação Direta\n")
    f.write(f"- **Tamanhos de matriz**: {df_pivot['matSize'].min()} a {df_pivot['matSize'].max()}\n\n")
    
    f.write("## Classificação do Overhead\n\n")
    if abs(overall_time_overhead) < 1.0:
        f.write("**DESPREZÍVEL** (< 1%): Docker pode ser usado sem impacto perceptível no desempenho.\n\n")
        f.write("✅ Recomendado para desenvolvimento E produção HPC\n\n")
    elif abs(overall_time_overhead) < 3.0:
        f.write("**ACEITÁVEL** (< 3%): Docker apresenta overhead pequeno, aceitável para a maioria dos casos.\n\n")
        f.write("✅ Recomendado para desenvolvimento e testes; aceitável para produção\n\n")
    elif abs(overall_time_overhead) < 5.0:
        f.write("**PEQUENO** (< 5%): Docker apresenta overhead mensurável, mas ainda gerenciável.\n\n")
        f.write("⚠️  Usar Docker apenas para desenvolvimento; preferir nativo para produção\n\n")
    else:
        f.write("**SIGNIFICATIVO** (≥ 5%): Docker introduz overhead considerável.\n\n")
        f.write("❌ Não recomendado para produção HPC; usar apenas ambiente nativo\n\n")
    
    f.write("## Resultados por Biblioteca e Método\n\n")
    f.write("### Tabela de Resumo\n\n")
    f.write(summary_table.to_markdown())
    f.write("\n\n")
    
    f.write("## Análise Estatística\n\n")
    f.write("### Overhead de Tempo (%)\n\n")
    overhead_time_stats = overhead_stats['overhead_tempo_percent'].round(3)
    f.write(overhead_time_stats.to_markdown())
    f.write("\n\n")
    
    f.write("### Overhead de GFLOPS (%)\n\n")
    overhead_gflops_stats = overhead_stats['overhead_gflops_percent'].round(3)
    f.write(overhead_gflops_stats.to_markdown())
    f.write("\n\n")
    
    f.write("## Conclusões\n\n")
    f.write("### Questões Respondidas\n\n")
    f.write("1. **Existe overhead mensurável ao usar Docker para aplicações HPC baseadas em DGEMM?**\n")
    f.write(f"   - Sim, overhead médio de {overall_time_overhead:.2f}% no tempo de execução\n\n")
    
    f.write("2. **Esse overhead depende do tamanho da matriz N?**\n")
    # Calcular correlação
    correlation = df_pivot[['matSize', 'overhead_tempo_percent']].corr().iloc[0, 1]
    if abs(correlation) > 0.5:
        trend = "aumenta" if correlation > 0 else "diminui"
        f.write(f"   - Sim, overhead {trend} com o tamanho da matriz (correlação: {correlation:.3f})\n\n")
    else:
        f.write(f"   - Overhead é relativamente constante independente do tamanho (correlação: {correlation:.3f})\n\n")
    
    f.write("3. **Diferentes implementações de BLAS são mais ou menos sensíveis ao Docker?**\n")
    for variant in variants:
        variant_overhead = df_pivot[df_pivot['variant'] == variant]['overhead_tempo_percent'].mean()
        f.write(f"   - {variant}: {variant_overhead:.3f}% overhead médio\n")
    f.write("\n")
    
    f.write("4. **Comparação entre Alternatives e Compilação Direta:**\n")
    for variant in variants:
        alt_overhead = df_pivot[(df_pivot['variant'] == variant) & 
                                (df_pivot['method'] == 'alternatives')]['overhead_tempo_percent'].mean()
        dir_overhead = df_pivot[(df_pivot['variant'] == variant) & 
                                (df_pivot['method'] == 'direct_compilation')]['overhead_tempo_percent'].mean()
        f.write(f"   - {variant}: Alternatives={alt_overhead:.3f}%, Direta={dir_overhead:.3f}%\n")
    f.write("\n")
    
    f.write("## Recomendações para HPC\n\n")
    f.write("Com base nos resultados obtidos:\n\n")
    
    if abs(overall_time_overhead) < 3.0:
        f.write("- ✅ **Docker é VIÁVEL para HPC** com overhead desprezível ou aceitável\n")
        f.write("- Benefícios: reprodutibilidade, portabilidade, facilidade de deployment\n")
        f.write("- Ideal para ambientes de desenvolvimento, testes e produção\n")
    else:
        f.write("- ⚠️  **Docker deve ser usado com cautela em HPC**\n")
        f.write("- Recomendado apenas para desenvolvimento e testes\n")
        f.write("- Para produção, preferir ambiente nativo para máximo desempenho\n")
    
    f.write("\n## Figuras Geradas\n\n")
    f.write("- `overhead_vs_tamanho_matriz.png`: Overhead em função do tamanho da matriz\n")
    f.write("- `overhead_distribuicao_boxplot.png`: Distribuição estatística do overhead\n")
    f.write("- `comparacao_desempenho_gflops.png`: Comparação de desempenho Native vs Docker\n")
    f.write("\n## Tabelas Geradas\n\n")
    f.write("- `resumo_overhead.csv/.tex`: Resumo de métricas por biblioteca e método\n")
    f.write("- `resultados_detalhados.csv/.tex`: Todas as medições e cálculos\n")
    f.write("- `estatisticas_overhead.csv/.tex`: Estatísticas descritivas completas\n")

print("✓ Relatório completo salvo: relatorio_overhead_docker.md")

print("\n" + "=" * 80)
print("RESUMO DOS ARTEFATOS GERADOS")
print("=" * 80)
print("\n📊 FIGURAS (300 DPI, formato PNG):")
print("  ├─ overhead_vs_tamanho_matriz.png")
print("  ├─ overhead_distribuicao_boxplot.png")
print("  └─ comparacao_desempenho_gflops.png")
print("\n📋 TABELAS (CSV e LaTeX):")
print("  ├─ resumo_overhead.csv / .tex")
print("  ├─ resultados_detalhados.csv / .tex")
print("  └─ estatisticas_overhead.csv / .tex")
print("\n📝 RELATÓRIO:")
print("  └─ relatorio_overhead_docker.md")
print("\n✅ Todos os TODOs foram implementados com sucesso!")
print("=" * 80)
