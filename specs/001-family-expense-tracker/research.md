# Research: Family Expense Tracker

**Date**: 2025-12-19
**Feature**: 001-family-expense-tracker

## Technology Decisions

### 1. Mobile Framework

**Decision**: Flutter 3.x with Dart

**Rationale**:
- Single codebase for Android (primary) with iOS potential
- Rich UI components for dashboards and charts
- Strong camera/image handling packages
- Active community and extensive package ecosystem
- User mentioned "flutter?" indicating preference

**Alternatives Considered**:
- **Native Kotlin/Android**: Better performance but limits future iOS expansion
- **React Native**: Good option but Flutter has better performance for image-heavy apps
- **Kotlin Multiplatform**: Emerging but less mature ecosystem

---

### 2. Backend/BaaS

**Decision**: Supabase

**Rationale**:
- Built-in authentication (email/password, social login ready)
- PostgreSQL database with Row Level Security (RLS) for group-based access
- Real-time subscriptions for group expense updates
- Storage for receipt images
- Free tier sufficient for initial development and small user base
- Open source, can self-host if needed later

**Alternatives Considered**:
- **Firebase**: Good option but vendor lock-in concerns, Firestore query limitations
- **Custom backend (FastAPI/Node)**: More control but significantly more development time
- **AWS Amplify**: More complex setup, overkill for MVP

---

### 3. Receipt OCR/AI Service

**Decision**: Google Cloud Vision API

**Rationale**:
- High accuracy for document/receipt text extraction
- Good support for Italian text
- Structured data extraction (DOCUMENT_TEXT_DETECTION)
- Pay-per-use pricing, free tier for development
- Well-documented Flutter integration

**Alternatives Considered**:
- **Tesseract (on-device)**: Free but lower accuracy, especially for Italian receipts
- **AWS Textract**: Similar quality but more complex setup
- **Azure Computer Vision**: Good alternative, similar pricing
- **ML Kit (Google)**: On-device option but less accurate for receipts

**Implementation Notes**:
- Use TEXT_DETECTION for basic extraction
- Post-process with regex patterns for Italian receipt formats
- Extract: total (TOTALE, IMPORTO), date (various formats), merchant (header/footer)

---

### 4. State Management

**Decision**: Riverpod 2.x

**Rationale**:
- Compile-time safety with code generation
- Easy testing and dependency injection
- Good separation of concerns
- Works well with async operations (Supabase calls)
- Active maintenance and Flutter team recommendations

**Alternatives Considered**:
- **Provider**: Simpler but less type-safe
- **BLoC**: More boilerplate, better for very large apps
- **GetX**: Less structured, harder to test

---

### 5. Local Storage/Caching

**Decision**: Drift (SQLite) + Hive for preferences

**Rationale**:
- Drift: Type-safe SQLite for expense data caching
- Hive: Fast key-value storage for user preferences, tokens
- Both work well offline (for future offline support)
- Drift schema matches Supabase for easy sync

**Alternatives Considered**:
- **sqflite directly**: More manual, less type-safe
- **Isar**: Good but Drift more mature
- **SharedPreferences only**: Not suitable for structured data

---

### 6. Charts/Visualization

**Decision**: fl_chart

**Rationale**:
- Highly customizable for expense dashboards
- Supports pie charts (categories), bar charts (time periods), line charts (trends)
- Good performance with reasonable data sets
- Active maintenance

**Alternatives Considered**:
- **syncfusion_flutter_charts**: More features but licensing costs
- **charts_flutter**: Official but less actively maintained
- **graphic**: Newer, less documentation

---

### 7. Camera & Image Handling

**Decision**: camera + image_picker packages

**Rationale**:
- `camera`: Direct camera control for receipt capture
- `image_picker`: Gallery selection as backup
- `image_cropper`: Allow user to crop receipt before OCR
- Standard Flutter packages, well maintained

---

### 8. Authentication Flow

**Decision**: Supabase Auth with email/password

**Rationale**:
- Simple email/password for MVP (matches FR-001)
- Password reset via email built-in (matches User Story 1)
- JWT tokens handled automatically
- Can add social login later without code changes

**Implementation Notes**:
- Minimum password: 8 characters
- Email verification optional for MVP (can enable later)
- Session persistence via secure storage

---

### 9. Group Invite System

**Decision**: 6-character alphanumeric codes with 7-day expiry

**Rationale**:
- Easy to share verbally or via message
- Short enough to type manually
- 7-day expiry balances security and convenience (per clarification)
- Stored in Supabase with created_at timestamp

**Implementation**:
- Generate: Random 6 chars (A-Z, 0-9, excluding confusable: 0/O, 1/I/L)
- Validate: Check exists, not expired, group not full
- One-time use: Delete after successful join

---

## Security Considerations

1. **Row Level Security (RLS)** on all Supabase tables:
   - Users can only see their own data
   - Group members can see group expenses
   - Admins have delete permissions on group expenses

2. **Secure Storage** for tokens (flutter_secure_storage)

3. **Image Upload**: Signed URLs with expiry for receipt images

4. **API Keys**: Google Cloud Vision key stored server-side (Supabase Edge Function) to avoid exposure in app

---

## Performance Strategy

1. **Pagination**: Load expenses in batches (20-50 items)
2. **Local Cache**: Store recent expenses in Drift for instant load
3. **Image Compression**: Compress receipts before upload (max 1MB)
4. **Lazy Loading**: Dashboard charts load data on-demand by period

---

## Development Phases Alignment

| User Story | Primary Technologies |
|------------|---------------------|
| US1 (Auth) | Supabase Auth, flutter_secure_storage |
| US2 (Groups) | Supabase DB + RLS, invite code generation |
| US3 (Scanner) | camera, Google Cloud Vision, Supabase Storage |
| US4 (Dashboard) | fl_chart, Riverpod, Drift caching |
