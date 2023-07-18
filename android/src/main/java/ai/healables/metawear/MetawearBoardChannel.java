package ai.healables.metawear;

import android.app.Activity;

import com.mbientlab.metawear.DeviceInformation;
import com.mbientlab.metawear.MetaWearBoard;
import com.mbientlab.metawear.Observer;
import com.mbientlab.metawear.Route;
import com.mbientlab.metawear.module.Accelerometer;
import com.mbientlab.metawear.data.Quaternion;
import com.mbientlab.metawear.module.Settings;
import com.mbientlab.metawear.module.SensorFusionBosch;

import java.util.HashMap;

import bolts.Continuation;
import bolts.Task;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.BinaryMessenger;
import android.util.Log;

public class MetawearBoardChannel implements MethodChannel.MethodCallHandler {
    private final BinaryMessenger messenger;
    private final MetaWearBoard board;
    private final Activity activity;
    // private final MethodChannel moduleChannel;
    private final MethodChannel deviceChannel;

    private SensorFusionBosch sensor;

    public String getRootNamespace() {
        return MetawearPlugin.NAMESPACE + "/metawear/" + board.getMacAddress();
    }

    public MetaWearBoard getBoard() {
        return board;
    }

    private SensorFusionBosch getSensor() {
        if (this.sensor == null) {
            this.sensor = board.getModule(SensorFusionBosch.class);
            this.sensor.configure()
                    .mode(SensorFusionBosch.Mode.NDOF)
                    .accRange(SensorFusionBosch.AccRange.AR_16G)
                    .gyroRange(SensorFusionBosch.GyroRange.GR_2000DPS)
                    .commit();
        }
        return this.sensor;
    }

    public MetawearBoardChannel(final BinaryMessenger messenger, final MetaWearBoard board, final Activity activity) {
        this.messenger = messenger;
        this.board = board;
        this.activity = activity;

        board.onUnexpectedDisconnect(new MetaWearBoard.UnexpectedDisconnectHandler() {
            @Override
            public void disconnected(int status) {
                deviceChannel.invokeMethod("onDisconnect", null);
                clearHandlers();
            }
        });

        deviceChannel = new MethodChannel(messenger, getRootNamespace());
        deviceChannel.setMethodCallHandler(this);
        Log.d("Channel: ", getRootNamespace() + " :onCorrectedAcceleration");

        Log.d(MetawearPlugin.TAG, "Device channel created: " + getRootNamespace());
        // moduleChannel = new MethodChannel(registrar.messenger(), getRootNamespace() +
        // "/modules");
        // moduleChannel.setMethodCallHandler(new MetawearModuleChannel(registrar,
        // this));
    }

    private void clearHandlers() {
        messenger.setMessageHandler(getRootNamespace(), null);
        // registrar.messenger().setMessageHandler(getRootNamespace() + "/modules",
        // null);
    }

