import 'package:flutter/widgets.dart';

class CampaignWorld {
  const CampaignWorld({
    required this.worldIndex,
    required this.name,
    required this.stageStart,
    required this.stageEnd,
    required this.backgroundAsset,
    required this.nodePositions,
  });

  final int worldIndex;
  final String name;
  final int stageStart;
  final int stageEnd;
  final String backgroundAsset;
  final List<Offset> nodePositions;

  bool containsStageOrder(int order) {
    return order >= stageStart && order <= stageEnd;
  }
}

int campaignWorldIndexForStageOrder(int order) {
  return ((order - 1) ~/ 10).clamp(0, campaignWorlds.length - 1);
}

CampaignWorld campaignWorldForStageOrder(int order) {
  return campaignWorlds[campaignWorldIndexForStageOrder(order)];
}

const campaignWorlds = <CampaignWorld>[
  CampaignWorld(
    worldIndex: 0,
    name: 'غابة البداية',
    stageStart: 1,
    stageEnd: 10,
    backgroundAsset: 'assets/images/campaign/worlds/world_01_forest.webp',
    nodePositions: <Offset>[
      Offset(0.53, 0.89),
      Offset(0.64, 0.78),
      Offset(0.76, 0.67),
      Offset(0.67, 0.59),
      Offset(0.56, 0.59),
      Offset(0.44, 0.57),
      Offset(0.33, 0.49),
      Offset(0.41, 0.38),
      Offset(0.54, 0.31),
      Offset(0.37, 0.19),
    ],
  ),
  CampaignWorld(
    worldIndex: 1,
    name: 'تلال المعرفة',
    stageStart: 11,
    stageEnd: 20,
    backgroundAsset: 'assets/images/campaign/worlds/world_02_hills.webp',
    nodePositions: <Offset>[
      Offset(0.25, 0.88),
      Offset(0.42, 0.93),
      Offset(0.58, 0.88),
      Offset(0.56, 0.72),
      Offset(0.64, 0.55),
      Offset(0.73, 0.47),
      Offset(0.65, 0.33),
      Offset(0.41, 0.60),
      Offset(0.33, 0.47),
      Offset(0.30, 0.30),
    ],
  ),
  CampaignWorld(
    worldIndex: 2,
    name: 'طريق المليون',
    stageStart: 21,
    stageEnd: 30,
    backgroundAsset: 'assets/images/campaign/worlds/world_03_million_path.webp',
    nodePositions: <Offset>[
      Offset(0.24, 0.88),
      Offset(0.31, 0.78),
      Offset(0.39, 0.71),
      Offset(0.47, 0.63),
      Offset(0.54, 0.58),
      Offset(0.60, 0.52),
      Offset(0.59, 0.43),
      Offset(0.66, 0.37),
      Offset(0.69, 0.28),
      Offset(0.78, 0.22),
    ],
  ),
  CampaignWorld(
    worldIndex: 3,
    name: 'صحراء الذكاء',
    stageStart: 31,
    stageEnd: 40,
    backgroundAsset: 'assets/images/campaign/worlds/world_04_desert.webp',
    nodePositions: <Offset>[
      Offset(0.46, 0.88),
      Offset(0.51, 0.76),
      Offset(0.58, 0.66),
      Offset(0.51, 0.56),
      Offset(0.41, 0.49),
      Offset(0.47, 0.40),
      Offset(0.55, 0.37),
      Offset(0.62, 0.34),
      Offset(0.51, 0.26),
      Offset(0.48, 0.14),
    ],
  ),
  CampaignWorld(
    worldIndex: 4,
    name: 'مدينة العباقرة',
    stageStart: 41,
    stageEnd: 50,
    backgroundAsset: 'assets/images/campaign/worlds/world_05_genius_city.webp',
    nodePositions: <Offset>[
      Offset(0.18, 0.74),
      Offset(0.32, 0.92),
      Offset(0.46, 0.88),
      Offset(0.53, 0.77),
      Offset(0.71, 0.69),
      Offset(0.39, 0.61),
      Offset(0.53, 0.42),
      Offset(0.62, 0.32),
      Offset(0.35, 0.31),
      Offset(0.47, 0.16),
    ],
  ),
  CampaignWorld(
    worldIndex: 5,
    name: 'جبل الأسئلة',
    stageStart: 51,
    stageEnd: 60,
    backgroundAsset: 'assets/images/campaign/worlds/world_06_mountain.webp',
    nodePositions: <Offset>[
      Offset(0.35, 0.82),
      Offset(0.43, 0.74),
      Offset(0.53, 0.66),
      Offset(0.62, 0.58),
      Offset(0.71, 0.50),
      Offset(0.67, 0.42),
      Offset(0.61, 0.34),
      Offset(0.67, 0.27),
      Offset(0.73, 0.21),
      Offset(0.76, 0.17),
    ],
  ),
  CampaignWorld(
    worldIndex: 6,
    name: 'بحر المعرفة',
    stageStart: 61,
    stageEnd: 70,
    backgroundAsset: 'assets/images/campaign/worlds/world_07_sea.webp',
    nodePositions: <Offset>[
      Offset(0.81, 0.83),
      Offset(0.61, 0.80),
      Offset(0.82, 0.63),
      Offset(0.62, 0.68),
      Offset(0.52, 0.58),
      Offset(0.25, 0.56),
      Offset(0.36, 0.38),
      Offset(0.63, 0.30),
      Offset(0.49, 0.25),
      Offset(0.48, 0.14),
    ],
  ),
  CampaignWorld(
    worldIndex: 7,
    name: 'مختبر العباقرة',
    stageStart: 71,
    stageEnd: 80,
    backgroundAsset: 'assets/images/campaign/worlds/world_08_lab.webp',
    nodePositions: <Offset>[
      Offset(0.60, 0.90),
      Offset(0.56, 0.78),
      Offset(0.68, 0.70),
      Offset(0.56, 0.62),
      Offset(0.51, 0.52),
      Offset(0.37, 0.47),
      Offset(0.57, 0.43),
      Offset(0.59, 0.31),
      Offset(0.53, 0.23),
      Offset(0.61, 0.15),
    ],
  ),
  CampaignWorld(
    worldIndex: 8,
    name: 'بوابة الأساطير',
    stageStart: 81,
    stageEnd: 90,
    backgroundAsset: 'assets/images/campaign/worlds/world_09_legends_gate.webp',
    nodePositions: <Offset>[
      Offset(0.22, 0.88),
      Offset(0.32, 0.83),
      Offset(0.57, 0.90),
      Offset(0.46, 0.80),
      Offset(0.38, 0.69),
      Offset(0.45, 0.59),
      Offset(0.41, 0.46),
      Offset(0.44, 0.32),
      Offset(0.38, 0.18),
      Offset(0.63, 0.37),
    ],
  ),
  CampaignWorld(
    worldIndex: 9,
    name: 'قصر المليون',
    stageStart: 91,
    stageEnd: 100,
    backgroundAsset:
        'assets/images/campaign/worlds/world_10_million_palace.webp',
    nodePositions: <Offset>[
      Offset(0.23, 0.92),
      Offset(0.30, 0.82),
      Offset(0.38, 0.76),
      Offset(0.49, 0.70),
      Offset(0.57, 0.64),
      Offset(0.58, 0.53),
      Offset(0.64, 0.44),
      Offset(0.42, 0.35),
      Offset(0.56, 0.28),
      Offset(0.65, 0.18),
    ],
  ),
];
