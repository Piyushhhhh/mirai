import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mirai/src/action_parsers/action_parsers.dart';
import 'package:mirai/src/action_parsers/mirai_network_request/mirai_network_request_parser.dart';
import 'package:mirai/src/framework/mirai_registry.dart';
import 'package:mirai/src/parsers/parsers.dart';
import 'package:mirai/src/services/mirai_network_service.dart';
import 'package:mirai/src/utils/log.dart';
import 'package:mirai_framework/mirai_framework.dart';

typedef ErrorWidgetBuilder = Widget Function(
  BuildContext context,
  dynamic error,
);

typedef LoadingWidgetBuilder = Widget Function(BuildContext context);

class Mirai {
  static final List<MiraiParser> _defaultParsers = [
    const MiraiContainerParser(),
    const MiraiTextParser(),
    const MiraiTextFieldParser(),
    const MiraiElevatedButtonParser(),
    const MiraiImageParser(),
    const MiraiIconParser(),
    const MiraiCenterParser(),
    const MiraiRowParser(),
    const MiraiColumnParser(),
    const MiraiStackParser(),
    const MiraiPositionedParser(),
    const MiraiIconButtonParser(),
    const MiraiFloatingActionButtonParser(),
    const MiraiOutlinedButtonParser(),
    const MiraiPaddingParser(),
    const MiraiAppBarParser(),
    const MiraiTextButtonParser(),
    const MiraiScaffoldParser(),
    const MiraiSizedBoxParser(),
    const MiraiFractionallySizedBoxParser(),
    const MiraiTextFormFieldParser(),
    const MiraiTabBarViewParser(),
    const MiraiTabBarParser(),
    const MiraiListTileParser(),
    const MiraiCardParser(),
    const MiraiBottomNavigationBarParser(),
    const MiraiListViewParser(),
    const MiraiDefaultTabControllerParser(),
    const MiraiSingleChildScrollViewParser(),
    const MiraiAlertDialogParser(),
    const MiraiTabParser(),
    const MiraiFormParser(),
    const MiraiCheckBoxWidgetParser(),
    const MiraiExpandedParser(),
    const MiraiFlexibleParser(),
    const MiraiSpacerParser(),
    const MiraiSafeAreaParser(),
    const MiraiSwitchParser(),
    const MiraiAlignParser(),
    const MiraiPageViewParser(),
    const MiraiRefreshIndicatorParser(),
    const MiraiNetworkWidgetParser(),
    const MiraiCircleAvatarParser(),
    const MiraiChipParser(),
    const MiraiGridViewParser(),
    const MiraiFilledButtonParser(),
    const MiraiBottomNavigationViewParser(),
    const MiraiDefaultBottomNavigationControllerParser(),
    const MiraiWrapParser(),
    const MiraiAutoCompleteParser(),
    const MiraiTableParser(),
    const MiraiTableCellParser(),
  ];

  static final List<MiraiActionParser> _defaultActionParsers = [
    const MiraiNoneActionParser(),
    const MiraiNavigateActionParser(),
    const MiraiNetworkRequestParser(),
    const MiraiModalBottomSheetActionParser(),
    const MiraiDialogActionParser(),
    const MiraiGetFormValueParser(),
    const MiraiFormValidateParser(),
  ];

  static Future<void> initialize({
    List<MiraiParser> parsers = const [],
    List<MiraiActionParser> actionParsers = const [],
    Dio? dio,
  }) async {
    MiraiRegistry.instance.registerAll([..._defaultParsers, ...parsers]);
    MiraiRegistry.instance.registerAllActions([..._defaultActionParsers, ...actionParsers]);
    MiraiNetworkService.initialize(dio ?? Dio());
  }

  static Widget? fromJson(Map<String, dynamic>? json, BuildContext context) {
    if (json == null) return null;

    try {
      final String widgetType = json['type'];
      final MiraiParser? parser = MiraiRegistry.instance.getParser(widgetType);
      if (parser != null) {
        final model = parser.getModel(json);
        return parser.parse(context, model);
      } else {
        Log.w('Widget type [$widgetType] not supported');
      }
    } catch (e) {
      Log.e('Error parsing widget from JSON: $e');
    }
    return null;
  }

  static FutureOr<dynamic> onCallFromJson(
    Map<String, dynamic>? json,
    BuildContext context,
  ) {
    if (json == null || json['actionType'] == null) return null;

    try {
      final String actionType = json['actionType'];
      final MiraiActionParser? actionParser = MiraiRegistry.instance.getActionParser(actionType);
      if (actionParser != null) {
        final model = actionParser.getModel(json);
        return actionParser.onCall(context, model);
      } else {
        Log.w('Action type [$actionType] not supported');
      }
    } catch (e) {
      Log.e('Error handling action from JSON: $e');
    }
    return null;
  }

  static Widget fromNetwork({
    required BuildContext context,
    required MiraiNetworkRequest request,
    LoadingWidgetBuilder? loadingWidget,
    ErrorWidgetBuilder? errorWidget,
  }) {
    return _buildFutureWidget(
      future: MiraiNetworkService.request(context, request),
      context: context,
      loadingWidget: loadingWidget,
      errorWidget: errorWidget,
    );
  }

  static Widget fromAssets(
    String assetPath, {
    LoadingWidgetBuilder? loadingWidget,
    ErrorWidgetBuilder? errorWidget,
  }) {
    return _buildFutureWidget(
      future: rootBundle.loadString(assetPath),
      context: context,
      loadingWidget: loadingWidget,
      errorWidget: errorWidget,
    );
  }

  static Widget _buildFutureWidget({
    required Future<dynamic> future,
    required BuildContext context,
    LoadingWidgetBuilder? loadingWidget,
    ErrorWidgetBuilder? errorWidget,
  }) {
    return FutureBuilder<dynamic>(
      future: future,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return loadingWidget?.call(context) ?? const SizedBox();
          case ConnectionState.done:
            if (snapshot.hasData) {
              final json = jsonDecode(snapshot.data.toString());
              return Mirai.fromJson(json, context) ?? const SizedBox();
            } else if (snapshot.hasError) {
              Log.e('Error loading data: ${snapshot.error}');
              return errorWidget?.call(context, snapshot.error) ?? const SizedBox();
            }
            break;
          default:
            break;
        }
        return const SizedBox();
      },
    );
  }
}

extension MiraiExtension on Widget? {
  PreferredSizeWidget? get toPreferredSizeWidget => this as PreferredSizeWidget?;
}
