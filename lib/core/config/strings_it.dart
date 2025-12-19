/// Italian string resources for the application.
/// All user-facing strings should be defined here for easy localization.
class StringsIt {
  StringsIt._();

  // App
  static const appName = 'Family Expense Tracker';
  static const appVersion = 'v1.0.0';

  // Common actions
  static const save = 'Salva';
  static const cancel = 'Annulla';
  static const delete = 'Elimina';
  static const edit = 'Modifica';
  static const confirm = 'Conferma';
  static const retry = 'Riprova';
  static const close = 'Chiudi';
  static const back = 'Indietro';
  static const next = 'Avanti';
  static const done = 'Fatto';
  static const search = 'Cerca';
  static const filter = 'Filtra';
  static const refresh = 'Aggiorna';
  static const loading = 'Caricamento...';
  static const noData = 'Nessun dato';
  static const error = 'Errore';

  // Auth
  static const login = 'Accedi';
  static const logout = 'Esci';
  static const register = 'Registrati';
  static const forgotPassword = 'Password dimenticata?';
  static const resetPassword = 'Reimposta password';
  static const email = 'Email';
  static const password = 'Password';
  static const confirmPassword = 'Conferma password';
  static const displayName = 'Nome';
  static const loginTitle = 'Accedi al tuo account';
  static const registerTitle = 'Crea un nuovo account';
  static const forgotPasswordTitle = 'Reimposta la password';
  static const noAccountYet = 'Non hai un account?';
  static const alreadyHaveAccount = 'Hai già un account?';
  static const resetPasswordInstructions =
      'Inserisci la tua email e ti invieremo un link per reimpostare la password.';
  static const resetPasswordSuccess =
      'Email inviata! Controlla la tua casella di posta.';

  // Validation
  static const emailRequired = 'Inserisci la tua email';
  static const emailInvalid = 'Inserisci un indirizzo email valido';
  static const passwordRequired = 'Inserisci la password';
  static String passwordTooShort(int minLength) =>
      'La password deve avere almeno $minLength caratteri';
  static const passwordsDoNotMatch = 'Le password non corrispondono';
  static const nameRequired = 'Inserisci il tuo nome';
  static String nameTooShort(int minLength) =>
      'Il nome deve avere almeno $minLength caratteri';
  static String nameTooLong(int maxLength) =>
      'Il nome può avere massimo $maxLength caratteri';
  static const nameInvalidChars = 'Il nome contiene caratteri non validi';

  // Groups
  static const groups = 'Gruppi';
  static const createGroup = 'Crea gruppo';
  static const joinGroup = 'Unisciti a un gruppo';
  static const leaveGroup = 'Abbandona gruppo';
  static const deleteGroup = 'Elimina gruppo';
  static const groupName = 'Nome del gruppo';
  static const groupMembers = 'Membri';
  static const inviteCode = 'Codice invito';
  static const copyInviteCode = 'Copia codice';
  static const inviteCodeCopied = 'Codice copiato!';
  static const generateNewCode = 'Genera nuovo codice';
  static const enterInviteCode = 'Inserisci il codice invito';
  static const noGroupTitle = 'Nessun gruppo';
  static const noGroupMessage =
      'Crea un nuovo gruppo o unisciti a uno esistente.';
  static const groupNameRequired = 'Inserisci il nome del gruppo';
  static const inviteCodeRequired = 'Inserisci il codice invito';
  static const inviteCodeInvalid = 'Codice non valido';
  static const inviteCodeExpired = 'Codice scaduto';
  static const leaveGroupConfirm =
      'Sei sicuro di voler abbandonare questo gruppo?';
  static const deleteGroupConfirm =
      'Sei sicuro di voler eliminare questo gruppo? Questa azione non può essere annullata.';
  static const admin = 'Admin';
  static const member = 'Membro';
  static const removeMember = 'Rimuovi membro';

