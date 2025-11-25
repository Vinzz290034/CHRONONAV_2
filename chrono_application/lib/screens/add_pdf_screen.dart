import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../services/api_service.dart';

// --- DATA MODEL (Remains the same for consistency) ---
class ExtractedScheduleData {
  final String rawText;
  final String scheduleCode;
  final String title;
  final String scheduleType;
  final String startDate;
  final String startTime;
  final String repeatFrequency;
  final String? description;
  final String? endDate;
  final String? endTime;
  final String? dayOfWeek;
  final String? location;

  ExtractedScheduleData({
    required this.rawText,
    required this.scheduleCode,
    required this.title,
    required this.scheduleType,
    required this.startDate,
    required this.startTime,
    required this.repeatFrequency,
    this.description,
    this.endDate,
    this.endTime,
    this.dayOfWeek,
    this.location,
  });

  @override
  String toString() {
    return 'Raw Text Length: ${rawText.length}\nCode: $scheduleCode, Title: $title, Type: $scheduleType, Start: $startDate @ $startTime, Days: $dayOfWeek, Freq: $repeatFrequency';
  }

  bool get isValid =>
      scheduleCode.isNotEmpty &&
      title.isNotEmpty &&
      startDate.isNotEmpty &&
      startTime.isNotEmpty &&
      repeatFrequency.isNotEmpty;
}

class AddPdfScreen extends StatefulWidget {
  const AddPdfScreen({super.key});

  @override
  State<AddPdfScreen> createState() => _AddPdfScreenState();
}

class _AddPdfScreenState extends State<AddPdfScreen> {
  String? _pickedFilePath;
  String _statusMessage = 'Ready to upload study load.';
  ExtractedScheduleData? _extractedData;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  final ApiService _apiService = ApiService();

  final String _mockUserId = 'mock_user_123';

  // --- HELPER WIDGETS FOR DISPLAYING EXTRACTED DATA ---

