package vn.ab.dash.plugins;

import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.JSObject;
import android.media.session.MediaSessionManager;
import android.media.session.MediaController;
import android.media.MediaMetadata;
import android.media.session.PlaybackState;
import android.content.ComponentName;
import android.content.Context;
import android.graphics.Bitmap;
import android.util.Base64;
import java.io.ByteArrayOutputStream;
import java.util.List;
import vn.ab.dash.services.NotificationListener;
import android.util.Log;

@CapacitorPlugin(name = "MediaControl")
public class MediaControlPlugin extends Plugin {

    private MediaController getActiveController() {
        MediaSessionManager msm = (MediaSessionManager) getContext().getSystemService(Context.MEDIA_SESSION_SERVICE);
        if (msm != null) {
            try {
                List<MediaController> controllers = msm.getActiveSessions(new ComponentName(getContext(), NotificationListener.class));
                if (controllers != null && !controllers.isEmpty()) {
                    return controllers.get(0);
                }
            } catch (Exception e) {
                Log.e("MediaControlPlugin", "Error getting active sessions", e);
            }
        }
        return null;
    }

    private String bitmapToBase64(Bitmap bitmap) {
        if (bitmap == null) return "";
        try {
            // Scale down for performance (max 120px)
            int maxSize = 120;
            float scale = Math.min((float) maxSize / bitmap.getWidth(), (float) maxSize / bitmap.getHeight());
            int w = Math.round(bitmap.getWidth() * scale);
            int h = Math.round(bitmap.getHeight() * scale);
            Bitmap scaled = Bitmap.createScaledBitmap(bitmap, w, h, true);

            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            scaled.compress(Bitmap.CompressFormat.JPEG, 70, baos);
            byte[] bytes = baos.toByteArray();
            return "data:image/jpeg;base64," + Base64.encodeToString(bytes, Base64.NO_WRAP);
        } catch (Exception e) {
            return "";
        }
    }

    @PluginMethod
    public void getPlayingInfo(PluginCall call) {
        JSObject ret = new JSObject();
        ret.put("title", "");
        ret.put("artist", "");
        ret.put("album", "");
        ret.put("albumArt", "");
        ret.put("packageName", "");
        ret.put("isPlaying", false);

        MediaController controller = getActiveController();
        if (controller != null) {
            // Get package name (spotify, youtube music, etc.)
            String pkg = controller.getPackageName();
            ret.put("packageName", pkg != null ? pkg : "");

            MediaMetadata metadata = controller.getMetadata();
            if (metadata != null) {
                String title = metadata.getString(MediaMetadata.METADATA_KEY_TITLE);
                String artist = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST);
                String album = metadata.getString(MediaMetadata.METADATA_KEY_ALBUM);

                ret.put("title", title != null ? title : "");
                ret.put("artist", artist != null ? artist : "");
                ret.put("album", album != null ? album : "");

                // Get album art
                Bitmap art = metadata.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART);
                if (art == null) {
                    art = metadata.getBitmap(MediaMetadata.METADATA_KEY_ART);
                }
                if (art == null) {
                    art = metadata.getBitmap(MediaMetadata.METADATA_KEY_DISPLAY_ICON);
                }
                ret.put("albumArt", bitmapToBase64(art));
            }

            PlaybackState pbState = controller.getPlaybackState();
            if (pbState != null) {
                boolean isPlaying = pbState.getState() == PlaybackState.STATE_PLAYING;
                ret.put("isPlaying", isPlaying);
            }
        }

        call.resolve(ret);
    }

    @PluginMethod
    public void play(PluginCall call) {
        MediaController controller = getActiveController();
        if (controller != null && controller.getTransportControls() != null) {
            controller.getTransportControls().play();
        }
        call.resolve();
    }

    @PluginMethod
    public void pause(PluginCall call) {
        MediaController controller = getActiveController();
        if (controller != null && controller.getTransportControls() != null) {
            controller.getTransportControls().pause();
        }
        call.resolve();
    }

    @PluginMethod
    public void next(PluginCall call) {
        MediaController controller = getActiveController();
        if (controller != null && controller.getTransportControls() != null) {
            controller.getTransportControls().skipToNext();
        }
        call.resolve();
    }

    @PluginMethod
    public void prev(PluginCall call) {
        MediaController controller = getActiveController();
        if (controller != null && controller.getTransportControls() != null) {
            controller.getTransportControls().skipToPrevious();
        }
        call.resolve();
    }
}
