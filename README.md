# Jogo Da Velha 2.0

Aplicativo Flutter para celular com visual inspirado nas referências fornecidas.

## Modos
- Jogar com CPU: IA minimax para o jogo clássico.
- Multijogador > Jogar com Amigo: dois jogadores no mesmo celular.
- Multijogador > Código do Jogo: cria/entra em sala online por código.
- Multijogador > Encontrar um Amigo: fila automática no servidor online.

## Multiplayer online
O app usa WebSocket. O endereço do servidor pode ser alterado na tela de multiplayer.

Servidor incluído em `server/`:

```bash
cd server
npm install
npm start
```

Por padrão ele escuta em `ws://0.0.0.0:8080`.

No celular, não use `ws://10.0.2.2:8080` a menos que esteja usando um emulador Android. Em um celular físico, coloque o IP local do PC, por exemplo `ws://192.168.0.50:8080`, ou use um endereço público `wss://...` quando hospedar o servidor.

## Logo / ícone
A logo enviada pelo usuário está em `assets/logo.png`. O arquivo `android_patch/AndroidManifest.xml.patch.txt` explica como aplicar a mesma imagem como ícone do Android no projeto Flutter já criado.

## Android
Abra a pasta do projeto e execute:

```bash
flutter pub get
flutter build apk --release
```

O APK sai em `build/app/outputs/flutter-apk/app-release.apk`.
