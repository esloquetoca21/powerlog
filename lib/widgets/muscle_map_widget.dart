import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Cached raw SVG strings — loaded once, reused across all instances.
  static String? _rawFront;
  static String? _rawBack;

  String? _frontSvg;
  String? _backSvg;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(MuscleMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.primaryMuscle != widget.primaryMuscle ||
        oldWidget.secondaryMuscles != widget.secondaryMuscles) {
      _reload();
    }
  }

  Future<void> _reload() async {
    try {
      _rawFront ??= await rootBundle.loadString(_frontAsset);
      _rawBack ??= await rootBundle.loadString(_backAsset);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    if (!mounted) return;
    _applyColors();
  }

  void _applyColors() {
    String front = _rawFront!;
    String back = _rawBack!;

    for (final muscle in widget.secondaryMuscles) {
      front = _colorMuscle(front, muscle, _secondaryColor);
      back = _colorMuscle(back, muscle, _secondaryColor);
    }
    front = _colorMuscle(front, widget.primaryMuscle, _primaryColor);
    back = _colorMuscle(back, widget.primaryMuscle, _primaryColor);

    setState(() {
      _frontSvg = front;
      _backSvg = back;
      _loading = false;
    });
  }

  /// Finds the element/group with [muscleId] and replaces all fill attributes
  /// inside it with [color].
  String _colorMuscle(String svg, String muscleId, String color) {
    final idAttr = 'id="$muscleId"';
    final idPos = svg.indexOf(idAttr);
    if (idPos == -1) return svg; // muscle not present in this view

    // Walk back to find the opening '<'
    final elemStart = svg.lastIndexOf('<', idPos);
    if (elemStart == -1) return svg;

    final isGroup = svg.startsWith('<g ', elemStart) ||
        svg.startsWith('<g>', elemStart);
    // End of the opening tag
    final tagEnd = svg.indexOf('>', elemStart) + 1;

    if (isGroup) {
      // Color all fill attributes of child elements up to the closing </g>
      final closePos = svg.indexOf('</g>', tagEnd);
      if (closePos == -1) return svg;
      final before = svg.substring(0, tagEnd);
      final inner = svg
          .substring(tagEnd, closePos)
          .replaceAll(RegExp(r'fill="[^"]*"'), 'fill="$color"');
      return before + inner + svg.substring(closePos);
    } else {
      // Single element — replace or insert its fill attribute
      final element = svg.substring(elemStart, tagEnd);
      final colored = element.contains('fill="')
          ? element.replaceAll(RegExp(r'fill="[^"]*"'), 'fill="$color"')
          : element.replaceFirst('>', ' fill="$color">');
      return svg.substring(0, elemStart) + colored + svg.substring(tagEnd);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _frontSvg == null) {
      return Container(
        height: widget.height,
        color: const Color(0xFF1A1A1A),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE53935),
            strokeWidth: 2,
          ),
        ),
      );
    }

    final svgWidth = widget.height * (200 / 460);

    return Container(
      color: const Color(0xFF1A1A1A),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SvgView(
            svgString: _frontSvg!,
            label: 'Anterior',
            width: svgWidth,
            height: widget.height,
          ),
          const SizedBox(width: 8),
          _SvgView(
            svgString: _backSvg!,
            label: 'Posterior',
            width: svgWidth,
            height: widget.height,
          ),
        ],
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
          // Key forces flutter_svg to re-render when string content changes
          key: ValueKey(svgString.hashCode),
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
