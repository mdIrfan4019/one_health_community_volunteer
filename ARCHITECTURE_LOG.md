# Architecture Decision & Change Log (ADL)

## [Phase 1: Authentication & Shared Handset Gate]
**Date:** 2026-10-13  
**Feature:** Multi-Volunteer Authentication UI (PIN Daily Login + OTP Fallback)

### 1. Files Added & Single Responsibilities:
- `lib/core/theme/app_colors.dart`: Central color design tokens (`#A3546B` brand primary, backgrounds, borders).
- `lib/features/auth/domain/auth_models.dart`: Domain entities (`SignInWithPinRequest`, `SendOtpRequest`, `UserSession`) completely isolated from UI.
- `lib/features/auth/data/auth_api_service.dart`: Network interface with mock implementation and pluggable backend endpoints (`loginWithPin`, `sendOtp`).
- `lib/features/auth/presentation/widgets/one_health_logo.dart`: Reusable CustomPainter emblem representing the 3 One Health pillars.
- `lib/features/auth/presentation/widgets/custom_text_field.dart`: Standardized text input with asterisks and focus state borders.
- `lib/features/auth/presentation/screens/sign_in_screen.dart`: Combined view handling both PIN-based login and OTP fallback modes.
- `lib/main.dart`: Root entrypoint initializing `CohvApp` and pointing to `SignInScreen`.

### 2. Why This Approach? (Design Rationale):
- **Zero-Coupling API Layer:** The UI depends only on the `AuthApiService` method signatures. When backend endpoints are provided, only `auth_api_service.dart` is modified; the UI requires zero edits.
- **Spec Compliance:** 
  - National mobile numbers are validated strictly with Indian regex `^[6-9]\d{9}$`.
  - PIN input enforces 4–6 numeric digits.
- **Shared Handset Readiness:** `UserSession` extracts the `volunteerId` and `sector`, which will bind the local database partition to prevent cross-account record leakage.

### 3. Data Flow:
[User Inputs Credentials]
   │
   ▼
[Form Validation (4-6 PIN or 10-digit Mobile)]
   │
   ▼
[AuthApiService.loginWithPin / sendOtp]
   │
   ├── (Mock / Future HTTP POST)
   ▼
[UserSession Created] ──► [Session Bound to Runtime Context]


## [UI Polish: Edge-to-Edge System Bar Integration]
**Date:** 2026-10-13  
**Changes:**
- `lib/main.dart`: Injected `SystemChrome.setSystemUIOverlayStyle` configuring a transparent status bar with dark iconography (`Brightness.dark`).
- `lib/features/auth/presentation/screens/sign_in_screen.dart`: Wrapped in `AnnotatedRegion<SystemUiOverlayStyle>` to eliminate the straight status bar boundary, rendering the app background edge-to-edge right below the time and battery status.


## [Feature: Attention Banner & Forgot PIN Recovery Flow]
**Date:** 2026-10-13  
**Changes:**
- `lib/features/auth/presentation/widgets/attention_banner.dart`: Created modular Attention Banner component implementing Section 8 Amber-to-Orange ramp standard (`#EA580C` accent strip on pale cream container).
- `lib/features/auth/data/auth_api_service.dart`: Added `endpointForgotPin` configuration and `requestForgotPin()` method with mock network delay, isolated for backend API wiring.
- `lib/features/auth/presentation/screens/sign_in_screen.dart`: Wired up `_handleForgotPin` validation lifecycle:
  - If field is not a valid 10-digit mobile number, activates the in-card Attention Banner (`1 item(s) need attention • Mobile Number must be a valid 10-digit number.`).
  - If valid, dispatches API call to `requestForgotPin()`.

### Data Flow:
[User Taps "Forgot password / PIN?"]
               │
               ▼
   [Validate 10-Digit Mobile?]
      ├── Invalid ──► [Display AttentionBanner (Amber-to-Orange)]
      └── Valid   ──► [AuthApiService.requestForgotPin] ──► [Dispatch Recovery OTP]


## [Feature: 6-Digit OTP Verification Screen]
**Date:** 2026-10-13  
**Feature:** First-Time / Mobile SMS OTP Verification (`OtpVerificationScreen`)

### 1. Files Added & Modified:
- `lib/features/auth/domain/auth_models.dart`: Added `VerifyOtpRequest(mobileNumber, otp)` entity.
- `lib/features/auth/data/auth_api_service.dart`: Added `endpointVerifyOtp` configuration and `verifyOtp()` with plug-and-play HTTP comments.
- `lib/features/auth/presentation/screens/otp_verification_screen.dart`: Created full verification UI matching the prototype specification:
  - 6 individual visual digit cells with active border indicators.
  - Native clipboard paste & auto-advance without external dependencies.
  - Section 8 compliant `AttentionBanner` for incomplete inputs or server rejections.
  - "Change mobile number" back-navigation link.
- `lib/features/auth/presentation/screens/sign_in_screen.dart`: Connected `sendOtp()` success callback to push `OtpVerificationScreen`.

### 2. Why This Approach? (Design Rationale):
- **Zero-Coupling API Layer:** The UI depends strictly on `AuthApiService.verifyOtp()`. When the real backend endpoint is deployed, developers only need to uncomment the HTTP block in `auth_api_service.dart`.
- **Keyboard & Paste Reliability:** Using an invisible `TextField` behind 6 visual cells eliminates backspace detection bugs across various Android/iOS OEM keyboards and provides native SMS OTP autofill and paste functionality.

### 3. Data Flow:
[User Enters Mobile on SignInScreen]
                 │
                 ▼
     [AuthApiService.sendOtp]
                 │
                 ▼
   [Navigate to OtpVerificationScreen]
                 │
                 ▼
     [User Types 6-Digit OTP]
                 │
                 ▼
    [AuthApiService.verifyOtp]
                 ├── Invalid ──► [Display AttentionBanner (Amber-to-Orange)]
                 └── Valid   ──► [Session Bound] ──► [Navigate to Dashboard]


