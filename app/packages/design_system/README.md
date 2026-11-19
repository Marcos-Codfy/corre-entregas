# corre_design_system

Design system do Corre em Flutter: tokens (cores, tipografia, espaçamentos, raios, sombras), tema claro e escuro e os componentes usados no app do motoboy, no painel web e no catálogo `ds_sample`.

## Como usar

```dart
import 'package:corre_design_system/corre_design_system.dart';

MaterialApp(
  theme: CorreTheme.light(),
  darkTheme: CorreTheme.dark(),
  home: Scaffold(
    body: CorreButton(label: 'Pedir entregador', onPressed: () {}),
  ),
);
```

Cores do tema: `context.palette.brand`, `context.palette.ink2` etc. Estilos de texto: `context.text.titleMedium`.
Status (sucesso, aviso, erro, informação) usam `CorreTone`, que define a cor do texto e do fundo.

## Organização

| Pasta | Conteúdo |
|---|---|
| `lib/src/tokens` | Valores base: `CorreRawColors`, `CorrePalette`, `CorreSpace`, `CorreRadius`, `CorreShadow`, `CorreDuration`, `CorreTypography` |
| `lib/src/theme` | `CorreTheme.light/dark` e a extensão `context.palette` |
| `lib/src/components` | Botões, campos, seleção, exibição, feedback, componentes de entrega e layout |

## Como adicionar um componente

1. Crie o widget em `lib/src/components`, usando só tokens e `context.palette` (nada de cor ou número solto).
2. Exporte em `lib/corre_design_system.dart`.
3. Mostre o componente no catálogo (`apps/ds_sample/lib/sections`), com os estados que ele tiver.
4. Escreva um teste em `test/` cobrindo o comportamento, inclusive os casos de erro.

## Testes

```bash
flutter test
```
