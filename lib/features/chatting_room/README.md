# Chatting Room Feature (`lib/features/chatting_room`)

Implements team chatting groups, pinned groups, real voice notes, WhatsApp-style saved stickers, image/file attachments, emoji reactions, message replies, forwarding, editing, deletion, and seen/listened tracking.

## Structure
- `cubit/chat_cubit.dart`: `ChatCubitMixin` state operations.
- `views/chatting_room.dart`: Switches between the groups list and the active conversation room.
- `widgets/group_conversation_room.dart`: Active conversation room shell (`reverse: true` so it always opens on the latest message).
- `widgets/conversation_header_bar.dart`: Top group info bar + pin button.
- `widgets/conversation_composer_bar.dart`: Always-LTR input bar (`ConversationComposerBar`), `VoiceRecordingBar`, and `ReplyEditBanner`.
- `widgets/chat_message_bubble.dart` & `widgets/chat_message_body.dart`: Message bubble frame and per-type content renderer.
- `widgets/chat_group_tile.dart` & `widgets/chat_group_form_sheet.dart`: Chat group list card and create/edit group modal.
- `sheets/chat_attachment_menu_sheet.dart`: Attachment menu, send image sheet, and send file sheet.
- `sheets/chat_sticker_picker_sheet.dart`: WhatsApp-style saved stickers sheet (`AppPreferences.getSavedStickers`).
- `sheets/chat_message_actions_sheet.dart`: Emoji reactions, reply, copy, forward, seen-by, edit, and delete sheets.
