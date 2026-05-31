package com.hj.xtream.iptv

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.hj.xtream.iptv/intent"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "launchIntent" -> {
                    val url = call.argument<String>("url") ?: ""
                    val packageName = call.argument<String>("package") ?: ""
                    val type = call.argument<String>("type") ?: "video/*"

                    try {
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(Uri.parse(url), type)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
                            if (packageName.isNotEmpty()) {
                                setPackage(packageName)
                            }
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INTENT_ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
