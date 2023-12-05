import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DismissibleBottomSheetView extends StatelessWidget {
  final Widget childView;

  const DismissibleBottomSheetView({required this.childView});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
     
      color: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            const SizedBox(height: 60),
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20)),
                child: childView,
              ),
            ),
          
          ],
        ),
      ),
    );
  }
}