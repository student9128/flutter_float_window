package com.kevin.flutterfloatwindow.flutter_float_window

import android.annotation.SuppressLint
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.net.Uri
import android.os.Binder
import android.os.Build
import android.os.IBinder
import android.util.Log
import android.view.*
import android.widget.FrameLayout
import android.widget.Toast
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.source.MediaSource
import com.google.android.exoplayer2.source.ProgressiveMediaSource
import com.google.android.exoplayer2.ui.StyledPlayerView
import com.google.android.exoplayer2.upstream.DefaultHttpDataSource
import kotlin.math.abs


class FloatWindowService : Service() {
    private lateinit var wmParams: WindowManager.LayoutParams
    private lateinit var mWindowManager: WindowManager
    private lateinit var mWindowView: View
    private lateinit var mContainer: FrameLayout
    private var hasAdded = false
    private var hasRelease = false
    private var currentUrl = ""
    private var isBig = true

    val touchResponseDistance = 10

    //声明IBinder接口的一个接口变量mBinder
    val mBinder: IBinder = LocalBinder()
    private var mNM: NotificationManager? = null

    //    private int NOTIFICATION = R.string.local_service_started;
    //LocalBinder是继承Binder的一个内部类
    inner class LocalBinder : Binder() {
        val service: FloatWindowService
            get() = this@FloatWindowService

        fun initFloatWindow(context: Context) {
            initPlayer(context)
            initWindowParams(context)
            initView(context)
            initGestureListener(context)
            addTestView()
        }

        fun initMediaSource(url: String) {
            currentUrl = url
            val uri = Uri.parse(url)
            val mediaSource = buildMediaSource(uri)
            player?.setMediaSource(mediaSource!!)
            player?.prepare()
            player?.play()
            mContainer.requestLayout()
            Log.d(
                javaClass.name,
                "player width height======${playerView!!.width},,${playerView!!.height}"
            )
        }

        fun startPlay() {
//            Log.d(javaClass.name,"player is playing======${player!!.isPlaying}")
            if (!player!!.isPlaying) {
                if (hasRelease) {
                    player?.prepare()
                    player?.playWhenReady = true
                } else {
                    player?.play()

                }
            }
        }

        fun stopPlay() {
            if (player!!.isPlaying) {
                player?.stop()
                hasRelease = true
//                player?.clearMediaItems()
            }
        }

        fun pausePlay() {
            if (player!!.isPlaying) {
                player?.pause()
            }
        }

        fun addFloatWindow() {
            addTestView()
        }

        fun removeFloatWindow() {
            removeWindowView()
        }

    }

    override fun onCreate() {
//        initPlayer()
//
//        initWindowParams()
//        initView()
//        initGestureListener()
//        addTestView()
        mNM = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        Log.e(javaClass.name, "onCreate")
        showNotification()
    }

    var player: ExoPlayer? = null
    var playerView: StyledPlayerView? = null
    private fun initPlayer(context: Context) {
        player = ExoPlayer.Builder(context).build()
//        val uri = Uri.parse("http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4")
//        val mediaSource = buildMediaSource(uri)
//        player?.setMediaSource(mediaSource!!)
//        player?.prepare()
        playerView = StyledPlayerView(this)
        var tvLayoutParams: FrameLayout.LayoutParams = FrameLayout.LayoutParams(-2, -2)
        tvLayoutParams.width = dip2px(context, 300f)
        tvLayoutParams.height = dip2px(context, 300 * 3 / 4f)
//        tvLayoutParams.rightMargin = 100
        playerView?.layoutParams = tvLayoutParams
        playerView?.player = player
//        player?.play()

    }

    private fun buildMediaSource(uri: Uri): MediaSource? {
        val httpDataSourceFactory = DefaultHttpDataSource.Factory()
            .setUserAgent("ExoPlayer")
            .setAllowCrossProtocolRedirects(true)
        return ProgressiveMediaSource.Factory(
            httpDataSourceFactory
        ).createMediaSource(MediaItem.fromUri(uri))
    }

