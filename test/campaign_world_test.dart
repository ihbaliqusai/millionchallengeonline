import 'package:flutter_test/flutter_test.dart';
import 'package:millionaire_flutter_exact/models/campaign_world.dart';

void main() {
  group('Campaign worlds', () {
    test('defines ten worlds with editable node positions', () {
      expect(campaignWorlds, hasLength(10));

      for (final world in campaignWorlds) {
        expect(world.backgroundAsset, isNotEmpty, reason: world.name);
        expect(world.nodePositions, hasLength(10), reason: world.name);
        for (final position in world.nodePositions) {
          expect(position.dx, inInclusiveRange(0, 1), reason: world.name);
          expect(position.dy, inInclusiveRange(0, 1), reason: world.name);
        }
      }
    });

    test('maps stage orders to the correct worlds', () {
      expect(campaignWorldForStageOrder(1).name, 'غابة البداية');
      expect(campaignWorldForStageOrder(10).name, 'غابة البداية');
      expect(campaignWorldForStageOrder(11).name, 'تلال المعرفة');
      expect(campaignWorldForStageOrder(91).name, 'قصر المليون');
      expect(campaignWorldForStageOrder(100).name, 'قصر المليون');

      expect(campaignWorlds.first.stageStart, 1);
      expect(campaignWorlds.first.stageEnd, 10);
      expect(campaignWorlds.last.stageStart, 91);
      expect(campaignWorlds.last.stageEnd, 100);
    });
  });
}
