package net.touchcapture.qr.flutterqr

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import com.google.zxing.*
import com.google.zxing.common.GlobalHistogramBinarizer
import com.google.zxing.common.HybridBinarizer
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.*


class QRMethodHandler(messenger: BinaryMessenger) : MethodChannel.MethodCallHandler {
    private val channel = MethodChannel(messenger, "net.touchcapture.qr.flutterqr.qrScan")
    private var decodeImgJob: Job? = null
    private val hints: Map<DecodeHintType, Any> = mapOf(
            DecodeHintType.TRY_HARDER to BarcodeFormat.QR_CODE,
            DecodeHintType.POSSIBLE_FORMATS to BarcodeFormat.values().toList(),
            DecodeHintType.CHARACTER_SET to "utf-8",
    )

    companion object {
        const val ERR_INVALID_PATH = 1
        const val ERR_DECODE_FAILED = 2
    }

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scanImage" -> {
                val args = call.arguments as Map<*, *>
                val path = args["path"] as String
                cancelDecodeImg()
                decodeImgJob = GlobalScope.launch(Dispatchers.Default) {
                    val image: Bitmap
                    try {
                        image = compressBitMap(path)
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error(ERR_INVALID_PATH.toString(), "invalid image path", e)
                        }
                        return@launch
                    }
                    try {
                        val res = scanQrFromImage(image)
                        val code = mapOf(
                                "code" to res.text,
                                "type" to res.barcodeFormat.name,
                                "rawBytes" to res.rawBytes)
                        withContext(Dispatchers.Main) {
                            result.success(code)
                        }
                    } catch (e: NotFoundException) {
                        // there are no qr code in image
                        withContext(Dispatchers.Main) {
                            result.success(null)
                        }
                    } catch (e: Exception) {
                        e.printStackTrace()
                        Log.i("Lee", "decode image error: ${e.message}")
                        withContext(Dispatchers.Main) {
                            result.error(ERR_DECODE_FAILED.toString(), "failed to decode image: $path", e)
                        }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun cancelDecodeImg() {
        if (decodeImgJob != null && !decodeImgJob!!.isCancelled) {
            decodeImgJob!!.cancel()
        }
        decodeImgJob = null
    }

    fun onDetach() {
        cancelDecodeImg()
    }

    // Scan qr code from image
    private fun scanQrFromImage(image: Bitmap): Result {
        var source: RGBLuminanceSource? = null
        ///如果是长图，就进行分段扫描
        ///要保证二维码位于两个分段中间扫描不上，所以需要有一定的重合点。
        if (image.height > 1000) {
            var index = 0;
            while ((index - 1) * 1000 < image.height) {
                val width: Int = image.width
                val height: Int = image.height
                val pixels = IntArray(width * height)
                var y = index * 1000 - 500;
                var doHeight = 1500;
                if (y < 0) {
                    y = 0
                }
                if (y + doHeight > image.height) {
                    doHeight = image.height - y
                }
                image.getPixels(pixels, 0, width, 0, y, width, doHeight)
                source = RGBLuminanceSource(width, doHeight, pixels)
                index += 1;
                try {
                    var re = MultiFormatReader().decode(BinaryBitmap(HybridBinarizer(source)), hints)
                    return re;
                } catch (e: Exception) {

                }
            }

        }

        try {
            val width: Int = image.width
            val height: Int = image.height
            val pixels = IntArray(width * height)
            image.getPixels(pixels, 0, width, 0, 0, width, image.height)
            source = RGBLuminanceSource(width, image.height, pixels)
            return MultiFormatReader().decode(BinaryBitmap(HybridBinarizer(source)), hints)
        } catch (e: Exception) {
            if (source == null) {
                throw e
            }
        }
        return MultiFormatReader().decode(BinaryBitmap(GlobalHistogramBinarizer(source)), hints)

    }

    private fun compressBitMap(path: String): Bitmap {
        val options = BitmapFactory.Options()
        options.inJustDecodeBounds = true
        BitmapFactory.decodeFile(path, options)
        val shrinkHeight = 5000
        // compress image, shrink it's height within 500
        options.inSampleSize = if (options.outHeight > shrinkHeight) options.outHeight / shrinkHeight else 1
        options.inJustDecodeBounds = false
        options.inPreferredConfig = Bitmap.Config.RGB_565
        return BitmapFactory.decodeFile(path, options)
    }
}