## [Feature: Volunteer Registration Cascade & Supervisor Gate]
**Date:** 2026-10-13  
**Feature:** Section 2 & 3 Compliance: Multi-Level Demographic Cascade & Supervisor Lock Screen

### 1. Files Added & Modified:
- `lib/features/auth/domain/auth_models.dart`: Added `VolunteerRegistrationRequest` and `RegistrationResult` domain models.
- `lib/features/auth/data/demographic_repository.dart`: Created the hybrid repository:
  - App-side standard enums for Gender, COHV Type (4 Pillars), Qualification, and Profession.
  - Offline-first cascading geographic hierarchy (State → District → Block → Panchayat → Village) with pilot seed data for Telangana & Tamil Nadu.
  - Pluggable `GET /api/v1/master/demographics` sync hook.
- `lib/features/auth/data/auth_api_service.dart`: Added `endpointRegister` and `registerVolunteer()` method.
- `lib/features/auth/presentation/screens/volunteer_registration_screen.dart`: Complete registration screen matching prototype:
  - Strict geographic anchoring: modifying an upstream unit invalidates and clears all downstream selections.
  - Dynamic Date of Birth validation enforcing minimum 18 years of age against current timestamp.
  - 4-6 digit numeric PIN.
  - GPS timestamp and location lock card with Refresh action.
  - Camera/Gallery photo attachment actions.
- `lib/features/auth/presentation/screens/awaiting_approval_screen.dart`: Complete Section 2 Supervisor Gate lock screen:
  - Displays Volunteer ID, candidate name, and `Account status: Inactive`.
  - Explanatory guidance on supervisory web portal review.
  - "Back to sign in" navigation reset.
- `lib/features/auth/presentation/screens/otp_verification_screen.dart`: Wired successful OTP verification to push `VolunteerRegistrationScreen`.

### 2. Data Flow:
[OTP Verified]
      │
      ▼
[VolunteerRegistrationScreen Loaded]
      │
      ├── Cascading Dropdowns: State ➔ District ➔ Block ➔ Panchayat ➔ Village
      ├── Form Validations: Age ≥ 18, 10-Digit Mobile, 4–6 Digit PIN
      │
      ▼
[AuthApiService.registerVolunteer]
      │
      ▼
[AwaitingApprovalScreen (Locked Status: Inactive)]
      │
      ▼
[Supervisor Web Console Approves] ──► [Volunteer Eligible for Daily PIN Sign-In]


## [Refactor: Direct Registration Flow & OTP Decommissioning]
**Date:** 2026-10-14  
**Feature:** Streamlined Authentication & Direct Volunteer Sign-up

### 1. Files Modified:
- `lib/features/auth/presentation/screens/sign_in_screen.dart`:
  - Removed secondary OTP login mode and the "Sign in with OTP instead" toggle.
  - Added dedicated "Don't have an account? Sign up" action row directly pushing `VolunteerRegistrationScreen`.
  - Added automatic mobile prefill detection if user typed a 10-digit number into the identifier field before clicking Sign up.
- `lib/features/auth/presentation/screens/volunteer_registration_screen.dart`:
  - Made `mobileNumber` constructor argument optional (`String?`) to support direct entry from registration form.
- `lib/features/auth/presentation/screens/otp_verification_screen.dart`:
  - Removed from active routing.

### 2. Data Flow:
[Sign In Screen]
       │
       ├── Existing User ──► [Enter Volunteer ID/Mobile + PIN] ──► [Sign In]
       │
       └── New User      ──► [Tap "Sign up"] ──► [VolunteerRegistrationScreen]
                                                           │
                                                           ▼
                                              [Fill Form & Cascade Anchors]
                                                           │
                                                           ▼
                                                [Register ➔ Inactive Gate]


## [Fix: CustomTextField Parameter Support]
**Date:** 2026-10-14  
**Feature:** Form Input Responsiveness

### 1. Files Modified:
- `lib/features/auth/presentation/widgets/custom_text_field.dart`: Added `final void Function(String)? onChanged` callback parameter to expose realtime keystroke listeners for live validation and clearing attention banners.


## [Feature: Core Dashboard & Surveillance Metric Engine]
**Date:** 2026-10-14  
**Feature:** Phase 3: Home Dashboard, Profile Anchor, and 8-Card KPI Grid

