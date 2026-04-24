import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import '../../data/models/pet_model.dart';
import '../../data/models/vaccine_model.dart';
import '../../data/models/medication_model.dart';
import '../../data/models/vet_record_model.dart';

class PdfService {
  static Future<pw.Document> generatePetIdCard({required Pet pet}) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, yyyy');

    final primaryColor = PdfColor.fromInt(0xFF2563EB);

    pw.MemoryImage? petImage;
    if (pet.photoUrl != null) {
      try {
        final response = await http.get(Uri.parse(pet.photoUrl!));
        if (response.statusCode == 200) {
          petImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {}
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(pet, primaryColor),
          pw.SizedBox(height: 25),
          _buildPetInfoCardCompact(pet, dateFormat, petImage, primaryColor),
          pw.SizedBox(height: 30),
          if (pet.isSharingEnabled && pet.shareLink.isNotEmpty)
            _buildShareSection(pet, primaryColor),
          pw.SizedBox(height: 30),
          _buildFooter(),
        ],
      ),
    );

    return pdf;
  }

  static Future<pw.Document> generatePetPassport({
    required Pet pet,
    required List<Vaccine> vaccines,
    required List<Medication> medications,
    required List<VetRecord> records,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, yyyy');

    final primaryColor = PdfColor.fromInt(0xFF2563EB);
    final successColor = PdfColor.fromInt(0xFF10B981);
    final warningColor = PdfColor.fromInt(0xFFF59E0B);
    final dangerColor = PdfColor.fromInt(0xFFEF4444);

    pw.MemoryImage? petImage;
    if (pet.photoUrl != null) {
      try {
        final response = await http.get(Uri.parse(pet.photoUrl!));
        if (response.statusCode == 200) {
          petImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (_) {}
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(pet, primaryColor),
          pw.SizedBox(height: 25),
          _buildPetInfoCard(pet, dateFormat, petImage),
          pw.SizedBox(height: 25),
          if (vaccines.isNotEmpty) ...[
            _buildSectionHeader('Vaccinations', primaryColor),
            pw.SizedBox(height: 12),
            ...vaccines.map(
              (v) => _buildVaccineItem(
                v,
                dateFormat,
                dangerColor,
                warningColor,
                successColor,
              ),
            ),
            pw.SizedBox(height: 20),
          ],
          if (medications.where((m) => m.isActive).isNotEmpty) ...[
            _buildSectionHeader('Current Medications', primaryColor),
            pw.SizedBox(height: 12),
            ...medications
                .where((m) => m.isActive)
                .map((m) => _buildMedicationItem(m, dateFormat)),
            pw.SizedBox(height: 20),
          ],
          if (records.isNotEmpty) ...[
            _buildSectionHeader('Health Records', primaryColor),
            pw.SizedBox(height: 12),
            ...records.take(10).map((r) => _buildRecordItem(r, dateFormat)),
          ],
          if (pet.isSharingEnabled && pet.shareLink.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            _buildShareSection(pet, primaryColor),
          ],
          pw.SizedBox(height: 30),
          _buildFooter(),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(Pet pet, PdfColor primaryColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [primaryColor, primaryColor.shade(0.8)],
          begin: pw.Alignment.centerLeft,
          end: pw.Alignment.centerRight,
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            'PawPass',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            'Pet Passport',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.normal,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(20),
            ),
            child: pw.Text(
              pet.species,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPetInfoCard(
    Pet pet,
    DateFormat dateFormat, [
    pw.MemoryImage? petImage,
  ]) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE0F0FF),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── TOP TITLE BAR ──────────────────────────────────────────────
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'PET  IDENTIFICATION CARD',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              pw.Row(
                children: [
                  _buildBone(size: 28),
                  pw.SizedBox(width: 6),
                  _buildPawPrint(size: 28),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),

          // ── BODY: LEFT (photo + barcode) | RIGHT (fields) ──────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── LEFT COLUMN ────────────────────────────────────────────
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Photo
                  pw.Container(
                    width: 140,
                    height: 140,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey500, width: 2),
                    ),
                    child: petImage != null
                        ? pw.ClipRRect(
                            horizontalRadius: 6,
                            verticalRadius: 6,
                            child: pw.Image(petImage, fit: pw.BoxFit.cover),
                          )
                        : pw.Center(
                            child: _buildPawPrint(
                              size: 60,
                              color: PdfColors.grey600,
                            ),
                          ),
                  ),

                  pw.SizedBox(height: 12),

                  // Barcode
                  _buildBarcode(width: 140, height: 40),
                ],
              ),

              pw.SizedBox(width: 20),

              // ── RIGHT COLUMN ───────────────────────────────────────────
              pw.Expanded(
                child: pw.Stack(
                  children: [
                    // Circular watermark behind fields
                    pw.Positioned(
                      top: 0,
                      right: 0,
                      child: pw.Container(
                        width: 180,
                        height: 180,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.grey300,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: _buildPawPrint(
                            size: 80,
                            color: PdfColors.grey500,
                          ),
                        ),
                      ),
                    ),

                    // Fields on top of watermark
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // "Name of the Pet" label
                        pw.Text(
                          'Name of the Pet:',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 2),

                        // Big pet name
                        pw.Text(
                          pet.name.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 30,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),

                        pw.Divider(color: PdfColors.black, thickness: 1.5),
                        pw.SizedBox(height: 10),

                        // Underlined info fields
                        _buildIdField(
                          'Birthday',
                          pet.dob != null ? dateFormat.format(pet.dob!) : 'N/A',
                        ),
                        _buildIdField('Sex', pet.gender ?? 'N/A'),
                        _buildIdField('Hair Color', pet.color ?? 'N/A'),
                        _buildIdField('Breed', pet.breed ?? 'N/A'),

                        pw.SizedBox(height: 16),

                        // Paw Print Mark box
                        pw.Row(
                          children: [
                            pw.Text(
                              'Paw Print Mark:',
                              style: pw.TextStyle(
                                fontSize: 11,
                                color: PdfColors.grey700,
                              ),
                            ),
                            pw.SizedBox(width: 10),
                            pw.Container(
                              width: 50,
                              height: 50,
                              decoration: pw.BoxDecoration(
                                border: pw.Border.all(
                                  color: PdfColors.black,
                                  width: 1.5,
                                ),
                              ),
                              child: pw.Center(child: _buildPawPrint(size: 36)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── HELPER: Underlined label-value row ─────────────────────────────────────
  static pw.Widget _buildIdField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.SizedBox(
                width: 80,
                child: pw.Text(
                  '$label:',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          ),
          pw.Divider(color: PdfColors.grey600, thickness: 0.8),
        ],
      ),
    );
  }

  static pw.Widget _buildPetInfoCardCompact(
    Pet pet,
    DateFormat dateFormat,
    pw.MemoryImage? petImage,
    PdfColor primaryColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFE0F0FF),
        borderRadius: pw.BorderRadius.circular(16),
        border: pw.Border.all(color: primaryColor, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'PET ID CARD',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                  letterSpacing: 2,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(
                  'OFFICIAL',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                children: [
                  pw.Container(
                    width: 120,
                    height: 120,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.grey500, width: 2),
                    ),
                    child: petImage != null
                        ? pw.ClipRRect(
                            horizontalRadius: 8,
                            verticalRadius: 8,
                            child: pw.Image(petImage, width: 120, height: 120),
                          )
                        : pw.Center(
                            child: pw.Text(
                              pet.speciesEmoji,
                              style: const pw.TextStyle(fontSize: 48),
                            ),
                          ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.BarcodeWidget(
                    barcode: pw.Barcode.qrCode(),
                    data: pet.shareLink.isNotEmpty ? pet.shareLink : pet.id,
                    width: 80,
                    height: 80,
                  ),
                ],
              ),
              pw.SizedBox(width: 24),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      pet.name,
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      '${pet.species} ${pet.breed != null ? "• ${pet.breed}" : ""}',
                      style: pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.SizedBox(height: 16),
                    _buildIdFieldCompact('Species', pet.species),
                    _buildIdFieldCompact('Breed', pet.breed ?? 'Unknown'),
                    _buildIdFieldCompact('Gender', pet.gender ?? 'Unknown'),
                    _buildIdFieldCompact(
                      'Birthday',
                      pet.dob != null ? dateFormat.format(pet.dob!) : 'Unknown',
                    ),
                    _buildIdFieldCompact('Age', pet.ageString),
                    if (pet.color != null)
                      _buildIdFieldCompact('Color', pet.color!),
                    if (pet.microchip != null)
                      _buildIdFieldCompact('Microchip', pet.microchip!),
                    if (pet.weightKg != null)
                      _buildIdFieldCompact('Weight', '${pet.weightKg} kg'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildIdFieldCompact(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPER: Drawn paw print (no emoji) ─────────────────────────────────────
  static pw.Widget _buildPawPrint({double size = 30, PdfColor? color}) {
    final c = color ?? PdfColors.black;
    return pw.CustomPaint(
      size: PdfPoint(size, size),
      painter: (canvas, pdfSize) {
        final s = size;

        void fillCircle(double x, double y, double r) {
          canvas
            ..setFillColor(c)
            ..drawEllipse(x, y, r, r)
            ..fillPath();
        }

        // Main pad (large oval)
        canvas
          ..setFillColor(c)
          ..drawEllipse(s * 0.5, s * 0.35, s * 0.28, s * 0.22)
          ..fillPath();

        // Three toe beans (top row)
        fillCircle(s * 0.22, s * 0.70, s * 0.10);
        fillCircle(s * 0.50, s * 0.78, s * 0.10);
        fillCircle(s * 0.78, s * 0.70, s * 0.10);

        // Fourth toe bean (bottom center)
        fillCircle(s * 0.50, s * 0.18, s * 0.09);
      },
    );
  }

  // ── HELPER: Drawn bone (no emoji) ──────────────────────────────────────────
  static pw.Widget _buildBone({double size = 30}) {
    return pw.CustomPaint(
      size: PdfPoint(size, size * 0.5),
      painter: (canvas, pdfSize) {
        final w = size;
        final h = size * 0.5;
        final r = h * 0.35;
        final midH = h * 0.3;

        canvas.setFillColor(PdfColors.black);

        // Center bar
        canvas
          ..drawRect(w * 0.2, h * 0.5 - midH, w * 0.6, midH * 2)
          ..fillPath();

        // End caps (two circles each side)
        void boneEnd(double cx, double cy) {
          canvas
            ..drawEllipse(cx, cy - r * 0.6, r, r)
            ..fillPath();
          canvas
            ..drawEllipse(cx, cy + r * 0.6, r, r)
            ..fillPath();
        }

        boneEnd(w * 0.18, h * 0.5); // left
        boneEnd(w * 0.82, h * 0.5); // right
      },
    );
  }

  // ── HELPER: Drawn barcode (no package needed) ───────────────────────────────
  static pw.Widget _buildBarcode({double width = 140, double height = 40}) {
    return pw.CustomPaint(
      size: PdfPoint(width, height),
      painter: (canvas, size) {
        final bars = [
          3,
          1,
          2,
          1,
          3,
          2,
          1,
          2,
          1,
          3,
          1,
          2,
          3,
          1,
          2,
          1,
          3,
          2,
          1,
          2,
          1,
          3,
          2,
          1,
          2,
        ];
        double x = 0;
        const gap = 1.5;
        bool black = true;
        for (final w in bars) {
          if (black) {
            canvas
              ..setFillColor(PdfColors.black)
              ..drawRect(x, 0, w.toDouble(), height)
              ..fillPath();
          }
          x += w + gap;
          black = !black;
        }
      },
    );
  }

  static pw.Widget _buildInfoChip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(20),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Text(
        '$label: $value',
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  static pw.Widget _buildSectionHeader(String title, PdfColor primaryColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: pw.BoxDecoration(
        color: primaryColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildVaccineItem(
    Vaccine vaccine,
    DateFormat dateFormat,
    PdfColor dangerColor,
    PdfColor warningColor,
    PdfColor successColor,
  ) {
    final color = vaccine.status == VaccineStatus.overdue
        ? dangerColor
        : vaccine.status == VaccineStatus.dueSoon
        ? warningColor
        : successColor;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                vaccine.name,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(
                  color: color.shade(0.9),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  vaccine.status.name.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Text(
                'Given: ',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                dateFormat.format(vaccine.dateGiven),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (vaccine.nextDueDate != null) ...[
                pw.SizedBox(width: 16),
                pw.Text(
                  'Next due: ',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  dateFormat.format(vaccine.nextDueDate!),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: vaccine.status == VaccineStatus.overdue
                        ? dangerColor
                        : PdfColors.grey900,
                  ),
                ),
              ],
            ],
          ),
          if (vaccine.vetName != null || vaccine.clinicName != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              [
                vaccine.vetName,
                vaccine.clinicName,
              ].where((e) => e != null).join(', '),
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildMedicationItem(
    Medication medication,
    DateFormat dateFormat,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                medication.name,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(
                  color: medication.isActive
                      ? PdfColors.green50
                      : PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  medication.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: medication.isActive
                        ? PdfColors.green800
                        : PdfColors.grey700,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              if (medication.dosage != null)
                _buildMedChip('Dosage', medication.dosage!),
              if (medication.frequency != null)
                _buildMedChip('Frequency', medication.frequencyLabel),
              if (medication.frequencyType != null)
                _buildMedChip('Type', medication.frequencyType!),
              if (medication.frequencyTimes != null)
                _buildMedChip('Times/Day', '${medication.frequencyTimes}'),
              if (medication.mealTiming != null)
                _buildMedChip('Meal', medication.mealTimingLabel),
              if (medication.timeOfDayLabel.isNotEmpty)
                _buildMedChip('Time', medication.timeOfDayLabel),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              if (medication.startDate != null)
                pw.Text(
                  'Started: ${dateFormat.format(medication.startDate!)}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              if (medication.endDate != null) ...[
                pw.SizedBox(width: 12),
                pw.Text(
                  'Ends: ${dateFormat.format(medication.endDate!)}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ],
            ],
          ),
          if (medication.prescribedBy != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Prescribed by: ${medication.prescribedBy}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
          if (medication.notes != null && medication.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Notes: ${medication.notes}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildMedChip(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        '$label: $value',
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildRecordItem(VetRecord record, DateFormat dateFormat) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  record.title,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  record.type,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Text(
                'Date: ',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
              pw.Text(
                dateFormat.format(record.date),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (record.cost != null) ...[
                pw.SizedBox(width: 16),
                pw.Text(
                  'Cost: ',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.Text(
                  '\$${record.cost!.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
          if (record.notes != null && record.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              record.notes!,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              maxLines: 2,
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildShareSection(Pet pet, PdfColor primaryColor) {
    final shareUrl = pet.shareLink;
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Scan to view live passport',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Always up to date',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  shareUrl,
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Powered by PawPass',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: shareUrl,
            width: 80,
            height: 80,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Column(
        children: [
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Text(
            'Generated by PawPass',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            DateFormat('MMMM d, yyyy').format(DateTime.now()),
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey400),
          ),
        ],
      ),
    );
  }

  static Future<void> printOrSavePdf(
    BuildContext context,
    pw.Document pdf,
    String fileName,
  ) async {
    await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
  }
}
