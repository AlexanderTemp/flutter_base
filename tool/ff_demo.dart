// Demo de consola: descarga las noticias rojas desde el feed oficial de
// FairEconomy (la misma vía que usa la app Flutter) y las lista con su
// forecast/previo. Prueba la lógica de la FASE 1 sin la app.
//
//   dart run tool/ff_demo.dart          # rojas de hoy
//   dart run tool/ff_demo.dart --week   # rojas de toda la semana
import 'dart:io';

import 'package:flutter_workspace/forex/ff_feed_client.dart';
import 'package:flutter_workspace/forex/ff_exception.dart';

Future<void> main(List<String> args) async {
  final week = args.contains('--week');
  final client = FfFeedClient();
  try {
    stdout.writeln('Descargando feed de Forex Factory (FairEconomy)…');
    final all = await client.fetchWeek();
    final today = DateTime.now();
    var red = all.where((e) => e.isHigh).toList();
    if (!week) {
      red = red
          .where(
            (e) =>
                e.time.year == today.year &&
                e.time.month == today.month &&
                e.time.day == today.day,
          )
          .toList();
    }
    red.sort((a, b) => a.time.compareTo(b.time));

    if (red.isEmpty) {
      stdout.writeln('No hay noticias rojas ${week ? "esta semana" : "hoy"}.');
      return;
    }

    stdout.writeln(
      '\n🔴 Noticias de alto impacto '
      '(${week ? "semana" : "hoy"}): ${red.length}\n',
    );
    for (final e in red) {
      final hhmm =
          '${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}';
      stdout.writeln(
        '${_day(e.time)} $hhmm  ${e.currency.padRight(4)} '
        '${e.name.padRight(34)}  '
        'fc=${(e.forecast.isEmpty ? "-" : e.forecast).padLeft(7)}  '
        'prev=${(e.previous.isEmpty ? "-" : e.previous).padLeft(7)}',
      );
    }
    stdout.writeln(
      '\nNota: el feed no trae el valor "actual" (requiere proxy, fase 2).',
    );
  } on FfException catch (e) {
    stderr.writeln('Error: ${e.message}');
    exitCode = 1;
  } finally {
    client.close();
  }
}

String _day(DateTime d) {
  const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  return '${days[d.weekday - 1]} ${d.day.toString().padLeft(2, '0')}';
}
