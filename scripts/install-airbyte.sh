#!/bin/bash
# ─────────────────────────────────────────────
# Airbyte OSS — instalação via abctl
#
# O docker-compose do Airbyte foi DEPRECIADO em ago/2024.
# A partir da versão 1.0, o Airbyte usa Kubernetes local (k3d)
# gerenciado pelo abctl (Airbyte Control CLI).
#
# Docs: https://docs.airbyte.com/platform/deploying-airbyte
# ─────────────────────────────────────────────
set -e

AIRBYTE_PORT="${AIRBYTE_PORT:-8000}"
INSTALL_DIR="$HOME/.airbyte"

echo "📦 Instalando abctl (Airbyte CLI)..."

# Instala abctl (Linux/macOS)
if ! command -v abctl &> /dev/null; then
  curl -LsfS https://get.airbyte.com | bash -
  # Adiciona ao PATH se necessário
  export PATH="$HOME/.local/bin:$PATH"
else
  echo "✅ abctl já instalado: $(abctl version)"
fi

echo ""
echo "🚀 Subindo Airbyte OSS na porta $AIRBYTE_PORT..."
echo "   Isso pode levar alguns minutos na primeira vez (download das imagens)."
echo ""

abctl local install --port "$AIRBYTE_PORT"

echo ""
echo "🎉 Airbyte disponível em: http://localhost:$AIRBYTE_PORT"
echo ""
echo "Credenciais padrão:"
abctl local credentials
