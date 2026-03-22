# CLAUDE.md — Microservices Project

## Project
[PROJECT_NAME] — Microservices architecture for [what it does].
[Number] services communicating via [REST / gRPC / message queue].

## Services
| Service | Port | Tech | Purpose |
|---------|------|------|---------|
| api-gateway | 8080 | [framework] | Request routing, auth |
| user-service | 8081 | [framework] | User management |
| [service-name] | [port] | [framework] | [purpose] |

## Commands
- `docker-compose up` — start all services
- `docker-compose up [service]` — start single service
- `cd services/[name] && [test command]` — test single service
- `[script] test-all` — run all service tests
- `[script] migrate` — run all migrations

## Architecture
- Each service owns its data — no shared databases
- Inter-service communication via [REST + circuit breakers / gRPC / Kafka / RabbitMQ]
- API Gateway handles auth, rate limiting, routing
- Shared contracts in proto/ or contracts/ directory
- Each service has its own CLAUDE.md for service-specific context

## Conventions
- Service naming: kebab-case (user-service, not UserService)
- Each service follows the same internal structure
- Distributed tracing via [OpenTelemetry / Jaeger]
- Centralized logging format: JSON structured logs
- Health checks: GET /health on every service

## Do NOT
- Make direct database calls to another service's database
- Create synchronous chains of more than 3 service calls
- Deploy services with different versions of shared contracts
- Skip circuit breakers on inter-service HTTP calls
