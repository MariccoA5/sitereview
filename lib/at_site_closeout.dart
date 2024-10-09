import 'dart:io';

import 'package:flutter/material.dart';

import 'package:site_connect/share_site.dart';
import 'package:site_connect/take_picture.dart';


class SiteCloseoutForm extends StatefulWidget {
  const SiteCloseoutForm({super.key});

  @override
  _SiteCloseoutFormState createState() => _SiteCloseoutFormState();
}

class _SiteCloseoutFormState extends State<SiteCloseoutForm> {
  final TextEditingController _siteNumberController = TextEditingController();
  final TextEditingController _siteNameController = TextEditingController();
  final TextEditingController _contractorController = TextEditingController();
  final TextEditingController _techInitialsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  final List<TextEditingController> _commentControllers = List.generate(3, (index) => TextEditingController());

  final List<bool> _checkboxValues = List.generate(8, (index) => false);
  final List<bool> _checkboxValues2 = List.generate(8, (index) => false);
  final List<bool> _checkboxValues3 = List.generate(10, (index) => false);

  List<File> _capturedPhotos = []; 

  List<String> checkboxQuestions = [
      'Herbicide applied to compound and exterior compound perimeter',
      'Small trash items removed from site = (1) 55 gal trash bag',
      'Vegetation removal & herbicide application around utilities and parking area\n\t- Glyphosate spray rate: 3.22 lb a.e./A. (glyphosate)\n\t- Glyphosate spray height: no higher than twelve (12) inches from ground level',
      'Marking dye used in herbicide application', 
      'Leaves blown/raked out of compound', 
      'Access road serviced (out 3’ back on both sides of the road and herbicide applied)', 
      'Mow guy paths from compound to anchor pens, where accessible', 
      'Weed removal/herbicide application on guy pens/anchor points'
    ];

  List<String> checkboxQuestions2 = [
      'Site’s security compromised (see comments)',
      'Site ID Sign Missing or illegible/faded',
      'Major fence damage to compound or guy compound',
      'Compound or Guy Compound washed out',
      'Access road washed out',
      'Vandalism (see comments)',
      'Bird nest present',
      'Utilities down or damaged (see comments)'
    ];

