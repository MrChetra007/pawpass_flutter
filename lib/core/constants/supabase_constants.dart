class SupabaseConstants {
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static const String petPhotosBucket = 'pet-photos';
  static const String vetDocumentsBucket = 'vet-documents';

  static const List<String> validThemes = [
    'forest',
    'ocean',
    'blossom',
    'amber',
    'midnight',
    'lavender',
  ];

  static const List<String> validPlans = [
    'free',
    'pro',
    'family',
  ];

  static const List<String> petSpecies = [
    'Dog',
    'Cat',
    'Rabbit',
    'Bird',
    'Other',
  ];

  static const List<String> recordTypes = [
    'checkup',
    'surgery',
    'illness',
    'injury',
    'dental',
    'grooming',
    'lab_result',
    'other',
  ];

  static const List<String> appointmentTypes = [
    'vet',
    'grooming',
    'training',
    'other',
  ];

  static const List<String> appointmentStatuses = [
    'upcoming',
    'completed',
    'cancelled',
  ];

  static const List<String> medicationFrequencies = [
    'Daily',
    'Weekly',
    'Monthly',
    'As Needed',
    'Custom',
  ];
}
