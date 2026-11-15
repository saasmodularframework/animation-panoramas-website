import 'dart:typed_data';
import 'package:dart_rss/dart_rss.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../pages_registry.dart';
import 'db_service.dart';

class RssService {
  static String _e(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  static String _date(DateTime d) =>
      '${DateFormat('EEE, dd MMM yyyy HH:mm:ss', 'en').format(d.toUtc())} GMT';
  static String _item(String t, String d, String link, DateTime when) =>
      '<item><title>${_e(t)}</title><description>${_e(d)}</description><link>$link</link>'
      '<guid>$link#${when.millisecondsSinceEpoch}</guid><pubDate>${_date(when)}</pubDate></item>';

  static Future<String> build(PageInfo p) async {
    final items = <String>[];
    if (p.slug == 'notes') {
      for (final n in await Db.notes()) {
        items.add(_item(n['title'] as String, n['body'] as String, p.url,
            DateTime.fromMillisecondsSinceEpoch(n['created'] as int)));
      }
    } else if (p.slug == 'coding-agenda' || p.slug == 'chart') {
      for (final b in await Db.bookings()) {
        items.add(_item('${b['service']}', b['note'] as String, p.url,
            DateTime.fromMillisecondsSinceEpoch(b['whenMs'] as int)));
      }
    }
    if (items.isEmpty) items.add(_item(p.title, p.description, p.url, DateTime.now()));
    final xml = '<?xml version="1.0" encoding="UTF-8"?><rss version="2.0"><channel>'
        '<title>${_e(p.title)}</title><link>${p.url}</link><description>${_e(p.description)}</description>'
        '${items.join()}</channel></rss>';
    RssFeed.parse(xml); 
    return xml;
  }
}

class PdfService {
  static Future<Uint8List> build(PageInfo p) async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (_) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(p.title, style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 12),
        pw.Text(p.description, style: const pw.TextStyle(fontSize: 14)),
        pw.SizedBox(height: 24),
        pw.Text(p.url, style: const pw.TextStyle(fontSize: 11, color: PdfColors.blue)),
        pw.Spacer(),
        pw.Text('Generated ${DateFormat.yMMMd().add_Hm().format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
      ]),
    ));
    return doc.save();
  }
}
