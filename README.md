# Jogo Da Velha — atualização

Atualização do projeto com:

- CPU com 3 dificuldades:
  - 🟢 Iniciante
  - 🟠 Amador
  - 🔴 Pro Player
- Identidade dos jogadores por ID aleatório permanente (JDV-XXXXXXXX).
- O ID é gerado uma vez e salvo no aparelho; não há campo para trocar nome.
- Amigos são adicionados usando o ID.
- Amigos Online / Offline.
- Multiplayer usando o servidor configurado internamente, sem mostrar URL WebSocket na interface.
- Correção do fluxo do WebSocket usando stream broadcast para evitar o erro de stream já escutada.
- Pontuação online sincronizada com o servidor.
- Rodapé: Feito por Rhuan Gabriel.

Servidor Render usado pelo app: `jogodavelha-6neh.onrender.com`.

## Atualizar o Render

Substitua o `server/server.js` pelo arquivo desta pasta e faça novo deploy no Render.

## Comandos no projeto Flutter

```bat
cd /d C:\Projetos\JogoDaVelha
flutter pub get
flutter build windows --release
flutter build apk --release
```
