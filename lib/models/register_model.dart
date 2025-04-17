import 'dart:convert';

RegisterResponse registerResponseFromJson(String str) =>
    RegisterResponse.fromJson(json.decode(str));

String registerResponseToJson(RegisterResponse data) =>
    json.encode(data.toJson());

class RegisterResponse {
  final String? message;
  final RegisterErrors? errors;

  RegisterResponse({this.message, this.errors});

  factory RegisterResponse.fromJson(Map<String, dynamic> json) =>
      RegisterResponse(
        message: json["message"],
        errors:
            json["errors"] == null
                ? null
                : RegisterErrors.fromJson(json["errors"]),
      );

  Map<String, dynamic> toJson() => {
    "message": message,
    "errors": errors?.toJson(),
  };
}

class RegisterErrors {
  final List<String>? name;
  final List<String>? email;
  final List<String>? password;

  RegisterErrors({this.name, this.email, this.password});

  factory RegisterErrors.fromJson(Map<String, dynamic> json) => RegisterErrors(
    name: json["name"] == null ? [] : List<String>.from(json["name"]),
    email: json["email"] == null ? [] : List<String>.from(json["email"]),
    password:
        json["password"] == null ? [] : List<String>.from(json["password"]),
  );

  Map<String, dynamic> toJson() => {
    "name": name == null ? [] : List<dynamic>.from(name!),
    "email": email == null ? [] : List<dynamic>.from(email!),
    "password": password == null ? [] : List<dynamic>.from(password!),
  };
}
