// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppConfigAdapter extends TypeAdapter<AppConfig> {
  @override
  final typeId = 0;

  @override
  AppConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AppConfig(
      themeMode: fields[0] == null ? 'system' : fields[0] as String,
      seedColorValue: fields[1] == null
          ? 0xFFB3261E
          : (fields[1] as num).toInt(),
      useDynamicColor: fields[2] == null ? false : fields[2] as bool,
      useBlackBackground: fields[3] == null ? false : fields[3] as bool,
      maxSoundCount: fields[4] == null ? 10 : (fields[4] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, AppConfig obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.themeMode)
      ..writeByte(1)
      ..write(obj.seedColorValue)
      ..writeByte(2)
      ..write(obj.useDynamicColor)
      ..writeByte(3)
      ..write(obj.useBlackBackground)
      ..writeByte(4)
      ..write(obj.maxSoundCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
