package com.ecologicaleaving.fin.widget

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import androidx.work.Worker
import androidx.work.WorkerParameters

/**
 * WorkManager worker for periodic widget updates in the background
 */
class WidgetUpdateWorker(
    context: Context,
    workerParams: WorkerParameters
) : Worker(context, workerParams) {

    override fun doWork(): Result {
        return try {
            // Get all widget IDs
            val appWidgetManager = AppWidgetManager.getInstance(applicationContext)
            val widgetComponent = ComponentName(applicationContext, BudgetWidgetProvider::class.java)
            val widgetIds = appWidgetManager.getAppWidgetIds(widgetComponent)

            // Update all widgets
            if (widgetIds.isNotEmpty()) {
                for (widgetId in widgetIds) {
                    BudgetWidgetProvider.updateAppWidget(
                        applicationContext,
                        appWidgetManager,
                        widgetId
                    )
                }
            }

            Result.success()
        } catch (e: Exception) {
            // Log error and retry
            println("Widget update worker failed: ${e.message}")
            Result.retry()
        }
    }
}
