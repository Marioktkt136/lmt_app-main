# Layout & Navigation Shell (`lib/features/layout`)

Hosts the primary 5-tab `PageView` shell (`Posts`, `Chats`, `Shared Files`, `Calendar`, `Members`), the top `CustomAppBar`, the offline connectivity banner, the `LmtNavigationDrawer`, and the `BottomNavBar`.

## Structure
- `cubit/layout_cubit.dart`: `LayoutCubitMixin` tab selection, manual sync, and demo reset.
- `views/layout.dart`: Primary `Scaffold` and swipeable `PageView`.
- `widgets/lmt_navigation_drawer.dart`: Side drawer with quick links (`Spiritual Khelwa`, `YouTube Channel`, `Settings`) and the **Log-out** button anchored at the bottom.
