import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Share buttons without any social SDK / platform channel.
/// Every button opens a plain URL (https: or mailto:), so nothing can throw
/// MissingPluginException and the user's own signed-in account is used:
///  - WhatsApp  -> wa.me opens the WhatsApp app / WhatsApp Web already logged in
///  - LinkedIn  -> share-offsite opens the app / the logged-in LinkedIn session
///  - Email     -> mailto: opens the device's default mail account; the user can
///                 also pick "Mail this link to my email" (recipient left empty,
///                 the mail app fills in / suggests the user's own address).
class ShareBar extends StatelessWidget {
  /// Short message (kept compact on purpose).
  final String text;

  /// Link to share. Appended to [text] when sharing.
  final String url;

  const ShareBar({super.key, required this.text, this.url = ''});

  String get _compact {
    final t = text.trim();
    final short = t.length > 140 ? '${t.substring(0, 137)}...' : t;
    return url.isEmpty ? short : '$short\n$url';
  }

  Future<void> _open(BuildContext c, Uri uri) async {
    final messenger = ScaffoldMessenger.of(c);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw 'could not open';
    } catch (_) {
      messenger.showSnackBar(const SnackBar(content: Text('Could not open the app on this device.')));
    }
  }

  Future<void> _emailMenu(BuildContext c) async {
    final choice = await showModalBottomSheet<String>(
      context: c,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.forward_to_inbox),
            title: const Text('Mail this link to my email'),
            subtitle: const Text('Uses the default mail account on this device'),
            onTap: () => Navigator.pop(ctx, 'self'),
          ),
          ListTile(
            leading: const Icon(Icons.send),
            title: const Text('Send to someone else'),
            onTap: () => Navigator.pop(ctx, 'other'),
          ),
        ]),
      ),
    );
    if (choice == null || !c.mounted) return;
    final subject = text.split('–').first.trim();
    final uri = Uri(
      scheme: 'mailto',
      // No recipient: the mail app picks the signed-in account, so the user can
      // address it to themselves ("self") or to anyone ("other").
      queryParameters: {'subject': subject.isEmpty ? 'Animation Panoramas' : subject, 'body': _compact},
    );
    await _open(c, uri);
  }

  @override
  Widget build(BuildContext context) {
    final enc = Uri.encodeComponent(_compact);
    return Wrap(spacing: 8, children: [
      IconButton.filledTonal(
        tooltip: 'LinkedIn',
        icon: const Icon(Icons.business_center),
        onPressed: () => _open(
          context,
          Uri.parse('https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(url.isEmpty ? text : url)}'),
        ),
      ),
      IconButton.filledTonal(
        tooltip: 'WhatsApp',
        icon: const Icon(Icons.chat),
        onPressed: () => _open(context, Uri.parse('https://wa.me/?text=$enc')),
      ),
      IconButton.filledTonal(
        tooltip: 'Email',
        icon: const Icon(Icons.mail),
        onPressed: () => _emailMenu(context),
      ),
    ]);
  }
}
