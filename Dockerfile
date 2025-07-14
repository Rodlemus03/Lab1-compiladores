FROM ubuntu:latest

# -----------------------------
# Dependencias del sistema
# -----------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl \
      bash-completion \
      openjdk-17-jdk \
      fontconfig \
      fonts-dejavu-core \
      software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Añadimos PPA de Python y instalamos pip + venv
RUN add-apt-repository -y ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      python3-pip \
      python3-venv \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Instalación de ANTLR
# -----------------------------
# JAR de ANTLR
COPY antlr-4.13.1-complete.jar /usr/local/lib/antlr-4.13.1-complete.jar

# Wrappers de antlr y grun
COPY commands/antlr /usr/local/bin/antlr
COPY commands/antlr /usr/bin/antlr
COPY commands/grun  /usr/local/bin/grun
COPY commands/grun  /usr/bin/grun
RUN apt-get update \
 && apt-get install -y dos2unix \
 && dos2unix /usr/local/bin/antlr /usr/local/bin/grun \
 && chmod +x /usr/local/bin/antlr /usr/local/bin/grun \
 && rm -rf /var/lib/apt/lists/*
RUN chmod +x /usr/local/bin/antlr /usr/bin/antlr \
             /usr/local/bin/grun   /usr/bin/grun

# -----------------------------
# Entorno Python
# -----------------------------
# Copiamos el requirements antes de instalar
COPY requirements.txt .

# Creamos el virtualenv
RUN python3 -m venv /venv

# Añadimos el venv al PATH para simplificar comandos posteriores
ENV PATH="/venv/bin:$PATH"

# Instalamos dependencias dentro del venv
RUN pip install --no-cache-dir -r requirements.txt

# -----------------------------
# Creación de usuario no-root
# -----------------------------
ARG USER=appuser
ARG UID=1001

RUN adduser \
      --disabled-password \
      --gecos "" \
      --home "/home/${USER}" \
      --no-create-home \
      --uid "${UID}" \
      "${USER}"

USER ${USER}

# -----------------------------
# Directorio de trabajo
# -----------------------------
WORKDIR /program

# A este punto, quien ejecute:
#   docker run --rm -ti -v "$(pwd)/program":/program lab1-image
# podrá entrar al contenedor y, dentro de /program, ejecutar:
#   antlr -Dlanguage=Python3 MiniLang.g4
#   python3 Driver.py program_test.txt