### 1. Files Added & Modified:
- `lib/features/dashboard/domain/dashboard_models.dart`: Added `DashboardMetrics` and `VolunteerProfile` domain entities.
- `lib/features/dashboard/data/dashboard_api_service.dart`: Created service layer with pluggable endpoints (`GET /dashboard/summary`, `GET /volunteer/profile`) and fallback mock data.
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`: Complete dashboard UI matching prototype:
  - Top AppBar with notification bell and synchronization/refresh action.
  - Profile Card with volunteer avatar, Volunteer ID (`COHV-26-0013`), demographic breadcrumb, and `Active` badge.
  - "Report an Event" peach-accented banner button.
  - 8-Card surveillance metric grid (Total visits, Alerts generated with orange ramp indicator dot, Referrals, Pending follow-ups, Awareness, Trainings imparted/attended, Sync queue).
  - 4-Tab Bottom Navigation Bar (Dashboard, Actions, Reports, Profile).
- `lib/features/auth/presentation/screens/sign_in_screen.dart`: Connected successful daily PIN sign-in to navigate straight to `DashboardScreen`.

### 2. Data Flow:
[User Enters Credentials & Signs In]
                 │
                 ▼
     [UserSession Active]
                 │
                 ▼
      [Navigate to DashboardScreen]
                 │
                 ├── [DashboardApiService.getVolunteerProfile] ──► Render Profile Header
                 └── [DashboardApiService.getDashboardMetrics]  ──► Render 8 KPI Cards


## [Feature: Quick Actions Surveillance Grid]
**Date:** 2026-10-14  
**Feature:** Section 7, 9 & 10 Quick Actions Module Router

### 1. Files Added & Modified:
- `lib/features/dashboard/presentation/screen/quick_actions_screen.dart`:
  - Created 6 surveillance entry cards matching prototype color palettes:
    1. **Report Event**: Amber/orange card routing to Section 7 Unified Event Reporting (`VISIT`).
    2. **Referral**: Rose card with referral emblem routing to Section 9 Inter-Sectoral Referrals (`REF`).
    3. **Awareness Activity**: Warm yellow card routing to Section 10 Community Awareness (`AWR`).
    4. **Sample Support**: Ice blue card routing to Section 10 Laboratory Sample Support (`SMP`).
    5. **Capacity Building**: Lavender card routing to Section 10 Training Imparted/Attended (`TRI`/`TRN`).
    6. **Success Stories**: Blush pink card routing to Section 10 Qualitative Evidence (`STY`).
- `lib/features/dashboard/presentation/screen/dashboard_screen.dart`:
  - Connected the 4-tab bottom navigation bar (`_selectedTabIndex == 1`).
  - Implemented dynamic App Bar title switching ("Dashboard" vs "Quick Actions").
  - Bound the "Report an Event" banner button directly to switch to the Actions tab.

### 2. Data Flow:
[User Taps "Actions" Tab on Bottom Bar]
                 │
                 ▼
    [App Bar Title: "Quick Actions"]
                 │
                 ▼
    [Render 6-Card Action Module Grid]
                 │
                 ├── Tap "Report Event"       ──► (Future VISIT / visitnew Engine)
                 ├── Tap "Referral"           ──► (Future REF Stream Engine)
                 ├── Tap "Awareness Activity" ──► (Future AWR Engine)
                 ├── Tap "Sample Support"     ──► (Future SMP Engine)
                 ├── Tap "Capacity Building"  ──► (Future TRN/TRI Engine)
                 └── Tap "Success Stories"    ──► (Future STY Engine)


## [Feature: Reports Module & Email Dispatch Engine]
**Date:** 2026-10-14  
**Feature:** Section 11 Summary Report Generation & Historical Request Log

### 1. Files Added & Modified:
- `lib/features/reports/domain/report_models.dart`: Added `ReportRequest` and `ReportItem` domain models with Section 4 standard entity prefix `RPT-26-0004`.
- `lib/features/reports/data/reports_api_service.dart`: Created service layer with pluggable endpoints (`POST /reports/request`, `GET /reports/history`) and mock fallback data.
- `lib/features/reports/presentation/screen/reports_screen.dart`: Complete reports UI matching prototype:
  - From & To native date pickers with logical boundary validation.
  - "Send to" email destination view.
  - "Send report on email" action button with live loading state.
  - "Requested" history card with date range, `sent` pill badge, and entity reference `RPT-26-0004`.
- `lib/features/dashboard/presentation/screen/dashboard_screen.dart`:
  - Connected the 3rd bottom navigation tab (`Reports`) to render `ReportsScreen`.
  - Updated dynamic App Bar title to "Reports".

### 2. Data Flow:
[User Selects Date Range & Taps "Send report on email"]
                         │
                         ▼
             [Validate fromDate ≤ toDate]
                         │
                         ▼
        [ReportsApiService.requestReport]
                         │
                         ▼
       [Insert Returned ReportItem into List] ──► [Render in "Requested" Card]


## [Feature: Volunteer Profile & Audit Log Module]
**Date:** 2026-10-14  
**Feature:** Section 1 Four-Pillar Domain Linking & Section 2 Shared Handset Audit History

### 1. Files Added & Modified:
- `lib/features/profile/domain/profile_models.dart`: Added `DetailedVolunteerProfile` and `LoginHistoryEntry` domain entities with full demographic hierarchy, One Health pillar institution bindings (`CHC`, `Veterinary institution: —`, `Forest institution: —`), and device identifiers.
- `lib/features/profile/data/profile_api_service.dart`: Created service layer with pluggable endpoints (`GET /volunteer/profile-details`, `GET /volunteer/login-history`, `PUT /volunteer/update`) with simulated fallback data.
- `lib/features/profile/presentation/screen/profile_screen.dart`: Complete profile view matching prototype screenshots:
  - Header with `[A]` letter badge, name `Test1`, Volunteer ID `COHV-26-0001`, and `COHV` designation.
  - Image placeholder container.
  - 21 Key-value detail rows reflecting demographic anchoring, pillar linked institutions, last login, and registration GPS stamp.
  - "Edit profile" action button.
  - "Login history" card automatically listing timestamped sign-in device records (`PIN · device DEV-C0YBZ9WK`).
- `lib/features/dashboard/presentation/screen/dashboard_screen.dart`:
  - Connected the 4th bottom navigation tab (`Profile`) to render `ProfileScreen`.
  - Updated dynamic App Bar title to "Profile".

### 2. Data Flow:
[User Taps "Profile" Tab on Bottom Bar]
                 │
                 ▼
     [App Bar Title: "Profile"]
                 │
                 ▼
  [ProfileApiService.getDetailedProfile] ──► Render 21 Pillar & Demographic Rows
                 │
                 ▼
  [ProfileApiService.getLoginHistory]   ──► Render Timestamped Audit Entries


## [Feature: Notifications Module & Real-time Supervisor Sync Alerts]
**Date:** 2026-10-14  
**Feature:** Section 2 & Section 3 Asynchronous Supervisor Event Feed & Sync Logs

### 1. Files Added & Modified:
- `lib/features/notifications/domain/notification_models.dart`: Created `AppNotification` entity supporting timestamped notification items, read receipts, and event categorization (`sync`, `report`, `alert`, `registration`).
- `lib/features/notifications/data/notifications_api_service.dart`: Created plug-and-play service with endpoint configuration (`GET /notifications`, `POST /notifications/mark-read`) and simulated fallback data matching the UI prototype.
- `lib/features/notifications/presentation/screen/notifications_screen.dart`: Complete Notifications screen featuring:
  - Mauve AppBar with navigation back arrow, active notification bell, and sync trigger.
  - White container card with subtle dividers and scrollbar.
  - Feed cards for sync completion logs, report requests, event-triggered supervisor alerts (`VISIT-26-0002` -> `ALERT-26-0003`), and supervisor account activation.
  - Linked bottom navigation bar enabling tab return.
- `lib/features/dashboard/presentation/screen/dashboard_screen.dart`:
  - Hooked AppBar notification bell icon to navigate to `NotificationsScreen`.

### 2. Data Flow:
[User Taps Notification Bell on Dashboard AppBar]
                       │
                       ▼
          [Push NotificationsScreen]
                       │
                       ▼
   [NotificationsApiService.getNotifications]
                       │
                       ▼
 [Render Chronological Notification Card List]
                       │
     ┌─────────────────┴─────────────────┐
     ▼                                   ▼
[Tap Back Arrow `<`]          [Tap Bottom Tab Item]
  Pop to Dashboard             Pop and switch to selected tab


## [Feature: Profile Photograph Camera & Gallery Upload Engine]
**Date:** 2026-10-14  
**Feature:** Volunteer Registration Photo Capture, Gallery Selection & Multipart API Plug

### 1. Files Added & Modified:
- `pubspec.yaml`: Added `image_picker: ^1.2.4` dependency.
- `android/app/src/main/AndroidManifest.xml`: Configured `android.permission.CAMERA` for Xiaomi/MIUI and standard Android compatibility.
- `lib/features/auth/presentation/screens/volunteer_registration_screen.dart`:
  - Hooked native Camera and Gallery pickers with `maxWidth: 1024`, `imageQuality: 85`.
  - Added photo preview container with thumbnail, filename, and Retake / Gallery / Remove actions.
  - Linked `photoPath` into `VolunteerRegistrationRequest`.
- `lib/features/auth/data/auth_api_service.dart`: Added `http.MultipartRequest` configuration ready for real backend file upload.

### 2. Data Flow:
[User Taps Camera or Gallery] 
             │
             ▼
  [ImagePicker.pickImage] ──► [Select / Capture Photo]
             │
             ▼
  [Render Preview Card with Thumbnail & File Name]
             │
             ▼
  [Tap "Register"] ──► [Attach photoPath to Request] ──► [Backend / AuthApiService]


## [Feature: Mobile-Anchored Volunteer ID & Dual Identifier Sign-In]
**Date:** 2026-10-15  
**Feature:** Section 2 Entity Identity Architecture & Section 1 Authentication Flow

### 1. Files Modified:
- `lib/features/auth/presentation/screens/volunteer_registration_screen.dart`:
  - Removed static Volunteer ID read-only field from the UI.
  - Implemented dynamic ID generation: `COHV-YY-Last4` (e.g. Mobile `9565897524` in 2026 becomes `COHV-26-7524`).
  - Passed generated ID directly to `AwaitingApprovalScreen`.
- `lib/features/auth/data/auth_api_service.dart`:
  - Added dual identifier detection in `loginWithPin`: automatically parses 10-digit mobile inputs to `COHV-YY-last4` or accepts direct `COHV-...` alphanumeric IDs.

### 2. User Journey:
[Fill Registration Form (No Volunteer ID shown)]
                       │
                       ▼
    [Click "Register" with Mobile 9565897524]
                       │
                       ▼
       [Generate ID: COHV-26-7524]
                       │
                       ▼
   [Awaiting Approval Screen (Status: Inactive)]
                       │
                       ▼ (Supervisor Approves)
      [Sign in via either:
       • Volunteer ID: COHV-26-7524 + PIN  OR
       • Mobile Number: 9565897524 + PIN]
                       │
                       ▼
            [Access Dashboard]


## [Feature: Offline-First Queue & Data Synchronisation Engine]
**Date:** 2026-10-15  
**Feature:** Section 2 Offline Event Persistence & Section 3 Batch Upload Synchronisation

### 1. Files Added & Modified:
- `lib/features/sync/domain/sync_models.dart`: Added `SyncRecord` entity with unique duplicate-prevention IDs (`REC-26-0000`), entity tags, preserved capture timestamps, and `SyncSummary`.
- `lib/features/sync/data/sync_repository.dart`: Central singleton queue storing local pending records, seed historical records, and connection override state.
- `lib/features/sync/data/sync_api_service.dart`: Pluggable service with endpoint `$baseUrl/sync/batch-upload` and ready-to-uncomment batch HTTP upload logic.
- `lib/features/sync/presentation/screen/sync_screen.dart`: Complete Synchronisation UI matching prototype:
  - Mauve AppBar with navigation back arrow, notifications bell, and sync icon.
  - White container with `[R]` emblem and specification description.
  - Live metric rows for Total records, Pending synchronisation, Synchronised count, and Device connection status.
  - "Treat this device as connected" override checkbox and "Follow the device connection" reset action.
  - "Synchronise now" batch upload button with progress indicator.
- `lib/features/dashboard/presentation/screen/dashboard_screen.dart`:
  - Connected AppBar sync button and "Data pending for synchronization" metric card to `SyncScreen`.

### 2. Data Flow:
[Offline Form Submission] ──► [Queue in SyncRepository with ID & Timestamp]
                                             │
                                             ▼
                               [Open Synchronisation Screen]
                                             │
                                             ▼
                 [Tap "Synchronise now" (When Connected/Overridden)]
                                             │
                                             ▼
                       [SyncApiService.uploadBatch]
                                             │
                                             ▼
                 [Mark Records Synced & Update Dashboard Counters]


## [Feature: Unified Event Reporting Module (VISIT / visitnew Engine)]
**Date:** 2026-10-15  
**Feature:** Section 2 One Health Field Surveillance & Outbreak Event Registration

### 1. Files Added & Modified:
- `lib/features/events/domain/event_models.dart`: Created `EventReportRequest` and `EventReportResult` domain entities covering syndromic surveillance, multi-sector categorization, observation word counts, alert/referral triggers, and GPS coordinates.
- `lib/features/events/data/event_api_service.dart`: Created pluggable service with endpoint `$baseUrl/events/report` and automated local offline queue enqueueing into `SyncRepository`.
- `lib/features/events/presentation/screen/event_reporting_screen.dart`: Complete Event Reporting form matching prototype screenshots:
  - Event, Sector, Village, Location Type, and Target Population dropdown cascades.
  - Side-by-side date and time pickers.
  - Live word counters for clinical observations and immediate actions (`0 / 250 words`).
  - Referral generated, Alert generated (with warning emblem), and Follow-up required flags.
  - Photograph, Video, and Document media attachment pickers.
  - GPS hardware stamp container with manual refresh.
- `lib/features/dashboard/presentation/screen/quick_actions_screen.dart`: Connected "Report Event" card to `EventReportingScreen`.
- `lib/features/dashboard/presentation/screen/dashboard_screen.dart`: Connected "Report an Event" banner button to `EventReportingScreen`.

### 2. Data Flow:
[User Fills Event Form & Taps "Submit event report"]
                           │
                           ▼
              [Validate Mandatory Fields (*)]
                           │
                           ▼
             [EventApiService.submitEventReport]
                           │
     ┌─────────────────────┴─────────────────────┐
     ▼                                           ▼
[Real Backend API (When active)]      [Enqueue into SyncRepository (VISIT)]
     │                                           │
     ▼                                           ▼
[Returns VISIT-26-XXXX]               [Increment Pending Sync Count]
     │                                           │
     └─────────────────────┬─────────────────────┘
                           ▼
[Show Confirmation Toast & Refresh Dashboard Counters]


## [Feature: Inter-Sectoral Referral Engine (REF Module)]
**Date:** 2026-10-15  
**Feature:** Section 2 Health Facility Referrals & Follow-up Tracking

### 1. Files Added & Modified:
- `lib/features/referrals/domain/referral_models.dart`: Created `ReferralItem` model containing facility destination (`CHC`), stream (`Human`), sequence identifier (`REF-26-0005`), follow-up indicator, and GPS stamp.
- `lib/features/referrals/data/referrals_api_service.dart`: Created service layer with pluggable endpoints (`GET /referrals/list`, `POST /referrals/create`), seed dataset, and local queue synchronization.
- `lib/features/referrals/presentation/screen/referrals_list_screen.dart`: Complete Referrals list with blue left accent border, `synced` pill badge, entity reference text, and `+ New Referral` floating action button.
- `lib/features/referrals/presentation/screen/new_referral_screen.dart`: Comprehensive referral registration form with stream/type/village pickers, dual date selectors, media attachment handlers, and GPS coordinates lock.
- `lib/features/dashboard/presentation/screen/quick_actions_screen.dart`: Connected the Referral action card to `ReferralsListScreen`.

### 2. Data Flow:
[Tap "Referral" on Actions Tab] ──► [Open ReferralsListScreen]
                                             │
                                             ▼
                               [Tap "+ New Referral"]
                                             │
                                             ▼
                               [Fill NewReferralScreen & Save]
                                             │
                                             ▼
                               [Enqueue into SyncRepository (REF)]
                                             │
                                             ▼
                               [Prepend to List & Return]


## [Feature: Community Awareness Module (AWR Engine)]
**Date:** 2026-10-15  
**Feature:** Section 2 Multi-Sectoral Health Education & Outreach Tracking

### 1. Files Added & Modified:
- `lib/features/awareness/domain/awareness_models.dart`: Created `AwarenessItem` model with activity categorization (`Village meetings`), date, village, people reached counter, topic covered, and stakeholder departments.
- `lib/features/awareness/data/awareness_api_service.dart`: Created service layer with endpoints (`GET /awareness/list`, `POST /awareness/create`), seed data (`AWR-26-0006`), and automated queue enqueueing into `SyncRepository`.
- `lib/features/awareness/presentation/screen/awareness_list_screen.dart`: Complete Awareness list with orange left accent border, `synced` pill badge, summary reach indicator (`45 reached · Sanitation and waste disposal`), and `+ New Activity` floating action button.
- `lib/features/awareness/presentation/screen/new_awareness_screen.dart`: Registration form covering activity types, date selection, village dropdown, reach count, topics, stakeholder departments, media attachments, and GPS coordinates stamp.
- `lib/features/dashboard/presentation/screen/quick_actions_screen.dart`: Connected the Awareness Activity card to `AwarenessListScreen`.

### 2. Data Flow:
[Tap "Awareness Activity" on Actions Tab] ──► [Open AwarenessListScreen]
                                                          │
                                                          ▼
                                            [Tap "+ New Activity"]
                                                          │
                                                          ▼
                                            [Fill NewAwarenessScreen & Save]
                                                          │
                                                          ▼
                                            [Enqueue into SyncRepository (AWR)]
                                                          │
                                                          ▼
                                            [Prepend to List & Refresh]


## [Feature: Centralized API Constants & Master State API Integration]
**Date:** 2026-10-16  
**Feature:** Section 3 Compliance: Dynamic Backend State Data Binding (`GET /api/locations/states`)

### 1. Files Added & Modified:
- `lib/core/constants/api_constants.dart`: Centralized `baseUrl` (`http://192.168.10.174:8000/api`) and master endpoints (`/locations/states`, `/locations/districts`, etc.).
- `lib/features/auth/domain/demographic_models.dart`: Added `StateModel` supporting `state_id`, `state_name`, and `state_lgd_code`.
- `lib/features/auth/data/demographic_repository.dart`: Added `fetchStatesFromApi()` with 12s timeout, JSON list/wrapper parsing, name sorting, and offline fallback.
- `lib/features/auth/presentation/screens/volunteer_registration_screen.dart`:
  - Connected `_loadStates()` in `initState()` to fetch state list on startup.
  - Enhanced `_buildDropdown` to show animated circular progress while loading and a retry button if offline.
  - Stored `_selectedStateModel` for downstream cascading endpoints (e.g. passing `stateId` to District API).
