import 'package:metawear/boards/metamotionrl_board.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'metawear_method_channel.dart';

abstract class MetawearPlatform extends PlatformInterface {
  /// Constructs a MetawearPlatform.
  MetawearPlatform() : super(token: _token);

  static final Object _token = Object();

  static MetawearPlatform _instance = MethodChannelMetawear();

  /// The default instance of [MetawearPlatform] to use.
  ///
  /// Defaults to [MethodChannelMetawear].
  static MetawearPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MetawearPlatform] when
  /// they register themselves.
  static set instance(MetawearPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<MetamotionRLBoard> connect(String mac, {bool? retry}) {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
