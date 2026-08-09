import 'package:flutter/widgets.dart';

enum FormFactor {
  compact,
  medium,
  expanded;

  int get gridColumns {
    switch (this) {
      case FormFactor.compact:
        return 2;
      case FormFactor.medium:
        return 3;
      case FormFactor.expanded:
        return 4;
    }
  }

  bool get isCompact => this == FormFactor.compact;
  bool get isExpanded => this == FormFactor.expanded;
}

FormFactor formFactorOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 1024) return FormFactor.expanded;
  if (width >= 600) return FormFactor.medium;
  return FormFactor.compact;
}

double maxBodyWidth(BuildContext context) {
  final factor = formFactorOf(context);
  switch (factor) {
    case FormFactor.compact:
      return double.infinity;
    case FormFactor.medium:
      return 720;
    case FormFactor.expanded:
      return 960;
  }
}