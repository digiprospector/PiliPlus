import 'package:PiliPlus/models/dynamics/result.dart'
    show DynamicsDataModel, ModuleBlocked;
import 'package:PiliPlus/pages/article/widgets/opus_content.dart'
    show moduleBlockedItem;
import 'package:material_ui/material_ui.dart';

Widget blockedItem(
  BuildContext context, {
  required ThemeData theme,
  required ModuleBlocked blocked,
}) {
  if (DynamicsDataModel.blockChargingVideo &&
      (blocked.hintMessage?.contains('充电') == true ||
          blocked.title?.contains('专属') == true ||
          blocked.button?.text?.contains('充电') == true)) {
    return const SizedBox.shrink();
  }
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 1),
    child: moduleBlockedItem(context, theme.colorScheme, blocked),
  );
}
