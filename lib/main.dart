import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:another_flushbar/flushbar.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Page;
import 'package:flutter/material.dart' as mt;
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_example/class/classroom.dart';
import 'package:livekit_example/exts.dart';
import 'package:livekit_example/sample.dart';
import 'package:livekit_example/theme.dart';
import 'package:logging/logging.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:system_theme/system_theme.dart';
import 'pages/connect.dart';
import 'pages/room.dart';
import 'theme2.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:window_manager/window_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/link.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:toastification/toastification.dart';
import 'package:flutter/material.dart' as mtx;
const String appTitle = 'Telemedicine RSUMMI';
bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

void main() async {
  final format = DateFormat('HH:mm:ss');
  // configure logs for debugging
  Logger.root.level = Level.FINE;
  Logger.root.onRecord.listen((record) {

  });

  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb &&
      [
        TargetPlatform.windows,
        TargetPlatform.android,
      ].contains(defaultTargetPlatform)) {
    SystemTheme.accentColor.load();
  }


    if (isDesktop) {
    await flutter_acrylic.Window.initialize();
    await flutter_acrylic.Window.hideWindowControls();
    await WindowManager.instance.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
      await windowManager.setMinimumSize(const Size(1360, 768));
      await windowManager.show();
      await windowManager.setPreventClose(true);
      await windowManager.setSkipTaskbar(false);
    });
  }
    runApp( const MyApp());
}

