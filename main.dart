import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const StudentQRApp());
}

class StudentQRApp extends StatelessWidget {
  const StudentQRApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Information QR Generator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const StudentQRPage(),
    );
  }
}

class StudentDataModel {
  final String name;
  final String id;
  final String email;
  final String phone;
  final String department;
  final String year;
  final int colorValue;
  final String generated;

  StudentDataModel({
    required this.name,
    required this.id,
    required this.email,
    required this.phone,
    required this.department,
    required this.year,
    required this.colorValue,
    required this.generated,
  });

  factory StudentDataModel.fromJson(Map<String, dynamic> json) {
    return StudentDataModel(
      name: json['name'] ?? '',
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      department: json['department'] ?? '',
      year: json['year'] ?? '',
      colorValue: int.tryParse(json['color'], radix: 16) ?? Colors.indigo.value,
      generated: json['generated'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'email': email,
      'phone': phone,
      'department': department,
      'year': year,
      'color': colorValue.toRadixString(16),
      'generated': generated,
    };
  }
}

class StudentQRPage extends StatefulWidget {
  const StudentQRPage({Key? key}) : super(key: key);

  @override
  State<StudentQRPage> createState() => _StudentQRPageState();
}

class _StudentQRPageState extends State<StudentQRPage> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // QR code key for capturing the image
  final GlobalKey _qrKey = GlobalKey();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  // QR data
  String _qrData = '';
  bool _showQR = false;

