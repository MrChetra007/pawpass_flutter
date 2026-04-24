import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../data/models/pet_model.dart';

class PetIdCardWidget extends StatelessWidget {
  final Pet pet;
  final GlobalKey? cardKey;

  const PetIdCardWidget({
    super.key,
    required this.pet,
    this.cardKey,
  });

  String get _ageLabel {
    if (pet.dob == null) return '';
    final months = DateTime.now().difference(pet.dob!).inDays ~/ 30;
    if (months < 1) return '< 1 mo';
    if (months < 12) return '$months mo';
    final y = months ~/ 12;
    final m = months % 12;
    return m == 0 ? '${y}y' : '${y}y ${m}m';
  }

  String get _speciesEmoji {
    switch (pet.species.toLowerCase()) {
      case 'dog':
        return '🐶';
      case 'cat':
        return '🐱';
      case 'rabbit':
        return '🐰';
      case 'bird':
        return '🐦';
      case 'fish':
        return '🐟';
      default:
        return '🐾';
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: cardKey,
      child: AspectRatio(
        aspectRatio: 85.6 / 54,
        child: LayoutBuilder(
          builder: (_, box) {
            final w = box.maxWidth;
            final s = w / 342;

            return ClipRRect(
              borderRadius: BorderRadius.circular(12 * s),
              child: Stack(
                children: [
                  _Background(w: w, h: box.maxHeight, s: s),
                  Positioned(
                    right: -18 * s,
                    top: -18 * s,
                    child: Opacity(
                      opacity: 0.06,
                      child: Icon(Icons.pets, size: 160 * s, color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(14 * s, 12 * s, 14 * s, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TopBar(pet: pet, s: s, speciesEmoji: _speciesEmoji),
                        SizedBox(height: 10 * s),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Photo(pet: pet, s: s, speciesEmoji: _speciesEmoji),
                              SizedBox(width: 12 * s),
                              Expanded(child: _InfoBlock(pet: pet, s: s, ageLabel: _ageLabel)),
                              SizedBox(width: 8 * s),
                              if (pet.isSharingEnabled && pet.shareLink.isNotEmpty)
                                _QrBlock(pet: pet, s: s),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _BottomStrip(pet: pet, s: s),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  final double w, h, s;
  const _Background({required this.w, required this.h, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w,
      height: h,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A3A8F), Color(0xFF2563EB), Color(0xFF3B82F6)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: CustomPaint(painter: _CirclesPainter(s: s)),
    );
  }
}

class _CirclesPainter extends CustomPainter {
  final double s;
  const _CirclesPainter({required this.s});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.04);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.25), 80 * s, paint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.85), 55 * s, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

class _TopBar extends StatelessWidget {
  final Pet pet;
  final double s;
  final String speciesEmoji;
  const _TopBar({required this.pet, required this.s, required this.speciesEmoji});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.pets, color: Colors.white, size: 11 * s),
        SizedBox(width: 4 * s),
        Text(
          'PawPass',
          style: TextStyle(
            color: Colors.white,
            fontSize: 9 * s,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 2 * s),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 0.5),
          ),
          child: Text(
            '$speciesEmoji  ${pet.species.toUpperCase()}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 7 * s,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
        ),
        SizedBox(width: 4 * s),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 2 * s),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'PET ID',
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 7 * s,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  final Pet pet;
  final double s;
  final String speciesEmoji;
  const _Photo({required this.pet, required this.s, required this.speciesEmoji});

  @override
  Widget build(BuildContext context) {
    final size = 58 * s;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8 * s),
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5 * s),
        color: Colors.white.withOpacity(0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6.5 * s),
        child: pet.photoUrl != null
            ? CachedNetworkImage(
                imageUrl: pet.photoUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Center(
                  child: Text(speciesEmoji, style: TextStyle(fontSize: 28 * s)),
                ),
                errorWidget: (_, __, ___) => Center(
                  child: Text(speciesEmoji, style: TextStyle(fontSize: 28 * s)),
                ),
              )
            : Center(
                child: Text(speciesEmoji, style: TextStyle(fontSize: 28 * s)),
              ),
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final Pet pet;
  final double s;
  final String ageLabel;
  const _InfoBlock({required this.pet, required this.s, required this.ageLabel});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          pet.name.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 16 * s,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            height: 1.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 3 * s),
        if (pet.breed != null)
          Text(
            pet.breed!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 8 * s,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        SizedBox(height: 8 * s),
        if (pet.gender != null) _field('Sex', pet.gender!, s),
        if (ageLabel.isNotEmpty) _field('Age', ageLabel, s),
        if (pet.dob != null) _field('Born', dateFormat.format(pet.dob!), s),
        if (pet.color != null) _field('Color', pet.color!, s),
      ],
    );
  }

  Widget _field(String label, String value, double s) {
    return Padding(
      padding: EdgeInsets.only(bottom: 3 * s),
      child: Row(
        children: [
          Text(
            '$label  ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 7 * s,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 7.5 * s,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrBlock extends StatelessWidget {
  final Pet pet;
  final double s;
  const _QrBlock({required this.pet, required this.s});

  @override
  Widget build(BuildContext context) {
    final qrSize = 46 * s;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(3 * s),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5 * s),
          ),
          child: QrImageView(
            data: pet.shareLink,
            version: QrVersions.auto,
            size: qrSize,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Color(0xFF1A3A8F),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Color(0xFF1A3A8F),
            ),
          ),
        ),
        SizedBox(height: 3 * s),
        Text(
          'SCAN ME',
          style: TextStyle(
            color: Colors.white.withOpacity(0.55),
            fontSize: 5.5 * s,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _BottomStrip extends StatelessWidget {
  final Pet pet;
  final double s;
  const _BottomStrip({required this.pet, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28 * s,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.15), width: 0.5),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 14 * s),
      child: Row(
        children: [
          Text(
            'ID',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 6 * s,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          SizedBox(width: 6 * s),
          _MiniBarcode(s: s),
          SizedBox(width: 8 * s),
          Text(
            pet.shareToken != null
                ? pet.shareToken!.substring(0, 8).toUpperCase()
                : pet.id.substring(0, 8).toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 6 * s,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          Text(
            'PAWPASS',
            style: TextStyle(
              color: Colors.white.withOpacity(0.3),
              fontSize: 6 * s,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBarcode extends StatelessWidget {
  final double s;
  const _MiniBarcode({required this.s});

  @override
  Widget build(BuildContext context) {
    const widths = [2, 1, 3, 1, 2, 1, 3, 1, 2, 2, 1, 3, 1, 2, 1, 2, 3, 1];
    return CustomPaint(
      size: Size(50 * s, 12 * s),
      painter: _BarcodePainter(widths: widths, s: s),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  final List<int> widths;
  final double s;
  const _BarcodePainter({required this.widths, required this.s});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.45);
    double x = 0;
    bool fill = true;
    for (final w in widths) {
      final barW = w * 1.5 * s;
      if (fill) canvas.drawRect(Rect.fromLTWH(x, 0, barW, size.height), paint);
      x += barW + 0.5 * s;
      fill = !fill;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}