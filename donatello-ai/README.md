# Donatello AI

Stack local de desenvolvimento com Ollama, Open WebUI e dois perfis para um Ryzen 7
5700X, 64 GB de RAM e RTX 3070 de 8 GB.

Consulte o [guia completo de execução](RUNBOOK.md) para pré requisitos, inicialização,
verificação da GPU e diagnóstico.

## Perfis

| Modelo | Uso | Memória e execução |
| --- | --- | --- |
| `francis-bacon-architect` | Análise, arquitetura e tarefas que exigem mais raciocínio | Mellum2 Thinking 12B MoE em Q4_K_M; 20 camadas na GPU e as demais na RAM/CPU. |
| `francis-bacon-fast` | Edição e perguntas curtas com menor latência | Qwen2.5-Coder 7B Q6; todas as camadas elegíveis na GPU. |
| `francis-bacon-opencode` | Agente OpenCode em repositórios | Mellum2 Thinking Q4 com contexto de 64K; 12 camadas na GPU e o restante em RAM/CPU. |

O primeiro perfil implementa offload RAM/GPU: a RAM de 64 GB comporta os pesos e a
RTX executa uma parte das camadas. Swap do sistema não é usado como extensão ativa do
modelo; ele só deve funcionar como proteção contra picos. Quando há paginação em swap,
a geração fica muito lenta. Por isso o serviço limita a um modelo e uma requisição em
paralelo, usa contexto de 8K e KV cache `q8_0`.

## Escolha do modelo

O BenchLM recomenda Mellum2-12B-A2.5B-Thinking para hardware com 8 GB de VRAM e
registra 69,9 no LiveCodeBench para o modelo. O mesmo levantamento coloca modelos de
8--20B em Q4 na faixa de 8--16 GB de VRAM e alerta que peso, overhead e KV cache
precisam caber juntos. A quantização Q4_K_M oficial do Mellum2 tem 8,1 GB; portanto
forçar o modelo inteiro na RTX 3070 deixaria a execução instável. O `num_gpu 20` faz a
troca controlada entre VRAM e RAM.

O Qwen2.5-Coder 7B Q6 é mantido como perfil rápido: a tag oficial mede 6,3 GB e usa
28 blocos, o que permite offload integral na placa com a configuração de contexto
conservadora.

Fontes: [BenchLM — LLMs locais](https://benchlm.ai/best/local-llm),
[BenchLM — Ollama](https://benchlm.ai/best/ollama-models),
[Mellum2 Q4/Q6/Q8](https://ollama.com/JetBrains/mellum2-thinking-q6_k) e
[Qwen2.5-Coder Q6](https://ollama.com/library/qwen2.5-coder%3A7b-instruct-q6_K).

## Início

```sh
cd donatello-ai
cp .env.example .env
# Edite .env e substitua o segredo pelo resultado de: openssl rand -hex 32
docker compose up -d ollama open-webui
docker compose --profile bootstrap run --rm ollama-init
```

Depois abra <http://127.0.0.1:3000> e escolha um dos modelos `francis-bacon-*`.
Para Aider, use o endpoint OpenAI compatível local:

```sh
uv tool run --from aider-chat aider \
  --model ollama/francis-bacon-architect \
  --openai-api-base http://127.0.0.1:11434/v1 \
  --architect
```

## Ajuste fino

Monitore `nvidia-smi` durante a primeira resposta. Se a VRAM ficar no limite ou o
processo cair para CPU, reduza `num_gpu` no `Architect.modelfile` de 20 para 16 e rode
novamente o bootstrap. Se houver folga sustentada, aumente de dois em dois. Não aumente
`num_ctx`, `num_batch` ou a concorrência antes de validar essa margem.
