# Plano — Onda 1: front-end completo sem integrações

> **Protocolo de retomada (ler primeiro).** Este arquivo é a fonte da verdade da Onda 1.
> - A cada passo concluído: marcar `[x]`, anotar no "Diário" no fim e fazer commit local (Conventional Commits, em inglês, sem assinatura de IA). Sem push sem validação do Marcos.
> - Ao retomar (nova sessão, contexto compactado, limite estourado, "continue", "código 0"): ler este arquivo, rodar `git log --oneline -5` e `git status`, e continuar no primeiro `[ ]`. Não refazer nada que já está `[x]`.
> - Se um passo ficar pela metade, o commit "wip:" e a nota no Diário dizem onde parou.
> - Só parar para perguntar se houver bloqueio real (falta de acesso, decisão de negócio). Todo o resto: decidir e seguir.
> - Economia: não reler documentos inteiros; consultar só a seção necessária dos estudos (docs/03-produto.md, docs/04-requisitos.md).

## GitHub e commits
- Repositório **público** na conta Marcos-Codfy, para portfólio (autorizado pelo Marcos em 2026-11-19). Criar no A0 com `gh` e dar push ao fim de cada parte (A, B, C) e no F1.
- Commits: Conventional Commits, atômicos (um assunto por commit), mensagens em inglês, **sem Co-Authored-By nem qualquer assinatura de IA**. Branch sem "claude" no nome.
- Código e nomes em inglês; comentários, README e textos de tela em português.
- README de portfólio seguindo as regras do CLAUDE.md global (tom simples, termos de mercado, sem números que envelhecem, dizer que foi feito com especificação própria e IA como assistente). Prints/GIF do ds_sample, app e painel + links ao vivo.
- Nunca commitar keystore, .env, chaves ou dados pessoais. Conferir antes de cada push.

## Escopo
- **Onda 1 (agora):** design system + app do motoboy (APK Android) + painel web (comércio e admin/suporte). Tudo funciona com **dados simulados**, sem backend, sem login real, sem pagamento. Mapa real (OpenStreetMap, grátis e sem chave).
- **Onda 2 (depois):** Supabase (auth, banco, realtime), Asaas (Pix), Google Places, push, despacho real entre aparelhos.
- **Simulação:** cada app tem um "modo demonstração" com perfis prontos (Marcos e o sócio podem entrar como motoboy, comércio, suporte ou admin, sem cadastro). Um simulador local gera os eventos do outro lado (comércio pedindo, motoboy andando no mapa, aceite, entrega). Como não há backend, o celular e o painel **não conversam entre si** na Onda 1; isso é a Onda 2.

## Decisões técnicas
| Tema | Escolha |
|---|---|
| Framework | Flutter (stable), Dart 3 |
| Monorepo | Dart pub workspaces (pasta `app/`) |
| Arquitetura | Clean Architecture por feature: `domain` (entidades, regras, contratos de repositório) → `data` (repositórios fake/in-memory) → `presentation` (MVVM com Riverpod) |
| Estado / DI | Riverpod (providers trocáveis: fake na Onda 1, Supabase na Onda 2) |
| Rotas | go_router |
| Modelos | classes imutáveis escritas à mão (sem codegen, build mais simples) |
| Mapa | flutter_map + tiles OSM; rotas simuladas por interpolação |
| Persistência local | shared_preferences (perfil, preferências, histórico demo) |
| Testes | unit (preço, máquina de estados, despacho), widget (componentes do DS), golden opcional |
| Hospedagem | Cloudflare Workers com assets estáticos (`wrangler deploy`, arquivo wrangler.jsonc em cada app web) |
| APK | `flutter build apk --release` com keystore próprio fora do repositório |

## Estrutura
```
app/
  pubspec.yaml               # workspace
  packages/
    design_system/           # tokens, tema, componentes, ícones
    core/                    # domínio compartilhado: entidades, regras de preço, estados, despacho, fakes, simulador
  apps/
    ds_sample/               # catálogo vivo do design system (web)
    courier/                 # app do motoboy (Android)
    panel/                   # painel web: comércio + suporte/admin
```

---

## Parte A — Design system + sample
- [x] A0. Ambiente: conferir Flutter, Android SDK, Java, `flutter doctor`; instalar o que faltar. `git init` na raiz com .gitignore.
- [x] A1. Criar workspace `app/` e pacotes vazios (design_system, core, ds_sample, courier, panel), lints (`very_good_analysis` ou `flutter_lints` estrito).
- [x] A2. Tokens: cores (marca, neutros, sucesso/aviso/erro/info, status de entrega), tipografia (Google Fonts embarcada), espaçamentos, raios, sombras, durações. Claro e escuro. Base: prototipo/design-system.html.
- [x] A3. `ThemeData` claro/escuro gerado dos tokens + extensões de tema (cores de status).
- [x] A4. Componentes base: botões (primário, secundário, fantasma, perigo, carregando), campos (texto, senha, telefone, moeda, busca), seleção (chip, switch, radio, checkbox, dropdown), cards, badges de status, avatar, lista, divisores.
- [x] A5. Componentes de feedback: snackbar/toast, diálogo de confirmação, bottom sheet, estado vazio, erro, skeleton, indicador de progresso.
- [x] A6. Componentes do domínio: card de oferta com contagem regressiva, linha do tempo de etapas, entrada de código de 4 dígitos, resumo de preço, card de entrega, marcador de moto/coleta/entrega para mapa, KPI tile, tabela de dados (painel).
- [x] A7. Layout: scaffold mobile com navegação inferior, shell web com menu lateral responsivo, breakpoints.
- [x] A8. App ds_sample: catálogo navegável de todos os tokens e componentes, alternância claro/escuro, estados (normal, desabilitado, erro, carregando).
- [x] A9. Testes de widget dos componentes principais; README do design_system (como usar, como adicionar componente).
- [x] A10. Publicar ds_sample (Cloudflare Pages) e atualizar o site do estudo com o link.

