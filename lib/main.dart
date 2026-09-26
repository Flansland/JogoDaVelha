import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const navy=Color(0xFF081A45), blue=Color(0xFF4D6FC5), cardBlue=Color(0xFF405EAE), cream=Color(0xFFF8F5E9), red=Color(0xFFF4555B);
const apiBase='https://jogodavelha-6neh.onrender.com';
const wsBase='wss://jogodavelha-6neh.onrender.com';

class PlayerSession{
  static String id=''; static String name='Player'; static Map<String,dynamic> profile={}; static List<dynamic> store=[]; static List<dynamic> packages=[];
  static Future<void> init() async{final p=await SharedPreferences.getInstance();id=p.getString('player_id')??'JDV-${List.generate(8,(_)=>'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'[Random().nextInt(36)]).join()}';name=p.getString('player_name')??'Player';await p.setString('player_id',id);await refresh();}
  static Future<void> setName(String value) async{name=value.trim().isEmpty?'Player':value.trim();final p=await SharedPreferences.getInstance();await p.setString('player_name',name);await refresh();}
  static Future<void> refresh() async{try{final r=await http.post(Uri.parse('$apiBase/api/profile'),headers:{'Content-Type':'application/json'},body:jsonEncode({'playerId':id,'name':name}));if(r.statusCode==200)profile=jsonDecode(r.body)['profile']??profile;final s=await http.get(Uri.parse('$apiBase/api/store'));if(s.statusCode==200){final d=jsonDecode(s.body);store=d['items']??[];packages=d['packages']??[];}}catch(_){}}
  static Future<String?> redeem(String code) async{try{final r=await http.post(Uri.parse('$apiBase/api/redeem'),headers:{'Content-Type':'application/json'},body:jsonEncode({'playerId':id,'code':code}));final d=jsonDecode(r.body);if(r.statusCode==200){profile=d['profile'];return d['message'];}return d['error']??'Código inválido.';}catch(_){return 'Servidor indisponível.';}}
  static Future<String?> buy(String itemId) async{try{final r=await http.post(Uri.parse('$apiBase/api/purchase'),headers:{'Content-Type':'application/json'},body:jsonEncode({'playerId':id,'itemId':itemId}));final d=jsonDecode(r.body);if(r.statusCode==200){profile=d['profile'];return null;}return d['error']??'Não foi possível comprar.';}catch(_){return 'Servidor indisponível.';}}
  static Future<String?> equip(String itemId) async{try{final r=await http.post(Uri.parse('$apiBase/api/equip'),headers:{'Content-Type':'application/json'},body:jsonEncode({'playerId':id,'itemId':itemId}));final d=jsonDecode(r.body);if(r.statusCode==200){profile=d['profile'];return null;}return d['error']??'Não foi possível equipar.';}catch(_){return 'Servidor indisponível.';}}
  static Future<void> gameReward(String result) async{try{final r=await http.post(Uri.parse('$apiBase/api/game/result'),headers:{'Content-Type':'application/json'},body:jsonEncode({'playerId':id,'result':result}));if(r.statusCode==200)profile=jsonDecode(r.body)['profile'];}catch(_) {}}
}

Map<String,dynamic>? equippedTheme(){final id='${PlayerSession.profile['equipped']?['theme']??'theme_classic'}';for(final x in PlayerSession.store){if(x['id']==id)return Map<String,dynamic>.from(x);}return null;}
Color currentBackground()=>parseColor(equippedTheme()?['bgColor']??'#081A45');
String currentBackgroundImage()=> '${equippedTheme()?['imageUrl']??''}';
BoxDecoration backgroundDecoration(){final image=currentBackgroundImage();return BoxDecoration(color:currentBackground(),image:image.isEmpty?null:DecorationImage(image:NetworkImage(image),fit:BoxFit.cover));}

Future<void> main() async{WidgetsFlutterBinding.ensureInitialized();await PlayerSession.init();runApp(const JogoDaVelhaApp());}

class JogoDaVelhaApp extends StatelessWidget{const JogoDaVelhaApp({super.key});@override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'Jogo Da Velha',theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:navy,colorScheme:ColorScheme.fromSeed(seedColor:blue)),home:const HomePage());}

