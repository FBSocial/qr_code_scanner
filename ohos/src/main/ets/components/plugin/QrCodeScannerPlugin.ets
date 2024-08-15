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
import { hilog } from '@kit.PerformanceAnalysisKit';
import { scanCore, scanBarcode, detectBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG: string = 'ScanKit createBarcode';

/** QrCodeScannerPlugin **/
export default class QrCodeScannerPlugin implements FlutterPlugin, MethodCallHandler {
  public channel: MethodChannel | null = null;
  public scanFileChanne: MethodChannel | null = null;
  public static instance: QrCodeScannerPlugin | null ;

  constructor() {}

  getUniqueClassName(): string {
    return "QrCodeScannerPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    QrCodeScannerPlugin.instance = this;
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "qr_code_scanner");
    this.scanFileChanne = new MethodChannel(binding.getBinaryMessenger(), "net.touchcapture.qr.flutterqr.qrScan");
    this.channel.setMethodCallHandler(this)
    this.scanFileChanne.setMethodCallHandler(this);
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
    if (call.method == "scanQrCode") {
      let options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.QR_CODE],
        enableMultiMode: true,
        enableAlbum: true
      };
      scanBarcode.startScanForResult(getContext(this), options).then((qrResult: scanBarcode.ScanResult) => {
        hilog.debug(0x0001, TAG,
          `扫码成功, result is ${JSON.stringify(result)}`);
        let qrString = qrResult.originalValue;
        result.success(qrString);
      }).catch((error: BusinessError) => {
        if (error.code == scanCore.ScanErrorCode.SCAN_SERVICE_CANCELED) {
          hilog.info(0x0001, TAG, `扫码失败，用户手动关闭`);
          result.success('');
        } else {
          hilog.error(0x0001, TAG, `扫码失败 to start the scanning service. Code: ${error.code}`);
          result.success('');
        }
      });
    } else if (call.method == "scanImage") {
      let path = call.argument("path") as string;
      let options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.ALL],
        enableMultiMode: true
      }
      detectBarcode.decode({ uri: path }, options).then((r: Array<scanBarcode.ScanResult>) => {
        if (r.length > 0) {
          result.success({"code": r[0].originalValue, "type": "QR_CODE"});
        }else {
          result.success(null);
        }
      }).catch((error: BusinessError) => {
        result.success(null);
      });
    } else {
      result.notImplemented()
    }
  }
}