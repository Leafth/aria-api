# Aria API

![Ruby](https://img.shields.io/badge/Ruby-CC342D?style=for-the-badge&logo=ruby&logoColor=white)
![Ruby on Rails](https://img.shields.io/badge/Ruby_on_Rails-D30001?style=for-the-badge&logo=rubyonrails&logoColor=white)
![Puma](https://img.shields.io/badge/Puma-5A1D81?style=for-the-badge&logo=rubygems&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/Postgres-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)
![Redis](https://img.shields.io/badge/Redis-FF4438?style=for-the-badge&logo=redis&logoColor=white)
![Sidekiq](https://img.shields.io/badge/Sidekiq-B1003E?style=for-the-badge&logo=sidekiq&logoColor=white)
![Devise](https://img.shields.io/badge/Devise-D30001?style=for-the-badge&logo=rubygems&logoColor=white)
![JWT](https://img.shields.io/badge/JWT-000000?style=for-the-badge&logo=jsonwebtokens&logoColor=white)
![Grover](https://img.shields.io/badge/Grover-4285F4?style=for-the-badge&logo=rubygems&logoColor=white)
![Puppeteer](https://img.shields.io/badge/Puppeteer-40B5A4?style=for-the-badge&logo=puppeteer&logoColor=white)
![RSpec](https://img.shields.io/badge/RSpec-CC342D?style=for-the-badge&logo=rubygems&logoColor=white)
![RuboCop](https://img.shields.io/badge/RuboCop-000000?style=for-the-badge&logo=rubocop&logoColor=white)
![Brakeman](https://img.shields.io/badge/Brakeman-8B0000?style=for-the-badge&logo=rubygems&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white)
![GitHub Actions](https://img.shields.io/badge/GitHub_Actions-2671E5?style=for-the-badge&logo=githubactions&logoColor=white)

Sistema voltado para o gerenciamento reprodutivo de matrizes bovinas. O sistema permite cadastrar matrizes, acompanhar eventos reprodutivos, receber alertas e gerenciar apoios reprodutivos.

### Pré-requisitos

![Git](https://img.shields.io/badge/Git-F05032?style=flat&logo=git&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)
![Docker Compose](https://img.shields.io/badge/Docker_Compose-2496ED?style=flat&logo=docker&logoColor=white)

### Executando o projeto

#### 1. Clone o repositório

```bash
git clone https://github.com/Leafth/aria-api.git
cd aria-api
```

#### 2. Configure as variáveis de ambiente

Crie o arquivo `.env` a partir do arquivo de exemplo:

```bash
cp .env.example .env
```

Revise os valores das variáveis de ambiente conforme necessário.

#### 3. Construa as imagens

```bash
docker compose -f compose.dev.yml build
```

#### 4. Gere o secret para o access token

```bash
docker compose -f compose.dev.yml run --rm api bin/rails secret
```

Copie o valor gerado e adicione-o à variável `ACCESS_TOKEN_SECRET` no arquivo `.env`.

#### 5. Popule o banco de dados

Execute as seeds para criar os dados iniciais de desenvolvimento:

```bash
docker compose -f compose.dev.yml run --rm api bin/rails db:seed
```

As seeds criam um usuário padrão para acesso ao sistema. As credenciais podem ser consultadas ou alteradas no arquivo `db/seeds.rb`.

#### 6. Inicie os serviços

```bash
docker compose -f compose.dev.yml up
```

Durante a inicialização, a aplicação prepara o banco de dados automaticamente.

A API estará disponível em:

```text
http://localhost:3000
```

### Serviços

| Serviço  | Descrição                                             |
| -------- | ----------------------------------------------------- |
| `api`    | Aplicação Ruby on Rails                               |
| `worker` | Processamento de tarefas em segundo plano com Sidekiq |
| `db`     | Banco de dados PostgreSQL                             |
| `redis`  | Armazenamento utilizado pelo Sidekiq                  |

### Comandos úteis

#### Iniciar serviços em segundo plano

```bash
docker compose -f compose.dev.yml up -d
```

#### Parar serviços

```bash
docker compose -f compose.dev.yml down
```

#### Visualizar serviços em execução

```bash
docker compose -f compose.dev.yml ps
```

#### Acompanhar logs

```bash
docker compose -f compose.dev.yml logs -f
```

#### Executar migrations

```bash
docker compose -f compose.dev.yml exec api bin/rails db:migrate
```

#### Executar seeds

```bash
docker compose -f compose.dev.yml exec api bin/rails db:seed
```

#### Abrir console Rails

```bash
docker compose -f compose.dev.yml exec api bin/rails console
```

#### Gerar secret com Rails

```bash
docker compose -f compose.dev.yml exec api bin/rails secret
```

### Frontend

Consulte o repositório da interface web em [Aria Frontend](https://github.com/Leafth/aria-frontend).
