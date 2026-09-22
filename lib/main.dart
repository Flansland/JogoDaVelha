import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const navy = Color(0xFF081A45);
const blue = Color(0xFF4D6FC5);
const blueDark = Color(0xFF3859A8);
const cardBlue = Color(0xFF405EAE);
const cream = Color(0xFFF8F5E9);
const red = Color(0xFFF4555B);
const purple = Color(0xFF35116E);

void main() => runApp(const JogoDaVelhaApp());

class JogoDaVelhaApp extends StatelessWidget {
  const JogoDaVelhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jogo Da Velha',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: navy,
        fontFamily: 'sans',
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Column(
            children: [
              Row(
                children: [
                  _pill(Icons.monetization_on, '40'),
                  const SizedBox(width: 10),
                  _pill(Icons.bolt, '10 XP'),
                ],
              ),
              const SizedBox(height: 18),
              Image.asset('assets/logo.png', width: 250, height: 250),
              const SizedBox(height: 12),
              const Text(
                'Jogo Da Velha',
                style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 28),
              _menuButton(context, Icons.smart_toy_rounded, 'Jogar com CPU', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const CpuSetupPage()));
              }, primary: true),
              const SizedBox(height: 14),
              _menuButton(context, Icons.groups_rounded, 'Multijogador', () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MultiplayerPage()));
              }),
              const SizedBox(height: 18),
              const Text(
                'Jogue localmente ou desafie um amigo usando um código de sala.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(color: const Color(0xFF102A63), borderRadius: BorderRadius.circular(22)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: cream, size: 20),
          const SizedBox(width: 7),
          Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _menuButton(BuildContext context, IconData icon, String text, VoidCallback onTap, {bool primary = false}) =>
      SizedBox(
        width: double.infinity,
        height: 58,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: primary ? blue : cream,
            foregroundColor: primary ? Colors.white : blue,
            shape: const StadiumBorder(),
          ),
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        ),
      );
}

class MultiplayerPage extends StatelessWidget {
  const MultiplayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('Multijogador', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            _action(context, Icons.person_rounded, 'Jogar com Amigo', 'Dois jogadores no mesmo celular', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const GamePage(mode: GameMode.local, mySymbol: 'X')));
            }),
            const SizedBox(height: 14),
            _action(context, Icons.search_rounded, 'Encontrar um Amigo', 'Encontre alguém na fila online', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OnlinePage(findMatch: true)));
            }),
            const SizedBox(height: 14),
            _action(context, Icons.code_rounded, 'Código do Jogo', 'Crie ou entre em uma sala online', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const OnlinePage()));
            }),
            const Spacer(),
            const Text('O multiplayer online precisa de um servidor WebSocket configurado.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String title, String subtitle, VoidCallback tap) => Card(
        color: cardBlue,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: tap,
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(children: [
              CircleAvatar(backgroundColor: cream, foregroundColor: blue, child: Icon(icon)),
              const SizedBox(width: 15),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
              const Icon(Icons.chevron_right, color: Colors.white),
            ]),
          ),
        ),
      );
}

class CpuSetupPage extends StatelessWidget {
  const CpuSetupPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: navy, foregroundColor: Colors.white, title: const Text('Jogar com CPU', style: TextStyle(fontWeight: FontWeight.w900))),
        body: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Escolha seu lado', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _side(context, 'X', 'Você começa', 'X', blue),
            const SizedBox(height: 12),
            _side(context, 'O', 'CPU começa', 'O', red),
            const SizedBox(height: 28),
            const Text('A CPU usa uma estratégia minimax para jogar no modo clássico.', style: TextStyle(color: Colors.white70)),
          ]),
        ),
      );

  Widget _side(BuildContext context, String symbol, String title, String mySymbol, Color color) => FilledButton(
        style: FilledButton.styleFrom(backgroundColor: cardBlue, foregroundColor: Colors.white, padding: const EdgeInsets.all(18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GamePage(mode: GameMode.cpu, mySymbol: mySymbol))),
        child: Row(children: [
          Text(symbol, style: TextStyle(color: color, fontSize: 40, fontWeight: FontWeight.w900)),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
          const Icon(Icons.chevron_right),
        ]),
      );
}

