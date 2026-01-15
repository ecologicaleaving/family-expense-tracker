package com.ecologicaleaving.fin.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import com.ecologicaleaving.fin.MainActivity
import com.ecologicaleaving.fin.R
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

/**
 * Implementation of App Widget functionality for Budget Home Screen Widget
 */
class BudgetWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // Update all widgets
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Notify Flutter that widget was added to home screen
        println("BudgetWidgetProvider: Widget enabled, sending broadcast")
        val intent = Intent("com.ecologicaleaving.fin.WIDGET_ENABLED")
        intent.setPackage(context.packageName)
        context.sendBroadcast(intent)
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }

    companion object {
        private const val SHARED_PREFS = "FlutterSharedPreferences"

        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // Get widget data from shared preferences
            val prefs = context.getSharedPreferences(SHARED_PREFS, Context.MODE_PRIVATE)

            // Check if widget data exists - now looking for JSON object
            val widgetDataJson = prefs.getString("flutter.widget_data", null)

            if (widgetDataJson == null) {
                // Show error state: no data configured
                println("BudgetWidgetProvider: No widget data found in SharedPreferences")
                showErrorState(context, appWidgetManager, appWidgetId, "Budget non configurato")
                return
            }

            try {
                // Parse JSON widget data
                val widgetData = JSONObject(widgetDataJson)

                val spent = widgetData.optDouble("spent", 0.0)
                val limit = widgetData.optDouble("limit", 800.0)
                val month = widgetData.optString("month", "")
                val currency = widgetData.optString("currency", "€")
                val isDarkMode = widgetData.optBoolean("isDarkMode", false)
                val groupName = widgetData.optString("groupName", null)

                // Parse lastUpdated from ISO8601 string to timestamp
                val lastUpdatedString = widgetData.optString("lastUpdated", "")
                val lastUpdated = if (lastUpdatedString.isNotEmpty()) {
                    try {
                        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSS", Locale.US).parse(lastUpdatedString)?.time ?: 0L
                    } catch (e: Exception) {
                        println("BudgetWidgetProvider: Error parsing lastUpdated: ${e.message}")
                        0L
                    }
                } else {
                    0L
                }

                // Calculate percentage
                val percentage = if (limit > 0) (spent / limit * 100) else 0.0

                // Check if data is stale (>24 hours old)
                val now = System.currentTimeMillis()
                val dataAge = now - lastUpdated
                val isStale = dataAge > (24 * 60 * 60 * 1000) // 24 hours

                if (isStale && lastUpdated > 0) {
                    // Show error state: stale data
                    println("BudgetWidgetProvider: Data is stale (${dataAge / 1000}s old)")
                    showErrorState(context, appWidgetManager, appWidgetId, "Dati non aggiornati")
                    return
                }

                println("BudgetWidgetProvider: Widget data loaded - spent: $spent, limit: $limit, month: $month")

                // Use unified responsive layout
                val views = RemoteViews(context.packageName, R.layout.budget_widget)

                // Update widget content
                updateWidgetContent(
                    context,
                    views,
                    spent,
                    limit,
                    month,
                    percentage,
                    currency,
                    lastUpdated,
                    groupName
                )

                // Set up click handlers
                setupClickHandlers(context, views)

                // Instruct the widget manager to update the widget
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                println("BudgetWidgetProvider: Error parsing widget data: ${e.message}")
                showErrorState(context, appWidgetManager, appWidgetId, "Errore lettura dati")
                return
            }
        }

        private fun showErrorState(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            errorMessage: String
        ) {
            val views = RemoteViews(context.packageName, R.layout.budget_widget)

            // Hide normal content and show error message
            views.setTextViewText(R.id.month_text, "Errore")
            views.setTextViewText(R.id.spent_text, errorMessage)
            views.setTextViewText(R.id.percentage_text, "")
            views.setProgressBar(R.id.budget_progress, 100, 0, false)

            // Add tap to open app
            val openAppIntent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val openAppPendingIntent = PendingIntent.getActivity(
                context,
                0,
                openAppIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_container, openAppPendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }


        private fun updateWidgetContent(
            context: Context,
            views: RemoteViews,
            spent: Double,
            limit: Double,
            month: String,
            percentage: Double,
            currency: String,
            lastUpdated: Long,
            groupName: String?
        ) {
            // Format amounts
            val spentFormatted = "$currency%.2f".format(spent)
            val limitFormatted = "$currency%.0f".format(limit)
            val percentageInt = percentage.toInt()

            // Update text views
            views.setTextViewText(R.id.month_text, month)
            views.setTextViewText(R.id.percentage_text, "$percentageInt%")
            views.setTextViewText(R.id.spent_text, spentFormatted)
            views.setTextViewText(R.id.limit_text, limitFormatted)

            // Update progress bar
            views.setProgressBar(R.id.budget_progress, 100, percentageInt, false)

            // Note: Cannot dynamically change progress bar color with RemoteViews
            // The color is set statically in the layout XML

            // Update last updated text
            val lastUpdatedText = formatLastUpdated(lastUpdated)
            views.setTextViewText(R.id.last_updated_text, lastUpdatedText)
        }

        private fun setupClickHandlers(context: Context, views: RemoteViews) {
            // Dashboard click (tap on budget display)
            val dashboardIntent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("finapp://dashboard")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val dashboardPendingIntent = PendingIntent.getActivity(
                context,
                0,
                dashboardIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.budget_display_container, dashboardPendingIntent)

            // Scan button click
            val scanIntent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("finapp://scan-receipt")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val scanPendingIntent = PendingIntent.getActivity(
                context,
                1,
                scanIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.scan_button, scanPendingIntent)

            // Manual entry button click
            val manualIntent = Intent(Intent.ACTION_VIEW).apply {
                data = Uri.parse("finapp://add-expense")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val manualPendingIntent = PendingIntent.getActivity(
                context,
                2,
                manualIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.manual_button, manualPendingIntent)
        }

        private fun formatLastUpdated(timestamp: Long): String {
            if (timestamp == 0L) return "Mai aggiornato"

            val now = System.currentTimeMillis()
            val diff = now - timestamp
            val minutes = diff / (1000 * 60)
            val hours = minutes / 60

            return when {
                minutes < 1 -> "Aggiornato ora"
                minutes < 60 -> "Aggiornato $minutes min fa"
                hours < 24 -> "Aggiornato $hours ore fa"
                else -> {
                    val dateFormat = SimpleDateFormat("dd/MM HH:mm", Locale.ITALIAN)
                    "Agg. ${dateFormat.format(Date(timestamp))}"
                }
            }
        }
    }
}
