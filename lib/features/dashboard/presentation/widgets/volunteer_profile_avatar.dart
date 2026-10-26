import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cohv/core/constants/api_constants.dart';
import 'package:cohv/core/widgets/fallback_network_image.dart';

/// Reusable circular avatar displaying the volunteer's profile image
/// with base URL resolution, fallback candidate paths, auth headers,
/// and a generic profile icon when the image is missing or fails to load.
class VolunteerProfileAvatar extends StatelessWidget {
  final String? photoPath;
  final String? authToken;
  final double size;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? backgroundColor;

  const VolunteerProfileAvatar({
    super.key,
    this.photoPath,
    this.authToken,
    this.size = 48,
    this.onTap,
    this.borderColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor =
        borderColor ?? Colors.white.withValues(alpha: 0.45);
    final effectiveBgColor =
        backgroundColor ?? Colors.white.withValues(alpha: 0.18);

    final rawPhoto = photoPath?.trim();
    final hasPhoto = rawPhoto != null && rawPhoto.isNotEmpty && rawPhoto != '—';

    final isLocalFile = hasPhoto &&
        !rawPhoto.startsWith('http') &&
        File(rawPhoto).existsSync();

    final candidateUrls = hasPhoto
        ? ApiConstants.resolveImageCandidateUrls(rawPhoto)
        : const <String>[];

    final Map<String, String>? headers =
        (authToken != null && authToken!.isNotEmpty)
            ? ApiConstants.defaultHeaders(token: authToken)
            : null;

    Widget avatarContent;
    if (hasPhoto && (candidateUrls.isNotEmpty || isLocalFile)) {
      avatarContent = ClipOval(
        child: FallbackNetworkImage(
          urls: candidateUrls,
          localFilePath: isLocalFile ? rawPhoto : null,
          headers: headers,
          fit: BoxFit.cover,
          width: size,
          height: size,
          fallbackBuilder: (context) => _buildFallbackIcon(),
        ),
      );
    } else {
      avatarContent = _buildFallbackIcon();
    }

    final container = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBgColor,
        border: Border.all(
          color: effectiveBorderColor,
          width: 1.5,
        ),
      ),
      child: Center(child: avatarContent),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: container,
      );
    }

    return container;
  }

  Widget _buildFallbackIcon() {
    return Center(
      child: Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: size * 0.55,
      ),
    );
  }
}
