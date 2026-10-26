import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../attendees/services/attendee_service.dart';
import '../models/event_report.dart';

const _brandPrimary = PdfColor.fromInt(0xFF541E06);
const _brandMuted = PdfColor.fromInt(0xFF7C6A5C);
const _brandBorder = PdfColor.fromInt(0xFFE3D7C9);

String _formatTzs(double amount) {
  final rounded = amount.round();
  final text = rounded.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return 'TZS $buffer';
}

String _messageStatusLabel(String status) {
  switch (status) {
    case 'sent':
      return 'Sent';
    case 'failed':
      return 'Failed';
    default:
      return 'Pending';
  }
}

/// Builds the same event report the mobile Reports screen shows, as a PDF —
/// a hand-laid-out document (headings, KPI/category/contribution tables)
/// built with the `pdf` package, since there's no server-side PDF route to
/// call (the portal's own PDF export runs client-side in the browser via
/// jsPDF and isn't reachable from Flutter).
Future<Uint8List> buildEventReportPdf(
  EventReport report, {
  List<AttendeeRecord>? attendees,
}) async {
  final doc = pw.Document();
  final dateFmt = DateFormat('d MMM yyyy, h:mm a');

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            report.event.name,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: _brandPrimary,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            [
              dateFmt.format(report.event.date.toLocal()),
              if (report.event.venue != null && report.event.venue!.isNotEmpty)
                report.event.venue!,
            ].join(' · '),
            style: const pw.TextStyle(fontSize: 11, color: _brandMuted),
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: _brandBorder, thickness: 1),
        ],
      ),
      footer: (context) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: _brandMuted),
        ),
      ),
      build: (context) => [
        pw.Text(
          'Generated ${dateFmt.format(report.generatedAt.toLocal())}',
          style: const pw.TextStyle(fontSize: 9, color: _brandMuted),
        ),
        pw.SizedBox(height: 16),

        _sectionTitle('Attendance'),
        _kpiGrid({
          'Registered': '${report.totals.registered}',
          'Checked in': '${report.totals.checkedIn}',
          'Not checked in': '${report.totals.notCheckedIn}',
          'Check-in rate': '${report.totals.checkInRate.round()}%',
          'Cards assigned': '${report.totals.cardsAssigned}',
          'Cards activated': '${report.totals.cardsActivated}',
        }),
        pw.SizedBox(height: 16),

        if (report.categories.isNotEmpty) ...[
          _sectionTitle('By category'),
          _categoryTable(report.categories),
          pw.SizedBox(height: 16),
        ],

        _sectionTitle('Timeline'),
        _timelineSummary('Check-ins', report.checkIns, dateFmt),
        pw.SizedBox(height: 8),
        _timelineSummary('Registrations', report.registrations, dateFmt),
        pw.SizedBox(height: 16),

        if (report.messaging != null) ...[
          _sectionTitle('Messaging'),
          _messagingSection(report.messaging!),
          pw.SizedBox(height: 16),
        ],

        if (report.contributions != null) ...[
          _sectionTitle('Contributions'),
          _contributionsSection(report.contributions!),
          pw.SizedBox(height: 16),
        ],

        if (attendees != null && attendees.isNotEmpty) ...[
          _sectionTitle('Participants'),
          _participantsTable(
            attendees,
            includeContributions: report.contributions != null,
          ),
        ],
      ],
    ),
  );

  return doc.save();
}

pw.Widget _sectionTitle(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 13,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.black,
      ),
    ),
  );
}

pw.Widget _kpiGrid(Map<String, String> items) {
  final entries = items.entries.toList();
  return pw.Wrap(
    spacing: 16,
    runSpacing: 10,
    children: [
      for (final entry in entries)
        pw.Container(
          width: 150,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _brandBorder),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                entry.value,
                style: pw.TextStyle(
                  fontSize: 15,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                entry.key,
                style: const pw.TextStyle(fontSize: 9, color: _brandMuted),
              ),
            ],
          ),
        ),
    ],
  );
}

