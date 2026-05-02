#!/usr/bin/env bash
# =============================================================================
# ChatMax — Provisionamento de novo cliente
# =============================================================================
# Uso:
#   ./new-client.sh --client=acme --backend-domain=api.acme.com.br --frontend-domain=app.acme.com.br
#
# Gera um arquivo .env.<cliente> pronto para colar no Dokploy.
# =============================================================================
set -euo pipefail

# ── Parsing de argumentos ───────────────────────────────────────────────────��
CLIENT=""
BACKEND_DOMAIN=""
FRONTEND_DOMAIN=""

for arg in "$@"; do
  case $arg in
    --client=*)          CLIENT="${arg#*=}" ;;
    --backend-domain=*)  BACKEND_DOMAIN="${arg#*=}" ;;
    --frontend-domain=*) FRONTEND_DOMAIN="${arg#*=}" ;;
  esac
done

# ── Validação ────────────────────────────────────────────────────────────────
if [[ -z "$CLIENT" || -z "$BACKEND_DOMAIN" || -z "$FRONTEND_DOMAIN" ]]; then
  echo "Uso: $0 --client=NOME --backend-domain=DOMINIO --frontend-domain=DOMINIO"
  echo ""
  echo "Exemplo:"
  echo "  $0 --client=acme --backend-domain=api.acme.com.br --frontend-domain=app.acme.com.br"
  exit 1
fi

# ── Nome do banco (sanitizado) ───────────────────────────────────────────────
DB_NAME="evo_$(echo "$CLIENT" | tr '[:upper:]' '[:lower:]' | tr '-' '_' | tr ' ' '_')"

# ── Geração de secrets ───────────────────────────────────────────────────────
gen() { openssl rand -base64 32 | tr -d '\n'; }

POSTGRES_PASSWORD=$(gen)
REDIS_PASSWORD=$(gen)
SECRET_KEY_BASE=$(gen)
JWT_SECRET_KEY=$(gen)
DOORKEEPER_JWT_SECRET_KEY=$(gen)
EVOAI_CRM_API_TOKEN=$(gen)
ENCRYPTION_KEY=$(gen)
BOT_RUNTIME_SECRET=$(gen)

# ── Arquivo de saída ─────────────────────────────────────────────────────────
OUTPUT_FILE=".env.${CLIENT}"

cat > "$OUTPUT_FILE" <<EOF
# =============================================================================
# ChatMax — Cliente: ${CLIENT}
# Gerado em: $(date '+%Y-%m-%d %H:%M:%S')
# =============================================================================

# -----------------------------------------------------------------------------
# DOMÍNIOS
# -----------------------------------------------------------------------------
BACKEND_URL=https://${BACKEND_DOMAIN}
FRONTEND_URL=https://${FRONTEND_DOMAIN}
CORS_ORIGINS=https://${FRONTEND_DOMAIN},https://${BACKEND_DOMAIN}
APP_URL=https://${FRONTEND_DOMAIN}
API_URL=https://${BACKEND_DOMAIN}

# -----------------------------------------------------------------------------
# BANCO
# -----------------------------------------------------------------------------
POSTGRES_DATABASE=${DB_NAME}
POSTGRES_USERNAME=postgres
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# -----------------------------------------------------------------------------
# REDIS
# -----------------------------------------------------------------------------
REDIS_PASSWORD=${REDIS_PASSWORD}

# -----------------------------------------------------------------------------
# SECRETS
# -----------------------------------------------------------------------------
SECRET_KEY_BASE=${SECRET_KEY_BASE}
JWT_SECRET_KEY=${JWT_SECRET_KEY}
DOORKEEPER_JWT_SECRET_KEY=${DOORKEEPER_JWT_SECRET_KEY}
EVOAI_CRM_API_TOKEN=${EVOAI_CRM_API_TOKEN}
ENCRYPTION_KEY=${ENCRYPTION_KEY}
BOT_RUNTIME_SECRET=${BOT_RUNTIME_SECRET}

# -----------------------------------------------------------------------------
# FIXO — IGUAL PARA TODOS OS CLIENTES
# -----------------------------------------------------------------------------

GATEWAY_PORT=3030
FRONTEND_PORT=5173

RAILS_ENV=production
RAILS_MAX_THREADS=5
RAILS_SERVE_STATIC_FILES=true
RAILS_LOG_TO_STDOUT=true

MAILER_SENDER_EMAIL=suporte@chatmax.app.br
DOORKEEPER_JWT_ALGORITHM=hs256
DOORKEEPER_JWT_ISS=evo-auth-service
MFA_ISSUER=chatmax
SIDEKIQ_CONCURRENCY=10
ACTIVE_STORAGE_SERVICE=local

DISABLE_TELEMETRY=true
LOG_LEVEL=info
ENABLE_ACCOUNT_SIGNUP=true
ENABLE_PUSH_RELAY_SERVER=true
ENABLE_INBOX_EVENTS=true

DB_MAX_IDLE_CONNS=10
DB_MAX_OPEN_CONNS=100
DB_CONN_MAX_LIFETIME=1h
DB_CONN_MAX_IDLE_TIME=30m
JWT_ALGORITHM=HS256
AI_PROCESSOR_VERSION=v1

REDIS_DB=0
REDIS_KEY_PREFIX=a2a:
REDIS_TTL=3600
HOST=0.0.0.0
PORT=8000
DEBUG=false
API_TITLE=ChatMax
API_DESCRIPTION=ChatMax Agent Processor
API_VERSION=1.0.0
ORGANIZATION_NAME=Maximus Resultados Comerciais
ORGANIZATION_URL=https://www.chatmax.app.br
TOOLS_CACHE_ENABLED=true
TOOLS_CACHE_TTL=3600

LISTEN_ADDR=0.0.0.0:8080
AI_CALL_TIMEOUT_SECONDS=30

VITE_BRAND_LOGO_URL=https://vrwqwnqnqbxppxtpwoae.supabase.co/storage/v1/object/public/CHATMAX%20LOGO/logo-horizontal-dark-2560.png
EOF

# ── Resumo ───────────────────────────────────────────────────────────────────
echo ""
echo "✓ Arquivo gerado: ${OUTPUT_FILE}"
echo ""
echo "  Cliente:   ${CLIENT}"
echo "  Banco:     ${DB_NAME}"
echo "  Frontend:  https://${FRONTEND_DOMAIN}"
echo "  Backend:   https://${BACKEND_DOMAIN}"
echo ""
echo "Próximos passos no Dokploy:"
echo "  1. Crie um novo projeto Compose"
echo "  2. Aponte para este repositório"
echo "  3. Cole o conteúdo de ${OUTPUT_FILE} nas variáveis de ambiente"
echo "  4. Configure os domínios: ${FRONTEND_DOMAIN} e ${BACKEND_DOMAIN}"
echo "  5. Deploy"
echo ""
