/// One fleet tier — matches the public site's fleet page exactly. `value`
/// is what's sent as `vehicle_class_requested`; confirmed live against the
/// real API that it's accepted as free text (no server-side enum).
class VehicleClassOption {
  const VehicleClassOption({
    required this.value,
    required this.tagline,
    required this.passengers,
    required this.bags,
  });

  final String value;
  final String tagline;
  final int passengers;
  final int bags;

  String get subtitle => '$passengers passengers · $bags bags';
}

const vehicleClasses = [
  VehicleClassOption(value: 'Saloon', tagline: 'Comfortable & efficient', passengers: 3, bags: 3),
  VehicleClassOption(value: 'Estate', tagline: 'Family choice', passengers: 4, bags: 2),
  VehicleClassOption(value: 'Executive', tagline: 'Business class', passengers: 3, bags: 2),
  VehicleClassOption(value: 'MPV', tagline: 'Spacious 6-seater', passengers: 6, bags: 4),
  VehicleClassOption(
      value: '8-Seater Minibus', tagline: 'Group travel', passengers: 8, bags: 6),
];
