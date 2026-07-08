---
description: Contrato e arquitetura do sentinel-app (Flutter/Android)
alwaysApply: true
---

# Regra: sentinel-app

Este é o app móvel offline-first do ecossistema Sentinel. Consulte SEMPRE como
fonte da verdade (estão no repo de docs / referenciados):
- `sentinel-api-app.md` — contrato dos endpoints que o app consome. NÃO invente
  campos, rotas ou formatos; o que não estiver aqui, pergunte ou marque pendente.
- `sentinel-scope.md` — arquitetura e UX decididas (capture-first, 3 camadas de
  integridade, fila/máquina de estados, TUS, check-in).
- `sentinel-decisoes.md` — histórico de decisões (transversal; consulte sob demanda).

## Regras de uso
1. App é offline-first: tudo salva localmente primeiro, sincroniza depois. Nunca
   bloquear captura/registro por falta de rede.
2. UUIDs são gerados no cliente; idempotência por id no sync.
3. Respeitar a separação de fases: captura, upload (TUS) e UI não se misturam num
   mesmo PR gigante. A fronteira de rede fica atrás de uma interface (SyncGateway).
4. `reported_by` é carimbado na captura (uid local) e enviado no payload de sync;
   o backend respeita o valor na 1ª gravação (imutável depois). Lista local filtra
   por dono; dados de outro uid permanecem no Drift mas não aparecem na UI.
5. Mudança que afete o contrato de API deve ser sinalizada (impacta o backend).
6. Stack: Flutter, Android, drift (persistência), state management conforme o README.