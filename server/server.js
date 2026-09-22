const WebSocket = require('ws');
const crypto = require('crypto');
const wss = new WebSocket.Server({ port: process.env.PORT || 8080, host: process.env.HOST || '0.0.0.0' });
const rooms = new Map();
const queue = [];
const emptyBoard = () => Array(9).fill('');
function code(){ return crypto.randomBytes(2).toString('hex').toUpperCase(); }
function send(ws, data){ if(ws.readyState===WebSocket.OPEN) ws.send(JSON.stringify(data)); }
function state(room){
  const players=[...room.players];
  return {type:'state', board:room.board, turn:room.turn, opponent: players.find(p=>p.symbol!=='?')?.name || 'Jogador', status:room.status, xWins:room.xWins, oWins:room.oWins, draws:room.draws};
}
function winner(b){ const L=[[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]]; for(const [a,c,d] of L){if(b[a] && b[a]===b[c]&&b[a]===b[d]) return b[a];} return null; }
function broadcast(room){ room.players.forEach(p=>send(p.ws,{...state(room), opponent: room.players.find(x=>x.ws!==p.ws)?.name || 'Aguardando'})); }
function reset(room){room.board=emptyBoard();room.turn='X';room.status='';}
function pair(room){ if(room.players.length!==2)return; room.players[0].symbol='X';room.players[1].symbol='O'; room.players.forEach(p=>send(p.ws,{type:'matched',code:room.code,symbol:p.symbol})); broadcast(room); }
function newRoom(){ let c; do c=code(); while(rooms.has(c)); const r={code:c,players:[],board:emptyBoard(),turn:'X',status:'',xWins:0,oWins:0,draws:0}; rooms.set(c,r); return r; }
function removeFromQueue(ws){ for(let i=queue.length-1;i>=0;i--) if(queue[i].ws===ws) queue.splice(i,1); }
wss.on('connection', ws=>{
  ws.on('message', raw=>{
    let m; try{m=JSON.parse(raw)}catch{return}
    if(m.type==='create'){
      const r=newRoom(); r.players.push({ws,name:m.name||'Player',symbol:'X'}); ws.room=r; send(ws,{type:'waiting',code:r.code}); return;
    }
    if(m.type==='join'){
      const r=rooms.get(String(m.code||'').toUpperCase()); if(!r||r.players.length>=2){send(ws,{type:'error',message:'Sala não encontrada ou cheia.'});return;}
      r.players.push({ws,name:m.name||'Player',symbol:'O'}); ws.room=r; pair(r); return;
    }
    if(m.type==='find'){
      removeFromQueue(ws); const other=queue.shift(); if(other && other.ws.readyState===WebSocket.OPEN){ const r=newRoom(); r.players.push(other, {ws,name:m.name||'Player',symbol:'O'}); other.ws.room=r; ws.room=r; pair(r); } else {queue.push({ws,name:m.name||'Player',symbol:'X'}); send(ws,{type:'waiting',code:'BUSCANDO'});} return;
    }
    const r=ws.room; if(!r) return;
    if(m.type==='move'){
      if(r.status || r.turn!==wsSymbol(r,ws)) return; const i=Number(m.index); if(!Number.isInteger(i)||i<0||i>8||r.board[i])return;
      r.board[i]=r.turn; const w=winner(r.board); if(w){r.status=`${w} venceu!`; if(w==='X')r.xWins++;else r.oWins++;} else if(r.board.every(Boolean)){r.status='Empate!';r.draws++;} else r.turn=r.turn==='X'?'O':'X'; broadcast(r); return;
    }
    if(m.type==='reset'){reset(r);broadcast(r);}
  });
  ws.on('close',()=>{removeFromQueue(ws); const r=ws.room; if(r){r.players=r.players.filter(p=>p.ws!==ws); if(r.players.length===0)rooms.delete(r.code); else {send(r.players[0].ws,{type:'state',board:r.board,turn:r.turn,status:'O outro jogador saiu.',xWins:r.xWins,oWins:r.oWins,draws:r.draws,opponent:'Aguardando'});}}});
});
function wsSymbol(r,ws){const p=r.players.find(p=>p.ws===ws);return p?.symbol;}
console.log('Jogo Da Velha multiplayer server em ws://0.0.0.0:'+(process.env.PORT||8080));
