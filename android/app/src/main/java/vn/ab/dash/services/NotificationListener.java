package vn.ab.dash.services;

import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;

public class NotificationListener extends NotificationListenerService {
    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {}
    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {}
}
