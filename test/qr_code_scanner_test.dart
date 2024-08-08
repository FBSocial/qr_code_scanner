import 'package:flutter_test/flutter_test.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_code_scanner/qr_code_scanner_platform_interface.dart';
import 'package:qr_code_scanner/qr_code_scanner_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockQrCodeScannerPlatform
    with MockPlatformInterfaceMixin
    implements QrCodeScannerPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final QrCodeScannerPlatform initialPlatform = QrCodeScannerPlatform.instance;

  test('$MethodChannelQrCodeScanner is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelQrCodeScanner>());
  });

  test('getPlatformVersion', () async {
    QrCodeScanner qrCodeScannerPlugin = QrCodeScanner();
    MockQrCodeScannerPlatform fakePlatform = MockQrCodeScannerPlatform();
    QrCodeScannerPlatform.instance = fakePlatform;

    expect(await qrCodeScannerPlugin.getPlatformVersion(), '42');
  });
}
