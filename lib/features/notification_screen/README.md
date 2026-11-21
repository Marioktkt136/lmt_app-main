# Notifications Feature (`lib/features/notification_screen`)

Displays categorized in-app notifications and reminders (`Chat`, `Calendar`, `Shared Files`, `Posts`, `System`) with unread badges, mark-all-read, and deep navigation to the target tab, chat group, or route.

## Structure
- `cubit/notifications_cubit.dart`: `NotificationsCubitMixin` read-state management.
- `notification_screen.dart`: Filterable notification list with deep-link tap handling.
