# Base image
FROM nvidia/cuda:11.6.0-base-ubuntu20.04 AS python-base
ENV PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_VERSION=1.1.11 \
    POETRY_PATH=/opt/poetry \
    VENV_PATH=/opt/venv
ENV PATH="$POETRY_PATH/bin:$VENV_PATH/bin:$PATH"

# Build image
FROM python-base AS installs
RUN apt-get update \
    && apt-get install gcc git curl build-essential -y \
    && python3 python3-pip \
    && apt-get install libgomp1 -y \
    && apt-get clean \
    && curl -sSL https://raw.githubusercontent.com/sdispater/poetry/master/get-poetry.py | python \
    && mv /root/.poetry $POETRY_PATH \
    && python -m venv $VENV_PATH \
    && rm -rf /var/lib/apt/lists/*
    
WORKDIR /usr/src/public_endpoint
COPY poetry.lock pyproject.toml ./
RUN poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi -vvv \
    && poetry add pytest requests \
    && pip3 install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu113 \
    && pip3 install opencv-python torchgeometry

# Production image
FROM python-base AS public_endpoint
RUN apt-get update && apt-get install libgomp1 -y
COPY --from=installs $VENV_PATH $VENV_PATH
WORKDIR /usr/src/public_endpoint
COPY . .

EXPOSE 4003
CMD ["gunicorn", "main:app", "--bind", "0.0.0.0:4003", "--worker-class", "uvicorn.workers.UvicornWorker", "--workers","4", "--threads", "2", "--timeout", "300", "--graceful-timeout", "300"]

# docker build --platform=amd64 -t viton-hd-docker:v1 .
# docker run --platform=linux/amd64 -p 127.0.0.1:80:4003 -itd viton-hd-docker:v1