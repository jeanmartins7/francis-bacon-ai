# Guia para rodar o Donatello AI

Este guia inicia o Ollama e o Open WebUI localmente no Donatello. Os serviços ficam
restritos a `127.0.0.1`; eles não ficam expostos na rede local.

## Pré requisitos

- Docker Engine com Docker Compose v2;
- driver NVIDIA funcionando;
- NVIDIA Container Toolkit configurado para o Docker;
- ao menos 20 GB livres em disco para imagens, pesos e dados do Open WebUI.

Confirme que o host enxerga a placa:

```sh
nvidia-smi
docker compose version
```

## Entrar no worktree

As mudanças desta configuração estão no worktree isolado:

```sh
cd /tmp/francis-bacon-ai-donatello/donatello-ai
```

## Criar o segredo local

O Open WebUI precisa de um segredo persistente. Gere-o uma vez:

```sh
cp .env.example .env
openssl rand -hex 32
```

Abra `.env` e substitua o valor de `WEBUI_SECRET_KEY` pelo resultado do segundo
comando. Não altere esse valor depois de já usar o Open WebUI, pois sessões existentes
podem ser invalidadas.

## Iniciar e baixar os modelos

Suba o servidor do Ollama e a interface web:

```sh
docker compose up -d ollama open-webui
```

Espere o Ollama ficar saudável e crie os modelos locais. O primeiro download pode
demorar e requer conexão com a internet:

```sh
docker compose --profile bootstrap run --rm ollama-init
```

Confira os modelos criados:

```sh
docker compose exec ollama ollama list
```

O resultado deve incluir `francis-bacon-architect` e `francis-bacon-fast`.

## Usar

Abra <http://127.0.0.1:3000>, crie a primeira conta e selecione um modelo:

- `francis-bacon-architect`: Mellum2 Q4 com 20 camadas na RTX 3070 e as demais em
  RAM/CPU. Use para análise de projeto, arquitetura e tarefas mais elaboradas.
- `francis-bacon-fast`: Qwen2.5-Coder 7B Q6 com offload integral para a GPU. Use para
  edição, explicações e iterações curtas.
- `francis-bacon-opencode`: Mellum2 Q4 com 64K de contexto para o agente OpenCode.
  É o perfil mais lento, pois deixa margem de VRAM para o cache do repositório.

Para usar a API OpenAI compatível do Ollama, o endpoint é
`http://127.0.0.1:11434/v1`.

## Usar OpenCode com Ollama

O OpenCode requer pelo menos 64K de contexto para modelos locais. Por isso, use somente
`francis-bacon-opencode` para o agente; os demais perfis foram afinados para chat e
trabalho interativo com 8K de contexto.

Instale o OpenCode e crie um `opencode.jsonc` no repositório que deseja editar. A
configuração aponta diretamente para o Ollama que está no container:

```sh
curl -fsSL https://opencode.ai/install | bash
```

```jsonc
{
  "$schema": "https://opencode.ai/config.json",
  "model": "ollama/francis-bacon-opencode",
  "providers": {
    "ollama": {
      "settings": {
        "baseURL": "http://127.0.0.1:11434/v1"
      }
    }
  }
}
```

Em seguida, execute `opencode` no mesmo diretório. Dentro da interface, use `/models`
para confirmar que `ollama/francis-bacon-opencode` está selecionado.

Se também houver o CLI do Ollama instalado no host, a integração oficial oferece o
atalho abaixo. Ele inicia o OpenCode com configuração temporária e não altera o arquivo
de configuração do usuário:

```sh
ollama launch opencode --model francis-bacon-opencode
```

## Acompanhar memória e logs

Em outro terminal, monitore a GPU enquanto envia a primeira pergunta:

```sh
watch -n 1 nvidia-smi
```

Consulte os logs quando um modelo não carregar ou uma requisição falhar:

```sh
docker compose logs -f ollama
docker compose logs -f open-webui
```

## Ajustar o perfil Architect

O Mellum2 Q4 tem pesos de aproximadamente 8,1 GB, por isso o perfil não tenta ocupá-lo
inteiro nos 8 GB de VRAM. `num_gpu 20` em `Architect.modelfile` mantém parte do modelo
na RAM de 64 GB e reserva VRAM para runtime e contexto.

Se o modelo falhar por falta de VRAM, altere `num_gpu` de `20` para `16`, então recrie
o modelo:

```sh
docker compose --profile bootstrap run --rm ollama-init
```

Se o `nvidia-smi` mostrar folga sustentada durante respostas, aumente o valor de dois em
dois e recrie. Mantenha `num_ctx` em 8192 e `OLLAMA_NUM_PARALLEL` em 1 até validar a
estabilidade.

## Parar ou reiniciar

```sh
docker compose down
docker compose up -d ollama open-webui
```

`docker compose down` preserva os modelos e os dados porque ambos ficam nos diretórios
`ollama/` e `open-webui/`.