  // Expenses
  static const expenses = 'Spese';
  static const addExpense = 'Aggiungi spesa';
  static const editExpense = 'Modifica spesa';
  static const deleteExpense = 'Elimina spesa';
  static const amount = 'Importo';
  static const date = 'Data';
  static const merchant = 'Negozio';
  static const category = 'Categoria';
  static const notes = 'Note';
  static const receipt = 'Scontrino';
  static const noExpenses = 'Nessuna spesa';
  static const noExpensesMessage = 'Aggiungi la tua prima spesa!';
  static const amountRequired = 'Inserisci l\'importo';
  static const amountInvalid = 'Importo non valido';
  static String amountMin(double min) =>
      'L\'importo minimo è \u20ac${min.toStringAsFixed(2)}';
  static String amountMax(double max) =>
      'L\'importo massimo è \u20ac${max.toStringAsFixed(2)}';
  static const dateRequired = 'Seleziona la data';
  static const dateFuture = 'La data non può essere nel futuro';
  static const deleteExpenseConfirm =
      'Sei sicuro di voler eliminare questa spesa?';

  // Categories
  static const categoryGroceries = 'Spesa';
  static const categoryRestaurant = 'Ristorante';
  static const categoryTransport = 'Trasporti';
  static const categoryUtilities = 'Utenze';
  static const categoryHealth = 'Salute';
  static const categoryEntertainment = 'Svago';
  static const categoryShopping = 'Shopping';
  static const categoryEducation = 'Istruzione';
  static const categoryOther = 'Altro';

  // Scanner
  static const scanReceipt = 'Scansiona scontrino';
  static const takePhoto = 'Scatta foto';
  static const chooseFromGallery = 'Scegli dalla galleria';
  static const scanning = 'Scansione in corso...';
  static const scanFailed = 'Scansione fallita';
  static const scanRetry = 'Riprova la scansione';
  static const reviewScan = 'Verifica dati';
  static const confirmAndSave = 'Conferma e salva';
  static const scanHint =
      'Inquadra lo scontrino in modo che sia ben visibile e leggibile.';

  // Dashboard
  static const dashboard = 'Dashboard';
  static const personalView = 'Personale';
  static const groupView = 'Gruppo';
  static const thisWeek = 'Settimana';
  static const thisMonth = 'Mese';
  static const thisYear = 'Anno';
  static const totalExpenses = 'Totale spese';
  static const expenseCount = 'Numero spese';
  static const averageExpense = 'Media';
  static const byCategory = 'Per categoria';
  static const byMember = 'Per membro';
  static const trend = 'Andamento';
  static const filterByMember = 'Filtra per membro';
  static const allMembers = 'Tutti i membri';
  static const noExpensesInPeriod = 'Nessuna spesa nel periodo';

  // Profile
  static const profile = 'Profilo';
  static const editProfile = 'Modifica profilo';
  static const accountInfo = 'Informazioni account';
  static const deleteAccount = 'Elimina account';
  static const deleteAccountConfirm =
      'Sei sicuro di voler eliminare il tuo account? Questa azione non può essere annullata.';
  static const deleteAccountDataChoice =
      'Le tue spese verranno conservate per il gruppo. Vuoi mantenere il tuo nome visibile sulle spese passate?';
  static const keepName = 'Mantieni nome';
  static const anonymize = 'Rendi anonimo';
  static const logoutConfirm = 'Sei sicuro di voler uscire?';

  // Errors
  static const errorGeneric = 'Si è verificato un errore. Riprova.';
  static const errorNetwork = 'Errore di connessione. Verifica la tua rete.';
  static const errorAuth = 'Errore di autenticazione. Accedi nuovamente.';
  static const errorNotFound = 'Risorsa non trovata.';
  static const errorPermission = 'Non hai i permessi per questa azione.';
  static const errorServer =
      'Errore del server. Riprova più tardi.';

  // Success messages
  static const successSaved = 'Salvato con successo';
  static const successDeleted = 'Eliminato con successo';
  static const successUpdated = 'Aggiornato con successo';
  static const successCopied = 'Copiato negli appunti';

  // Time formats
  static const today = 'Oggi';
  static const yesterday = 'Ieri';
  static String daysAgo(int days) => '$days giorni fa';
}
