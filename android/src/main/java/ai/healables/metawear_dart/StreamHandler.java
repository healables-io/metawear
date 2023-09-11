package ai.healables.metawear_dart;

import android.app.Activity;
import android.content.Context;
import io.flutter.plugin.common.EventChannel;
import android.util.Log;

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
    Log.d(MetawearDartPlugin.TAG, "success: " + data);
    if (sink != null) {
      sink.success(data);
    } else {
      Log.d(MetawearDartPlugin.TAG, "sink is null");
    }
  }

  public void error(String errorCode, String errorMessage, Object errorDetails) {
    Log.d(MetawearDartPlugin.TAG, "error: " + errorCode + " " + errorMessage + " " + errorDetails);

    if (sink != null) {
      sink.error(errorCode, errorMessage, errorDetails);
    } else {
      Log.d(MetawearDartPlugin.TAG, "sink is null");
    }
  }
}