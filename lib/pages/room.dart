import 'dart:convert';
import 'dart:math' as math;
import 'dart:math';

import 'package:fluent_ui/fluent_ui.dart' as flue;
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:livekit_example/class/classroom.dart';
import 'package:livekit_example/class/myapi.dart';
import 'package:livekit_example/widgets/pages.dart';
import 'package:http/http.dart' as http;
import '../exts.dart';
import '../widgets/controls.dart';
import '../widgets/dismisablebottom.dart';
import '../widgets/participant.dart';
import '../widgets/participant_info.dart';
import 'package:glassmorphism/glassmorphism.dart';
class RoomPage extends StatefulWidget {
  //
  final Room room;
  final EventsListener<RoomEvent> listener;

  const RoomPage(
    this.room,
    this.listener, {
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> with PageMixin {

  int currentIndex = 0;
List<Tab> tabs = [];

/// Creates a tab for the given index
flue.Tab generateTab(int index) {
    late flue.Tab tab;
    tab = flue.Tab(
        text: Text('Document $index'),
        semanticLabel: 'Document #$index',
        icon: const FlutterLogo(),
        body: Container(
            color: flue.Colors.accentColors[Random().nextInt(flue.Colors.accentColors.length)],
        ),
        onClosed: () {
            setState(() {
                tabs!.remove(tab);

                if (currentIndex > 0) currentIndex--;
            });
        },
    );
    return tab;
}
  List<ParticipantTrack> participantTracks = [];
  EventsListener<RoomEvent> get _listener => widget.listener;
  bool get fastConnection => widget.room.engine.fastConnectOptions != null;
     List<Map<String, dynamic>>? items; 
    String country  = '';
  void getdata()async{

setState((){

List<String> splitText = ClassStatus.country.split(',');
country = splitText.first;

  print('Teks sebelum koma: $country');

});
final response = await http.post(Uri.parse('http://api.rsummi.co.id:1842/rsummi-api/GetNomorRekam'),body : {
  'norekam' : RoomDetailed.rekam_medis
});
  print('response nya ${jsonDecode(response.body)}');
  if(jsonDecode(response.body)['metadata']['code'] == 200){
    final List<dynamic> responseData = jsonDecode(response.body)['response'];
    setState(() {
       items = responseData.map((data) {
          return {
            'jenis_kelamin':  data['jenis_kelamin'],
            'nama_lengkap': capitalize(data['nama_lengkap']) ,
            'tanggal_lahir':'${ calculateAge( data['tanggal_lahir'])} Tahun',
          };
        }).toList();
    });
  }
  }


   String calculateAge(String birthDate) {
    DateTime today = DateTime.now();
    DateTime birthDateTime = DateTime.parse(birthDate);
    
    int age = today.year - birthDateTime.year;
    if (today.month < birthDateTime.month ||
        (today.month == birthDateTime.month && today.day < birthDateTime.day)) {
      age--;
    }
    return age.toString();
  }
  @override
  void initState() {
    super.initState();
    getdata();
    // add callback for a `RoomEvent` as opposed to a `ParticipantEvent`
    widget.room.addListener(_onRoomDidUpdate);
    // add callbacks for finer grained events
    _setUpListeners();
    _sortParticipants();
    WidgetsBindingCompatible.instance?.addPostFrameCallback((_) {
      if (!fastConnection) {
        _askPublish();
      }
    });

    if (lkPlatformIsMobile()) {
      Hardware.instance.setSpeakerphoneOn(true);
    }
  }

  @override
  void dispose() {
    // always dispose listener
    (() async {
      widget.room.removeListener(_onRoomDidUpdate);
      await _listener.dispose();
      await widget.room.dispose();
      ClassStatus.sedangcall = false;
    })();
    super.dispose();
  }

  /// for more information, see [event types](https://docs.livekit.io/client/events/#events)
  void _setUpListeners() => _listener
    ..on<RoomDisconnectedEvent>((event) async {
      if (event.reason != null) {
        print('Room disconnected: reason => ${event.reason}');
      }
      WidgetsBindingCompatible.instance
          ?.addPostFrameCallback((timeStamp) => Navigator.pop(context));
    })
    ..on<ParticipantEvent>((event) {
      print('Participant event');
      // sort participants on many track events as noted in documentation linked above
      _sortParticipants();
    })
    ..on<RoomRecordingStatusChanged>((event) {
      context.showRecordingStatusChangedDialog(event.activeRecording);
    })
    ..on<LocalTrackPublishedEvent>((_) => _sortParticipants())
    ..on<LocalTrackUnpublishedEvent>((_) => _sortParticipants())
    ..on<TrackE2EEStateEvent>(_onE2EEStateEvent)
    ..on<ParticipantNameUpdatedEvent>((event) {
      print(
          'Participant name updated: ${event.participant.identity}, name => ${event.name}');
      _sortParticipants();
    })
    ..on<ParticipantMetadataUpdatedEvent>((event) {
      print(
          'Participant metadata updated: ${event.participant.identity}, metadata => ${event.metadata}');
    })
    ..on<RoomMetadataChangedEvent>((event) {
      print('Room metadata changed: ${event.metadata}');
    })
    ..on<DataReceivedEvent>((event) {
      String decoded = 'Failed to decode';
      try {
        decoded = utf8.decode(event.data);
      } catch (_) {
        print('Failed to decode: $_');
      }
      context.showDataReceivedDialog(decoded);
    })
    ..on<AudioPlaybackStatusChanged>((event) async {
      if (!widget.room.canPlaybackAudio) {
        print('Audio playback failed for iOS Safari ..........');
        bool? yesno = await context.showPlayAudioManuallyDialog();
        if (yesno == true) {
          await widget.room.startAudio();
        }
      }
    });
String? capitalize(String? text) {
  if (text == null || text.isEmpty) {
    return text;
  }

  final words = text.split(' ');
  final capitalizedWords = words.map((word) {
    if (word.length > 1) {
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    } else {
      return word.toUpperCase();
    }
  });

  return capitalizedWords.join(' ');
}
  void _askPublish() async {
    final result = await context.showPublishDialog();
    if (result == true) return;
    // video will fail when running in ios simulator
    try {
      await widget.room.localParticipant?.setCameraEnabled(true);
    } catch (error) {
      print('could not publish video: $error');
      await context.showErrorDialog(error);
    }
    try {
      await widget.room.localParticipant?.setMicrophoneEnabled(true);
    } catch (error) {
      print('could not publish audio: $error');
      await context.showErrorDialog(error);
    }
  }

  void _onRoomDidUpdate() {
    _sortParticipants();
  }

  void _onE2EEStateEvent(TrackE2EEStateEvent e2eeState) {
    print('e2ee state: $e2eeState');
  }

  void _sortParticipants() {
    List<ParticipantTrack> userMediaTracks = [];
    List<ParticipantTrack> screenTracks = [];
    for (var participant in widget.room.participants.values) {
      for (var t in participant.videoTracks) {
        if (t.isScreenShare) {
          screenTracks.add(ParticipantTrack(
            participant: participant,
            videoTrack: t.track,
            isScreenShare: true,
          ));
        } else {
          userMediaTracks.add(ParticipantTrack(
            participant: participant,
            videoTrack: t.track,
            isScreenShare: false,
          ));
        }
      }
    }
    // sort speakers for the grid
    userMediaTracks.sort((a, b) {
      // loudest speaker first
      if (a.participant.isSpeaking && b.participant.isSpeaking) {
        if (a.participant.audioLevel > b.participant.audioLevel) {
          return -1;
        } else {
          return 1;
        }
      }

      // last spoken at
      final aSpokeAt = a.participant.lastSpokeAt?.millisecondsSinceEpoch ?? 0;
      final bSpokeAt = b.participant.lastSpokeAt?.millisecondsSinceEpoch ?? 0;

      if (aSpokeAt != bSpokeAt) {
        return aSpokeAt > bSpokeAt ? -1 : 1;
      }

      // video on
      if (a.participant.hasVideo != b.participant.hasVideo) {
        return a.participant.hasVideo ? -1 : 1;
      }

      // joinedAt
      return a.participant.joinedAt.millisecondsSinceEpoch -
          b.participant.joinedAt.millisecondsSinceEpoch;
    });

    final localParticipantTracks = widget.room.localParticipant?.videoTracks;
    if (localParticipantTracks != null) {
      for (var t in localParticipantTracks) {
        if (t.isScreenShare) {
          screenTracks.add(ParticipantTrack(
            participant: widget.room.localParticipant!,
            videoTrack: t.track,
            isScreenShare: true,
          ));
        } else {
          userMediaTracks.add(ParticipantTrack(
            participant: widget.room.localParticipant!,
            videoTrack: t.track,
            isScreenShare: false,
          ));
        }
      }
    }
    setState(() {
      participantTracks = [...screenTracks, ...userMediaTracks];
    });
  }
 final controller = flue.FlyoutController();
  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          height: MediaQuery.of(context).size.height,
          width:   MediaQuery.of(context).size.width,
          child:  Row(
                children: [
                  
                  Expanded(
                     flex: 6,
                    child: Column(
                      children: [
                         Expanded(
                          flex: 2,
                          child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                            flue.FlyoutTarget(
    controller: controller,
    child: 
GestureDetector(
  child:  GlassmorphicContainer(
            width: 200,
            height: 80,
            borderRadius: 8,
            blur: 10,
            alignment: Alignment.center,
            border: 2,
            linearGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.withOpacity(0.1),
                Colors.grey.withOpacity(0.05),
              ],
            ),
            borderGradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey.withOpacity(0.5),
                Colors.grey.withOpacity(0.2),
              ],
            ),
            
    child: flue.Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
             image: DecorationImage(
              
              fit: BoxFit.cover,
              image: NetworkImage( "https://mjengoflexi.com/wp-content/uploads/2022/05/Blank-male-Avatar.png",))
            ),
          ),
          SizedBox(width: 4),
          Text(
     
            "${items![0]['nama_lengkap']}",
                   overflow : TextOverflow.ellipsis)
        ],
      ),
    ),
  ),
  onTap: () {
    controller.showFlyout(
      // ... (bagian kode lainnya)
      builder: (context) {
        return flue.FlyoutContent(
          child: Container(
            width :600,
            child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    height: 150,
                    width: 150,
                    child: Image.network(
                      "https://mjengoflexi.com/wp-content/uploads/2022/05/Blank-male-Avatar.png",
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        'Detail Pasien',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12.0),
                      Text("Nama : ${items![0]['nama_lengkap']}"),
                      Text("Jenis Kelamin : ${items![0]['jenis_kelamin']}"),
                      Text("Umur : ${items![0]['tanggal_lahir']}"),
                    ],
                  ),
                ],
              ),
          )
        );
      },
    );
  },
)
),
Expanded(child: Container(
padding: EdgeInsets.all(18),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text( "Speed : ${ClassStatus.speed  == null ? "belum dimulai" :ClassStatus.speed }",style:TextStyle(
        fontSize: 21,fontWeight: FontWeight.bold
      ))
      ,
     Text( "Region : $country",style:TextStyle(
        fontSize: 21,fontWeight: FontWeight.bold
      ))
      ,
    ],
  ),
  margin:EdgeInsets.only(left : 120),
  height: 100,color:const flue.Color.fromARGB(255, 104, 56, 53)))

                            ],
                          ),
                          )),
                        Expanded(
                          flex: 9,
                            child: participantTracks.isNotEmpty
                                ?  Stack(
                                  children: [
                                    ParticipantWidget.widgetFor(participantTracks.first,
                                            showStatsLayer: true),
 if(participantTracks.length > 1)...[
                  Positioned(
                right: 12,
                bottom: 42,
                    child: SizedBox(
                        width: 180,
                        height: 160,
                        child: ParticipantWidget.widgetFor(
                            participantTracks[1]),
                      ),
                  ),
                 ],
     if (widget.room.localParticipant != null)
                  Positioned(
                    right: 0,
                    left: 0,
                    bottom: 62,
                    child: ControlsWidget(
                        widget.room, widget.room.localParticipant!),
                  ),
                 Text("${participantTracks.length}",style: TextStyle(
                  color: Colors.white
                 ),),

                
               
                //   Positioned(
                // right: 12,
                // bottom: 42,
                // child: SizedBox(
                //   height: 120,
                //   child: ListView.builder(
                //     scrollDirection: Axis.horizontal,
                //     itemCount: math.max(0, participantTracks.length - 1),
                //     itemBuilder: (BuildContext context, int index) => SizedBox(
                //       width: 180,
                //       height: 120,
                //       child: ParticipantWidget.widgetFor(
                //           participantTracks[index + 1]),
                //     ),
                //   ),
                // )),
                                  ],
                                )
                                : Container()),
                            Expanded(
                       flex: 1,
                      child: Container(color: Colors.red,)),
                           
                      ],
                    ),
                  ),               
                      Expanded(
                       flex: 1,
                      child: Container(color: Colors.red,)),
        
                ],
              ),
        ),
      );
}
