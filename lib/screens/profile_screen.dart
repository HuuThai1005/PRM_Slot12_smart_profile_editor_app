import 'dart:async';

import 'package:flutter/material.dart';

import '../models/profile_model.dart';
import '../repositories/profile_repository.dart';
import '../services/draft_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();

  final _repository = ProfileRepository();
  final _draftService = DraftService();

  Timer? _draftTimer;
  bool _loading = true;
  String? _loadError;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final draft = await _draftService.load();
      final profile = draft ?? await _repository.getProfile();

      if (!mounted) return;

      _nameController.text = profile.name;
      _emailController.text = profile.email;
      _phoneController.text = profile.phone;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Không tải được hồ sơ: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Profile _currentProfile() {
    return Profile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Không được để trống';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return 'Không được để trống';

    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

    return valid ? null : 'Email không hợp lệ';
  }

  String? _validatePhone(String? value) {
    final phone = (value ?? '').trim();
    if (phone.isEmpty) return 'Không được để trống';

    final allowedCharacters = RegExp(r'^[0-9+\-\s()]+$');
    final digitCount = phone.replaceAll(RegExp(r'\D'), '').length;

    if (!allowedCharacters.hasMatch(phone) || digitCount < 8) {
      return 'Số điện thoại cần ít nhất 8 chữ số';
    }
    return null;
  }

  void _scheduleDraftSave() {
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        await _draftService.save(_currentProfile());
      } catch (error) {
        print('Lỗi lưu nháp: $error');
      }
    });
  }

  Future<void> _submit() async {
    if (_loading) return;

    FocusScope.of(context).unfocus();

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    _draftTimer?.cancel();

    setState(() {
      _loading = true;
      _submitError = null;
    });

    try {
      await _repository.updateProfile(_currentProfile());
      await _draftService.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cập nhật thành công')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitError = 'Cập nhật thất bại: $error');
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cập nhật thất bại')));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Profile Editor'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadProfile,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_loadError!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loadProfile,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              )
            : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              focusNode: _nameFocus,
              decoration: const InputDecoration(labelText: 'Họ tên'),
              textInputAction: TextInputAction.next,
              validator: _validateRequired,
              onFieldSubmitted: (_) => _emailFocus.requestFocus(),
              onChanged: (_) => _scheduleDraftSave(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              focusNode: _emailFocus,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
              onFieldSubmitted: (_) => _phoneFocus.requestFocus(),
              onChanged: (_) => _scheduleDraftSave(),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              validator: _validatePhone,
              onFieldSubmitted: (_) => _submit(),
              onChanged: (_) => _scheduleDraftSave(),
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 12),
              Text(_submitError!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: const Text('Lưu cập nhật'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