class HomePage extends StatefulWidget{const HomePage({super.key});@override State<HomePage>createState()=>_HomePageState();}
class _HomePageState extends State<HomePage>{final nameCtrl=TextEditingController();@override void initState(){super.initState();nameCtrl.text=PlayerSession.name;}@override void dispose(){nameCtrl.dispose();super.dispose();}Future<void> reload()async{await PlayerSession.refresh();if(mounted)setState((){});}Widget pill(IconData i,String t)=>Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:8),decoration:BoxDecoration(color:const Color(0xFF102A63),borderRadius:BorderRadius.circular(20)),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(i,color:cream,size:18),const SizedBox(width:6),Text(t,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900))]));
@override Widget build(BuildContext context){final p=PlayerSession.profile;return Scaffold(body:Container(decoration:backgroundDecoration(),child:SafeArea(child:RefreshIndicator(onRefresh:reload,child:ListView(padding:const EdgeInsets.fromLTRB(18,16,18,28),children:[Row(children:[pill(Icons.monetization_on,'${p['coins']??0}'),const SizedBox(width:8),pill(Icons.bolt,'${p['xp']??0} XP'),const SizedBox(width:8),pill(Icons.star,'Nv. ${p['level']??1}')]),const SizedBox(height:18),Center(child:Image.asset('assets/logo.png',width:190,height:190)),const SizedBox(height:8),const Center(child:Text('Jogo Da Velha',style:TextStyle(color:Colors.white,fontSize:30,fontWeight:FontWeight.w900))),const SizedBox(height:8),Center(child:Text('ID: ${PlayerSession.id}',style:const TextStyle(color:Colors.white54,fontSize:11))),const SizedBox(height:18),TextField(controller:nameCtrl,style:const TextStyle(color:Colors.white),decoration:dec('Seu nome').copyWith(prefixIcon:const Icon(Icons.person,color:Colors.white70)),onSubmitted:(v)async{await PlayerSession.setName(v);if(mounted)setState((){});}),const SizedBox(height:14),menu(context,Icons.smart_toy,'Jogar com CPU',()=>push(context,const CpuSetupPage()),primary:true),const SizedBox(height:10),menu(context,Icons.groups,'Multijogador',()=>push(context,const MultiplayerPage())),const SizedBox(height:10),menu(context,Icons.store,'Loja',()=>push(context,const StorePage())),const SizedBox(height:10),menu(context,Icons.card_giftcard,'Código de recompensa',()=>push(context,const RedeemPage())),const SizedBox(height:10),menu(context,Icons.person_add_alt_1,'Amigos',()=>push(context,const FriendsPage())),const SizedBox(height:20),const Center(child:Text('Vitórias, empates e derrotas ficam registrados na conta.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white54,fontSize:12))) ])))));}
Widget menu(BuildContext c,IconData i,String t,VoidCallback f,{bool primary=false})=>SizedBox(height:56,width:double.infinity,child:FilledButton.icon(style:FilledButton.styleFrom(backgroundColor:primary?blue:cream,foregroundColor:primary?Colors.white:blue,shape:const StadiumBorder()),onPressed:f,icon:Icon(i),label:Text(t,style:const TextStyle(fontWeight:FontWeight.w900))));
}
void push(BuildContext c,Widget w)=>Navigator.push(c,MaterialPageRoute(builder:(_)=>w));
InputDecoration dec(String h)=>InputDecoration(hintText:h,hintStyle:const TextStyle(color:Colors.white54),filled:true,fillColor:const Color(0xFF314F9C),border:OutlineInputBorder(borderRadius:BorderRadius.all(Radius.circular(14)),borderSide:BorderSide.none));

class StartPage extends StatelessWidget{final String title;final String mode;final String level;const StartPage({super.key,required this.title,required this.mode,this.level='Iniciante'});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(backgroundColor:navy,foregroundColor:Colors.white,title:Text(title,style:const TextStyle(fontWeight:FontWeight.w900))),body:Padding(padding:const EdgeInsets.all(22),child:Column(crossAxisAlignment:CrossAxisAlignment.stretch,children:[const Text('Quem começa?',style:TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:14),FilledButton(onPressed:()=>_open(c,'X'),child:const Text('COMEÇAR COM X')),const SizedBox(height:12),FilledButton(onPressed:()=>_open(c,'O'),child:const Text('COMEÇAR COM O'))])));void _open(BuildContext c,String s){push(c,GamePage(mode:mode=='cpu'?GameMode.cpu:GameMode.local,mySymbol:s,cpuLevel:level));}}
class CpuSetupPage extends StatefulWidget{const CpuSetupPage({super.key});@override State<CpuSetupPage>createState()=>_CpuSetupPageState();}
class _CpuSetupPageState extends State<CpuSetupPage>{String level='Iniciante';@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(backgroundColor:navy,foregroundColor:Colors.white,title:const Text('Jogar com CPU',style:TextStyle(fontWeight:FontWeight.w900))),body:ListView(padding:const EdgeInsets.all(22),children:[const Text('Nível da CPU',style:TextStyle(color:Colors.white,fontSize:24,fontWeight:FontWeight.w900)),const SizedBox(height:12),for(final x in [['Iniciante','Tranquila'],['Amador','Equilibrada'],['Pro Player','Minimax']])...[_level(x[0],x[1])],const SizedBox(height:18),const Text('Quem começa?',style:TextStyle(color:Colors.white,fontSize:19,fontWeight:FontWeight.w800)),const SizedBox(height:10),Row(children:[Expanded(child:FilledButton(onPressed:()=>push(c,GamePage(mode:GameMode.cpu,mySymbol:'X',cpuLevel:level)),child:const Text('EU — X'))),const SizedBox(width:10),Expanded(child:FilledButton(onPressed:()=>push(c,GamePage(mode:GameMode.cpu,mySymbol:'O',cpuLevel:level)),child:const Text('CPU — X')))])]));Widget _level(String n,String s){final active=n==level;return Padding(padding:const EdgeInsets.only(bottom:10),child:InkWell(onTap:()=>setState(()=>level=n),borderRadius:BorderRadius.circular(18),child:Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:cardBlue,borderRadius:BorderRadius.circular(18),border:Border.all(color:active?Colors.white:Colors.transparent,width:2)),child:Row(children:[Icon(Icons.circle,color:n=='Iniciante'?Colors.green:n=='Amador'?Colors.orange:Colors.red),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(n,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:16)),Text(s,style:const TextStyle(color:Colors.white70,fontSize:12))])),if(active)const Icon(Icons.check,color:Colors.white)]))));}}

