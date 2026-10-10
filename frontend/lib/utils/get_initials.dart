class InitialsHelper {
  static String getInitials(String? name, {String defaultChar = ""}) {
    if (name == null || name.trim().isEmpty) return defaultChar;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
