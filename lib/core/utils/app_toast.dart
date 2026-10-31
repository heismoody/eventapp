import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

enum AppToastType { success, error, info, warning }

class AppToast {
  AppToast._();

  static void show(
    String message, {
    BuildContext? context,
    AppToastType type = AppToastType.info,
  }) {
    toastification.show(
      context: context,
      type: _toastType(type),
      style: ToastificationStyle.flatColored,
      icon: _icon(type),
      showIcon: true,
      title: Text(message),
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topCenter,
      showProgressBar: false,
      dragToClose: true,
      closeOnClick: true,
      pauseOnHover: false,
    );
  }

  static void success(String message, {BuildContext? context}) {
    show(message, context: context, type: AppToastType.success);
  }

  static void error(String message, {BuildContext? context}) {
    show(message, context: context, type: AppToastType.error);
  }

  static void info(String message, {BuildContext? context}) {
    show(message, context: context, type: AppToastType.info);
  }

  static void warning(String message, {BuildContext? context}) {
    show(message, context: context, type: AppToastType.warning);
  }

  static ToastificationType _toastType(AppToastType type) {
    return switch (type) {
      AppToastType.success => ToastificationType.success,
      AppToastType.error => ToastificationType.error,
      AppToastType.info => ToastificationType.info,
      AppToastType.warning => ToastificationType.warning,
    };
  }

  static Icon _icon(AppToastType type) {
    return switch (type) {
      AppToastType.success => Icon(
        Icons.check_circle_rounded,
        color: ToastificationType.success.color,
        size: 24,
      ),
      AppToastType.error => Icon(
        Icons.error_rounded,
        color: ToastificationType.error.color,
        size: 24,
      ),
      AppToastType.info => Icon(
        Icons.info_rounded,
        color: ToastificationType.info.color,
        size: 24,
      ),
      AppToastType.warning => Icon(
        Icons.warning_rounded,
        color: ToastificationType.warning.color,
        size: 24,
      ),
    };
  }
}
