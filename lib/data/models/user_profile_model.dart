import 'package:hive_ce/hive.dart';

import '../../../domain/entities/user_profile.dart';
import '../local/hive_registry.dart';

/// Modelo persistible de [UserProfile] (caja singleton).
class UserProfileModel extends HiveObject {
  final String id;
  final String name;
  final int? age;
  final String? country;
  final String? address;

  UserProfileModel({
    required this.id,
    required this.name,
    required this.age,
    required this.country,
    required this.address,
  });

  factory UserProfileModel.fromEntity(UserProfile e) => UserProfileModel(
        id: e.id,
        name: e.name,
        age: e.age,
        country: e.country,
        address: e.address,
      );

  UserProfile toEntity() => UserProfile(
        id: id,
        name: name,
        age: age,
        country: country,
        address: address,
      );

  @override
  String toString() => 'UserProfileModel($id, "$name", age=$age)';
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
      age: fields[2] as int?,
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
      ..writeByte(2)
      ..write(obj.age)
      ..writeByte(3)
      ..write(obj.country)
      ..writeByte(4)
      ..write(obj.address);
  }
}
