import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class SmartSnack {
  SmartSnack._();

  static final _controller = _SmartSnackController();

  static SmartSnackHandle warning(String message, {Duration? duration}) =>
      _controller._show(SmartSnackKind.warning, message, duration ?? const Duration(seconds: 6));

  static SmartSnackHandle info(String message, {Duration? duration}) =>
      _controller._show(SmartSnackKind.info, message, duration ?? const Duration(seconds: 4));

  static SmartSnackHandle loading(String message, {Duration? duration}) =>
      _controller._show(SmartSnackKind.loading, message, duration ?? const Duration(seconds: 10));

  static void clear() => _controller._clear();

  static void demo() {
    warning('Checking internet');
    Timer(const Duration(milliseconds: 600), () => info('New update available'));
    Timer(const Duration(milliseconds: 1200), () => loading('Processing data'));
  }
}

enum SmartSnackKind { warning, info, loading }

class SmartSnackHandle {
  SmartSnackHandle._(this._entry, this._controller);
  final _SnackEntry _entry;
  final _SmartSnackController _controller;

  bool get isOpen => !_entry.closing && _controller._entries.contains(_entry);

  void close() => _controller._requestClose(_entry);
}

class SmartSnackColors {
  SmartSnackColors._();
  static const warning = Color(0xFF7A5A4A); // brownish
  static const info = Color(0xFF43698C); // blueish
  static const loading = Color(0xFF5B6670); // greyish

  static Color of(SmartSnackKind k) => switch (k) {
        SmartSnackKind.warning => warning,
        SmartSnackKind.info => info,
        SmartSnackKind.loading => loading,
      };
}

class _SnackEntry {
  _SnackEntry(this.id, this.kind, this.message, this.duration);
  final int id;
  final SmartSnackKind kind;
  final String message;

  final Duration duration;

  bool closing = false;
}

class _SmartSnackController extends ChangeNotifier {
  static const _maxVisible = 3;

  final List<_SnackEntry> _entries = [];
  int _nextId = 0;

  SmartSnackHandle _show(SmartSnackKind kind, String message, Duration duration) {
    final entry = _SnackEntry(_nextId++, kind, message, duration);
    _entries.add(entry);
    // Keep the stack short: retire the oldest ones first.
    final open = _entries.where((e) => !e.closing).toList();
    for (var i = 0; i < open.length - _maxVisible; i++) {
      open[i].closing = true;
    }
    _emit();
    return SmartSnackHandle._(entry, this);
  }

  void _requestClose(_SnackEntry entry) {
    if (entry.closing || !_entries.contains(entry)) return;
    // No host mounted (nobody could animate it out): drop it right away.
    if (!hasListeners) {
      _entries.remove(entry);
      return;
    }
    entry.closing = true;
    _emit();
  }

  void _remove(_SnackEntry entry) {
    if (_entries.remove(entry)) _emit();
  }

  void _clear() {
    for (final e in _entries) {
      e.closing = true;
    }
    if (!hasListeners) _entries.clear();
    _emit();
  }

  void _emit() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
    } else {
      notifyListeners();
    }
  }
}

class SmartSnackHost extends StatelessWidget {
  const SmartSnackHost({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Positioned.fill(child: child),
      Positioned.fill(
        child: AnimatedBuilder(
          animation: SmartSnack._controller,
          builder: (context, _) {
            final entries = List<_SnackEntry>.of(SmartSnack._controller._entries);
            if (entries.isEmpty) return const SizedBox.shrink();
            final wide = MediaQuery.of(context).size.width >= 720;
            return SafeArea(
              child: Align(
                // Wide: bottom-left (the QR box lives bottom-right).
                // Narrow: centred, lifted above the QR box like page content is.
                alignment: wide ? Alignment.bottomLeft : Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, wide ? 16 : 100),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final e in entries)
                          _SnackItem(key: ValueKey(e.id), entry: e, controller: SmartSnack._controller),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ]);
  }
}

class _SnackItem extends StatefulWidget {
  const _SnackItem({super.key, required this.entry, required this.controller});
  final _SnackEntry entry;
  final _SmartSnackController controller;

  @override
  State<_SnackItem> createState() => _SnackItemState();
}

class _SnackItemState extends State<_SnackItem> with SingleTickerProviderStateMixin {
  late final AnimationController _ac = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _curve = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic, reverseCurve: Curves.easeIn);
  Timer? _timer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _ac.forward();
    _startTimer();
    if (widget.entry.closing) _leave();
  }

  @override
  void didUpdateWidget(covariant _SnackItem old) {
    super.didUpdateWidget(old);
    if (widget.entry.closing) _leave();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ac.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    final d = widget.entry.duration;
    if (d == Duration.zero || _leaving) return;
    _timer = Timer(d, () => widget.controller._requestClose(widget.entry));
  }

  void _pauseTimer() => _timer?.cancel();

  /// Slide out, then drop the entry.
  void _leave() {
    if (_leaving) return;
    _leaving = true;
    _timer?.cancel();
    _ac.reverse().then((_) => widget.controller._remove(widget.entry));
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    return SizeTransition(
      sizeFactor: _curve,
      axisAlignment: -1,
      child: FadeTransition(
        opacity: _curve,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(_curve),
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: MouseRegion(
              onEnter: (_) => _pauseTimer(),
              onExit: (_) => _startTimer(),
              child: Listener(
                onPointerDown: (_) => _pauseTimer(),
                onPointerUp: (_) => _startTimer(),
                onPointerCancel: (_) => _startTimer(),
                child: Dismissible(
                  key: ValueKey('dismiss-${e.id}'),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) {
                    _timer?.cancel();
                    widget.controller._remove(e);
                  },
                  child: _SnackCard(entry: e, onClose: () => widget.controller._requestClose(e)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SnackCard extends StatelessWidget {
  const _SnackCard({required this.entry, required this.onClose});
  final _SnackEntry entry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    const fg = Colors.white;
    final Widget leading = switch (entry.kind) {
      SmartSnackKind.warning => const Icon(Icons.warning_amber_rounded, color: fg, size: 22),
      SmartSnackKind.info => const Icon(Icons.info_outline_rounded, color: fg, size: 22),
      SmartSnackKind.loading => const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
        ),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: SmartSnackColors.of(entry.kind),
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 4, 4),
          child: Row(children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w500, height: 1.25),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close, size: 18, color: Colors.white70),
              visualDensity: VisualDensity.compact,
              onPressed: onClose,
            ),
          ]),
        ),
      ),
    );
  }
}

void smartSnackDebugDemo() {
  if (!kDebugMode) return;
  WidgetsBinding.instance.addPostFrameCallback((_) => SmartSnack.demo());
}