- `test/features/auth/demographic_repository_test.dart`: Added unit tests verifying `StateModel` deserialization and type conversion.

### 2. Data Flow:
[VolunteerRegistrationScreen Loaded]
                │
                ▼
  [DemographicRepository.fetchStatesFromApi]
  (GET /api/locations/states)
                │
     ┌──────────┴──────────┐
     ▼                     ▼
[200 OK]              [Network Failure / Offline]
     │                     │
[Parse StateModel]    [Use Fallback Seed States]
     │                     │
     └──────────┬──────────┘
                ▼
 [Populate State Dropdown Options]
                │
                ▼
 [User Selects State (e.g., Andaman and Nicobar Islands)]
                │
                ▼
 [Set _selectedState & _selectedStateModel (stateLgdCode: 35)]
                │
                ▼
 [Invalidates Downstream: District, Block, Panchayat, Village]


## [Feature: Cascading District API Integration]
**Date:** 2026-10-16  
**Feature:** Section 3 Compliance: Dynamic Backend District Data Binding (`GET /api/locations/districts?state_lgd_code=`)

### 1. Files Added & Modified:
- `lib/features/auth/domain/demographic_models.dart`: Added `DistrictModel` supporting `district_name`, `district_lgd_code`, and `state_lgd_code`.
- `lib/features/auth/data/demographic_repository.dart`: Added `fetchDistrictsFromApi(String stateLgdCode)` with caching, alphabetical sorting, and offline fallback.
- `lib/features/auth/presentation/screens/volunteer_registration_screen.dart`:
  - Connected `_loadDistricts(stateLgdCode)` triggered upon state selection.
  - State change resets downstream selections (`_selectedDistrict = null`, `_selectedBlock = null`, etc.) and immediately fetches corresponding districts.
  - District dropdown displays "Select State first" when unselected, and "Loading districts..." with progress indicator while fetching.
  - Stored `_selectedDistrictModel` ready for upcoming Block API.
