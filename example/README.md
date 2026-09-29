# core_architecture demo

The app behind the **[▶ live demo](https://himera19.github.io/core_architecture/)**. Every page
shows one part of [`core_architecture`](../packages/core_architecture) running, re-branded
from a single purple `brandColor` with a custom loading spinner installed once on the theme.

| Page | Shows |
| --- | --- |
| Theme | `AppTheme`, the colour schemes, `themeProvider`, the type ramp |
| Tokens | spacing, radius, sizes, borders, elevation, opacity, durations |
| Widgets | buttons, text fields, dropdowns, a validating form, SnackBars |
| Responsive | breakpoints, `ResponsiveBuilder`, `ResponsiveValue`, `PlatformInfo` |
| Storage & providers | `StorageService`, onboarding state, logging, `CoreInitializer` |
| Utils | `DateHelper` in two locales, `Validators`, `SpacingUtils`, `UrlLauncher` |
| Domain | `BaseEntity`, `CrudContract`, failures and exceptions |

It depends on the core by path, so it always shows the source next to it rather than a published
tag. It uses no backend.

```bash
cd example
flutter run -d chrome
```

To see how a real app is laid out, scaffold one with [`core_architecture create`](../cli).
