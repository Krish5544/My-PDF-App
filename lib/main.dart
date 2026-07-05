import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:shared_preferences/shared_preferences.dart'; // मेमोरी के लिए

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Best PDF Editor',
      debugShowCheckedModeBanner: false,
      home: DashboardScreen(), // अब ऐप डैशबोर्ड से शुरू होगी
    );
  }
}

// ------ पहला पन्ना: आपका डैशबोर्ड (रिसेंट फाइल्स के साथ) ------
class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<String> _recentFiles = []; // यहाँ आपकी पुरानी फाइलों की लिस्ट रहेगी

  @override
  void initState() {
    super.initState();
    _loadRecentFiles(); // ऐप खुलते ही पुरानी फाइलें लोड होंगी
  }

  // मेमोरी से रिसेंट फाइलें निकालने का फंक्शन
  Future<void> _loadRecentFiles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _recentFiles = prefs.getStringList('recent_pdfs') ?? [];
    });
  }

  // नई फाइल को रिसेंट लिस्ट में सेव करने का फंक्शन
  Future<void> _saveRecentFile(String path) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _recentFiles.remove(path); // अगर पहले से है, तो हटा दो
    _recentFiles.insert(0, path); // और लिस्ट में सबसे ऊपर डाल दो
    if (_recentFiles.length > 10) {
      _recentFiles = _recentFiles.sublist(0, 10); // सिर्फ आखिरी 10 फाइलें ही सेव रखो
    }
    await prefs.setStringList('recent_pdfs', _recentFiles);
    setState(() {});
  }

  // फाइल मैनेजर से नई फाइल चुनने का फंक्शन
  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      String path = result.files.single.path!;
      await _saveRecentFile(path); // चुनी गई फाइल को मेमोरी में सेव करो
      _openPdfScreen(path); // और पढ़ने वाले पन्ने पर भेज दो
    }
  }

  // PDF पढ़ने वाले पन्ने पर जाने का फंक्शन
  void _openPdfScreen(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(pdfPath: path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('मेरा PDF एडिटर', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ऊपर का हिस्सा: फोटो के डिज़ाइन जैसा गोल बटन
          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Row(
              children: [
                InkWell(
                  onTap: _pickPdf,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.blueAccent.withOpacity(0.2),
                        child: Icon(Icons.picture_as_pdf, size: 35, color: Colors.blueAccent),
                      ),
                      SizedBox(height: 10),
                      Text("PDF खोलें", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          Divider(color: Colors.grey[700], thickness: 1),
          
          // नीचे का हिस्सा: रिसेंट फाइल्स की लिस्ट
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
              "रिसेंट फाइल्स (Recent)",
              style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.bold),
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
                      String fileName = path.split('/').last; // फाइल के रास्ते से सिर्फ नाम अलग करना
                      return ListTile(
                        leading: Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 30),
                        title: Text(fileName, style: TextStyle(color: Colors.white)),
                        subtitle: Text(path, style: TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () {
                          _saveRecentFile(path); // क्लिक करने पर इसे लिस्ट में सबसे ऊपर ले आओ
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

// ------ दूसरा पन्ना: जहाँ आपकी किताब/PDF खुलेगी ------
class PdfViewerScreen extends StatelessWidget {
  final String pdfPath;

  PdfViewerScreen({required this.pdfPath});

  @override
  Widget build(BuildContext context) {
    String fileName = pdfPath.split('/').last;
    return Scaffold(
      appBar: AppBar(
        title: Text(fileName, style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SfPdfViewer.file(File(pdfPath)),
    );
  }
}
