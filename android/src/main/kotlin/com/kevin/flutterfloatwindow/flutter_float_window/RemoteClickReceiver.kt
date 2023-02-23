package com.kevin.flutterfloatwindow.flutter_float_window

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class RemoteClickReceiver constructor(private val listener: RemoteClickListener.RemoteViewClickListener) : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent) {
        when (intent.action) {
            "com.kevin.float.FORWARD" -> {
                Log.d(javaClass.name, "forward")
                listener.onForwardClick()
            }
            "com.kevin.float.PLAY" -> {
                listener.onPlayClick()
                updateRemoteViews()
                Log.d(javaClass.name, "play")
            }
            "com.kevin.float.BACKWARD" -> {
                listener.onBackwardClick()
                Log.d(javaClass.name, "backward")
            }
        }
    }
}