- `test/features/auth/demographic_repository_test.dart`: Added unit tests for `DistrictModel` parsing.

### 2. Data Flow:
[User Selects State]
        │
        ▼
[Extract state_lgd_code (e.g., "35")]
        │
        ▼
[DemographicRepository.fetchDistrictsFromApi]
(GET /api/locations/districts?state_lgd_code=35)
        │
   ┌────┴────────────────┐
   ▼                     ▼
[200 OK]            [Network Failure / Offline]
   │                     │
[Parse DistrictModel] [Fallback Seed Districts]
   │                     │
   └──────────┬──────────┘
              ▼
[Populate District Dropdown]
              │
              ▼
[User Selects District] ──► [Set _selectedDistrict & _selectedDistrictModel] ──► [Invalidates Downstream Blocks]


## [Feature: Cascading Block API Integration]
**Date:** 2026-10-16  
**Feature:** Section 3 Compliance: Dynamic Backend Block Data Binding (`GET /api/locations/blocks?district_lgd_code=`)

### 1. Files Added & Modified:
- `lib/features/auth/domain/demographic_models.dart`: Added `BlockModel` supporting `block_name`, `block_lgd_code`, and `district_lgd_code`.
- `lib/features/auth/data/demographic_repository.dart`: Added `fetchBlocksFromApi(String districtLgdCode)` with caching, alphabetical sorting, and offline fallback.
- `lib/features/auth/presentation/screens/volunteer_registration_screen.dart`:
  - Connected `_loadBlocks(districtLgdCode)` triggered upon district selection.
  - District selection resets downstream selections (`_selectedBlock = null`, `_selectedPanchayat = null`, `_selectedVillage = null`) and immediately fetches corresponding blocks.
  - Block dropdown displays "Select District first" when unselected, and "Loading blocks..." with progress indicator while fetching.
  - Stored `_selectedBlockModel` with `blockLgdCode` ready for upcoming Gram Panchayat API.
