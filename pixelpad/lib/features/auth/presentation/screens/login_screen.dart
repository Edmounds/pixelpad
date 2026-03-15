import 'package:flutter/material.dart';

import 'package:pixelpad/core/app/navigation.dart';
import 'package:pixelpad/core/app/routes.dart';
import 'package:pixelpad/core/theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _agreed = false;
  bool _showWarning = false;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -8), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8, end: 8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _handlePhoneLoginTap() {
    if (_agreed) {
      AppNavigator.pushNamed(context, AppRoutes.phoneLogin);
      return;
    }
    setState(() => _showWarning = true);
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () =>
                        AppNavigator.pushNamedAndRemoveUntil(context, AppRoutes.mainShell),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Transform.rotate(
                        angle: 3.1415926,
                        child: const Icon(
                          Icons.play_arrow,
                          size: 18,
                          color: Color(0xFFF9F871),
                        ),
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      '登录',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF9F871),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double areaHeight = constraints.maxHeight;
                  final double barHeight = (areaHeight * 0.34).clamp(150.0, 230.0);
                  const double gap = 18;

                  return Stack(
                    children: [
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: double.infinity,
                          height: barHeight,
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
                          decoration: const BoxDecoration(
                            color: Color(0xFFB8A6FF),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Center(
                                  child: _LoginOption(
                                    iconAsset: 'assets/common_icon/wechat.png',
                                    label: '微信一键登录',
                                    onTap: () {},
                                  ),
                                ),
                                const SizedBox(height: 40),
                                Center(
                                  child: _LoginOption(
                                    iconAsset: 'assets/common_icon/phone.png',
                                    label: '手机号一键登录',
                                    onTap: _handlePhoneLoginTap,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: Transform.translate(
                          offset: Offset(0, -(barHeight / 2 + gap + 90)),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/source/logo.png',
                                width: 96,
                                height: 96,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Welcome',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _shakeAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(_shakeAnimation.value, 0),
                                    child: AnimatedOpacity(
                                      opacity: _showWarning ? 1 : 0,
                                      duration: const Duration(milliseconds: 180),
                                      child: child,
                                    ),
                                  );
                                },
                                child: const Text(
                                  '请阅读并勾选用户协议',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFF9F871),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Checkbox(
                                    value: _agreed,
                                    onChanged: (value) {
                                      setState(() {
                                        _agreed = value ?? false;
                                        if (_agreed) {
                                          _showWarning = false;
                                        }
                                      });
                                    },
                                    shape: const CircleBorder(),
                                    activeColor: const Color(0xFFF9F871),
                                    checkColor: const Color(0xFF232323),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity:
                                        const VisualDensity(horizontal: -2, vertical: -2),
                                    side: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      width: 1.5,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Text(
                                    '同意《用户协议》和《隐私政策》',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: 315,
                                child: Text(
                                  '在这里，\n你将拥有一个独一无二的创作身份。\n未来所有的灵感、作品与成长记录都将在此安家。',
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.14,
                                    color: Colors.white.withValues(alpha: 0.53),
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginOption extends StatelessWidget {
  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  const _LoginOption({
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconAsset,
              width: 22,
              height: 22,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E2E2E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

