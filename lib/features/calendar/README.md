# Calendar & Reminders Feature (`lib/features/calendar`)

Provides the team rehearsal & service calendar, a 14-day quick selector strip, a full multi-month/year calendar screen, and exact lock-screen reminder notifications via `LocalNotificationService`.

## Structure
- `cubit/calendar_cubit.dart`: `CalendarCubitMixin` event & reminder operations.
- `views/calendar_screen.dart`: Primary Calendar tab view.
- `views/full_months_calendar_page.dart`: Full 12-month & day grid page.
- `widgets/calendar_days_strip.dart`: Horizontal 14-day quick filter strip.
- `widgets/full_calendar_launcher_card.dart`: Launcher card to open the full calendar page.
- `widgets/calendar_month_selector_card.dart`: Year & 12-month strip with event count badges.
- `widgets/calendar_month_days_grid.dart`: 7-column monthly day grid.
- `widgets/calendar_event_card.dart`, `calendar_event_date_badge.dart`, `calendar_event_meta.dart`, `calendar_event_menu.dart`, `calendar_reminder_bar.dart`: Modular event card components.
- `widgets/calendar_event_form_sheet.dart`: Add/Edit calendar event bottom sheet.