## Parte B — App do motoboy (Android)
- [x] B1. core/domínio: entidades (Courier, Merchant, Delivery, Address, Offer, Wallet, Payout, Rating, Event), enums de estado, máquina de estados da entrega (03-produto), regra de preço (R$ 8 até 5 km + R$ 1,50/km arredondando 0,5 km; adicionais), regra de cancelamento (R$ 3 após 1 km), elegibilidade (nota ≥ 4,0).
- [x] B2. core: contratos de repositório + implementações fake com seed realista de Palmas (comércios, endereços por quadra, motoboys, histórico) e registro de eventos.
- [x] B3. core: simulador (gera ofertas, cascata de 20 s, raios 5/7/10 km, preferidos primeiro, movimento GPS interpolado a cada 7 s acelerado, cliente ausente, ocorrência).
- [x] B4. Testes unitários: preço, estados (transições válidas e inválidas), despacho, cancelamento.
- [x] B5. App courier: estrutura, rotas, tema, modo demonstração (escolher perfil, sem cadastro).
- [x] B6. Telas de entrada: splash, login (e-mail/Google simulados), cadastro com envio de documentos (CNH A definitiva com EAR, CRLV, selfie, Pix) e status de aprovação.
- [x] B7. Início: online/offline, ganhos do dia, mapa com posição, pico de hoje, comércios que preferem você.
- [x] B8. Oferta: card com contagem de 20 s, aceitar/recusar (sem penalidade), som/vibração.
- [x] B9. Corrida: etapas (indo ao comércio → no comércio → coletado → indo ao cliente → no cliente), mapa, abrir Maps/Waze, ligar, relatar problema.
- [x] B10. Prova de entrega por código de 4 dígitos; cliente sem código (ligar ao comércio); cliente ausente (espera 10 min, retorno +50%).
- [x] B11. Carteira (saldo, extrato, saque Pix simulado), histórico de corridas, nota e regras, perfil (moto: só modelo), ajuda/suporte, termos.
- [x] B12. Estados de erro, sem GPS, sem internet (fila offline simulada), permissões.
- [x] B13. Ícone, splash nativa, nome do app, keystore, `flutter build apk --release`; testar no emulador; copiar APK para `entregas/`.

## Parte C — Painel web (comércio + suporte/admin)
- [x] C1. App panel: shell responsivo, rotas por papel (merchant_owner, merchant_staff, support, admin), modo demonstração com troca de perfil.
- [x] C2. Comércio: início (saldo, entregas em andamento, preferidos), nova entrega (endereço com busca simulada + pino no mapa, cálculo de frete, total), acompanhamento no mapa, enviar link + código pelo WhatsApp (link wa.me real), cancelar.
- [x] C3. Comércio: histórico com filtros e exportar CSV, carteira e recarga Pix (QR simulado), plano (Avulso atual; Parceiro "em breve"), cupons, motoboys preferidos (até 3), equipe, configurações do comércio.
- [x] C4. Página pública de rastreio do cliente (`/r/:token`): mapa, etapa, código.
- [x] C5. Suporte: fila sem aceite, mapa de motoboys online, despacho manual, ocorrências críticas com roteiro passo a passo, aprovação de cadastros, chat/WhatsApp com as partes.
- [x] C6. Admin: dashboard de KPIs (aceite, tempos, cancelamentos, entregas por comércio, ganho/hora), preços e adicionais, cupons (criar a qualquer momento), repasses, comércios, motoboys, eventos (log), configurações.
- [x] C7. Testes de widget das telas críticas; responsividade (celular, tablet, desktop).
- [x] C8. `flutter build web --release`, deploy no Cloudflare Pages, conferir no navegador; atualizar site do estudo com links.

## Entrega final da Onda 1
- [x] F1. APK em `entregas/app-motoboy.apk` + link do painel + link do design system.
- [x] F2. Atualizar documentação (site), PROGRESS.md e nota no Obsidian.

## Diário
- 2026-11-19: plano criado. Aguardando "comece".
- 2026-11-19: A0–A7 feitos (workspace, tokens, tema claro/escuro, componentes). Próximo: A8 ds_sample.
- 2026-11-19: Parte A concluída. Catálogo: https://corre-design-system.vinicius-codfy.workers.dev . Repo: https://github.com/Marcos-Codfy/corre-entregas . Link no site do estudo fica para o F2. Próximo: B1.
- 2026-11-19: B1–B4 feitos (core: domínio, repositórios em memória, DeliveryService, Simulator, DemoEnvironment, 50 testes). Próximo: B5 app courier.
- 2026-11-19: B5–B12 feitos (app courier completo, 6 testes). Pacote novo packages/shared (providers, apresentação, links). B13 em andamento: keystore em C:/Users/Marcos/.corre-keys (senha em android/key.properties, fora do git). Sem AVD na máquina: conferir visual pela versão web do courier.
- 2026-11-19: Parte C concluída (painel: 12 testes). Deploys: painel https://corre-painel.vinicius-codfy.workers.dev , motoboy web https://corre-motoboy.vinicius-codfy.workers.dev , DS https://corre-design-system.vinicius-codfy.workers.dev . Admin pode editar preços (core). Próximo: B13 APK final (split arm64 + universal em entregas/), F1 README com prints, F2 docs/site/Obsidian, push.
- 2026-11-19: Onda 1 concluída. APKs em entregas/, README com prints, Obsidian atualizado, push feito. Pendente só republicar o site do estudo na Vercel (aguarda validação).
