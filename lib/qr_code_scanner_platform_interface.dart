import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'qr_code_scanner_method_channel.dart';

abstract class QrCodeScannerPlatform extends PlatformInterface {
  /// Constructs a QrCodeScannerPlatform.
  QrCodeScannerPlatform() : super(token: _token);

  static final Object _token = Object();

  static QrCodeScannerPlatform _instance = MethodChannelQrCodeScanner();

  /// The default instance of [QrCodeScannerPlatform] to use.
  ///
  /// Defaults to [MethodChannelQrCodeScanner].
  static QrCodeScannerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [QrCodeScannerPlatform] when
  /// they register themselves.
  static set instance(QrCodeScannerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
