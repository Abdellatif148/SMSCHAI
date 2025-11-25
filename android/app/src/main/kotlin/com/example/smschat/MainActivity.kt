package com.example.smschat

import io.flutter.embedding.android.FlutterActivity

import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.smschat/mms"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "sendMms") {
                val address = call.argument<String>("address")
                val attachmentPath = call.argument<String>("attachmentPath")
                val body = call.argument<String>("message")

                if (address != null && attachmentPath != null) {
                    sendMms(address, attachmentPath, body)
                    result.success(null)
                } else {
                    result.error("INVALID_ARGUMENTS", "Address or attachmentPath is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun sendMms(address: String, filePath: String, body: String?) {
        val file = File(filePath)
        
        // Verify file exists
        if (!file.exists()) {
            throw IllegalArgumentException("File does not exist: $filePath")
        }
        
        val contentUri: Uri = FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.fileprovider",
            file
        )

        // Detect MIME type based on file extension
        val mimeType = when (file.extension.lowercase()) {
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "gif" -> "image/gif"
            "mp4" -> "video/mp4"
            "3gp" -> "video/3gp"
            "mp3" -> "audio/mpeg"
            "m4a" -> "audio/mp4"
            else -> "image/*" // Default fallback
        }

        val intent = Intent(Intent.ACTION_SEND).apply {
            putExtra("address", address)
            putExtra("sms_body", body ?: "")
            putExtra(Intent.EXTRA_STREAM, contentUri)
            type = mimeType
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        // Try to target the default SMS app
        val defaultSmsPackageName = android.provider.Telephony.Sms.getDefaultSmsPackage(this)
        if (defaultSmsPackageName != null) {
            intent.setPackage(defaultSmsPackageName)
        }

        startActivity(intent)
    }
}
