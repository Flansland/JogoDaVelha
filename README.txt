JOGO DA VELHA 2.2.0 — ATUALIZAÇÃO

Alterações:
- Placar de X, O e empates nas partidas.
- Recompensas de moedas e XP ao terminar partidas.
- Nível do jogador baseado em XP.
- Loja com temas de fundo.
- Loja com estilos diferentes para X e O.
- Pacote que desbloqueia fundo + X + O.
- Escolha de quem começa nas partidas CPU, local e ao criar sala online.
- Pedidos de amizade com confirmação/entrega e lista de amizades pelo ID.
- Servidor WebSocket atualizado para o novo sistema.
- Versão 2.2.0.

IMPORTANTE — SERVIDOR:
O arquivo server/server.js precisa ser publicado no serviço Render usado pelo jogo. Se o Render ainda estiver com a versão antiga, os novos recursos online não funcionarão.

IMPORTANTE — AMIZADES:
Os pedidos ficam armazenados em memória no servidor. Se o serviço Render reiniciar, pedidos pendentes que ainda não foram aceitos podem ser perdidos. Para persistência definitiva, será necessário adicionar um banco de dados.

MOEDAS E XP:
Nesta versão ficam salvos no aparelho usando SharedPreferences. As recompensas são aplicadas quando uma partida termina.
