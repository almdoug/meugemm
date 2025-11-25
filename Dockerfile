FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

LABEL maintainer="meuGEMM Project"
LABEL description="Container para testes de desempenho DGEMM"

# instalar dependências
RUN apt-get update && apt-get install -y \
    gcc \
    make \
    libgsl-dev \
    libblas-dev \
    libblas64-dev \
    libatlas-base-dev \
    libopenblas64-dev \
    libopenblas64-serial-dev \
    libopenblas64-pthread-dev \
    libopenblas64-openmp-dev \
    libblis64-dev \
    libblis64-pthread-dev \
    libblis64-openmp-dev \
    libblis-dev \
    libblis-pthread-dev \
    libblis-openmp-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY teste_GSL_DGEMM.c .
COPY teste_DGEMM.c .
COPY run_all_tests.sh .
COPY run_all_alternatives.sh .
COPY run_all_tests_multithread.sh .
COPY run_all_alternatives_multithread.sh .

# scripts executáveis
RUN chmod +x run_all_tests.sh run_all_alternatives.sh run_all_tests_multithread.sh run_all_alternatives_multithread.sh

# criar estrutura de diretórios para outputs
RUN mkdir -p output/single/native/alternatives \
    && mkdir -p output/single/native/direct_compilation \
    && mkdir -p output/single/docker/alternatives \
    && mkdir -p output/single/docker/direct_compilation \
    && mkdir -p output/multi/native/alternatives \
    && mkdir -p output/multi/native/direct_compilation \
    && mkdir -p output/multi/docker/alternatives \
    && mkdir -p output/multi/docker/direct_compilation \
    && mkdir -p logs/single/native/alternatives \
    && mkdir -p logs/single/native/direct_compilation \
    && mkdir -p logs/single/docker/alternatives \
    && mkdir -p logs/single/docker/direct_compilation \
    && mkdir -p logs/multi/native/alternatives \
    && mkdir -p logs/multi/native/direct_compilation \
    && mkdir -p logs/multi/docker/alternatives \
    && mkdir -p logs/multi/docker/direct_compilation

# variáveis de ambiente
ENV OPENBLAS_NUM_THREADS=1
ENV BLIS_NUM_THREADS=1

# comando padrão
CMD ["./run_all_tests.sh"]