enum GameMode { local, cpu, online }

class GamePage extends StatefulWidget {
  final GameMode mode;
  final String mySymbol;
  final WebSocketChannel? channel;
  final String roomCode;
  final String onlineName;

  const GamePage({super.key, required this.mode, required this.mySymbol, this.channel, this.roomCode = '', this.onlineName = ''});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  List<String> board = List.filled(9, '');
  String turn = 'X';
  String status = '';
  String opponent = 'Jogador 2';
  int xWins = 0;
  int oWins = 0;
  int draws = 0;
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    if (widget.mode == GameMode.online && widget.channel != null) {
      sub = widget.channel!.stream.listen(_onNetwork, onError: (_) => _setStatus('Conexão perdida.'), onDone: () => _setStatus('Conexão encerrada.'));
    }
    if (widget.mode == GameMode.cpu && widget.mySymbol == 'O') {
      Future.delayed(const Duration(milliseconds: 450), _cpuMove);
    }
  }

  @override
  void dispose() {
    sub?.cancel();
    widget.channel?.sink.close();
    super.dispose();
  }

  void _onNetwork(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;
      if (data['type'] == 'state') {
        setState(() {
          board = List<String>.from(data['board'] ?? List.filled(9, ''));
          turn = data['turn'] ?? 'X';
          opponent = data['opponent'] ?? opponent;
          status = data['status'] ?? '';
          xWins = data['xWins'] ?? xWins;
          oWins = data['oWins'] ?? oWins;
          draws = data['draws'] ?? draws;
        });
      }
    } catch (_) {}
  }

  void _setStatus(String value) {
    if (mounted) setState(() => status = value);
  }

  void tap(int index) {
    if (board[index].isNotEmpty || status.isNotEmpty) return;
    if (widget.mode == GameMode.online) {
      if (turn != widget.mySymbol) return;
      widget.channel?.sink.add(jsonEncode({'type': 'move', 'index': index}));
      return;
    }
    if (widget.mode == GameMode.cpu && turn != widget.mySymbol) return;
    setState(() {
      board[index] = turn;
      _afterMove();
    });
    if (widget.mode == GameMode.cpu && status.isEmpty && turn != widget.mySymbol) {
      Future.delayed(const Duration(milliseconds: 350), _cpuMove);
    }
  }

  void _afterMove() {
    final winner = winnerOf(board);
    if (winner != null) {
      status = '$winner venceu!';
      if (winner == 'X') xWins++; else oWins++;
      return;
    }
    if (board.every((x) => x.isNotEmpty)) {
      status = 'Empate!';
      draws++;
      return;
    }
    turn = turn == 'X' ? 'O' : 'X';
  }

  void _cpuMove() {
    if (!mounted || widget.mode != GameMode.cpu || status.isNotEmpty || turn == widget.mySymbol) return;
    final cpu = widget.mySymbol == 'X' ? 'O' : 'X';
    final move = bestMove(board, cpu);
    if (move == -1) return;
    setState(() {
      board[move] = cpu;
      _afterMove();
    });
  }

  void reset() {
    if (widget.mode == GameMode.online) {
      widget.channel?.sink.add(jsonEncode({'type': 'reset'}));
      return;
    }
    setState(() {
      board = List.filled(9, '');
      turn = 'X';
      status = '';
    });
    if (widget.mode == GameMode.cpu && widget.mySymbol == 'O') Future.delayed(const Duration(milliseconds: 350), _cpuMove);
  }

  @override
  Widget build(BuildContext context) {
    final me = widget.mode == GameMode.online ? widget.mySymbol : 'X';
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: Text(widget.mode == GameMode.online ? 'Sala ${widget.roomCode}' : 'Clássico', style: const TextStyle(fontWeight: FontWeight.w900)),
        actions: [if (widget.mode == GameMode.online) const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.wifi))],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(children: [
            Row(children: [
              Expanded(child: _playerCard(widget.mode == GameMode.cpu ? 'Você' : 'Jogador X', 'X', turn == 'X')),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('VS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
              Expanded(child: _playerCard(widget.mode == GameMode.cpu ? 'CPU' : opponent, 'O', turn == 'O')),
            ]),
            const SizedBox(height: 18),
            Expanded(child: Center(child: AspectRatio(aspectRatio: 1, child: _board()))),
            const SizedBox(height: 15),
            Text(status.isEmpty ? 'Vez de $turn' : status, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
            if (widget.mode == GameMode.online && status.isEmpty) Padding(padding: const EdgeInsets.only(top: 5), child: Text('Você é $me', style: const TextStyle(color: Colors.white60))),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: FilledButton.icon(onPressed: reset, icon: const Icon(Icons.refresh), label: const Text('Nova partida'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)), onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back), label: const Text('Voltar'))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _playerCard(String name, String symbol, bool active) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: active ? blue : cardBlue.withOpacity(.65), borderRadius: BorderRadius.circular(18), border: Border.all(color: active ? Colors.white : Colors.transparent)),
        child: Row(children: [
          CircleAvatar(backgroundColor: cream, foregroundColor: blue, child: Text(symbol, style: const TextStyle(fontWeight: FontWeight.w900))),
          const SizedBox(width: 8),
          Expanded(child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
        ]),
      );

  Widget _board() => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: cardBlue, borderRadius: BorderRadius.circular(24)),
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 9,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
          itemBuilder: (_, i) => Material(
            color: const Color(0xFF4968B8),
            child: InkWell(
              onTap: () => tap(i),
              child: Center(child: AnimatedSwitcher(duration: const Duration(milliseconds: 150), child: Text(board[i], key: ValueKey('$i-${board[i]}'), style: TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: board[i] == 'X' ? cream : red)))),
            ),
          ),
        ),
      );
}

