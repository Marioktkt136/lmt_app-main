# Members Management Feature (`lib/features/members`)

Displays the team member directory with search, role filtering (`Admin`, `Editor`, `Member`), and role-based member management.

## Authority Rules
- **Admin**: Can create accounts of any role, change any member's role, edit details, and delete members.
- **Editor**: Can create `Member` or `Editor` accounts and upgrade a `Member` to `Editor`.
- **Member**: Read-only directory access.

## Structure
- `cubit/members_cubit.dart`: `MembersCubitMixin` CRUD and role authority checks.
- `views/members_screen.dart`: Search bar, role filter chips, and member cards list.
- `widgets/member_card.dart`: Member identity card with role badge, committee, specialty, and joined groups.
- `widgets/member_sheets.dart`: Add Member and Manage Member Role bottom sheets.
