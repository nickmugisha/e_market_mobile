package com.example.e_market

import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlin.math.max
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.e_market/native_image_picker"
    private val imageRequestCode = 4701
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickImage" -> openImagePicker(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun openImagePicker(result: MethodChannel.Result) {
        if (pendingResult != null) {
            result.error(
                "picker_busy",
                "The image picker is already open.",
                null,
            )
            return
        }

        pendingResult = result

        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "image/*"
            addCategory(Intent.CATEGORY_OPENABLE)
        }

        startActivityForResult(
            Intent.createChooser(intent, "Choose product image"),
            imageRequestCode,
        )
    }

    @Deprecated("Deprecated in Android API, retained for FlutterActivity compatibility")
    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?,
    ) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != imageRequestCode) return

        val result = pendingResult
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            result?.success(null)
            return
        }

        try {
            val bytes = compressImage(data.data!!)
            result?.success(bytes)
        } catch (error: Exception) {
            result?.error(
                "image_read_failed",
                error.message ?: "Could not read the selected image.",
                null,
            )
        }
    }

    private fun compressImage(uri: Uri): ByteArray {
        val original = contentResolver.openInputStream(uri).use { stream ->
            requireNotNull(stream) { "Could not open the selected image." }
            requireNotNull(BitmapFactory.decodeStream(stream)) {
                "The selected file is not a readable image."
            }
        }

        val maxDimension = 900
        val largestSide = max(original.width, original.height)

        val scaled = if (largestSide > maxDimension) {
            val scale = maxDimension.toDouble() / largestSide.toDouble()
            val width = (original.width * scale).roundToInt().coerceAtLeast(1)
            val height = (original.height * scale).roundToInt().coerceAtLeast(1)
            Bitmap.createScaledBitmap(original, width, height, true)
        } else {
            original
        }

        var quality = 62
        var bytes: ByteArray

        do {
            val output = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.JPEG, quality, output)
            bytes = output.toByteArray()
            quality -= 8
        } while (bytes.size > 430 * 1024 && quality >= 30)

        if (scaled !== original) {
            scaled.recycle()
        }
        original.recycle()

        require(bytes.size <= 450 * 1024) {
            "The image is still too large after compression. Choose a simpler image."
        }

        return bytes
    }
}
