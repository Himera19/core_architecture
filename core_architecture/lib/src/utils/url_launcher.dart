import 'package:url_launcher/url_launcher.dart';

class UrlLauncher {
  const UrlLauncher._();
  // Opens given URL safely
  static Future<void> goToUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}
