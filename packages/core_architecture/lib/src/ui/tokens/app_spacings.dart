/// The spacing ramp.
///
/// One set of values, exposed under three names. `w*`, `h*` and `r*` are the
/// same numbers — they differ only in reading well at the call site
/// (`horizontal(wMd)`, `SizedBox(height: hMd)`, `circular(rMd)`). They used to
/// be three independent lists of literals, which meant they could drift apart
/// without anything noticing; now each one points at the same constant.
final class AppSpacings {
  AppSpacings._();

  static const double _xxs = 4;
  static const double _xs = 8;
  static const double _sm = 12;
  static const double _md = 16;
  static const double _lg = 24;
  static const double _xl = 32;
  static const double _xxl = 40;

  // Width-based spacings
  static const double wXxs = _xxs;
  static const double wXs = _xs;
  static const double wSm = _sm;
  static const double wMd = _md;
  static const double wLg = _lg;
  static const double wXl = _xl;
  static const double wXxl = _xxl;

  // Height-based spacings
  static const double hXxs = _xxs;
  static const double hXs = _xs;
  static const double hSm = _sm;
  static const double hMd = _md;
  static const double hLg = _lg;
  static const double hXl = _xl;
  static const double hXxl = _xxl;

  // Radius-based spacings
  static const double rXxs = _xxs;
  static const double rXs = _xs;
  static const double rSm = _sm;
  static const double rMd = _md;
  static const double rLg = _lg;
  static const double rXl = _xl;
  static const double rXxl = _xxl;
}
