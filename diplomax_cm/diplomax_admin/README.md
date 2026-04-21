# Diplomax Admin Portal

**Web-based system administration portal for the Diplomax CM platform.**

A complete Flutter Web app for Diplomax superadmins and Ministry of Education officials to manage institutions, approve registrations, create sub-admins, monitor audit logs, and configure platform settings.

## Features

### Institution Management
- View all institution registration applications (pending, under review, approved, rejected, suspended)
- Mark applications as "under review" 
- Approve institutions → auto-generate API keys and staff credentials
- Reject applications with custom reasons
- Suspend active institutions (disable all access)
- Reinstate suspended institutions
- Force-rotate API keys
- View institution details, uploaded documents, and activity history

### Sub-Admin Management (Superadmin only)
- Create new admin accounts with any role
- Auto-generate temporary passwords (sent via email)
- Suspend/reinstate admin accounts
- Delete admin accounts
- Change admin roles on the fly

### Audit Logs
- Complete immutable audit trail of every admin action
- Filter by: admin, institution, action, date range
- Export logs as CSV for compliance reports

### Platform Settings (Superadmin only)
- Configure certification fees (diploma, transcript, certificate, attestation)
- Adjust revenue split percentages (treasury, university, platform)
- Set security parameters (max login attempts, lockout duration)
- Toggle maintenance mode to disable all user logins

### Role-Based Access Control (4-tier hierarchy)
1. **diplomax_superadmin** — Full control (Bassa Joëlle by default)
2. **diplomax_admin** — Manage institutions, view data, create sub-admins
3. **ministry_superadmin** — Approve/reject institutions, view all data, export reports
4. **ministry_analyst** — Read-only analytics and institution list

## Demo Credentials

```
Email: admin@diplomax.cm
Password: DiplomaxAdmin2024!
```

## Running Locally

### Prerequisites
- Flutter 3.0+
- .NET 8+ (for backend API)
- Dart SDK

### Setup

1. **Clone the repository** and navigate to the admin app:
   ```bash
   cd diplomax_cm/diplomax_admin
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Set backend API URL** (via dart-define):
   ```bash
   flutter run -d chrome \
     --dart-define=API_BASE_URL=http://localhost:8000/v1 \
     --dart-define=ADMIN_EMAIL=admin@diplomax.cm \
     --dart-define=ADMIN_PASSWORD=DiplomaxAdmin2024!
   ```
   
   Or in Android Studio:
   - Run → Edit Configurations
   - Add arguments: `--dart-define=API_BASE_URL=http://localhost:8000/v1`
   - Select Chrome as run target
   - Press Run

4. **Access the admin portal**:
   - Opens at `http://localhost:PORT` (typically 54321)
   - Login with demo credentials above

## Architecture

### Directory Structure
```
diplomax_admin/
├── lib/
│   ├── main.dart                        # Entry point with routing
│   ├── features/
│   │   ├── auth/screens/login_screen.dart
│   │   ├── dashboard/screens/admin_dashboard_screen.dart
│   │   ├── institutions/screens/
│   │   │   ├── institutions_screen.dart
│   │   │   └── institution_detail_screen.dart
│   │   ├── admins/screens/admins_management_screen.dart
│   │   ├── audit/screens/audit_logs_screen.dart
│   │   └── settings/screens/platform_settings_screen.dart
│   └── l10n/app_strings.dart            # Localization (EN/FR)
├── pubspec.yaml
├── analysis_options.yaml
└── web/
    └── index.html
```

### Key Dependencies
- **flutter_riverpod** — State management
- **go_router** — Client-side routing
- **dio** — HTTP client
- **google_fonts** — Typography
- **jwt_decoder** — Token parsing

## API Endpoints Used

All endpoints use `/v1/admin/` prefix:

### Institutions
- `GET /institutions/pending` — List pending applications
- `POST /institutions/{id}/approve` — Approve institution
- `POST /institutions/{id}/reject` — Reject institution
- `POST /institutions/{id}/under-review` — Mark as under review
- `POST /institutions/{id}/suspend` — Suspend institution
- `POST /institutions/{id}/reinstate` — Reinstate institution
- `GET /institutions/{id}/detail` — Full institution details

