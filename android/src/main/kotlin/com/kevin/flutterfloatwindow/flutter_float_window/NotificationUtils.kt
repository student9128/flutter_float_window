package com.kevin.flutterfloatwindow.flutter_float_window

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.Icon
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.util.Log
import android.widget.RemoteViews
import android.widget.RemoteViews.RemoteView
import androidx.core.app.NotificationManagerCompat

lateinit var mNManager: NotificationManager
lateinit var notification2: Notification
var isPlaying = true
fun showNotification(
    context: Context,
    title: String,
    summary: String,
    channelID: String,
    channelName: String
) {
    val intent = Intent()
    intent.setPackage(context.packageName)
    val pendingIntent = createPendingIntent(context, intent)
    mNManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    mNManager.cancelAll()
    val builder: Notification.Builder =
        createNotificationBuilder(context, pendingIntent, title, summary, channelID)

    //设置下拉之后显示的图片
//        builder.setLargeIcon(BitmapFactory.decodeResource(context.getResources(), R.mipmap.ic_launcher));
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        val channel =
            NotificationChannel(channelID, channelName, NotificationManager.IMPORTANCE_DEFAULT)
        channel.enableLights(false)
        channel.lightColor = Color.GREEN
        channel.setShowBadge(false) //是否在久按桌面图标时显示此渠道的通知
        mNManager.createNotificationChannel(channel)
    }
    notification2 = builder.build()
    mNManager.notify(3, notification2)
}

/**
 * check if notification can show
 */
fun checkCanShowNotification(context: Context): Boolean {
    val notificationManager: NotificationManagerCompat = NotificationManagerCompat.from(context)
    return notificationManager.areNotificationsEnabled()
}

/**
 * go setting page to setting notification permission
 */
fun goSettingPage(context: Context) {
    val intent: Intent = Intent()
    try {
        intent.action = Settings.ACTION_APP_NOTIFICATION_SETTINGS

        //8.0及以后版本使用这两个extra.  >=API 26
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, context.packageName)
            intent.putExtra(Settings.EXTRA_CHANNEL_ID, context.applicationInfo.uid)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            //5.0-7.1 使用这两个extra.  <= API 25, >=API 21
            intent.putExtra("app_package", context.packageName)
            intent.putExtra("app_uid", context.applicationInfo.uid)
        }
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

        context.startActivity(intent)
    } catch (e: Exception) {
        e.printStackTrace()

        //其他低版本或者异常情况，走该节点。进入APP设置界面
        intent.action = Settings.ACTION_APPLICATION_DETAILS_SETTINGS
        intent.putExtra("package", context.packageName)

        //val uri = Uri.fromParts("package", packageName, null)
        //intent.data = uri
        context.startActivity(intent)
    }
}

lateinit var remoteView: RemoteViews
private fun createNotificationBuilder(
    context: Context,
    pendingIntent: PendingIntent?,
    title: String, summary: String, channelID: String
): Notification.Builder {
    val builder: Notification.Builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        Notification.Builder(context, channelID)
    } else {
        Notification.Builder(context)
    }
    remoteView = RemoteViews(context.packageName, R.layout.layout_remote_view)
    remoteView.setTextViewText(R.id.tvTitle, title)
    remoteView.setTextViewText(R.id.tvContent, summary)
    remoteView.setImageViewResource(R.id.ivPlay, R.drawable.ic_pause)
    remoteView.setImageViewResource(R.id.ivCover,R.drawable.ic_play)
    var forwardPendingIntent = PendingIntent.getBroadcast(
        context,
        0,
        Intent("com.kevin.float.FORWARD"),
        PendingIntent.FLAG_UPDATE_CURRENT
    )
    remoteView.setOnClickPendingIntent(R.id.llForward, forwardPendingIntent)
    var playPendingIntent = PendingIntent.getBroadcast(
        context,
        1,
        Intent("com.kevin.float.PLAY"),
        PendingIntent.FLAG_UPDATE_CURRENT
    )
    remoteView.setOnClickPendingIntent(R.id.llPlay, playPendingIntent)
    var backwardPendingIntent = PendingIntent.getBroadcast(
        context,
        2,
        Intent("com.kevin.float.BACKWARD"),
        PendingIntent.FLAG_UPDATE_CURRENT
    )
    remoteView.setOnClickPendingIntent(R.id.llBackward, backwardPendingIntent)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
//        builder.setCustomContentView(remoteView)
        builder.setCustomBigContentView(remoteView)
        builder.setCustomHeadsUpContentView(remoteView)
    } else {
        builder.setContent(remoteView)
    }
    //设置标题
    builder.setContentTitle(title)
    //设置内容
    builder.setContentText(summary)
    //设置状态栏显示的图标，建议图标颜色透明
    builder.setSmallIcon(context.applicationInfo.icon)
    // 设置通知灯光（LIGHTS）、铃声（SOUND）、震动（VIBRATE）、（ALL 表示都设置）
    builder.setDefaults(Notification.DEFAULT_ALL)
    //灯光三个参数，颜色（argb）、亮时间（毫秒）、暗时间（毫秒）,灯光与设备有关
    builder.setLights(Color.RED, 200, 200)
    // 铃声,传入铃声的 Uri（可以本地或网上）我这没有铃声就不传了
    builder.setSound(Uri.parse(""))
    // 震动，传入一个 long 型数组，表示 停、震、停、震 ... （毫秒）
    builder.setVibrate(longArrayOf(0, 200, 200, 200, 200, 200))
    // 通知栏点击后自动消失
    builder.setAutoCancel(true)
    if(Build.VERSION.SDK_INT >= Build.VERSION_CODES.M){
    builder.setLargeIcon(Icon.createWithResource(context,R.drawable.ic_play))
    }else{
    }
    // 简单通知栏设置 Intent
    builder.setContentIntent(pendingIntent)
    builder.setPriority(Notification.PRIORITY_HIGH)
    return builder
}

private fun createPendingIntent(
    context: Context,
    intent: Intent
): PendingIntent? {
    val pendingIntent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
    } else {
        PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
    }
    return pendingIntent
}

fun updateRemoteViews() {
    Log.d("Notification", "update")
    if (isPlaying) {
        isPlaying = false
        remoteView.setImageViewResource(R.id.ivPlay, R.drawable.ic_play)
    } else {
        isPlaying = true
        remoteView.setImageViewResource(R.id.ivPlay, R.drawable.ic_pause)
    }
    mNManager.notify(3, notification2)
}