- `test/features/auth/demographic_repository_test.dart`: Added unit tests for `BlockModel` parsing.

### 2. Data Flow:
[User Selects District]
        │
        ▼
[Extract district_lgd_code]
        │
        ▼
[DemographicRepository.fetchBlocksFromApi]
(GET /api/locations/blocks?district_lgd_code=...)
        │
   ┌────┴────────────────┐
   ▼                     ▼
[200 OK]            [Network Failure / Offline]
   │                     │
[Parse BlockModel]   [Fallback Seed Blocks]
   │                     │
   └──────────┬──────────┘
              ▼
[Populate Block Dropdown]
              │
              ▼
[User Selects Block] ──► [Set _selectedBlock & _selectedBlockModel] ──► [Invalidates Downstream Panchayats & Villages]


## [Feature: Dynamic Event Form Metadata Integration (GET /api/events/form-metadata)]
**Date:** 2026-10-17  
**Feature:** Section 7 Compliance: Dynamic Backend Dropdown & Sector Configuration Binding per Logged-in Volunteer

### 1. Files Added & Modified:
- `lib/core/constants/api_constants.dart`:
  - Added `endpointEventFormMetadata = '$baseUrl/events/form-metadata'`.
- `lib/core/storage/session_manager.dart`:
  - Added `saveEventFormMetadata(Map<String, dynamic> json)` and `getEventFormMetadata()`.
  - Added cache invalidation for `_keyEventFormMetadata` on `SessionManager.clearSession()`.
- `lib/features/events/domain/event_models.dart`:
  - Added `EventFormMetadata`, `PrimarySector`, `EventTypeOption`, `PopulationMetadata`, `PopulationOption`, `EventVillageOption`, and `UploadLimitsMetadata`.
  - Added `EventFormMetadata.fallback()` seeded with official One Health Community Volunteer schema.
  - Enriched `EventReportRequest` with backend entity IDs (`eventTypeId`, `villageLgdCode`, `targetPopulationId`, `primarySectorCode`, `otherEvent`, `otherPopulation`) with full backward compatibility.
