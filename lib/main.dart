import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';

const navy=Color(0xFF081A45), blue=Color(0xFF4D6FC5), cardBlue=Color(0xFF405EAE), cream=Color(0xFFF8F5E9), red=Color(0xFFF4555B);
const paper=Color(0xFFF4EBDD), paperCard=Color(0xFFFBF7EE), ink=Color(0xFF211E1A), paperLine=Color(0xFFD8CFBF), paperMuted=Color(0xFF665F55);

class PaperShell extends StatelessWidget{final Widget child;final EdgeInsetsGeometry padding;const PaperShell({super.key,required this.child,this.padding=EdgeInsets.zero});@override Widget build(BuildContext c)=>Container(color:paper,child:CustomPaint(painter:_PaperPainter(),child:SafeArea(child:Padding(padding:padding,child:child))));}
class _PaperPainter extends CustomPainter{ @override void paint(Canvas canvas,Size size){final line=Paint()..color=paperLine..strokeWidth=.7;for(double y=24;y<size.height;y+=30){canvas.drawLine(Offset(0,y),Offset(size.width,y),line);}final inkPaint=Paint()..color=ink..strokeWidth=2..style=PaintingStyle.stroke..strokeCap=StrokeCap.round;final x=size.width-42;canvas.drawLine(Offset(x-10,48),Offset(x+10,38),inkPaint);canvas.drawLine(Offset(x+10,38),Offset(x+5,38),inkPaint);canvas.drawLine(Offset(x+10,38),Offset(x+8,44),inkPaint);canvas.drawLine(Offset(28,size.height-34),Offset(50,size.height-46),inkPaint);canvas.drawLine(Offset(50,size.height-46),Offset(44,size.height-45),inkPaint);canvas.drawLine(Offset(50,size.height-46),Offset(48,size.height-40),inkPaint);} @override bool shouldRepaint(covariant CustomPainter oldDelegate)=>false;}

Color parseColor(dynamic value){
  final s='${value??''}'.trim().replaceAll('#','');
  final hex=s.length==6?'FF$s':s;
  final n=int.tryParse(hex,radix:16);
  return Color(n??0xFF081A45);
}

TextStyle paperH1({double size=30})=>TextStyle(color:ink,fontSize:size,fontWeight:FontWeight.w900,fontStyle:FontStyle.italic);

const apiBase='https://jogodavelha-6neh.onrender.com';
const wsBase='wss://jogodavelha-6neh.onrender.com';

class PlayerSession{
  static const String appVersion='3.1.0';
  static String id='';
  static String name='Player';
  static Map<String,dynamic> profile={};
  static List<dynamic> store=[];
  static List<dynamic> packages=[];
  static Map<String,dynamic> config={};
  static List<dynamic> notifications=[];
  static Future<void> init() async{
    final p=await SharedPreferences.getInstance();
    id=p.getString('player_id')??'JDV-${List.generate(8,(_)=>'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'[Random().nextInt(36)]).join()}';
    name=p.getString('player_name')??'Player';
    await p.setString('player_id',id);
    await refresh();
    await loadConfig();
    await loadNotifications();
  }
  static Future<void> setName(String value) async{name=value.trim().isEmpty?'Player':value.trim();final p=await SharedPreferences.getInstance();await p.setString('player_name',name);await refresh();}
  static Future<void> refresh() async{try{final r=await http.post(Uri.parse('$apiBase/api/profile'),headers:{'Content-Type':'application/json'},body:jsonEncode({'playerId':id,'name':name}));if(r.statusCode==200)profile=jsonDecode(r.body)['profile']??profile;final s=await http.get(Uri.parse('$apiBase/api/store'));if(s.statusCode==200){final d=jsonDecode(s.body);store=d['items']??[];packages=d['packages']??[];}}catch(_){} }
  static Future<void> loadConfig() async{try{final r=await http.get(Uri.parse('$apiBase/api/config'));if(r.statusCode==200)config=jsonDecode(r.body) as Map<String,dynamic>;}catch(_){} }
  static Future<void> loadNotifications() async{try{final r=await http.get(Uri.parse('$apiBase/api/notifications?playerId=${Uri.encodeComponent(id)}'));if(r.statusCode==200)notifications=(jsonDecode(r.body)['items']??[]) as List<dynamic>;}catch(_){} }
  static Future<String?> redeem(String code) async{try{final r=await http.post(Uri.parse('$apiBase/api/redeem'),headers:{'Content-Type':'application/json'},body:jsonEncode({'playerId':id,'code':code}));final d=jsonDecode(r.body);if(r.statusCode==200){profile=d['profile'];await loadNotifications();return d['message'];}return d['error']??'Código inválido.';}catch(_){return 'Servidor indisponível.';}}
  static Future<String?> buy(String itemId) async{try{final r=await http.post(Uri.parse('$apiBase/api/purchase'),headers:{'Content-Type':'application/json'},body:jsonEncode({'playerId':id,'itemId':itemId}));final d=jsonDecode(r.body);if(r.statusCode==200){profile=d['profile'];return null;}return d['error']??'Não foi possível comprar.';}catch(_){return 'Servidor indisponível.';}}
  static Future<String?> equip(String itemId) async{try{final r=await http.post(Uri.parse('$apiBase/api/equip'),headers:{'Content-Type':'application/json'},body:jsonEncode({'playerId':id,'itemId':itemId}));final d=jsonDecode(r.body);if(r.statusCode==200){profile=d['profile'];return null;}return d['error']??'Não foi possível equipar.';}catch(_){return 'Servidor indisponível.';}}
  static Future<String?> sendCoins(String toId,int amount) async{try{final r=await http.post(Uri.parse('$apiBase/api/present/coins'),headers:{'Content-Type':'application/json'},body:jsonEncode({'fromId':id,'toId':toId,'amount':amount}));final d=jsonDecode(r.body);if(r.statusCode==200){profile=d['profile'];await loadNotifications();return null;}return d['error']??'Não foi possível enviar.';}catch(_){return 'Servidor indisponível.';}}
  static Future<String?> sendItem(String toId,String itemId) async{try{final r=await http.post(Uri.parse('$apiBase/api/present/item'),headers:{'Content-Type':'application/json'},body:jsonEncode({'fromId':id,'toId':toId,'itemId':itemId}));final d=jsonDecode(r.body);if(r.statusCode==200){profile=d['profile'];await loadNotifications();return null;}return d['error']??'Não foi possível enviar o presente.';}catch(_){return 'Servidor indisponível.';}}
  static Future<void> markNotificationRead(String idv) async{try{await http.post(Uri.parse('$apiBase/api/notifications/read'),headers:{'Content-Type':'application/json'},body:jsonEncode({'playerId':id,'id':idv}));}catch(_){} }
  static Future<void> gameReward(String result) async{try{final r=await http.post(Uri.parse('$apiBase/api/game/result'),headers:{'Content-Type':'application/json'},body:jsonEncode({'playerId':id,'result':result}));if(r.statusCode==200)profile=jsonDecode(r.body)['profile'];}catch(_) {} }
  static bool get maintenance=>config['maintenance']==true;
  static bool get hasUpdate=>versionCompare('${config['latestVersion']??appVersion}',appVersion)>0 && '${config['updateUrl']??''}'.isNotEmpty;
  static int get unreadCount=>notifications.where((n)=>n['read']!=true).length;
  static Future<String?> downloadUpdate() async{
    try{
      final url='${config['updateUrl']??''}'.startsWith('http')?'${config['updateUrl']}':'$apiBase${config['updateUrl']??'/api/update/apk'}';
      final r=await http.get(Uri.parse(url));
      if(r.statusCode!=200)return 'Não foi possível baixar a atualização.';
      final file=File('${Directory.systemTemp.path}${Platform.pathSeparator}JogoDaVelha-update.apk');
      await file.writeAsBytes(r.bodyBytes,flush:true);
      await OpenFilex.open(file.path,type:'application/vnd.android.package-archive');
      return null;
    }catch(e){return 'Falha ao abrir a atualização.';}
  }
}

