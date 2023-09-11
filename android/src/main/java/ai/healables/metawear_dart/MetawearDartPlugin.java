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
import java.util.ArrayList;
import android.content.*;
import java.util.HashMap;
import java.util.UUID;

import com.mbientlab.metawear.MetaWearBoard;
import com.mbientlab.metawear.android.BtleService;
import bolts.Continuation;
import bolts.Task;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.BinaryMessenger;

/** MetawearDartPlugin */
public class MetawearDartPlugin
    implements FlutterPlugin, MethodCallHandler, ServiceConnection, ActivityAware {

  private MethodChannel channel;
  private EventChannel scanEvents;
  private StreamHandler scanEventsStreamHandler;

  private Context context;
  private Activity activity;

  private BtleService.LocalBinder serviceBinder;
  private BluetoothManager bluetoothManager;
  private BluetoothAdapter bluetoothAdapter;
  private BinaryMessenger messenger;

  private ArrayList<MetawearBoardChannel> devices = new ArrayList<>();
  private ArrayList<String> macAddresses = new ArrayList<>();

  public static final String TAG = "MetawearDartPlugin";
  public static final String NAMESPACE = "ai.healables.metawear_dart";

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    messenger = flutterPluginBinding.getBinaryMessenger();
    channel = new MethodChannel(messenger, NAMESPACE);
    channel.setMethodCallHandler(this);

    scanEvents = new EventChannel(messenger, NAMESPACE + "/scan");
    scanEventsStreamHandler = new StreamHandler(flutterPluginBinding.getApplicationContext());
    scanEvents.setStreamHandler(scanEventsStreamHandler);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("startScan")) {
      startScan(call, result);
    } else if (call.method.equals("stopScan")) {
      stopScan(call, result);
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
    context.unbindService(this);
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

  public void startScan(@NonNull MethodCall methodCall, @NonNull Result result) {

    if (bluetoothAdapter == null) {
      result.error("bluetooth_unavailable", "Bluetooth is not available", null);
      return;
    }

    if (!bluetoothAdapter.isEnabled()) {
      result.error("bluetooth_disabled", "Bluetooth is disabled", null);
      return;
    }

    devices.clear();
    macAddresses.clear();

    bluetoothAdapter.startLeScan(
        new UUID[] {
            MetaWearBoard.METAWEAR_GATT_SERVICE,
        },
        scanCallback);
    result.success(null);
  }

  public void stopScan(@NonNull MethodCall methodCall, @NonNull Result result) {
    bluetoothAdapter.stopLeScan(
        scanCallback);
    result.success(null);
  }

  private BluetoothAdapter.LeScanCallback scanCallback = new BluetoothAdapter.LeScanCallback() {

    @Override
    public void onLeScan(BluetoothDevice device, int rssi, byte[] scanRecord) {
      if (serviceBinder == null) {
        Log.d(TAG, "serviceBinder is null");
        return;
      }

      MetaWearBoard board = serviceBinder.getMetaWearBoard(device);
      if (board == null) {
        Log.d(TAG, "board is null");
        return;
      }

      String macAddress = board.getMacAddress();

      if (macAddresses.contains(macAddress)) {
        return;
      }

      MetawearBoardChannel channel = new MetawearBoardChannel(messenger, board, activity, context);
      devices.add(channel);
      macAddresses.add(macAddress);
      if (scanEventsStreamHandler == null) {
        Log.d(TAG, "scanEventsStreamHandler is null");
        scanEventsStreamHandler = new StreamHandler(context);
      }
      scanEventsStreamHandler.success(new HashMap<String, Object>() {
        {
          put("mac", macAddress);
          put("id", macAddress);
          // put("name", device.getName());
          put("rssi", rssi);
        }
      });

      return;
    };
  };

}
