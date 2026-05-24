class AppData {
  AppData._();

  static const List<Map<String, String>> serviceTimes = [
    {'day': 'Sunday', 'service': 'Morning Service', 'time': '9:00 AM'},
    {'day': 'Sunday', 'service': 'Evening Service', 'time': '5:00 PM'},
    {'day': 'Wednesday', 'service': 'Mid-Week', 'time': '6:30 PM'},
  ];

  static const List<Map<String, String>> mediaItems = [
    {'title': 'Sunday Sermon', 'type': 'Audio', 'icon': 'music'},
    {'title': 'Bible Study Notes', 'type': 'Document', 'icon': 'doc'},
    {'title': 'Worship Night', 'type': 'Audio', 'icon': 'music'},
    {'title': 'Prayer Guide', 'type': 'Document', 'icon': 'doc'},
  ];

  static const List<String> filterTopics = [
    'All Topics',
    'Government',
    'Education',
    'Media',
    'Religion',
    'Arts & Culture',
  ];

  //  Full media library data

  static const List<Map<String, String>> videos = [
    {
      'title': 'Sunday Service — A Sure Foundation',
      'speaker': 'Pastor James',
      'duration': '58:22',
      'date': 'Mar 10, 2025',
      'category': 'Sunday Service',
      'youtubeId': 'a2AN3sPLoh0',
      'thumb': 'https://img.youtube.com/vi/a2AN3sPLoh0/hqdefault.jpg',
    },
    {
      'title': 'Mid-Week Bible Study — John 17',
      'speaker': 'Pastor James',
      'duration': '44:10',
      'date': 'Mar 5, 2025',
      'category': 'Bible Study',
      'youtubeId': 'a2AN3sPLoh0',
      'thumb': 'https://img.youtube.com/vi/a2AN3sPLoh0/hqdefault.jpg',
    },
    {
      'title': 'Worship Night — Abiding in the Word',
      'speaker': 'Cenacle Worship',
      'duration': '1:12:05',
      'date': 'Feb 28, 2025',
      'category': 'Worship',
      'youtubeId': 'a2AN3sPLoh0',
      'thumb': 'https://img.youtube.com/vi/a2AN3sPLoh0/hqdefault.jpg',
    },
    {
      'title': 'Kingdom Kids — Special Session',
      'speaker': "Children's Ministry",
      'duration': '32:44',
      'date': 'Feb 23, 2025',
      'category': 'Ministries',
      'youtubeId': 'a2AN3sPLoh0',
      'thumb': 'https://img.youtube.com/vi/a2AN3sPLoh0/hqdefault.jpg',
    },
    {
      'title': "The Forge — Men's Conference",
      'speaker': 'Various Speakers',
      'duration': '2:05:18',
      'date': 'Feb 15, 2025',
      'category': 'Conference',
      'youtubeId': 'a2AN3sPLoh0',
      'thumb': 'https://img.youtube.com/vi/a2AN3sPLoh0/hqdefault.jpg',
    },
  ];

  static const List<Map<String, String>> audio = [
    {
      'title': 'Sunday Sermon — Knowing vs Believing',
      'speaker': 'Pastor James',
      'duration': '52:10',
      'date': 'Mar 10, 2025',
      'category': 'Sermon',
      'url':
          'https://vwysqlfwbbdtaxyjshuu.supabase.co/storage/v1/object/public/media-library/audio/1773041223406.mp3',
    },
    {
      'title': 'Worship Night Highlights',
      'speaker': 'Cenacle Worship',
      'duration': '38:44',
      'date': 'Feb 28, 2025',
      'category': 'Worship',
      'url':
          'https://vwysqlfwbbdtaxyjshuu.supabase.co/storage/v1/object/public/media-library/audio/1773041223406.mp3',
    },
    {
      'title': 'Prayer & Intercession Session',
      'speaker': 'Prayer Team',
      'duration': '1:02:30',
      'date': 'Feb 20, 2025',
      'category': 'Prayer',
      'url':
          'https://vwysqlfwbbdtaxyjshuu.supabase.co/storage/v1/object/public/media-library/audio/1773041223406.mp3',
    },
    {
      'title': 'Bible Study — The Epistles',
      'speaker': 'Pastor James',
      'duration': '47:55',
      'date': 'Feb 12, 2025',
      'category': 'Bible Study',
      'url':
          'https://vwysqlfwbbdtaxyjshuu.supabase.co/storage/v1/object/public/media-library/audio/1773041223406.mp3',
    },
    {
      'title': 'YT Nation Praise Session',
      'speaker': 'Youth Ministry',
      'duration': '29:18',
      'date': 'Feb 8, 2025',
      'category': 'Youth',
      'url':
          'https://vwysqlfwbbdtaxyjshuu.supabase.co/storage/v1/object/public/media-library/audio/1773041223406.mp3',
    },
    {
      'title': "Royal Daughters — Women's Fellowship",
      'speaker': "Women's Ministry",
      'duration': '55:00',
      'date': 'Jan 25, 2025',
      'category': 'Ministries',
      'url':
          'https://vwysqlfwbbdtaxyjshuu.supabase.co/storage/v1/object/public/media-library/audio/1773041223406.mp3',
    },
  ];

  static const List<Map<String, String>> books = [
    {
      'title': 'Bible Study Notes — John 17',
      'author': 'Pastor James',
      'pages': '24 pages',
      'date': 'Mar 2025',
      'category': 'Study Notes',
      'description':
          'Detailed notes from the John 17 series covering eternal life, sanctification and unity.',
      'url':
          'https://vwysqlfwbbdtaxyjshuu.supabase.co/storage/v1/object/public/media-library/book/1771328999216.pdf',
    },
    {
      'title': 'Prayer Guide — 21 Days',
      'author': 'Cenacle Link',
      'pages': '36 pages',
      'date': 'Jan 2025',
      'category': 'Prayer',
      'description':
          'A structured 21-day prayer guide for personal and corporate intercession.',
      'url':
          'https://vwysqlfwbbdtaxyjshuu.supabase.co/storage/v1/object/public/media-library/book/1771328999216.pdf',
    },
    {
      'title': 'Discipleship Handbook',
      'author': 'Pastor James',
      'pages': '88 pages',
      'date': 'Dec 2024',
      'category': 'Discipleship',
      'description':
          'A comprehensive handbook for new believers walking through foundational Christian truths.',
      'url':
          'https://vwysqlfwbbdtaxyjshuu.supabase.co/storage/v1/object/public/media-library/book/1771328999216.pdf',
    },
    {
      'title': 'YT Nation — Faith Foundations',
      'author': 'Youth Ministry',
      'pages': '52 pages',
      'date': 'Nov 2024',
      'category': 'Youth',
      'description':
          'Youth-focused study material covering foundational truths of the Christian faith.',
      'url':
          'https://vwysqlfwbbdtaxyjshuu.supabase.co/storage/v1/object/public/media-library/book/1771328999216.pdf',
    },
  ];
}
