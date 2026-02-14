# Finn - Setup Supabase

## 🎯 Configurazione Completa

Finn è configurato per usare **Supabase self-hosted** su VPS CiccioHouse (80/20 Solutions).

### 📦 Ambienti Disponibili

- **Development** → Supabase Dev (https://dev.8020solutions.org)
- **Production** → Supabase Prod (https://api.8020solutions.org)

---

## 🚀 Setup Locale

### 1. Installare Dipendenze

```bash
cd finn
flutter pub get
```

### 2. Configurazione Ambiente

I file `.env.dev` e `.env.prod` sono già configurati con le credenziali corrette.

**NON servono modifiche** per iniziare a sviluppare!

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
# Copia ambiente
cp .env.dev .env

# Lancia app
flutter run
```

---

## 🔍 Verifica Connessione

### Test API da terminale:
```bash
curl https://dev.8020solutions.org/
```

### Studio UI (Browser):
- Dev Studio: Accesso via VPS (SSH tunnel temporaneo se necessario)
- Prod Studio: Accesso via VPS

### Database Diretto:
```
# Via SSH tunnel (se necessario)
ssh -L 54322:127.0.0.1:54322 root@46.225.60.101

# Poi connetti con:
postgresql://postgres:postgres@localhost:54322/postgres
```

---

## 📝 File Configurazione

```
.env.dev      → Development (dev.8020solutions.org)
.env.prod     → Production (api.8020solutions.org)
.env.example  → Template (per riferimento)
```

**⚠️ NON committare mai** `.env.dev` o `.env.prod`! Sono in `.gitignore`.

---

## 🆚 Prima vs Dopo

### PRIMA (Tunnel SSH)
```
❌ Serviva tunnel: ssh -L 54321:...
❌ Solo localhost
⚠️ HTTP non sicuro
```

### DOPO (HTTPS Diretto)
```
✅ Nessun tunnel necessario
✅ Accessibile ovunque
✅ HTTPS con SSL
✅ Più semplice da debuggare
```

---

## ⚠️ Troubleshooting

**Errore: "SUPABASE_URL not configured"**
→ Assicurati che `.env` esista (copiato da `.env.dev` o `.env.prod`)

**Errore: "Connection refused"**
→ Verifica che Supabase Dev sia running sul VPS:
```bash
ssh root@46.225.60.101 "cd ~/supabase-cli && supabase status"
```

**Errore: "SSL certificate problem"**
→ Verifica certificato SSL:
```bash
curl -v https://dev.8020solutions.org 2>&1 | grep -i ssl
```

---

## 🎉 Ready to Code!

Ora puoi sviluppare in locale con:
- ✅ Hot reload completo
- ✅ Backend VPS sicuro
- ✅ Dev/Prod separati
- ✅ Zero tunnel SSH

**Buon coding! 💰📊**
