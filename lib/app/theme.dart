import 'package:flutter/material.dart';

/// Tema visual do Relato (UX-Fable): identidade "colete de campo" —
/// amarelo-sinalização sobre carvão (cores do ícone/splash), neutros de viés
/// quente e tokens semânticos para estados de sincronização.
///
/// Uso: `theme: RelatoTheme.light()`, `darkTheme: RelatoTheme.dark()`.
/// Estados de sync: `Theme.of(context).extension<SyncStatusColors>()!`.

/// Cores de marca e neutros base.
abstract final class RelatoColors {
  /// Amarelo-sinalização (mesmo do ícone adaptativo, #FFD51F).
  static const Color signal = Color(0xFFFFD51F);

  /// Variante do amarelo legível sobre fundo claro.
  static const Color signalInk = Color(0xFF7A6400);

  /// Carvão — superfície escura de marca (splash/login/FAB).
  static const Color charcoal = Color(0xFF12110A);

  /// Ground claro com viés quente (nunca cinza puro).
  static const Color paper = Color(0xFFFAF9F3);

  /// Ground escuro do dark theme.
  static const Color night = Color(0xFF161509);

  // Neutros quentes — light.
  static const Color inkLight = Color(0xFF191712);
  static const Color inkMutedLight = Color(0xFF6B6850);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color lineLight = Color(0xFFE7E4D4);
  static const Color fillLight = Color(0xFFF0EDDD);

  // Neutros quentes — dark.
  static const Color inkDark = Color(0xFFF2EFDE);
  static const Color inkMutedDark = Color(0xFFA6A37E);
  static const Color cardDark = Color(0xFF201E10);
  static const Color lineDark = Color(0xFF33301A);
  static const Color fillDark = Color(0xFF2B2913);
}

/// Cores semânticas dos estados de sincronização (par texto/fundo por estado).
///
/// Separadas do accent de marca: o amarelo sinaliza ação/navegação; estes
/// tokens sinalizam estado de dado (ok / pendente / em curso / falha / rascunho).
@immutable
class SyncStatusColors extends ThemeExtension<SyncStatusColors> {
  const SyncStatusColors({
    required this.synced,
    required this.syncedContainer,
    required this.pending,
    required this.pendingContainer,
    required this.syncing,
    required this.syncingContainer,
    required this.failed,
    required this.failedContainer,
    required this.draft,
    required this.draftContainer,
  });

  final Color synced;
  final Color syncedContainer;
  final Color pending;
  final Color pendingContainer;
  final Color syncing;
  final Color syncingContainer;
  final Color failed;
  final Color failedContainer;
  final Color draft;
  final Color draftContainer;

  static const SyncStatusColors light = SyncStatusColors(
    synced: Color(0xFF2E7D32),
    syncedContainer: Color(0xFFE3F1E4),
    pending: Color(0xFFA34E09),
    pendingContainer: Color(0xFFFCEED8),
    syncing: Color(0xFF2563EB),
    syncingContainer: Color(0xFFE3ECFC),
    failed: Color(0xFFC0392B),
    failedContainer: Color(0xFFFBE4E1),
    draft: Color(0xFF6B6850),
    draftContainer: Color(0xFFEFEDE0),
  );

  static const SyncStatusColors dark = SyncStatusColors(
    synced: Color(0xFF7BC67F),
    syncedContainer: Color(0xFF17301B),
    pending: Color(0xFFF0A75A),
    pendingContainer: Color(0xFF382608),
    syncing: Color(0xFF7EA6F4),
    syncingContainer: Color(0xFF14233F),
    failed: Color(0xFFF08A7E),
    failedContainer: Color(0xFF3B1512),
    draft: Color(0xFFA6A37E),
    draftContainer: Color(0xFF2B2913),
  );

  @override
  SyncStatusColors copyWith({
    Color? synced,
    Color? syncedContainer,
    Color? pending,
    Color? pendingContainer,
    Color? syncing,
    Color? syncingContainer,
    Color? failed,
    Color? failedContainer,
    Color? draft,
    Color? draftContainer,
  }) {
    return SyncStatusColors(
      synced: synced ?? this.synced,
      syncedContainer: syncedContainer ?? this.syncedContainer,
      pending: pending ?? this.pending,
      pendingContainer: pendingContainer ?? this.pendingContainer,
      syncing: syncing ?? this.syncing,
      syncingContainer: syncingContainer ?? this.syncingContainer,
      failed: failed ?? this.failed,
      failedContainer: failedContainer ?? this.failedContainer,
      draft: draft ?? this.draft,
      draftContainer: draftContainer ?? this.draftContainer,
    );
  }

