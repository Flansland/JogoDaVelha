import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

const navy = Color(0xFF081A45);
const blue = Color(0xFF4D6FC5);
const cardBlue = Color(0xFF405EAE);
const cream = Color(0xFFF8F5E9);
const red = Color(0xFFF4555B);

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
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 28),
              _menuButton(context, Icons.smart_toy_rounded, 'Jogar com CPU',
                  () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CpuSetupPage(),
                  ),
                );
              }, primary: true),
              const SizedBox(height: 14),
              _menuButton(context, Icons.groups_rounded, 'Multijogador', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MultiplayerPage(),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF102A63),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: cream, size: 20),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuButton(
    BuildContext context,
    IconData icon,
    String text,
    VoidCallback onTap, {
    bool primary = false,
  }) {
    return SizedBox(
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
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class MultiplayerPage extends StatelessWidget {
  const MultiplayerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Multijogador',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          children: [
            _action(
              context,
              Icons.person_rounded,
              'Jogar com Amigo',
              'Dois jogadores no mesmo celular',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GamePage(
                      mode: GameMode.local,
                      mySymbol: 'X',
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _action(
              context,
              Icons.search_rounded,
              'Encontrar um Amigo',
              'Encontre alguém na fila online',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OnlinePage(findMatch: true),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),
            _action(
              context,
              Icons.code_rounded,
              'Código do Jogo',
              'Crie ou entre em uma sala online',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OnlinePage(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback tap,
  ) {
    return Card(
      color: cardBlue,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: tap,
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: cream,
                foregroundColor: blue,
                child: Icon(icon),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CpuSetupPage extends StatelessWidget {
  const CpuSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Jogar com CPU',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Escolha seu lado',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _side(context, 'X', 'Você começa', 'X', blue),
            const SizedBox(height: 12),
            _side(context, 'O', 'CPU começa', 'O', red),
          ],
        ),
      ),
    );
  }

  Widget _side(
    BuildContext context,
    String symbol,
    String title,
    String mySymbol,
    Color color,
  ) {
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: cardBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GamePage(
              mode: GameMode.cpu,
              mySymbol: mySymbol,
            ),
          ),
        );
      },
      child: Row(
        children: [
          Text(
            symbol,
            style: TextStyle(
              color: color,
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

enum GameMode { local, cpu, online }

class GamePage extends StatefulWidget {
  final GameMode mode;
  final String mySymbol;
  final WebSocketChannel? channel;
  final Stream<dynamic>? stream;
  final String roomCode;

  const GamePage({
    super.key,
    required this.mode,
    required this.mySymbol,
    this.channel,
    this.stream,
    this.roomCode = '',
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  List<String> board = List<String>.filled(9, '');
  String turn = 'X';
  String status = '';
  String opponent = 'Jogador O';

  int xPoints = 0;
  int oPoints = 0;
  int draws = 0;

  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();

    if (widget.mode == GameMode.online && widget.channel != null) {
      final gameStream = widget.stream ?? widget.channel!.stream;
      sub = gameStream.listen(
        _onNetwork,
        onError: (_) => _setStatus('Conexão perdida.'),
        onDone: () => _setStatus('Conexão encerrada.'),
      );
    }

    if (widget.mode == GameMode.cpu && widget.mySymbol == 'O') {
      Future.delayed(
        const Duration(milliseconds: 500),
        _cpuMove,
      );
    }
  }

  @override
  void dispose() {
    sub?.cancel();
    if (widget.mode == GameMode.online) {
      widget.channel?.sink.close();
    }
    super.dispose();
  }

  void _onNetwork(dynamic raw) {
    try {
      final data = jsonDecode(raw as String) as Map<String, dynamic>;

      if (data['type'] == 'state' && mounted) {
        setState(() {
          board = List<String>.from(
            data['board'] ?? List<String>.filled(9, ''),
          );
          turn = data['turn'] ?? 'X';
          opponent = data['opponent'] ?? opponent;
          status = data['status'] ?? '';
          xPoints = data['xWins'] ?? xPoints;
          oPoints = data['oWins'] ?? oPoints;
          draws = data['draws'] ?? draws;
        });
      }
    } catch (_) {}
  }

  void _setStatus(String value) {
    if (!mounted) return;
    setState(() {
      status = value;
    });
  }

  // ESTA É A FUNÇÃO QUE REGISTRA O CLIQUE EM CADA CASA.
  // Ela não bloqueia casas vazias no modo local.
  void tapCell(int index) {
    if (index < 0 || index >= 9) return;

    // Casa já ocupada.
    if (board[index].isNotEmpty) return;

    // Partida terminou.
    if (status.isNotEmpty) return;

    // Multiplayer online: só envia a jogada do jogador da vez.
    if (widget.mode == GameMode.online) {
      if (turn != widget.mySymbol) return;

      widget.channel?.sink.add(
        jsonEncode({
          'type': 'move',
          'index': index,
        }),
      );
      return;
    }

    // CPU: não permite clicar enquanto a CPU está jogando.
    if (widget.mode == GameMode.cpu && turn != widget.mySymbol) {
      return;
    }

    setState(() {
      board[index] = turn;
      _finishOrNextTurn();
    });

    // Depois da jogada humana, chama a CPU.
    if (widget.mode == GameMode.cpu &&
        status.isEmpty &&
        turn != widget.mySymbol) {
      Future.delayed(
        const Duration(milliseconds: 350),
        _cpuMove,
      );
    }
  }

  void _finishOrNextTurn() {
    final winner = winnerOf(board);

    if (winner != null) {
      status = '$winner venceu!';
      if (winner == 'X') {
        xPoints++;
      } else {
        oPoints++;
      }
      return;
    }

    if (board.every((cell) => cell.isNotEmpty)) {
      status = 'EMPATE!';
      draws++;
      return;
    }

    turn = turn == 'X' ? 'O' : 'X';
  }

  void _cpuMove() {
    if (!mounted) return;
    if (widget.mode != GameMode.cpu) return;
    if (status.isNotEmpty) return;
    if (turn == widget.mySymbol) return;

    final cpu = widget.mySymbol == 'X' ? 'O' : 'X';
    final move = bestMove(board, cpu);

    if (move == -1) return;

    setState(() {
      board[move] = cpu;
      _finishOrNextTurn();
    });
  }

  void reset() {
    if (widget.mode == GameMode.online) {
      widget.channel?.sink.add(
        jsonEncode({'type': 'reset'}),
      );
      return;
    }

    setState(() {
      board = List<String>.filled(9, '');
      turn = 'X';
      status = '';
    });

    if (widget.mode == GameMode.cpu && widget.mySymbol == 'O') {
      Future.delayed(
        const Duration(milliseconds: 400),
        _cpuMove,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDraw = status == 'EMPATE!';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: Text(
          widget.mode == GameMode.online
              ? 'Sala ${widget.roomCode}'
              : 'Clássico',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          if (widget.mode == GameMode.online)
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.wifi),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              // PLACAR
              Row(
                children: [
                  Expanded(
                    child: _scoreCard(
                      'X',
                      'Pontos X',
                      xPoints,
                      turn == 'X',
                      cream,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _scoreCard(
                      'O',
                      'Pontos O',
                      oPoints,
                      turn == 'O',
                      red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _drawCard(),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // JOGADORES
              Row(
                children: [
                  Expanded(
                    child: _playerCard(
                      widget.mode == GameMode.cpu ? 'Você' : 'Jogador X',
                      'X',
                      turn == 'X',
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _playerCard(
                      widget.mode == GameMode.cpu ? 'CPU' : opponent,
                      'O',
                      turn == 'O',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // TABULEIRO CLICÁVEL
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 520,
                      maxHeight: 520,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _board(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // MENSAGEM DE RESULTADO / VEZ
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: isDraw
                      ? const Color(0xFF66551A)
                      : status.isNotEmpty
                          ? const Color(0xFF1C4D39)
                          : const Color(0xFF102A63),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status.isEmpty ? 'Vez de $turn' : status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Nova partida'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Colors.white54,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Voltar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreCard(
    String symbol,
    String title,
    int points,
    bool active,
    Color symbolColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: active ? blue : cardBlue.withOpacity(.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active ? Colors.white : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Text(
            symbol,
            style: TextStyle(
              color: symbolColor,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            '$points',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: cardBlue.withOpacity(.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.handshake_rounded,
            color: cream,
            size: 23,
          ),
          Text(
            '$draws',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Empates',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _playerCard(
    String name,
    String symbol,
    bool active,
  ) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: active ? blue : cardBlue.withOpacity(.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? Colors.white : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: cream,
            foregroundColor: symbol == 'X' ? blue : red,
            child: Text(
              symbol,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _board() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: cardBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: GridView.builder(
        // Importante: não usar NeverScrollableScrollPhysics sozinho
        // para bloquear os cliques. As casas continuam recebendo onTap.
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: 9,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
        ),
        itemBuilder: (context, index) {
          final value = board[index];
          final enabled =
              value.isEmpty && status.isEmpty && _canPlayNow();

          return Material(
            color: const Color(0xFF4968B8),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              // onTap está diretamente na CASA.
              onTap: enabled ? () => tapCell(index) : null,
              splashColor: Colors.white24,
              highlightColor: Colors.white10,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Text(
                    value,
                    key: ValueKey('$index-$value'),
                    style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      color: value == 'X' ? cream : red,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _canPlayNow() {
    if (status.isNotEmpty) return false;

    if (widget.mode == GameMode.cpu) {
      return turn == widget.mySymbol;
    }

    if (widget.mode == GameMode.online) {
      return turn == widget.mySymbol;
    }

    return true;
  }
}

String? winnerOf(List<String> b) {
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

  for (final line in lines) {
    final value = b[line[0]];
    if (value.isNotEmpty &&
        value == b[line[1]] &&
        value == b[line[2]]) {
      return value;
    }
  }

  return null;
}

int bestMove(List<String> input, String cpu) {
  final human = cpu == 'X' ? 'O' : 'X';

  var bestScore = -1000;
  var move = -1;

  for (var i = 0; i < 9; i++) {
    if (input[i].isNotEmpty) continue;

    final board = List<String>.from(input);
    board[i] = cpu;

    final score = minimax(
      board,
      false,
      cpu,
      human,
    );

    if (score > bestScore) {
      bestScore = score;
      move = i;
    }
  }

  return move;
}

int minimax(
  List<String> board,
  bool maximizing,
  String cpu,
  String human,
) {
  final winner = winnerOf(board);

  if (winner == cpu) return 10;
  if (winner == human) return -10;
  if (board.every((x) => x.isNotEmpty)) return 0;

  if (maximizing) {
    var best = -1000;

    for (var i = 0; i < 9; i++) {
      if (board[i].isEmpty) {
        final next = List<String>.from(board);
        next[i] = cpu;

        best = max(
          best,
          minimax(
            next,
            false,
            cpu,
            human,
          ),
        );
      }
    }

    return best;
  }

  var best = 1000;

  for (var i = 0; i < 9; i++) {
    if (board[i].isEmpty) {
      final next = List<String>.from(board);
      next[i] = human;

      best = min(
        best,
        minimax(
          next,
          true,
          cpu,
          human,
        ),
      );
    }
  }

  return best;
}

class OnlinePage extends StatefulWidget {
  final bool findMatch;

  const OnlinePage({
    super.key,
    this.findMatch = false,
  });

  @override
  State<OnlinePage> createState() => _OnlinePageState();
}

class _OnlinePageState extends State<OnlinePage> {
  final url = TextEditingController(
    text: 'wss://jogodavelha-6neh.onrender.com',
  );

  final code = TextEditingController();
  final name = TextEditingController(text: 'Player');
  static const _savedNameKey = 'jogo_da_velha_player_name';

  bool busy = false;
  String message = '';
  WebSocketChannel? _pendingChannel;
  StreamSubscription? _pendingSubscription;

  @override
  void initState() {
    super.initState();
    _loadSavedName();

    if (widget.findMatch) {
      Future.delayed(
        const Duration(milliseconds: 250),
        findMatch,
      );
    }
  }

  Future<void> _loadSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_savedNameKey);
    if (!mounted || saved == null || saved.trim().isEmpty) return;
    name.text = saved;
  }

  Future<void> _saveName() async {
    final value = name.text.trim();
    if (value.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedNameKey, value);
  }

  @override
  void dispose() {
    _pendingSubscription?.cancel();
    _pendingChannel?.sink.close();
    url.dispose();
    code.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> connect(String action) async {
    if (busy) return;

    setState(() {
      busy = true;
      message = 'Conectando...';
    });

    WebSocketChannel? channel;
    StreamSubscription? subscription;
    bool openedGame = false;
    Stream<dynamic>? broadcastStream;

    try {
      final uri = Uri.parse(url.text.trim());

      if (uri.scheme != 'ws' && uri.scheme != 'wss') {
        throw Exception('URL WebSocket inválida');
      }

      channel = WebSocketChannel.connect(uri);
      _pendingChannel = channel;

      // Converte o stream para broadcast UMA única vez. Isso permite
      // transferir a conexão para a tela do jogo sem o erro
      // 'Stream has already been listened to'.
      broadcastStream = channel.stream.asBroadcastStream();

      // Espera a conexão. O stream NÃO é escutado aqui.
      await channel.ready;

      final playerName = name.text.trim().isEmpty ? 'Player' : name.text.trim();
      name.text = playerName;
      await _saveName();

      channel.sink.add(
        jsonEncode({
          'type': action,
          'code': code.text.trim().toUpperCase(),
          'name': playerName,
        }),
      );

      // Um único listener fica responsável pelas mensagens enquanto
      // a sala ainda está sendo criada/procurada.
      subscription = broadcastStream.listen(
        (raw) {
          if (openedGame) return;

          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            final type = data['type'];

            if (type == 'waiting') {
              if (!mounted) return;

              setState(() {
                busy = false;
                message = 'Sala criada: ${data['code']}\n'
                    'Compartilhe o código com seu amigo.';
                code.text = data['code'] ?? '';
              });

              // Continua usando ESTE MESMO listener até o adversário entrar.
              return;
            }

            if (type == 'matched') {
              openedGame = true;
              _openGame(channel!, data, subscription, broadcastStream!);
              return;
            }

            if (type == 'error') {
              if (!mounted) return;
              channel?.sink.close();
              subscription?.cancel();
              _pendingChannel = null;
              _pendingSubscription = null;

              setState(() {
                busy = false;
                message = data['message'] ?? 'Erro.';
              });
            }
          } catch (_) {
            // Ignora mensagens inválidas do servidor.
          }
        },
        onError: (_) {
          if (!mounted || openedGame) return;
          setState(() {
            busy = false;
            message = 'Conexão perdida com o servidor.';
          });
        },
        onDone: () {
          if (!mounted || openedGame) return;
          setState(() {
            busy = false;
            message = 'Conexão encerrada pelo servidor.';
          });
        },
      );

      _pendingSubscription = subscription;
    } catch (_) {
      await subscription?.cancel();
      await channel?.sink.close();
      _pendingSubscription = null;
      _pendingChannel = null;

      if (!mounted) return;

      setState(() {
        busy = false;
        message = 'Não foi possível conectar ao servidor.\n'
            'Se o Render estiver iniciando, aguarde alguns segundos e tente novamente.';
      });
    }
  }

  Future<void> _openGame(
    WebSocketChannel channel,
    Map<String, dynamic> data,
    StreamSubscription? pendingSubscription,
    Stream<dynamic> broadcastStream,
  ) async {
    // É essencial cancelar o listener desta tela ANTES de o GamePage
    // começar a escutar o mesmo WebSocket. Assim nunca existem dois
    // listeners em um stream single-subscription.
    await pendingSubscription?.cancel();

    _pendingSubscription = null;
    _pendingChannel = null;

    if (!mounted) {
      await channel.sink.close();
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GamePage(
          mode: GameMode.online,
          mySymbol: data['symbol'] ?? 'X',
          channel: channel,
          stream: broadcastStream,
          roomCode: data['code'] ?? code.text,
        ),
      ),
    );
  }

  void findMatch() {
    connect('find');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text(
          'Código do Jogo',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _field('Seu nome', name, Icons.person),
          const SizedBox(height: 12),
          _field('Servidor WebSocket', url, Icons.wifi),
          const SizedBox(height: 18),
          Card(
            color: cardBlue,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text(
                    'Criar uma sala',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Crie um código e envie para seu amigo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: busy ? null : () => connect('create'),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Criar'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: cardBlue,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  const Text(
                    'Entrar com código',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: code,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ex.: ABC123',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: navy,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: busy ? null : () => connect('join'),
                    icon: const Icon(Icons.login),
                    label: const Text('Entrar'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: const Color(0xFF102A63),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                message.isEmpty
                    ? 'Servidor: jogodavelha-6neh.onrender.com'
                    : message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: cream),
        filled: true,
        fillColor: cardBlue,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
