import 'package:flutter/material.dart';

class SiteCloseoutForm extends StatefulWidget {
  @override
  _SiteCloseoutFormState createState() => _SiteCloseoutFormState();
}

class _SiteCloseoutFormState extends State<SiteCloseoutForm> {
  // Define controllers for text fields if needed
  final List<TextEditingController> _commentControllers = List.generate(3, (index) => TextEditingController());
  final List<bool> _checkboxValues = List.generate(3, (index) => false);

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    for (var controller in _commentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Site Closeout Form'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: List.generate(3, (index) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Question ${index + 1}:'),
                CheckboxListTile(
                  title: Text('Check this box'),
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
                SizedBox(height: 20),
              ],
            );
          }),
        ),
      ),
    );
  }
}
