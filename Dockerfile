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
    libblis64-dev \
    libblis-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY teste_GSL_DGEMM.c .
COPY teste_DGEMM.c .
COPY run_all_tests.sh .
COPY run_all_alternatives.sh .

# scripts executáveis
RUN chmod +x run_all_tests.sh run_all_alternatives.sh
RUN mkdir -p output logs

# variáveis de ambiente
ENV OPENBLAS_NUM_THREADS=1
ENV BLIS_NUM_THREADS=1

# comando padrão
CMD ["./run_all_tests.sh"]