- `lib/features/events/data/event_api_service.dart`:
  - Implemented `getEventFormMetadata({bool forceRefresh = false})` sending authenticated `GET /api/events/form-metadata` with Bearer token.
  - Added background revalidation (`_refreshMetadataInBackground`) and local storage fallback.
- `lib/features/events/presentation/screen/event_reporting_screen.dart`:
  - Removed all hardcoded dropdown lists (`_eventOptions`, `_sectors`, `_villages`, `_locationTypes`, `_populationTypes`).
  - Added dynamic dropdowns with generic builder `_buildDropdownGeneric<T>`.
  - Bound Primary Sector to display dynamic `sectorName` and badge for `sectorCode`.
  - Bound Target Population label and options dynamically (`metadata.population.label`).
  - Dynamic expansion of text fields when selecting options where `is_other: true` ("Other").
  - Date picker constrained dynamically by `minDate` and `maxDate` from the backend.
  - Media upload limits dynamically rendered and enforced from `metadata.uploadLimits`.
  - Village selection dynamically populates location breadcrumb (`village › panchayat › block`).
  - Added pull-to-refresh to re-fetch configuration at any time.
- `test/features/events/event_form_metadata_test.dart`:
  - Added comprehensive unit and widget tests for JSON parsing, fallback creation, caching, and UI rendering.

### 2. Why This Approach? (Design Rationale & Architectural Decisions):
- **Volunteer-Specific Dynamic Configuration**: The backend returns `form-metadata` tailored specifically to the logged-in volunteer based on their assigned sector (e.g., Human Health, Animal Health), assigned villages/panchayats, allowed location types, and allowable media limits. Hardcoding any of these values breaks multi-sector volunteer workflows.
- **Zero Hardcoding**: All options—event types, target populations, villages, location types, primary sector, and upload limits—are sourced directly from the backend API.
- **Offline Resilience & Instant Rendering**: By persisting the metadata into `SessionManager` (`SharedPreferences`), the form opens instantaneously with the volunteer's cached options even when offline in remote field areas, while performing background revalidation when online.
- **Dynamic "Other" Input Triggers**: When options marked `is_other: true` (e.g., event type 68 or population option 7) are selected, dedicated text input fields dynamically expand, prompting the volunteer for clarification and capturing clean audit details.
- **Date Boundary Enforcement**: `min_date` and `max_date` from the API strictly limit the date picker range so volunteers cannot report events outside allowed surveillance windows.
- **Enriched Submission Contract**: `EventReportRequest` now passes both human-readable names and backend entity IDs (`event_type_id`, `village_lgd_code`, `target_population_id`, `primary_sector_code`), ensuring clean compatibility when binding the POST submission API.

### 3. Data Flow:
[EventReportingScreen Initializes]
              │
              ▼
    [SessionManager.getEventFormMetadata (Cache)]
              │ (Instant populate without UI flicker)
              ▼
    [EventApiService.getEventFormMetadata]
    (GET /api/events/form-metadata with Bearer token)
              │
         ┌────┴───────────────────────────┐
         ▼                                ▼
    [200 OK]                  [Offline / Server Error]
         │                                │
    [Parse EventFormMetadata]    [Read Stored Cache / Fallback]
         │                                │
         └───────────────┬────────────────┘
                         ▼
        [Cache to SessionManager (SharedPreferences)]
                         ▼
        [Dynamically Populate Event Form]
        ├── Sector Badge (e.g. Human Health / HUMAN)
        ├── Event Types Dropdown (ID + Name + Dynamic Other Field)
        ├── Date Range Lock ([minDate, maxDate])
        ├── Villages Dropdown (LGD Code, Name, Panchayat, Block)
        ├── Location Types Dropdown (Urban, Rural)
        ├── Target Population Dropdown (Dynamic Label & Options + Other Field)
        └── Upload Limits (Max photo/video/doc count & MB limits)


## [Feature: Event Report Submission API (POST /api/events)]
**Date:** 2026-10-17  
**Feature:** Section 7 Compliance: Event Report Multipart Form-Data Submission to Backend with Automatic Offline Sync Queueing

### 1. Files Added & Modified:
- `lib/core/constants/api_constants.dart`:
  - Defined `endpointEvents = '$baseUrl/events'` and mapped `endpointReportEvent = endpointEvents`.
- `lib/features/events/domain/event_models.dart`:
  - Updated `EventReportRequest` to strictly map to the OpenAPI `EventReportForm` specification:
    - Required: `event_type_id`, `date`, `time`, `village_lgd_code`, `purpose_of_visit`, `location_type`, `total_visits`, `population_type_id`.
    - Optional: `event_type_other`, `is_out_of_area`, `population_other`, `observations`, `action_taken`, `description`, `referral_generated`, `alert_generated`, `follow_up_required`, `latitude`, `longitude`, `gps_accuracy_m`, `gps_unavailable_reason`, `device_id`, `client_ref`.
    - Media attachments: `photos`, `videos`, `documents`.
  - Updated `EventReportResult` matching `EventReportResponse`:
    - `message`, `event_report_id`, `event_report_code`, `verification_status`, `alert_code`, `attachments`, `duplicate`, `status`.
- `lib/features/events/data/event_api_service.dart`:
  - Implemented `submitEventReport(EventReportRequest request)`:
    - Constructs `http.MultipartRequest('POST', Uri.parse(endpointEvents))` with `Authorization: Bearer <token>`.
    - Serializes all 20+ fields according to the OpenAPI schema.
    - Attaches local media files (`photos`, `videos`, `documents`) as multipart file streams.
    - Parses 201 Created response into `EventReportResult`.
    - Implemented offline fallback: if network is unreachable (`SocketException` / `ClientException`), the payload is enqueued into `SyncRepository` with entity type `'EVENT'`, ensuring zero field data loss.
