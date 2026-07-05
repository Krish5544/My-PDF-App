import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Best PDF Editor',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}

// चूँकि हम स्क्रीन पर बदलाव (PDF दिखाना) करेंगे, इसलिए इसे StatefulWidget बनाया है
class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedPdf; // चुनी गई PDF फाइल यहाँ सेव होगी

  // फाइल पिकर खोलने का फंक्शन
  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // सिर्फ PDF फाइलें दिखेंगी
    );

    if (result != null) {
      setState(() {
        _selectedPdf = File(result.files.single.path!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text(
          'मेरा PDF एडिटर',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // अगर कोई PDF खुली है, तो ऊपर एक 'फोल्डर' आइकॉन दिखेगा ताकि दूसरी फाइल चुनी जा सके
          if (_selectedPdf != null)
            IconButton(
              icon: Icon(Icons.folder_open),
              onPressed: _pickPdf,
              tooltip: 'दूसरी PDF चुनें',
            )
        ],
      ),
      // अगर PDF नहीं चुनी गई है तो बटन दिखाओ, अगर चुन ली गई है तो PDF दिखाओ
      body: _selectedPdf == null
          ? Center(
              child: ElevatedButton.icon(
                onPressed: _pickPdf, // बटन दबाने पर फाइल पिकर खुलेगा
                icon: Icon(Icons.folder_open, color: Colors.white),
                label: Text(
                  "PDF फाइल चुनें",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            )
          : SfPdfViewer.file(_selectedPdf!), // यहाँ आपकी किताब खुलेगी
    );
  }
}
