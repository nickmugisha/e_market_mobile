import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/data/user_profile_repository.dart';
import '../../auth/domain/user_profile.dart';
import '../domain/profile_validator.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.profile,
  });

  final UserProfile profile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _profiles = UserProfileRepository();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _whatsapp;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.name);
    _phone = TextEditingController(text: widget.profile.phone);
    _whatsapp = TextEditingController(text: widget.profile.whatsappNumber);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await _profiles.updateProfile(
        profile: widget.profile,
        name: _name.text,
        phone: _phone.text,
        whatsappNumber: _whatsapp.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.profile.role == UserRole.seller
                ? 'Could not update the profile and seller product contact details.'
                : 'Could not update the profile.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final seller = widget.profile.role == UserRole.seller;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: const Text('Edit profile'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 25,
                    backgroundColor: AppColors.accent,
                    child: Icon(Icons.person_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.profile.role.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.profile.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white60),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _name,
              enabled: !_saving,
              validator: (value) =>
                  ProfileValidator.validateName(value ?? ''),
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              enabled: !_saving,
              validator: (value) =>
                  ProfileValidator.validatePhone(value ?? ''),
              keyboardType: TextInputType.phone,
              textInputAction:
                  seller ? TextInputAction.next : TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
            if (seller) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _whatsapp,
                enabled: !_saving,
                validator: (value) => ProfileValidator.validateWhatsApp(
                  role: widget.profile.role,
                  value: value ?? '',
                ),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Seller WhatsApp',
                  hintText: '+257...',
                  prefixIcon: Icon(Icons.chat_outlined),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Changing your seller name or WhatsApp also updates the public contact details on your existing products.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving...' : 'Save profile'),
            ),
          ],
        ),
      ),
    );
  }
}
