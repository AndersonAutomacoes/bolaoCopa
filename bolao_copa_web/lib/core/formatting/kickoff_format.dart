String formatKickoff(DateTime utc) {
  final l = utc.toLocal();
  final d = l.day.toString().padLeft(2, '0');
  final m = l.month.toString().padLeft(2, '0');
  final h = l.hour.toString().padLeft(2, '0');
  final min = l.minute.toString().padLeft(2, '0');
  return '$d/$m/${l.year} $h:$min';
}
