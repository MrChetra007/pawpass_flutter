import 'package:flutter_dotenv/flutter_dotenv.dart';

class Pet {
  final String id;
  final String userId;
  final String name;
  final String species;
  final String? breed;
  final String? gender;
  final DateTime? dob;
  final double? weightKg;
  final String? photoUrl;
  final String? color;
  final String? microchip;
  final bool neutered;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? shareToken;
  final bool isSharingEnabled;

  static const String sharePage = 'index.html';

  static String get shareBaseUrl {
    final envUrl = dotenv.env['SHARE_ROOT_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      // If envUrl doesn't end with html, append the page name
      if (envUrl.endsWith('.html')) return envUrl;
      return '$envUrl/$sharePage';
    }
    return 'https://pawpass.vercel.app/$sharePage';
  }

  Pet({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
    this.breed,
    this.gender,
    this.dob,
    this.weightKg,
    this.photoUrl,
    this.color,
    this.microchip,
    this.neutered = false,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.shareToken,
    this.isSharingEnabled = false,
  });

  factory Pet.fromJson(Map<String, dynamic> json) {
    return Pet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      species: json['species'] as String,
      breed: json['breed'] as String?,
      gender: json['gender'] as String?,
      dob: json['dob'] != null ? DateTime.parse(json['dob'] as String) : null,
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      photoUrl: json['photo_url'] as String?,
      color: json['color'] as String?,
      microchip: json['microchip'] as String?,
      neutered: json['neutered'] as bool? ?? false,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
      shareToken: json['share_token'] as String?,
      isSharingEnabled: json['is_sharing_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'species': species,
      if (breed != null) 'breed': breed,
      if (gender != null) 'gender': gender,
      if (dob != null) 'dob': dob!.toIso8601String().split('T').first,
      if (weightKg != null) 'weight_kg': weightKg,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (color != null) 'color': color,
      if (microchip != null) 'microchip': microchip,
      'neutered': neutered,
      if (notes != null) 'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (shareToken != null) 'share_token': shareToken,
      'is_sharing_enabled': isSharingEnabled,
    };
  }

  Pet copyWith({
    String? id,
    String? userId,
    String? name,
    String? species,
    String? breed,
    String? gender,
    DateTime? dob,
    double? weightKg,
    String? photoUrl,
    String? color,
    String? microchip,
    bool? neutered,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? shareToken,
    bool? isSharingEnabled,
  }) {
    return Pet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      weightKg: weightKg ?? this.weightKg,
      photoUrl: photoUrl ?? this.photoUrl,
      color: color ?? this.color,
      microchip: microchip ?? this.microchip,
      neutered: neutered ?? this.neutered,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shareToken: shareToken ?? this.shareToken,
      isSharingEnabled: isSharingEnabled ?? this.isSharingEnabled,
    );
  }

  String get shareLink {
    if (shareToken == null || shareToken!.isEmpty) return '';
    return '$shareBaseUrl?token=$shareToken';
  }

  String get ageString {
    if (dob == null) return 'Unknown';
    final now = DateTime.now();
    final years = now.year - dob!.year;
    final months = now.month - dob!.month;
    
    int totalMonths = years * 12 + months;
    if (now.day < dob!.day) totalMonths--;
    
    if (totalMonths < 1) {
      final days = now.difference(dob!).inDays;
      return '$days day${days == 1 ? '' : 's'}';
    } else if (totalMonths < 12) {
      return '$totalMonths month${totalMonths == 1 ? '' : 's'}';
    } else {
      final y = totalMonths ~/ 12;
      final m = totalMonths % 12;
      if (m == 0) return '$y year${y == 1 ? '' : 's'}';
      return '$y year${y == 1 ? '' : 's'}, $m month${m == 1 ? '' : 's'}';
    }
  }

  String get speciesEmoji {
    switch (species.toLowerCase()) {
      case 'dog':
        return '🐶';
      case 'cat':
        return '🐱';
      case 'rabbit':
        return '🐰';
      case 'bird':
        return '🐦';
      default:
        return '🐾';
    }
  }
}
