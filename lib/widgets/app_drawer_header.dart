import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Couleurs du thème restaurant (synchronisées avec LoginScreen)
const Color _warmOrange = Color(0xFFE85D04);
const Color _cream = Color(0xFFFFF8F0);
const Color _gold = Color(0xFFD4A574);

class AppDrawerHeader extends StatelessWidget {
  const AppDrawerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return DrawerHeader(
      padding: const EdgeInsets.all(12), // Reduced padding to prevent overflow
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3D2914), Color(0xFF5D3A1A)], // _deepBrown gradient
        ),
      ),
      child: Center(
        child: SingleChildScrollView( // Added SingleChildScrollView to handle small screens
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Use min to hug content
            children: [
              // Logo stylisé similaire à l'écran de connexion
              Stack(
                alignment: Alignment.center,
                children: [
                  // Cercle extérieur
                  Container(
                    width: 60, // Reduced size
                    height: 60, // Reduced size
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _gold.withValues(alpha: 0.3), width: 1.5),
                    ),
                  ),
                  // Cercle intérieur avec dégradé
                  Container(
                    width: 50, // Reduced size
                    height: 50, // Reduced size
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _warmOrange,
                          _warmOrange.withValues(alpha: 0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 24), // Reduced icon size
                  ),
                ],
              ),
              const SizedBox(height: 12), // Reduced spacing
              // Titre "SAVEURS"
              Text(
                'SAVEURS',
                style: GoogleFonts.playfairDisplay(
                  color: _cream,
                  fontSize: 20, // Reduced font size
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 4),
              // Sous-titre "GESTION"
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 16, height: 1, color: _gold.withValues(alpha: 0.5)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      'GESTION',
                      style: GoogleFonts.inter(
                        color: _gold,
                        fontSize: 9, // Reduced font size
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  Container(width: 16, height: 1, color: _gold.withValues(alpha: 0.5)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
