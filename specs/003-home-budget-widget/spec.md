# Feature Specification: Home Screen Budget Widget

**Feature Branch**: `003-home-budget-widget`
**Created**: 2025-12-31
**Status**: Draft
**Input**: Widget nativo per home screen Android/iOS che permette di aggiungere spese rapidamente senza aprire l'app, mostrando budget mensile corrente con barra progresso visiva e due pulsanti per scansione scontrino o inserimento manuale.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - At-a-Glance Budget Monitoring (Priority: P1)

Un utente vuole controllare rapidamente il proprio budget mensile direttamente dalla home screen del telefono, senza aprire l'app, per sapere quanto ha speso e quanto budget rimane disponibile.

**Why this priority**: Fornisce il valore core del widget - visibilità immediata del budget. Gli utenti possono prendere decisioni di spesa informate in pochi secondi guardando la home screen.

**Independent Test**: Installare il widget sulla home screen e verificare che mostri: importo speso corrente, limite mensile, percentuale di utilizzo e barra di progresso. Tap sul widget deve aprire l'app sulla Dashboard.

**Acceptance Scenarios**:

1. **Given** l'utente ha installato il widget sulla home screen, **When** visualizza la home screen, **Then** il widget mostra il budget del mese corrente con: "€450 / €800 (56%)" e una barra di progresso visiva al 56%
2. **Given** l'utente ha speso €750 su budget di €800, **When** visualizza il widget, **Then** il widget mostra un indicatore visivo di attenzione (es. colore arancione/rosso) per budget quasi esaurito
3. **Given** l'utente tappa sul widget nella sezione budget, **When** l'app si apre, **Then** viene mostrata la Dashboard con le statistiche complete
4. **Given** sono state aggiunte nuove spese nell'app, **When** l'utente torna alla home screen, **Then** il widget mostra i valori aggiornati del budget
5. **Given** è iniziato un nuovo mese, **When** l'utente visualizza il widget, **Then** mostra i dati del nuovo mese corrente con il contatore azzerato

---

### User Story 2 - Quick Expense Entry from Home Screen (Priority: P2)

Un utente vuole aggiungere velocemente una spesa direttamente dalla home screen usando lo scanner scontrino o il form manuale, senza dover aprire l'app, navigare nei menu, e trovare il pulsante di aggiunta.

**Why this priority**: Riduce drasticamente la friction per aggiungere spese (da 5-6 tap a 1-2 tap), aumentando la probabilità che gli utenti registrino tutte le spese in tempo reale.

**Independent Test**: Dal widget, tappare "Scansiona" e verificare che l'app si apra direttamente sulla fotocamera scanner. Tappare "Manuale" e verificare che l'app si apra direttamente sul form di inserimento manuale.

**Acceptance Scenarios**:

1. **Given** l'utente ha installato il widget, **When** tappa sul pulsante "Scansiona Scontrino", **Then** l'app si apre immediatamente sulla schermata della fotocamera scanner
2. **Given** l'utente ha installato il widget, **When** tappa sul pulsante "Inserimento Manuale", **Then** l'app si apre immediatamente sul form di inserimento manuale spesa
3. **Given** l'app non è in esecuzione in background, **When** l'utente tappa un pulsante del widget, **Then** l'app si avvia e mostra la schermata corretta entro 2 secondi
4. **Given** l'utente tappa "Scansiona" dal widget, **When** completa la scansione e salva, **Then** tornando alla home screen vede il budget aggiornato nel widget

---

### User Story 3 - Responsive Widget Sizes and Themes (Priority: P3)

Un utente vuole scegliere tra diverse dimensioni del widget (piccolo, medio, grande) per adattarlo al proprio layout della home screen, e vuole che il widget rispetti automaticamente il tema chiaro/scuro del sistema operativo.

**Why this priority**: Migliora la flessibilità e l'integrazione estetica del widget, ma il valore core (budget monitoring e quick access) è già fornito dalle P1 e P2.

**Independent Test**: Aggiungere il widget in diverse dimensioni (small, medium, large) e verificare che il layout si adatti. Cambiare il tema del sistema da chiaro a scuro e verificare che il widget aggiorni i colori automaticamente.

**Acceptance Scenarios**:

