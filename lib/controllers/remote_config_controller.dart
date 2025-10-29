// import 'package:firebase_remote_config/firebase_remote_config.dart';

// class RemoteConfigWidget extends StatefulWidget {
//   @override
//   _RemoteConfigWidgetState createState() => _RemoteConfigWidgetState();
// }

// class _RemoteConfigWidgetState extends State<RemoteConfigWidget> {
//   RemoteConfig _remoteConfig;

//   @override
//   void initState() {
//     super.initState();
//     _remoteConfig = RemoteConfig.instance;
//     _fetchRemoteConfig();
//   }

//   Future<void> _fetchRemoteConfig() async {
//     try {
//       await _remoteConfig.fetch();
//       await _remoteConfig.activateFetched();
//       setState(() {}); // Update the UI with the new values
//     } catch (e) {
//       print('Error fetching remote config: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     // Use the Remote Config values in your UI
//     String welcomeMessage = _remoteConfig.getString('welcome_message');

//     return Text(
//       welcomeMessage,
//       style: TextStyle(fontSize: 20),
//     );
//   }
// }
