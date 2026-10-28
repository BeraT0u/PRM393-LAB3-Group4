import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/study_plan_model.dart';
import '../models/student_profile_model.dart';
import '../utils/app_logger.dart';

class PdfReportService {
  /// Sinh file PDF A4 Kế hoạch học tập & Chiến lược
  Future<Uint8List> generatePlanPdf({
    required StudyPlanModel plan,
    required StudentProfileModel student,
  }) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Tiêu đề
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'EduPlan Blueprint',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 22,
                          color: PdfColor.fromHex('#2563EB'),
                        ),
                      ),
                      pw.Text(
                        'Bản Kế Hoạch & Phân Bổ Chiến Lược Học Tập',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 12,
                          color: PdfColor.fromHex('#78716C'),
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#DCFCE7'),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Text(
                      'Học kỳ: ${plan.semesterName}',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 11,
                        color: PdfColor.fromHex('#15803D'),
                      ),
                    ),
                  ),
                ],
              ),
              pw.Divider(color: PdfColor.fromHex('#EAE1D0'), thickness: 1),
              pw.SizedBox(height: 12),

              // Thông tin sinh viên
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FFFDF7'),
                  border: pw.Border.all(color: PdfColor.fromHex('#EAE1D0')),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Sinh viên: ${student.fullName}',
                            style: pw.TextStyle(font: fontBold, fontSize: 13)),
                        pw.Text('MSSV: ${student.studentId} • Chuyên ngành KTPM',
                            style: pw.TextStyle(font: fontRegular, fontSize: 11)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Tiến độ tích lũy: ${student.accumulatedCredits}/${student.totalGraduationCredits} TC',
                            style: pw.TextStyle(font: fontRegular, fontSize: 11)),
                        pw.Text('GPA tích lũy: ${student.currentGpa.toStringAsFixed(2)}',
                            style: pw.TextStyle(font: fontBold, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Thẻ KPI tổng kết
              pw.Row(
                children: [
                  _buildKpiPdfCard('Số môn học', '${plan.selectedCourses.length} Môn', fontBold, fontRegular),
                  pw.SizedBox(width: 8),
                  _buildKpiPdfCard('Tổng tín chỉ', '${plan.totalCredits} TC', fontBold, fontRegular),
                  pw.SizedBox(width: 8),
                  _buildKpiPdfCard('Tự học/Tuần', '${plan.totalSelfStudyHours.toInt()} Giờ', fontBold, fontRegular),
                  pw.SizedBox(width: 8),
                  _buildKpiPdfCard('GPA Mục tiêu', plan.targetGpa.toStringAsFixed(2), fontBold, fontRegular),
                ],
              ),
              pw.SizedBox(height: 20),

              // Danh sách môn học bảng
              pw.Text('Chi tiết chiến lược từng môn',
                  style: pw.TextStyle(font: fontBold, fontSize: 14)),
              pw.SizedBox(height: 8),

              pw.TableHelper.fromTextArray(
                border: pw.TableBorder.all(color: PdfColor.fromHex('#EAE1D0'), width: 0.8),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F4ECE8')),
                headerHeight: 28,
                cellHeight: 26,
                headerStyle: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColor.fromHex('#1C1917')),
                cellStyle: pw.TextStyle(font: fontRegular, fontSize: 10),
                headers: ['Mã môn', 'Tên môn học', 'Số TC', 'Độ khó', 'Mục tiêu', 'Giờ tự học'],
                data: plan.selectedCourses.map((c) {
                  return [
                    c.code,
                    c.name,
                    '${c.credits}',
                    '${c.difficulty.toStringAsFixed(0)}/5 ⭐',
                    'Điểm ${c.selectedGradeTarget}',
                    '${c.plannedSelfStudyHours.toInt()}h / tuần',
                  ];
                }).toList(),
              ),

              pw.Spacer(),

              // Footer chữ ký / ghi chú
              pw.Divider(color: PdfColor.fromHex('#EAE1D0'), thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Xuất tự động từ EduPlan Mobile • Hệ thống Lập kế hoạch học tập thông minh',
                    style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColor.fromHex('#78716C')),
                  ),
                  pw.Text(
                    'Ngày xuất: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColor.fromHex('#78716C')),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildKpiPdfCard(String title, String value, pw.Font bold, pw.Font regular) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#FFFDF7'),
          border: pw.Border.all(color: PdfColor.fromHex('#EAE1D0')),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColor.fromHex('#78716C'))),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 12, color: PdfColor.fromHex('#2563EB'))),
          ],
        ),
      ),
    );
  }

  /// Kích hoạt hộp thoại xem trước và in PDF hoặc chia sẻ file
  Future<void> previewOrSharePdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: filename,
      );
    } catch (e, st) {
      AppLogger.error('Lỗi khi mở bản in PDF', e, st);
    }
  }
}
