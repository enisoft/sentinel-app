# Sentinel — Registro de Decisões

Resumo das decisões tomadas durante a revisão de arquitetura e produto.
Formato: o que estava no escopo inicial → o que foi decidido, e por quê.
Para o estado atual da arquitetura, ver `sentinel-scope.md`.

Última atualização: 2026-06-13

---

## 0. A decisão de fundação (produto)

- **Inicial:** vocabulário de operação de inteligência, com objetivo de registrar crimes eleitorais **ou oportunidades**.
- **Decidido:** versão **defensável** — registrar informações para apoiar uma campanha e documentar violações eleitorais **observáveis**, sem vigiar pessoas. Governa permissões, dados coletados e risco legal.

---

## 1. Captura e UX do operador

| Tema | Inicial | Decidido |
|------|---------|----------|
| Forma de captura | Em aberto | **Câmera in-app, capture-first** (estilo stories). Form nunca bloqueia captura. |
| Importar da galeria | — | **Fallback** apenas, tier de menor integridade. |
| Duração de vídeo | 4-6 vídeos de 20-30 min | **Máx. 4-5 min.** Menos dados, melhor sync, menos transeuntes. |
| Mídia padrão | Vídeo assumido | Vídeo é escolha consciente; foto + áudio cobre boa parte. |

---

## 2. Integridade da evidência

| Tema | Inicial | Decidido |
|------|---------|----------|
| Nível de rigor | Implícito "forense" | **Sem rigor forense/jurídico**; foco em confiabilidade. |
| Hash | Ausente | **SHA-256 por arquivo na captura** — detecta upload truncado/corrompido. |
| Original | Re-codificado e descartado | **Preservado no device**; comprimido é cópia derivada. |
| Timestamp | Relógio do device | Carimbo na **captura** + `synced_at` (recebimento) no servidor. |

---

## 3. Upload de mídia

| Tema | Inicial | Decidido |
|------|---------|----------|
| Protocolo | Upload direto | **TUS (resumable)** — obrigatório para vídeo em rede instável. |
| Plano | — | **Supabase Pro**. |
| Tamanho | — | Upload padrão < 6MB; TUS para vídeo. Hostname direto de storage. |
| Bucket | "URL pública" | **Bucket privado**; `path` guarda caminho do objeto; URL assinada para ver. |
| Rede | — | Vídeo **só Wi-Fi** + override manual; foto/áudio em qualquer rede. |

---

## 4. Sync em background ("sincroniza e dorme")

| Tema | Inicial | Decidido |
|------|---------|----------|
| Estratégia | Worker genérico | **Foreground Service** (notificação persistente); não depende do app aberto. |
| Limite Android 15 | Não considerado | dataSync FGS tem limite de 6h/24h → usar **UIDT Jobs** (Android 14+). |
| Agendamento | — | WorkManager com restrição de Wi-Fi (e "carregando" para uso noturno). |

---

## 5. Fila e máquina de estados

| Tema | Inicial | Decidido |
|------|---------|----------|
| Estados | `pending/synced/failed` | `local_saved → media_uploading → media_done → json_syncing → synced` + `failed_phase`, `retry_count`. |
| Timestamps | — | `created_local_at`, `media_uploaded_at`, `synced_at`, `last_attempt_at`, `failed_reason`. |
| Idempotência | UUID cliente + upsert | **Mantido** (acerto do escopo original). |
| Confirmação | `id` ∈ `data.ids` | **Mantido** (padrão correto). |
| Ordenação | Mídia → JSON | **Confirmado**; job de limpeza de órfãos com carência obrigatória. |

---

## 6. Autenticação e identidade

| Tema | Inicial | Decidido |
|------|---------|----------|
| Auth | Sem auth ("Sanctum planejado") | **Supabase Auth desde a partida.** Endpoint sem auth era o pior risco. |
| Mecanismo | Sanctum (própria) | **Supabase Auth** — não reimplementar login/reset/MFA, e **uma identidade autoriza Storage (RLS) e API ao mesmo tempo**. Auth própria reintroduziria descompasso no upload ao bucket privado. |
| Modelo | `users` própria | `auth.users` (Supabase, credencial) **+** `public.users` (perfil de domínio), 1:1 por id. |
| Identidade na API | — | Laravel **valida o JWT do Supabase**; `reported_by`/`user_id` derivados do token, nunca do payload. |

---

## 7. Localização

| Tema | Inicial | Decidido |
|------|---------|----------|
| GPS na ocorrência | `latitude`/`longitude` | **Mantido**, carimbado na captura (primeiro plano). |
| Rastreamento do operador | "localizador e etc" | **Descartado tracking contínuo** (background = revisão dura do Play + LGPD/trabalhista). |
| Presença | — | **Check-in manual** (`check_ins`); só localização em primeiro plano. |

---

## 8. Ambiente, distribuição e hardware

| Tema | Inicial | Decidido |
|------|---------|----------|
| Dev local | Postgres "pelado" | **Stack Supabase via CLI (Docker)** — Postgres `:54322`, Auth, Storage, Studio. Espelha produção; libera RLS de Storage local. |
| `.env` local | `sentinel`/`5432` | Apontado ao Supabase local (`postgres` `:54322`); confirmado funcionando + migrado. |
| Distribuição | Teste interno | Teto de 100 testers — insuficiente para 200. Usar **conta de organização + teste fechado** ou **Managed Google Play** (frota privada). |
| Localização (permissão) | "localizador" | Só **primeiro plano** (evita revisão de background location). |
| Aparelho | Em aberto | Critério = confiabilidade de upload noturno. **Motorola Edge 60 Fusion** (Android limpo, 256GB) recomendado; **Samsung A56 256GB** alternativa. Android **14+** (UIDT); fugir de OEM com task-killer. |

---

## 9. Trabalho concluído (auditado em 2026-06-13)

Correções aplicadas no `sentinel-backend` e **confirmadas por auditoria** (suíte 7/7 verde):

- `created_at`/`updated_at` offline agora **persistem** com o valor do cliente.
- Coluna e comportamento de **`synced_at`** (autoridade do servidor; ignora valor do cliente).
- **Isolamento de testes** no schema `testing` (via `phpunit.xml` + `tests/bootstrap.php`), sem tocar no `public` de dev.
- `location` máx. 255; subseção "Infraestrutura Laravel"; bucket privado / caminho em `path`.
- `STATUS_PROJETO.md` realinhado ao código e ao ambiente Supabase local.

Estado da fundação: **sólido e verdadeiro**. O sync, parte mais difícil, está pronto e testado.

---

## Próximos passos em aberto

1. **Bridge de auth** — `public.users` ↔ `auth.users`; validação de JWT no Laravel; `reported_by` do token. (Maior peça; exige cabeça fresca.)
2. **Catálogo + seeds** no Laravel (observables/categorias/municípios) — pré-requisito de teste do app.
3. Endpoints app-facing restantes: `GET /me`, catálogo (delta sync), `POST /check-ins/sync`, inbox de tasks (ver `sentinel-api-app.md`).
4. Pendências menores da auditoria: alinhar `.env.example`, documentar `path` máx. 2048 e o edge case de `updated_at` derivado.

## Riscos a continuar vigiando

- **LGPD:** coleta de imagem/áudio/localização de terceiros e de operadores — manter minimização, finalidade e transparência.
- **Linha vigilância vs. monitoramento:** o que entra como "observável" e como alvo define se o produto continua defensável.
- **Confiabilidade em campo:** foreground service morto por OEM; fix de GPS ruim; upload de muitos GB. Mitigado pelas decisões acima.
