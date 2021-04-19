import Flutter
import UIKit

public class SwiftFlutterQrPlugin: NSObject, FlutterPlugin {
    var factory: QRViewFactory
    public init(with registrar: FlutterPluginRegistrar) {
        self.factory = QRViewFactory(withRegistrar: registrar)
        registrar.register(factory, withId: "net.touchcapture.qr.flutterqr/qrview")
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "net.touchcapture.qr.flutterqr.qrScan", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterQrPlugin(with: registrar)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func applicationDidEnterBackground(_ application: UIApplication) {
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method{
        case "scanImage":
            if  let args =  call.arguments as? [String: Any], let path = args["path"] as? String{
                let res = self.scanImage(path)
                result(res)
            }else{
                result(FlutterError(code: "1", message: "Path is null, you have to pass a valid path!", details:nil))
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func scanImage(_ path: String) -> [String: Any]?{
        if let image = UIImage(named: path), let ciImage = CIImage.init(image: image){
            var options: [String: Any]
            let context = CIContext()
            options = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
            let qrDetector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: options)
            if ciImage.properties.keys.contains((kCGImagePropertyOrientation as String)){
                options = [CIDetectorImageOrientation: ciImage.properties[(kCGImagePropertyOrientation as String)] ?? 1]
            } else {
                options = [CIDetectorImageOrientation: 1]
            }
            if let features = qrDetector?.features(in: ciImage, options: options), !features.isEmpty{
                for case let row as CIQRCodeFeature in features{
                    if row.messageString != nil {
                        return ["code": row.messageString as Any, "type": "QR_CODE"]
                    }
                }
            }
            return nil
            
        }
        return nil
    }
}
