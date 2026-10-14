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
