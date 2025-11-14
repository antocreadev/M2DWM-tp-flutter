import 'package:flutter/material.dart';
import 'package:chat_app/constants.dart';

/// Widget d'écran de chargement affiché pendant les opérations asynchrones
class LoadingScreen extends StatelessWidget {
  final String? message;

  const LoadingScreen({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
            ),
            if (message != null) ...[
              const SizedBox(height: AppConstants.largePadding),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: AppConstants.bodyFontSize,
                  color: AppConstants.onBackground,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
