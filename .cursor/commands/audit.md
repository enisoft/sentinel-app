# Audit read-only

Tarefa de AUDITORIA (read-only). NÃO altere código. Verifique o que a última
tarefa afirma ter feito contra o código real e o contrato do projeto.

## Entradas
- Último relatório: `.cursor/docs/last_executed_task.md`
- Contrato/escopo: docs de referência do projeto (api-app, scope, decisoes)

## Verifique
1. Cada item que o relatório diz "feito" existe de fato no código (cite arquivo:linha).
2. Aderência ao contrato: nomes de campos, tipos, estados e formatos batem com
   os docs de referência. Aponte divergências.
3. Escopo: nada além do pedido foi adicionado (sem dependências/recursos extras).
4. Testes: passam, cobrem o comportamento afirmado, e nenhum foi enfraquecido
   (asserção trocada por algo trivial só pra passar).
5. Fronteiras abstratas combinadas (ex.: interfaces sem implementação) seguem assim.

## Saída
Salve em `.cursor/docs/audit_{timestamp}.md`, iniciando com:
- resumo do que foi pedido para verificar
- relatório por critério no formato: ✅ CONFERE / ⚠️ DIVERGENTE / ❌ FANTASMA / 🔍 NÃO DOCUMENTADO (com arquivo:linha)
- veredito de 2 linhas: pronto para ser considerado concluído? ressalvas?