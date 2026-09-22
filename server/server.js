const WebSocket = require('ws');
const crypto = require('crypto');

const PORT = Number(process.env.PORT || 8080);
const HOST = process.env.HOST || '0.0.0.0';

const wss = new WebSocket.Server({ port: PORT, host: HOST });

const rooms = new Map();
const queue = [];

const emptyBoard = () => Array(9).fill('');

function code() {
  return crypto.randomBytes(2).toString('hex').toUpperCase();
}

function send(ws, data) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify(data));
  }
}

function state(room) {
  return {
    type: 'state',
    board: room.board,
    turn: room.turn,
    status: room.status,
    xWins: room.xWins,
    oWins: room.oWins,
    draws: room.draws,
  };
}

function winner(board) {
  const lines = [
    [0, 1, 2],
    [3, 4, 5],
    [6, 7, 8],
    [0, 3, 6],
    [1, 4, 7],
    [2, 5, 8],
    [0, 4, 8],
    [2, 4, 6],
  ];

  for (const [a, b, c] of lines) {
    if (board[a] && board[a] === board[b] && board[a] === board[c]) {
      return board[a];
    }
  }

  return null;
}

function broadcast(room) {
  room.players.forEach((player) => {
    const opponent = room.players.find((other) => other.ws !== player.ws);

    send(player.ws, {
      ...state(room),
      opponent: opponent ? opponent.name : 'Aguardando',
    });
  });
}

function reset(room) {
  room.board = emptyBoard();
  room.turn = 'X';
  room.status = '';
}

function pair(room) {
  if (room.players.length !== 2) return;

  room.players[0].symbol = 'X';
  room.players[1].symbol = 'O';

  room.players.forEach((player) => {
    send(player.ws, {
      type: 'matched',
      code: room.code,
      symbol: player.symbol,
      opponent: room.players.find((other) => other.ws !== player.ws)?.name || 'Jogador',
    });
  });

  broadcast(room);
}

function newRoom() {
  let roomCode;
  do {
    roomCode = code();
  } while (rooms.has(roomCode));

  const room = {
    code: roomCode,
    players: [],
    board: emptyBoard(),
    turn: 'X',
    status: '',
    xWins: 0,
    oWins: 0,
    draws: 0,
  };

  rooms.set(roomCode, room);
  return room;
}

function removeFromQueue(ws) {
  for (let i = queue.length - 1; i >= 0; i--) {
    if (queue[i].ws === ws) {
      queue.splice(i, 1);
    }
  }
}

function findWaitingRoom() {
  for (const room of rooms.values()) {
    if (room.players.length === 1) {
      return room;
    }
  }
  return null;
}

wss.on('connection', (ws) => {
  ws.on('message', (raw) => {
    let message;

    try {
      message = JSON.parse(raw.toString());
    } catch {
      return;
    }

    const playerName =
      typeof message.name === 'string' && message.name.trim()
        ? message.name.trim().slice(0, 20)
        : 'Player';

    if (message.type === 'create') {
      removeFromQueue(ws);

      const room = newRoom();

      room.players.push({
        ws,
        name: playerName,
        symbol: 'X',
      });

      ws.room = room;

      send(ws, {
        type: 'waiting',
        code: room.code,
      });

      return;
    }

    if (message.type === 'join') {
      removeFromQueue(ws);

      const room = rooms.get(String(message.code || '').trim().toUpperCase());

      if (!room || room.players.length >= 2) {
        send(ws, {
          type: 'error',
          message: 'Sala não encontrada ou cheia.',
        });
        return;
      }

      room.players.push({
        ws,
        name: playerName,
        symbol: 'O',
      });

      ws.room = room;
      pair(room);
      return;
    }

    if (message.type === 'find') {
      removeFromQueue(ws);

      // Primeiro tenta encontrar outro jogador que também está procurando.
      const other = queue.shift();

      if (other && other.ws.readyState === WebSocket.OPEN) {
        const room = newRoom();

        room.players.push(
          other,
          {
            ws,
            name: playerName,
            symbol: 'O',
          },
        );

        other.ws.room = room;
        ws.room = room;

        pair(room);
        return;
      }

      // Se não houver outro jogador na fila, procura uma sala criada
      // por alguém que está aguardando um amigo. Isso permite:
      // PC -> Criar sala
      // Celular -> Encontrar um Amigo
      const waitingRoom = findWaitingRoom();

      if (waitingRoom && waitingRoom.players[0].ws !== ws) {
        waitingRoom.players.push({
          ws,
          name: playerName,
          symbol: 'O',
        });

        ws.room = waitingRoom;

        pair(waitingRoom);
        return;
      }

      queue.push({
        ws,
        name: playerName,
      });

      send(ws, {
        type: 'waiting',
        code: 'BUSCANDO',
      });

      return;
    }

    const room = ws.room;

    if (!room) return;

    if (message.type === 'move') {
      if (room.status || room.turn !== wsSymbol(room, ws)) {
        return;
      }

      const index = Number(message.index);

      if (
        !Number.isInteger(index) ||
        index < 0 ||
        index > 8 ||
        room.board[index]
      ) {
        return;
      }

      room.board[index] = room.turn;

      const win = winner(room.board);

      if (win) {
        room.status = `${win} venceu!`;

        if (win === 'X') {
          room.xWins++;
        } else {
          room.oWins++;
        }
      } else if (room.board.every(Boolean)) {
        room.status = 'Empate!';
        room.draws++;
      } else {
        room.turn = room.turn === 'X' ? 'O' : 'X';
      }

      broadcast(room);
      return;
    }

    if (message.type === 'reset') {
      reset(room);
      broadcast(room);
    }
  });

  ws.on('close', () => {
    removeFromQueue(ws);

    const room = ws.room;

    if (!room) return;

    room.players = room.players.filter((player) => player.ws !== ws);

    if (room.players.length === 0) {
      rooms.delete(room.code);
      return;
    }

    send(room.players[0].ws, {
      ...state(room),
      opponent: 'Aguardando',
      status: 'O outro jogador saiu.',
    });
  });
});

function wsSymbol(room, ws) {
  return room.players.find((player) => player.ws === ws)?.symbol;
}

console.log(
  `Jogo Da Velha multiplayer server em ws://${HOST}:${PORT}`,
);
