/// Available Milkdown themes based on @milkdown/crepe.
///
/// Each theme has a light and dark variant. Themes can be set at initialization
/// via [MilkdownEditor.theme] or changed at runtime via
/// [MilkdownController.setTheme].
///
/// Example:
/// ```dart
/// MilkdownEditor(
///   theme: MilkdownTheme.nord,
///   ...
/// )
///
/// // Runtime switching
/// await controller.setTheme(MilkdownTheme.nordDark);
/// ```
enum MilkdownTheme {
  /// Modern frame style (light).
  ///
  /// A clean, modern design with subtle borders and shadows.
  frame('frame'),

  /// Modern frame style (dark).
  ///
  /// Dark variant of [frame] theme for low-light environments.
  frameDark('frame-dark'),

  /// Nord color palette (light).
  ///
  /// Based on the Nord color scheme - arctic, north-bluish clean colors.
  nord('nord'),

  /// Nord color palette (dark).
  ///
  /// Dark variant of [nord] theme.
  nordDark('nord-dark');

  const MilkdownTheme(this.value);

  /// The string value passed to the JS layer.
  final String value;

  /// Returns true if this is a dark theme variant.
  bool get isDark => value.endsWith('-dark');

  /// Returns the light variant of this theme, or itself if already light.
  MilkdownTheme get lightVariant {
    return switch (this) {
      MilkdownTheme.frameDark => MilkdownTheme.frame,
      MilkdownTheme.nordDark => MilkdownTheme.nord,
      _ => this,
    };
  }

  /// Returns the dark variant of this theme, or itself if already dark.
  MilkdownTheme get darkVariant {
    return switch (this) {
      MilkdownTheme.frame => MilkdownTheme.frameDark,
      MilkdownTheme.nord => MilkdownTheme.nordDark,
      _ => this,
    };
  }

  /// Parses a theme string into a [MilkdownTheme] enum value.
  ///
  /// Returns `null` if the string doesn't match any known theme.
  static MilkdownTheme? tryParse(String value) {
    return switch (value) {
      'frame' => MilkdownTheme.frame,
      'frame-dark' => MilkdownTheme.frameDark,
      'nord' => MilkdownTheme.nord,
      'nord-dark' => MilkdownTheme.nordDark,
      _ => null,
    };
  }
}
