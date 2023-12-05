

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/pages.dart';


class AnlyticsPages extends StatefulWidget {
  const AnlyticsPages({super.key});

  @override
  State<AnlyticsPages> createState() => _AnlyticsPagesState();
}

class _AnlyticsPagesState extends State<AnlyticsPages> with PageMixin {
  bool selected = true;
  String? comboboxValue;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasFluentTheme(context));
    final theme = FluentTheme.of(context);

    return ScaffoldPage.scrollable(
  
      children: [
        Center(child: Container(
          child: ElevatedButton(onPressed: ()  =>   GoRouter.of(context).pop(), child: Text("data")),
        ),)
      ],
    );
  }
}
