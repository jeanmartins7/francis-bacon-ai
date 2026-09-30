# Donatello AI - Arquitetura de LLM Local com Troca de RAM e GPU

Ambiente local otimizado para o computador **Donatello** (AMD Ryzen 7 5700X, 64GB RAM, NVIDIA RTX 3070 8GB) executando no CachyOS.

---

## 1. Avaliação de Modelos (Base: [BenchLM.ai](https://benchlm.ai/))

De acordo com as métricas do **BenchLM.ai** (focadas em *SWE-bench Verified*, *LiveCodeBench* e *BenchAlign Coding Score*), os modelos foram categorizados para a sua configuração de hardware:

| Modelo | Tamanho (Q4) | Localização no Hardware | Performance (Tokens/s) | BenchLM / SWE-bench | Recomendação de Uso |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Qwen2.5-Coder-14B** *(Recomendado)* | ~9.0 GB | **GPU (5.8 GB) + RAM (3.2 GB)** | **~15 - 22 t/s** | **85.2% HumanEval / 73% LiveCodeBench** | **Melhor Custo-Benefício Geral** para desenvolvimento ativo com Aider. |
| **Qwen2.5-Coder-32B** | ~19.9 GB | **GPU (5.5 GB) + RAM (14.5 GB)** | **~4 - 7 t/s** | **92.7% HumanEval+ / Top SWE-bench** | **Deep Architecture / Refatoração Crítica** no modo `--architect`. |
| **Qwen2.5-Coder-7B** | ~5.5 - 7.0 GB | **100% GPU (VRAM)** | **~50 - 60 t/s** | Adequado para tarefas simples | **Edições rápidas e scripts pontuais**. |
| **Mellum2-12B-A2.5B-Thinking** | ~7.0 GB | **GPU + RAM (MoE)** | **~25 - 35 t/s** | **69.9 LiveCodeBench** | Modelo MoE esparso da JetBrains indicado pelo BenchLM para CPU offload. |

---

## 2. Conceito de Troca de RAM e GPU (Layer Offloading)

### Como funciona no Ollama / llama.cpp:
1. **Divisão por Camadas (Transformer Layers):**
   - Um modelo de 14B possui cerca de 48 camadas. A RTX 3070 possui 8GB de VRAM GDDR6 (~6.5GB livres para inferência).
   - O Ollama aloca as primeiras ~30 camadas na VRAM da RTX 3070 (largura de banda ultra-alta de 448 GB/s).
   - As ~18 camadas restantes são alocadas nos **64GB de memória RAM DDR4** do computador.
2. **Transferência PCIe 4.0 x16:**
   - Durante a inferência, a GPU processa os tensores pesados e envia apenas as ativações intermediárias através do barramento PCIe 4.0 x16 (~31.5 GB/s), gerando latência quase imperceptível na troca.
   - O processador Ryzen 7 5700X processa as camadas restantes na RAM do sistema via instruções AVX2.
3. **Otimizações aplicadas:**
   - `OLLAMA_FLASH_ATTENTION=1`: reduz drasticamente o consumo de memória de contexto e acelera o processamento de prompts longos.
   - `PARAMETER num_thread 8`: configurado exatamente para os 8 núcleos físicos do Ryzen 7 5700X, evitando concorrência excessiva de cache L3 (SMT/hyperthreading thrashing).
   - `PARAMETER num_ctx 16384`: janela de contexto de 16k tokens, permitindo ao Aider mapear repositórios inteiros.

---

## 3. Como Utilizar

### 3.1 Subir os Serviços (Ollama + Open-WebUI)
```bash
cd donatello-ai
docker compose up -d
```
- **Ollama API:** `http://localhost:11434`
- **Open-WebUI (Chat no Navegador):** `http://localhost:3000`

### 3.2 Compilar os Modelos Customizados
Utilize o script automatizado:
```bash
# Compilar o modelo principal (14B Sweet Spot - Recomendado):
./donatello-ai/build-models.sh 14b

# Opcional: Compilar a versão Deep Architect (32B):
./donatello-ai/build-models.sh 32b

# Opcional: Compilar a versão Ultra-Fast (7B 100% GPU):
./donatello-ai/build-models.sh 7b

# Listar modelos instalados:
./donatello-ai/build-models.sh list
```

### 3.3 Executar o Aider com o Agente Francis Bacon
Na raiz do projeto:
```bash
# Executa com o modelo padrão de melhor custo-benefício (14B):
./fb-architect

# Ou selecionar variantes sob demanda:
./fb-architect --32b    # Para tarefas complexas de arquitetura
./fb-architect --7b     # Para edições rápidas
```