1. **Given** l'utente aggiunge il widget in size "Small", **When** visualizza la home screen, **Then** vede un widget compatto con budget e percentuale, senza pulsanti dettagliati
2. **Given** l'utente aggiunge il widget in size "Medium", **When** visualizza la home screen, **Then** vede budget completo con barra progresso e 2 pulsanti affiancati (Scansiona, Manuale)
3. **Given** l'utente aggiunge il widget in size "Large", **When** visualizza la home screen, **Then** vede budget dettagliato, barra progresso estesa, e pulsanti grandi ben spaziati
4. **Given** il sistema operativo è in tema scuro, **When** l'utente visualizza il widget, **Then** il widget usa colori scuri per background e chiari per testo
5. **Given** l'utente cambia da tema chiaro a scuro, **When** torna alla home screen, **Then** il widget si è automaticamente aggiornato al tema scuro

---

### Edge Cases

- **Nessuna connessione dati**: Il widget mostra l'ultimo budget caricato con un indicatore "Dati non aggiornati". Tap sui pulsanti apre comunque l'app.
- **Utente non autenticato**: Se l'utente esegue logout dall'app, il widget mostra un messaggio "Accedi per visualizzare budget" con un pulsante per aprire il login.
- **Primo utilizzo senza budget impostato**: Il widget mostra "Budget non configurato" con pulsante "Configura" che apre l'app sulle impostazioni.
- **Dispositivo con spazio limitato**: Se l'utente prova ad aggiungere il widget ma la home screen è piena, il sistema mostra il normale messaggio di errore del OS.
- **Widget rimosso e ri-aggiunto**: Il widget ricarica i dati correnti dal backend al prossimo refresh.
- **Budget superato (speso più del limite)**: Il widget mostra la percentuale oltre il 100% (es. "€950 / €800 (119%)") con colore rosso.
- **Cambio di gruppo famiglia**: Se l'utente cambia il gruppo attivo nell'app, il widget si aggiorna mostrando il budget del nuovo gruppo.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Il widget DEVE mostrare il budget mensile corrente del gruppo famiglia dell'utente nel formato "€[speso] / €[limite] ([percentuale]%)"
- **FR-002**: Il widget DEVE mostrare una barra di progresso visiva che rappresenta la percentuale di budget utilizzato
- **FR-003**: Il widget DEVE fornire un pulsante "Scansiona Scontrino" che apre l'app direttamente sulla schermata della fotocamera scanner
- **FR-004**: Il widget DEVE fornire un pulsante "Inserimento Manuale" che apre l'app direttamente sul form di inserimento spesa
- **FR-005**: Il widget DEVE aggiornarsi automaticamente quando vengono aggiunte nuove spese nell'app
- **FR-006**: Il widget DEVE supportare il tap sulla sezione budget per aprire l'app sulla Dashboard
- **FR-007**: Il widget DEVE essere disponibile per dispositivi Android
- **FR-008**: Il widget DEVE essere disponibile per dispositivi iOS
- **FR-009**: Il widget DEVE supportare tema chiaro e tema scuro, adattandosi automaticamente alle impostazioni di sistema
- **FR-010**: Il widget DEVE supportare almeno 3 dimensioni: piccola, media, e grande
- **FR-011**: Il widget DEVE mostrare il nome del mese corrente (es. "Dicembre 2025") o un indicatore temporale
- **FR-012**: Il widget DEVE calcolare il totale speso sommando tutte le spese del gruppo nel mese corrente
- **FR-013**: Il widget DEVE gestire stati di errore (no connessione, utente non autenticato, budget non configurato) con messaggi appropriati
- **FR-014**: I pulsanti del widget DEVONO aprire l'app sulla schermata corretta (Dashboard, Scanner, Inserimento Manuale)
- **FR-015**: Il widget DEVE aggiornare i dati ad intervalli regolari anche quando l'app non è aperta

### Key Entities

- **Monthly Budget**: Il budget totale allocato per il mese corrente del gruppo famiglia (es. €800/mese). Include: periodo (mese/anno), limite impostato, gruppo di riferimento.
- **Budget Progress**: Lo stato corrente del budget calcolato sommando tutte le spese del mese. Include: totale speso, percentuale utilizzata, giorni rimanenti nel mese.
- **Widget Configuration**: Le preferenze dell'utente per il widget. Include: dimensione selezionata, tema preferito (auto/chiaro/scuro), frequenza di refresh.
- **User Group**: Il gruppo famiglia a cui appartiene l'utente e per cui viene calcolato il budget. Include: ID gruppo, membri, budget condiviso.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Gli utenti possono visualizzare il budget mensile corrente dalla home screen in meno di 1 secondo (senza aprire l'app)
- **SC-002**: Il tap su "Scansiona" o "Manuale" apre l'app sulla schermata corretta in meno di 2 secondi
- **SC-003**: Il widget si aggiorna entro 30 secondi dall'aggiunta di una nuova spesa nell'app
- **SC-004**: Il widget è compatibile con la maggior parte dei dispositivi Android e iOS moderni in uso
- **SC-005**: Il tempo medio per aggiungere una spesa si riduce del 60% (da ~30 secondi a ~12 secondi) grazie all'accesso diretto dal widget
- **SC-006**: Il widget consuma meno di 5MB di RAM quando attivo sulla home screen
- **SC-007**: Il widget è responsive e si adatta correttamente ad almeno 3 size diverse (small, medium, large)
- **SC-008**: Il widget si adatta automaticamente al tema del sistema (chiaro/scuro) in meno di 1 secondo dal cambio tema
- **SC-009**: Il widget mostra sempre dati accurati aggiornati al massimo entro 5 minuti dall'ultima modifica