    override fun onDestroy() {
        Log.e(javaClass.name, "onDestroy")
        mNM!!.cancel(101)
        Toast.makeText(this, "服务停止", Toast.LENGTH_SHORT).show()
    }

    override fun onBind(intent: Intent): IBinder? {
        Log.e(javaClass.name, "onBind")
        return mBinder
    }

    override fun onUnbind(intent: Intent): Boolean {
        Log.e(javaClass.name, "onUnbind")
        player?.stop()
        removeWindowView()
        return super.onUnbind(intent)
    }

    private fun showNotification() {
//        CharSequence text = ;
//        val contentIntent = PendingIntent.getActivity(
//            this, 0,
//            Intent(this, ServiceActivity::class.java), 0
//        )
//        val notification = Notification.Builder(this)
//            .setSmallIcon(R.mipmap.ic_launcher)
//            .setTicker("Service Start")
//            .setWhen(System.currentTimeMillis())
//            .setContentTitle("current service")
//            .setContentText("Service Start")
//            .setContentIntent(contentIntent)
//            .build()
//        mNM!!.notify(101, notification)
        Log.e(javaClass.name, "通知栏已出")
    }

    private fun initWindowParams(context: Context) {
        mWindowManager = application.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        wmParams = WindowManager.LayoutParams()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N_MR1) {
            setWMTypeCompat()
        } else if (RomUtil.isMiui) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                setWMTypeCompat()
            } else {
                wmParams.type = WindowManager.LayoutParams.TYPE_PHONE
            }
        } else {
            wmParams.type = WindowManager.LayoutParams.TYPE_TOAST
        }
        wmParams.format = PixelFormat.RGBA_8888
        wmParams.flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
        wmParams.gravity = Gravity.START or Gravity.TOP
        wmParams.width = WindowManager.LayoutParams.WRAP_CONTENT
        wmParams.height = WindowManager.LayoutParams.WRAP_CONTENT
    }

    private fun initView(context: Context) {
        mContainer = FrameLayout(context)
        mContainer.setBackgroundColor(Color.parseColor("#2196f3"))
        var flp = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        )
        mContainer.layoutParams = flp
    }

    private fun setWMTypeCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            wmParams.type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            wmParams.type = WindowManager.LayoutParams.TYPE_PHONE
        }
    }

    private fun addTestView() {
        if (!hasAdded) {
            try {
                if (mContainer.childCount > 0) {
                    mContainer.removeAllViews()
                }
                Log.d(
                    javaClass.name,
                    "player width height=23=====${playerView!!.width},,${playerView!!.height}"
                )
                mContainer.addView(playerView)
                mWindowManager.addView(mContainer, wmParams)
                val width = mWindowManager.defaultDisplay.width
                val height = mWindowManager.defaultDisplay.height
                wmParams.x = width - 600
                wmParams.y = 200
                hasAdded = true
                mWindowManager.updateViewLayout(mContainer, wmParams)
            } catch (e: Exception) {
                hasAdded = false
            }
            Log.e(javaClass.name, "initFloatWindow12")
        }
    }

    private fun addViewToWindow(view: View) {
        if (!hasAdded) {
            try {
                if (mContainer.childCount > 0) {
                    mContainer.removeAllViews()
                }
                mContainer.addView(view)
                mWindowManager.addView(mContainer, wmParams)
                val width = mWindowManager.defaultDisplay.width
                val height = mWindowManager.defaultDisplay.height
                wmParams.x = width
                wmParams.y = height / 2
                hasAdded = true
                mWindowManager.updateViewLayout(mContainer, wmParams)
            } catch (e: Exception) {
                hasAdded = false
            }
        }

    }

    /**
     * 移除控件
     */
    private fun removeWindowView() {
        if (hasAdded) {
            //移除悬浮窗口
            mWindowManager.removeView(mContainer)
            hasAdded = false
        }
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun initGestureListener(context: Context) {
        var gestureDetector =
            GestureDetector(applicationContext, object : GestureDetector.OnGestureListener {
                override fun onDown(e: MotionEvent?): Boolean = false

                override fun onShowPress(e: MotionEvent?) {
                }

                override fun onSingleTapUp(e: MotionEvent?): Boolean = false

                override fun onScroll(
                    e1: MotionEvent?,
                    e2: MotionEvent?,
                    distanceX: Float,
                    distanceY: Float
                ): Boolean {
                    Log.d(
                        javaClass.name,
                        "${e1!!.x - e2!!.x},,${e1.y - e2.y},,$distanceX,,,,$distanceY,,,${mContainer.x}.,,${mContainer.y}"
                    )
                    val absX = abs(e1.rawX - e2.rawX)
                    val absY = abs(e1.rawY - e2.rawY)
                    if (absX > touchResponseDistance && absY > touchResponseDistance) {
                        wmParams.x = e2.rawX.toInt() - mContainer.measuredWidth / 2
                        wmParams.y = e2.rawY.toInt() - mContainer.measuredWidth / 2
                        mWindowManager.updateViewLayout(mContainer, wmParams)
                    } else if (absX > touchResponseDistance && absY <= touchResponseDistance) {
                        wmParams.x = e2.rawX.toInt() - mContainer.measuredWidth / 2
                        mWindowManager.updateViewLayout(mContainer, wmParams)
                    } else if (absX < touchResponseDistance && absY > touchResponseDistance) {
                        wmParams.y = e2.rawY.toInt() - mContainer.measuredWidth / 2
                        mWindowManager.updateViewLayout(mContainer, wmParams)
                    }

                    return true
                }

                override fun onLongPress(e: MotionEvent?) {
                }

                override fun onFling(
                    e1: MotionEvent?,
                    e2: MotionEvent?,
                    velocityX: Float,
                    velocityY: Float
                ): Boolean = false

            })
        gestureDetector.setOnDoubleTapListener(object : GestureDetector.OnDoubleTapListener {
            override fun onSingleTapConfirmed(e: MotionEvent?): Boolean {
                if (player!!.isPlaying) {
                    player?.pause()
                } else {
                    player?.play()
                }
                return true
            }

            override fun onDoubleTap(e: MotionEvent?): Boolean {
//                Toast.makeText(applicationContext, "双击了", Toast.LENGTH_SHORT).show()
                if (isBig) {
                    var tvLayoutParams: FrameLayout.LayoutParams = FrameLayout.LayoutParams(-2, -2)
                    tvLayoutParams.width = dip2px(context, 200f)
                    tvLayoutParams.height = dip2px(context, 200 * 3 / 4f)
                    playerView?.layoutParams = tvLayoutParams
//                    playerView?.player = player
                    isBig = false
                } else {
                    var tvLayoutParams: FrameLayout.LayoutParams = FrameLayout.LayoutParams(-2, -2)
                    tvLayoutParams.width = dip2px(context, 300f)
                    tvLayoutParams.height = dip2px(context, 300 * 3 / 4f)
                    playerView?.layoutParams = tvLayoutParams
//                    playerView?.player = player
                    isBig = true
                }
                return true
            }

            override fun onDoubleTapEvent(e: MotionEvent?): Boolean = false

        })
        playerView?.setOnTouchListener { v, event ->
            gestureDetector.onTouchEvent(event)
            true
        }
    }
    //getTouchSlop


    // 根据手机的分辨率从 dp 的单位 转成为 px(像素)
    fun dip2px(context: Context, dpValue: Float): Int {
        // 获取当前手机的像素密度（1个dp对应几个px）
        val scale = context.resources.displayMetrics.density
        return (dpValue * scale + 0.5f).toInt() // 四舍五入取整
    }

    // 根据手机的分辨率从 px(像素) 的单位 转成为 dp
    fun px2dip(context: Context, pxValue: Float): Int {
        // 获取当前手机的像素密度（1个dp对应几个px）
        val scale = context.resources.displayMetrics.density
        return (pxValue / scale + 0.5f).toInt() // 四舍五入取整
    }

}