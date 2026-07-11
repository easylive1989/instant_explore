"""e2e_cases collector 的靜態解析測試。"""
from lorescape_dashboard.collectors.e2e_cases import extract_case_names

DART = """\
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('generate narration success', ($) async {
    await $.pumpWidget(app);
  });

  patrolTest(
    'saved generate narration success',
    ($) async {},
  );

  testWidgets("permission denied shows dialog", (tester) async {});

  testWidgets('given Explore loads, '
      'when OS denies location, '
      'then a dialog shows', (tester) async {});

  // patrolTest('註解掉的不算', ($) async {});
}
"""


class TestExtractCaseNames:
    def test_解析_patrolTest_與_testWidgets_名稱(self):
        assert extract_case_names(DART) == [
            "generate narration success",
            "saved generate narration success",
            "permission denied shows dialog",
            "given Explore loads, when OS denies location, then a dialog shows",
        ]

    def test_相鄰字串常值合併為單一案例名(self):
        names = extract_case_names(DART)
        assert "given Explore loads, when OS denies location, then a dialog shows" in names

    def test_跳過註解行(self):
        assert "註解掉的不算" not in extract_case_names(DART)