## Scope *(mandatory)*

### In Scope

- Widget nativo per dispositivi Android
- Widget nativo per dispositivi iOS
- Visualizzazione budget mensile corrente con barra progresso
- 2 pulsanti accesso rapido: Scansiona Scontrino, Inserimento Manuale
- Apertura diretta dell'app sulla schermata corretta quando si tappa un pulsante
- Aggiornamento automatico widget quando si aggiungono spese
- Supporto temi chiaro/scuro automatico
- 3 dimensioni widget: piccola, media, grande
- Stati di errore: no connessione, non autenticato, budget non configurato
- Aggiornamento dati anche quando l'app è chiusa

### Out of Scope

- Inserimento spese direttamente dal widget (senza aprire app) - limitazioni tecniche delle piattaforme
- Widget per tablet o smartwatch
- Personalizzazione colori o font del widget
- Multiple widgets per diversi gruppi famiglia contemporaneamente
- Notifiche push quando si avvicina al limite budget
- Widget per web app o desktop
- Cronologia delle spese visualizzata nel widget
- Grafici o statistiche dettagliate nel widget
- Widget interattivi con form input diretto (limitazioni tecniche)

## Assumptions *(mandatory)*

1. **Budget mensile esiste**: Si assume che il gruppo famiglia abbia già configurato un budget mensile nell'app. Se non configurato, il widget mostra un prompt per la configurazione.
2. **Autenticazione persistente**: L'utente rimane autenticato anche quando l'app non è aperta, permettendo al widget di caricare dati automaticamente.
3. **Permessi di sistema**: L'utente ha concesso i permessi necessari per aggiornamento automatico e accesso alla fotocamera (per scanner).
4. **Connessione dati**: Il dispositivo ha accesso a internet (WiFi o dati mobili) per aggiornare i dati del widget. In assenza, mostra ultimi dati disponibili.
5. **Spazio home screen**: L'utente ha spazio disponibile sulla home screen per aggiungere il widget nella dimensione desiderata.
6. **Sistema operativo compatibile**: Dispositivo Android o iOS con versione sufficientemente recente per supportare widget nativi (Android 4.1+ o iOS 14+).
7. **Aggiornamento automatico abilitato**: L'utente ha abilitato l'aggiornamento automatico nelle impostazioni del dispositivo.

## Dependencies *(optional)*

### User Dependencies

- L'utente deve aver già installato e configurato l'app Fin
- L'utente deve appartenere a un gruppo famiglia con budget mensile configurato
- L'utente deve aver eseguito login almeno una volta nell'app

## Risks *(optional)*

### Technical Risks

- **Limitazioni piattaforme mobile**: I sistemi operativi non permettono widget completamente interattivi (no inserimento testo diretto). Soluzione: i pulsanti aprono l'app per l'inserimento dati.
- **Limitazioni aggiornamento automatico**: I sistemi operativi limitano l'aggiornamento automatico per preservare la batteria. Rischio: dati non sempre aggiornati in tempo reale. Mitigazione: mostrare timestamp "Aggiornato X minuti fa".
- **Autenticazione sicura**: Mantenere l'utente autenticato per l'aggiornamento automatico senza compromettere la sicurezza. Mitigazione: sistema di autenticazione sicuro con scadenza controllata.
- **Performance del widget**: Widget troppo complessi possono rallentare la home screen del telefono. Mitigazione: interfaccia minimale e ottimizzata.

### User Experience Risks

- **Dati sensibili visibili**: Il budget è visibile a chiunque veda la home screen del telefono. Mitigazione: opzione per nascondere importi (mostrare solo percentuale).
- **Widget non si aggiorna**: Se background refresh fallisce, utente vede dati vecchi. Mitigazione: mostrare chiaramente timestamp ultimo aggiornamento.
- **Confusione multi-gruppo**: Se utente appartiene a più gruppi famiglia, potrebbe non essere chiaro quale budget mostra. Mitigazione: mostrare nome gruppo nel widget.
