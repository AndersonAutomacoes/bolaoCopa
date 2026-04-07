import 'package:intl/intl.dart';

String formatKickoff(DateTime utc) {
  final l = utc.toLocal();
  final d = l.day.toString().padLeft(2, '0');
  final m = l.month.toString().padLeft(2, '0');
  final h = l.hour.toString().padLeft(2, '0');
  final min = l.minute.toString().padLeft(2, '0');
  return '$d/$m/${l.year} $h:$min';
}

/// Data/hora longa em pt_BR (ex.: sexta-feira, 12 de junho de 2026 • 15:00).
final DateFormat _kickoffLongPtBr = DateFormat("EEEE, d 'de' MMMM yyyy '•' HH:mm", 'pt_BR');

String formatKickoffLongPtBr(DateTime utc) {
  final raw = _kickoffLongPtBr.format(utc.toLocal());
  return _sentenceCasePt(raw);
}

/// Uma linha curta para faixas de contexto (fase + data curta + hora).
String formatKickoffMediumPtBr(DateTime utc) {
  final l = utc.toLocal();
  final wd = _weekdayShortPt(l.weekday);
  final d = l.day.toString().padLeft(2, '0');
  final mo = _monthShortPt(l.month);
  final h = l.hour.toString().padLeft(2, '0');
  final min = l.minute.toString().padLeft(2, '0');
  return '$wd, $d $mo ${l.year} • $h:$min';
}

String formatKickoffTimeOnly(DateTime utc) {
  final l = utc.toLocal();
  final h = l.hour.toString().padLeft(2, '0');
  final min = l.minute.toString().padLeft(2, '0');
  return '$h:$min';
}

String _sentenceCasePt(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

String _weekdayShortPt(int weekday) {
  const names = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
  return names[(weekday - 1).clamp(0, 6)];
}

String _monthShortPt(int month) {
  const names = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];
  return names[(month - 1).clamp(0, 11)];
}

/// Linha curta estilo mockup “Meus palpites”: `SÁB 27 JUN • 13:00`.
String formatKickoffPalpiteMockup(DateTime utc) {
  final l = utc.toLocal();
  final wd = _weekdayShortPt(l.weekday).toUpperCase();
  final mo = _monthShortPt(l.month).toUpperCase();
  final d = l.day.toString().padLeft(2, '0');
  final h = l.hour.toString().padLeft(2, '0');
  final min = l.minute.toString().padLeft(2, '0');
  return '$wd $d $mo • $h:$min';
}
