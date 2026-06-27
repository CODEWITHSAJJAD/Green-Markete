import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class OTPVerifyPage extends ConsumerStatefulWidget {
  const OTPVerifyPage({super.key});

  @override
  ConsumerState<OTPVerifyPage> createState() => _OTPVerifyPageState();
}

class _OTPVerifyPageState extends ConsumerState<OTPVerifyPage> {
  final _otpController = TextEditingController();
  int _resendTimer = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _canResend = false;
    _resendTimer = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _resendTimer--;
        if (_resendTimer <= 0) _canResend = true;
      });
      return _resendTimer > 0;
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verify() {
    // API call to verify OTP
    context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 32),
            const Text(
              'Enter the verification code sent to your phone',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'OTP Code',
                hintText: 'Enter 6-digit OTP',
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _otpController.text.length == 6 ? _verify : null,
                child: const Text('Verify', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _canResend
                  ? () {
                      _startTimer();
                      // Resend OTP API call
                    }
                  : null,
              child: Text(
                _canResend ? 'Resend Code' : 'Resend in $_resendTimer s',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
