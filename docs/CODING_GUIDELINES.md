# Coding Guidelines

## Files
- One public class/widget per file; file name = `snake_case` of the class.
- Target ≤ 200 lines per file. If bigger, split into widgets/helpers.
- Screens (`views/`) only compose widgets and read state; logic goes to Cubits/services.

## Naming
- Classes `UpperCamelCase`, members `lowerCamelCase`, private members `_prefixed`.
- Cubit mixins `<Feature>CubitMixin`; sheets `show<Name>Sheet`; dialogs `show<Name>Dialog`.

## Documentation
- Every public class, method and field has a `///` dartdoc: what it does, when to use it, constraints.
- Non-obvious decisions get a short `//` comment explaining *why*.
- Each feature has a `README.md` with structure and "how to edit".

## SOLID
- **S**: a widget renders one thing; a cubit mixin handles one feature.
- **O**: extend via new widgets/mixins, don't modify unrelated code.
- **L/I**: depend on small abstractions (`LmtRepository`).
- **D**: UI depends on Cubits; Cubits depend on repository abstractions injected through `core/di`.

## Flutter practices
- Use `const` constructors where possible; avoid rebuilding large trees (use `BlocBuilder` with `buildWhen`).
- Never use `BuildContext` after `await` without `if (!mounted)` / `context.mounted`.
- Import UI from `package:material_ui/material_ui.dart`.
- Keep colors/typography in `core/theme`; no hard-coded colors in features except brand accents.
- Always dispose controllers, timers and subscriptions.
- Run `flutter analyze` – the project must stay at **0 issues** before every commit.
