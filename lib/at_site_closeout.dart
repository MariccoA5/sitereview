import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
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
  final TextEditingController _visitedDaysController = TextEditingController();
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
    _visitedDaysController.dispose();
    _siteNameController.dispose();
    _contractorController.dispose();
    _siteNumberController.dispose();
    _techInitialsController.dispose();
    for (var controller in _commentControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 216,
          padding: const EdgeInsets.only(top: 6.0),
          color: CupertinoColors.white,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: _selectedDate,
            onDateTimeChanged: (DateTime newDateTime) {
              setState(() {
                _selectedDate = newDateTime;
              });
            },
          ),
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String formatDate(DateTime date) {
  final DateFormat formatter = DateFormat('yyyy-MM-dd'); // Specify the format you want
  return formatter.format(date).toString();
}

  Map<String, dynamic> _submitForm() {
    return {
      'contractor': _contractorController.text,
      'visitedDays': _visitedDaysController.text,
      'techInitials': _techInitialsController.text,
      'mainCheckbox': _checkboxValues,
      'mainComments': _commentControllers[0].text,
      'iaiCheckbox': _checkboxValues2,
      'iaiComments': _commentControllers[1].text,
      'ooswCheckbox': _checkboxValues3,
      'ooswComments': _commentControllers[2].text,
      'siteName': _siteNameController.text,
      'selectedDate': formatDate(_selectedDate),
      'photos': _capturedPhotos,
      'siteNumber': _siteNumberController.text,
    };
  }

  @override
Widget build(BuildContext context) {
  return GestureDetector(
    onTap: () {
      FocusScope.of(context).unfocus(); // This dismisses the keyboard
    },
    child: CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Site Closeout Form'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.delete),
          onPressed: () {
            setState(() {
              _contractorController.clear();
              _techInitialsController.clear();
              _siteNumberController.clear();
              _siteNameController.clear();
              _visitedDaysController.clear();
              for (var controller in _commentControllers) {
                controller.clear();
              }
              _capturedPhotos.clear();
              _selectedDate = DateTime.now();
              _checkboxValues.fillRange(0, 8, false);
              _checkboxValues2.fillRange(0, 8, false);
              _checkboxValues3.fillRange(0, 10, false);
            });
          },
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.share),
          onPressed: () {
            if (_capturedPhotos.isEmpty) {
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: const Text('No Photos'),
                  content: const Text('Photos are required to complete the form.'),
                  actions: [
                    CupertinoDialogAction(
                      child: const Text('OK'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
              return;
            }
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => PdfGeneratorPage(
                  submitForm: _submitForm(),
                ),
              ),
            );
          },
        ),
      ),
      child: PageView(
        children: [
          _buildSiteInfoSection(),
          _buildMainSOWSection(),
          _buildImmediateAttentionSection(),
          _buildOOSWSection(),
        ],
      ),
    ),
  );
}


  // Site Information Section
