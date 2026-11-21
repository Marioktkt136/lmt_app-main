# Home / Posts Feed Feature (`lib/features/home`)

Implements the Timeline Posts Feed supporting Simple Posts, Interactive Polls (vote and unvote on second tap), Image/Video Media Posts, Likes, Comments, and the Annual Slogan & Verse Banner.

## Structure
- `cubit/posts_cubit.dart`: `PostsCubitMixin` state operations.
- `views/home_screen.dart`: Entry screen rendering `PostsList`.
- `widgets/post_list.dart`: Scrollable feed composing `YearVerseBanner`, `PostComposerCard`, and `TimelinePostCard` items.
- `widgets/year_verse_banner.dart`: Slogan & Bible Verse of the Year card.
- `widgets/post_composer_card.dart` & `widgets/composer_type_button.dart`: Quick post creation card.
- `sheets/create_post_sheet.dart`, `widgets/post_type_selector.dart`, `widgets/poll_options_editor.dart`, `widgets/media_picker_strip.dart`: Modular post creation bottom sheet components.
- `widgets/timeline_post_card.dart` & `widgets/post_comments_sheet.dart`: Post card with interactive poll voting/unvoting, likes, and comments modal.
