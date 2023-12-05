

import 'dart:math';

import 'package:floating_chat_button/floating_chat_button.dart';
import 'package:fluent_ui/fluent_ui.dart' as flue;
import 'package:flutter/material.dart';

import 'widgets/dismisablebottom.dart';
class sampleHome extends StatefulWidget {
  const sampleHome({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<sampleHome> createState() => _sampleHomeState();
}

class _sampleHomeState extends State<sampleHome> {
 
  int tabBarIndex = 0;
 int currentIndex = 0;
List<flue.Tab> tabs = [];

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


Future<void> _showBottomSheet(BuildContext bContext) async {
  return showModalBottomSheet(
    enableDrag: false,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    context: bContext,
    builder: (context) => Container(
      alignment: Alignment.bottomRight, // Mengatur alignment ke kiri
      child: DismissibleBottomSheetView(
        childView: Container(
          width: 300,
          height: 200,
          color: Colors.white,
          child:  Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.close,color: Colors.black,))
                ],
              ),
            ),
        ),
      ),
    ),
  );
}


  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return  FloatingChatButton(
       
            onTap: (_) {
              _showBottomSheet(context);
            },
               shouldPutWidgetInCircle : true,
            showMessageParameters: ShowMessageParameters(
                delayDuration: const Duration(seconds: 1),
                showMessageFrequency: 0.5));
      default:
        return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: 
flue.TabView(
    tabs: tabs!,
    currentIndex: currentIndex,
    onChanged: (index) => setState(() => currentIndex = index),
    tabWidthBehavior: flue.TabWidthBehavior.equal,
    closeButtonVisibility: flue.CloseButtonVisibilityMode.onHover,
    showScrollButtons: true,
   
    onNewPressed: () {
        setState(() {
            final index = tabs!.length + 1;
            final tab = generateTab(index);
            tabs!.add(tab);
        });
    },
    onReorder: (oldIndex, newIndex) {
        setState(() {
            if (oldIndex < newIndex) {
                newIndex -= 1;
            }
            final item = tabs!.removeAt(oldIndex);
            tabs!.insert(newIndex, item);

            if (currentIndex == newIndex) {
                currentIndex = oldIndex;
            } else if (currentIndex == oldIndex) {
                currentIndex = newIndex;
            }
        });
    },
)

    );
  }
}