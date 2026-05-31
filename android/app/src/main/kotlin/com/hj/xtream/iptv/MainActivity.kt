package com.hj.xtream.iptv

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

import com.google.android.gms.cast.MediaInfo
import com.google.android.gms.cast.MediaLoadRequestData
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.cast.MediaStatus
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastSession
import com.google.android.gms.cast.framework.SessionManager
import com.google.android.gms.cast.framework.SessionManagerListener
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.api.PendingResult

class MainActivity: FlutterActivity() {
    private val TAG = "XTREAM_IPTV"

    private val CHANNEL = "com.hj.xtream.iptv/intent"
    private val CAST_CHANNEL = "com.hj.xtream.iptv/cast"
    private val CAST_STATE_CHANNEL = "com.hj.xtream.iptv/cast_state"

    private var castContext: CastContext? = null
    private var sessionManager: SessionManager? = null
    private var currentCastSession: CastSession? = null
    private var castStateSink: EventChannel.EventSink? = null

    private val sessionManagerListener = object : SessionManagerListener<CastSession> {
        override fun onSessionStarted(session: CastSession, sessionId: String) {
            currentCastSession = session
            Log.d(TAG, "Cast session started: $sessionId")
            sendCastState("connected")
        }

        override fun onSessionResumed(session: CastSession, wasSuspended: Boolean) {
            currentCastSession = session
            Log.d(TAG, "Cast session resumed")
            sendCastState("connected")
        }

        override fun onSessionEnded(session: CastSession, error: Int) {
            currentCastSession = null
            Log.d(TAG, "Cast session ended with error: $error")
            sendCastState("disconnected")
        }

        override fun onSessionSuspended(session: CastSession, reason: Int) {
            Log.d(TAG, "Cast session suspended: $reason")
            sendCastState("suspended")
        }

        override fun onSessionStarting(session: CastSession) {
            Log.d(TAG, "Cast session starting")
            sendCastState("connecting")
        }

        override fun onSessionStartFailed(session: CastSession, error: Int) {
            currentCastSession = null
            Log.d(TAG, "Cast session start failed: $error")
            sendCastState("error")
        }

        override fun onSessionEnding(session: CastSession) {
            Log.d(TAG, "Cast session ending")
        }

        override fun onSessionResuming(session: CastSession, sessionId: String) {
            Log.d(TAG, "Cast session resuming: $sessionId")
            sendCastState("connecting")
        }

        override fun onSessionResumeFailed(session: CastSession, error: Int) {
            Log.d(TAG, "Cast session resume failed: $error")
            sendCastState("error")
        }
    }

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

        initCast()

        MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, CAST_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    result.success(true)
                }
                "isAvailable" -> {
                    val available = GoogleApiAvailability.getInstance()
                        .isGooglePlayServicesAvailable(this) == ConnectionResult.SUCCESS
                    result.success(available && castContext != null)
                }
                "getCastState" -> {
                    val state = when {
                        currentCastSession != null -> "connected"
                        castContext != null -> "disconnected"
                        else -> "unavailable"
                    }
                    result.success(state)
                }
                "loadMedia" -> {
                    val url = call.argument<String>("url") ?: ""
                    val title = call.argument<String>("title") ?: ""
                    val subtitle = call.argument<String>("subtitle") ?: ""
                    val contentType = call.argument<String>("contentType") ?: "video/mp4"
                    val imageUrl = call.argument<String>("imageUrl") ?: ""

                    if (url.isEmpty()) {
                        result.error("INVALID_URL", "Stream URL is empty", null)
                        return@setMethodCallHandler
                    }

                    loadMediaToCast(url, title, subtitle, contentType, imageUrl, result)
                }
                "play" -> {
                    currentCastSession?.remoteMediaClient?.play()
                    result.success(true)
                }
                "pause" -> {
                    currentCastSession?.remoteMediaClient?.pause()
                    result.success(true)
                }
                "seekTo" -> {
                    val position = call.argument<Int>("position") ?: 0
                    currentCastSession?.remoteMediaClient?.seek(position.toLong())
                    result.success(true)
                }
                "stop" -> {
                    currentCastSession?.remoteMediaClient?.stop()
                    result.success(true)
                }
                "getPlaybackStatus" -> {
                    val client = currentCastSession?.remoteMediaClient
                    if (client != null) {
                        val state = when (client.mediaStatus?.playerState) {
                            MediaStatus.PLAYER_STATE_PLAYING -> "playing"
                            MediaStatus.PLAYER_STATE_PAUSED -> "paused"
                            MediaStatus.PLAYER_STATE_BUFFERING -> "buffering"
                            MediaStatus.PLAYER_STATE_IDLE -> "idle"
                            else -> "unknown"
                        }
                        val position = client.approximateStreamPosition
                        val duration = client.streamDuration
                        result.success(mapOf(
                            "state" to state,
                            "position" to position,
                            "duration" to duration
                        ))
                    } else {
                        result.success(mapOf(
                            "state" to "disconnected",
                            "position" to 0L,
                            "duration" to 0L
                        ))
                    }
                }
                "endSession" -> {
                    sessionManager?.endCurrentSession(false)
                    currentCastSession = null
                    sendCastState("disconnected")
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine?.dartExecutor?.binaryMessenger!!, CAST_STATE_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    castStateSink = events
                    val state = when {
                        currentCastSession != null -> "connected"
                        castContext != null -> "disconnected"
                        else -> "unavailable"
                    }
                    events?.success(state)
                }
                override fun onCancel(arguments: Any?) {
                    castStateSink = null
                }
            }
        )
    }

    private fun initCast() {
        try {
            val availability = GoogleApiAvailability.getInstance()
            val resultCode = availability.isGooglePlayServicesAvailable(this)

            if (resultCode != ConnectionResult.SUCCESS) {
                Log.w(TAG, "Google Play Services not available: ${availability.getErrorString(resultCode)}")
                return
            }

            @Suppress("DEPRECATION")
            castContext = CastContext.getSharedInstance(this)
            sessionManager = castContext?.sessionManager
            sessionManager?.addSessionManagerListener(sessionManagerListener, CastSession::class.java)

            Log.d(TAG, "Cast framework initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize Cast framework: ${e.message}")
        }
    }

    private fun loadMediaToCast(
        url: String,
        title: String,
        subtitle: String,
        contentType: String,
        imageUrl: String,
        result: MethodChannel.Result
    ) {
        try {
            val session = currentCastSession
            if (session == null) {
                result.error("NO_SESSION", "No active Cast session. Please connect to a device first.", null)
                return
            }

            val remoteMediaClient = session.remoteMediaClient
            if (remoteMediaClient == null) {
                result.error("NO_CLIENT", "Remote media client not available", null)
                return
            }

            val mediaMetadata = MediaMetadata(MediaMetadata.MEDIA_TYPE_MOVIE)
            mediaMetadata.putString(MediaMetadata.KEY_TITLE, title)
            mediaMetadata.putString(MediaMetadata.KEY_SUBTITLE, subtitle)

            if (imageUrl.isNotEmpty()) {
                mediaMetadata.addImage(com.google.android.gms.common.images.WebImage(Uri.parse(imageUrl)))
            }

            val streamType = when {
                url.contains(".m3u8") -> MediaInfo.STREAM_TYPE_LIVE
                url.contains("/live/") -> MediaInfo.STREAM_TYPE_LIVE
                contentType.contains("mpegurl") -> MediaInfo.STREAM_TYPE_LIVE
                else -> MediaInfo.STREAM_TYPE_BUFFERED
            }

            val mediaInfo = MediaInfo.Builder(url)
                .setStreamType(streamType)
                .setContentType(contentType)
                .setMetadata(mediaMetadata)
                .build()

            val loadRequestData = MediaLoadRequestData.Builder()
                .setMediaInfo(mediaInfo)
                .setAutoplay(true)
                .build()

            val pendingResult = remoteMediaClient.load(loadRequestData)

            pendingResult.setResultCallback { status ->
                if (status.status.isSuccess) {
                    Log.d(TAG, "Media loaded successfully to Cast device")
                    result.success(true)
                } else {
                    val error = status.status.statusMessage ?: "Unknown error loading media"
                    Log.e(TAG, "Failed to load media: $error")
                    result.error("LOAD_FAILED", error, null)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading media to Cast: ${e.message}")
            result.error("CAST_ERROR", e.message, null)
        }
    }

    private fun sendCastState(state: String) {
        try {
            activity.runOnUiThread {
                castStateSink?.success(state)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error sending cast state: ${e.message}")
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        try {
            sessionManager?.removeSessionManagerListener(sessionManagerListener, CastSession::class.java)
        } catch (e: Exception) {
            Log.e(TAG, "Error removing session listener: ${e.message}")
        }
    }
}
