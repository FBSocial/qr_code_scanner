import {
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  StandardMessageCodec,
} from '@ohos/flutter_ohos';

import { CustomFactory } from '../CustomFactory';

/** QrCodeScannerPlugin **/
export default class QrCodeScannerPlugin implements FlutterPlugin, MethodCallHandler {
  public channel: MethodChannel | null = null;

  public static instance: QrCodeScannerPlugin | null ;

  constructor() {
  }

  getUniqueClassName(): string {
    return "QrCodeScannerPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    QrCodeScannerPlugin.instance = this;
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "qr_code_scanner");
    this.channel.setMethodCallHandler(this)
    binding.getPlatformViewRegistry()?.
    registerViewFactory('net.touchcapture.qr.flutterqr/qrview', new CustomFactory(binding.getBinaryMessenger(), StandardMessageCodec.INSTANCE));
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
    QrCodeScannerPlugin.instance = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method == "getPlatformVersion") {
      result.success("OpenHarmony ^ ^ ")
    } else {
      result.notImplemented()
    }
  }
}