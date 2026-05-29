# Treino de Guitarra — Áudio e Aba Teclado

**Data:** 2026-05-29  
**Status:** Aprovado

## Contexto

O app é um único arquivo `index.html` com HTML/CSS/JS vanilla. Não tem build tool nem dependências externas. As mudanças são adicionadas diretamente no arquivo.

## Escopo

1. Remover aba "CAGED: Tocar"
2. Adicionar engine de áudio com amostras reais de piano (Tone.js + Salamander)
3. Tocar som das notas ao clicar em botões e casas do braço
4. Tocar acorde ao acertar o quiz de Tríades
5. Nova aba "Teclado" — piano interativo de 4 oitavas + extensões opcionais

---

## 1. Remoção da aba CAGED: Tocar

Remover do HTML:
- Botão `<button class="tab-btn" data-tab="caged-play">CAGED: Tocar</button>`
- Painel `<div class="panel" data-panel="caged-play">...</div>` (incluindo todo o conteúdo interno)
- Bloco IIFE `(function() { ... })()` que gerencia a lógica de `caged-play` no `<script>`

Nenhuma outra parte do código referencia esse painel.

---

## 2. Engine de Áudio

### Dependência

```html
<script src="https://cdnjs.cloudflare.com/ajax/libs/tone/14.7.77/Tone.js"
        integrity="sha384-HASH_A_CALCULAR"
        crossorigin="anonymous"></script>
```

Adicionado no `<head>`, antes do `</head>`.

