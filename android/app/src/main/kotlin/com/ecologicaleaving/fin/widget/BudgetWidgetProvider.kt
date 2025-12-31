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
        // Enter relevant functionality for when the first widget is created
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

            // Check if widget data exists
            val hasData = prefs.contains("flutter.spent")

            if (!hasData) {
                // Show error state: no data configured
                showErrorState(context, appWidgetManager, appWidgetId, "Budget non configurato")
                return
            }

            val spent = prefs.getFloat("flutter.spent", 0f).toDouble()
            val limit = prefs.getFloat("flutter.limit", 800f).toDouble()
            val month = prefs.getString("flutter.month", "")
            val percentage = prefs.getFloat("flutter.percentage", 0f).toDouble()
            val currency = prefs.getString("flutter.currency", "€")
            val isDarkMode = prefs.getBoolean("flutter.isDarkMode", false)
            val lastUpdated = prefs.getLong("flutter.lastUpdated", 0L)
            val groupName = prefs.getString("flutter.groupName", null)

            // Check if data is stale (>24 hours old)
            val now = System.currentTimeMillis()
            val dataAge = now - lastUpdated
            val isStale = dataAge > (24 * 60 * 60 * 1000) // 24 hours

            if (isStale && lastUpdated > 0) {
                // Show error state: stale data
                showErrorState(context, appWidgetManager, appWidgetId, "Dati non aggiornati")
                return
            }

            // Determine widget size and select appropriate layout
            val views = getRemoteViewsForSize(context, appWidgetManager, appWidgetId)

            // Update widget content
            updateWidgetContent(
                context,
                views,
                spent,
                limit,
                month ?: "",
                percentage,
                currency ?: "€",
                lastUpdated,
                groupName
            )

            // Set up click handlers
            setupClickHandlers(context, views)

            // Instruct the widget manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        private fun showErrorState(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            errorMessage: String
        ) {
            val views = RemoteViews(context.packageName, R.layout.budget_widget_medium)

            // Hide normal content and show error message
            try {
                views.setTextViewText(R.id.month_text, "Errore")
                views.setTextViewText(R.id.spent_text, errorMessage)
                views.setTextViewText(R.id.percentage_text, "")
                views.setProgressBar(R.id.budget_progress, 100, 0, false)
            } catch (e: Exception) {
                // Fallback for small layout
                views.setTextViewText(R.id.budget_summary, errorMessage)
            }

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

        private fun getRemoteViewsForSize(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ): RemoteViews {
            // Get widget size
            val options = appWidgetManager.getAppWidgetOptions(appWidgetId)
            val width = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)
            val height = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)

            // Determine layout based on size
            // Small: 2x2 (< 180dp width)
            // Medium: 4x2 (180-360dp width, < 180dp height)
            // Large: 4x4 (> 180dp height)
            val layoutId = when {
                height >= 180 -> R.layout.budget_widget_large
                width >= 180 -> R.layout.budget_widget_medium
                else -> R.layout.budget_widget_small
            }

            return RemoteViews(context.packageName, layoutId)
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

            // Update based on layout (different layouts have different views)
            try {
                // Try to update full amounts (medium/large layouts)
                views.setTextViewText(R.id.spent_text, spentFormatted)
                views.setTextViewText(R.id.limit_text, limitFormatted)
            } catch (e: Exception) {
                // Small layout: use combined budget_summary
                val budgetSummary = "$spentFormatted / $limitFormatted"
                views.setTextViewText(R.id.budget_summary, budgetSummary)
            }

            // Update progress bar
            views.setProgressBar(R.id.budget_progress, 100, percentageInt, false)

            // Update progress bar color based on percentage
            val progressColor = when {
                percentageInt >= 100 -> R.color.widget_progress_critical
                percentageInt >= 80 -> R.color.widget_progress_warning
                else -> R.color.widget_progress_normal
            }
            views.setInt(R.id.budget_progress, "setProgressTintList",
                context.getColor(progressColor))

            // Update last updated text
            val lastUpdatedText = formatLastUpdated(lastUpdated)
            views.setTextViewText(R.id.last_updated_text, lastUpdatedText)

            // Update group name (large layout only)
            try {
                if (!groupName.isNullOrEmpty()) {
                    views.setTextViewText(R.id.group_name_text, groupName)
                    views.setViewVisibility(R.id.group_name_text, android.view.View.VISIBLE)
                }
            } catch (e: Exception) {
                // Group name view doesn't exist in this layout
            }
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

            try {
                views.setOnClickPendingIntent(R.id.budget_display_container, dashboardPendingIntent)
            } catch (e: Exception) {
                // Small widget doesn't have budget_display_container
                views.setOnClickPendingIntent(R.id.widget_container, dashboardPendingIntent)
            }

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
