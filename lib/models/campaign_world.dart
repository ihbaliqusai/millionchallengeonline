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
      Offset(0.594, 0.827),
      Offset(0.786, 0.676),
      Offset(0.779, 0.432),
      Offset(0.650, 0.586),
      Offset(0.468, 0.575),
      Offset(0.264, 0.551),
      Offset(0.349, 0.395),
      Offset(0.517, 0.343),
      Offset(0.706, 0.290),
      Offset(0.371, 0.205),
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
      Offset(0.258, 0.943),
      Offset(0.333, 0.830),
      Offset(0.153, 0.556),
      Offset(0.621, 0.875),
      Offset(0.445, 0.730),
      Offset(0.589, 0.617),
      Offset(0.424, 0.464),
      Offset(0.621, 0.493),
      Offset(0.688, 0.380),
      Offset(0.791, 0.285),
    ],
  ),
  CampaignWorld(
    worldIndex: 3,
    name: 'صحراء الذكاء',
    stageStart: 31,
    stageEnd: 40,
    backgroundAsset: 'assets/images/campaign/worlds/world_04_desert.webp',
    nodePositions: <Offset>[
      Offset(0.171, 0.920),
      Offset(0.439, 0.919),
      Offset(0.582, 0.761),
      Offset(0.764, 0.617),
      Offset(0.464, 0.619),
      Offset(0.414, 0.508),
      Offset(0.578, 0.412),
      Offset(0.513, 0.279),
      Offset(0.251, 0.255),
      Offset(0.466, 0.146),
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
      Offset(0.065, 0.664),
      Offset(0.318, 0.930),
      Offset(0.690, 0.893),
      Offset(0.877, 0.799),
      Offset(0.478, 0.785),
      Offset(0.689, 0.660),
      Offset(0.544, 0.519),
      Offset(0.669, 0.409),
      Offset(0.498, 0.312),
      Offset(0.656, 0.227),
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
      Offset(0.136, 0.747),
      Offset(0.392, 0.927),
      Offset(0.607, 0.928),
      Offset(0.844, 0.685),
      Offset(0.587, 0.752),
      Offset(0.514, 0.570),
      Offset(0.330, 0.434),
      Offset(0.757, 0.347),
      Offset(0.565, 0.401),
      Offset(0.586, 0.190),
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
      Offset(0.108, 0.652),
      Offset(0.252, 0.939),
      Offset(0.346, 0.837),
      Offset(0.468, 0.763),
      Offset(0.586, 0.641),
      Offset(0.226, 0.534),
      Offset(0.637, 0.448),
      Offset(0.423, 0.364),
      Offset(0.557, 0.340),
      Offset(0.647, 0.205),
    ],
  ),
];
