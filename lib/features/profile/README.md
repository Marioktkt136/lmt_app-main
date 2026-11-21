# Profile Feature (`lib/features/profile`)

Displays the authenticated user's profile (`ID`, `Name`, `Role`, `Specialist at`, `Committee`, and `Joined Groups`), profile editor, and password update flow.

## Structure
- `cubit/profile_cubit.dart`: `ProfileCubitMixin` profile & password update operations.
- `views/profile_screen.dart`: User identity header card, details card, joined groups chips, and update password button.
- `widgets/profile_info_row.dart`: Single labelled profile attribute row.
- `widgets/profile_sheets.dart`: Edit Profile info sheet and Update Password sheet.
