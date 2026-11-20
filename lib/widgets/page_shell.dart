import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:circular_gradient_spinner/circular_gradient_spinner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breadcrumb/flutter_breadcrumb.dart';
import 'package:iconify_flutter_plus/iconify_flutter_plus.dart';
import 'package:iconify_flutter_plus/icons/mdi.dart';
import 'package:intl/intl.dart';
import 'package:qr/qr.dart';
import 'package:sticky_footer_scrollview/sticky_footer_scrollview.dart';
import 'package:time/time.dart';

import '../data/ecosystems.dart';
import '../l10n/app_strings.dart';
import '../models/ecosystem.dart';
import '../pages_registry.dart';
import 'animated_switcher_translation.dart';
import 'smart_snack.dart';

class PageShell extends StatefulWidget {
  final String slug, title;
  final Widget child;
  final List<String> crumbs;

  final List<String?> crumbSlugs;
  final bool busy;
  final Ecosystem? ecosystem;

  final Widget? bottom;
  final Widget? footer;
  const PageShell({
    super.key,
    required this.slug,
    required this.title,
    required this.child,
    this.crumbs = const [],
    this.crumbSlugs = const [],
    this.busy = false,
    this.ecosystem,
    this.bottom,
    this.footer,
  });

  @override
  State<PageShell> createState() => _PageShellState();
}

class _PageShellState extends State<PageShell> {
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(700.milliseconds, () {
      if (mounted) setState(() => _booting = false);
    });
  }

  void _openCrumb(BuildContext context, int i) {
    final root = Navigator.of(context, rootNavigator: true);
    if (i == 0) {
      root.pushNamedAndRemoveUntil('/', (_) => false);
      return;
    }
    final slug = i - 1 < widget.crumbSlugs.length ? widget.crumbSlugs[i - 1] : null;
    if (slug != null) {
      root.pushReplacementNamed(slug == 'main' ? '/' : '/$slug');
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Widget _buildGlobalFooter(BuildContext context) {
    if (widget.footer != null) return widget.footer!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: cs.surfaceContainerLow.withValues(alpha: 0.9),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 104, 12),
        child: Row(
          children: [
            const Iconify(Mdi.panorama_horizontal, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: AutoSizeText(
                context.tr('appTitle'),
                maxLines: 1,
                minFontSize: 11,
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => openPage(context, 'about'),
              child: Text(context.tr('about')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eco = widget.ecosystem ?? getEcosystems().first;
    final loading = _booting || widget.busy;
    final trail = [context.tr('home'), ...widget.crumbs];
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? const BackButton()
            : IconButton(
                tooltip: context.tr('home'),
                icon: const Icon(Icons.home),
                onPressed: () => Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/', (_) => false),
              ),
        title: Row(children: [
          const Iconify(Mdi.panorama_horizontal, size: 22),
          const SizedBox(width: 8),
          Expanded(child: AutoSizeText(widget.title, maxLines: 1, minFontSize: 12)),
        ]),
        actions: [
          // Manual trigger for the SmartSnack messages (they also appear automatically on every page).
          IconButton(
            tooltip: context.tr('Notifications'),
            icon: const Icon(Icons.notifications_none),
            onPressed: SmartSnack.demo,
          ),
          const DayNightSwitch(),
          const AnimatedSwitcherTranslation(),
          Builder(
            builder: (c) => IconButton(
              tooltip: c.tr('menu'),
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(c).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: _AppDrawer(currentSlug: widget.slug),
      bottomNavigationBar: widget.bottom,
      body: Stack(children: [
        Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(children: [
              const DateClock(),
              const SizedBox(width: 12),
              Flexible(
                child: Text(AppStrings.of(context).tf('latLng', {'lat': eco.lat, 'lng': eco.lng}),
                    overflow: TextOverflow.ellipsis, style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: BreadCrumb(
              overflow: ScrollableOverflow(),
              divider: const Icon(Icons.chevron_right, size: 16),
              items: [
                for (int i = 0; i < trail.length; i++)
                  BreadCrumbItem(
                    content: Text(trail[i],
                        style: TextStyle(fontWeight: i == trail.length - 1 ? FontWeight.bold : FontWeight.normal)),
                    onTap: i == trail.length - 1 ? null : () => _openCrumb(context, i),
                  ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return StickyFooterScrollView(
                  itemCount: 1,
                  itemBuilder: (context, _) => ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: widget.child,
                  ),
                  footer: _buildGlobalFooter(context),
                );
              },
            ),
          ),
        ]),
        Positioned(right: 12, bottom: 12, child: QrBox(data: widget.slug == 'main' ? baseUrl : '$baseUrl/${widget.slug}')),
        if (loading)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: Colors.grey.withValues(alpha: 0.8),
                child: const Center(child: CircularGradientSpinner(color: Colors.blue, size: 80, strokeWidth: 8)),
              ),
            ),
          ),
      ]),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final String currentSlug;
  const _AppDrawer({required this.currentSlug});

  static const _groupTitles = {'climate': 'NASA Earth Science'};

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      DrawerHeader(child: Align(alignment: Alignment.bottomLeft, child: Text(context.tr('menu'), style: Theme.of(context).textTheme.headlineSmall))),
    ];
    String? lastGroup;
    for (final p in appPages) {
      // A small heading each time a new named group starts.
      if (p.group != lastGroup && _groupTitles.containsKey(p.group)) {
        children.add(const Divider());
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Text(_groupTitles[p.group]!, style: Theme.of(context).textTheme.labelLarge),
        ));
      } else if (p.group != lastGroup && lastGroup != null) {
        children.add(const Divider());
      }
      lastGroup = p.group;
      children.add(ListTile(
        dense: true,
        selected: p.slug == currentSlug,
        leading: const Iconify(Mdi.chevron_right),
        title: Text(p.title),
        onTap: () {
          Navigator.pop(context);
          if (p.slug != currentSlug) openPage(context, p.slug);
        },
      ));
    }
    return Drawer(child: ListView(children: children));
  }
}

class DateClock extends StatefulWidget {
  const DateClock({super.key});
  @override
  State<DateClock> createState() => _DateClockState();
}

class _DateClockState extends State<DateClock> {
  late final Timer _t;
  DateTime _now = DateTime.now();
  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(1.seconds, (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tag = Localizations.localeOf(context).toLanguageTag();
    return Text(DateFormat.yMMMd(tag).add_Hms().format(_now),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600));
  }
}

class QrBox extends StatelessWidget {
  final String data;
  final double size;
  const QrBox({super.key, required this.data, this.size = 76});

  @override
  Widget build(BuildContext context) {
    QrImage? img;
    try {
      img = QrImage(QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.L));
    } catch (e) {
      debugPrint('QR error: $e');
    }
    if (img == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)]),
      child: CustomPaint(size: Size.square(size), painter: _QrPainter(img)),
    );
  }
}

class _QrPainter extends CustomPainter {
  final QrImage img;
  _QrPainter(this.img);
  @override
  void paint(Canvas canvas, Size size) {
    final n = img.moduleCount;
    final cell = size.width / n;
    final p = Paint()..color = Colors.black;
    for (var x = 0; x < n; x++) {
      for (var y = 0; y < n; y++) {
        if (img.isDark(y, x)) canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.img != img;
}