final _appTheme = AppTheme();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _appTheme,
      builder: (context, child) {
        final appTheme = context.watch<AppTheme>();
        return FluentApp.router(
          title: appTitle,
          themeMode: appTheme.mode,
          debugShowCheckedModeBanner: false,
          color: appTheme.color,
          darkTheme: FluentThemeData(
            brightness: Brightness.dark,
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen(context) ? 2.0 : 0.0,
            ),
          ),
          theme: FluentThemeData(
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen(context) ? 2.0 : 0.0,
            ),
          ),
          locale: appTheme.locale,
          builder: (context, child) {
            return Directionality(
              textDirection: appTheme.textDirection,
              child: NavigationPaneTheme(
                data: NavigationPaneThemeData(
                  backgroundColor: appTheme.windowEffect !=
                          flutter_acrylic.WindowEffect.disabled
                      ? Colors.transparent
                      : null,
                ),
                child: child!,
              ),
            );
          },
          routeInformationParser: router.routeInformationParser,
          routerDelegate: router.routerDelegate,
          routeInformationProvider: router.routeInformationProvider,
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
    required this.child,
    required this.shellContext,
  });

  final Widget child;
  final BuildContext? shellContext;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WindowListener {
  bool value = false;

  IO.Socket? socket;

  int  az = 0;

 void connectToSocket() async{
  // Ganti URL dengan URL server socket.io yang sesuai
  socket = IO.io('https://api.rsummi.co.id:9193', <String, dynamic>{
    'transports': ['websocket'],
    'autoConnect': false,
  });
if (socket != null) {
  socket!.destroy();
}
  await socket!.connect();
  socket!.emit('joinlivekit', "-1234");

  socket!.onConnect((_) {
    socket!.on('terima-dokter', (data){

       toastification.show(
          context: context,
          autoCloseDuration: const Duration(seconds: 20),
          title: 'Panggilan Masuk!',
          description:
              'permintaan Panggilan Dari ${data['dari']}',
          animationDuration: const Duration(milliseconds: 300),
          icon: Icon(FluentIcons.message_fill),
          backgroundColor: Color.fromARGB(255, 70, 95, 68),
          onCloseTap: () {
         
    
          },
       
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          borderRadius: BorderRadius.circular(8),
        
          showProgressBar: true,
        
          closeOnClick: true,
          pauseOnHover: true,
        );
    });
  
   az += 1;
   print("contoh $az");
  });

  socket!.onDisconnect((_) {
    print('Disconnected from socket.io');
     // Memanggil fungsi untuk mencoba kembali koneksi
  });
}

void reconnect() {
  // Logika untuk mencoba kembali koneksi
  // Contohnya, mencoba kembali koneksi setelah jeda waktu tertentu
  Future.delayed(Duration(seconds: 5), () {
    print('Trying to reconnect...');
    connectToSocket(); // Menghubungkan kembali
  });
}


  void sendDataToServer() {
    // Mengirim data ke server
    socket!.emit('terima-dokter', 'Hello, Server!');
  }


  final viewKey = GlobalKey(debugLabel: 'Navigation View Key');
  final searchKey = GlobalKey(debugLabel: 'Search Bar Key');
  final searchFocusNode = FocusNode();
  final searchController = TextEditingController();

  late final List<NavigationPaneItem> originalItems = [
    PaneItem(
      onTap: (){
   
        
      },
      key: const ValueKey('/'),
      icon: const Icon(FluentIcons.hangup),
      title: const Text('Home'),
      body: const SizedBox.shrink(),
    ),

    PaneItem(

      key: const ValueKey('/dismisable'),
      icon: const Icon(FluentIcons.analytics_report),
      title: const Text('Analytics'),
      body: const SizedBox.shrink(),
    ),
    PaneItem(
      key: const ValueKey('/forms/auto_suggest_box'),
      icon: const Icon(FluentIcons.record_routing),
      title: const Text('Record'),
      body: const SizedBox.shrink(),
    ),

    PaneItemHeader(header: const Text('Panggilan Permintaan Panggilan')),
  ].map((e) {
    if (e is PaneItem) {
      return PaneItem(
        key: e.key,
        icon: e.icon,
        title: e.title,
        body: e.body,
        onTap: () {
          final path = (e.key as ValueKey).value;
          if (GoRouterState.of(context).uri.toString() != path) {
            context.go(path);
          }
          e.onTap?.call();
        },
      );
    }
    return e;
  }).toList();
   late Timer timer;

  @override
  void initState() {
    windowManager.addListener(this);
    // Mengatur timer untuk melakukan pengecekan setiap 2 detik
    timer = Timer.periodic(Duration(seconds: 2), (Timer t) => getnotification());
    this.connectToSocket();
    super.initState();
  }
  final controller = FlyoutController();
  final attachKey = GlobalKey();
List<int> a = []; // List untuk menyimpan indeks
List<PaneItem> myPaneItems = []; // List PaneItem

void changestatus(String roomkey)async{
  myPaneItems.clear();
  final response = await http.post(Uri.parse("http://api.rsummi.co.id:1842/rsummi-api/PutTelemedic"),body: {"roomkey" : roomkey});
}
void showContentDialog(BuildContext context) async {
    final result = await showDialog<String>(
      barrierDismissible: true,
        context: context,
        builder: (context) => ContentDialog(
            title: const Text('Gagal Melakukan'),
            content: const Text(
                'anda sedang berada dalam panggilan tidak dapat melakukan pemanggilan lain',
            ),
            actions: [
              
                FilledButton(
                    child: const Text('Tutup'),
                    onPressed: () => Navigator.pop(context, 'User canceled dialog'),
                ),
            ],
        ),
    );
    setState(() {});
}

void getnotification() async {
  final response = await http.post(
    Uri.parse("http://api.rsummi.co.id:1842/rsummi-api/GetTelemedic"),
    body: {"did": "-1234"},
  );
  if (response.statusCode == 200 && jsonDecode(response.body)['metadata']['code'] == 200) {
    final jsonResponse = jsonDecode(response.body);
    final List<dynamic> responseData = jsonResponse['response'];

    setState(() {
      List<PaneItem> tempPaneItems = List.from(myPaneItems);
      Uuid uuid = Uuid();
      String uniqueKey = uuid.v4();
      for (var data in responseData) {
        String roomKey = data['cid'];

        bool isRoomKeyExistsInMyPaneItems = tempPaneItems.any((item) => item.title == Text('Panggilan Masuk - Room Key: $roomKey'));

        if (isRoomKeyExistsInMyPaneItems) {
          tempPaneItems.removeWhere((item) => item.title == Text('$roomKey'));
        } else {
          PaneItem newItem = PaneItem(
            key: ValueKey(uniqueKey),
            onTap2: () {
                      socket!.emit('balasan-dokter', {
    'pasien':data['cid'],
    'pesan': "gajadika maaf",
    'iddokter': "-1234",
    'jawaban' :false,
  });
           changestatus(data['roomkey']);
  String roomKey = data['roomkey'];

  // Cari indeks item dengan roomKey yang sesuai dan hapus jika ditemukan
  int indexToRemove = myPaneItems.indexWhere((item) => item.title == Text('$roomKey'));
  if (indexToRemove != -1) { 
    setState(() {
      myPaneItems.removeAt(indexToRemove);
    });
  }
            },
            onTap3: () {
              if(ClassStatus.sedangcall){
     showContentDialog(context);
              }else{
changestatus(data['roomkey']);
        _connect(context,data['dkey'],data['roomkey']);
          Future.delayed(Duration.zero).then((value) {
                 socket!.emit('balasan-dokter', {
    'pasien':data['cid'],
    'pesan': "jadi ka",
    'iddokter': "-1234",
    'jawaban' :true,
    'roomkey' : data['ckey']
  });
  ClassStatus.country = data['country_flag'];
            ClassStatus.sedangcall = true;
      RoomDetailed.rekam_medis = data['cid'];});

              }
      
    
            },
            iscalltype: true,
            icon: Icon(FluentIcons.ringer_active),
            title: Text(data['nama_lengkap'].toString().toLowerCase()), // Menampilkan room key dalam judul PaneItem
            onTap: () {},
            body: Container()
          );

          myPaneItems.add(newItem); // Menambahkan item baru ke myPaneItems
          a.add(lastIndex);
      
          lastIndex++;
        }
      }

      // Hapus item yang tidak ada di respons API baru dari myPaneItems
      for (var item in tempPaneItems) {
        myPaneItems.remove(item);
      }
    });
  } else {

setState(() {
      myPaneItems.clear();
});
  }
}
bool _busy = false;
bool _simulcast = true;
  bool _adaptiveStream = true;
  bool _dynacast = true;
  bool _fastConnect = true;
  bool _e2ee = false;
  bool _multiCodec = false;
  String _preferredCodec = 'Preferred Codec';
  String _backupCodec = 'VP8';

Future<void> _connect(BuildContext ctx,String token,String roomkey) async {
    //
    try {
      setState(() {
        _busy = true;
      });

      // Save URL and Token for convenience


      E2EEOptions? e2eeOptions;
      if (_e2ee) {
        final keyProvider = await BaseKeyProvider.create();
        e2eeOptions = E2EEOptions(keyProvider: keyProvider);
        var sharedKey = "_sharedKeyCtrl.text";
        await keyProvider.setSharedKey(sharedKey);
      }

      String preferredCodec = 'VP8';
      if (_preferredCodec != 'Preferred Codec') {
        preferredCodec = _preferredCodec;
      }
// create new room
      RoomDetailed.room = Room(
          roomOptions: RoomOptions(
        adaptiveStream: _adaptiveStream,
        dynacast: _dynacast,
        defaultAudioPublishOptions: const AudioPublishOptions(
          dtx: true,
        ),
        defaultVideoPublishOptions: VideoPublishOptions(
          simulcast: _simulcast,
          videoCodec: preferredCodec,
        ),
        defaultScreenShareCaptureOptions: const ScreenShareCaptureOptions(
            useiOSBroadcastExtension: true,
            params: VideoParametersPresets.screenShareH1080FPS30),
        e2eeOptions: e2eeOptions,
        defaultCameraCaptureOptions: const CameraCaptureOptions(
          maxFrameRate: 30,
          params: VideoParametersPresets.h720_169,
        ),
      ));
      RoomDetailed. listener = RoomDetailed.room!.createListener();
      await RoomDetailed. room!.connect(
     "ws://api.rsummi.co.id:7880",
 token.toString()
     ,     fastConnectOptions: _fastConnect
            ? FastConnectOptions(
                microphone: const TrackOption(enabled: true),
                camera: const TrackOption(enabled: true),
              )
            : null,
      );

 changestatus(roomkey);
      await context.push('/roomPages');
      //  changestatus(token);
    } catch (error) {
      print('Could not connect $error');
      await ctx.showErrorDialog(error);
    } finally {
      setState(() {
        _busy = false;
        
      });
    }
  }

void navigateToNewPage(BuildContext context) {

  setState(() {
    // PatientUserId.name = "bagus andre wijaya";
  });
context.push('/SamplePage');
}

void removePaneItemAt(int index) {
  setState(() {
    if (index >= 0 && index < myPaneItems.length) {
      myPaneItems.removeAt(index);
    }
  });
}

int lastIndex = -1;
String generateRandomKey() {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789'; // Karakter yang digunakan untuk kunci acak
  final random = Random();
  final keyLength = 6; // Panjang kunci yang diinginkan

  String randomKey = ''; // Variabel untuk menyimpan kunci acak

  for (var i = 0; i < keyLength; i++) {
    randomKey += chars[random.nextInt(chars.length)];
  }

  return randomKey;
}

void dataprint(id,nama){
  print(id);
  print(nama);
}
  @override
  void dispose() {
    windowManager.removeListener(this);
    searchController.dispose();
    if(socket != null) {
  socket!.disconnect();
}
    super.dispose();
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    int indexOriginal = originalItems
        .where((item) => item.key != null)
        .toList()
        .indexWhere((item) => item.key == Key(location));

    if (indexOriginal == -1) {

      
      return originalItems
              .where((element) => element.key != null)
              .toList()
              .length;
    } else {
      return indexOriginal;
    }
  }


  StreamController<List<PaneItem>> paneItemsController = StreamController();
  
  @override
  Widget build(BuildContext context) {
    
    final localizations = FluentLocalizations.of(context);

    final appTheme = context.watch<AppTheme>();
    final theme = FluentTheme.of(context);
    if (widget.shellContext != null) {
      if (router.canPop() == false) {
        setState(() {});
      }
    }
    return NavigationView(
      key: viewKey,
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        leading: () {
          final enabled = widget.shellContext != null && router.canPop();

          final onPressed = enabled
              ? () {
                  if (router.canPop()) {
                    context.pop();
                    setState(() {});
                  }
                }
              : null;
          return ;
        }(),
        title: () {
          if (kIsWeb) {
            return const Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(appTitle),
            );
          }
          return const DragToMoveArea(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(appTitle),
            ),
          );
        }(),
        actions: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 8.0),
              child: ToggleSwitch(
                content: const Text('Dark Mode'),
                checked: FluentTheme.of(context).brightness.isDark,
                onChanged: (v) {
                  if (v) {
                    appTheme.mode = ThemeMode.dark;
                    socket!.connect();
                  } else {
                     socket!.disconnect();
                    appTheme.mode = ThemeMode.light;
                     
                  }
                },
              ),
            ),
          ),

         
          if (!kIsWeb) const WindowButtons(),
        ]),
      ),
      paneBodyBuilder: (item, child) {
        final name =
            item?.key is ValueKey ? (item!.key as ValueKey).value : null;
        return FocusTraversalGroup(
          key: ValueKey('body$name'),
          child: widget.child,
        );
      },
      pane: NavigationPane(
        selected: _calculateSelectedIndex(context),
        header: SizedBox(
          height: kOneLineTileHeight,
          child: ShaderMask(
            shaderCallback: (rect) {
              final color = appTheme.color.defaultBrushFor(
                theme.brightness,
              );
              return LinearGradient(
                colors: [
                  color,
                  color,
                ],
              ).createShader(rect);
            },
       
          ),
        ),
        displayMode: appTheme.displayMode,
        indicator: () {
          switch (appTheme.indicator) {
            case NavigationIndicators.end:
              return const EndNavigationIndicator();
            case NavigationIndicators.sticky:
            default:
              return const StickyNavigationIndicator();
          }
        }(),
        
       
   
  
      items: [
        ...originalItems,
        ...myPaneItems,
        
      ],
      ),
   
    );
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose && mounted) {
      showDialog(
        context: context,
        builder: (_) {
          return ContentDialog(
            title: const Text('Confirm close'),
            content: const Text('Are you sure you want to close this window?'),
            actions: [
              FilledButton(
                child: const Text('Yes'),
                onPressed: () {
                  Navigator.pop(context);
                  windowManager.destroy();
                },
              ),
              Button(
                child: const Text('No'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final FluentThemeData theme = FluentTheme.of(context);

    return SizedBox(
      width: 138,
      height: 50,
      child: WindowCaption(
        brightness: theme.brightness,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}

class _LinkPaneItemAction extends PaneItem {
  _LinkPaneItemAction({
    required super.icon,
    required this.link,
    required super.body,
    super.title,
  });

  final String link;

  @override
  Widget build(
    BuildContext context,
    bool selected,
    VoidCallback? onPressed, {
    PaneDisplayMode? displayMode,
    bool showTextOnTop = true,
    bool? autofocus,
    int? itemIndex,
  }) {
    return Link(
      uri: Uri.parse(link),
      builder: (context, followLink) => Semantics(
        link: true,
        child: super.build(
          context,
          selected,
          followLink,
          displayMode: displayMode,
          showTextOnTop: showTextOnTop,
          itemIndex: itemIndex,
          autofocus: autofocus,
        ),
      ),
    );
  }
}

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(navigatorKey: rootNavigatorKey, routes: [
  ShellRoute(
    navigatorKey: _shellNavigatorKey,
    builder: (context, state, child) {
      return MyHomePage(
        shellContext: _shellNavigatorKey.currentContext,
        child: child,
      );
    },
    
    routes: [
      GoRoute(path: '/', builder: (context, state) => const ConnectPage()),
    GoRoute(path: '/dismisable', builder: (context, state) =>  sampleHome(title: 'asdasd',)),
   GoRoute(path: '/roomPages', builder: (context, state) =>   RoomPage(RoomDetailed.room!, RoomDetailed.listener!)),
    ],
  ),
]);