enum GameMode{local,cpu,online}
class GamePage extends StatefulWidget{final GameMode mode;final String mySymbol;final WebSocketChannel? channel;final Stream? networkStream;final String roomCode;final String cpuLevel;const GamePage({super.key,required this.mode,required this.mySymbol,this.channel,this.networkStream,this.roomCode='',this.cpuLevel='Iniciante'});@override State<GamePage>createState()=>_GamePageState();}
class _GamePageState extends State<GamePage>{List<String> board=List.filled(9,'');String turn='X',status='',opponent='Jogador 2';String initialTurn='X';int xWins=0,oWins=0,draws=0,timeLeft=600;Timer? timer;StreamSubscription? sub;bool rewarded=false;
@override void initState(){super.initState();initialTurn=widget.mode==GameMode.online?'X':widget.mySymbol;turn=initialTurn;timeLeft=600;if(widget.mode==GameMode.online&&widget.networkStream!=null)sub=widget.networkStream!.listen(_net,onError:(_)=>_status('Conexão perdida.'),onDone:()=>_status('Conexão encerrada.'));_startTimer();if(widget.mode==GameMode.cpu&&widget.mySymbol=='O')Future.delayed(const Duration(milliseconds:400),_cpuMove);}
void _startTimer(){timer?.cancel();timer=Timer.periodic(const Duration(seconds:1),(t){if(!mounted)return;if(timeLeft<=1){t.cancel();setState((){timeLeft=0;status='Tempo esgotado!';});_reward('loss');}else setState(()=>timeLeft--);});}
@override void dispose(){timer?.cancel();sub?.cancel();widget.channel?.sink.close();super.dispose();}
void _status(String s){if(mounted)setState(()=>status=s);}
void _net(dynamic raw){try{final d=jsonDecode(raw as String) as Map<String,dynamic>;if(d['type']=='state'){setState((){board=List<String>.from(d['board']??List.filled(9,''));turn='${d['turn']??'X'}';status='${d['status']??''}';opponent='${d['opponent']??opponent}';xWins=int.tryParse('${d['xWins']}')??xWins;oWins=int.tryParse('${d['oWins']}')??oWins;draws=int.tryParse('${d['draws']}')??draws;timeLeft=int.tryParse('${d['timeLeft']}')??timeLeft;});if(status.isNotEmpty)_reward(status=='Empate!'?'draw':status.startsWith(widget.mySymbol)?'win':'loss');}if(d['type']=='profile')PlayerSession.profile=d['profile']??PlayerSession.profile;}catch(_) {}}
void tap(int i){if(board[i].isNotEmpty||status.isNotEmpty)return;if(widget.mode==GameMode.online){if(turn!=widget.mySymbol)return;widget.channel?.sink.add(jsonEncode({'type':'move','index':i}));return;}if(widget.mode==GameMode.cpu&&turn!=widget.mySymbol)return;setState((){board[i]=turn;_afterMove();});if(widget.mode==GameMode.cpu&&status.isEmpty&&turn!=widget.mySymbol)Future.delayed(const Duration(milliseconds:300),_cpuMove);}
void _afterMove(){final w=winnerOf(board);if(w!=null){status='$w venceu!';if(w=='X')xWins++;else oWins++;_reward(w==widget.mySymbol?'win':'loss');return;}if(board.every((x)=>x.isNotEmpty)){status='Empate!';draws++;_reward('draw');return;}turn=turn=='X'?'O':'X';}
void _reward(String r){if(rewarded)return;rewarded=true;PlayerSession.gameReward(r);}
void _cpuMove(){if(!mounted||widget.mode!=GameMode.cpu||status.isNotEmpty||turn==widget.mySymbol)return;final cpu=widget.mySymbol=='X'?'O':'X';final m=bestMoveForLevel(board,cpu,widget.cpuLevel);if(m<0)return;setState((){board[m]=cpu;_afterMove();});}
void reset(){timer?.cancel();setState((){board=List.filled(9,'');turn=initialTurn;status='';timeLeft=600;rewarded=false;});_startTimer();if(widget.mode==GameMode.online)widget.channel?.sink.add(jsonEncode({'type':'reset'}));else if(widget.mode==GameMode.cpu&&widget.mySymbol=='O')Future.delayed(const Duration(milliseconds:300),_cpuMove);}
@override
Widget build(BuildContext c) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      title: Text(widget.mode == GameMode.online ? 'Sala ${widget.roomCode}' : 'Partida', style: const TextStyle(fontWeight: FontWeight.w900)),
    ),
    body: Container(
      decoration: backgroundDecoration(),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
          child: Column(children: [
            Row(children: [
              Expanded(child: _player('Jogador X', 'X', turn == 'X', xWins)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('VS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
              Expanded(child: _player(widget.mode == GameMode.cpu ? 'CPU' : opponent, 'O', turn == 'O', oWins)),
            ]),
            const SizedBox(height: 8),
            Text('⏱ ${timeLeft ~/ 60}:${(timeLeft % 60).toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Expanded(child: Center(child: AspectRatio(aspectRatio: 1, child: _board()))),
            const SizedBox(height: 8),
            Text(status.isEmpty ? 'Vez de $turn' : status, style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: FilledButton.icon(onPressed: reset, icon: const Icon(Icons.refresh), label: const Text('Nova partida'))),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white54)), onPressed: () => Navigator.pop(c), icon: const Icon(Icons.arrow_back), label: const Text('Voltar'))),
            ]),
          ]),
        ),
      ),
    ),
  );
}
Widget _player(String n,String s,bool active,int wins)=>Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(color:active?blue:cardBlue.withValues(alpha:.65),borderRadius:BorderRadius.circular(17),border:Border.all(color:active?Colors.white:Colors.transparent)),child:Row(children:[CircleAvatar(backgroundColor:cream,foregroundColor:blue,child:Text(s,style:const TextStyle(fontWeight:FontWeight.w900))),const SizedBox(width:8),Expanded(child:Text('$n  •  $wins',overflow:TextOverflow.ellipsis,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800)))]));
Widget _board() => Container(
  padding: const EdgeInsets.all(8),
  decoration: BoxDecoration(color: cardBlue, borderRadius: BorderRadius.circular(24)),
  child: GridView.builder(
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 9,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4, mainAxisSpacing: 4),
    itemBuilder: (_, i) {
      final v = board[i];
      return Material(
        color: const Color(0xFF4968B8),
        child: InkWell(
          onTap: () => tap(i),
          child: Center(
            child: Text(v, style: TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: v == 'X' ? cream : red)),
          ),
        ),
      );
    },
  ),
);
}
String? winnerOf(List<String>b){const l=[[0,1,2],[3,4,5],[6,7,8],[0,3,6],[1,4,7],[2,5,8],[0,4,8],[2,4,6]];for(final x in l){final v=b[x[0]];if(v.isNotEmpty&&v==b[x[1]]&&v==b[x[2]])return v;}return null;}
int bestMoveForLevel(List<String>b,String cpu,String level){final e=[for(var i=0;i<9;i++)if(b[i].isEmpty)i];if(e.isEmpty)return -1;if(level=='Iniciante'&&Random().nextDouble()<.75)return e[Random().nextInt(e.length)];if(level=='Amador'&&Random().nextDouble()<.28)return e[Random().nextInt(e.length)];return bestMove(b,cpu);}
int bestMove(List<String>b,String cpu){final human=cpu=='X'?'O':'X';var best=-1000,move=-1;for(var i=0;i<9;i++)if(b[i].isEmpty){final n=List<String>.from(b)..[i]=cpu;final s=minimax(n,false,cpu,human);if(s>best){best=s;move=i;}}return move;}
int minimax(List<String>b,bool maxing,String cpu,String human){final w=winnerOf(b);if(w==cpu)return 10;if(w==human)return -10;if(b.every((x)=>x.isNotEmpty))return 0;if(maxing){var best=-1000;for(var i=0;i<9;i++)if(b[i].isEmpty){final n=List<String>.from(b)..[i]=cpu;best=max(best,minimax(n,false,cpu,human));}return best;}var best=1000;for(var i=0;i<9;i++)if(b[i].isEmpty){final n=List<String>.from(b)..[i]=human;best=min(best,minimax(n,true,cpu,human));}return best;}

