# Person Face Registration and Recognition Backend System with uvicorn, fastapi, milvus, redis and mysql

![Docker](https://img.shields.io/badge/docker-%230db7ed.svg?style=for-the-badge&logo=docker&logoColor=white)![FastAPI](https://img.shields.io/badge/FastAPI-005571?style=for-the-badge&logo=fastapi)

Tested with `docker-compose version 1.29.2`.

Backend system for detecting and saving a person's face from images into a vectorized milvus database to run facial recognition on images along with saving the person's data in a redis-cached mysql table for later retrieval. (Note: The system currently only supports one face per image for both face registration and lookup).

<img src="app_docker_compose/app/static/project_flow.png" width="40%" />

-   [milvus official setup reference](https://milvus.io/docs/install_standalone-docker.md)

## Setup

### 1. Download model weights

```bash
python3 -m venv venv
source venv/bin/activate
# inside venv/virtualenv/conda
pip install gdown
# download model weights
gdown 18dH0l6ESMaHJo3tFMySt0I8LsKcCss3o
unzip models.zip -d app_docker_compose/app/triton_server
rm models.zip
```

### 2, Create .env file

Create a `.env` file inside `app_docker_compose` based on the following parameters with necessary variables replaced:

```yaml
# download paths
DOWNLOAD_CACHE_PATH="app/.data"
DOWNLOAD_IMAGE_PATH="volumes/person_images"
# http api server
API_SERVER_PORT=8080
# milvus
MILVUS_HOST=standalone
MILVUS_PORT=19530
ATTU_PORT=3000
# mysql mariadb
MYSQL_HOST=mysql
MYSQL_PORT=3306
MYSQL_USER=user
MYSQL_PASSWORD=pass
MYSQL_DATABASE=default
MYSQL_PERSON_TABLE=person
MYSQL_ROOT_PASSWORD=admin
# phpmyadmin mariadb
PMA_GUI_PORT=8001
PMA_HOST=${MYSQL_HOST}
PMA_PORT=${MYSQL_PORT}
PMA_USER=${MYSQL_USER}
PMA_PASSWORD=${MYSQL_PASSWORD}
# redis
REDIS_HOST=redis-server
REDIS_PORT=6379
```

Note: Only `.env` allows docker-compose to access variables inside `.env` file during build-time. Using `env_file` or the `environment` parameters inside the docker-compose file only allows variable access inside containers and not during build time.

### 3. Setup sql schema for storing person data

Schema for creating person data table and the table name should be modified at: `app_docker_compose/app/static/sql/init.sql`

### 4. Create a volume directory to hold user images

```shell
mkdir -p volumes/person_images
```

## Setup with Docker Compose for Deployment

**Start uvicorn and triton server with a milvus instance for face vector storage & search**

Note, an easier way to use later versions of docker-compose is to install the pip package with `pip install docker-compose` in a venv

```shell
cd app_docker_compose
# create shared volume directory to store imgs
mkdir -p volumes/person_images
# build all required containers
docker-compose build
# start all services
docker-compose up -d
```

Face registration and recognition fastapi will be available at <http://localhost:8080>.

## Setup with Docker and local python envs for Development

**Allows for rapid prototyping.**

Change into main working directory where all subsequent commands must be run.

```shell
cd app_docker_compose
```

### 1. Build docker

```shell
bash scripts/build_docker.sh
```

### 2. Local uvicorn requirements

```bash
# setup virtual env (conda env is fine as well)
python -m venv venv
source venv/bin/activate
# install all reqs
pip install --upgrade pip
pip install -r requirements.txt
```

### 3. Run servers

#### 3a. Start all required microservices with docker-compose

```shell
# clear all stopped containers
docker container prune
# start milvus vector database server with docker-compose
docker-compose up -d etcd minio standalone attu mysql mysql-admin redis-server
# check milvus server status with
docker-compose ps
```

#### 3b. Start face model triton=server

```shell
# start triton-server in a docker container exposed onport 8081
docker run -d --rm -p 127.0.0.1:8081:8081 --name uvicorn_trt_server_cont uvicorn_trt_server:latest tritonserver --model-store app/triton_server/models --allow-grpc=true --allow-http=false --grpc-port=8081
# check trtserver status with
docker logs uvicorn_trt_server_cont
```

#### 3c. Run fastapi + uvicorn server

```shell
python3 app/server.py -p EXPOSED_HTTP_PORT
```

## Running tests

```shell
cd app_docker_compose
pip install -r requirements.txt
pip install -r tests/requirements.txt
# set up all microservices
docker-compose up -d etcd minio standalone attu mysql mysql-admin redis-server
# start face model triton server
docker run -d --rm -p 127.0.0.1:8081:8081 --name uvicorn_trt_server_cont uvicorn_trt_server:latest tritonserver --model-store app/triton_server/models --allow-grpc=true --allow-http=false --grpc-port=8081
# run tests
pytest tests
```

Generating coverage reports

```shell
coverage run -m pytest tests/
coverage report -m -i
```

### Notes on docker-compose yml setup

Note if services other than the uvicorn web-api are to be exposed such as the milvus or minio servers, alter the `expose` options to published `ports` for access outside the docker containers.

```yaml
expose:
  - "9001"

ports:
  - "9001:9001"
```

For `docker-compose version 1.29.2` and `yaml version 3.9`, `mem_limit` can be used with `docker-compose up`:

```yaml
mem_limit: 512m
```

For `docker-compose version <1.29.2` and `yaml version <3.9`, the following deploy setup can be used with `docker-compose --compatibility up`:

```yaml
deploy:
  resources:
    limits:
      memory: 512m
```

### Notes on triton-server

Check saved.model inputs/outputs with `$ saved_model_cli show --dir savemodel_dir --all` after installing tensorflow.

Options for CPU and GPU based models for tritonserver:

```yaml
# CPU mode
instance_group [
    {
      count: 1
      kind: KIND_CPU
    }
  ]

# GPU mode
instance_group [
    {
      count: 1
      kind: KIND_GPU
      gpus: [ 0 ]
    }
  ]
```

## Acknowledgements

-   [milvus](https://milvus.io/)
-   [triton-server](https://developer.nvidia.com/nvidia-triton-inference-server)
-   [mariadb-mysql](https://mariadb.org/)
-   [redis](https://redis.io/)
-   [uvicorn](https://www.uvicorn.org/)
-   [fastapi](https://fastapi.tiangolo.com/)
