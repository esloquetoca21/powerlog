import 'package:flutter/material.dart';

/// Slider editable de bienestar (1–10).
class WellnessSlider extends StatelessWidget {
  final IconData icon;
  final String label;
  final String leftLabel;
  final String rightLabel;
  final int value;
  final ValueChanged<int> onChanged;

  const WellnessSlider({
    super.key,
    required this.icon,
    required this.label,
    required this.leftLabel,
    required this.rightLabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFE53935), size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$value',
                    style: const TextStyle(
                        color: Color(0xFFE53935),
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFE53935),
              inactiveTrackColor: Colors.white.withOpacity(0.1),
              thumbColor: const Color(0xFFE53935),
              overlayColor: const Color(0xFFE53935).withOpacity(0.15),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              min: 1,
              max: 10,
              divisions: 9,
              value: value.toDouble(),
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(leftLabel,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35), fontSize: 10)),
                Text(rightLabel,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35), fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fila de solo lectura para mostrar una valoración de bienestar.
class WellnessRatingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String leftLabel;
  final String rightLabel;
  final int value;

  const WellnessRatingRow({
    super.key,
    required this.icon,
    required this.label,
    required this.leftLabel,
    required this.rightLabel,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE53935), size: 15),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(label,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 12)),
                    ),
                    Text('$value/10',
                        style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                LayoutBuilder(builder: (_, constraints) {
                  return Stack(
                    children: [
                      Container(
                        height: 3,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Container(
                        height: 3,
                        width: constraints.maxWidth * value / 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(leftLabel,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.25),
                            fontSize: 9)),
                    Text(rightLabel,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.25),
                            fontSize: 9)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
