import 'package:flutter_test/flutter_test.dart';
import 'package:metawear/boards/metamotionrl_board.dart';
import 'package:metawear/metawear.dart';
import 'package:metawear/metawear_platform_interface.dart';
import 'package:metawear/metawear_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMetawearPlatform
    with MockPlatformInterfaceMixin
    implements MetawearPlatform {
  @override
  Future<MetamotionRLBoard> connect(String mac, {bool? retry}) {
    throw UnimplementedError();
  }
}

void main() {
  final MetawearPlatform initialPlatform = MetawearPlatform.instance;

  test('$MethodChannelMetawear is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMetawear>());
  });
}
