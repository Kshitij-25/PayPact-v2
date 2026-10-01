class UserEntity {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;

  /// UPI address others can pay (shown in settle-up and as a QR code).
  final String? upiId;

  const UserEntity({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.upiId,
  });
}