class MultiplayerPage extends StatelessWidget{const MultiplayerPage({super.key});@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(backgroundColor:navy,foregroundColor:Colors.white,title:const Text('Multijogador',style:TextStyle(fontWeight:FontWeight.w900))),body:ListView(padding:const EdgeInsets.all(20),children:[_a(c,Icons.phone_android,'2 jogadores no mesmo celular',()=>push(c,const StartPage(title:'Partida local',mode:'local'))),const SizedBox(height:12),_a(c,Icons.search,'Encontrar jogador',()=>push(c,const OnlinePage(findMatch:true))),const SizedBox(height:12),_a(c,Icons.code,'Criar/entrar com código',()=>push(c,const OnlinePage()))]));Widget _a(BuildContext c,IconData i,String t,VoidCallback f)=>Card(color:cardBlue,child:ListTile(onTap:f,leading:CircleAvatar(backgroundColor:cream,foregroundColor:blue,child:Icon(i)),title:Text(t,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),trailing:const Icon(Icons.chevron_right,color:Colors.white)));}

class OnlinePage extends StatefulWidget{final bool findMatch;const OnlinePage({super.key,this.findMatch=false});@override State<OnlinePage>createState()=>_OnlinePageState();}
class _OnlinePageState extends State<OnlinePage>{final code=TextEditingController();String start='X';bool busy=false;String message='';WebSocketChannel? ch;Stream? stream;StreamSubscription? waitSub;@override void initState(){super.initState();if(widget.findMatch)Future.delayed(const Duration(milliseconds:300),()=>connect('find'));}@override void dispose(){waitSub?.cancel();ch?.sink.close();code.dispose();super.dispose();}Future<void>connect(String action)async{if(busy)return;setState(()=>busy=true);try{final c=WebSocketChannel.connect(Uri.parse(wsBase));await c.ready;final s=c.stream.asBroadcastStream();ch=c;stream=s;c.sink.add(jsonEncode({'type':action,'code':code.text.trim().toUpperCase(),'id':PlayerSession.id,'name':PlayerSession.name,'start':start}));final d=jsonDecode(await s.first.timeout(const Duration(seconds:60)) as String) as Map<String,dynamic>;if(d['type']=='waiting'){code.text='${d['code']}';setState(()=>message='Sala criada: ${d['code']} — compartilhe com o amigo.');setState(()=>busy=false);waitSub=s.listen((raw){try{final x=jsonDecode(raw as String) as Map<String,dynamic>;if(x['type']=='matched'&&mounted)_open(c,s,x);}catch(_){}});}else if(d['type']=='matched'){_open(c,s,d);}else{setState(()=>message='${d['message']??'Erro'}');setState(()=>busy=false);}}catch(_){setState((){busy=false;message='Servidor indisponível. Tente novamente.';});}}
void _open(WebSocketChannel c,Stream s,Map<String,dynamic>d){if(!mounted)return;push(context,GamePage(mode:GameMode.online,mySymbol:'${d['symbol']}',channel:c,networkStream:s,roomCode:'${d['code']}'));}
  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(backgroundColor: navy, foregroundColor: Colors.white, title: const Text('Online', style: TextStyle(fontWeight: FontWeight.w900))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Quem começa?', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        SegmentedButton<String>(segments: const [ButtonSegment(value: 'X', label: Text('X')), ButtonSegment(value: 'O', label: Text('O'))], selected: {start}, onSelectionChanged: (v) => setState(() => start = v.first)),
        const SizedBox(height: 14),
        TextField(controller: code, style: const TextStyle(color: Colors.white, letterSpacing: 4, fontWeight: FontWeight.w900), decoration: dec('Código da sala')),
        const SizedBox(height: 12),
        FilledButton.icon(onPressed: busy ? null : () => connect('create'), icon: const Icon(Icons.add), label: const Text('Criar sala')),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: busy ? null : () => connect('join'), icon: const Icon(Icons.login), label: const Text('Entrar')),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: busy ? null : () => connect('find'), icon: const Icon(Icons.search), label: const Text('Encontrar jogador')),
        if (busy) const Padding(padding: EdgeInsets.all(18), child: Center(child: CircularProgressIndicator())),
        if (message.isNotEmpty) Padding(padding: const EdgeInsets.all(15), child: Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
      ],
      ),
    );
  }
}
class StorePage extends StatefulWidget{const StorePage({super.key});@override State<StorePage>createState()=>_StorePageState();}
class _StorePageState extends State<StorePage>{String filter='theme';Future<void> action(Map<String,dynamic>item)async{final owned=List<String>.from(PlayerSession.profile['owned']??[]);final isOwned=owned.contains(item['id']);final err=isOwned?await PlayerSession.equip(item['id']):await PlayerSession.buy(item['id']);if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(err??(isOwned?'Equipado!':'Comprado!'))));setState((){});}}@override Widget build(BuildContext c){final items=[...PlayerSession.store.where((x)=>x['type']==filter),...PlayerSession.packages.where((x)=>filter=='pack')];return Scaffold(appBar:AppBar(backgroundColor:navy,foregroundColor:Colors.white,title:const Text('Loja',style:TextStyle(fontWeight:FontWeight.w900))),body:ListView(padding:const EdgeInsets.all(16),children:[Card(color:cardBlue,child:Padding(padding:const EdgeInsets.all(14),child:Column(children:[const Text('Prévia dos kits',style:TextStyle(color:Colors.white,fontSize:20,fontWeight:FontWeight.w900)),const SizedBox(height:10),Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[_preview('X','O'),_preview('O','X'),_preview('Fundo','',bg:const Color(0xFF193B80))])]))),const SizedBox(height:12),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[for(final x in [['theme','Temas'],['xstyle','Estilos X'],['ostyle','Estilos O'],['pack','Pacotes']])Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(x[1]),selected:filter==x[0],onSelected:(_)=>setState(()=>filter=x[0])))])),const SizedBox(height:12),...items.map((i)=>_card(c,i))]));}
Widget _preview(String a,String b,{Color? bg})=>Container(width:92,height:72,decoration:BoxDecoration(color:bg??cardBlue,borderRadius:BorderRadius.circular(14)),child:Center(child:Text(a=='Fundo'?'🌄':a,style:TextStyle(color:a=='X'?cream:red,fontSize:30,fontWeight:FontWeight.w900))));Widget _card(BuildContext c,Map<String,dynamic>i){final owned=List<String>.from(PlayerSession.profile['owned']??[]).contains(i['id']);return Card(color:cardBlue,child:Padding(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[_preview('${i['name']}',i['type'] as String,bg:i['bgColor']!=null?parseColor(i['bgColor']):null),const SizedBox(height:8),Text(i['name']??'Item',style:const TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.w900)),Text(i['description']??'',style:const TextStyle(color:Colors.white70)),const SizedBox(height:8),Row(children:[Text('${i['price']??0} moedas',style:const TextStyle(color:Colors.amber,fontWeight:FontWeight.w900)),const Spacer(),FilledButton(onPressed:()=>action(i),child:Text(owned?'Equipar':'Comprar'))])])));}}
Color parseColor(dynamic s){try{var h='${s??''}'.replaceAll('#','');if(h.length==6)h='FF$h';return Color(int.parse(h,radix:16));}catch(_){return cardBlue;}}

