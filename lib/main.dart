import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img_pkg; // इमेज रोटेट करने के लिए

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Best PDF Editor',
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(),
    );
  }
}

// ------ मुख्य डैशबोर्ड स्क्रीन ------
class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<String> _recentFiles = [];

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  Future<void> _loadRecentFiles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentFiles = prefs.getStringList('recent_pdfs') ?? [];
    });
  }

  Future<void> _saveRecentFile(String path) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _recentFiles.remove(path);
    _recentFiles.insert(0, path);
    if (_recentFiles.length > 10) {
      _recentFiles = _recentFiles.sublist(0, 10);
    }
    await prefs.setStringList('recent_pdfs', _recentFiles);
    setState(() {});
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      String path = result.files.single.path!;
      await _saveRecentFile(path);
      _openPdfScreen(path);
    }
  }

  void _openPdfScreen(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(pdfPath: path),
      ),
    ).then((_) => _loadRecentFiles());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('मेरा PDF एडिटर', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _pickPdf,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        child: Icon(Icons.picture_as_pdf, size: 32, color: Colors.blueAccent),
                      ),
                      SizedBox(height: 8),
                      Text("PDF खोलें", style: TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
                SizedBox(width: 30),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ImageToPdfScreen()),
                    ).then((_) => _loadRecentFiles());
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Colors.greenAccent.withOpacity(0.2),
                        child: Icon(Icons.image, size: 32, color: Colors.greenAccent),
                      ),
                      SizedBox(height: 8),
                      Text("इमेज टू PDF", style: TextStyle(color: Colors.white, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey[800], thickness: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Text(
              "रिसेंट फाइल्स (Recent)",
              style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: _recentFiles.isEmpty
                ? Center(
                    child: Text("अभी तक कोई फाइल नहीं खोली गई है", style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    itemCount: _recentFiles.length,
                    itemBuilder: (context, index) {
                      String path = _recentFiles[index];
                      String fileName = path.split('/').last;
                      return ListTile(
                        leading: Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 28),
                        title: Text(fileName, style: TextStyle(color: Colors.white, fontSize: 15)),
                        subtitle: Text(path, style: TextStyle(color: Colors.grey, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          _saveRecentFile(path);
                          _openPdfScreen(path);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ------ फोटो का डेटा स्टोर करने के लिए एक नई क्लास ------
class SelectedImage {
  final File file;
  int quarterTurns; // 90 डिग्री के लिए (0, 1, 2, 3)

  SelectedImage({required this.file, this.quarterTurns = 0});
}

// ------ नया पन्ना: इमेज टू पीडीएफ (प्रीव्यू और रोटेट के साथ) ------
class ImageToPdfScreen extends StatefulWidget {
  @override
  _ImageToPdfScreenState createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  List<SelectedImage> _selectedImages = [];
  bool _isConverting = false;

  Future<void> _pickImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _selectedImages.addAll(result.paths.map((path) => SelectedImage(file: File(path!))).toList());
      });
    }
  }

  void _moveUp(int index) {
    if (index > 0) {
      setState(() {
        SelectedImage temp = _selectedImages.removeAt(index);
        _selectedImages.insert(index - 1, temp);
      });
    }
  }

  void _moveDown(int index) {
    if (index < _selectedImages.length - 1) {
      setState(() {
        SelectedImage temp = _selectedImages.removeAt(index);
        _selectedImages.insert(index + 1, temp);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // --- इमेज को फुल स्क्रीन में दिखाने का फंक्शन (Preview) ---
  void _showImagePreview(SelectedImage item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer( // फोटो को ज़ूम करने की सुविधा
              child: RotatedBox(
                quarterTurns: item.quarterTurns,
                child: Image.file(item.file),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 35),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _convertToPdf() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isConverting = true;
    });

    try {
      final pdf = pw.Document();

      for (var item in _selectedImages) {
        Uint8List imageBytes = await item.file.readAsBytes();

        // अगर फोटो घुमाई गई है (Rotate), तो उसे प्रोसेस करें
        if (item.quarterTurns % 4 != 0) {
          img_pkg.Image? decodedImage = img_pkg.decodeImage(imageBytes);
          if (decodedImage != null) {
            int angle = (item.quarterTurns % 4) * 90;
            img_pkg.Image rotatedImage = img_pkg.copyRotate(decodedImage, angle: angle);
            imageBytes = img_pkg.encodeJpg(rotatedImage); // घुमाकर वापस सेव करना
          }
        }

        final pdfImage = pw.MemoryImage(imageBytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain));
            },
          ),
        );
      }

      final outputDir = await getApplicationDocumentsDirectory();
      final filePath = "${outputDir.path}/PDF_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> recents = prefs.getStringList('recent_pdfs') ?? [];
      recents.insert(0, filePath);
      await prefs.setStringList('recent_pdfs', recents);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("पीडीएफ सफलतापूर्वक बन गई है!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("एरर: पीडीएफ नहीं बन सकी")),
      );
    } finally {
      setState(() {
        _isConverting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('इमेज टू PDF बनाएं'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: _isConverting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 20),
                  Text("PDF बन रही है, कृपया प्रतीक्षा करें...", style: TextStyle(color: Colors.white, fontSize: 16))
                ],
              ),
            )
          : Column(
              children: [
                SizedBox(height: 15),
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: Icon(Icons.add_photo_alternate, color: Colors.black),
                  label: Text("मोबाइल से इमेज चुनें", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                ),
                SizedBox(height: 15),
                Expanded(
                  child: _selectedImages.isEmpty
                      ? Center(child: Text("कोई इमेज नहीं चुनी गई है", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            var item = _selectedImages[index];
                            return Card(
                              color: Colors.grey[850],
                              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                // फोटो पर क्लिक करने पर प्रीव्यू खुलेगा
                                leading: InkWell(
                                  onTap: () => _showImagePreview(item),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: RotatedBox(
                                      quarterTurns: item.quarterTurns,
                                      child: Image.file(item.file, width: 50, height: 50, fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                                title: Text("पेज नंबर ${index + 1}", style: TextStyle(color: Colors.white)),
                                trailing: FittedBox(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // नया 90-डिग्री रोटेट बटन
                                      IconButton(
                                        icon: Icon(Icons.rotate_right, color: Colors.blueAccent, size: 26),
                                        onPressed: () {
                                          setState(() {
                                            item.quarterTurns = (item.quarterTurns + 1) % 4;
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.arrow_upward, color: Colors.grey, size: 24),
                                        onPressed: index == 0 ? null : () => _moveUp(index),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.arrow_downward, color: Colors.grey, size: 24),
                                        onPressed: index == _selectedImages.length - 1 ? null : () => _moveDown(index),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.redAccent, size: 24),
                                        onPressed: () => _removeImage(index),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                if (_selectedImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Container(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _convertToPdf,
                        child: Text("कन्वर्ट टू PDF", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// ------ दूसरा पन्ना: जहाँ पीडीएफ खुलेगी ------
class PdfViewerScreen extends StatelessWidget {
  final String pdfPath;

  PdfViewerScreen({required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    String fileName = pdfPath.split('/').last;
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName, style: TextStyle(fontSize: 15)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SfPdfViewer.file(File(pdfPath)),
    );
  }
}