### Admins
- `POST /admins/create` — Create new admin
- `GET /admins` — List all admins
- `POST /admins/{id}/role` — Change admin role
- `POST /admins/{id}/suspend` — Suspend/reinstate admin

### Audit Logs
- `GET /audit-logs` — List audit logs (with filtering)

### Platform Settings
- `GET /settings` — Get current settings
- `PATCH /settings` — Update settings

### Dashboard
- `GET /dashboard` — Dashboard analytics

## Responsive Design

- **Desktop (1200px+)**: Full sidebar + multi-column layouts
- **Tablet (768-1200px)**: Adaptive two-column layouts
- **Mobile (< 768px)**: Single column with hamburger menu

## Security

- **JWT Bearer tokens** — Issued by `/v1/auth/login` endpoint
- **RBAC** — Enforced at API level (admin must have correct role)
- **Audit logging** — Every action recorded with IP, timestamp, admin email
- **Session management** — FlutterSecureStorage for token persistence
- **HTTPS only** — SSL pinning for production

## Localization

The admin portal supports:
- **English** — Default
- **French** — Same UI, translated strings

Switch language via locale controls (settings in future releases).

## Testing

### Manual Testing Checklist
- [ ] Login with valid credentials
- [ ] Dashboard displays correct counts
- [ ] Create new admin account
- [ ] Approve/reject pending institutions
- [ ] View institution audit trail
- [ ] Change platform settings and verify persistence
- [ ] Logout and login again (session recovery)

### Test Accounts
```
email: admin@diplomax.cm
password: DiplomaxAdmin2024!
role: diplomax_superadmin

email: analyst@diplomax.cm
password: DiplomaxAnalyst2024!
role: ministry_analyst
```

## Deployment

### To Azure App Service (Static Web App)

1. Build for release:
   ```bash
   flutter build web --release
   ```

2. Deploy via Azure Static Web Apps:
   ```bash
   az staticwebapp create \
     --name diplomax-admin \
     --resource-group diplomax-rg \
     --source ./build/web
   ```

### Environment Variables (Required)
- `API_BASE_URL` — Backend API base URL (e.g., https://diplomax-backend.azurewebsites.net/v1)
- `ADMIN_EMAIL` — Default admin email (e.g., admin@diplomax.cm)
- `ADMIN_PASSWORD` — Default admin password

## Development

### Adding a New Feature

1. Create feature folder under `lib/features/`
2. Add screens and providers
3. Update routing in `lib/main.dart`
4. Add localized strings to `lib/l10n/app_strings.dart`
5. Test on Chrome desktop first, then mobile

### Building Custom Widgets

Use the existing color constants:
```dart
const _G = Color(0xFF0F6E56);        // Green primary
const _GL = Color(0xFFE1F5EE);       // Green light (backgrounds)
const _BG = Color(0xFFF7F6F2);       // Page background
const _SUR = Color(0xFFFFFFFF);      // Surface (white)
const _T1 = Color(0xFF1A1A1A);       // Text primary (dark)
const _T2 = Color(0xFF6B6B6B);       // Text secondary (gray)
const _BD = Color(0xFFE0DDD5);       // Border/divider
```

## Troubleshooting

### Build errors
- Ensure `flutter pub get` completed successfully  
- Check Dart SDK version: `flutter --version`
- Run `flutter clean && flutter pub get` to reset

### API connection errors
- Verify `--dart-define=API_BASE_URL` is set correctly
- Ensure backend is running: `curl http://localhost:8000/healthz`
- Check browser console (F12) for CORS/SSL issues

### Login always fails
- Verify admin exists in database (check backend logs)
- Confirm credentials match `/v1/admin` endpoint expectations
- Check JWT secret is correctly configured

## Contributing

Admin portal updates should:
1. Maintain consistent UI design (use existing color/typography)
2. Include audit log entries for compliance
3. Add appropriate role checks on all actions
4. Test across Chrome, Firefox, Safari
5. Follow Flutter/Dart style guidelines (dartfmt)

## License

Proprietary — Diplomax CM 2024

## Support

For issues or questions:
- Backend API issues: Check `diplomax_cm/backend/` README
- Flutter issues: See [Flutter Documentation](https://flutter.dev/docs)
- Diplomax support: admin@diplomax.cm
