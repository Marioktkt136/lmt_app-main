import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/colors.dart';
import '../cubit/chat_cubit.dart';
import '../widgets/conversation_header_bar.dart';
import '../widgets/group_conversation_room.dart';

/// Full-screen pushed page for an active chat group conversation.
///
/// - Uses [ConversationHeaderBar] as a full-width edge-to-edge mobile [AppBar]
///   (not a floating island card) with harmonized Light/Dark status bar colors.
/// - Tapping the group avatar or name in the [AppBar] opens the Update Group sheet.
/// - Pressing the system Back button / back gesture pops this screen and returns
///   directly to the Chatting Room Groups List.
class GroupConversationPage extends StatelessWidget {
  /// The ID of the chat group to display.
  final String groupId;

  /// Creates a [GroupConversationPage].
  const GroupConversationPage({
    super.key,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LmtCubit, LmtState>(
      builder: (context, state) {
        final group =
            state.chatGroups.where((g) => g.id == groupId).firstOrNull;

        if (group == null) {
          return Scaffold(
            backgroundColor: AppColors.backgroundOf(context),
            appBar: AppBar(
              backgroundColor: AppColors.primaryOf(context),
              foregroundColor: Colors.white,
            ),
            body: const SizedBox.shrink(),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundOf(context),
          appBar: ConversationHeaderBar(
            group: group,
            state: state,
            onBack: () => Navigator.of(context).maybePop(),
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              child: GroupConversationRoom(
                group: group,
                onBack: () => Navigator.of(context).maybePop(),
                showInlineHeader: false,
              ),
            ),
          ),
        );
      },
    );
  }
}
