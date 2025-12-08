// lib/screens/add_pdf_screen.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

// Import necessary services and model
import '../services/api_service.dart';
import '../models/schedule_entry.dart';

// Renaming the class to the new model name for clarity
typedef Schedule = ScheduleEntry;

class AddPdfScreen extends StatefulWidget {
  const AddPdfScreen({super.key});

  @override
  State<AddPdfScreen> createState() => _AddPdfScreenState();
}

class _AddPdfScreenState extends State<AddPdfScreen> {
  String? _pickedFilePath;
  String _statusMessage = 'Ready to upload study load.';

  // 🎯 MODEL UPDATE: Use List<ScheduleEntry>
  List<ScheduleEntry> _extractedSchedules = [];
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  final ApiService _apiService = ApiService();

  // ------------------------------------------------------------------------
  // --- HELPER WIDGETS FOR DISPLAYING EXTRACTED DATA (New Card Design) ---
  // ------------------------------------------------------------------------

  // Widget now uses the ScheduleEntry model
  Widget _buildScheduleCard(ScheduleEntry data, int index) {
    // Determine colors based on data validity or type (similar to screenshot)
    final bool isMissingKeyData =
        data.scheduleCode.isEmpty ||
        data.title.isEmpty ||
        data.startTime.isEmpty;
    final Color cardColor = isMissingKeyData
        ? Colors.red.shade50
        : Theme.of(context).cardColor;
    final Color textColor = isMissingKeyData
        ? Colors.red.shade700
        : Theme.of(context).colorScheme.primary;

    // Format for display
    final String daysAndTimes =
        (data.dayOfWeek?.isNotEmpty == true ? '${data.dayOfWeek} | ' : '') +
        (data.startTime.isNotEmpty ? 'Time: ${data.startTime}' : 'Time: N/A') +
        (data.endTime?.isNotEmpty == true
            ? ' - ${data.endTime}'
            : ''); // Include End Time

    // 🎯 UI FIX: Use data.room (the new field) and update the label
    final String typeAndRoom =
        (data.scheduleType.isNotEmpty
            ? 'Type: ${data.scheduleType} | '
            : 'Type: N/A | ') +
        (data.room?.isNotEmpty == true ? 'Room: ${data.room}' : 'Room: N/A');

    // Determine the subject code for display
    final String subjectCode = data.scheduleCode.isNotEmpty
        ? data.scheduleCode
        : 'UNK-CODE';
    final String subjectTitle = data.title.isNotEmpty
        ? data.title
        : 'Unknown Class Title';

    return Card(
      elevation: 2,
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(
          isMissingKeyData ? Icons.warning_amber_rounded : Icons.menu_book,
          color: isMissingKeyData
              ? Colors.red.shade700
              : Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          '$subjectCode: $subjectTitle',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: textColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              daysAndTimes,
              style: TextStyle(
                fontSize: 13,
                color: textColor.withAlpha((255 * 0.8).round()),
              ),
            ),
            Text(
              typeAndRoom, // Displaying the new room/type line
              style: TextStyle(
                fontSize: 13,
                color: textColor.withAlpha((255 * 0.8).round()),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: textColor.withAlpha((255 * 0.5).round()),
        ),
        onTap: () {
          // TODOImplement navigation to an 'Edit Schedule' screen
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tapped on $subjectCode. Implementation needed for manual correction.',
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget now uses the List<ScheduleEntry> model
  Widget _buildExtractedDataReview(
    List<ScheduleEntry> schedules, {
    required String rawText,
  }) {
    if (schedules.isEmpty) {
      return Center(
        child: Text(
          'No schedules could be extracted from the document.',
          style: TextStyle(
            color: Colors.red.shade700,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    // Check if any critical data is missing (for enabling/disabling Confirm button)
    final bool hasInvalidData = schedules.any(
      (data) => data.scheduleCode.isEmpty || data.title.isEmpty,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Extraction Status & Results (${schedules.length} found)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (hasInvalidData)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              '⚠️ Some entries are incomplete (UNK-CODE). Tap to edit before confirming.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        const SizedBox(height: 10),

        // List of extracted schedules (Scrollable area)
        Expanded(
          child: ListView.builder(
            itemCount: schedules.length,
            itemBuilder: (context, index) {
              return _buildScheduleCard(schedules[index], index);
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --------------------------------------------------------------------------------
  // 🧠 OCR & DATA PROCESSING LOGIC (Uses ScheduleEntry) - **FINAL FIXED LOGIC**
  // --------------------------------------------------------------------------------

  // 🎯 NEW HELPER: Simple Date Formatting (e.g., "01/06/25" -> "2025-01-06")
  String _formatOcrDate(String dateString) {
    try {
      final parts = dateString.split(
        RegExp(r'/\s?'),
      ); // Split by / or / and space
      if (parts.length < 3) return ''; // Return empty string if invalid

      // Attempt to parse MM/DD/YY or MM/DD/YYYY
      final int month = int.tryParse(parts[0]) ?? 1;
      final int day = int.tryParse(parts[1]) ?? 1;
      int year = int.tryParse(parts[2]) ?? DateTime.now().year;

      // Convert two-digit year (e.g., 25 -> 2025)
      if (year < 100) {
        year += 2000;
      }

      // Ensure the date is valid before formatting
      return DateTime(year, month, day).toString().split(' ')[0];
    } catch (e) {
      return ''; // Return empty string on parsing failure
    }
  }

  // Function now returns a List<ScheduleEntry>
  Future<List<ScheduleEntry>> _processImageForOcr(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    RecognizedText?
    recognizedText; // Make this nullable and initialize outside try
    final List<ScheduleEntry> extractedList = [];

    try {
      // 1. Process the image within the try block
      recognizedText = await textRecognizer.processImage(inputImage);

      // Safety check: if processing somehow returned null or failed silently
      // ignore: unnecessary_null_comparison
      if (recognizedText == null) {
        debugPrint('OCR processing returned no text data.');
        return [];
      }

      final rawText = recognizedText.text;

      debugPrint('--- FULL OCR OUTPUT (for Debugging) ---');
      debugPrint(rawText);
      debugPrint('---------------------------------------');

      // CRITICAL FIX 1: Join fragmented time and separator lines.
      String processedText = rawText.replaceAll(RegExp(r'\n\s*-\s*\n'), ' - ');
      processedText = processedText.replaceAll(
        RegExp(r'(\d{1,2}:\d{2})\s*-\s*\n\s*(\d{1,2}:\d{2})'),
        r'$1 - $2',
      );

      // Re-split the processed text into lines
      final lines = processedText
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      // --- (The rest of your extraction logic starts here) ---

      // --- Global Date Variables (for fallback) ---
      String extractedStartDate = '';
      final String fallbackDate = DateTime.now().toString().split(' ')[0];

      // Storage for collected column data
      List<String> courseCodes = [];
      List<String> times = [];
      List<String> days = [];
      List<String> rooms = [];

      // State machine to track which column list we are currently filling
      String currentState = 'NONE';

      // Define RegEx patterns for identification within the vertical lists
      final RegExp courseCodePattern = RegExp(
        r'[A-Z]{2,}-[A-Z0-9]{2,}',
        caseSensitive: false,
      );
      final RegExp timePattern = RegExp(
        r'\d{1,2}:\d{2}\s*(-|\s)\s*\d{1,2}:\d{2}',
        caseSensitive: false,
      );
      final RegExp roomPattern = RegExp(
        r'^\d+[A-Z]?$|^[A-Z]?\d+$',
        caseSensitive: false,
      ); // Match room formats: "536", "B201", "201B", etc.

      // --- Phase 1: Vertical Column Collection ---
      for (var line in lines) {
        String upperLine = line.toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

        // Check for DATE
        if (extractedStartDate.isEmpty && upperLine.contains('DATE ENROLLED')) {
          final RegExp dateRegex = RegExp(r'\d{1,2}/\s?\d{1,2}/\s?\d{2,4}');
          final dateMatch = dateRegex.firstMatch(line);
          if (dateMatch != null) {
            extractedStartDate = _formatOcrDate(dateMatch.group(0)!);
          }
        }

        // Check for column headers to switch state
        if (upperLine.contains('COURSE NO.')) {
          currentState = 'COURSE';
          continue;
        } else if (upperLine.contains('TIME')) {
          currentState = 'TIME';
          continue;
        } else if (upperLine.contains('ROOM')) {
          // Check for ROOM header BEFORE DAYS because sometimes we see "DAYS ROOM" on same line
          currentState = 'ROOM';
          continue;
        } else if (upperLine.contains('DAYS')) {
          currentState = 'DAYS';
          continue;
        } else if (upperLine.contains('SCHED. NO.')) {
          // Ignore schedule numbers, they confuse the course list
          continue;
        }

        // Add line data to the correct list based on state
        switch (currentState) {
          case 'COURSE':
            if (courseCodePattern.hasMatch(line)) {
              courseCodes.add(line);
            }
            break;
          case 'TIME':
            // Handle split time data seen in the raw output (e.g., '3:00 PM')
            // We will try to catch single times or merged times
            if (timePattern.hasMatch(line)) {
              times.add(line);
            } else if (line.contains(RegExp(r'\d{1,2}:\d{2}\s*(PM|AM)'))) {
              // Catch single time stamps
              times.add(line);
            }
            break;
          case 'DAYS':
            // Days are letter patterns: M, MW, FRI, TTH, M-S, MWF, etc.
            // Must start with a letter and be <= 5 chars, NOT all digits
            if (line.length <= 5 &&
                line.contains(RegExp(r'^[A-Za-z]', multiLine: true)) &&
                !RegExp(r'^\d+$').hasMatch(line)) {
              days.add(line);
            }
            break;
          case 'ROOM':
            // Rooms are digits (like '536', '201B', 'B201') or short alphanumeric codes.
            // Accept if it matches the room pattern OR is a short string (<=6 chars) that contains at least one digit
            if (roomPattern.hasMatch(line) ||
                (line.length <= 6 && line.contains(RegExp(r'\d')))) {
              rooms.add(line);
            }
            break;
          default:
            // Ignore lines outside known sections
            break;
        }
      }

      // Debug: Print collected columns after extraction
      debugPrint('Extracted columns:');
      debugPrint('Course Codes: $courseCodes');
      debugPrint('Times: $times');
      debugPrint('Days: $days');
      debugPrint('Rooms: $rooms');

      // --- Phase 2: Horizontal Row Assembly ---
      final int entryCount = courseCodes.length;

      for (int i = 0; i < entryCount; i++) {
        final String code = courseCodes[i].trim();

        // Safely retrieve data from lists, defaulting to null/hardcoded value if the list is too short or empty
        final String timeStr = (i < times.length && times[i].isNotEmpty)
            ? times[i]
            : '08:00 - 09:00 AM';
        final String dayOfWeek = (i < days.length && days[i].isNotEmpty)
            ? days[i]
            : 'M';
        final String roomNumber = (i < rooms.length && rooms[i].isNotEmpty)
            ? rooms[i]
            : 'N/A';

        // Parse Time (Handle cases like "7:30 - 9:30 AM" or just "3:00 PM")
        String startTime = '08:00';
        String? endTime;

        final RegExp timeSplit = RegExp(
          r'(\d{1,2}:\d{2})\s*[-–\s](.+)\s*(PM|AM)',
        ); // Matches 1:00 - 2:00 PM
        final RegExp singleTime = RegExp(
          r'(\d{1,2}:\d{2})\s*(PM|AM)',
        ); // Matches 3:00 PM

        final match = timeSplit.firstMatch(timeStr);

        if (match != null) {
          startTime = match.group(1)!;
          endTime = match.group(2)!.trim();
          final ampm = match.group(3)?.trim();
          if (ampm != null) {
            startTime = '$startTime $ampm';
            endTime = '$endTime $ampm';
          }
        } else {
          final singleMatch = singleTime.firstMatch(timeStr);
          if (singleMatch != null) {
            // FIX: String interpolation used here instead of concatenation
            startTime = '${singleMatch.group(1)!} ${singleMatch.group(2)!}';
            endTime = null;
          } else {
            // Last resort: just use the entire string as start time
            startTime = timeStr;
          }
        }

        // --- Title Guess ---
        final String titleGuess =
            'Class: ${code.replaceAll(RegExp(r'-\d+$|\d+$'), '').trim()}';

        extractedList.add(
          ScheduleEntry(
            scheduleCode: code,
            title: titleGuess,
            scheduleType: 'class',
            startDate: extractedStartDate.isEmpty
                ? fallbackDate
                : extractedStartDate,
            endDate: null,

            startTime: startTime,
            endTime: endTime,
            // FIX: The condition for dayOfWeek is now always true because 'M' is not nullable.
            // We use .isNotEmpty which is safer, but DayOfWeek is a String here, so it's not strictly null.
            repeatFrequency: (dayOfWeek.isNotEmpty) ? 'weekly' : 'none',
            dayOfWeek: dayOfWeek,
            room: roomNumber,

            // Mock metadata
            id: i + 1,
            userId: 0,
            uploaderName: 'Self-Upload',
            isActive: true,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      }

      return extractedList; // Return the list from the try block
    } catch (e) {
      debugPrint('Error during OCR processing: $e');
      // Rethrow or return an empty list depending on desired error handling behavior
      rethrow;
    } finally {
      // 2. CRITICAL: Ensure the recognizer is closed in the finally block
      textRecognizer.close();
    }
  }

  // --------------------------------------------------------------------------------
  // Main Extraction Caller (Logic updated to handle new return type)
  // --------------------------------------------------------------------------------
  Future<void> _extractAndProcess(String? originalPath) async {
    if (originalPath == null) return;
    File? tempFile;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Processing file... Please wait.';
      _extractedSchedules = []; // Clear previous data
    });

    try {
      String pathForOcr = originalPath;
      final extension = p.extension(originalPath).toLowerCase();

      // PDF Conversion Logic (unchanged)
      if (extension == '.pdf') {
        setState(() {
          _statusMessage = 'Converting PDF to image for OCR...';
        });
        final doc = await PdfDocument.openFile(originalPath);
        final page = await doc.getPage(1);
        final PdfPageImage? image = await page.render(
          width: page.width * 3,
          height: page.height * 3,
        );
        if (image == null) {
          throw Exception("Failed to render PDF page to image data.");
        }
        final tempDir = await getTemporaryDirectory();
        final tempImagePath =
            '${tempDir.path}/temp_ocr_page_${DateTime.now().millisecondsSinceEpoch}.png';
        tempFile = File(tempImagePath);
        await tempFile.writeAsBytes(image.bytes);
        pathForOcr = tempImagePath;
      }

      // 🎯 CHANGE 4: Call the OCR processor and receive a List<ScheduleEntry>
      final List<ScheduleEntry> extractedList = await _processImageForOcr(
        pathForOcr,
      );

      // Check validity (at least one valid schedule found)
      final bool isValid = extractedList.any(
        (data) => data.scheduleCode.isNotEmpty,
      );

      setState(() {
        _extractedSchedules = extractedList;
        if (isValid) {
          _statusMessage = 'Extraction Complete! Review and Confirm.';
        } else {
          _statusMessage =
              'Extraction Complete, but **no valid schedules were found**. Review or Retry.';
        }
      });
      debugPrint('Extracted ${extractedList.length} schedules.');
    } catch (e) {
      setState(() {
        _statusMessage = 'Extraction FAILED: ${e.toString()}';
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
  // API Submission Logic - BULK SAVE (Uses ScheduleEntry)
  // ------------------------------------------------------------------
  Future<void> _confirmUpload() async {
    if (_pickedFilePath == null ||
        _isProcessing ||
        _extractedSchedules.isEmpty) {
      return;
    }

    // Filter out invalid/incomplete entries before sending to the server
    final List<Map<String, dynamic>> schedulesToSave = _extractedSchedules
        .where(
          (data) =>
              data.scheduleCode.isNotEmpty &&
              data.title.isNotEmpty &&
              data.startDate.isNotEmpty &&
              data.startTime.isNotEmpty &&
              data.repeatFrequency.isNotEmpty,
        )
        // 🎯 Change 5: Call toJson() on ScheduleEntry to get the correct Map format
        .map((data) => data.toJson())
        .toList();

    if (schedulesToSave.isEmpty) {
      setState(() {
        _statusMessage = 'Cannot confirm: No complete schedules to save.';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage =
          'Uploading file and saving ${schedulesToSave.length} schedule entries...';
    });

    try {
      final fileToUpload = File(_pickedFilePath!);
      final currentUserId = await _apiService.getUserId();
      if (currentUserId == null) {
        throw Exception("User ID not available. Please log in.");
      }

      // --- STEP 1: Upload the PDF/Image file (for history/server-side extraction record) ---
      final uploadFileResponse = await _apiService.uploadSchedulePdf(
        fileToUpload,
        currentUserId.toString(),
      );
      debugPrint('File uploaded successfully. Response: $uploadFileResponse');

      // --- STEP 2: Save the extracted schedule data to the database (BULK SAVE) ---
      // Use the bulk save API call
      final saveScheduleResponse = await _apiService.saveExtractedSchedules(
        schedulesToSave,
      );
      debugPrint(
        'Schedule data bulk saved successfully. Response: $saveScheduleResponse',
      );

      if (mounted) {
        // We need to return the saved schedule list to the Dashboard
        final savedEntries = _extractedSchedules;

        setState(() {
          final savedCount =
              saveScheduleResponse['saved_count'] ?? schedulesToSave.length;
          _statusMessage =
              '✅ Upload & Save successful! Saved $savedCount entries.';
        });
        await Future.delayed(const Duration(milliseconds: 500));

        // 🎯 FIX: Return the list of extracted schedules (ScheduleEntry objects)
        // to the calling screen (DashboardScreen).
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop(savedEntries);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Upload FAILED: ${e.toString()}';
          _isProcessing = false;
        });
      }
      // If the upload fails, return null or false.
      // ignore: use_build_context_synchronously
      if (mounted) Navigator.of(context).pop(false);
    }
  }

  // --- Clear/Retry Logic (Unchanged) ---
  void _clearFile() {
    setState(() {
      _pickedFilePath = null;
      _extractedSchedules = [];
      _statusMessage = 'Ready to upload study load.';
    });
  }

  // ------------------------------------------------------------------
  // ⭐️ ADDED: Missing Helper Methods (_pickFile, _captureImage)
  // ------------------------------------------------------------------

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

  // ------------------------------------------------------------------
  // ⭐️ ADDED: Missing Helper Widget (_buildUploadButton)
  // ------------------------------------------------------------------
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

    // Check validity: Can confirm if we have a file, are not processing,
    // and have at least one complete schedule entry ready to save.
    final bool canConfirm =
        _pickedFilePath != null &&
        !_isProcessing &&
        // Check if AT LEAST ONE entry meets the server's required fields
        _extractedSchedules.any(
          (data) =>
              data.scheduleCode.isNotEmpty &&
              data.title.isNotEmpty &&
              data.startDate.isNotEmpty &&
              data.startTime.isNotEmpty &&
              data.repeatFrequency.isNotEmpty,
        );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('OCR Upload Module'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Upload your study load document (PDF) to automatically extract your class schedule.',
              style: TextStyle(fontSize: 14, color: hintColor),
            ),
            const SizedBox(height: 30),

            // --- Upload/Capture Buttons ---
            _buildUploadButton(
              context,
              icon: Icons.upload_file,
              title: 'Upload from File (PDF)',
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
                color: _extractedSchedules.isNotEmpty
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
                            _statusMessage,
                            style: TextStyle(color: hintColor),
                          ),
                        ],
                      ),
                    )
                  : _extractedSchedules.isNotEmpty
                  ? _buildExtractedDataReview(
                      _extractedSchedules,
                      rawText: 'Raw Text Hidden',
                    )
                  : Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: hintColor.withAlpha((255 * 0.5).round()),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Select a PDF to begin automatic schedule extraction.',
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
                    onPressed: canConfirm ? _confirmUpload : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: primaryColor,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: const Text('Confirm and Save'),
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
