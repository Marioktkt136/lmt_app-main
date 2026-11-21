# UI / UX Guidelines

1. **Clarity first**: one primary action per screen/sheet, clearly labelled (verb + object: "Save changes").
2. **Touch targets** ≥ 48×48 dp; spacing in multiples of 4/8 dp using `ScreenUtil` (`.w/.h/.sp/.r`).
3. **Feedback**: every action gives feedback (snackbar, progress indicator, disabled state). Destructive actions ask for confirmation.
4. **Empty / loading / error states** are always designed (`LmtEmptyState`, progress indicators, retry hint).
5. **Bilingual**: all layouts must work in Arabic (RTL) and English (LTR). Exception: the chat composer row stays LTR by design.
6. **Theme**: use `AppColors.*Of(context)` so Light/Dark (WCAG AA) both work; use `LmtCard` / `AppColors.cardShadows` for elevation consistency.
7. **Accessibility**: tooltips on icon buttons, sufficient contrast, text scales with `sp`, no information by color alone.
8. **Forms**: inline validation messages, correct keyboard type, visible password toggle, keyboard-safe bottom sheets (`viewInsets`).
9. **Navigation**: bottom bar for the 5 main areas, drawer for secondary pages with **Log-out as last item**.
10. **Consistency**: reuse global widgets in `core/widgets` before creating new ones.
