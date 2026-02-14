# Finn - Setup Supabase

## 🎯 Configurazione Completa

Finn è configurato per usare **Supabase self-hosted** sul VPS 8020solutions.org.

### 📦 Ambienti Disponibili

- **Development** → Supabase Dev (https://dev.8020solutions.org)
- **Production** → Supabase Prod (https://api.8020solutions.org)

---

## 🚀 Setup sul PC Locale

### 1. Installare Dipendenze

```bash
cd finn
flutter pub get
```

### 2. Configurare Ambiente

I file `.env.dev` e `.env.prod` sono già configurati con gli endpoint corretti:

**Development (.env.dev):**
```env
SUPABASE_URL=https://dev.8020solutions.org
SUPABASE_ANON_KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
```

**Production (.env.prod):**
```env
SUPABASE_URL=https://api.8020solutions.org
SUPABASE_ANON_KEY=sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH
```

### 3. Lanciare l'App

**Development (consigliato):**
```bash
./scripts/run_dev.sh
```

**Production:**
```bash
./scripts/run_prod.sh
```

**Manuale (se script non funziona):**
```bash
# Development
cp .env.dev .env
flutter run

# Production
cp .env.prod .env
flutter run --release
```

---

## 🔍 Verifica Connessione

### Test API:
```bash
curl https://dev.8020solutions.org/
```

### Studio UI (via tunnel temporaneo):
```bash
ssh -L 54323:127.0.0.1:54323 root@46.225.60.101
```
Poi: http://localhost:54323

---

## ⚠️ Troubleshooting

**Errore: "SUPABASE_URL not configured"**
→ Assicurati che esista il file `.env` nella root del progetto
→ Lo script `run_dev.sh` lo crea automaticamente

**Errore: "Connection refused"**
→ Verifica che Supabase sia attivo sul VPS:
```bash
ssh root@46.225.60.101 "cd ~/supabase-cli && supabase status"
```

**Errore: "Invalid API key"**
→ Verifica che la chiave in `.env.dev` sia corretta

---

## 📝 Note Importanti

- **Nessun tunnel SSH necessario!** Tutto via HTTPS
- I file `.env*` sono già in `.gitignore`
- `flutter_dotenv` legge automaticamente da `.env`
- Hot reload funziona normalmente
- Le migrazioni Supabase sono in `supabase/migrations/`

---

## 🎉 Ready to Code!

Ora puoi sviluppare Finn con Supabase backend sempre disponibile! 💰😎