  @override
  SyncStatusColors lerp(ThemeExtension<SyncStatusColors>? other, double t) {
    if (other is! SyncStatusColors) return this;
    return SyncStatusColors(
      synced: Color.lerp(synced, other.synced, t)!,
      syncedContainer: Color.lerp(syncedContainer, other.syncedContainer, t)!,
      pending: Color.lerp(pending, other.pending, t)!,
      pendingContainer:
          Color.lerp(pendingContainer, other.pendingContainer, t)!,
      syncing: Color.lerp(syncing, other.syncing, t)!,
      syncingContainer:
          Color.lerp(syncingContainer, other.syncingContainer, t)!,
      failed: Color.lerp(failed, other.failed, t)!,
      failedContainer: Color.lerp(failedContainer, other.failedContainer, t)!,
      draft: Color.lerp(draft, other.draft, t)!,
      draftContainer: Color.lerp(draftContainer, other.draftContainer, t)!,
    );
  }
}

/// Acesso seguro aos tokens de sync: cai no conjunto padrão da luminosidade
/// quando o ThemeData não tem a extensão (ex.: MaterialApp cru nos testes).
extension SyncStatusColorsX on ThemeData {
  SyncStatusColors get syncStatusColors =>
      extension<SyncStatusColors>() ??
      (brightness == Brightness.dark
          ? SyncStatusColors.dark
          : SyncStatusColors.light);
}

/// Fábrica dos ThemeData claro/escuro do Relato.
abstract final class RelatoTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: RelatoColors.signal,
      brightness: Brightness.light,
    ).copyWith(
      primary: RelatoColors.charcoal,
      onPrimary: RelatoColors.signal,
      secondary: RelatoColors.signalInk,
      onSecondary: Colors.white,
      secondaryContainer: RelatoColors.fillLight,
      onSecondaryContainer: RelatoColors.inkLight,
      surface: RelatoColors.paper,
      onSurface: RelatoColors.inkLight,
      onSurfaceVariant: RelatoColors.inkMutedLight,
      outline: RelatoColors.inkMutedLight,
      outlineVariant: RelatoColors.lineLight,
      surfaceContainerLowest: RelatoColors.cardLight,
      surfaceContainerLow: RelatoColors.cardLight,
      surfaceContainer: RelatoColors.fillLight,
      surfaceContainerHigh: Color(0xFFEAE7D8),
      error: const Color(0xFFC0392B),
    );
    return _base(scheme, SyncStatusColors.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: RelatoColors.signal,
      brightness: Brightness.dark,
    ).copyWith(
      primary: RelatoColors.signal,
      onPrimary: RelatoColors.charcoal,
      secondary: RelatoColors.signal,
      onSecondary: RelatoColors.charcoal,
      secondaryContainer: RelatoColors.fillDark,
      onSecondaryContainer: RelatoColors.inkDark,
      surface: RelatoColors.night,
      onSurface: RelatoColors.inkDark,
      onSurfaceVariant: RelatoColors.inkMutedDark,
      outline: RelatoColors.inkMutedDark,
      outlineVariant: RelatoColors.lineDark,
      surfaceContainerLowest: RelatoColors.cardDark,
      surfaceContainerLow: RelatoColors.cardDark,
      surfaceContainer: Color(0xFF1C1A0C),
      surfaceContainerHigh: RelatoColors.fillDark,
      error: const Color(0xFFF08A7E),
    );
    return _base(scheme, SyncStatusColors.dark);
  }

  static ThemeData _base(ColorScheme scheme, SyncStatusColors syncColors) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final display = TextStyle(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: scheme.onSurface,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      extensions: [syncColors],
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.merge(display),
        titleLarge: base.textTheme.titleLarge?.merge(display),
        titleMedium: base.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: display.copyWith(fontSize: 24),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: RelatoColors.signal,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? RelatoColors.charcoal
                : scheme.onSurfaceVariant,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        extendedTextStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
