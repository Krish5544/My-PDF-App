import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart'; // पीडीएफ क्रिएशन के लिए
import 'package:pdf/widgets.dart' as pw; // पीडीएफ विजेट्स के लिए
import 'package:path_provider/path_provider.dart'; // फाइल पाथ के लिए

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
    ).then((_) => _loadRecentFiles()); // वापस आने पर रिसेंट लिस्ट रिफ्रेश होगी
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
          // ऊपर का हिस्सा: फीचर्स के बटन्स (ग्रिड/रो लुक)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // बटन 1: PDF खोलें
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
                // बटन 2: इमेज टू PDF
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
          
          // नीचे का हिस्सा: रिसेंट फाइल्स
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

// ------ नया पन्ना: इमेज टू पीडीएफ (प्रीव्यू और ऑर्डर सेटिंग्स के साथ) ------
class ImageToPdfScreen extends StatefulWidget {
  @override
  _ImageToPdfScreenState createState() => _ImageToPdfScreenState();
}

class _ImageToPdfScreenState extends State<ImageToPdfScreen> {
  List<File> _selectedImages = []; // चुनी गई इमेजेस की लिस्ट
  bool _isConverting = false;

  // गैलरी से मल्टीपल इमेजेस चुनने का फंक्शन
  Future<void> _pickImages() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true, // एक से ज्यादा फोटो चुनने की परमिशन
    );

    if (result != null) {
      setState(() {
        _selectedImages.addAll(result.paths.map((path) => File(path!)).toList());
      });
    }
  }

  // पेज को ऊपर ले जाने का फंक्शन
  void _moveUp(int index) {
    if (index > 0) {
      setState(() {
        File temp = _selectedImages.removeAt(index);
        _selectedImages.insert(index - 1, temp);
      });
    }
  }

  // पेज को नीचे ले जाने का फंक्शन
  void _moveDown(int index) {
    if (index < _selectedImages.length - 1) {
      setState(() {
        File temp = _selectedImages.removeAt(index);
        _selectedImages.insert(index + 1, temp);
      });
    }
  }

  // इमेज को लिस्ट से हटाने का फंक्शन
  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // फाइनल पीडीएफ बनाने का फंक्शन
  Future<void> _convertToPdf() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isConverting = true;
    });

    try {
      final pdf = pw.Document();

      // सभी चुनी गई इमेजेस को एक-एक पेज पर जोड़ना
      for (var imageFile in _selectedImages) {
        final image = pw.MemoryImage(imageFile.readAsBytesSync());
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
            },
          ),
        );
      }

      // फोन की डॉक्यूमेंट डायरेक्टरी में सेव करना ताकि सुरक्षित रहे
      final outputDir = await getApplicationDocumentsDirectory();
      final filePath = "${outputDir.path}/PDF_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // रिसेंट मेमोरी में सेव करें
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> recents = prefs.getStringList('recent_pdfs') ?? [];
      recents.insert(0, filePath);
      await prefs.setStringList('recent_pdfs', recents);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("पीडीएफ सफलतापूर्वक बन गई है!")),
      );

      Navigator.pop(context); // काम पूरा होने पर डैशबोर्ड पर वापस जाएं
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
          ? Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : Column(
              children: [
                SizedBox(height: 15),
                // इमेजेस चुनने का बटन
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: Icon(Icons.add_photo_alternate, color: Colors.black),
                  label: Text("मोबाइल से इमेज चुनें", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                ),
                SizedBox(height: 15),
                // प्रीव्यू और री-ऑर्डर लिस्ट
                Expanded(
                  child: _selectedImages.isEmpty
                      ? Center(child: Text("कोई इमेज नहीं चुनी गई है", style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: _selectedImages.length,
                          itemBuilder: (context, index) {
                            return Card(
                              color: Colors.grey[850],
                              margin: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.file(_selectedImages[index], width: 50, height: 50, fit: BoxFit.cover),
                                ),
                                title: Text("पेज नंबर ${index + 1}", style: TextStyle(color: Colors.white)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ऊपर ले जाने का बटन
                                    IconButton(
                                      icon: Icon(Icons.arrow_upward, color: Colors.grey),
                                      onPressed: index == 0 ? null : () => _moveUp(index),
                                    ),
                                    // नीचे ले जाने का बटन
                                    IconButton(
                                      icon: Icon(Icons.arrow_downward, color: Colors.grey),
                                      onPressed: index == _selectedImages.length - 1 ? null : () => _moveDown(index),
                                    ),
                                    // डिलीट बटन
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.redAccent),
                                      onPressed: () => _removeImage(index),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // फाइनल पीडीएफ बनाने का बटन (सिर्फ तब दिखेगा जब इमेज चुनी हो)
                if (_selectedImages.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    key: ValueKey('generate_btn'),
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