  // Helper for consistent row formatting
  Widget _buildDataRow(String label, String? value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                // ignore: deprecated_member_use
                color: color.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value?.isNotEmpty == true ? value! : 'N/A',
              style: TextStyle(
                fontWeight: FontWeight.normal,
                color: value?.isNotEmpty == true
                    ? color
                    : Colors.redAccent.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Main review card widget
  Widget _buildExtractedDataReview(ExtractedScheduleData data) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color successColor = Colors.green.shade700;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Extracted Schedule Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          // Main Data Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDataRow('Code', data.scheduleCode, primaryColor),
                  _buildDataRow('Title', data.title, primaryColor),
                  _buildDataRow('Type', data.scheduleType, primaryColor),
                  const Divider(height: 20),
                  _buildDataRow('Start Date', data.startDate, successColor),
                  _buildDataRow('Start Time', data.startTime, successColor),
                  _buildDataRow(
                    'Frequency',
                    data.repeatFrequency,
                    successColor,
                  ),
                  _buildDataRow('Days', data.dayOfWeek, primaryColor),
                  _buildDataRow('Location', data.location, primaryColor),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Raw Text Output (for verification):',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          // Raw Text Box
          Container(
            height: 120, // Reduced height to fit on screen
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SingleChildScrollView(
              child: Text(
                data.rawText,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- CORE OCR & DATA PROCESSING LOGIC (Unchanged) ---
  Future<ExtractedScheduleData> _processImageForOcr(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );
    textRecognizer.close();
    final rawText = recognizedText.text;

    // --- MOCK PARSING LOGIC ---
    String scheduleCode = 'UNK-CODE';
    String title = 'Unknown Class';
    String scheduleType = 'Class';
    String startDate = '2025-01-01'; // Default placeholder
    String startTime = '08:00'; // Default placeholder
    String repeatFrequency = 'Weekly'; // Default placeholder
    String? dayOfWeek;
    String? location;

    final lines = rawText.split('\n');
    for (var line in lines) {
      if (line.toUpperCase().contains('COURSE CODE:')) {
        scheduleCode = line.split(':').last.trim();
      } else if (line.toUpperCase().contains('TITLE:')) {
        title = line.split(':').last.trim();
      } else if (line.toUpperCase().contains('DAYS:')) {
        dayOfWeek = line.split(':').last.trim().replaceAll(RegExp(r'\s+'), '');
      } else if (line.toUpperCase().contains('ROOM:') ||
          line.toUpperCase().contains('LOC:')) {
        location = line.split(':').last.trim();
      }
    }

    return ExtractedScheduleData(
      rawText: rawText,
      scheduleCode: scheduleCode,
      title: title,
      scheduleType: scheduleType,
      startDate: startDate,
      startTime: startTime,
      repeatFrequency: repeatFrequency,
      dayOfWeek: dayOfWeek,
      location: location,
    );
  }

  // --------------------------------------------------------------------------------
  // Main Extraction Caller (Unchanged)
  // --------------------------------------------------------------------------------
  Future<void> _extractAndProcess(String? originalPath) async {
    if (originalPath == null) return;
    File? tempFile;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing file... Please wait.';
      _extractedData = null;
    });

    try {
      String pathForOcr = originalPath;
      final extension = p.extension(originalPath).toLowerCase();

      // PDF Conversion Logic (using pdfx)
      if (extension == '.pdf') {
        setState(() {
          _statusMessage = 'Converting PDF to image for OCR (using pdfx)...';
        });

        final doc = await PdfDocument.openFile(originalPath);
        final page = await doc.getPage(1);
        final double targetWidth = page.width * 4;
        final double targetHeight = page.height * 4;

        final PdfPageImage? image = await page.render(
          width: targetWidth,
          height: targetHeight,
        );

        if (image == null) {
          throw Exception(
            "Failed to render PDF page to image data. Image is null or bytes are empty.",
          );
        }

        final tempDir = await getTemporaryDirectory();
        final tempImagePath =
            '${tempDir.path}/temp_ocr_page_${DateTime.now().millisecondsSinceEpoch}.png';

        tempFile = File(tempImagePath);
        await tempFile.writeAsBytes(image.bytes);
        pathForOcr = tempImagePath;
      }

      // Call the OCR processor with the confirmed image path
      final ExtractedScheduleData data = await _processImageForOcr(pathForOcr);

      setState(() {
        _extractedData = data;
        if (data.isValid) {
          _statusMessage = 'Extraction Complete! Review and Confirm.';
        } else {
          _statusMessage =
              'Extraction Complete, but **key data is missing/invalid**. Review Raw Text.';
        }
      });
      debugPrint('Extracted Data: ${data.toString()}');
    } catch (e) {
      setState(() {
        _statusMessage = 'Extraction FAILED. Error: $e';
      });
      debugPrint('Extraction Error: $e');
    } finally {
      if (await tempFile?.exists() ?? false) {
        await tempFile!.delete();
        debugPrint('Temporary PDF image file deleted.');
      }

      setState(() {
        _isProcessing = false;
      });
    }
  }

  // ------------------------------------------------------------------
  // API Submission Logic - Returns data to the caller (DashboardScreen)
  // ------------------------------------------------------------------
  Future<void> _confirmUpload() async {
    // 1. Basic checks
    if (_pickedFilePath == null || _isProcessing || _extractedData == null) {
      return;
    }

    // 2. Data validation
    if (!_extractedData!.isValid) {
      setState(() {
        _statusMessage =
            'Cannot confirm: Extracted data is incomplete/invalid. Please retry.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Uploading schedule and confirming...';
    });

    try {
      final fileToUpload = File(_pickedFilePath!);

      // 3. Call the external API for file upload (this is asynchronous)
      await _apiService.uploadSchedulePdf(fileToUpload, _mockUserId);

      // 4. On successful API call, update status and return data to the dashboard
      if (mounted) {
        setState(() {
          _statusMessage = '✅ Upload successful! Returning data...';
        });
        // Delay briefly for visual confirmation, then pop
        await Future.delayed(const Duration(milliseconds: 500));

        // CRITICAL STEP: POP the screen and return the ExtractedScheduleData object
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop(_extractedData);
      }
    } catch (e) {
      // 5. Handle API failure
      if (mounted) {
        setState(() {
          _statusMessage = 'Upload FAILED: ${e.toString()}';
          _isProcessing = false;
        });
      }
    }
  }

  // --- File Picker Logic (Unchanged) ---
  Future<void> _pickFile() async {
    if (_isProcessing) return;
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        setState(() {
          _pickedFilePath = file.path;
          _statusMessage = 'File selected: ${file.name}. Ready for extraction.';
        });
        await _extractAndProcess(file.path);
      } else {
        setState(() {
          _statusMessage = 'File selection cancelled.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error picking file: $e';
      });
    }
  }

  // --- Camera Capture Logic (Unchanged) ---
  Future<void> _captureImage() async {
    if (_isProcessing) return;
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
      );

      if (photo != null) {
        setState(() {
          _pickedFilePath = photo.path;
          final fileName = p.basename(photo.path);
          _statusMessage = 'Image captured: $fileName. Ready for extraction.';
        });
        await _extractAndProcess(photo.path);
      } else {
        setState(() {
          _statusMessage = 'Camera capture cancelled.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Camera capture error: $e';
      });
    }
  }

  // --- Clear/Retry Logic (Unchanged) ---
  void _clearFile() {
    setState(() {
      _pickedFilePath = null;
      _extractedData = null;
      _statusMessage = 'Ready to upload study load.';
    });
  }

  // Helper widget for the file/camera upload buttons (Unchanged)
  Widget _buildUploadButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: _isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
          child: Row(
            children: [
              Icon(icon, color: primaryColor, size: 28),
              const SizedBox(width: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_isProcessing &&
                  (title.contains('Upload') || title.contains('Capture')))
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: primaryColor.withAlpha((255 * 0.7).round()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color hintColor = Theme.of(context).hintColor;

    final bool canConfirm =
        _pickedFilePath != null &&
        !_isProcessing &&
        (_extractedData?.isValid ?? false); // Check validity here

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Upload Study Load'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Upload your study load document (PDF or image) to automatically extract your class schedule using Tesseract OCR.',
              style: TextStyle(fontSize: 14, color: hintColor),
            ),
            const SizedBox(height: 30),

            // --- Upload/Capture Buttons ---
            _buildUploadButton(
              context,
              icon: Icons.upload_file,
              title: 'Upload from File (PDF/Image)',
              onTap: _pickFile,
            ),
            const SizedBox(height: 15),

            _buildUploadButton(
              context,
              icon: Icons.camera_alt,
              title: 'Capture with Camera (Scan)',
              onTap: _captureImage,
            ),
            const SizedBox(height: 40),

            // --- Status Message ---
            Text(
              'Status:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _statusMessage,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _extractedData != null
                    ? Colors.green.shade700
                    : hintColor,
              ),
            ),
            const SizedBox(height: 20),

            // --- Extracted Data Review Area (Expanded) ---
            Expanded(
              child: _isProcessing
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 10),
                          Text(
                            'Analyzing document...',
                            style: TextStyle(color: hintColor),
                          ),
                        ],
                      ),
                    )
                  : _extractedData != null
                  ? _buildExtractedDataReview(
                      _extractedData!,
                    ) // Display structured data
                  : Container(
                      // Placeholder when no file is processed
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        // ignore: deprecated_member_use
                        border: Border.all(color: hintColor.withOpacity(0.5)),
                      ),
                      child: Center(
                        child: Text(
                          'Select a PDF or image to begin automatic schedule extraction.',
                          style: TextStyle(
                            color: hintColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 20),

            // --- Bottom Action Buttons ---
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickedFilePath != null && !_isProcessing
                        ? _clearFile
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(color: primaryColor),
                    ),
                    child: const Text('Retry / Clear'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: FilledButton(
                    // Only enabled if data is valid and not processing
                    onPressed: canConfirm ? _confirmUpload : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: primaryColor,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Confirm Upload'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
