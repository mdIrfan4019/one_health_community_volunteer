import 'package:flutter/material.dart';

/// Centralized configuration model and lookup for department-specific
/// titles, descriptions, and icons across the Dashboard and Quick Actions screens.
class DepartmentConfig {
  final String departmentKey;
  final String displayName;
  final String dashboardIntroTitle;
  final String quickActionsIntroTitle;
  final IconData icon;
  final String dashboardDescription;
  final String quickActionsDescription;

  const DepartmentConfig({
    required this.departmentKey,
    required this.displayName,
    required this.dashboardIntroTitle,
    required this.quickActionsIntroTitle,
    required this.icon,
    required this.dashboardDescription,
    required this.quickActionsDescription,
  });

  // =========================================================================
  // 🏥 1. Public Health Department
  // =========================================================================
  static const DepartmentConfig publicHealth = DepartmentConfig(
    departmentKey: 'public_health',
    displayName: 'Public Health Department',
    dashboardIntroTitle: 'Healthy communities start with you',
    quickActionsIntroTitle: 'People first',
    icon: Icons.person_rounded,
    dashboardDescription: 'Small actions. Healthier communities.',
    quickActionsDescription: 'Capture health concerns and community needs.',
  );

  // =========================================================================
  // 🏡 2. Rural Department
  // =========================================================================
  static const DepartmentConfig rural = DepartmentConfig(
    departmentKey: 'rural',
    displayName: 'Rural Department',
    dashboardIntroTitle: 'Stronger rural communities',
    quickActionsIntroTitle: 'Stronger villages',
    icon: Icons.cottage_rounded,
    dashboardDescription: 'Small actions. Stronger villages.',
    quickActionsDescription: 'Bring local observations into one shared picture.',
  );

  // =========================================================================
  // 🏙️ 3. Urban Department
  // =========================================================================
  static const DepartmentConfig urban = DepartmentConfig(
    departmentKey: 'urban',
    displayName: 'Urban Department',
    dashboardIntroTitle: 'Better cities, healthier lives',
    quickActionsIntroTitle: 'Make every place safer',
    icon: Icons.location_city_rounded,
    dashboardDescription: 'Small actions. Healthier urban communities.',
    quickActionsDescription: 'Track community concerns across local areas.',
  );

  // =========================================================================
  // 🌿 4. Environment Department
  // =========================================================================
  static const DepartmentConfig environment = DepartmentConfig(
    departmentKey: 'environment',
    displayName: 'Environment Department',
    dashboardIntroTitle: 'Nature in focus',
    quickActionsIntroTitle: 'Nature in focus',
    icon: Icons.eco_rounded,
    dashboardDescription: 'Small actions. A healthier environment.',
    quickActionsDescription: 'Spot environmental risks before they spread.',
  );

  // =========================================================================
  // 🐾 5. Animal Husbandry Department
  // =========================================================================
  static const DepartmentConfig animalHusbandry = DepartmentConfig(
    departmentKey: 'animal_husbandry',
    displayName: 'Animal Husbandry Department',
    dashboardIntroTitle: 'Every animal matters',
    quickActionsIntroTitle: 'Every paw matters',
    icon: Icons.pets_rounded,
    dashboardDescription: 'Small actions. Healthier animals and communities.',
    quickActionsDescription: 'Record animal health events while you are there.',
  );

  // =========================================================================
  // 🌲 6. Wildlife Department
  // =========================================================================
  static const DepartmentConfig wildlife = DepartmentConfig(
    departmentKey: 'wildlife',
    displayName: 'Wildlife Department',
    dashboardIntroTitle: 'Protect the wild',
    quickActionsIntroTitle: 'Protect the wild',
    icon: Icons.forest_rounded,
    dashboardDescription: 'Small actions. A safer environment for wildlife.',
    quickActionsDescription: 'Report wildlife observations and emerging risks.',
  );

  // =========================================================================
  // 🛡️ 7. Unassigned / Default Department (strictly no fake public health)
  // =========================================================================
  static const DepartmentConfig unassigned = DepartmentConfig(
    departmentKey: 'unassigned',
    displayName: 'Assigned Department',
    dashboardIntroTitle: 'SETU Fieldspace',
    quickActionsIntroTitle: 'Field Actions',
    icon: Icons.shield_outlined,
    dashboardDescription: 'Connecting communities and essential services.',
    quickActionsDescription: 'Access your field tools and services.',
  );

  /// All registered department configurations
  static const List<DepartmentConfig> allDepartments = [
    publicHealth,
    rural,
    urban,
    environment,
    animalHusbandry,
    wildlife,
  ];

  /// Generic fallback when department is unspecified or unrecognized
  static const DepartmentConfig fallback = publicHealth;

  /// Resolves the department configuration dynamically using the exact or
  /// fuzzy value of `cohv_type` / department name from `/api/auth/me`.
  /// Handles case differences, extra whitespaces, underscores, and hyphens safely.
  static DepartmentConfig fromCohvType(String? cohvType) {
    if (cohvType == null || cohvType.trim().isEmpty) {
      return fallback;
    }

    final normalized = cohvType
        .trim()
        .toLowerCase()
        .replaceAll('-', ' ')
        .replaceAll('_', ' ');

    // 1. Wildlife Department (checked before animal husbandry to avoid "wild animal" ambiguity)
    if (normalized.contains('wildlife') ||
        normalized.contains('wild life') ||
        normalized.contains('forest') ||
        normalized == 'wild') {
      return wildlife;
    }

    // 2. Animal Husbandry Department
    if (normalized.contains('animal') ||
        normalized.contains('husbandry') ||
        normalized.contains('veterinary') ||
        normalized.contains('vet') ||
        normalized.contains('livestock') ||
        normalized.contains('pet')) {
      return animalHusbandry;
    }

    // 3. Environment Department
    if (normalized.contains('environment') ||
        normalized.contains('ecology') ||
        normalized.contains('nature')) {
      return environment;
    }

    // 4. Rural Department
    if (normalized.contains('rural') ||
        normalized.contains('village') ||
        normalized.contains('panchayat')) {
      return rural;
    }

    // 5. Urban Department
    if (normalized.contains('urban') ||
        normalized.contains('city') ||
        normalized.contains('municipality')) {
      return urban;
    }

    // 6. Public Health Department
    if (normalized.contains('public health') ||
        normalized.contains('health') ||
        normalized.contains('medical') ||
        normalized.contains('human')) {
      return publicHealth;
    }

    // Fallback for unknown / unrecognized departments
    return fallback;
  }
}