pw.Widget _categoryTable(List<ReportCategoryRow> categories) {
  return pw.TableHelper.fromTextArray(
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
    cellStyle: const pw.TextStyle(fontSize: 10),
    headerDecoration: const pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF6EFE8),
    ),
    cellAlignments: const {
      0: pw.Alignment.centerLeft,
      1: pw.Alignment.centerRight,
      2: pw.Alignment.centerRight,
      3: pw.Alignment.centerRight,
    },
    headers: const ['Category', 'Guests', 'Checked in', 'Rate'],
    data: [
      for (final c in categories)
        [
          c.name,
          '${c.attendees}',
          '${c.checkedIn}',
          c.attendees > 0
              ? '${(c.checkedIn / c.attendees * 100).round()}%'
              : '0%',
        ],
    ],
  );
}

pw.Widget _timelineSummary(
  String label,
  ReportTimeline timeline,
  DateFormat dateFmt,
) {
  final first = timeline.first;
  final last = timeline.last;
  return pw.Row(
    children: [
      pw.SizedBox(
        width: 90,
        child: pw.Text(
          label,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.Expanded(
        child: pw.Text(
          first == null || last == null
              ? 'No activity yet'
              : '${dateFmt.format(first.toLocal())} — ${dateFmt.format(last.toLocal())}',
          style: const pw.TextStyle(fontSize: 10, color: _brandMuted),
        ),
      ),
    ],
  );
}

pw.Widget _messagingSection(ReportMessaging messaging) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.TableHelper.fromTextArray(
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        cellStyle: const pw.TextStyle(fontSize: 10),
        headerDecoration: const pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFF6EFE8),
        ),
        headers: const ['Channel', 'Sent', 'Failed', 'Pending', 'Credits left'],
        data: [
          for (final c in messaging.channels)
            [
              c.channel == 'sms' ? 'SMS' : 'WhatsApp',
              '${c.sent}',
              '${c.failed}',
              '${c.pending}',
              '${c.available}',
            ],
        ],
      ),
      pw.SizedBox(height: 6),
      pw.Text(
        '${messaging.attendeesReached} guests reached',
        style: const pw.TextStyle(fontSize: 10, color: _brandMuted),
      ),
      if (messaging.messages.isNotEmpty) ...[
        pw.SizedBox(height: 10),
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 9,
          ),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF6EFE8),
          ),
          headers: const ['Recipient', 'Channel', 'Type', 'Status'],
          data: [
            for (final m in messaging.messages)
              [
                m.recipientName,
                m.channel == 'sms' ? 'SMS' : 'WhatsApp',
                m.type,
                _messageStatusLabel(m.status),
              ],
          ],
        ),
      ],
    ],
  );
}

pw.Widget _contributionsSection(ReportContributions contributions) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _kpiGrid({
        'Collected': _formatTzs(contributions.totalCollected),
        'Expected': _formatTzs(contributions.totalExpected),
        'Fully paid': '${contributions.fullyPaidCount}',
        'Partial': '${contributions.partialCount}',
        'Unpaid': '${contributions.unpaidCount}',
      }),
      pw.SizedBox(height: 10),
      if (contributions.categories.isNotEmpty)
        pw.TableHelper.fromTextArray(
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
          ),
          cellStyle: const pw.TextStyle(fontSize: 10),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColor.fromInt(0xFFF6EFE8),
          ),
          cellAlignments: const {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.centerRight,
            2: pw.Alignment.centerRight,
          },
          headers: const ['Category', 'Collected', 'Expected'],
          data: [
            for (final c in contributions.categories)
              [c.name, _formatTzs(c.collected), _formatTzs(c.expected)],
          ],
        ),
    ],
  );
}

pw.Widget _participantsTable(
  List<AttendeeRecord> attendees, {
  required bool includeContributions,
}) {
  final sorted = [...attendees]..sort((a, b) => a.name.compareTo(b.name));

  return pw.TableHelper.fromTextArray(
    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
    cellStyle: const pw.TextStyle(fontSize: 9),
    headerDecoration: const pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF6EFE8),
    ),
    cellAlignments: {
      0: pw.Alignment.centerLeft,
      1: pw.Alignment.centerLeft,
      2: pw.Alignment.centerLeft,
      3: pw.Alignment.center,
      if (includeContributions) 4: pw.Alignment.centerRight,
    },
    headers: [
      'Name',
      'Phone',
      'Category',
      'Checked in',
      if (includeContributions) 'Paid',
    ],
    data: [
      for (final a in sorted)
        [
          a.name,
          a.phone,
          a.categoryName ?? '—',
          a.checkedIn ? 'Yes' : 'No',
          if (includeContributions) _formatTzs(a.paidAmount),
        ],
    ],
  );
}
