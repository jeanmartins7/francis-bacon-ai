#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function show_help() {
    echo "=========================================================="
    echo "  Donatello AI - Gerenciador de Modelos Locais (Ollama)   "
    echo "  Configurado para: RTX 3070 8GB + 64GB RAM (Offload)     "
    echo "=========================================================="
    echo "Uso: ./build-models.sh [14b|32b|7b|all|list]"
    echo ""
    echo "  14b  (Padrão / Recomendado BenchLM - Melhor Custo-Benefício):"
    echo "       Qwen2.5-Coder-14B (~9GB) -> ~30 layers na GPU (5.8GB) + ~18 layers na RAM (3.2GB)"
    echo "       Cria o modelo: francis-bacon-architect"
    echo ""
    echo "  32b  (Deep Architecture / Refatoração Complexa):"
    echo "       Qwen2.5-Coder-32B (~20GB) -> ~15 layers na GPU + ~49 layers na RAM (15GB)"
    echo "       Cria o modelo: francis-bacon-architect-32b"
    echo ""
    echo "  7b   (Ultra-Fast / 100% VRAM):"
    echo "       Qwen2.5-Coder-7B (~7GB) -> 100% dos layers na GPU (0% RAM)"
    echo "       Cria o modelo: francis-bacon-architect-7b"
    echo ""
    echo "  all  Compila todas as 3 variantes"
    echo "  list Lista os modelos atualmente instalados no Ollama"
    echo "=========================================================="
}

TARGET="${1:-14b}"

if ! docker ps | grep -q "ollama"; then
    echo "❌ O container 'ollama' não está rodando. Iniciando com docker compose..."
    (cd "$DIR" && docker compose up -d)
fi

case "$TARGET" in
    14b)
        echo "🚀 [1/2] Baixando modelo base qwen2.5-coder:14b-instruct-q4_K_M..."
        docker exec -it ollama ollama pull qwen2.5-coder:14b-instruct-q4_K_M
        echo "🔨 [2/2] Criando modelo francis-bacon-architect (14B Sweet Spot)..."
        docker exec -it ollama ollama create francis-bacon-architect -f /etc/ollama/context/Architect.modelfile
        echo "✅ Modelo 'francis-bacon-architect' criado com sucesso!"
        ;;
    32b)
        echo "🚀 [1/2] Baixando modelo base qwen2.5-coder:32b-instruct-q4_K_M..."
        docker exec -it ollama ollama pull qwen2.5-coder:32b-instruct-q4_K_M
        echo "🔨 [2/2] Criando modelo francis-bacon-architect-32b (Deep Architect)..."
        docker exec -it ollama ollama create francis-bacon-architect-32b -f /etc/ollama/context/Architect-32b.modelfile
        echo "✅ Modelo 'francis-bacon-architect-32b' criado com sucesso!"
        ;;
    7b)
        echo "🚀 [1/2] Baixando modelo base qwen2.5-coder:7b-instruct-q8_0..."
        docker exec -it ollama ollama pull qwen2.5-coder:7b-instruct-q8_0
        echo "🔨 [2/2] Criando modelo francis-bacon-architect-7b (Fast Pure GPU)..."
        docker exec -it ollama ollama create francis-bacon-architect-7b -f /etc/ollama/context/Architect-7b.modelfile
        echo "✅ Modelo 'francis-bacon-architect-7b' criado com sucesso!"
        ;;
    all)
        "$0" 14b
        "$0" 32b
        "$0" 7b
        ;;
    list)
        echo "📦 Modelos disponíveis no Ollama:"
        docker exec -it ollama ollama list
        ;;
    *)
        show_help
        exit 1
        ;;
esac
