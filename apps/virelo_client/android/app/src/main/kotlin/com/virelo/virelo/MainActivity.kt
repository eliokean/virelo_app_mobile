package com.virelo.virelo

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val CHANNEL = "com.virelo.client/hce"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setPayload" -> {
                    val payload = call.argument<String>("payload")
                    VireloHceService.currentPayload = payload
                    result.success(true)
                }
                "clearPayload" -> {
                    VireloHceService.currentPayload = null
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