> **Nota de segurança:** O hash SRI (`integrity`) deve ser calculado durante a implementação com `openssl dgst -sha384 -binary Tone.js | openssl base64 -A` após baixar o arquivo, ou obtido via [srihash.org](https://www.srihash.org/). Não usar hash placeholder em produção.

### Objeto `Audio`

Objeto global único declarado no `<script>` principal:

```js
const Audio = {
  sampler: null,
  ready: false,

  async init() {
    if (this.ready) return;
    await Tone.start();
    this.sampler = new Tone.Sampler({
      urls: {
        A0: 'A0.mp3', C1: 'C1.mp3', 'D#1': 'Ds1.mp3', 'F#1': 'Fs1.mp3',
        A1: 'A1.mp3', C2: 'C2.mp3', 'D#2': 'Ds2.mp3', 'F#2': 'Fs2.mp3',
        A2: 'A2.mp3', C3: 'C3.mp3', 'D#3': 'Ds3.mp3', 'F#3': 'Fs3.mp3',
        A3: 'A3.mp3', C4: 'C4.mp3', 'D#4': 'Ds4.mp3', 'F#4': 'Fs4.mp3',
        A4: 'A4.mp3', C5: 'C5.mp3', 'D#5': 'Ds5.mp3', 'F#5': 'Fs5.mp3',
        A5: 'A5.mp3', C6: 'C6.mp3', 'D#6': 'Ds6.mp3', 'F#6': 'Fs6.mp3',
        A6: 'A6.mp3', C7: 'C7.mp3', 'D#7': 'Ds7.mp3', 'F#7': 'Fs7.mp3',
        A7: 'A7.mp3', C8: 'C8.mp3',
      },
      baseUrl: 'https://tonejs.github.io/audio/salamander/',
      onload: () => { this.ready = true; }
    }).toDestination();
  },

  playNote(note, octave = 4) {
    if (!this.sampler) return;
    this.sampler.triggerAttackRelease(note + octave, '8n');
  },

  playChord(notes, octave = 4) {
    if (!this.sampler) return;
    notes.forEach(n => this.sampler.triggerAttackRelease(n + octave, '2n'));
  }
};
```

### Inicialização lazy

`Audio.init()` é chamado uma única vez no primeiro evento de interação do usuário (qualquer clique na página). Após isso, `Audio.ready` indica se os samples carregaram.

```js
document.addEventListener('click', () => Audio.init(), { once: true });
```

---

## 3. Sons nos Quizzes Existentes

### 3.1 Quiz de Tríades

**Botões de nota** — ao clicar em qualquer `.note-btn`, antes da lógica de seleção:
```js
Audio.playNote(n, 4);
```

**Acerto** — dentro da função `check()`, quando `ok === true`:
```js
Audio.playChord(cur.notes, 4);
```

### 3.2 Quiz Notas no Braço

**Botões de nota** — ao clicar em qualquer `.note-btn` no painel `notes`:
```js
Audio.playNote(n, cur.sIdx <= 1 ? 4 : 3); // oitava aproximada pela corda
```

Simplificação aceitável: todas as notas tocam na oitava 4.

### 3.3 Casas do Braço (fret-spot)

O `renderFB` já tem callback `onClick`. Nos painéis onde o fretboard é clicável (`find` e `caged-id`), adicionar ao início do callback:
```js
Audio.playNote(pos.note, 4);
```

---

## 4. Aba Teclado

### 4.1 Estrutura da Aba

Nova aba inserida após "CAGED: Forma":

```html
<button class="tab-btn" data-tab="keyboard">Teclado</button>
```

Painel correspondente:
```html
<div class="panel" data-panel="keyboard">
  <!-- toggles -->
  <!-- container do teclado -->
</div>
```

### 4.2 Toggles de Extensão

```html
<div class="settings">
  <div class="settings-row">
    <span class="settings-label">Extensões opcionais:</span>
    <div class="toggle" id="kb-oct5">+Oitava 5</div>
    <div class="toggle" id="kb-oct6">+Oitava 6</div>
  </div>
</div>
```

Clicar em um toggle chama `renderKeyboard()` que reconstrói o teclado com o range atualizado.

### 4.3 Range do Teclado

- **Base fixa:** oitavas 1–4 (C1 a B4 = 28 teclas brancas, 20 teclas pretas)
- **+Oitava 5:** estende para C5–B5 (+7 brancas, +5 pretas)
- **+Oitava 6:** estende para C6–B6 (+7 brancas, +5 pretas)
- **Máximo:** oitavas 1–6 (C1 a B6 = 42 brancas, 30 pretas)

### 4.4 Renderização

Função `renderKeyboard(opts)` que gera o HTML do piano dinamicamente:

```js
function renderKeyboard({ container, fromOct, toOct }) { ... }
```

- Gera teclas brancas como elementos `<div class="kb-white">` com `data-note` e `data-octave`
- Gera teclas pretas posicionadas absolutamente sobre as brancas
- Cada tecla exibe o nome completo: `C4`, `F#3`, etc.
- Teclas brancas: largura 44px, altura 120px
- Teclas pretas: largura 28px, altura 74px, sobrepostas

### 4.5 Interação

Eventos adicionados em cada tecla:
- `mousedown` → `handleKeyPress(note, octave, element)`
- `mouseup` / `mouseleave` → `handleKeyRelease(element)`
- `touchstart` (com `preventDefault()`) → `handleKeyPress`
- `touchend` → `handleKeyRelease`

```js
function handleKeyPress(note, octave, el) {
  el.classList.add('on');
  Audio.playNote(note, octave);
}
function handleKeyRelease(el) {
  el.classList.remove('on');
}
```

Estado visual `.on`: teclas brancas ficam amarelas (`#ffd84a`), teclas pretas ficam douradas (`#c49b00`).

### 4.6 CSS das Teclas

```css
.kb-white {
  position: absolute;
  background: white;
  border: 1.5px solid #ccc;
  border-radius: 0 0 5px 5px;
  display: flex; align-items: flex-end; justify-content: center;
  padding-bottom: 5px;
  font-size: 9px; font-weight: 700; color: #555;
  cursor: pointer;
  user-select: none;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}
.kb-white.on { background: #ffd84a; border-color: #e6b800; }
.kb-black {
  position: absolute;
  background: #1a1a1a;
  border-radius: 0 0 3px 3px;
  display: flex; align-items: flex-end; justify-content: center;
  padding-bottom: 3px;
  font-size: 7px; color: #aaa;
  cursor: pointer; z-index: 2;
  user-select: none;
}
.kb-black.on { background: #c49b00; color: white; }
```

O container do teclado usa `overflow-x: auto` para scroll horizontal em telas menores.

---

## 5. Estrutura Final das Abas

| # | data-tab | Exibição |
|---|----------|----------|
| 1 | triads | Tríades |
| 2 | notes | Notas no Braço |
| 3 | find | Encontrar Nota |
| 4 | caged-id | CAGED: Forma |
| 5 | keyboard | Teclado ← novo |

---

## Fora do Escopo

- Sons no quiz "Encontrar Nota" ao verificar resposta (só toca ao clicar nas casas)
- Teclado de computador (keyboard shortcuts para tocar o piano)
- Persistência de notas tocadas / histórico
- Indicador visual de loading dos samples Salamander