int versionCompare(String a,String b){
  final aa=a.split('.').map((x)=>int.tryParse(x.replaceAll(RegExp(r'[^0-9]'),''))??0).toList();
  final bb=b.split('.').map((x)=>int.tryParse(x.replaceAll(RegExp(r'[^0-9]'),''))??0).toList();
  for(var i=0;i<max(aa.length,bb.length);i++){final x=i<aa.length?aa[i]:0;final y=i<bb.length?bb[i]:0;if(x!=y)return x.compareTo(y);}return 0;
}

Map<String,dynamic>? equippedTheme(){final id='${PlayerSession.profile['equipped']?['theme']??'theme_classic'}';for(final x in PlayerSession.store){if(x['id']==id)return Map<String,dynamic>.from(x);}return null;}
Color currentBackground()=>parseColor(equippedTheme()?['bgColor']??'#081A45');
String currentBackgroundImage()=> '${equippedTheme()?['imageUrl']??''}';
BoxDecoration backgroundDecoration(){final image=currentBackgroundImage();return BoxDecoration(color:currentBackground(),image:image.isEmpty?null:DecorationImage(image:NetworkImage(image),fit:BoxFit.cover));}

void push(BuildContext context, Widget page){Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));}
InputDecoration dec(String label)=>InputDecoration(labelText:label,labelStyle:const TextStyle(color:Colors.white70),enabledBorder:const UnderlineInputBorder(borderSide:BorderSide(color:Colors.white38)),focusedBorder:const UnderlineInputBorder(borderSide:BorderSide(color:Colors.white)));
Future<void> main() async{WidgetsFlutterBinding.ensureInitialized();await PlayerSession.init();runApp(const JogoDaVelhaApp());}

class JogoDaVelhaApp extends StatelessWidget{const JogoDaVelhaApp({super.key});@override Widget build(BuildContext context)=>MaterialApp(debugShowCheckedModeBanner:false,title:'Jogo Da Velha',theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:navy,colorScheme:ColorScheme.fromSeed(seedColor:blue)),home:const GatePage());}

class GatePage extends StatefulWidget{const GatePage({super.key});@override State<GatePage> createState()=>_GatePageState();}
class _GatePageState extends State<GatePage>{Timer? timer;@override void initState(){super.initState();timer=Timer.periodic(const Duration(seconds:15),(_)=>_check());}@override void dispose(){timer?.cancel();super.dispose();}Future<void>_check()async{await PlayerSession.loadConfig();await PlayerSession.refresh();if(mounted)setState((){});} @override Widget build(BuildContext c)=>PlayerSession.maintenance?const MaintenancePage():const HomePage();}

class MaintenancePage extends StatefulWidget{const MaintenancePage({super.key});@override State<MaintenancePage>createState()=>_MaintenancePageState();}
class _MaintenancePageState extends State<MaintenancePage>{Timer?timer;@override void initState(){super.initState();timer=Timer.periodic(const Duration(seconds:10),(_)=>check());}@override void dispose(){timer?.cancel();super.dispose();}Future<void>check()async{await PlayerSession.loadConfig();if(!PlayerSession.maintenance&&mounted)setState((){});}@override Widget build(BuildContext c){final msg=PlayerSession.config['maintenanceMessage']?.toString()??'O jogo está em manutenção.';return Scaffold(backgroundColor:paper,body:PaperShell(padding:const EdgeInsets.all(28),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:520),child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('↘ feito à mão, feito com carinho',style:TextStyle(color:paperMuted,fontSize:11,fontStyle:FontStyle.italic)),const SizedBox(height:12),Image.asset('assets/logo.png',width:130,height:130),Text('Jogo Da Velha',style:paperH1(size:38)),const SizedBox(height:8),const Text('MANUTENÇÃO',style:TextStyle(color:ink,fontSize:13,fontWeight:FontWeight.w900,letterSpacing:2)),const SizedBox(height:10),Container(width:70,height:1,color:ink),const SizedBox(height:18),Text(msg,textAlign:TextAlign.center,style:const TextStyle(color:ink,fontSize:14)),const SizedBox(height:22),OutlinedButton.icon(onPressed:()=>push(c,const AdminLoginPage()),style:OutlinedButton.styleFrom(foregroundColor:ink,side:const BorderSide(color:ink),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(3))),icon:const Icon(Icons.lock_outline),label:const Text('Acesso autorizado')),const SizedBox(height:8),const Text('Apenas administradores autorizados podem entrar durante a manutenção.',textAlign:TextAlign.center,style:TextStyle(color:paperMuted,fontSize:11))])))));}}

