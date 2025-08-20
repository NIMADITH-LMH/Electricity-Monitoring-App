import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

import '../models/usage_record_model.dart';
import '../models/budget_model.dart';

class ReportService {
  // Generate a monthly usage report as PDF
  static Future<String?> generateMonthlyReport({
    required List<UsageRecordModel> records,
    required int year,
    required int month,
    required BudgetModel? budget,
    required double totalKwh,
    required double totalCost,
  }) async {
    try {
      // Create a PDF document
      final pdf = pw.Document();

      // Format month and year
      final monthName = DateFormat('MMMM').format(DateTime(year, month));
      final reportTitle = 'Electricity Usage Report - $monthName $year';

      // Add content to the PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              _buildReportHeader(reportTitle),
              pw.SizedBox(height: 20),
              _buildSummarySection(totalKwh, totalCost, budget),
              pw.SizedBox(height: 20),
              _buildUsageDetails(records),
              pw.SizedBox(height: 20),
              _buildFooter(),
            ];
          },
        ),
      );

      // Save the PDF file
      final String fileName =
          'electricity_report_${year}_${month.toString().padLeft(2, '0')}.pdf';
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Open the PDF file
      await OpenFile.open(filePath);

      return filePath;
    } catch (e) {
      debugPrint('Error generating report: $e');
      return null;
    }
  }

  // Helper method to build the report header
  static pw.Widget _buildReportHeader(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
        pw.Divider(thickness: 2),
      ],
    );
  }

  // Helper method to build the summary section
  static pw.Widget _buildSummarySection(
    double totalKwh,
    double totalCost,
    BudgetModel? budget,
  ) {
    final costPercentage = budget != null && budget.maxCost > 0
        ? (totalCost / budget.maxCost) * 100
        : 0;
    final kwhPercentage = budget != null && budget.maxKwh > 0
        ? (totalKwh / budget.maxKwh) * 100
        : 0;

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 1, color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Monthly Summary',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildSummaryItem(
                  'Total Consumption',
                  '$totalKwh kWh',
                  budget != null
                      ? '${kwhPercentage.toStringAsFixed(1)}% of budget'
                      : 'No budget set',
                ),
              ),
              pw.Expanded(
                child: _buildSummaryItem(
                  'Total Cost',
                  'LKR ${totalCost.toStringAsFixed(2)}',
                  budget != null
                      ? '${costPercentage.toStringAsFixed(1)}% of budget'
                      : 'No budget set',
                ),
              ),
            ],
          ),
          if (budget != null) ...[
            pw.SizedBox(height: 10),
            pw.Row(
              children: [
                pw.Expanded(
                  child: _buildSummaryItem(
                    'kWh Budget',
                    '${budget.maxKwh} kWh',
                    totalKwh > budget.maxKwh
                        ? 'Exceeded by ${(totalKwh - budget.maxKwh).toStringAsFixed(1)} kWh'
                        : 'Under by ${(budget.maxKwh - totalKwh).toStringAsFixed(1)} kWh',
                  ),
                ),
                pw.Expanded(
                  child: _buildSummaryItem(
                    'Cost Budget',
                    'LKR ${budget.maxCost.toStringAsFixed(2)}',
                    totalCost > budget.maxCost
                        ? 'Exceeded by LKR ${(totalCost - budget.maxCost).toStringAsFixed(2)}'
                        : 'Under by LKR ${(budget.maxCost - totalCost).toStringAsFixed(2)}',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Helper method to build a summary item
  static pw.Widget _buildSummaryItem(
    String title,
    String value,
    String subtitle,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            subtitle,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  // Helper method to build the usage details table
  static pw.Widget _buildUsageDetails(List<UsageRecordModel> records) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Usage Details',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1),
          },
          children: [
            // Table header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableHeader('Date'),
                _buildTableHeader('Usage (kWh)'),
                _buildTableHeader('Cost (LKR)'),
              ],
            ),
            // Table rows for each record
            ...records.map((record) {
              return pw.TableRow(
                children: [
                  _buildTableCell(DateFormat('yyyy-MM-dd').format(record.date)),
                  _buildTableCell(record.totalKwh.toString()),
                  _buildTableCell('LKR ${record.totalCost.toStringAsFixed(2)}'),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  // Helper method to build a table header cell
  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Helper method to build a table cell
  static pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 10),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Helper method to build the footer
  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 5),
        pw.Text(
          'This report was generated by Electricity Monitoring App',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 5),
        pw.Text(
          'For any inquiries, please contact support@electricitymonitoringapp.com',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }
}