- `lib/features/events/presentation/screen/event_reporting_screen.dart`:
  - Integrated `_handleSubmit()` to validate all mandatory fields, format ISO dates & times, construct `EventReportRequest`, and call `_apiService.submitEventReport`.
  - Separated media management into `_photos`, `_videos`, and `_documents` with chips, counter limits, and deletion support.
  - Added user feedback via SnackBar displaying the created `event_report_code` (e.g. `EVT-26-0005`) and returned `true` to notify caller.
- `test/features/events/event_form_metadata_test.dart`:
  - Added test cases verifying multipart form construction, Bearer token injection, 201 response parsing, and offline fallback queueing in `SyncRepository`.

### 2. Why This Approach? (Design Rationale & Architectural Decisions):
- **OpenAPI Schema Conformance**: The backend requires `multipart/form-data` with exact parameter types (integers for IDs, booleans as string flags, ISO 8601 date and time). Constructing an `http.MultipartRequest` guarantees that both text parameters and binary image/video streams are uploaded in a single atomic transaction.
- **Volunteer Sector Derivation**: As documented in the backend schema, the primary sector is linked server-side to the volunteer's registered COHV type. The mobile app passes the volunteer's active credentials in the Bearer token without attempting to override server sector rules.
- **Field Worker Offline Resilience**: Community One Health Volunteers frequently work in areas with poor or intermittent network connectivity. If the HTTP request fails due to network outage, the record is immediately enqueued into the local SQLite/SharedPreferences sync queue with an offline ID, ensuring volunteers never lose surveillance data.
- **Granular Error Handling**: When validation fails (HTTP 422), detailed backend messages (e.g. invalid date or character limits) are extracted and displayed in clear user-friendly notices.

### 3. Data Flow:
[User Completes Event Form]
           │
           ▼
[Form Validation Guard & Token Check]
           │
           ▼
[Construct EventReportRequest]
           │
           ▼
[EventApiService.submitEventReport]
(POST http://192.168.10.174:8000/api/events with Bearer Token)
           │
      ┌────┴────────────────────────────────┐
      ▼                                     ▼
 [201 Created]                  [Network Failure / Offline]
      │                                     │
 [Parse EventReportResponse]     [Enqueue into SyncRepository]
 (e.g. EVT-26-0005 / ALERT-26)   (status: 'queued_offline')
      │                                     │
      └──────────────────┬──────────────────┘
                         ▼
             [Display Success SnackBar]
                         ▼
             [Navigator.pop(context, true)]


## [Feature: Inline Searchable Dropdown Form Field Component Integration]
**Date:** 2026-10-17  
**Feature:** UI/UX Consistency: Inline Searchable Dropdown Overlay (identical to Volunteer Registration Form) for Event Reporting Form

### 1. Files Added & Modified:
- `lib/core/widgets/searchable_dropdown.dart`:
  - Created `SearchableDropdownFormField<T>`, a generic, reusable form field component matching the inline searchable dropdown architecture used in `volunteer_registration_screen.dart`.
  - Implemented `_InlineSearchableDropdown<T>` utilizing Flutter's `CompositedTransformTarget`, `CompositedTransformFollower`, and `LayerLink`:
    - Floating elevated material overlay (`elevation: 6`, `borderRadius: 12`) anchored directly 4px below the input field, exactly matching its width.
    - Inline search text input where users type directly to filter options in real time.
    - Up/down animated toggle chevron (`Icons.keyboard_arrow_up` / `Icons.keyboard_arrow_down`) in `AppColors.primary`.
    - Outside-tap auto-dismissal using `TapRegion(groupId: widget.fieldId)` on both the input field and the floating overlay.
    - Highlighted active selections with primary tint (`AppColors.primary.withValues(alpha: 0.08)`) and checkmark icons.
    - Item label, subtitle support (e.g. Block and Gram Panchayat hierarchy for villages), and multi-attribute search matching.
    - Error state handling with red border and error message rendering below the input field.
- `lib/features/events/presentation/screen/event_reporting_screen.dart`:
  - Updated `_buildDropdownGeneric<T>` to delegate directly to `SearchableDropdownFormField<T>` with unique `fieldId`s:
    1. **Event Type** (`fieldId: 'event_type'`): Inline typing filters 21+ backend events.
    2. **Village / Ward** (`fieldId: 'village_ward'`): Inline typing filters across Village, Gram Panchayat, and Block names.
    3. **Type of Location** (`fieldId: 'location_type'`): Inline typing filters location categories (Urban, Rural, etc.).
    4. **Target Population** (`fieldId: 'target_population'`): Inline typing filters dynamic backend target demographics.
- `test/core/widgets/searchable_dropdown_test.dart`:
  - Unit and widget tests verifying inline overlay display, keystroke filtering (e.g. typing "h" as in the volunteer registration screenshot), item selection, and FormState validation.
- `test/features/events/event_form_metadata_test.dart`:
  - Updated widget test verifying inline event type search, typing "clusters", real-time filtering, item selection, and form display.

### 2. Design Rationale & Usability Decisions:
- **Design Consistency**: Replicates the exact inline design established in `VolunteerRegistrationScreen` (as shown in the user's reference screenshot with the "h" filter and floating list).
- **Smooth Inline Interaction**: Users type directly into the form field; the dropdown overlay appears attached right below the field without opening a bottom sheet, keeping surrounding form context visible.

### 3. Data Flow:
[User Taps Dropdown Field]
            │
            ▼
[FocusNode Requests Focus -> Open Floating Overlay Entry]
            │
    ┌───────┴────────────────────────┐
    ▼                                ▼
[Browse Full Options List]   [Type Directly in Text Field]
    │                                │
    │                        [Real-Time Filter via searchMatcher / itemLabel]
    │                                │
    └───────────────┬────────────────┘
                    ▼
          [Tap Desired Option]
                    │
                    ▼
    [Set Controller Text, Unfocus FocusNode, Remove Overlay]
                    │
                    ▼
     [state.didChange(selected) & onChanged(selected)]
                    │
                    ▼
  [Update Field Display & FormState Validated]







