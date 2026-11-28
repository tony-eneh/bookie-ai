package com.bookieai.sms_inbox

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.provider.Telephony
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Serves `bookie_ai/sms` in every Flutter engine, including headless ones. */
class SmsInboxPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "bookie_ai/sms")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "readInbox" -> {
                val since = call.argument<Number>("since")?.toLong() ?: 0L
                val limit = call.argument<Int>("limit") ?: 200
                if (context.checkSelfPermission(Manifest.permission.READ_SMS)
                    != PackageManager.PERMISSION_GRANTED
                ) {
                    result.error("PERMISSION_DENIED", "READ_SMS not granted", null)
                    return
                }
                try {
                    result.success(readInbox(since, limit))
                } catch (e: Exception) {
                    result.error("READ_FAILED", e.message, null)
                }
            }
            else -> result.notImplemented()
        }
    }

    /** Inbox messages received after [since] (epoch ms), newest first. */
    private fun readInbox(since: Long, limit: Int): List<Map<String, Any?>> {
        val messages = mutableListOf<Map<String, Any?>>()
        context.contentResolver.query(
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
