import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../network/api_client.dart';

class AdminInspectionBanner extends StatelessWidget {
  const AdminInspectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (ApiClient.inspectingArtisanId == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: AppColors.secondary,
      child: Row(
        children: [
          const Icon(Icons.remove_red_eye_outlined, color: Colors.black, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '👁️ Mode Inspection Admin : ${ApiClient.inspectingArtisanName ?? 'Atelier'}',
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ApiClient.inspectingArtisanId = null;
              ApiClient.inspectingArtisanName = null;
              context.go('/admin');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Quitter', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
