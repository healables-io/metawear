enum DeviceModel {
  METADETECT,
  METAENV,
  METAHEALTH,
  METAMOTION_C,
  METAMOTION_R,
  METAMOTION_RL,
  METAMOTION_S,
  METATRACKER,
  METAWEAR_C,
  METAWEAR_CPRO,
  METAWEAR_R,
  METAWEAR_RG,
  METAWEAR_RPRO,
  unknown,
}

extension DeviceModelExtension on DeviceModel {
  DeviceModel fromString(String name) {
    for (var model in DeviceModel.values) {
      if (model.name == name) {
        return model;
      }
    }
    return DeviceModel.unknown;
  }

  DeviceModel fromId(int id) {
    for (var model in DeviceModel.values) {
      if (model.index + 1 == id) {
        return model;
      }
    }
    return DeviceModel.unknown;
  }
}

class DeviceInfo {
  String manufacturer;
  String modelNumber;
  String serialNumber;
  String firmwareRevision;
  String hardwareRevision;

  DeviceInfo({
    required this.manufacturer,
    required this.modelNumber,
    required this.serialNumber,
    required this.firmwareRevision,
    required this.hardwareRevision,
  });

  factory DeviceInfo.fromMap(Map<String, dynamic> map) {
    return DeviceInfo(
      manufacturer: map['manufacturer'],
      modelNumber: map['modelNumber'],
      serialNumber: map['serialNumber'],
      firmwareRevision: map['firmwareRevision'],
      hardwareRevision: map['hardwareRevision'],
    );
  }

  @override
  String toString() {
    return 'DeviceInfo{manufacturer: $manufacturer, modelNumber: $modelNumber, serialNumber: $serialNumber, firmwareRevision: $firmwareRevision, hardwareRevision: $hardwareRevision}';
  }
}