Widget _buildSiteInfoSection() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded( // Wrap the scrollable content in Expanded
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Image.asset(
                    'assets/GRC.png',
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Site Information',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                CupertinoTextField(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
                  controller: _siteNameController,
                  placeholder: 'Site Name',
                ),
                const SizedBox(height: 20),
                CupertinoTextField(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
                  controller: _siteNumberController,
                  placeholder: 'Site Number',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 20),
                CupertinoTextField(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
                  controller: _contractorController,
                  placeholder: 'Contractor',
                ),
                const SizedBox(height: 20),
                CupertinoTextField(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
                  controller: _techInitialsController,
                  placeholder: 'Tech\'s Initials',
                ),
                const SizedBox(height: 20),
                CupertinoTextField(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 12.0),
                  controller: _visitedDaysController,
                  placeholder: 'Visited #',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text("Date: ${_selectedDate.toLocal().toString().split(' ')[0]}"),
                    const SizedBox(width: 10),
                    CupertinoButton(
                      child: const Icon(CupertinoIcons.calendar),
                      onPressed: () => _selectDate(context),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Number of photos taken: ${_capturedPhotos.length}',
                    ),
                    const SizedBox(width: 10),
                    CupertinoButton(
                      child: const Icon(CupertinoIcons.photo_camera),
                      onPressed: () async {
                        final result = await Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => TakePictureScreen(
                              existingImages: _capturedPhotos,
                            ),
                          ),
                        );

                        if (result != null && result is List<File>) {
                          setState(() {
                            _capturedPhotos = result;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildSwipeHint(0, 4), // Swipe hint at the bottom
      ],
    ),
  );
}


  Widget _buildMainSOWSection() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded( // Make the scrollable content take up available space
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Main SOW:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                ...List.generate(checkboxQuestions.length, (index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              checkboxQuestions[index],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          CupertinoSwitch(
                            value: _checkboxValues[index],
                            onChanged: (bool value) {
                              setState(() {
                                _checkboxValues[index] = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 1,
                        color: CupertinoColors.separator,
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                }),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: _commentControllers[0],
                  placeholder: 'Comments',
                  maxLines: 4,
                  keyboardType: TextInputType.text,
                ),
              ],
            ),
          ),
        ),
        _buildSwipeHint(1, 4), // The swipe hint is at the bottom
      ],
    ),
  );
}


  Widget _buildImmediateAttentionSection() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded( // This makes the content scrollable and take available height
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Immediate Attention Issues:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                ...List.generate(checkboxQuestions2.length, (index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              checkboxQuestions2[index],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          CupertinoSwitch(
                            value: _checkboxValues2[index],
                            onChanged: (bool value) {
                              setState(() {
                                _checkboxValues2[index] = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 1,
                        color: CupertinoColors.separator,
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                }),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: _commentControllers[1],
                  placeholder: 'Comments',
                  maxLines: 4,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        // Swipe hint stays at the bottom
        _buildSwipeHint(2, 4),
      ],
    ),
  );
}



  Widget _buildOOSWSection() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded( // Scrollable content wrapped inside Expanded
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'OOSW that needs attention:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                ...List.generate(checkboxQuestions3.length, (index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              checkboxQuestions3[index],
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          CupertinoSwitch(
                            value: _checkboxValues3[index],
                            onChanged: (bool value) {
                              setState(() {
                                _checkboxValues3[index] = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        height: 1,
                        color: CupertinoColors.separator,
                      ),
                      const SizedBox(height: 10),
                    ],
                  );
                }),
                const SizedBox(height: 10),
                CupertinoTextField(
                  controller: _commentControllers[2],
                  placeholder: 'Comments',
                  maxLines: 4,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        _buildSwipeHint(3, 4), // Swipe hint fixed at the bottom
      ],
    ),
  );
}



Widget _buildSwipeHint(int currentPage, int totalPages) {
  // Start page: swipe left
  if (currentPage == 0) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Swipe to continue',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.inactiveGray,
            ),
          ),
          SizedBox(width: 8),
          Icon(
            CupertinoIcons.chevron_right,
            color: CupertinoColors.inactiveGray,
          ),
        ],
      ),
    );
  }
  // End page: swipe right
  else if (currentPage == totalPages - 1) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chevron_left,
            color: CupertinoColors.inactiveGray,
          ),
          SizedBox(width: 8),
          Text(
            'Swipe to go back',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.inactiveGray,
            ),
          ),
        ],
      ),
    );
  }
  // Middle pages: Swipe to continue
  else {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chevron_left,
            color: CupertinoColors.inactiveGray,
          ),
          SizedBox(width: 8),
          Text(
            'Swipe to continue',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.inactiveGray,
            ),
          ),
          SizedBox(width: 8),
          Icon(
            CupertinoIcons.chevron_right,
            color: CupertinoColors.inactiveGray,
          ),
        ],
      ),
    );
  }
}
}
