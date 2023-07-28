package ai.healables.metawear_dart;

import androidx.annotation.NonNull;
import android.content.ServiceConnection;
import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.ComponentName;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.os.IBinder;
import android.util.Log;

import com.mbientlab.metawear.MetaWearBoard;
import com.mbientlab.metawear.android.BtleService;
import bolts.Continuation;
import bolts.Task;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.BinaryMessenger;

/** MetawearDartPlugin */
public class MetawearDartPlugin
    implements FlutterPlugin, MethodCallHandler, ServiceConnection, ActivityAware {

  private MethodChannel channel;

  private Context context;
  private Activity activity;

  private BtleService.LocalBinder serviceBinder;
  private BluetoothManager bluetoothManager;
  private BluetoothAdapter bluetoothAdapter;
  private BinaryMessenger messenger;

  public static final String TAG = "MetawearDartPlugin";
  public static final String NAMESPACE = "ai.healables.metawear_dart";

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    messenger = flutterPluginBinding.getBinaryMessenger();
    channel = new MethodChannel(messenger, NAMESPACE);
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("connect")) {
      onMethodCallConnect(call, result);
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }

  @Override
  public void onServiceConnected(ComponentName name, IBinder service) {
    Log.d(TAG, "onServiceConnected");
    serviceBinder = (BtleService.LocalBinder) service;
  }

  @Override
  public void onServiceDisconnected(ComponentName name) {
    serviceBinder = null;
  }

  @Override
  public void onDetachedFromActivity() {
    activity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    Log.d(TAG, "onAttachedToActivity");
    activity = binding.getActivity();
    context = activity.getApplicationContext();
    activity.bindService(new Intent(context, BtleService.class), this, Context.BIND_AUTO_CREATE);
    bluetoothManager = (BluetoothManager) activity.getSystemService(Context.BLUETOOTH_SERVICE);
    bluetoothAdapter = bluetoothManager.getAdapter();

  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    activity = null;
  }

  public void onMethodCallConnect(@NonNull MethodCall methodCall, @NonNull Result result) {
    final String mac = (String) methodCall.argument("mac");
    BluetoothDevice device = bluetoothAdapter.getRemoteDevice(mac);
    final MetaWearBoard board = serviceBinder.getMetaWearBoard(device);
    board.connectAsync().continueWith(new Continuation<Void, Object>() {
      @Override
      public Object then(Task<Void> task) throws Exception {
        if (task.isFaulted()) {
          Log.d(TAG, "cannot connect");
          result.success(false);
        } else {
          Log.d(TAG, "connected");
          new MethodChannel(messenger, NAMESPACE + "/metawear/" +
              board.getMacAddress())
              .setMethodCallHandler(new MetawearBoardChannel(messenger, board, activity));
          result.success(true);
        }
        return null;
      }
    });

  }

}
