import 'package:flutter/material.dart';

/// TS Minicab's visual system, carried over from tsminicab.com: navy leads,
/// orange is spent only on the one action that moves a job forward and on
/// "in progress" states, everything else sits on cool navy-tinted neutrals.
/// One family (Figtree, bundled) across headings, labels, body and data;
/// times, fares and references use tabular figures so columns line up.
abstract final class Brand {
  static const navy900 = Color(0xFF081A30);
  static const navy800 = Color(0xFF0E2A4D);
  static const navy700 = Color(0xFF16385F);
  static const navy500 = Color(0xFF3D5B80);
  static const navy100 = Color(0xFFE7ECF3);
  static const orange = Color(0xFFE2560B);
  static const orangeDeep = Color(0xFFC9490A);
  static const orangeSoft = Color(0xFFFDEEE4);
  static const fontFamily = 'Figtree';
}

/// Tabular (fixed-width) digits — times, fares, booking refs, counts.
const tabularFigures = [FontFeature.tabularFigures()];

/// Colours for the booking lifecycle and document compliance, resolved per
/// theme. Every pill pairs its colour with a word, never colour alone.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.waiting,
    required this.onWaiting,
    required this.open,
    required this.onOpen,
    required this.assigned,
    required this.onAssigned,
    required this.live,
    required this.onLive,
    required this.done,
    required this.onDone,
    required this.stopped,
    required this.onStopped,
  });

  final Color waiting, onWaiting; // pending approval, review, expiring
  final Color open, onOpen; // released to drivers
  final Color assigned, onAssigned; // driver accepted
  final Color live, onLive; // en route, arrived, on board
  final Color done, onDone; // completed, verified
  final Color stopped, onStopped; // cancelled, rejected, expired

  static const light = StatusColors(
    waiting: Color(0xFFFFF1D6),
    onWaiting: Color(0xFF7A4B00),
    open: Color(0xFFE3EAF4),
    onOpen: Color(0xFF223E63),
    assigned: Color(0xFFDCE6F7),
    onAssigned: Brand.navy800,
    live: Brand.orangeSoft,
    onLive: Color(0xFF9A3A06),
    done: Color(0xFFDDF3E4),
    onDone: Color(0xFF17643A),
    stopped: Color(0xFFFBE3E1),
    onStopped: Color(0xFF9B1C14),
  );

  static const dark = StatusColors(
    waiting: Color(0xFF4A3509),
    onWaiting: Color(0xFFFFD58A),
    open: Color(0xFF1C3554),
    onOpen: Color(0xFFC3D3EA),
    assigned: Color(0xFF213F66),
    onAssigned: Color(0xFFD6E3F7),
    live: Color(0xFF4F2510),
    onLive: Color(0xFFFFB98F),
    done: Color(0xFF15402A),
    onDone: Color(0xFF9EE0B6),
    stopped: Color(0xFF4D1915),
    onStopped: Color(0xFFFFB4AB),
  );

  @override
  StatusColors copyWith() => this;

  @override
  StatusColors lerp(ThemeExtension<StatusColors>? other, double t) {
    if (other is! StatusColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return StatusColors(
      waiting: l(waiting, other.waiting),
      onWaiting: l(onWaiting, other.onWaiting),
      open: l(open, other.open),
      onOpen: l(onOpen, other.onOpen),
      assigned: l(assigned, other.assigned),
      onAssigned: l(onAssigned, other.onAssigned),
      live: l(live, other.live),
      onLive: l(onLive, other.onLive),
      done: l(done, other.done),
      onDone: l(onDone, other.onDone),
      stopped: l(stopped, other.stopped),
      onStopped: l(onStopped, other.onStopped),
    );
  }
}

extension StatusColorsX on BuildContext {
  StatusColors get statusColors => Theme.of(this).extension<StatusColors>()!;
}

const _radiusCard = 18.0;
const _radiusControl = 14.0;

