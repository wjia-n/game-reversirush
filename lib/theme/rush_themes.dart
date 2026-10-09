import 'package:flutter/material.dart';

/// Reversi Rush visual catalog: board themes (12) + disc styles (9) + a
/// custom creator. Everything stays inside the Mid-Century Speed Club art
/// direction (teak, brass, enamel, cream) — warm physical materials, no neon,
/// no glow, no futuristic chrome.
///
/// The Stitch design system ("Mid-Century Speed Club" v1) is the default
/// theme [RushThemes.teakClassic]; every other theme is a warm-material
/// variation of that same language.
class RushTheme {
  final String id;
  final String name;
  final Color field; // board field base
  final Color fieldAlt; // alternate cell wash
  final Color grid; // brass inlay grid
  final Color hint; // legal-move hint rings
  final Color frame; // board frame
  final Color grain; // wood grain streaks

  const RushTheme({
    required this.id,
    required this.name,
    required this.field,
    required this.fieldAlt,
    required this.grid,
    required this.hint,
    required this.frame,
    required this.grain,
  });

  Map<String, int> toJson() => {
        'field': field.toARGB32(),
        'fieldAlt': fieldAlt.toARGB32(),
        'grid': grid.toARGB32(),
        'hint': hint.toARGB32(),
        'frame': frame.toARGB32(),
        'grain': grain.toARGB32(),
      };

  static RushTheme fromJson(String id, String name, Map<String, int> j) =>
      RushTheme(
        id: id,
        name: name,
        field: Color(j['field'] ?? 0xFF543018),
        fieldAlt: Color(j['fieldAlt'] ?? 0x0DFFFFFF),
        grid: Color(j['grid'] ?? 0xFFC89B3C),
        hint: Color(j['hint'] ?? 0xFFC89B3C),
        frame: Color(j['frame'] ?? 0xFF2A1D12),
        grain: Color(j['grain'] ?? 0x14000000),
      );
}

class RushThemes {
  static const teakClassic = RushTheme(
    id: 'teak',
    name: 'Teak Classic',
    field: Color(0xFF543018),
    fieldAlt: Color(0x0DFFFFFF),
    grid: Color(0xFFC89B3C),
    hint: Color(0xFFC89B3C),
    frame: Color(0xFF2A1D12),
    grain: Color(0x14000000),
  );

