import 'package:intl/intl.dart';

/// Centralized date formatting helpers.
///
/// Use these instead of inline DateFormat calls so we have consistent
/// formatting across screens.
class AppDate {
  AppDate._();

  /// "30 أبريل 2026"
  static String full(DateTime d) => DateFormat('dd MMMM yyyy', 'ar').format(d);

  /// "30 أبر 2026"
  static String medium(DateTime d) => DateFormat('dd MMM yyyy', 'ar').format(d);

  /// "30/04"
  static String shortDM(DateTime d) => DateFormat('dd/MM', 'ar').format(d);

  /// "30/04/2026"
  static String shortDMY(DateTime d) => DateFormat('dd/MM/yyyy', 'ar').format(d);

  /// "10:30 ص"
  static String time(DateTime d) => DateFormat('hh:mm a', 'ar').format(d);

  /// "30 أبر 2026 - 10:30 ص"
  static String mediumWithTime(DateTime d) =>
      '${medium(d)} - ${time(d)}';

  /// "الجمعة 30 أبر 2026 - 10:30 ص"
  static String fullWithTime(DateTime d) =>
      DateFormat('EEEE dd MMM yyyy - hh:mm a', 'ar').format(d);

  /// Relative time: "منذ ساعتين", "أمس", إلخ
  static String relative(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return medium(d);
  }
}