    @Override
    public void onMethodCall(final MethodCall methodCall, final MethodChannel.Result result) {
        final MetawearBoardChannel metawearChannel = this;
        Log.d(MetawearPlugin.TAG, "onMethodCall: " + methodCall.method + " " + methodCall.arguments);

        switch (methodCall.method) {
            case "disconnect": {
                Log.d(MetawearPlugin.TAG, "disconnect");
                board.disconnectAsync().continueWith(new Continuation<Void, Object>() {
                    @Override
                    public Object then(Task<Void> task) throws Exception {
                        result.success(true);
                        clearHandlers();
                        return null;
                    }
                });
            }
                break;
            case "model":
                result.success(board.getModel().toString());
                break;
            case "deviceInfo":
                board.readDeviceInformationAsync().continueWith(new Continuation<DeviceInformation, Object>() {
                    @Override
                    public Object then(Task<DeviceInformation> task) throws Exception {
                        final DeviceInformation deviceInformation = task.getResult();
                        result.success(new HashMap<String, Object>() {
                            {
                                put("manufacturer", deviceInformation.manufacturer);
                                put("model_number", deviceInformation.modelNumber);
                                put("serial_number", deviceInformation.serialNumber);
                                put("firmware_revision", deviceInformation.firmwareRevision);
                                put("hardware_revision", deviceInformation.hardwareRevision);
                            }
                        });
                        return null;
                    }
                });
                break;
            case "startCorrectedAcceleration":
                // sensor.resetOrientation();
                SensorFusionBosch s = this.getSensor();
                s.correctedAcceleration()
                        .addRouteAsync(source1 -> source1.stream((data, env) -> {
                            this.activity.runOnUiThread(new Runnable() {
                                @Override
                                public void run() {
                                    float x = data.value(SensorFusionBosch.CorrectedAcceleration.class).x();
                                    float y = data.value(SensorFusionBosch.CorrectedAcceleration.class).y();
                                    float z = data.value(SensorFusionBosch.CorrectedAcceleration.class).z();
                                    long time = data.timestamp().getTimeInMillis();
                                    deviceChannel.invokeMethod("onCorrectedAcceleration",
                                            new HashMap<String, Object>() {
                                                {
                                                    put("x", x);
                                                    put("y", y);
                                                    put("z", z);
                                                    put("time", time);
                                                }

                                            ;
                                            });

                                }
                            });
                        }));
                s.correctedAcceleration().start();
                s.start();
                result.success(true);
                break;
             case "startCorrectedAngularVelocity":
                s = this.getSensor();
                // sensor.resetOrientation();
                s.correctedAngularVelocity()
                        .addRouteAsync(source1 -> source1.stream((data, env) -> {

                            this.activity.runOnUiThread(new Runnable() {
                                @Override
                                public void run() {
                                    float x = data.value(SensorFusionBosch.CorrectedAngularVelocity.class).x();
                                    float y = data.value(SensorFusionBosch.CorrectedAngularVelocity.class).y();
                                    float z = data.value(SensorFusionBosch.CorrectedAngularVelocity.class).z();
                                    long time = data.timestamp().getTimeInMillis();
                                    deviceChannel.invokeMethod("onCorrectedAngularVelocity",
                                            new HashMap<String, Object>() {
                                                {
                                                    put("x", x);
                                                    put("y", y);
                                                    put("z", z);
                                                    put("time", time);
                                                }

                                            ;
                                            });

                                }
                            });
                        }));
                s.correctedAngularVelocity().start();
                s.start();
                result.success(true);
                break;
             case "startCorrectedMagneticField":
                s = this.getSensor();
                sensor.configure()
                        .mode(SensorFusionBosch.Mode.NDOF)
                        .accRange(SensorFusionBosch.AccRange.AR_16G)
                        .gyroRange(SensorFusionBosch.GyroRange.GR_2000DPS)
                        .commit();
                // sensor.resetOrientation();
                sensor.correctedMagneticField()
                        .addRouteAsync(source1 -> source1.stream((data, env) -> {

                            this.activity.runOnUiThread(new Runnable() {
                                @Override
                                public void run() {
                                    float x = data.value(SensorFusionBosch.CorrectedMagneticField.class).x();
                                    float y = data.value(SensorFusionBosch.CorrectedMagneticField.class).y();
                                    float z = data.value(SensorFusionBosch.CorrectedMagneticField.class).z();
                                    long time = data.timestamp().getTimeInMillis();
                                    deviceChannel.invokeMethod("onCorrectedMagneticField",
                                            new HashMap<String, Object>() {
                                                {
                                                    put("x", x);
                                                    put("y", y);
                                                    put("z", z);
                                                    put("time", time);
                                                }

                                            ;
                                            });

                                }
                            });
                        }));
                sensor.correctedMagneticField().start();
                sensor.start();
                result.success(true);
                break;
            case "startQuaternion":
                // sensor.resetOrientation();
                s = this.getSensor();
                s.quaternion()
                        .addRouteAsync(source1 -> source1.stream((data, env) -> {

                            this.activity.runOnUiThread(new Runnable() {
                                @Override
                                public void run() {
                                    float w = data.value(Quaternion.class).w();
                                    float x = data.value(Quaternion.class).x();
                                    float y = data.value(Quaternion.class).y();
                                    float z = data.value(Quaternion.class).z();
                                    long time = data.timestamp().getTimeInMillis();
                                    deviceChannel.invokeMethod("onQuaternion",
                                            new HashMap<String, Object>() {
                                                {
                                                    put("w", w);
                                                    put("x", x);
                                                    put("y", y);
                                                    put("z", z);
                                                    put("time", time);
                                                }

                                            ;
                                            });

                                }
                            });
                        }));
                s.quaternion().start();
                s.start();
                result.success(true);
                break;
          case "stop":
                s = this.getSensor();
                s.correctedAcceleration().stop();                
                s.correctedAngularVelocity().stop();
                s.correctedMagneticField().stop();
                s.quaternion().stop();
                s.stop();
                result.success(true);
                break;
        }
    }

    public interface MetawearDispose {
        void onDispose();
    }

}