const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Brand.navy800,
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFDCE6F7),
  onPrimaryContainer: Brand.navy900,
  secondary: Brand.navy500,
  onSecondary: Colors.white,
  secondaryContainer: Brand.navy100,
  onSecondaryContainer: Brand.navy800,
  tertiary: Brand.orange,
  onTertiary: Colors.white,
  tertiaryContainer: Brand.orangeSoft,
  onTertiaryContainer: Color(0xFF7A2E04),
  error: Color(0xFFB3261E),
  onError: Colors.white,
  errorContainer: Color(0xFFFBE3E1),
  onErrorContainer: Color(0xFF7A1610),
  surface: Color(0xFFF4F6F9),
  onSurface: Color(0xFF0F1B2B),
  onSurfaceVariant: Color(0xFF4F5D70),
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: Color(0xFFFAFBFC),
  surfaceContainer: Color(0xFFEEF1F5),
  surfaceContainerHigh: Color(0xFFE7EBF1),
  surfaceContainerHighest: Color(0xFFDFE4EB),
  outline: Color(0xFF8592A3),
  outlineVariant: Color(0xFFD6DCE4),
  inverseSurface: Brand.navy800,
  onInverseSurface: Colors.white,
  inversePrimary: Color(0xFFAFC6E8),
  shadow: Color(0xFF081A30),
  scrim: Color(0xFF081A30),
);

const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFAFC6E8),
  onPrimary: Brand.navy900,
  primaryContainer: Color(0xFF213F66),
  onPrimaryContainer: Color(0xFFD6E3F7),
  secondary: Color(0xFF9DB0C9),
  onSecondary: Brand.navy900,
  secondaryContainer: Color(0xFF1C3554),
  onSecondaryContainer: Color(0xFFD6E3F7),
  tertiary: Color(0xFFF26B24),
  onTertiary: Colors.white,
  tertiaryContainer: Color(0xFF4F2510),
  onTertiaryContainer: Color(0xFFFFDBC9),
  error: Color(0xFFFFB4AB),
  onError: Color(0xFF690005),
  errorContainer: Color(0xFF4D1915),
  onErrorContainer: Color(0xFFFFDAD6),
  surface: Color(0xFF071524),
  onSurface: Color(0xFFE6ECF3),
  onSurfaceVariant: Color(0xFFA9B6C6),
  surfaceContainerLowest: Color(0xFF050F1B),
  surfaceContainerLow: Color(0xFF0B1C30),
  surfaceContainer: Color(0xFF0E2238),
  surfaceContainerHigh: Color(0xFF132A44),
  surfaceContainerHighest: Color(0xFF1A3350),
  outline: Color(0xFF7487A0),
  outlineVariant: Color(0xFF243A56),
  inverseSurface: Color(0xFFE6ECF3),
  onInverseSurface: Brand.navy900,
  inversePrimary: Brand.navy800,
  shadow: Colors.black,
  scrim: Colors.black,
);

class AppTheme {
  static ThemeData light = _build(_lightScheme, StatusColors.light);
  static ThemeData dark = _build(_darkScheme, StatusColors.dark);

