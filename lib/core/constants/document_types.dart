/// Every document type the backend accepts. Labels match the backend's own
/// (lib/compliance.ts) so emails, the app and the admin panel agree.
const documentTypeLabels = {
  'driver_photo': 'Driver photo',
  'driving_licence': 'Driving licence (front)',
  'driving_licence_back': 'Driving licence (back)',
  'tfl_pco_badge': 'TfL PCO badge',
  'phv_licence': 'PHV driver licence',
  'dbs': 'DBS certificate',
  'vehicle_photo': 'Vehicle photo',
  'mot': 'MOT certificate',
  'insurance': 'Hire & reward insurance',
  'phv_vehicle_licence': 'PHV vehicle licence',
  'v5c_logbook': 'V5C logbook',
  'permission_letter': 'Vehicle permission letter',
  'other': 'Other',
};

String documentTypeLabel(String type) => documentTypeLabels[type] ?? type;

/// Required before a driver can be approved. The permission letter is only
/// required when the driver doesn't own the vehicle.
const requiredDocumentTypes = [
  'driver_photo',
  'driving_licence',
  'driving_licence_back',
  'tfl_pco_badge',
  'vehicle_photo',
  'mot',
  'insurance',
  'phv_vehicle_licence',
  'v5c_logbook',
];

/// Optional uploads shown below the required ones.
const optionalDocumentTypes = ['phv_licence', 'dbs'];

/// These carry an expiry date — the backend rejects uploads without one.
/// Photos, the V5C and the permission letter don't expire.
const expiringDocumentTypes = {
  'driving_licence',
  'tfl_pco_badge',
  'phv_licence',
  'mot',
  'insurance',
  'phv_vehicle_licence',
  'dbs',
};

bool documentTypeExpires(String type) => expiringDocumentTypes.contains(type);
