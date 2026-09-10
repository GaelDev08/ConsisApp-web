import 'package:hive_ce/hive.dart';

import '../../../domain/entities/user_profile.dart';
import '../local/hive_registry.dart';

/// Modelo persistible de [UserProfile] (caja singleton).
class UserProfileModel extends HiveObject {
  final String id;
  final String name;
  final DateTime? birthdate;
  final String? country;
  final String? address;

  UserProfileModel({
    required this.id,
    required this.name,
    this.birthdate,
    required this.country,
    required this.address,
  });

  factory UserProfileModel.fromEntity(UserProfile e) => UserProfileModel(
        id: e.id,
        name: e.name,
        birthdate: e.birthdate,
        country: e.country,
        address: e.address,
      );

  UserProfile toEntity() => UserProfile(
        id: id,
        name: name,
        birthdate: birthdate,
        country: country,
        address: address,
      );

  @override
  String toString() => 'UserProfileModel($id, "$name", birthdate=$birthdate)';
}

/// TypeAdapter manual (sin build_runner).
class UserProfileModelAdapter extends TypeAdapter<UserProfileModel> {
  @override
  final int typeId = BoxTypeIds.userProfile;

  @override
  UserProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfileModel(
      id: fields[0] as String? ?? '',
      name: fields[1] as String? ?? '',
      birthdate: fields[5] as DateTime?,
      country: fields[3] as String?,
      address: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfileModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.country)
      ..writeByte(4)
      ..write(obj.address)
      ..writeByte(5)
      ..write(obj.birthdate);
  }
}
