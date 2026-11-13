import 'package:flutter/material.dart';
import 'package:flutter_social_share_plugin/flutter_social_share_plugin.dart';
import 'package:social_sharing_plus/social_sharing_plus.dart';

class ShareBar extends StatelessWidget {
  final String text;
  const ShareBar({super.key, required this.text});

  void _snack(BuildContext c, Object e) =>
      ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('Share failed: $e')));

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, children: [
      IconButton.filledTonal(
        tooltip: 'LinkedIn',
        icon: const Icon(Icons.business_center),
        onPressed: () async {
          try {
            await SocialSharingPlus.shareToSocialMedia(SocialPlatform.linkedin, text, isOpenBrowser: true);
          } catch (e) {
            _snack(context, e);
          }
        },
      ),
      IconButton.filledTonal(
        tooltip: 'WhatsApp',
        icon: const Icon(Icons.chat),
        onPressed: () async {
          try {
            await FlutterSocialSharePlugin.shareToWhatsApp(msg: text); 
          } catch (e) {
            _snack(context, e);
          }
        },
      ),
      IconButton.filledTonal(
        tooltip: 'Mail',
        icon: const Icon(Icons.mail),
        onPressed: () async {
          try {
            await FlutterSocialSharePlugin.shareToMail(mailBody: text, mailSubject: 'Ecosystem Viewer');
          } catch (e) {
            _snack(context, e);
          }
        },
      ),
    ]);
  }
}
