import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MuscleMapWidget extends StatefulWidget {
  final String primaryMuscle;
  final List<String> secondaryMuscles;
  final double height;

  const MuscleMapWidget({
    super.key,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    this.height = 200,
  });

  @override
  State<MuscleMapWidget> createState() => _MuscleMapWidgetState();
}

class _MuscleMapWidgetState extends State<MuscleMapWidget> {
  static const String _frontAsset = 'assets/images/muscle_map_front.svg';
  static const String _backAsset = 'assets/images/muscle_map_back.svg';

  static const String _primaryColor = '#E74C3C';
  static const String _secondaryColor = '#E67E22';

  Future<(String, String)>? _svgFuture;

  @override
  void initState() {
    super.initState();
    _svgFuture = _loadAndColorSvgs();
  }

  @override
  void didUpdateWidget(MuscleMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryMuscle != widget.primaryMuscle ||
        oldWidget.secondaryMuscles != widget.secondaryMuscles) {
      _svgFuture = _loadAndColorSvgs();
    }
  }

  Future<(String, String)> _loadAndColorSvgs() async {
    final bundle = DefaultAssetBundle.of(context);
    final frontRaw = await bundle.loadString(_frontAsset);
    final backRaw = await bundle.loadString(_backAsset);

    String front = frontRaw;
    String back = backRaw;

    // Apply secondary muscles first (lower priority, painted underneath primary)
    for (final muscle in widget.secondaryMuscles) {
      front = _colorMuscle(front, muscle, _secondaryColor);
      back = _colorMuscle(back, muscle, _secondaryColor);
    }

    // Apply primary muscle last (highest priority)
    front = _colorMuscle(front, widget.primaryMuscle, _primaryColor);
    back = _colorMuscle(back, widget.primaryMuscle, _primaryColor);

    return (front, back);
  }

  /// Replaces the fill color of a muscle element identified by [muscleId].
  ///
  /// Handles two orderings of attributes:
  ///   <path id="muscleId" fill="...">
  ///   <path fill="..." id="muscleId">
  /// Also handles <g id="muscleId"> by injecting a fill attribute.
  String _colorMuscle(String svg, String muscleId, String color) {
    // Case 1: id comes before fill  →  id="X" ... fill="old"
    svg = svg.replaceAllMapped(
      RegExp('(id="$muscleId"[^>]*?)fill="[^"]*"'),
      (m) => '${m.group(1)}fill="$color"',
    );

    // Case 2: fill comes before id  →  fill="old" ... id="X"
    svg = svg.replaceAllMapped(
      RegExp('fill="[^"]*"([^>]*?id="$muscleId")'),
      (m) => 'fill="$color"${m.group(1)}',
    );

    // Case 3: element with id but no fill attribute (e.g. <g id="X">)
    // Insert fill after the id attribute.
    svg = svg.replaceAllMapped(
      RegExp('(id="$muscleId")(?![^>]*fill=)'),
      (m) => '${m.group(1)} fill="$color"',
    );

    return svg;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
      ),
      child: FutureBuilder<(String, String)>(
        future: _svgFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return SizedBox(
              height: widget.height,
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFE53935),
                  strokeWidth: 2,
                ),
              ),
            );
          }

          if (snapshot.hasError) {
            return SizedBox(
              height: widget.height,
              child: const Center(
                child: Icon(Icons.error_outline, color: Colors.white38, size: 32),
              ),
            );
          }

          final (frontSvg, backSvg) = snapshot.data!;
          final svgWidth = widget.height * (200 / 460);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SvgView(
                svgString: frontSvg,
                label: 'Anterior',
                width: svgWidth,
                height: widget.height,
              ),
              const SizedBox(width: 8),
              _SvgView(
                svgString: backSvg,
                label: 'Posterior',
                width: svgWidth,
                height: widget.height,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SvgView extends StatelessWidget {
  final String svgString;
  final String label;
  final double width;
  final double height;

  const _SvgView({
    required this.svgString,
    required this.label,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.string(
          svgString,
          width: width,
          height: height,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
