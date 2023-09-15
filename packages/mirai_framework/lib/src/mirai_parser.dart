import 'package:flutter/widgets.dart';

abstract class MiraiParser<T> {
  const MiraiParser();

  String get type;

  T getModel(Map<String, dynamic> json);

  Widget parse(BuildContext context, T model);
}
