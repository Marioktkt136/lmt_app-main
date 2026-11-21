# Khelwa feature

Daily spiritual "Khelwa" tracker: day counter, record button, today's attendees.

```
khelwa/
  cubit/khelwa_cubit.dart        # KhelwaCubitMixin (group summary publishing)
  data/khelwa_repository.dart    # SharedPreferences logic + KhelwaSnapshot
  views/khelwa_screen.dart       # screen: state + composition only
  widgets/
    khelwa_counter_circle.dart   # blue counter
    khelwa_take_button.dart      # green action button
    khelwa_attendees_card.dart   # today's list + open-group button
    khelwa_attendee_chip.dart    # one attendee pill
    khelwa_snackbars.dart        # success / error feedback
```

## Conventions
- Storage keys are fixed (`last_khelwa_date_<userId>`, `khelwa_attendees_<yyyy-MM-dd>`); do not rename.
- Never touch SharedPreferences from widgets; add methods to `KhelwaRepository`.
- Colors from `AppColors`; Khelwa brand blue/green are local constants in widgets.
- Every public class/method needs a `///` doc.