String? winnerOf(List<String> b) {
  const lines = [[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];
  for (final line in lines) {
    final v = b[line[0]];
    if (v.isNotEmpty && v == b[line[1]] && v == b[line[2]]) return v;
  }
  return null;
}

int bestMove(List<String> input, String cpu) {
  final human = cpu == 'X' ? 'O' : 'X';
  var bestScore = -1000;
  var move = -1;
  for (var i = 0; i < 9; i++) {
    if (input[i].isNotEmpty) continue;
    final b = List<String>.from(input)..[i] = cpu;
    final score = minimax(b, false, cpu, human);
    if (score > bestScore) { bestScore = score; move = i; }
  }
  return move;
}

int minimax(List<String> b, bool maximizing, String cpu, String human) {
  final winner = winnerOf(b);
  if (winner == cpu) return 10;
  if (winner == human) return -10;
  if (b.every((x) => x.isNotEmpty)) return 0;
  if (maximizing) {
    var best = -1000;
    for (var i=0;i<9;i++) if (b[i].isEmpty) { final n=List<String>.from(b)..[i]=cpu; best=max(best,minimax(n,false,cpu,human)); }
    return best;
  }
  var best = 1000;
  for (var i=0;i<9;i++) if (b[i].isEmpty) { final n=List<String>.from(b)..[i]=human; best=min(best,minimax(n,true,cpu,human)); }
  return best;
}

class OnlinePage extends StatefulWidget {
  final bool findMatch;
  const OnlinePage({super.key, this.findMatch = false});
  @override
  State<OnlinePage> createState() => _OnlinePageState();
}

class _OnlinePageState extends State<OnlinePage> {
  final url = TextEditingController(text: 'wss://jogodavelha-6neh.onrender.com');
  final code = TextEditingController();
  final name = TextEditingController(text: 'Player');
  bool busy = false;
  String message = '';

  @override
  void initState() {
    super.initState();
    if (widget.findMatch) Future.delayed(const Duration(milliseconds: 250), findMatch);
  }

  @override
  void dispose() { url.dispose(); code.dispose(); name.dispose(); super.dispose(); }

  Future<void> connect(String action) async {
    if (busy) return;
    setState(() { busy = true; message = 'Conectando...'; });
    try {
      final channel = WebSocketChannel.connect(Uri.parse(url.text.trim()));
      await channel.ready;
      channel.sink.add(jsonEncode({'type': action, 'code': code.text.trim().toUpperCase(), 'name': name.text.trim().isEmpty ? 'Player' : name.text.trim()}));
      final first = await channel.stream.first.timeout(const Duration(seconds: 8));
      final data = jsonDecode(first as String) as Map<String, dynamic>;
      if (data['type'] == 'waiting') {
        setState(() { busy = false; message = 'Sala criada: ${data['code']}\nCompartilhe o código com seu amigo.'; code.text = data['code']; });
        _listenWaiting(channel, data['code']);
      } else if (data['type'] == 'matched') {
        _openGame(channel, data);
      } else if (data['type'] == 'error') {
        await channel.sink.close();
        setState(() { busy = false; message = data['message'] ?? 'Erro.'; });
      }
    } catch (e) {
      setState(() { busy = false; message = 'Não foi possível conectar. Confira o endereço do servidor.'; });
    }
  }

  void _listenWaiting(WebSocketChannel channel, String room) {
    channel.stream.listen((raw) {
      try {
        final data = jsonDecode(raw as String) as Map<String, dynamic>;
        if (data['type'] == 'matched' && mounted) _openGame(channel, data);
      } catch (_) {}
    }, onError: (_) {});
  }

  void _openGame(WebSocketChannel channel, Map<String, dynamic> data) {
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GamePage(mode: GameMode.online, mySymbol: data['symbol'] ?? 'X', channel: channel, roomCode: data['code'] ?? code.text, onlineName: name.text)));
  }

  void findMatch() { connect('find'); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(backgroundColor: navy, foregroundColor: Colors.white, title: const Text('Código do Jogo', style: TextStyle(fontWeight: FontWeight.w900))),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          _field('Seu nome', name, Icons.person),
          const SizedBox(height: 12),
          _field('Servidor WebSocket', url, Icons.wifi),
          const SizedBox(height: 18),
          Card(color: cardBlue, child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
            const Text('Criar uma sala', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Crie um código e envie para seu amigo.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 14),
            FilledButton.icon(onPressed: busy ? null : () => connect('create'), icon: const Icon(Icons.add_circle_outline), label: const Text('Criar')), 
          ]))),
          const SizedBox(height: 14),
          Card(color: cardBlue, child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
            const Text('Entrar com código', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(controller: code, textCapitalization: TextCapitalization.characters, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 5), decoration: _dec('ABCD')),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: busy ? null : () => connect('join'), icon: const Icon(Icons.login), label: const Text('Juntar-se')), 
          ]))),
          const SizedBox(height: 14),
          Card(color: cardBlue, child: Padding(padding: const EdgeInsets.all(18), child: Column(children: [
            const Text('Encontrar um amigo', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Entra na fila e conecta automaticamente dois jogadores.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: busy ? null : findMatch, icon: const Icon(Icons.search), label: const Text('Procurar')), 
          ]))),
          if (busy) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
          if (message.isNotEmpty) Padding(padding: const EdgeInsets.all(15), child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
        ],
      ),
    );

  InputDecoration _dec(String hint) => InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Colors.white54), filled: true, fillColor: const Color(0xFF314F9C), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none));
  Widget _field(String label, TextEditingController c, IconData icon) => TextField(controller: c, style: const TextStyle(color: Colors.white), decoration: _dec(label).copyWith(labelText: label, labelStyle: const TextStyle(color: Colors.white70), prefixIcon: Icon(icon, color: Colors.white70)));
}
