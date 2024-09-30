import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:site_connect/providers.dart';
import 'package:site_connect/take_picture.dart';
import 'package:supabase/supabase.dart';

class SiteCloseoutForm extends StatefulWidget {
  const SiteCloseoutForm({super.key});

  @override
  _SiteCloseoutFormState createState() => _SiteCloseoutFormState();
}

class _SiteCloseoutFormState extends State<SiteCloseoutForm> {
  // Define controllers for text fields
  final TextEditingController _contractorController = TextEditingController();
  final TextEditingController _techInitialsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // Define controllers and checkboxes for the 3 main sections
  final List<TextEditingController> _commentControllers = List.generate(3, (index) => TextEditingController());
  final List<bool> _checkboxValues = List.generate(3, (index) => false);

  // Image management (You mentioned the photos are handled separately)
  String _photoUrl = ''; // Replace with actual photo URL logic

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _contractorController.dispose();
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
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    final providers = Provider.of<Providers>(context, listen: false);
    final SupabaseClient = providers.supabaseClient;
    final contractor = _contractorController.text;
    final techInitials = _techInitialsController.text;
    final date = _selectedDate.toIso8601String();

    // Map the comment and checkbox values
    final mainCheckbox = _checkboxValues[0];
    final mainComments = _commentControllers[0].text;

    final iaiCheckbox = _checkboxValues[1];
    final iaiComments = _commentControllers[1].text;

    final ooswCheckbox = _checkboxValues[2];
    final ooswComments = _commentControllers[2].text;

    // Insert data into Supabase
    final response = await SupabaseClient
        .from('site_closeout')
        .insert({
          'contractor': contractor,
          'techs_initals': techInitials,
          'created_at': date,
          'main_checkbox': mainCheckbox,
          'main_commen': mainComments,
          'iai_checkbox': iaiCheckbox,
          'iai_comments': iaiComments,
          'oosw_checkbc': ooswCheckbox,
          'oosw_commer': ooswComments,
          'photos': _photoUrl, // Assuming you store the URL of the uploaded photo
        });
  
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Site Closeout Form'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contractor field
            TextField(
              controller: _contractorController,
              decoration: InputDecoration(
                labelText: 'Contractor',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Tech Initials field
            TextField(
              controller: _techInitialsController,
              decoration: InputDecoration(
                labelText: 'Tech Initials',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Date Picker
            Text("Date: ${_selectedDate.toLocal()}"),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: const Text('Select Date'),
            ),
            const SizedBox(height: 20),

            // Questions with Checkboxes and Comments
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Question ${index + 1}:'),
                    CheckboxListTile(
                      title: const Text('Check this box'),
                      value: _checkboxValues[index],
                      onChanged: (bool? value) {
                        setState(() {
                          _checkboxValues[index] = value ?? false;
                        });
                      },
                    ),
                    TextField(
                      controller: _commentControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Comments',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),

            // Submit button
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Submit Form'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the photo upload screen
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TakePictureScreen()));
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
