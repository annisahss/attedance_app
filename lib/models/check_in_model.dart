import 'dart:convert';

CheckInResponse checkInResponseFromJson(String str) =>
    CheckInResponse.fromJson(json.decode(str));

String checkInResponseToJson(CheckInResponse data) =>
    json.encode(data.toJson());

class CheckInResponse {
  final String? message;
  final CheckInData? data;

  CheckInResponse({this.message, this.data});

  factory CheckInResponse.fromJson(Map<String, dynamic> json) =>
      CheckInResponse(
        message: json["message"],
        data: json["data"] == null ? null : CheckInData.fromJson(json["data"]),
      );

  Map<String, dynamic> toJson() => {"message": message, "data": data?.toJson()};
}

class CheckInData {
  final int? userId;
  final DateTime? checkIn;
  final String? checkInLocation;
  final double? checkInLat;
  final double? checkInLng;
  final String? checkInAddress;
  final String? status;
  final dynamic alasanIzin;
  final DateTime? updatedAt;
  final DateTime? createdAt;
  final int? id;

  CheckInData({
    this.userId,
    this.checkIn,
    this.checkInLocation,
    this.checkInLat,
    this.checkInLng,
    this.checkInAddress,
    this.status,
    this.alasanIzin,
    this.updatedAt,
    this.createdAt,
    this.id,
  });

  factory CheckInData.fromJson(Map<String, dynamic> json) => CheckInData(
    userId: json["user_id"],
    checkIn: json["check_in"] == null ? null : DateTime.parse(json["check_in"]),
    checkInLocation: json["check_in_location"],
    checkInLat: json["check_in_lat"]?.toDouble(),
    checkInLng: json["check_in_lng"]?.toDouble(),
    checkInAddress: json["check_in_address"],
    status: json["status"],
    alasanIzin: json["alasan_izin"],
    updatedAt:
        json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    createdAt:
        json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "check_in": checkIn?.toIso8601String(),
    "check_in_location": checkInLocation,
    "check_in_lat": checkInLat,
    "check_in_lng": checkInLng,
    "check_in_address": checkInAddress,
    "status": status,
    "alasan_izin": alasanIzin,
    "updated_at": updatedAt?.toIso8601String(),
    "created_at": createdAt?.toIso8601String(),
    "id": id,
  };
}