class RedeemPage extends StatefulWidget{const RedeemPage({super.key});@override State<RedeemPage>createState()=>_RedeemPageState();}class _RedeemPageState extends State<RedeemPage>{final c=TextEditingController();bool busy=false;@override Widget build(BuildContext x)=>Scaffold(appBar:AppBar(backgroundColor:navy,foregroundColor:Colors.white,title:const Text('Código de recompensa')),body:Padding(padding:const EdgeInsets.all(20),child:Column(children:[const Text('Digite um código criado pelo administrador.',style:TextStyle(color:Colors.white70)),const SizedBox(height:18),TextField(controller:c,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,letterSpacing:3),decoration:dec('EXEMPLO2026')),const SizedBox(height:12),FilledButton.icon(onPressed:busy?null:()async{setState(()=>busy=true);final m=await PlayerSession.redeem(c.text);if(mounted){setState(()=>busy=false);ScaffoldMessenger.of(x).showSnackBar(SnackBar(content:Text(m??'Erro')));}},icon:const Icon(Icons.card_giftcard),label:const Text('Resgatar')),])));@override void dispose(){c.dispose();super.dispose();}}

class FriendsPage extends StatefulWidget{const FriendsPage({super.key});@override State<FriendsPage>createState()=>_FriendsPageState();}
class _FriendsPageState extends State<FriendsPage>{List<dynamic> incoming=[],friends=[];final id=TextEditingController();@override void initState(){super.initState();load();}Future<void>load()async{try{final r=await http.get(Uri.parse('$apiBase/api/friends?playerId=${Uri.encodeComponent(PlayerSession.id)}'));final d=jsonDecode(r.body);if(mounted)setState((){incoming=d['incoming']??[];friends=d['friends']??[];});}catch(_){}}Future<void>send()async{final r=await http.post(Uri.parse('$apiBase/api/friend/request'),headers:{'Content-Type':'application/json'},body:jsonEncode({'fromId':PlayerSession.id,'toId':id.text.trim().toUpperCase()}));final d=jsonDecode(r.body);if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(d['error']??'Pedido enviado!')));id.clear();load();}Future<void>accept(String rid)async{final r=await http.post(Uri.parse('$apiBase/api/friend/accept'),headers:{'Content-Type':'application/json'},body:jsonEncode({'playerId':PlayerSession.id,'requestId':rid}));if(r.statusCode==200)load();}@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(backgroundColor:navy,foregroundColor:Colors.white,title:const Text('Amigos',style:TextStyle(fontWeight:FontWeight.w900))),body:ListView(padding:const EdgeInsets.all(18),children:[Card(color:cardBlue,child:Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Seu ID',style:TextStyle(color:Colors.white70)),SelectableText(PlayerSession.id,style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:6),const Text('Esse ID identifica sua conta no jogo.',style:TextStyle(color:Colors.white60))]))),const SizedBox(height:12),TextField(controller:id,style:const TextStyle(color:Colors.white),decoration:dec('ID do amigo')),const SizedBox(height:8),FilledButton.icon(onPressed:send,icon:const Icon(Icons.person_add),label:const Text('Enviar pedido')),const SizedBox(height:20),const Text('SOLICITAÇÕES',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),...incoming.map((r)=>Card(color:cardBlue,child:ListTile(title:Text(r['from']['name']??'',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),subtitle:Text(r['from']['id']??'',style:const TextStyle(color:Colors.white60)),trailing:FilledButton(onPressed:()=>accept(r['id']),child:const Text('Aceitar'))))),const SizedBox(height:20),const Text('AMIGOS',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),...friends.map((f)=>ListTile(leading:const CircleAvatar(backgroundColor:Colors.green),title:Text(f['name']??'',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),subtitle:Text(f['id']??'',style:const TextStyle(color:Colors.white60))))]));@override void dispose(){id.dispose();super.dispose();}}

void runAdminApp()=>runApp(const AdminApp());
class AdminApp extends StatelessWidget{const AdminApp({super.key});@override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:navy,colorScheme:ColorScheme.fromSeed(seedColor:blue)),home:const AdminLoginPage());}
class AdminLoginPage extends StatefulWidget{const AdminLoginPage({super.key});@override State<AdminLoginPage>createState()=>_AdminLoginPageState();}
class _AdminLoginPageState extends State<AdminLoginPage> {
  final e = TextEditingController(text: 'rhuanprodutor3@gmail.com');
  final p = TextEditingController();
  bool busy = false;
  String error = '';
  @override Widget build(BuildContext c) => Scaffold(
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            color: cardBlue,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.admin_panel_settings, color: Colors.white, size: 64),
                const Text('Painel do Dono', style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
                TextField(controller: e, style: const TextStyle(color: Colors.white), decoration: dec('E-mail')),
                const SizedBox(height: 10),
                TextField(controller: p, obscureText: true, style: const TextStyle(color: Colors.white), decoration: dec('Senha')),
                if (error.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Text(error, style: const TextStyle(color: Colors.redAccent))),
                const SizedBox(height: 10),
                FilledButton(onPressed: busy ? null : login, child: const Text('Entrar')),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
  Future<void> login() async {
    setState(() => busy = true);
    try {
      final r = await http.post(Uri.parse('$apiBase/api/admin/login'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': e.text, 'password': p.text}));
      final d = jsonDecode(r.body);
      if (r.statusCode == 200) { if (mounted) push(context, AdminDashboard(token: d['token'])); }
      else if (mounted) setState(() => error = d['error'] ?? 'Falha');
    } catch (_) { if (mounted) setState(() => error = 'Servidor indisponível.'); }
    if (mounted) setState(() => busy = false);
  }
}
class AdminDashboard extends StatefulWidget {
  final String token;
  const AdminDashboard({super.key, required this.token});
  @override State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> users = [], items = [], packs = [], codes = [];
  Future<Map<String,String>> get headers async => {'Authorization':'Bearer ${widget.token}'};
  Future<void> load() async {
    try {
      final h = await headers;
      final u = await http.get(Uri.parse('$apiBase/api/admin/users'), headers:h);
      final s = await http.get(Uri.parse('$apiBase/api/admin/store'), headers:h);
      if (u.statusCode != 200 || s.statusCode != 200) return;
      final ud = jsonDecode(u.body), sd = jsonDecode(s.body);
      if (mounted) setState(() { users = ud['users'] ?? []; items = sd['items'] ?? []; packs = sd['packages'] ?? []; codes = sd['codes'] ?? []; });
    } catch (_) {}
  }
  @override void initState(){super.initState();load();}

  Future<void> adjust(Map<String,dynamic> u) async {
    final co=TextEditingController(text:'${u['coins']}'), xp=TextEditingController(text:'${u['xp']}'), lv=TextEditingController(text:'${u['level']}');
    await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text(u['name']??u['id']),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:co,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Moedas')),TextField(controller:xp,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'XP')),TextField(controller:lv,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Nível'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancelar')),FilledButton(onPressed:()async{final h=await headers;await http.post(Uri.parse('$apiBase/api/admin/user-adjust'),headers:{...h,'Content-Type':'application/json'},body:jsonEncode({'playerId':u['id'],'coins':int.tryParse(co.text),'xp':int.tryParse(xp.text),'level':int.tryParse(lv.text)}));if(ctx.mounted)Navigator.pop(ctx);load();},child:const Text('Salvar'))]));
  }

  Future<void> newCode() async {
    final c = TextEditingController();
    final a = TextEditingController();
    final m = TextEditingController();
    String type = 'coins';
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Criar código'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: c, decoration: const InputDecoration(labelText: 'Código')),
            DropdownButton<String>(value: type, items: const [
              DropdownMenuItem(value: 'coins', child: Text('Moedas')),
              DropdownMenuItem(value: 'xp', child: Text('XP')),
            ], onChanged: (v) { if (v != null) setLocal(() => type = v); }),
            TextField(controller: a, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade')),
            TextField(controller: m, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Limite de usos (vazio = ilimitado)')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () async {
              final h = await headers;
              await http.post(Uri.parse('$apiBase/api/admin/code'), headers: {...h, 'Content-Type': 'application/json'}, body: jsonEncode({'code': c.text, 'rewardType': type, 'amount': int.tryParse(a.text) ?? 0, 'maxUses': m.text}));
              if (ctx.mounted) Navigator.pop(ctx);
              load();
            }, child: const Text('Criar')),
          ],
        ),
      ),
    );
  }

  Future<void> newTheme() async {
    final n = TextEditingController(), p = TextEditingController(), b = TextEditingController(text: '#081A45'), a = TextEditingController(text: '#4D6FC5'), img = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo tema'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: n, decoration: const InputDecoration(labelText: 'Nome')),
          TextField(controller: p, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Preço')),
          TextField(controller: b, decoration: const InputDecoration(labelText: 'Fundo sólido (#hex)')),
          TextField(controller: a, decoration: const InputDecoration(labelText: 'Paleta/acento (#hex)')),
          TextField(controller: img, decoration: const InputDecoration(labelText: 'Imagem de fundo (URL)')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () async {
            final h = await headers;
            await http.post(Uri.parse('$apiBase/api/admin/theme'), headers: {...h, 'Content-Type': 'application/json'}, body: jsonEncode({'name': n.text, 'price': int.tryParse(p.text) ?? 0, 'bgColor': b.text, 'accent': a.text, 'imageUrl': img.text}));
            if (ctx.mounted) Navigator.pop(ctx);
            load();
          }, child: const Text('Criar')),
        ],
      ),
    );
  }

  Future<void> newPack() async {
    final selected = <String>{};
    final n = TextEditingController(), p = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Criar pacote'),
          content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: n, decoration: const InputDecoration(labelText: 'Nome do pacote')),
            TextField(controller: p, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Preço')),
            const SizedBox(height: 10),
            const Align(alignment: Alignment.centerLeft, child: Text('Selecione os itens:')),
            for (final x in items) CheckboxListTile(
              value: selected.contains(x['id']),
              onChanged: (v) => setLocal(() { if (v == true) selected.add(x['id']); else selected.remove(x['id']); }),
              title: Text(x['name'] ?? ''),
              subtitle: Text('${x['type']} • ${x['price']} moedas'),
            ),
          ]))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(onPressed: () async {
              final h = await headers;
              await http.post(Uri.parse('$apiBase/api/admin/pack'), headers: {...h, 'Content-Type': 'application/json'}, body: jsonEncode({'name': n.text, 'price': int.tryParse(p.text) ?? 0, 'items': selected.toList()}));
              if (ctx.mounted) Navigator.pop(ctx);
              load();
            }, child: const Text('Criar pacote')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('Administração', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [IconButton(onPressed: load, icon: const Icon(Icons.refresh))],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(color: cardBlue, child: Padding(padding: const EdgeInsets.all(14), child: Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(onPressed: newCode, icon: const Icon(Icons.qr_code), label: const Text('Novo código')),
          FilledButton.icon(onPressed: newTheme, icon: const Icon(Icons.palette), label: const Text('Novo tema')),
          FilledButton.icon(onPressed: newPack, icon: const Icon(Icons.inventory_2), label: const Text('Novo pacote')),
        ]))),
        const SizedBox(height: 18),
        Text('USUÁRIOS (${users.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ...users.map((u) => Card(color: cardBlue, child: ListTile(
          title: Text(u['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          subtitle: Text('${u['id']} • ${u['coins']} moedas • ${u['xp']} XP • Nv.${u['level']}', style: const TextStyle(color: Colors.white70)),
          trailing: IconButton(color: Colors.white, onPressed: () => adjust(u), icon: const Icon(Icons.edit)),
        ))),
        const SizedBox(height: 18),
        Text('CÓDIGOS (${codes.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ...codes.map((x) => ListTile(title: Text(x['code'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), subtitle: Text('${x['amount']} ${x['rewardType']} • usos ${x['uses']}', style: const TextStyle(color: Colors.white60)))),
        const SizedBox(height: 18),
        Text('TEMAS E ITENS (${items.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ...items.map((x) => ListTile(title: Text(x['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), subtitle: Text('${x['type']} • ${x['price']} moedas', style: const TextStyle(color: Colors.white60)))),
        const SizedBox(height: 18),
        Text('PACOTES (${packs.length})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        ...packs.map((x) => ListTile(title: Text(x['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), subtitle: Text('${x['price']} moedas • ${(x['items'] ?? []).length} itens', style: const TextStyle(color: Colors.white60)))),
      ]),
    );
  }
}
