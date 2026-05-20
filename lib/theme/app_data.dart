class AppData {
  AppData._();

  // Used by home_screen.dart service times section
  static const List<Map<String, String>> serviceTimes = [
    {'day': 'Sunday', 'service': 'Morning Service', 'time': '9:00 AM'},
    {'day': 'Sunday', 'service': 'Evening Service', 'time': '5:00 PM'},
    {'day': 'Wednesday', 'service': 'Mid-Week', 'time': '6:30 PM'},
  ];

  // Used by home_screen.dart media library section
  static const List<Map<String, String>> mediaItems = [
    {'title': 'Sunday Sermon', 'type': 'Audio', 'icon': 'music'},
    {'title': 'Bible Study Notes', 'type': 'Document', 'icon': 'doc'},
    {'title': 'Worship Night', 'type': 'Audio', 'icon': 'music'},
    {'title': 'Prayer Guide', 'type': 'Document', 'icon': 'doc'},
  ];

  // Used by LetsTalkScreen filter chips
  static const List<String> filterTopics = [
    'All Topics',
    'Government',
    'Education',
    'Media',
    'Religion',
    'Arts & Culture',
  ];
}