class HomePage extends StatefulWidget{const HomePage({super.key});@override State<HomePage>createState()=>_HomePageState();}
class _HomePageState extends State<HomePage>{final nameCtrl=TextEditingController();Timer? syncTimer;@override void initState(){super.initState();nameCtrl.text=PlayerSession.name;syncTimer=Timer.periodic(const Duration(seconds:5),(_)=>reload());}@override void dispose(){syncTimer?.cancel();nameCtrl.dispose();super.dispose();}Future<void> reload()async{await PlayerSession.loadConfig();await PlayerSession.refresh();await PlayerSession.loadNotifications();if(mounted)setState((){});}
Widget stat(String label,String value,IconData icon)=>Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:9),decoration:BoxDecoration(color:paperCard,border:Border.all(color:ink,width:1),borderRadius:BorderRadius.circular(4)),child:Row(mainAxisSize:MainAxisSize.min,children:[Icon(icon,size:17,color:ink),const SizedBox(width:6),Text(value,style:const TextStyle(color:ink,fontWeight:FontWeight.w900)),const SizedBox(width:5),Text(label,style:const TextStyle(color:paperMuted,fontSize:11))]));
Widget menuPaper(BuildContext c,IconData icon,String title,String note,VoidCallback f)=>Material(color:Colors.transparent,child:InkWell(onTap:f,child:Container(margin:const EdgeInsets.only(bottom:10),padding:const EdgeInsets.fromLTRB(15,13,12,13),decoration:BoxDecoration(color:paperCard,border:Border.all(color:ink,width:1),borderRadius:BorderRadius.circular(5)),child:Row(children:[Container(width:38,height:38,alignment:Alignment.center,decoration:BoxDecoration(border:Border.all(color:ink),borderRadius:BorderRadius.circular(4)),child:Icon(icon,color:ink)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(color:ink,fontSize:16,fontWeight:FontWeight.w900)),Text(note,style:const TextStyle(color:paperMuted,fontSize:11))])),const Text('↗',style:TextStyle(color:ink,fontSize:20,fontWeight:FontWeight.w900))]))));
@override Widget build(BuildContext context){final p=PlayerSession.profile;return Scaffold(backgroundColor:paper,body:PaperShell(padding:const EdgeInsets.fromLTRB(22,18,22,30),child:RefreshIndicator(onRefresh:reload,color:ink,backgroundColor:paperCard,child:ListView(children:[Row(children:[stat('moedas','${p['coins']??0}',Icons.monetization_on_outlined),const SizedBox(width:7),stat('XP','${p['xp']??0}',Icons.bolt),const SizedBox(width:7),stat('nível','${p['level']??1}',Icons.star_outline),const Spacer(),IconButton(onPressed:()=>push(context,const NotificationsPage()),icon:Badge(label:Text('${PlayerSession.unreadCount}'),isLabelVisible:PlayerSession.unreadCount>0,child:const Icon(Icons.notifications_none,color:ink)))]),const SizedBox(height:25),Center(child:Column(children:[const Text('↘ feito à mão, feito com carinho',style:TextStyle(color:paperMuted,fontSize:11,fontStyle:FontStyle.italic)),const SizedBox(height:2),Image.asset('assets/logo.png',width:175,height:150,fit:BoxFit.contain),const Text('Jogo',style:TextStyle(color:ink,fontSize:45,fontWeight:FontWeight.w900,fontStyle:FontStyle.italic)),const Text('Da Velha',style:TextStyle(color:ink,fontSize:44,fontWeight:FontWeight.w900,fontStyle:FontStyle.italic)),const SizedBox(height:7),Text('Um pequeno jogo criado por Rhuan Gabriel.',style:const TextStyle(color:ink,fontSize:13)),const Text('Simples, artesanal e feito para jogar.',style:const TextStyle(color:ink,fontSize:13))])),const SizedBox(height:24),if(PlayerSession.hasUpdate)Container(padding:const EdgeInsets.all(13),margin:const EdgeInsets.only(bottom:12),decoration:BoxDecoration(color:const Color(0xFFE7D7A6),border:Border.all(color:ink),borderRadius:BorderRadius.circular(4)),child:Row(children:[const Icon(Icons.system_update_alt,color:ink),const SizedBox(width:10),Expanded(child:Text('Nova versão ${PlayerSession.config['latestVersion']} disponível.',style:const TextStyle(color:ink,fontWeight:FontWeight.w800))),TextButton(onPressed:PlayerSession.downloadUpdate,child:const Text('atualizar'))])),Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(border:Border.all(color:ink),borderRadius:BorderRadius.circular(4)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('seu perfil',style:TextStyle(color:paperMuted,fontSize:11)),const SizedBox(height:4),Text(PlayerSession.name,style:paperH1(size:24)),Text('ID ${PlayerSession.id}',style:const TextStyle(color:paperMuted,fontSize:11)),const SizedBox(height:9),TextField(controller:nameCtrl,style:const TextStyle(color:ink),decoration:InputDecoration(labelText:'Nome no jogo',labelStyle:TextStyle(color:paperMuted),enabledBorder:UnderlineInputBorder(borderSide:BorderSide(color:ink)),focusedBorder:UnderlineInputBorder(borderSide:BorderSide(color:ink))),onSubmitted:(v)async{await PlayerSession.setName(v);if(mounted)setState((){});})])),const SizedBox(height:22),const Text('01 — jogar',style:TextStyle(color:paperMuted,fontSize:11)),const SizedBox(height:5),Text('Escolha como jogar.',style:paperH1(size:28)),const SizedBox(height:10),menuPaper(context,Icons.smart_toy_outlined,'Contra a CPU','Iniciante, Amador e Pro Player',()=>push(context,const CpuSetupPage())),menuPaper(context,Icons.groups_outlined,'Multijogador','2 jogadores, salas e partidas online',()=>push(context,const MultiplayerPage())),const SizedBox(height:5),const Text('02 — comunidade',style:TextStyle(color:paperMuted,fontSize:11)),const SizedBox(height:5),menuPaper(context,Icons.storefront_outlined,'Loja','Temas, estilos, pacotes e presentes',()=>push(context,const StorePage())),menuPaper(context,Icons.card_giftcard_outlined,'Presentear jogador','Envie moedas ou itens pelo ID',()=>push(context,const GiftPage())),menuPaper(context,Icons.redeem_outlined,'Código de recompensa','Resgate códigos criados pelo administrador',()=>push(context,const RedeemPage())),menuPaper(context,Icons.person_add_alt_1_outlined,'Amigos','Pedidos, amigos e ID do jogador',()=>push(context,const FriendsPage())),menuPaper(context,Icons.notifications_none,'Notificações','Presentes, recompensas e avisos',()=>push(context,const NotificationsPage())),const SizedBox(height:8),const Text('03 — acesso',style:TextStyle(color:paperMuted,fontSize:11)),const SizedBox(height:5),menuPaper(context,Icons.lock_outline,'Acesso autorizado','Área administrativa protegida',()=>push(context,const AdminLoginPage())),const SizedBox(height:18),const Center(child:Text('Jogo Da Velha • versão 3.1.0',style:TextStyle(color:paperMuted,fontSize:11))) ]))));}
}

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
class _StorePageState extends State<StorePage>{String filter='theme';Future<void> action(Map<String,dynamic>item)async{final owned=List<String>.from(PlayerSession.profile['owned']??[]);final isOwned=owned.contains(item['id']);final err=isOwned?await PlayerSession.equip(item['id']):await PlayerSession.buy(item['id']);if(mounted){ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(err??(isOwned?'Equipado!':'Comprado!'))));setState((){});}}
@override Widget build(BuildContext c){final items=[...PlayerSession.store.where((x)=>x['type']==filter),...PlayerSession.packages.where((x)=>filter=='pack')];return Scaffold(backgroundColor:paper,appBar:AppBar(backgroundColor:paper,foregroundColor:ink,elevation:0,title:Text('Loja',style:paperH1(size:26)),bottom:PreferredSize(preferredSize:const Size.fromHeight(1),child:Container(color:ink,height:1))),body:PaperShell(padding:const EdgeInsets.fromLTRB(18,18,18,28),child:ListView(children:[const Text('03 — loja',style:TextStyle(color:paperMuted,fontSize:11)),const SizedBox(height:4),Text('Escolha algo para deixar seu jogo com a sua cara.',style:paperH1(size:25)),const SizedBox(height:6),Text('Seu saldo: ${PlayerSession.profile['coins']??0} moedas',style:const TextStyle(color:ink,fontWeight:FontWeight.w800)),const SizedBox(height:16),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[for(final x in [['theme','Temas'],['xstyle','Estilos X'],['ostyle','Estilos O'],['pack','Pacotes']])Padding(padding:const EdgeInsets.only(right:8),child:ChoiceChip(label:Text(x[1]),selected:filter==x[0],onSelected:(_)=>setState(()=>filter=x[0]),selectedColor:ink,labelStyle:TextStyle(color:filter==x[0]?paper:ink),backgroundColor:paperCard,side:const BorderSide(color:ink)))])),const SizedBox(height:14),if(items.isEmpty)Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(border:Border.all(color:ink),borderRadius:BorderRadius.circular(4)),child:const Text('Nenhum item nesta categoria ainda.',style:TextStyle(color:ink))),...items.map((i)=>_card(c,i))])));}
Widget _card(BuildContext c,Map<String,dynamic>i){final owned=List<String>.from(PlayerSession.profile['owned']??[]).contains(i['id']);final equipped=PlayerSession.profile['equipped']?['theme']==i['id']||PlayerSession.profile['equipped']?['xstyle']==i['id']||PlayerSession.profile['equipped']?['ostyle']==i['id'];final image='${i['imageUrl']??''}';return Container(margin:const EdgeInsets.only(bottom:14),decoration:BoxDecoration(color:paperCard,border:Border.all(color:ink),borderRadius:BorderRadius.circular(5)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[if(image.isNotEmpty)ClipRRect(borderRadius:const BorderRadius.vertical(top:Radius.circular(4)),child:Image.network(image,height:170,width:double.infinity,fit:BoxFit.cover,errorBuilder:(_,__,___)=>_art(i))) else _art(i),Padding(padding:const EdgeInsets.fromLTRB(14,12,14,14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${i['name']??'Item'}',style:paperH1(size:22)),const SizedBox(height:4),Text('${i['description']??'Um item para personalizar sua partida.'}',style:const TextStyle(color:paperMuted,fontSize:12)),const SizedBox(height:12),Row(children:[Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:5),decoration:BoxDecoration(border:Border.all(color:ink),borderRadius:BorderRadius.circular(3)),child:Text('${i['price']??0} moedas',style:const TextStyle(color:ink,fontWeight:FontWeight.w900))),const Spacer(),OutlinedButton(onPressed:()=>action(i),style:OutlinedButton.styleFrom(foregroundColor:ink,side:const BorderSide(color:ink),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(3))),child:Text(equipped?'Equipado':owned?'Equipar':'Comprar'))])]))]));}
Widget _art(Map<String,dynamic>i){final bg=parseColor(i['bgColor']??'#D8CFBF');return Container(height:170,width:double.infinity,color:bg,child:Center(child:Text('${i['name']??'ITEM'}',textAlign:TextAlign.center,style:TextStyle(color:ink,fontSize:28,fontWeight:FontWeight.w900,fontStyle:FontStyle.italic))));}
}
class RedeemPage extends StatefulWidget{const RedeemPage({super.key});@override State<RedeemPage>createState()=>_RedeemPageState();}class _RedeemPageState extends State<RedeemPage>{final c=TextEditingController();bool busy=false;@override Widget build(BuildContext x)=>Scaffold(appBar:AppBar(backgroundColor:navy,foregroundColor:Colors.white,title:const Text('Código de recompensa')),body:Padding(padding:const EdgeInsets.all(20),child:Column(children:[const Text('Digite um código criado pelo administrador.',style:TextStyle(color:Colors.white70)),const SizedBox(height:18),TextField(controller:c,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,letterSpacing:3),decoration:dec('EXEMPLO2026')),const SizedBox(height:12),FilledButton.icon(onPressed:busy?null:()async{setState(()=>busy=true);final m=await PlayerSession.redeem(c.text);if(mounted){setState(()=>busy=false);ScaffoldMessenger.of(x).showSnackBar(SnackBar(content:Text(m??'Erro')));}},icon:const Icon(Icons.card_giftcard),label:const Text('Resgatar')),])));@override void dispose(){c.dispose();super.dispose();}}


class GiftPage extends StatefulWidget{const GiftPage({super.key});@override State<GiftPage>createState()=>_GiftPageState();}
class _GiftPageState extends State<GiftPage>{final id=TextEditingController();final amount=TextEditingController();String? itemId;bool coins=true;@override Widget build(BuildContext c){final owned=List<dynamic>.from(PlayerSession.store).where((x)=>List<dynamic>.from(PlayerSession.profile['owned']??[]).contains(x['id'])).toList();return Scaffold(appBar:AppBar(backgroundColor:navy,foregroundColor:Colors.white,title:const Text('Dar presente',style:TextStyle(fontWeight:FontWeight.w900))),body:ListView(padding:const EdgeInsets.all(18),children:[Card(color:cardBlue,child:Padding(padding:const EdgeInsets.all(15),child:Column(children:[TextField(controller:id,style:const TextStyle(color:Colors.white),decoration:dec('ID do jogador')),const SizedBox(height:10),SegmentedButton<bool>(segments:const [ButtonSegment(value:true,label:Text('Moedas')),ButtonSegment(value:false,label:Text('Item da loja'))],selected:{coins},onSelectionChanged:(v)=>setState(()=>coins=v.first)),const SizedBox(height:12),if(coins)TextField(controller:amount,keyboardType:TextInputType.number,style:const TextStyle(color:Colors.white),decoration:dec('Quantidade de moedas')),if(!coins)DropdownButtonFormField<String>(value:itemId,dropdownColor:cardBlue,decoration:dec('Item para presentear'),items:[for(final x in owned)DropdownMenuItem(value:'${x['id']}',child:Text('${x['name']} • ${x['price']} moedas',style:const TextStyle(color:Colors.white)))],onChanged:(v)=>setState(()=>itemId=v)),const SizedBox(height:14),FilledButton.icon(onPressed:()async{final to=id.text.trim().toUpperCase();if(to.isEmpty)return;String? m;if(coins)m=await PlayerSession.sendCoins(to,int.tryParse(amount.text)??0);else if(itemId!=null)m=await PlayerSession.sendItem(to,itemId!);else m='Escolha um item.';if(c.mounted)ScaffoldMessenger.of(c).showSnackBar(SnackBar(content:Text(m??'Presente enviado!')));if(m==null){id.clear();amount.clear();setState(()=>itemId=null);}},icon:const Icon(Icons.card_giftcard),label:const Text('Enviar presente'))]))),const SizedBox(height:14),const Text('O destinatário recebe a mensagem imediatamente no sistema de notificações.',style:TextStyle(color:Colors.white70))]));}@override void dispose(){id.dispose();amount.dispose();super.dispose();}}

class NotificationsPage extends StatefulWidget{const NotificationsPage({super.key});@override State<NotificationsPage>createState()=>_NotificationsPageState();}
class _NotificationsPageState extends State<NotificationsPage>{Timer?timer;@override void initState(){super.initState();load();timer=Timer.periodic(const Duration(seconds:3),(_)=>load());}@override void dispose(){timer?.cancel();super.dispose();}Future<void>load()async{await PlayerSession.loadNotifications();if(mounted)setState((){});} @override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(backgroundColor:navy,foregroundColor:Colors.white,title:const Text('Notificações',style:TextStyle(fontWeight:FontWeight.w900))),body:PlayerSession.notifications.isEmpty?const Center(child:Text('Nenhuma notificação.',style:TextStyle(color:Colors.white70))):ListView.builder(padding:const EdgeInsets.all(14),itemCount:PlayerSession.notifications.length,itemBuilder:(c,i){final n=PlayerSession.notifications[i];return Card(color:n['read']==true?cardBlue:blue,child:ListTile(leading:Icon(n['kind']=='admin'?Icons.admin_panel_settings:Icons.card_giftcard,color:cream),title:Text(n['message']??'',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),subtitle:Text('${n['createdAt']??''}',style:const TextStyle(color:Colors.white60)),onTap:()async{await PlayerSession.markNotificationRead('${n['id']}');load();}));}));}
class FriendsPage extends StatefulWidget{const FriendsPage({super.key});@override State<FriendsPage>createState()=>_FriendsPageState();}
class _FriendsPageState extends State<FriendsPage>{List<dynamic> incoming=[],friends=[];final id=TextEditingController();@override void initState(){super.initState();load();}Future<void>load()async{try{final r=await http.get(Uri.parse('$apiBase/api/friends?playerId=${Uri.encodeComponent(PlayerSession.id)}'));final d=jsonDecode(r.body);if(mounted)setState((){incoming=d['incoming']??[];friends=d['friends']??[];});}catch(_){}}Future<void>send()async{final r=await http.post(Uri.parse('$apiBase/api/friend/request'),headers:{'Content-Type':'application/json'},body:jsonEncode({'fromId':PlayerSession.id,'toId':id.text.trim().toUpperCase()}));final d=jsonDecode(r.body);if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(d['error']??'Pedido enviado!')));id.clear();load();}Future<void>accept(String rid)async{final r=await http.post(Uri.parse('$apiBase/api/friend/accept'),headers:{'Content-Type':'application/json'},body:jsonEncode({'playerId':PlayerSession.id,'requestId':rid}));if(r.statusCode==200)load();}@override Widget build(BuildContext c)=>Scaffold(appBar:AppBar(backgroundColor:navy,foregroundColor:Colors.white,title:const Text('Amigos',style:TextStyle(fontWeight:FontWeight.w900))),body:ListView(padding:const EdgeInsets.all(18),children:[Card(color:cardBlue,child:Padding(padding:const EdgeInsets.all(15),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Seu ID',style:TextStyle(color:Colors.white70)),SelectableText(PlayerSession.id,style:const TextStyle(color:Colors.white,fontSize:22,fontWeight:FontWeight.w900)),const SizedBox(height:6),const Text('Esse ID identifica sua conta no jogo.',style:TextStyle(color:Colors.white60))]))),const SizedBox(height:12),TextField(controller:id,style:const TextStyle(color:Colors.white),decoration:dec('ID do amigo')),const SizedBox(height:8),FilledButton.icon(onPressed:send,icon:const Icon(Icons.person_add),label:const Text('Enviar pedido')),const SizedBox(height:20),const Text('SOLICITAÇÕES',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),...incoming.map((r)=>Card(color:cardBlue,child:ListTile(title:Text(r['from']['name']??'',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),subtitle:Text(r['from']['id']??'',style:const TextStyle(color:Colors.white60)),trailing:FilledButton(onPressed:()=>accept(r['id']),child:const Text('Aceitar'))))),const SizedBox(height:20),const Text('AMIGOS',style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),...friends.map((f)=>ListTile(leading:const CircleAvatar(backgroundColor:Colors.green),title:Text(f['name']??'',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),subtitle:Text(f['id']??'',style:const TextStyle(color:Colors.white60))))]));@override void dispose(){id.dispose();super.dispose();}}

void runAdminApp()=>runApp(const AdminApp());
class AdminApp extends StatelessWidget{const AdminApp({super.key});@override Widget build(BuildContext c)=>MaterialApp(debugShowCheckedModeBanner:false,theme:ThemeData(useMaterial3:true,scaffoldBackgroundColor:navy,colorScheme:ColorScheme.fromSeed(seedColor:blue)),home:const AdminLoginPage());}
class AdminLoginPage extends StatefulWidget{const AdminLoginPage({super.key});@override State<AdminLoginPage>createState()=>_AdminLoginPageState();}
class _AdminLoginPageState extends State<AdminLoginPage>{static const _authorizedEmail='rhuanprodutor3@gmail.com';final p=TextEditingController();bool busy=false;String error='';@override void dispose(){p.dispose();super.dispose();}@override Widget build(BuildContext c)=>Scaffold(backgroundColor:paper,body:PaperShell(padding:const EdgeInsets.all(24),child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:430),child:Container(padding:const EdgeInsets.all(24),decoration:BoxDecoration(color:paperCard,border:Border.all(color:ink),borderRadius:BorderRadius.circular(5)),child:Column(mainAxisSize:MainAxisSize.min,children:[const Text('04 — acesso',style:TextStyle(color:paperMuted,fontSize:11)),const SizedBox(height:4),Text('Área autorizada.',style:paperH1(size:30)),const SizedBox(height:8),const Text('Entre somente se você possui acesso administrativo.',textAlign:TextAlign.center,style:TextStyle(color:paperMuted,fontSize:12)),const SizedBox(height:18),TextField(controller:p,obscureText:true,style:const TextStyle(color:ink),decoration:const InputDecoration(labelText:'Senha',labelStyle:TextStyle(color:paperMuted),enabledBorder:UnderlineInputBorder(borderSide:BorderSide(color:ink)),focusedBorder:UnderlineInputBorder(borderSide:BorderSide(color:ink))),onSubmitted:(_)=>login()),if(error.isNotEmpty)Padding(padding:const EdgeInsets.only(top:10),child:Text(error,style:const TextStyle(color:Colors.red))),const SizedBox(height:14),SizedBox(width:double.infinity,child:OutlinedButton(onPressed:busy?null:login,style:OutlinedButton.styleFrom(foregroundColor:ink,side:const BorderSide(color:ink),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(3))),child:Text(busy?'Entrando...':'Entrar')))]))))));
Future<void>login()async{setState(()=>busy=true);try{final r=await http.post(Uri.parse('$apiBase/api/admin/login'),headers:{'Content-Type':'application/json'},body:jsonEncode({'email':_authorizedEmail,'password':p.text}));final d=jsonDecode(r.body);if(r.statusCode==200){if(mounted)push(context,AdminDashboard(token:d['token']));}else if(mounted)setState(()=>error=d['error']??'Falha');}catch(_){if(mounted)setState(()=>error='Servidor indisponível.');}if(mounted)setState(()=>busy=false);}
}
class AdminDashboard extends StatefulWidget{
  final String token;
  const AdminDashboard({super.key,required this.token});
  @override State<AdminDashboard> createState()=>_AdminDashboardState();
}
class _AdminDashboardState extends State<AdminDashboard>{
  List<dynamic> users=[],items=[],packs=[],codes=[];
  Map<String,dynamic> config={};
  bool busy=false;
  Future<Map<String,String>> get headers async=>{'Authorization':'Bearer ${widget.token}'};
  Future<void> load() async{try{final h=await headers;final u=await http.get(Uri.parse('$apiBase/api/admin/users'),headers:h);final s=await http.get(Uri.parse('$apiBase/api/admin/store'),headers:h);if(u.statusCode!=200||s.statusCode!=200)return;final ud=jsonDecode(u.body),sd=jsonDecode(s.body);if(mounted)setState((){users=ud['users']??[];items=sd['items']??[];packs=sd['packages']??[];codes=sd['codes']??[];config=sd['config']??{};});}catch(_){} }
  @override void initState(){super.initState();load();}
  Future<void> grant(Map<String,dynamic>u)async{final co=TextEditingController(),xp=TextEditingController(),lv=TextEditingController();await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text('Dar/retirar — ${u['name']}'),content:Column(mainAxisSize:MainAxisSize.min,children:[Text('Atual: ${u['coins']} moedas • ${u['xp']} XP • Nv.${u['level']}'),TextField(controller:co,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Moedas (+ dar / - retirar)')),TextField(controller:xp,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'XP (+ dar / - retirar)')),TextField(controller:lv,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Nível (+ / -)'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancelar')),FilledButton(onPressed:()async{final h=await headers;await http.post(Uri.parse('$apiBase/api/admin/grant'),headers:{...h,'Content-Type':'application/json'},body:jsonEncode({'playerId':u['id'],'coinsDelta':int.tryParse(co.text)??0,'xpDelta':int.tryParse(xp.text)??0,'levelDelta':int.tryParse(lv.text)??0}));if(ctx.mounted)Navigator.pop(ctx);load();},child:const Text('Aplicar'))]));}
  Future<void>grantItem(Map<String,dynamic>u)async{String? selected;await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setLocal)=>AlertDialog(title:Text('Dar item — ${u['name']}'),content:DropdownButtonFormField<String>(value:selected,items:[for(final x in [...items,...packs])DropdownMenuItem(value:'${x['id']}',child:Text('${x['name']} • ${x['price']}'))],onChanged:(v)=>setLocal(()=>selected=v),decoration:const InputDecoration(labelText:'Item da loja')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancelar')),FilledButton(onPressed:()async{if(selected==null)return;final h=await headers;await http.post(Uri.parse('$apiBase/api/admin/grant-item'),headers:{...h,'Content-Type':'application/json'},body:jsonEncode({'playerId':u['id'],'itemId':selected}));if(ctx.mounted)Navigator.pop(ctx);load();},child:const Text('Dar item'))])));}
  Future<void>newCode()async{final c=TextEditingController(),a=TextEditingController(),m=TextEditingController();String type='coins';await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setLocal)=>AlertDialog(title:const Text('Criar código'),content:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:c,decoration:const InputDecoration(labelText:'Código')),DropdownButton<String>(value:type,items:const[DropdownMenuItem(value:'coins',child:Text('Moedas')),DropdownMenuItem(value:'xp',child:Text('XP'))],onChanged:(v){if(v!=null)setLocal(()=>type=v);}),TextField(controller:a,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Quantidade')),TextField(controller:m,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Limite de usos (vazio = ilimitado)'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancelar')),FilledButton(onPressed:()async{final h=await headers;await http.post(Uri.parse('$apiBase/api/admin/code'),headers:{...h,'Content-Type':'application/json'},body:jsonEncode({'code':c.text,'rewardType':type,'amount':int.tryParse(a.text)??0,'maxUses':m.text}));if(ctx.mounted)Navigator.pop(ctx);load();},child:const Text('Criar'))])));}
  Future<void>newTheme()async{final n=TextEditingController(),p=TextEditingController(),b=TextEditingController(text:'#081A45'),a=TextEditingController(text:'#4D6FC5'),img=TextEditingController();await showDialog(context:context,builder:(ctx)=>AlertDialog(title:const Text('Novo tema'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[TextField(controller:n,decoration:const InputDecoration(labelText:'Nome')),TextField(controller:p,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Preço')),TextField(controller:b,decoration:const InputDecoration(labelText:'Fundo sólido (#hex)')),TextField(controller:a,decoration:const InputDecoration(labelText:'Paleta/acento (#hex)')),TextField(controller:img,decoration:const InputDecoration(labelText:'URL da imagem de fundo'))])),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancelar')),FilledButton(onPressed:()async{final h=await headers;await http.post(Uri.parse('$apiBase/api/admin/theme'),headers:{...h,'Content-Type':'application/json'},body:jsonEncode({'name':n.text,'price':int.tryParse(p.text)??0,'bgColor':b.text,'accent':a.text,'imageUrl':img.text}));if(ctx.mounted)Navigator.pop(ctx);load();},child:const Text('Criar tema'))]));}
  Future<void>newPack()async{
    final selected=<String>{};
    final n=TextEditingController();
    final p=TextEditingController();
    await showDialog(
      context:context,
      builder:(ctx)=>StatefulBuilder(
        builder:(ctx,setLocal)=>AlertDialog(
          title:const Text('Criar pacote'),
          content:SizedBox(
            width:440,
            child:SingleChildScrollView(
              child:Column(
                mainAxisSize:MainAxisSize.min,
                children:[
                  TextField(controller:n,decoration:const InputDecoration(labelText:'Nome')),
                  TextField(controller:p,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Preço')),
                  for(final x in items)
                    CheckboxListTile(
                      value:selected.contains(x['id']),
                      onChanged:(v)=>setLocal(()=>v==true?selected.add(x['id']):selected.remove(x['id'])),
                      title:Text(x['name']??''),
                      subtitle:Text('${x['type']} • ${x['price']} moedas'),
                    ),
                ],
              ),
            ),
          ),
          actions:[
            TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancelar')),
            FilledButton(
              onPressed:()async{
                final h=await headers;
                await http.post(Uri.parse('$apiBase/api/admin/pack'),headers:{...h,'Content-Type':'application/json'},body:jsonEncode({'name':n.text,'price':int.tryParse(p.text)??0,'items':selected.toList()}));
                if(ctx.mounted)Navigator.pop(ctx);
                load();
              },
              child:const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }
  Future<void>maintenance()async{final msg=TextEditingController(text:'${config['maintenanceMessage']??'O jogo está em manutenção. Tente novamente em alguns minutos.'}');bool enabled=config['maintenance']==true;await showDialog(context:context,builder:(ctx)=>StatefulBuilder(builder:(ctx,setLocal)=>AlertDialog(title:const Text('Manutenção'),content:Column(mainAxisSize:MainAxisSize.min,children:[SwitchListTile(value:enabled,onChanged:(v)=>setLocal(()=>enabled=v),title:const Text('Modo manutenção')),TextField(controller:msg,maxLines:3,decoration:const InputDecoration(labelText:'Aviso para os jogadores'))]),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancelar')),FilledButton(onPressed:()async{final h=await headers;await http.post(Uri.parse('$apiBase/api/admin/maintenance'),headers:{...h,'Content-Type':'application/json'},body:jsonEncode({'enabled':enabled,'message':msg.text}));if(ctx.mounted)Navigator.pop(ctx);load();},child:const Text('Salvar'))])));}
  Future<void>uploadUpdate()async{final file=await FilePicker.pickFile(type:FileType.custom,allowedExtensions:['apk']);if(file==null)return;final version=TextEditingController(text:'${config['latestVersion']??PlayerSession.appVersion}');await showDialog(context:context,builder:(ctx)=>AlertDialog(title:Text('Enviar ${file.name}'),content:TextField(controller:version,decoration:const InputDecoration(labelText:'Nova versão (ex.: 3.2.0)')),actions:[TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancelar')),FilledButton(onPressed:()async{if(mounted)setState(()=>busy=true);final bytes=await file.readAsBytes();final h=await headers;final req=http.Request('POST',Uri.parse('$apiBase/api/admin/update-upload?version=${Uri.encodeComponent(version.text.trim())}'));req.headers.addAll(h);req.headers['Content-Type']='application/vnd.android.package-archive';req.bodyBytes=bytes;final resp=await req.send();if(ctx.mounted)Navigator.pop(ctx);if(mounted)setState(()=>busy=false);if(resp.statusCode!=200&&mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Falha ao enviar APK.')));load();},child:const Text('Enviar APK'))]));}
  Widget sectionTitle(String t)=>Padding(padding:const EdgeInsets.only(top:18,bottom:8),child:Text(t,style:const TextStyle(color:Colors.white,fontSize:17,fontWeight:FontWeight.w900)));
  @override Widget build(BuildContext c){
    final maintenanceOn=config['maintenance']==true;
    final published='${config['latestVersion']??PlayerSession.appVersion}';
    return Scaffold(
      appBar:AppBar(
        backgroundColor:navy,
        foregroundColor:Colors.white,
        title:const Text('Admin • Jogo Da Velha',style:TextStyle(fontWeight:FontWeight.w900)),
        actions:[IconButton(onPressed:load,icon:const Icon(Icons.refresh))],
      ),
      body:Container(
        decoration:backgroundDecoration(),
        child:ListView(
          padding:const EdgeInsets.all(16),
          children:[
            Card(color:cardBlue,child:Padding(padding:const EdgeInsets.all(14),child:Wrap(spacing:8,runSpacing:8,children:[
              FilledButton.icon(onPressed:newCode,icon:const Icon(Icons.qr_code),label:const Text('Criar código')),
              FilledButton.icon(onPressed:newTheme,icon:const Icon(Icons.palette),label:const Text('Criar tema')),
              FilledButton.icon(onPressed:newPack,icon:const Icon(Icons.inventory_2),label:const Text('Criar pacote')),
              FilledButton.icon(onPressed:maintenance,icon:const Icon(Icons.build),label:Text(maintenanceOn?'Sair da manutenção':'Entrar em manutenção')),
              FilledButton.icon(onPressed:busy?null:uploadUpdate,icon:const Icon(Icons.upload_file),label:const Text('Atualizar jogo')),
            ]))),
            Card(color:maintenanceOn?Colors.orange.shade800:cardBlue,child:ListTile(
              leading:Icon(maintenanceOn?Icons.warning:Icons.check_circle,color:cream),
              title:Text(maintenanceOn?'MANUTENÇÃO ATIVA':'Servidor operacional',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),
              subtitle:Text('Versão publicada: $published',style:const TextStyle(color:Colors.white70)),
            )),
            sectionTitle('USUÁRIOS • ${users.length}'),
            ...users.map((u)=>Card(color:cardBlue,child:ListTile(
              title:Text(u['name']??'',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900)),
              subtitle:Text('${u['id']} • ${u['coins']} moedas • ${u['xp']} XP • Nv.${u['level']}',style:const TextStyle(color:Colors.white70)),
              trailing:Wrap(children:[
                IconButton(color:Colors.amber,onPressed:()=>grant(u),icon:const Icon(Icons.monetization_on)),
                IconButton(color:Colors.white,onPressed:()=>grantItem(u),icon:const Icon(Icons.card_giftcard)),
              ]),
            ))),
            sectionTitle('CÓDIGOS • ${codes.length}'),
            ...codes.map((x)=>ListTile(
              title:Text(x['code']??'',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),
              subtitle:Text('${x['amount']} ${x['rewardType']} • usos ${x['uses']}',style:const TextStyle(color:Colors.white60)),
            )),
            sectionTitle('LOJA • ${items.length+packs.length} itens'),
            ...items.map((x)=>Card(color:cardBlue,child:ListTile(
              leading:previewIcon(x),
              title:Text(x['name']??'',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),
              subtitle:Text('${x['type']} • ${x['price']} moedas',style:const TextStyle(color:Colors.white60)),
            ))),
            ...packs.map((x)=>Card(color:cardBlue,child:ListTile(
              leading:const Icon(Icons.inventory_2,color:Colors.amber),
              title:Text(x['name']??'',style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w800)),
              subtitle:Text('${x['price']} moedas • ${(x['items']??[]).length} itens',style:const TextStyle(color:Colors.white60)),
            ))),
          ],
        ),
      ),
    );
  }
  Widget previewIcon(Map<String,dynamic>x)=>CircleAvatar(backgroundColor:parseColor(x['bgColor']??'#405EAE'),child:Text(x['type']=='xstyle'?'X':x['type']=='ostyle'?'O':'🎨'));
}
