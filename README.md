<div align="center">

# 🎥 Mars 5 Ultra Camera

### Abra a câmera da **Elegoo Mars 5 Ultra** no Windows com um único arquivo `.bat`

[![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows&logoColor=white)](https://www.microsoft.com/windows)
[![Batch](https://img.shields.io/badge/Script-Windows%20Batch-4D4D4D?logo=windows-terminal&logoColor=white)](Mars5Ultra-Camera.bat)
[![FFmpeg](https://img.shields.io/badge/Player-FFplay-007808?logo=ffmpeg&logoColor=white)](https://ffmpeg.org/)
[![RTSP](https://img.shields.io/badge/Stream-RTSP%20%2F%20UDP-orange)](#como-funciona)

**Sem CHITUBOX aberto para assistir à câmera. Sem configuração manual do FFplay.**

</div>

---

## ⚠️ Antes de usar: altere o IP da sua impressora

O arquivo vem configurado com este IP de exemplo:

```bat
set "IP=192.168.31.190"
```

Você **precisa trocar esse valor pelo IP da sua própria Mars 5 Ultra**.

1. Clique com o botão direito em `Mars5Ultra-Camera.bat`.
2. Escolha **Editar** ou **Abrir com > Bloco de Notas**.
3. Localize:

```bat
set "IP=192.168.31.190"
```

4. Substitua `192.168.31.190` pelo IP da sua impressora.
5. Salve o arquivo.
6. Dê dois cliques no `.bat`.

> Se o roteador entregar um novo IP para a impressora no futuro, será necessário atualizar essa linha novamente.

---

## ✨ O que este projeto faz

O `Mars5Ultra-Camera.bat` automatiza todo o processo necessário para abrir o stream RTSP da câmera da Mars 5 Ultra no Windows.

Ao executar o arquivo, ele passa por **4 etapas**:

| Etapa | O que acontece |
|---|---|
| **1. Proteção contra sessões duplicadas** | Verifica se já existe algum `ffplay.exe` em execução. Se existir, o script para e **não abre uma segunda sessão**. |
| **2. Preparação do FFplay** | Procura o FFplay instalado. Se não encontrar, tenta instalá-lo automaticamente usando o **WinGet** e o pacote `Gyan.FFmpeg.Essentials`. |
| **3. Teste da impressora** | Usa PowerShell para tentar uma conexão TCP rápida com o IP configurado na porta `554`, com timeout de aproximadamente 2,5 segundos. |
| **4. Abertura da câmera** | Abre o stream `rtsp://IP:554/video` no FFplay usando transporte **RTSP sobre UDP**. |

---

## ▶️ Uso rápido

Depois de configurar o IP, basta executar:

```text
Mars5Ultra-Camera.bat
```

Não é necessário abrir PowerShell ou Prompt de Comando manualmente.

O próprio arquivo cuida do restante.

---

## 🔍 Como funciona

O endereço do stream é montado automaticamente a partir destas variáveis:

```bat
set "IP=192.168.31.190"
set "PORTA=554"
set "STREAM=rtsp://%IP%:%PORTA%/video"
```

Na prática, com o IP de exemplo, o endereço final fica:

```text
rtsp://192.168.31.190:554/video
```

A câmera é aberta com uma chamada equivalente a:

```bat
ffplay -hide_banner -loglevel fatal -rtsp_transport udp "rtsp://192.168.31.190:554/video"
```

### Por que UDP?

Este projeto usa o modo que foi testado com a Mars 5 Ultra deste projeto:

```text
RTSP → UDP → /video
```

O teste anterior da porta `554` usa **TCP apenas para verificar rapidamente se o dispositivo está acessível**. O vídeo em si continua sendo aberto pelo FFplay usando `-rtsp_transport udp`.

---

## 🛡️ Proteção contra sessões presas

O script foi feito para **não encerrar o FFplay à força**.

Antes de abrir a câmera, ele executa:

```bat
tasklist /FI "IMAGENAME eq ffplay.exe"
```

Se encontrar um FFplay em execução, ele mostra um aviso e não abre outra cópia.

Isso é intencional.

O arquivo também **não usa `taskkill`**. Para encerrar a câmera corretamente, faça uma destas duas coisas:

- feche normalmente a janela do FFplay;
- pressione `Q` enquanto a janela do FFplay estiver ativa.

Isso permite que a sessão de vídeo seja encerrada normalmente em vez de matar o processo à força.

---

## 📦 Instalação automática do FFplay

O projeto tenta localizar o FFplay nesta ordem:

1. caminho conhecido de uma instalação do `Gyan.FFmpeg.Essentials` via WinGet;
2. `ffplay.exe` disponível no `PATH` do Windows;
3. pasta do pacote `Gyan.FFmpeg.Essentials` dentro do WinGet;
4. se ainda não existir, instalação automática com:

```bat
winget install --id Gyan.FFmpeg.Essentials -e --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
```

Depois da instalação, o script procura novamente o executável antes de continuar.

### Requisito para a instalação automática

O Windows precisa ter o **WinGet** disponível.

Se o FFplay já estiver instalado e puder ser localizado pelo script, o WinGet não é utilizado.

---

## 🌐 Requisitos

- Windows 10 ou Windows 11
- Elegoo Mars 5 Ultra conectada à rede
- computador e impressora acessíveis na mesma rede local
- IP correto da impressora configurado no `.bat`
- porta RTSP `554` acessível
- WinGet somente caso o FFplay ainda precise ser instalado

---

## 🧭 Fluxo completo

```text
Abrir Mars5Ultra-Camera.bat
          │
          ▼
Existe ffplay.exe aberto?
     │             │
    SIM           NÃO
     │             │
     ▼             ▼
Não abre      Localiza FFplay
outra sessão       │
                   ▼
             Encontrou?
              │       │
             SIM     NÃO
              │       │
              │       ▼
              │   Instala via WinGet
              │       │
              └───┬───┘
                  ▼
        Testa IP + porta 554
                  │
            ┌─────┴─────┐
            │           │
           OK          ERRO
            │           │
            ▼           ▼
     Abre RTSP/UDP   Não abre stream
            │
            ▼
    FFplay mostra a câmera
```

---

## 🧰 Solução de problemas

### `Não consegui acessar a camera em IP:554`

Confira primeiro o IP configurado no início do arquivo:

```bat
set "IP=SEU_IP_AQUI"
```

Também verifique se a impressora está ligada e acessível pela rede.

### `Já existe uma sessão de video aberta`

O script detectou um `ffplay.exe` em execução e, por segurança, não abriu outro.

Feche normalmente a janela existente e execute novamente.

### `O instalador WinGet não foi encontrado`

O FFplay não foi encontrado e o Windows também não disponibilizou o `winget.exe` para instalação automática.

Nesse caso, instale/ative o WinGet ou instale o FFmpeg/FFplay manualmente.

### A janela abre, mas a imagem demora

O FFplay pode levar alguns segundos até receber quadros suficientes do stream para exibir a imagem.

---

## 📄 Arquivo do projeto

```text
mars5-camera/
├── Mars5Ultra-Camera.bat
└── README.md
```

A proposta é manter o projeto propositalmente simples: **um único executável de script para o usuário final**.

---

## ⚠️ Observações

- O script é específico para **Windows**.
- O endereço utilizado é `/video` na porta `554`.
- O IP não é descoberto automaticamente; ele precisa estar configurado no arquivo.
- A detecção de sessão existente considera qualquer processo chamado `ffplay.exe` no computador, mesmo que ele esteja sendo usado para outro vídeo.
- Este projeto não é oficial e não possui vínculo com a Elegoo ou com o projeto FFmpeg.

---

<div align="center">

### 🖨️ Mars 5 Ultra + RTSP + FFplay

Um arquivo. Dois cliques. Câmera aberta.

</div>