  /// The one forward action on a screen (Accept job, Start job, Approve,
  /// Save) is orange; everything else uses navy/tonal/outlined variants.
  static ButtonStyle primaryActionStyle(ColorScheme c) => FilledButton.styleFrom(
        backgroundColor: c.tertiary,
        foregroundColor: c.onTertiary,
        disabledBackgroundColor: c.onSurface.withValues(alpha: 0.12),
        minimumSize: const Size(64, 56),
        textStyle: const TextStyle(fontFamily: Brand.fontFamily, fontSize: 17, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusControl)),
      );

  static TextTheme _text(ColorScheme c) {
    TextStyle s(double size, FontWeight w, {double height = 1.3, double ls = 0}) => TextStyle(
          fontFamily: Brand.fontFamily,
          fontSize: size,
          fontWeight: w,
          height: height,
          letterSpacing: ls,
          color: c.onSurface,
        );
    return TextTheme(
      displaySmall: s(34, FontWeight.w800, height: 1.12, ls: -0.6),
      headlineLarge: s(30, FontWeight.w800, height: 1.15, ls: -0.5),
      headlineMedium: s(26, FontWeight.w800, height: 1.18, ls: -0.4),
      headlineSmall: s(22, FontWeight.w700, height: 1.22, ls: -0.2),
      titleLarge: s(20, FontWeight.w700, height: 1.25, ls: -0.1),
      titleMedium: s(16, FontWeight.w700, height: 1.3),
      titleSmall: s(14, FontWeight.w700, height: 1.3),
      bodyLarge: s(16, FontWeight.w500, height: 1.45),
      bodyMedium: s(14, FontWeight.w500, height: 1.45),
      bodySmall: s(12.5, FontWeight.w500, height: 1.4).copyWith(color: c.onSurfaceVariant),
      labelLarge: s(14, FontWeight.w700, height: 1.2, ls: 0.1),
      labelMedium: s(12.5, FontWeight.w600, height: 1.2, ls: 0.2),
      labelSmall: s(11.5, FontWeight.w600, height: 1.2, ls: 0.3),
    );
  }

  static ThemeData _build(ColorScheme c, StatusColors status) {
    final text = _text(c);
    final controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusControl));
    const buttonPadding = EdgeInsets.symmetric(vertical: 14, horizontal: 22);
    final isDark = c.brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: c,
      fontFamily: Brand.fontFamily,
      textTheme: text,
      scaffoldBackgroundColor: c.surface,
      extensions: [status],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        foregroundColor: c.onSurface,
        titleTextStyle: text.titleLarge,
        shape: Border(bottom: BorderSide(color: c.outlineVariant.withValues(alpha: 0.7))),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: c.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radiusCard),
          side: BorderSide(color: c.outlineVariant.withValues(alpha: isDark ? 1 : 0.8)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: controlShape,
          padding: buttonPadding,
          minimumSize: const Size(64, 48),
          textStyle: text.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(shape: controlShape, padding: buttonPadding, minimumSize: const Size(64, 48)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: controlShape,
          padding: buttonPadding,
          minimumSize: const Size(64, 48),
          side: BorderSide(color: c.outlineVariant, width: 1.5),
          foregroundColor: c.onSurface,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: controlShape,
          minimumSize: const Size(48, 48),
          foregroundColor: isDark ? c.primary : Brand.navy700,
          textStyle: text.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.tertiary,
        foregroundColor: c.onTertiary,
        elevation: 2,
        highlightElevation: 4,
        extendedTextStyle: text.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusControl),
          borderSide: BorderSide(color: c.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusControl),
          borderSide: BorderSide(color: c.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radiusControl),
          borderSide: BorderSide(color: c.primary, width: 2),
        ),
        labelStyle: text.bodyMedium?.copyWith(color: c.onSurfaceVariant),
        floatingLabelStyle: text.labelMedium?.copyWith(color: c.primary),
        helperStyle: text.bodySmall,
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: c.outlineVariant),
        backgroundColor: c.surfaceContainerLowest,
        labelStyle: text.labelMedium,
      ),
      listTileTheme: ListTileThemeData(
        titleTextStyle: text.titleSmall,
        subtitleTextStyle: text.bodySmall,
        iconColor: c.onSurfaceVariant,
        minVerticalPadding: 10,
      ),
      dividerTheme: DividerThemeData(color: c.outlineVariant.withValues(alpha: 0.8), space: 1, thickness: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        indicatorColor: c.primaryContainer,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => text.labelMedium?.copyWith(
            color: s.contains(WidgetState.selected) ? c.onSurface : c.onSurfaceVariant,
            fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.primaryContainer,
        selectedLabelTextStyle: text.labelMedium?.copyWith(color: c.onSurface, fontWeight: FontWeight.w700),
        unselectedLabelTextStyle: text.labelMedium?.copyWith(color: c.onSurfaceVariant),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: c.surfaceContainerLowest, surfaceTintColor: Colors.transparent),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: text.titleLarge,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: c.onInverseSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radiusControl)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.tertiary, linearTrackColor: c.surfaceContainerHighest),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: text.labelMedium?.copyWith(color: c.onSurfaceVariant),
        dataTextStyle: text.bodyMedium?.copyWith(fontFeatures: tabularFigures),
        dividerThickness: 1,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.tertiary,
        selectionColor: c.tertiary.withValues(alpha: 0.25),
        selectionHandleColor: c.tertiary,
      ),
    );
  }
}
