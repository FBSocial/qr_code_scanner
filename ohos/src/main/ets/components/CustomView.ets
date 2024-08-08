import MethodChannel, {
  MethodCallHandler,
  MethodResult
} from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodChannel';
import PlatformView, { Params } from '@ohos/flutter_ohos/src/main/ets/plugin/platform/PlatformView';
import common from '@ohos.app.ability.common';
import { BinaryMessenger } from '@ohos/flutter_ohos/src/main/ets/plugin/common/BinaryMessenger';
import StandardMethodCodec from '@ohos/flutter_ohos/src/main/ets/plugin/common/StandardMethodCodec';
import MethodCall from '@ohos/flutter_ohos/src/main/ets/plugin/common/MethodCall';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { scanCore, scanBarcode } from '@kit.ScanKit';
import { BusinessError } from '@kit.BasicServicesKit';
import  QrCodeScannerPlugin  from  './plugin/QrCodeScannerPlugin';
const TAG: string = 'ScanKit createBarcode';

@Component
struct ButtonComponent {
  @Prop params: Params
  customView: CustomView = this.params.platformView as CustomView
  @StorageLink('numValue') storageLink: string = "first"
  @State bkColor: Color = Color.Black
  @State isTimerRunning: boolean = false

  build() {
    Column() {
      Text(``)
    }.alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .direction(Direction.Ltr)
    .width('100%')
    .height('100%')
  }

  onDidBuild(): void {
    setTimeout(() => {
      let options: scanBarcode.ScanOptions = {
        scanTypes: [scanCore.ScanType.QR_CODE],
        enableMultiMode: true,
        enableAlbum: true
      };
      try {
        scanBarcode.startScanForResult(getContext(this), options).then((result: scanBarcode.ScanResult) => {
          hilog.debug(0x0001, TAG,
            `扫码成功, result is ${JSON.stringify(result)}`);
          let qrString = result.originalValue;
          let map:Record<string,string> = {
            "code":qrString,
            "type":"QR_CODE",
          };
          this.customView.sendMessage(map);
        }).catch((error: BusinessError) => {
          if (error.code == scanCore.ScanErrorCode.SCAN_SERVICE_CANCELED) {
            hilog.info(0x0001, TAG, `扫码失败，用户手动关闭`);
            this.customView.sendError();
          } else {
            hilog.error(0x0001, TAG, `扫码失败 to start the scanning service. Code: ${error.code}`);
            this.customView.sendError();
          }
        });
      } catch (error) {
        hilog.error(0x0001, TAG, `扫码失败 to start scan. Code: ${error.code}`);
        this.customView.sendError();
      }
    }, 500);

  }

}

@Builder
function ButtonBuilder(params: Params) {
  ButtonComponent({ params: params })
    .backgroundColor(Color.Black)
}

AppStorage.setOrCreate('numValue', 'test')

@Observed
export class CustomView extends PlatformView implements MethodCallHandler {
  numValue: string = "test";

  methodChannel: MethodChannel;
  index: number = 1;

  constructor(context: common.Context, viewId: number, args: ESObject, message: BinaryMessenger) {
    super();
    // 注册消息通道
    this.methodChannel = new MethodChannel(message, `net.touchcapture.qr.flutterqr/qrview_${viewId}`, StandardMethodCodec.INSTANCE);
    this.methodChannel.setMethodCallHandler(this);
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    // 接受Dart侧发来的消息
    let method: string = call.method;
    let link1: SubscribedAbstractProperty<number> = AppStorage.link('numValue');
    switch (method) {
      case 'getMessageFromFlutterView':
        let value: ESObject = call.args;
        this.numValue = value;
        link1.set(value)
        console.log("nodeController receive message from dart: " + this.numValue);
        result.success(true);
        break;
    }
  }

  public  sendMessage(data: Record<string,string>): void {
    console.log("nodeController sendMessage")
    //向Dart侧发送消息
    if (this.methodChannel != null) {
      this.methodChannel.invokeMethod('onRecognizeQR',data);
    }
  }

  public  sendError(): void {
    let map:Record<string,string> = {
      "code":'ohos:error',
      "type":"QR_CODE",
    };
    console.log("nodeController sendMessage")
    //向Dart侧发送消息
    this.sendMessage(map);
  }

  getView(): WrappedBuilder<[Params]> {
    return new WrappedBuilder(ButtonBuilder);
  }

  dispose(): void {
  }
}