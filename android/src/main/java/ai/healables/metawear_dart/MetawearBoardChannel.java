package ai.healables.metawear_dart;

import android.app.Activity;
import android.content.Context;

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
import io.flutter.plugin.common.EventChannel;
import android.util.Log;

public class MetawearBoardChannel implements MethodChannel.MethodCallHandler {
    private final BinaryMessenger messenger;
    private final MetaWearBoard board;
    private final Activity activity;

    private final MethodChannel deviceChannel;
    private final StreamHandler stateHandler;

    private SensorFusionBosch sensor;

    private SensorFusionBosch getSensor(MethodCall methodCall) {
        if (this.sensor == null) {
            this.sensor = board.getModule(SensorFusionBosch.class);

            SensorFusionBosch.Mode mode = methodCall.argument("mode") == "IMU_PLUS" ? SensorFusionBosch.Mode.IMU_PLUS
                    : methodCall.argument("mode") == "COMPASS" ? SensorFusionBosch.Mode.COMPASS
                            : methodCall.argument("mode") == "M4G" ? SensorFusionBosch.Mode.M4G
                                    : methodCall.argument("mode") == "NDOF" ? SensorFusionBosch.Mode.NDOF
                                            : methodCall.argument("mode") == "SLEEP" ? SensorFusionBosch.Mode.SLEEP
                                                    : SensorFusionBosch.Mode.NDOF;
            SensorFusionBosch.AccRange accRange = methodCall.argument("accRange") == "AR_16G"
                    ? SensorFusionBosch.AccRange.AR_16G
                    : methodCall.argument("accRange") == "AR_8G" ? SensorFusionBosch.AccRange.AR_8G
                            : methodCall.argument("accRange") == "AR_4G" ? SensorFusionBosch.AccRange.AR_4G
                                    : methodCall.argument("accRange") == "AR_2G" ? SensorFusionBosch.AccRange.AR_2G
                                            : SensorFusionBosch.AccRange.AR_16G;
            SensorFusionBosch.GyroRange gyroRange = methodCall.argument("gyroRange") == "GR_2000DPS"
                    ? SensorFusionBosch.GyroRange.GR_2000DPS
                    : methodCall.argument("gyroRange") == "GR_1000DPS" ? SensorFusionBosch.GyroRange.GR_1000DPS
                            : methodCall.argument("gyroRange") == "GR_500DPS" ? SensorFusionBosch.GyroRange.GR_500DPS
                                    : methodCall.argument("gyroRange") == "GR_250DPS"
                                            ? SensorFusionBosch.GyroRange.GR_250DPS
                                            : SensorFusionBosch.GyroRange.GR_2000DPS;

            this.sensor.configure()
                    .mode(mode)
                    .accRange(accRange)
                    .gyroRange(gyroRange)
                    .commit();
        }
        return this.sensor;
    }

    public MetawearBoardChannel(
            final BinaryMessenger messenger,
            final MetaWearBoard board,
            final Activity activity,
            final Context context) {
        this.messenger = messenger;
        this.board = board;
        this.activity = activity;

        board.onUnexpectedDisconnect(new MetaWearBoard.UnexpectedDisconnectHandler() {
            @Override
            public void disconnected(int status) {
                stateHandler.success(
                        new HashMap<String, Object>() {
                            {
                                put("connected", false);
                                put("reason", "disconnected");
                            }
                        });
                clearHandlers();
            }
        });

        deviceChannel = new MethodChannel(messenger, getRootNamespace());
        deviceChannel.setMethodCallHandler(this);

        Log.d(MetawearDartPlugin.TAG, "MetawearBoardChannel: " + getRootNamespace());

        stateHandler = new StreamHandler(context);
        new EventChannel(messenger, getRootNamespace() + "/state").setStreamHandler(stateHandler);
    }

    public String getRootNamespace() {
        return MetawearDartPlugin.NAMESPACE + "/metawear/" + board.getMacAddress();
    }

    public MetaWearBoard getBoard() {
        return board;
    }

    private void clearHandlers() {
        messenger.setMessageHandler(getRootNamespace(), null);
        // registrar.messenger().setMessageHandler(getRootNamespace() + "/modules",
        // null);
    }

    @Override
    public void onMethodCall(final MethodCall methodCall, final MethodChannel.Result result) {
        final MetawearBoardChannel metawearChannel = this;
        Log.d(MetawearDartPlugin.TAG, "onMethodCall: " + methodCall.method + " " + methodCall.arguments);

        switch (methodCall.method) {
            case "connect": {
                Log.d(MetawearDartPlugin.TAG, "connect");
                board.connectAsync().continueWith(new Continuation<Void, Object>() {
                    @Override
                    public Object then(Task<Void> task) throws Exception {
                        if (task.isFaulted()) {
                            result.error("connect", task.getError().getMessage(), null);
                        } else {
                            stateHandler.success(
                                    new HashMap<String, Object>() {
                                        {
                                            put("connected", true);
                                        }
                                    });
                            result.success(true);
                        }
                        return null;
                    }
                });
            }
                break;
            case "disconnect": {
                Log.d(MetawearDartPlugin.TAG, "disconnect");
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
                                put("modelNumber", deviceInformation.modelNumber);
                                put("serialNumber", deviceInformation.serialNumber);
                                put("firmwareRevision", deviceInformation.firmwareRevision);
                                put("hardwareRevision", deviceInformation.hardwareRevision);
                            }
                        });
                        return null;
                    }
                });
                break;
            case "battery":
                board.readBatteryLevelAsync().continueWith(new Continuation<Byte, Object>() {
                    @Override
                    public Object then(Task<Byte> task) throws Exception {
                        result.success(task.getResult());
                        return null;
                    }
                });
                break;
            case "startCorrectedAcceleration":
                SensorFusionBosch s = this.getSensor(methodCall);
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
                s = this.getSensor(methodCall);
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
                s = this.getSensor(methodCall);
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
                s = this.getSensor(methodCall);
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
                s = this.getSensor(methodCall);
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