  static const List<RushTheme> catalog = [
    teakClassic,
    RushTheme(
      id: 'walnut',
      name: 'Walnut Night',
      field: Color(0xFF3E2415),
      fieldAlt: Color(0x0AFFFFFF),
      grid: Color(0xFFB08A3E),
      hint: Color(0xFFB08A3E),
      frame: Color(0xFF1D1209),
      grain: Color(0x18000000),
    ),
    RushTheme(
      id: 'cherry',
      name: 'Cherry Speedway',
      field: Color(0xFF6B2A1A),
      fieldAlt: Color(0x0DFFFFFF),
      grid: Color(0xFFD9A94E),
      hint: Color(0xFFD9A94E),
      frame: Color(0xFF33150C),
      grain: Color(0x14000000),
    ),
    RushTheme(
      id: 'mahogany',
      name: 'Mahogany Club',
      field: Color(0xFF4A1F14),
      fieldAlt: Color(0x0CFFFFFF),
      grid: Color(0xFFC89B3C),
      hint: Color(0xFFE0B75A),
      frame: Color(0xFF241009),
      grain: Color(0x16000000),
    ),
    RushTheme(
      id: 'honeyoak',
      name: 'Honey Oak',
      field: Color(0xFF8A5A28),
      fieldAlt: Color(0x12000000),
      grid: Color(0xFF6E4426),
      hint: Color(0xFF543018),
      frame: Color(0xFF4A2E12),
      grain: Color(0x1A4A2E12),
    ),
    RushTheme(
      id: 'smokedash',
      name: 'Smoked Ash',
      field: Color(0xFF4E463C),
      fieldAlt: Color(0x0CFFFFFF),
      grid: Color(0xFFC9B48A),
      hint: Color(0xFFC9B48A),
      frame: Color(0xFF262019),
      grain: Color(0x14000000),
    ),
    RushTheme(
      id: 'espresso',
      name: 'Espresso Pit',
      field: Color(0xFF33221A),
      fieldAlt: Color(0x0AFFFFFF),
      grid: Color(0xFF9A7326),
      hint: Color(0xFFDFB75A),
      frame: Color(0xFF17100B),
      grain: Color(0x18000000),
    ),
    RushTheme(
      id: 'butterscotch',
      name: 'Butterscotch',
      field: Color(0xFF9A6A30),
      fieldAlt: Color(0x14000000),
      grid: Color(0xFF543018),
      hint: Color(0xFF3B2110),
      frame: Color(0xFF5E3A16),
      grain: Color(0x1A5E3A16),
    ),
    RushTheme(
      id: 'ivory',
      name: 'Ivory Archive',
      field: Color(0xFFEFE9D9),
      fieldAlt: Color(0x14000000),
      grid: Color(0xFF9A7326),
      hint: Color(0xFF9A7326),
      frame: Color(0xFF3B2110),
      grain: Color(0x12000000),
    ),
    RushTheme(
      id: 'slate',
      name: 'Slate & Brass',
      field: Color(0xFF3A3F45),
      fieldAlt: Color(0x0CFFFFFF),
      grid: Color(0xFFD9A94E),
      hint: Color(0xFFD9A94E),
      frame: Color(0xFF1C1F23),
      grain: Color(0x14000000),
    ),
    RushTheme(
      id: 'forest',
      name: 'Forest Rally',
      field: Color(0xFF2E4034),
      fieldAlt: Color(0x0CFFFFFF),
      grid: Color(0xFFC9B48A),
      hint: Color(0xFFC9B48A),
      frame: Color(0xFF16211A),
      grain: Color(0x14000000),
    ),
    RushTheme(
      id: 'crimson',
      name: 'Crimson Pit',
      field: Color(0xFF5E2318),
      fieldAlt: Color(0x0DFFFFFF),
      grid: Color(0xFFE0B75A),
      hint: Color(0xFFE0B75A),
      frame: Color(0xFF2A1009),
      grain: Color(0x16000000),
    ),
  ];

  static RushTheme byId(String id, {RushTheme? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in catalog) {
      if (t.id == id) return t;
    }
    return teakClassic;
  }
}

/// A disc style: face/edge/specular colors for both sides + rim color.
/// All 9 stay inside the club material language (enamel, wood, leather,
/// metal) — never neon, never glow.
class DiscStyle {
  final String id;
  final String name;
  final Color blackFace;
  final Color blackEdge;
  final Color blackSpec;
  final Color whiteFace;
  final Color whiteEdge;
  final Color whiteSpec;
  final Color rim;

  const DiscStyle({
    required this.id,
    required this.name,
    required this.blackFace,
    required this.blackEdge,
    required this.blackSpec,
    required this.whiteFace,
    required this.whiteEdge,
    required this.whiteSpec,
    required this.rim,
  });

  Map<String, int> toJson() => {
        'blackFace': blackFace.toARGB32(),
        'whiteFace': whiteFace.toARGB32(),
      };

  static DiscStyle customFrom(Map<String, int> j) {
    final bf = Color(j['blackFace'] ?? 0xFF1E1E1E);
    final wf = Color(j['whiteFace'] ?? 0xFFFAFAF7);
    return DiscStyle(
      id: 'custom',
      name: 'Custom Pour',
      blackFace: bf,
      blackEdge: bf.withValues(alpha: 1),
      blackSpec: const Color(0xFFFFFFFF),
      whiteFace: wf,
      whiteEdge: wf,
      whiteSpec: const Color(0xFFFFF6E0),
      rim: const Color(0xFFC89B3C),
    );
  }
}

class DiscStyles {
  static const enamel = DiscStyle(
    id: 'enamel',
    name: 'Hand-Poured Enamel',
    blackFace: Color(0xFF1E1E1E),
    blackEdge: Color(0xFF0C0C0C),
    blackSpec: Color(0xFFFFFFFF),
    whiteFace: Color(0xFFFAFAF7),
    whiteEdge: Color(0xFFE4DCC8),
    whiteSpec: Color(0xFFFFF6E0),
    rim: Color(0xFFC89B3C),
  );