  List<String> checkboxQuestions3 = [
      'Trees within 5’ of tower',
      'Trees within 5’ of compound',
      'Excessive Trash/Construction Debris',
      'Fence/Gate Damage',
      'Trees in guy paths',
      'Dead/Hazard trees in danger of falling',
      'Access Road needs attention',
      'Cut volunteer trees/brush out of screening landscaping',
      'Trees in compound/guy compounds',
      'Cut back clear overgrown access road'
    ];
    
      
  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _contractorController.dispose();
    _siteNumberController.dispose();
    _techInitialsController.dispose();
    for (var controller in _commentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
Map<String, dynamic> _submitForm() {
  final contractor = _contractorController.text;
  final techInitials = _techInitialsController.text;

  final mainCheckbox = _checkboxValues;
  final mainComments = _commentControllers[0].text;
  final iaiCheckbox = _checkboxValues2;
  final iaiComments = _commentControllers[1].text;
  final ooswCheckbox = _checkboxValues3;
  final ooswComments = _commentControllers[2].text;
  final selectedDate = _selectedDate.toString();

  return {
    'contractor': contractor,
    'techInitials': techInitials,
    'mainCheckbox': mainCheckbox,
    'mainComments': mainComments,
    'iaiCheckbox': iaiCheckbox,
    'iaiComments': iaiComments,
    'ooswCheckbox': ooswCheckbox,
    'ooswComments': ooswComments,
    'siteName': _siteNameController.text,
    'selectedDate': selectedDate,
    'photos': _capturedPhotos,
    'siteNumber': _siteNumberController.text,
  };
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Closeout Form'),
        leading: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            // Clear all text fields and checkboxes
            _contractorController.clear();
            _techInitialsController.clear();
            _siteNumberController.clear();
            for (var controller in _commentControllers) {
              controller.clear();
            }
            setState(() {
              _capturedPhotos.clear();
              _siteNumberController.clear();
              _selectedDate = DateTime.now();
              _checkboxValues.fillRange(0, 8, false);
              _checkboxValues2.fillRange(0, 8, false);
              _checkboxValues3.fillRange(0, 10, false);
            });
          
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              if (_capturedPhotos.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please take photos before saving the form.')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PdfGeneratorPage(
                    submitForm: _submitForm(), // Your form data here
                   
                  ),
                ),
              );

              },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the image from assets at the top
              Image.asset(
              'assets/psATLogo.png', 
              height: 200, // Adjust the size based on your needs
              fit: BoxFit.contain,

            ),
            const SizedBox(height: 20),

            // Site Information header
            const Text(
              'Site Information',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _siteNameController,
              decoration: const InputDecoration(
                labelText: 'Site Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 10),
            TextField(
              controller: _siteNumberController,
              decoration: const InputDecoration(
                labelText: 'Site Number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Contractor field
            TextField(
              controller: _contractorController,
              decoration: const InputDecoration(
                labelText: 'Contractor',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Tech Initials field
            TextField(
              controller: _techInitialsController,
              decoration: const InputDecoration(
                labelText: 'Tech\'s Initials',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Date Picker
            Row(
              children: [
                Text("Date: ${_selectedDate.toLocal().toString().split(' ')[0]}"),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: () => _selectDate(context),
                  child: const Icon(Icons.calendar_month),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              'Number of photos taken: ${_capturedPhotos.length}',
            ),
            const SizedBox(height: 20),

            // Main SOW header
            const Padding(
              padding: EdgeInsets.fromLTRB(8.0, 8, 0, 0),
              child: Text(
                'Main SOW:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),

            // Questions with Checkboxes and Comments
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              itemBuilder: (context, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Example of customized checkbox tile
                    CheckboxListTile(
                      title: Text(checkboxQuestions[index]),
                      value: _checkboxValues[index],
  
                      onChanged: (bool? value) {
                        setState(() {
                          _checkboxValues[index] = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
            
                  ],
                );
              },
            ),
            TextField(
              controller: _commentControllers[0],
              decoration: const InputDecoration(
                labelText: 'Comments',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Immediate Attention Issues:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 8,
              itemBuilder: (context, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Example of customized checkbox tile
                    CheckboxListTile(
                      title: Text(checkboxQuestions2[index]),
                      value: _checkboxValues2[index],
  
                      onChanged: (bool? value) {
                        setState(() {
                          _checkboxValues2[index] = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
            
                  ],
                );
              },
            ),
            TextField(
              controller: _commentControllers[1],
              decoration: const InputDecoration(
                labelText: 'Comments',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'OOSW that needs attention:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 10,
              itemBuilder: (context, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Example of customized checkbox tile
                    CheckboxListTile(
                      title: Text(checkboxQuestions3[index]),
                      value: _checkboxValues3[index],
  
                      onChanged: (bool? value) {
                        setState(() {
                          _checkboxValues3[index] = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
            
                  ],
                );
              },
            ),
            TextField(
              controller: _commentControllers[2],
              decoration: const InputDecoration(
                labelText: 'Comments',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const Divider(),

            const SizedBox(height: 50),
            
          ],
        ),
      ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.fromLTRB(48, 0, 0, 24),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: FloatingActionButton(
            backgroundColor: Colors.black54,
            onPressed: () async {
              // Navigate to TakePictureScreen and pass existing images
              
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TakePictureScreen(
                    existingImages: _capturedPhotos, // Pass existing photos to the screen
                  ),
                ),
              );
          
                if (result != null && result is List<File>) {
                  setState(() {
                    // Update _capturedPhotos with the returned images (new + existing)
                    _capturedPhotos = result;
                  });
                }
                },
                child: const Icon(Icons.camera_alt, color: Colors.white,),
              ),
        ),
      ),
      
    );
  }
}
