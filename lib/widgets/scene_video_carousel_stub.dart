import 'package:flutter/widgets.dart';

class SceneVideoCarousel extends StatelessWidget {
  const SceneVideoCarousel({super.key, required this.assets, required this.fallback});

  final List<String> assets;
  final Widget fallback;

  @override
  Widget build(BuildContext context) => fallback;
}
