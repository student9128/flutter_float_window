package com.kevin.flutterfloatwindow.flutter_float_window

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class ScreenLockBroadcastReceiver constructor(private val listener: ScreenLockListener.ScreenStateListener) :
    BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action

        if (Intent.ACTION_SCREEN_ON == action) {
            listener.onScreenOn()
        } else if (Intent.ACTION_SCREEN_OFF == action) {
            listener.onScreenOff()
        } else if (Intent.ACTION_USER_PRESENT == action) {
            listener.onScreenPresent()
        }
    }
}