  // Selected profile color
  Color _profileColor = Colors.indigo;
  final List<Color> _colorOptions = [
    Colors.indigo,
    Colors.teal,
    Colors.red,
    Colors.purple,
    Colors.orange,
    Colors.green,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _departmentController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _generateQRCode() {
    if (_formKey.currentState!.validate()) {
      // Create data for QR code
      final studentData = StudentDataModel(
        name: _nameController.text,
        id: _idController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        department: _departmentController.text,
        year: _yearController.text,
        colorValue: _profileColor.value,
        generated: DateTime.now().toIso8601String(),
      );

      // Convert to JSON string
      final jsonData = jsonEncode(studentData.toJson());

      setState(() {
        _qrData = jsonData;
        _showQR = true;
      });
    }
  }

  // Save QR code to gallery
  Future<void> _saveQRToGallery() async {
    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // Save to gallery
        final result = await ImageGallerySaver.saveImage(pngBytes,
            quality: 100,
            name: "student_qr_${DateTime.now().millisecondsSinceEpoch}");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR Code saved to gallery')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save QR Code: $e')),
      );
    }
  }

  // Share QR code
  Future<void> _shareQRCode() async {
    try {
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // Create a temporary file
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/student_qr.png').create();
        await file.writeAsBytes(pngBytes);

        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Student QR Code for ${_nameController.text}',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share QR Code: $e')),
      );
    }
  }

  Widget _buildColorPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Profile Color: ',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Wrap(
          spacing: 8,
          children: _colorOptions
              .map((color) => InkWell(
                    onTap: () {
                      setState(() {
                        _profileColor = color;
                      });
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _profileColor == color
                              ? Colors.white
                              : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: _profileColor == color
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 5,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Information QR Generator'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QRScannerPage(),
                ),
              );
            },
            tooltip: 'Scan QR Code',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade50, Colors.white],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Student Information Form
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Center(
                              child: Text(
                                'Student Information',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                            ),
                            const SizedBox(height: 25),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter student name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _idController,
                              decoration: InputDecoration(
                                labelText: 'Student ID',
                                prefixIcon: const Icon(Icons.badge),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter student ID';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter email address';
                                }
                                if (!value.contains('@')) {
                                  return 'Please enter a valid email address';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _phoneController,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: const Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _departmentController,
                              decoration: InputDecoration(
                                labelText: 'Department',
                                prefixIcon: const Icon(Icons.business),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter department';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              controller: _yearController,
                              decoration: InputDecoration(
                                labelText: 'Year/Semester',
                                prefixIcon: const Icon(Icons.calendar_today),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter year/semester';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildColorPicker(),
                            const SizedBox(height: 25),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _generateQRCode,
                                icon: const Icon(Icons.qr_code),
                                label: const Text('Generate QR Code'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30, vertical: 15),
                                  textStyle: const TextStyle(fontSize: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // QR Code Display
                  if (_showQR) ...[
                    const SizedBox(height: 30),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            const Text(
                              'Student QR Code',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Real QR Code generation
                            RepaintBoundary(
                              key: _qrKey,
                              child: Container(
                                width: 250,
                                height: 250,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: QrImageView(
                                        data: _qrData,
                                        version: QrVersions.auto,
                                        size: 200,
                                        backgroundColor: Colors.white,
                                        foregroundColor: _profileColor,
                                        eyeStyle: QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: _profileColor,
                                        ),
                                        dataModuleStyle: QrDataModuleStyle(
                                          dataModuleShape:
                                              QrDataModuleShape.square,
                                          color: _profileColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _profileColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        _nameController.text,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: _profileColor,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.center,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Student Preview Card
                            Container(
                              width: 300,
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _profileColor,
                                    _profileColor.withOpacity(0.7)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: _profileColor.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.white,
                                    radius: 40,
                                    child: Text(
                                      _nameController.text.isNotEmpty
                                          ? _nameController.text
                                              .split(' ')
                                              .map((e) =>
                                                  e.isNotEmpty ? e[0] : '')
                                              .join('')
                                          : 'S',
                                      style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: _profileColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    _nameController.text,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    _departmentController.text,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.school,
                                            color: Colors.white),
                                        const SizedBox(width: 5),
                                        Text(
                                          _idController.text,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _saveQRToGallery,
                                  icon: const Icon(Icons.download),
                                  label: const Text('Download'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo.shade100,
                                    foregroundColor: Colors.indigo,
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _shareQRCode,
                                  icon: const Icon(Icons.share),
                                  label: const Text('Share'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo.shade100,
                                    foregroundColor: Colors.indigo,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Scan this QR code with the scanner in this app to view student details',
                              style: TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// QR Scanner Page
class QRScannerPage extends StatefulWidget {
  const QRScannerPage({Key? key}) : super(key: key);

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  MobileScannerController controller = MobileScannerController();
  bool _isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Student QR Code'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.flash_off : Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: controller,
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;

                for (final barcode in barcodes) {
                  if (barcode.rawValue != null && _isScanning) {
                    setState(() {
                      _isScanning = false;
                    });

                    try {
                      final data = jsonDecode(barcode.rawValue!);
                      final student = StudentDataModel.fromJson(data);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StudentDetailsPage(student: student),
                        ),
                      ).then((_) {
                        setState(() {
                          _isScanning = true;
                        });
                      });
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Invalid QR code format. Please scan a valid student QR code.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      setState(() {
                        _isScanning = true;
                      });
                    }
                  }
                }
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo,
            width: double.infinity,
            child: const Text(
              'Point the camera at a Student QR Code',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// Student Details Page (shown after scanning)
class StudentDetailsPage extends StatelessWidget {
  final StudentDataModel student;

  const StudentDetailsPage({Key? key, required this.student}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color profileColor = Color(student.colorValue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Details'),
        backgroundColor: profileColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [profileColor.withOpacity(0.1), Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Student Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [profileColor, profileColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: profileColor.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 50,
                        child: Text(
                          student.name.isNotEmpty
                              ? student.name
                                  .split(' ')
                                  .map((e) => e.isNotEmpty ? e[0] : '')
                                  .join('')
                              : 'S',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: profileColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        student.department,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.school, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              student.id,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Details Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          'Student Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Student Details List
                        _buildInfoRow(Icons.badge, 'Student ID', student.id),
                        _buildInfoRow(Icons.email, 'Email', student.email),
                        _buildInfoRow(Icons.phone, 'Phone', student.phone),
                        _buildInfoRow(
                            Icons.business, 'Department', student.department),
                        _buildInfoRow(Icons.calendar_today, 'Year/Semester',
                            student.year),
                        _buildInfoRow(Icons.access_time, 'Generated On',
                            _formatDateTime(student.generated)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Color(student.colorValue)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value.isNotEmpty ? value : 'Not provided',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String dateTimeStr) {
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeStr;
    }
  }
}
