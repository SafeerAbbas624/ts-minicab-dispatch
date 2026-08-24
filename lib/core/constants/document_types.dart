/// Confirmed live (validation error from a deliberately-invalid
/// document_type surfaced the full enum): phv_licence | insurance | dbs |
/// mot | other | driving_licence | vehicle_photo | driver_photo |
/// tfl_pco_badge.
const documentTypeLabels = {
  'phv_licence': 'PHV Licence',
  'insurance': 'Insurance',
  'dbs': 'DBS Check',
  'mot': 'MOT',
  'driving_licence': 'Driver Licence',
  'vehicle_photo': 'Car Picture',
  'driver_photo': 'Driver Picture',
  'tfl_pco_badge': 'TfL PCO Badge',
  'other': 'Other',
};

String documentTypeLabel(String type) => documentTypeLabels[type] ?? type;
