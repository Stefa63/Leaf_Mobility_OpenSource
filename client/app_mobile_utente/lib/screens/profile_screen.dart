import 'dart:io';

import 'package:flutter/material.dart';
import 'package:app_mobile_utente/theme.dart';
import 'package:app_mobile_utente/api/auth_repository.dart';
import 'package:app_mobile_utente/screens/account_screen.dart';
import 'package:app_mobile_utente/screens/sensitive_data_screen.dart';
import 'package:app_mobile_utente/screens/subscription_manager_screen.dart';
import 'package:app_mobile_utente/screens/support_screen.dart';
import 'package:app_mobile_utente/l10n.dart';
import 'package:app_mobile_utente/profile_store.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Translated((context) {
      return Scaffold(
      appBar: AppBar(
        title: Text(
          tr('Profilo'),
          style: const TextStyle(color: AppTheme.darkGreen),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Profile Info Header — riflette i dati locali del profilo (UT.21).
            ValueListenableBuilder<String?>(
              valueListenable: ProfileStore.photoPath,
              builder: (context, path, _) {
                final hasPhoto = path != null && File(path).existsSync();
                return CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.primaryGreen,
                  backgroundImage: hasPhoto ? FileImage(File(path)) : null,
                  child: hasPhoto
                      ? null
                      : const Icon(Icons.person, color: Colors.white, size: 48),
                );
              },
            ),
            const SizedBox(height: 16),
            ValueListenableBuilder<String>(
              valueListenable: ProfileStore.firstName,
              builder: (context, first, _) => ValueListenableBuilder<String>(
                valueListenable: ProfileStore.lastName,
                builder: (context, last, _) => Text(
                  '$first $last',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<String>(
              valueListenable: ProfileStore.email,
              builder: (context, email, _) => Text(
                email,
                style: const TextStyle(fontSize: 16, color: AppTheme.textGrey),
              ),
            ),
            const SizedBox(height: 32),
            const Divider(color: Colors.black12, thickness: 1),
            // Menu Items
            ListTile(
              leading: const Icon(
                Icons.person_outline,
                color: AppTheme.accentBrown,
              ),
              title: Text(
                tr('Account'),
                style: const TextStyle(color: AppTheme.textDark),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppTheme.textGrey,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.card_membership,
                color: AppTheme.accentBrown,
              ),
              title: Text(
                tr('Gestione abbonamento'),
                style: const TextStyle(color: AppTheme.textDark),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppTheme.textGrey,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: Text(
                          tr('Gestione abbonamento'),
                          style: const TextStyle(color: AppTheme.darkGreen),
                        ),
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      body: const SubscriptionManagerScreen(),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.security, color: AppTheme.accentBrown),
              title: Text(
                tr('Dati sensibili'),
                style: const TextStyle(color: AppTheme.textDark),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppTheme.textGrey,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SensitiveDataScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.help_outline,
                color: AppTheme.accentBrown,
              ),
              title: Text(
                tr('Assistenza'),
                style: const TextStyle(color: AppTheme.textDark),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: AppTheme.textGrey,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportScreen(),
                  ),
                );
              },
            ),
            const Spacer(),
            const Divider(color: Colors.black12, thickness: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: Text(
                tr('Log out'),
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await authRepository.esci();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      );
    });
  }
}
