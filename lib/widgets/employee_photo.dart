import 'package:flutter/material.dart';

import '../core/network/api_client.dart';

class EmployeePhoto extends StatelessWidget {
  final String? path;
  final double size;
  final double radius;

  const EmployeePhoto({
    super.key,
    required this.path,
    this.size = 72,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiClient.assetUrl(path);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: size,
        height: size,
        child: imageUrl.isEmpty
            ? _placeholder()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _placeholder(),
              ),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: Colors.white.withValues(alpha: 0.16),
    alignment: Alignment.center,
    child: Icon(Icons.person_rounded, size: size * 0.52, color: Colors.white),
  );
}
