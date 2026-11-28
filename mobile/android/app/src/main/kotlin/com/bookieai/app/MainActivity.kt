package com.bookieai.app

import android.Manifest
import android.content.pm.PackageManager
import android.provider.Telephony
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "bookie_ai/sms")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "readInbox" -> {
                        val since = call.argument<Number>("since")?.toLong() ?: 0L
                        val limit = call.argument<Int>("limit") ?: 200
                        if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS)
                            != PackageManager.PERMISSION_GRANTED
                        ) {
                            result.error("PERMISSION_DENIED", "READ_SMS not granted", null)
                        } else {
                            try {
                                result.success(readInbox(since, limit))
                            } catch (e: Exception) {
                                result.error("READ_FAILED", e.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /** Inbox messages received after [since] (epoch ms), newest first. */
    private fun readInbox(since: Long, limit: Int): List<Map<String, Any?>> {
        val messages = mutableListOf<Map<String, Any?>>()
        contentResolver.query(
            Telephony.Sms.Inbox.CONTENT_URI,
            arrayOf(Telephony.Sms.ADDRESS, Telephony.Sms.BODY, Telephony.Sms.DATE),
            "${Telephony.Sms.DATE} > ?",
            arrayOf(since.toString()),
            "${Telephony.Sms.DATE} DESC",
        )?.use { cursor ->
            val address = cursor.getColumnIndexOrThrow(Telephony.Sms.ADDRESS)
            val body = cursor.getColumnIndexOrThrow(Telephony.Sms.BODY)
            val date = cursor.getColumnIndexOrThrow(Telephony.Sms.DATE)
            while (cursor.moveToNext() && messages.size < limit) {
                messages.add(
                    mapOf(
                        "address" to cursor.getString(address),
                        "body" to cursor.getString(body),
                        "date" to cursor.getLong(date),
                    ),
                )
            }
        }
        return messages
    }
}
