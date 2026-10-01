import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

void showCustomAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App Icon / Logo
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(10),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.shopping_cart,
                    color: AppTheme.primaryColor,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App Name
            const Text(
              'Supermarket DZ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),

            // POS Subtitle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Built for Algerian POS Systems',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.verified_outlined,
                    label: 'Version',
                    value: '1.0 (Supermarket DZ)',
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildInfoRow(
                    icon: Icons.code,
                    label: 'Developer',
                    value: 'JARVISCYBER',
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildInfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: 'jarviscyber918@gmail.com',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Copyright notice
            Text(
              '© ${DateTime.now().year} JARVISCYBER • All rights reserved',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Fermer / إغلاق',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildInfoRow({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Row(
    children: [
      Icon(icon, size: 18, color: AppTheme.primaryColor),
      const SizedBox(width: 10),
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const Spacer(),
      Text(
        value,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    ],
  );
}
