import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';
import 'router.dart';
import 'theme.dart';

class EventApp extends ConsumerWidget {
  const EventApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'EventSys Scanner',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
      builder: (context, child) {
        final screenWidth = MediaQuery.sizeOf(context).width;
        final topPadding = MediaQuery.paddingOf(context).top;

        return ToastificationWrapper(
          config: ToastificationConfig(
            alignment: Alignment.topCenter,
            itemWidth: screenWidth * 0.95,
            marginBuilder: (context, alignment) {
              return EdgeInsets.only(top: topPadding + 8);
            },
            maxTitleLines: 4,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
