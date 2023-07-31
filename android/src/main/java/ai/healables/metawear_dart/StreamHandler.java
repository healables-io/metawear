package ai.healables.metawear_dart;

import android.app.Activity;
import android.content.Context;
import io.flutter.plugin.common.EventChannel;

public class StreamHandler implements EventChannel.StreamHandler {
    private final Context context;

    private EventChannel.EventSink sink;

    public StreamHandler(Context context) {
        this.context = context;
    }

    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        sink = events;
    }

    @Override
    public void onCancel(Object arguments) {
        sink = null;
    }

    public void success(Object data) {
      sink.success(data);
    }

    public void error(String errorCode, String errorMessage, Object errorDetails) {
      sink.error(errorCode, errorMessage, errorDetails);
    }
}