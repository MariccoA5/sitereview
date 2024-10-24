import 'package:flutter/cupertino.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Profile'),
      ),
      child: Center(
        child: Text('Profile page coming soon'),
      ),
    );
  }
}
