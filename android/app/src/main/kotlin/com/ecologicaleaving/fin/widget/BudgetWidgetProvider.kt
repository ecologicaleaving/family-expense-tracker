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
                // Parse JSON widget data (Feature 001: Updated to totalAmount + expenseCount)
                val widgetData = JSONObject(widgetDataJson)

                val totalAmount = widgetData.optDouble("totalAmount", 0.0)
                val expenseCount = widgetData.optInt("expenseCount", 0)
                val month = widgetData.optString("month", "")
                val currency = widgetData.optString("currency", "€")
                val isDarkMode = widgetData.optBoolean("isDarkMode", false)
                val hasError = widgetData.optBoolean("hasError", false)
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

                // Check if data is stale (>24 hours old)
                val now = System.currentTimeMillis()
                val dataAge = now - lastUpdated
                val isStale = dataAge > (24 * 60 * 60 * 1000) // 24 hours

                println("BudgetWidgetProvider: Widget data loaded - totalAmount: $totalAmount, count: $expenseCount, month: $month")

                // Use unified responsive layout
                val views = RemoteViews(context.packageName, R.layout.budget_widget)

                // Update widget content
                updateWidgetContent(
                    context,
                    views,
                    totalAmount,
                    expenseCount,
                    month,
                    currency,
                    lastUpdated,
                    hasError || isStale,
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

            // Show error message (Feature 001: Updated for new layout)
            views.setTextViewText(R.id.month_text, "Errore")
            views.setTextViewText(R.id.total_amount_text, errorMessage)
            views.setTextViewText(R.id.expense_count_text, "")
            views.setViewVisibility(R.id.error_indicator, android.view.View.VISIBLE)

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
            totalAmount: Double,
            expenseCount: Int,
            month: String,
            currency: String,
            lastUpdated: Long,
            hasError: Boolean,
            groupName: String?
        ) {
            // Format total amount (Feature 001: Italian number format)
            val totalFormatted = String.format(Locale.ITALIAN, "%s%.2f", currency, totalAmount)

            // Format expense count text
            val countText = if (expenseCount == 1) "1 spesa" else "$expenseCount spese"

            // Update text views
            views.setTextViewText(R.id.month_text, month)
            views.setTextViewText(R.id.total_amount_text, totalFormatted)
            views.setTextViewText(R.id.expense_count_text, countText)

            // Show/hide error indicator
            val errorVisibility = if (hasError) android.view.View.VISIBLE else android.view.View.GONE
            views.setViewVisibility(R.id.error_indicator, errorVisibility)

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
