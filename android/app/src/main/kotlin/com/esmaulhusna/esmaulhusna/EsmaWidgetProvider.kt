package com.esmaulhusna.esmaulhusna

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/// Esma-ül Hüsnâ ana ekran widget'ı. Son kalınan zikri gösterir ve
/// "+ Çek" ile ana ekrandan sayaç düşürmeyi sağlar.
class EsmaWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.esma_widget)

            val arabic = widgetData.getString("w_arabic", "الرَّحْمَنُ")
            val latin = widgetData.getString("w_latin", "Er-Rahman")
            val remaining = widgetData.getString("w_remaining", "—")
            val sub = widgetData.getString("w_sub", "kalan")
            val progress = widgetData.getString("w_progress", "0")?.toIntOrNull() ?: 0

            views.setTextViewText(R.id.w_arabic, arabic)
            views.setTextViewText(R.id.w_latin, latin)
            views.setTextViewText(R.id.w_remaining, remaining)
            views.setTextViewText(R.id.w_sub, sub)
            views.setProgressBar(R.id.w_progress, 100, progress, false)

            // "+ Çek": arka planda çalışan callback'i tetikler (uygulama açılmaz).
            val cekIntent = HomeWidgetBackgroundIntent.getBroadcast(
                context,
                Uri.parse("esmawidget://cek")
            )
            views.setOnClickPendingIntent(R.id.w_btn_cek, cekIntent)

            // Başlığa dokununca uygulamayı açar.
            val openIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("esmawidget://open")
            )
            views.setOnClickPendingIntent(R.id.w_header, openIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
