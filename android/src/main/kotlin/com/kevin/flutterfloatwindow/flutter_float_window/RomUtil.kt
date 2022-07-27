package com.kevin.flutterfloatwindow.flutter_float_window

import com.kevin.flutterfloatwindow.flutter_float_window.RomUtil
import android.text.TextUtils
import android.os.Build
import android.util.Log
import java.io.BufferedReader
import java.io.IOException
import java.io.InputStreamReader
import java.util.*

/**
 * Created by yy on 2020/6/13.
 * function: Rom类型
 */
object RomUtil {
    private const val TAG = "RomUtil"
    const val ROM_MIUI = "MIUI"
    const val ROM_EMUI = "EMUI"
    const val ROM_FLYME = "FLYME"
    const val ROM_OPPO = "OPPO"
    const val ROM_SMARTISAN = "SMARTISAN"
    const val ROM_VIVO = "VIVO"
    const val ROM_QIKU = "QIKU"
    const val ROM_LENOVO = "LENOVO"
    const val ROM_SAMSUNG = "SAMSUNG"
    const val ROM_EUI = "EUI"
    const val ROM_YULONG = "YULONG"
    const val ROM_AMIGO = "AmigoOS"
    private const val KEY_VERSION_MIUI = "ro.miui.ui.version.name"
    private const val KEY_VERSION_EMUI = "ro.build.version.emui"
    private const val KEY_VERSION_OPPO = "ro.build.version.opporom"
    private const val KEY_VERSION_SMARTISAN = "ro.smartisan.version"
    private const val KEY_VERSION_VIVO = "ro.vivo.os.version"

    // 乐视 : eui
    private const val KEY_EUI_VERSION = "ro.letv.release.version" // "5.9.023S"
    private const val KEY_EUI_VERSION_DATE = "ro.letv.release.version_date" // "5.9.023S_03111"
    private const val KEY_EUI_NAME = "ro.product.letv_name" // "乐1s"
    private const val KEY_EUI_MODEL = "ro.product.letv_model" // "Letv X500"

    // 金立 : amigo
    private const val KEY_AMIGO_ROM_VERSION = "ro.gn.gnromvernumber" // "GIONEE ROM5.0.16"
    private const val KEY_AMIGO_SYSTEM_UI_SUPPORT = "ro.gn.amigo.systemui.support" // "yes"

    // 酷派 : yulong
    private const val KEY_YULONG_VERSION_RELEASE =
        "ro.yulong.version.release" // "5.1.046.P1.150921.8676_M01"
    private const val KEY_YULONG_VERSION_TAG = "ro.yulong.version.tag" // "LC"
    val isEmui: Boolean
        get() = check(ROM_EMUI)
    val isMiui: Boolean
        get() = check(ROM_MIUI)
    val isVivo: Boolean
        get() = check(ROM_VIVO)
    val isOppo: Boolean
        get() = check(ROM_OPPO)
    val isFlyme: Boolean
        get() = check(ROM_FLYME)
    val isQiku: Boolean
        get() = check(ROM_QIKU) || check("360")
    val isSmartisan: Boolean
        get() = check(ROM_SMARTISAN)
    private var sName: String? = null
    val name: String?
        get() {
            if (sName == null) {
                check("")
            }
            return sName
        }
    private var sVersion: String? = null
    val version: String?
        get() {
            if (sVersion == null) {
                check("")
            }
            return sVersion
        }

    fun check(rom: String): Boolean {
        if (sName != null) {
            return sName == rom
        }
        if (!TextUtils.isEmpty(getProp(KEY_VERSION_MIUI).also { sVersion = it })) {
            sName = ROM_MIUI
        } else if (!TextUtils.isEmpty(getProp(KEY_VERSION_EMUI).also { sVersion = it })) {
            sName = ROM_EMUI
        } else if (!TextUtils.isEmpty(getProp(KEY_VERSION_OPPO).also { sVersion = it })) {
            sName = ROM_OPPO
        } else if (!TextUtils.isEmpty(getProp(KEY_VERSION_VIVO).also { sVersion = it })) {
            sName = ROM_VIVO
        } else if (!TextUtils.isEmpty(getProp(KEY_VERSION_SMARTISAN).also { sVersion = it })) {
            sName = ROM_SMARTISAN
        } else if (!TextUtils.isEmpty(getProp(KEY_AMIGO_ROM_VERSION).also {
                sVersion = it
            }) || !TextUtils.isEmpty(
                getProp(KEY_AMIGO_SYSTEM_UI_SUPPORT).also { sVersion = it })
        ) {
            // amigo
            sName = ROM_AMIGO
        } else if (!TextUtils.isEmpty(getProp(KEY_EUI_VERSION).also {
                sVersion = it
            }) || !TextUtils.isEmpty(
                getProp(KEY_EUI_NAME).also { sVersion = it }) || !TextUtils.isEmpty(
                getProp(
                    KEY_EUI_MODEL
                ).also { sVersion = it })
        ) {
            sName = ROM_EUI
        } else if (!TextUtils.isEmpty(getProp(KEY_YULONG_VERSION_RELEASE).also {
                sVersion = it
            }) || !TextUtils.isEmpty(
                getProp(KEY_YULONG_VERSION_TAG).also { sVersion = it })
        ) {
            sName = ROM_YULONG
        } else {
            sVersion = Build.DISPLAY
            if (sVersion!!.uppercase(Locale.getDefault()).contains(ROM_FLYME)) {
                sName = ROM_FLYME
            } else {
                sVersion = Build.UNKNOWN
                sName = Build.MANUFACTURER.uppercase(Locale.getDefault())
            }
        }
        return sName == rom
    }

    fun getProp(name: String): String? {
        var line: String? = null
        var input: BufferedReader? = null
        try {
            val p = Runtime.getRuntime().exec("getprop $name")
            input = BufferedReader(InputStreamReader(p.inputStream), 1024)
            line = input.readLine()
            input.close()
        } catch (ex: IOException) {
            Log.e(TAG, "Unable to read prop $name", ex)
            return null
        } finally {
            if (input != null) {
                try {
                    input.close()
                } catch (e: IOException) {
                    e.printStackTrace()
                }
            }
        }
        return line
    }
}