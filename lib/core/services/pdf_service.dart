import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../data/models/pet_model.dart';
import '../../data/models/vaccine_model.dart';
import '../../data/models/medication_model.dart';
import '../../data/models/vet_record_model.dart';

class PdfService {
  static Future<pw.Document> generatePetPassport({
    required Pet pet,
    required List<Vaccine> vaccines,
    required List<Medication> medications,
    required List<VetRecord> records,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM d, yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(pet),
          pw.SizedBox(height: 20),
          _buildPetInfo(pet, dateFormat),
          pw.SizedBox(height: 20),
          if (vaccines.isNotEmpty) ...[
            _buildSectionTitle('Vaccinations'),
            pw.SizedBox(height: 10),
            ...vaccines.map((v) => _buildVaccineItem(v, dateFormat)),
            pw.SizedBox(height: 20),
          ],
          if (medications.isNotEmpty) ...[
            _buildSectionTitle('Current Medications'),
            pw.SizedBox(height: 10),
            ...medications.where((m) => m.isActive).map((m) => _buildMedicationItem(m, dateFormat)),
            pw.SizedBox(height: 20),
          ],
          if (records.isNotEmpty) ...[
            _buildSectionTitle('Health Records'),
            pw.SizedBox(height: 10),
            ...records.map((r) => _buildRecordItem(r, dateFormat)),
          ],
          pw.SizedBox(height: 30),
          _buildFooter(),
        ],
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(Pet pet) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            '🐾',
            style: pw.TextStyle(fontSize: 24),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            'Pet Passport',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal900,
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            pet.speciesEmoji,
            style: pw.TextStyle(fontSize: 24),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPetInfo(Pet pet, DateFormat dateFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            pet.name,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              _buildInfoChip('Species', pet.species),
              if (pet.breed != null) _buildInfoChip('Breed', pet.breed!),
              if (pet.gender != null) _buildInfoChip('Gender', pet.gender!),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              if (pet.dob != null)
                _buildInfoChip('Birthday', dateFormat.format(pet.dob!)),
              if (pet.dob != null) _buildInfoChip('Age', pet.ageString),
              if (pet.weightKg != null)
                _buildInfoChip('Weight', '${pet.weightKg} kg'),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _buildInfoChip('Neutered', pet.neutered ? 'Yes' : 'No'),
              if (pet.color != null) _buildInfoChip('Color', pet.color!),
              if (pet.microchip != null)
                _buildInfoChip('Microchip', pet.microchip!),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoChip(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(right: 12, bottom: 8),
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey700,
              ),
            ),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.teal,
        borderRadius: pw.BorderRadius.circular(4),
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

  static pw.Widget _buildVaccineItem(Vaccine vaccine, DateFormat dateFormat) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                vaccine.name,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                dateFormat.format(vaccine.dateGiven),
                style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
              ),
            ],
          ),
          if (vaccine.nextDueDate != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Next due: ${dateFormat.format(vaccine.nextDueDate!)}',
              style: pw.TextStyle(
                fontSize: 10,
                color: vaccine.status == VaccineStatus.overdue
                    ? PdfColors.red
                    : PdfColors.grey600,
              ),
            ),
          ],
          if (vaccine.vetName != null || vaccine.clinicName != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              [vaccine.vetName, vaccine.clinicName].where((e) => e != null).join(' - '),
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildMedicationItem(Medication medication, DateFormat dateFormat) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            medication.name,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          if (medication.dosage != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              'Dosage: ${medication.dosage}',
              style: pw.TextStyle(fontSize: 10),
            ),
          ],
          if (medication.frequency != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'Frequency: ${medication.frequency}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
          if (medication.startDate != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'Started: ${dateFormat.format(medication.startDate!)}',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildRecordItem(VetRecord record, DateFormat dateFormat) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                record.title,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  record.type,
                  style: pw.TextStyle(fontSize: 9),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            dateFormat.format(record.date),
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          if (record.notes != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              record.notes!,
              style: pw.TextStyle(fontSize: 10),
            ),
          ],
          if (record.cost != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              '\$${record.cost!.toStringAsFixed(2)}',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      alignment: pw.Alignment.center,
      child: pw.Text(
        'Generated by PawPass - ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
        style: pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey500,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  static Future<void> printOrSavePdf(BuildContext context, pw.Document pdf, String fileName) async {
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: fileName,
    );
  }
}