  static const List<DiscStyle> catalog = [
    enamel,
    DiscStyle(
      id: 'tortoise',
      name: 'Tortoise & Bone',
      blackFace: Color(0xFF2E1F12),
      blackEdge: Color(0xFF180F08),
      blackSpec: Color(0xFFFFE9C4),
      whiteFace: Color(0xFFF3E7CE),
      whiteEdge: Color(0xFFD9C9A6),
      whiteSpec: Color(0xFFFFFFFF),
      rim: Color(0xFF9A7326),
    ),
    DiscStyle(
      id: 'walnutmaple',
      name: 'Walnut & Maple',
      blackFace: Color(0xFF4A2E16),
      blackEdge: Color(0xFF2A1A0C),
      blackSpec: Color(0xFFFFE9C4),
      whiteFace: Color(0xFFE8D3A8),
      whiteEdge: Color(0xFFC9A96F),
      whiteSpec: Color(0xFFFFFFFF),
      rim: Color(0xFF6E4426),
    ),
    DiscStyle(
      id: 'brasscoin',
      name: 'Brass Coin',
      blackFace: Color(0xFF3A332A),
      blackEdge: Color(0xFF211D16),
      blackSpec: Color(0xFFFFF0C8),
      whiteFace: Color(0xFFE3C878),
      whiteEdge: Color(0xFFB08A3E),
      whiteSpec: Color(0xFFFFFFFF),
      rim: Color(0xFFDFB75A),
    ),
    DiscStyle(
      id: 'leather',
      name: 'Leather & Suede',
      blackFace: Color(0xFF33241A),
      blackEdge: Color(0xFF1D130C),
      blackSpec: Color(0xFFFFE4B8),
      whiteFace: Color(0xFFD9C4A0),
      whiteEdge: Color(0xFFB89B72),
      whiteSpec: Color(0xFFFFFFFF),
      rim: Color(0xFF543018),
    ),
    DiscStyle(
      id: 'marble',
      name: 'Marble & Slate',
      blackFace: Color(0xFF2A2D33),
      blackEdge: Color(0xFF14161A),
      blackSpec: Color(0xFFFFFFFF),
      whiteFace: Color(0xFFECE9E2),
      whiteEdge: Color(0xFFC9C4B8),
      whiteSpec: Color(0xFFFFFFFF),
      rim: Color(0xFF8A8F96),
    ),
    DiscStyle(
      id: 'rallycheck',
      name: 'Rally Check',
      blackFace: Color(0xFF1E1E1E),
      blackEdge: Color(0xFF0C0C0C),
      blackSpec: Color(0xFFFFFFFF),
      whiteFace: Color(0xFFFAFAF7),
      whiteEdge: Color(0xFFB93829),
      whiteSpec: Color(0xFFFFF6E0),
      rim: Color(0xFFB93829),
    ),
    DiscStyle(
      id: 'piano',
      name: 'Piano Lacquer',
      blackFace: Color(0xFF101010),
      blackEdge: Color(0xFF000000),
      blackSpec: Color(0xFFFFFFFF),
      whiteFace: Color(0xFFFFFFFF),
      whiteEdge: Color(0xFFE8E4DA),
      whiteSpec: Color(0xFFFFF6E0),
      rim: Color(0xFFDFB75A),
    ),
    DiscStyle(
      id: 'copper',
      name: 'Copper & Cream',
      blackFace: Color(0xFF5E3A22),
      blackEdge: Color(0xFF3A2110),
      blackSpec: Color(0xFFFFD9A8),
      whiteFace: Color(0xFFF7F0DC),
      whiteEdge: Color(0xFFD9C9A6),
      whiteSpec: Color(0xFFFFFFFF),
      rim: Color(0xFFB0703A),
    ),
  ];

  static DiscStyle byId(String id, {Map<String, int>? customJson}) {
    if (id == 'custom' && customJson != null) {
      return DiscStyle.customFrom(customJson);
    }
    for (final d in catalog) {
      if (d.id == id) return d;
    }
    return enamel;
  }
}
