PAINEL DO DONO / ADMIN

O Flutter nao possui o comando nativo "flutter build admin-windows".
Use os scripts desta pasta:
- Admin\Windows\build_admin_windows.bat
- Admin\Android\build_admin_android.bat

Eles geram o painel separado usando lib/admin_main.dart.

Configure no Render:
ADMIN_EMAIL=rhuanprodutor3@gmail.com
ADMIN_PASSWORD=UMA_SENHA_FORTE
ADMIN_TOKEN=UM_TOKEN_SECRETO_LONGO
DATA_DIR=/var/data

Para manter moedas, XP, usuarios, codigos, temas e pacotes depois de reinicios/deploys, o servidor precisa de armazenamento persistente. No Render, armazenamento persistente em disco exige servico pago; sem isso, o filesystem e efemero.
