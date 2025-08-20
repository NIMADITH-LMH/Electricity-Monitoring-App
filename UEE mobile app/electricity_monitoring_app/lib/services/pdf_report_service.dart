import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';

import '../models/appliance_model.dart';
import '../models/budget_model.dart';
import '../models/usage_record_model.dart';
import '../models/tip_model.dart';

class PdfReportService {
  // Generate appliance report
  Future<void> generateApplianceReport(
    List<ApplianceModel> appliances,
    List<TipModel> tips,
  ) async {
    final pdf = pw.Document();

    // Calculate total consumption
    double totalDailyConsumption = appliances.fold(
      0,
      (total, appliance) => total + appliance.dailyConsumption,
    );
    double totalMonthlyConsumption = appliances.fold(
      0,
      (total, appliance) => total + appliance.monthlyConsumption,
    );
    double totalAnnualConsumption = appliances.fold(
      0,
      (total, appliance) => total + appliance.annualConsumption,
    );

    // Create PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Header(
              level: 0,
              child: pw.Text(
                'Appliance Consumption Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Paragraph(
              text:
                  'Generated on: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
            ),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Summary')),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow('Total Appliances:', '${appliances.length}'),
                  _buildSummaryRow(
                    'Daily Consumption:',
                    '${totalDailyConsumption.toStringAsFixed(2)} kWh',
                  ),
                  _buildSummaryRow(
                    'Monthly Consumption:',
                    '${totalMonthlyConsumption.toStringAsFixed(2)} kWh',
                  ),
                  _buildSummaryRow(
                    'Annual Consumption:',
                    '${totalAnnualConsumption.toStringAsFixed(2)} kWh',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Appliance Details')),
            _buildApplianceTable(appliances),
            pw.SizedBox(height: 20),
            pw.Header(
              level: 1,
              child: pw.Text('Recommended Energy Saving Tips'),
            ),
            _buildTipsList(tips),
          ];
        },
      ),
    );

    // Save the PDF
    final output = await _getReportFilePath('appliance_report.pdf');
    final file = File(output);
    await file.writeAsBytes(await pdf.save());

    // Open the PDF
    OpenFile.open(output);
  }

  // Generate budget report
  Future<void> generateBudgetReport(
    BudgetModel budget,
    List<UsageRecordModel> records,
  ) async {
    final pdf = pw.Document();

    // Calculate actual usage and percentages
    double totalKwh = records.fold(
      0,
      (total, record) => total + record.totalKwh,
    );
    double totalCost = records.fold(
      0,
      (total, record) => total + record.totalCost,
    );
    double kwhPercentage = budget.maxKwh > 0
        ? (totalKwh / budget.maxKwh) * 100
        : 0;
    double costPercentage = budget.maxCost > 0
        ? (totalCost / budget.maxCost) * 100
        : 0;

    // Parse month and year from budget.month (format: "2025-08")
    final parts = budget.month.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final monthName = DateFormat('MMMM').format(DateTime(year, month));

    // Create PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Header(
              level: 0,
              child: pw.Text(
                'Budget Report - $monthName $year',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Paragraph(
              text:
                  'Generated on: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
            ),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Budget Summary')),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow('Budget Period:', '$monthName $year'),
                  _buildSummaryRow(
                    'Maximum kWh:',
                    '${budget.maxKwh.toStringAsFixed(2)} kWh',
                  ),
                  _buildSummaryRow(
                    'Maximum Cost:',
                    'LKR ${budget.maxCost.toStringAsFixed(2)}',
                  ),
                  pw.Divider(),
                  _buildSummaryRow(
                    'Actual kWh:',
                    '${totalKwh.toStringAsFixed(2)} kWh (${kwhPercentage.toStringAsFixed(0)}%)',
                  ),
                  _buildSummaryRow(
                    'Actual Cost:',
                    'LKR ${totalCost.toStringAsFixed(2)} (${costPercentage.toStringAsFixed(0)}%)',
                  ),
                  pw.Divider(),
                  _buildSummaryRow(
                    'Status:',
                    totalCost <= budget.maxCost
                        ? 'Within Budget'
                        : 'Over Budget',
                    textColor: totalCost <= budget.maxCost
                        ? PdfColors.green700
                        : PdfColors.red700,
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Usage Breakdown')),
            _buildUsageRecordTable(records),
            pw.SizedBox(height: 20),
            pw.Paragraph(
              text:
                  'Note: This report provides a comparison between your budget targets and actual electricity consumption for $monthName $year.',
              style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
            ),
          ];
        },
      ),
    );

    // Save the PDF
    final output = await _getReportFilePath(
      'budget_report_${budget.month}.pdf',
    );
    final file = File(output);
    await file.writeAsBytes(await pdf.save());

    // Open the PDF
    OpenFile.open(output);
  }

  // Generate usage record report
  Future<void> generateUsageReport(
    List<UsageRecordModel> records,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final pdf = pw.Document();

    // Filter records by date range
    final filteredRecords = records.where((record) {
      return record.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          record.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();

    // Calculate totals
    double totalKwh = filteredRecords.fold(
      0,
      (total, record) => total + record.totalKwh,
    );
    double totalCost = filteredRecords.fold(
      0,
      (total, record) => total + record.totalCost,
    );
    double avgKwhPerDay = filteredRecords.isEmpty
        ? 0
        : totalKwh / filteredRecords.length;

    // Create PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Header(
              level: 0,
              child: pw.Text(
                'Electricity Usage Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Paragraph(
              text:
                  'Generated on: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
            ),
            pw.Paragraph(
              text:
                  'Report Period: ${DateFormat('MMM dd, yyyy').format(startDate)} to ${DateFormat('MMM dd, yyyy').format(endDate)}',
            ),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Usage Summary')),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow(
                    'Total Records:',
                    '${filteredRecords.length}',
                  ),
                  _buildSummaryRow(
                    'Total Consumption:',
                    '${totalKwh.toStringAsFixed(2)} kWh',
                  ),
                  _buildSummaryRow(
                    'Total Cost:',
                    'LKR ${totalCost.toStringAsFixed(2)}',
                  ),
                  _buildSummaryRow(
                    'Average Daily Usage:',
                    '${avgKwhPerDay.toStringAsFixed(2)} kWh',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Usage Details')),
            _buildUsageRecordTable(filteredRecords),
            pw.SizedBox(height: 20),
            pw.Paragraph(
              text:
                  'Note: This report provides an analysis of your electricity consumption during the selected period.',
              style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic),
            ),
          ];
        },
      ),
    );

    // Save the PDF
    final output = await _getReportFilePath(
      'usage_report_${DateFormat('yyyyMMdd').format(startDate)}_${DateFormat('yyyyMMdd').format(endDate)}.pdf',
    );
    final file = File(output);
    await file.writeAsBytes(await pdf.save());

    // Open the PDF
    OpenFile.open(output);
  }

  // Generate tips report
  Future<void> generateTipsReport(List<TipModel> tips, String? category) async {
    final pdf = pw.Document();

    // Filter tips by category if provided
    final filteredTips = category != null && category.isNotEmpty
        ? tips.where((tip) => tip.category == category).toList()
        : tips;

    // Create PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Header(
              level: 0,
              child: pw.Text(
                'Energy-Saving Tips Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Paragraph(
              text:
                  'Generated on: ${DateFormat('MMM dd, yyyy').format(DateTime.now())}',
            ),
            if (category != null && category.isNotEmpty)
              pw.Paragraph(
                text: 'Category: $category',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Summary')),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow('Total Tips:', '${filteredTips.length}'),
                  _buildSummaryRow(
                    'Estimated Annual Savings:',
                    'LKR ${_calculateTotalSavings(filteredTips).toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Header(level: 1, child: pw.Text('Energy-Saving Tips')),
            _buildTipsList(filteredTips),
          ];
        },
      ),
    );

    // Save the PDF
    final reportName = category != null && category.isNotEmpty
        ? 'tips_report_${category.replaceAll(' ', '_')}.pdf'
        : 'tips_report_all.pdf';
    final output = await _getReportFilePath(reportName);
    final file = File(output);
    await file.writeAsBytes(await pdf.save());

    // Open the PDF
    OpenFile.open(output);
  }

  // Helper for appliance table
  pw.Widget _buildApplianceTable(List<ApplianceModel> appliances) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Name', isHeader: true),
            _buildTableCell('Wattage', isHeader: true),
            _buildTableCell('Hours/day', isHeader: true),
            _buildTableCell('Location', isHeader: true),
            _buildTableCell('Daily kWh', isHeader: true),
            _buildTableCell('Monthly kWh', isHeader: true),
          ],
        ),
        // Data rows
        ...appliances.map(
          (appliance) => pw.TableRow(
            children: [
              _buildTableCell(appliance.name),
              _buildTableCell('${appliance.wattage.toStringAsFixed(0)}W'),
              _buildTableCell(appliance.dailyUsageHrs.toString()),
              _buildTableCell(appliance.location),
              _buildTableCell(appliance.dailyConsumption.toStringAsFixed(2)),
              _buildTableCell(appliance.monthlyConsumption.toStringAsFixed(2)),
            ],
          ),
        ),
      ],
    );
  }

  // Helper for usage record table
  pw.Widget _buildUsageRecordTable(List<UsageRecordModel> records) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('Date', isHeader: true),
            _buildTableCell('kWh', isHeader: true),
            _buildTableCell('Cost', isHeader: true),
          ],
        ),
        // Data rows
        ...records.map(
          (record) => pw.TableRow(
            children: [
              _buildTableCell(DateFormat('MMM dd, yyyy').format(record.date)),
              _buildTableCell(record.totalKwh.toStringAsFixed(2)),
              _buildTableCell('LKR ${record.totalCost.toStringAsFixed(2)}'),
            ],
          ),
        ),
      ],
    );
  }

  // Helper for tips list
  pw.Widget _buildTipsList(List<TipModel> tips) {
    return pw.Column(
      children: tips
          .map(
            (tip) => pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    tip.title,
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (tip.category != null && tip.category!.isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 2, bottom: 4),
                      child: pw.Text(
                        'Category: ${tip.category}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey700,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ),
                  pw.SizedBox(height: 4),
                  pw.Text(tip.description),
                  if (tip.estimatedSavings != null && tip.estimatedSavings! > 0)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 4),
                      child: pw.Text(
                        'Estimated Savings: LKR ${tip.estimatedSavings!.toStringAsFixed(2)} per year',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // Helper for summary rows
  pw.Widget _buildSummaryRow(
    String label,
    String value, {
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(
            value,
            style: textColor != null ? pw.TextStyle(color: textColor) : null,
          ),
        ],
      ),
    );
  }

  // Helper for table cells
  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: isHeader ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
      ),
    );
  }

  // Helper to get total savings from tips
  double _calculateTotalSavings(List<TipModel> tips) {
    return tips.fold(0, (total, tip) => total + (tip.estimatedSavings ?? 0));
  }

  // Helper to get a file path for saving reports
  Future<String> _getReportFilePath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$fileName';
  }
}
