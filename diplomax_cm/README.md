# Diplomax CM

Full-stack academic credential platform with FastAPI backend and multiple Flutter clients.

## One-Sentence Value Proposition
Diplomax CM provides issuance, verification, and management workflows for academic credentials across students, universities, recruiters, and administrators.

## Problem Statement
Credential validation workflows are often slow, fragmented, and difficult to trust across institutions and recruiters.

## Proposed Solution
Diplomax CM combines a role-based backend, mobile/web clients, and verification-support services to streamline academic document management and verification.

## Implemented Architecture
- **Backend:** FastAPI + SQLAlchemy async + PostgreSQL
- **Cache/queues:** Redis + Celery worker queues
- **Edge/proxy:** Nginx
- **Clients:** Flutter apps for student, university, recruiter, and admin roles
- **Ops:** Docker Compose local stack and GitHub Actions CI/CD workflows

## Repository Structure
- `backend/` — FastAPI API, data models, services, tests
- `diplomax_student/` — Flutter student app
- `diplomax_university/` — Flutter university/staff app
- `diplomax_recruiter/` — Flutter recruiter app
- `diplomax_admin/` — Flutter web administration portal
- `playwright-mvp/` — Playwright test scaffolding
- `RUNNING.md` — local run instructions
- `CI-CD.md` — CI/CD workflow documentation

## Technology Stack
- Python, FastAPI, SQLAlchemy, Celery
- PostgreSQL, Redis
- Flutter / Dart
- Docker Compose, Nginx
- GitHub Actions

## Security and Configuration
- `.env.example` is provided for local configuration.
- Sensitive values are environment-driven (JWT keys, DB credentials, payment keys, cloud keys).
- Do not commit real credentials to source control.

## Setup and Running
Use [`RUNNING.md`](./RUNNING.md) for full setup.

Quick overview:
1. Configure backend `.env` from `.env.example`
2. Start services via Docker Compose
3. Run required Flutter client with API base URL override when needed

## Testing
- Backend smoke tests: `backend/tests/test_smoke_endpoints.py`
- CI workflow includes backend pytest and Flutter analyze/test checks

## Deployment Status
- CI workflows exist for backend checks, APK builds, release assets, and backend image publishing.
- Production deployment details depend on external environment configuration.

## Project Status
Actively implemented multi-module project with production-oriented structure and remaining enhancement areas.

## Limitations
- Full local execution requires Docker, Flutter SDK, and configured credentials.
- Some integrations depend on external service credentials/environments.

## Future Improvements
- Expand backend unit/integration coverage
- Add consolidated architecture diagrams in markdown
- Add reproducible local developer bootstrap scripts per platform

## Contribution Context
This repository is a major academic engineering project with substantial implementation by **Nguend Arthur Johann** across backend and client modules.

## Contact
- GitHub: [NGUEND-ARTHUR](https://github.com/NGUEND-ARTHUR)
