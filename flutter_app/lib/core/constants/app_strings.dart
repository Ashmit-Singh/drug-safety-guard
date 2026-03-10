class AppStrings {
  AppStrings._();

  static const String appName = 'Drug Safety Guard';
  static const String appTagline = 'Prevent Dangerous Drug Interactions Before They Reach Patients';
  static const String appDescription =
      'A clinical decision support system that detects harmful drug '
      'combinations at the ingredient level and generates real-time '
      'safety alerts before prescriptions reach patients.';

  // Auth
  static const String loginTitle = 'Welcome Back';
  static const String loginSubtitle = 'Sign in to continue protecting patients';
  static const String emailHint = 'Email address';
  static const String passwordHint = 'Password';
  static const String signIn = 'Sign In';
  static const String signOut = 'Sign Out';
  static const String forgotPassword = 'Forgot Password?';

  // Navigation
  static const String dashboard = 'Dashboard';
  static const String prescriptions = 'Prescriptions';
  static const String patients = 'Patients';
  static const String drugs = 'Drugs';
  static const String alerts = 'Alerts';
  static const String analytics = 'Analytics';
  static const String settings = 'Settings';

  // Dashboard
  static const String totalPrescriptions = 'Total Prescriptions';
  static const String activePatients = 'Active Patients';
  static const String alertsToday = 'Alerts Today';
  static const String severeAlerts = 'Severe Alerts';
  static const String weeklyTrends = 'Weekly Interaction Trends';
  static const String dangerousPairs = 'Top 5 Dangerous Drug Pairs';
  static const String recentAlerts = 'Recent Alerts';

  // Prescription Builder
  static const String newPrescription = 'New Prescription';
  static const String selectPatient = 'Select Patient';
  static const String searchDrugs = 'Search & Add Drugs';
  static const String searchDrugsHint = 'Type drug name to search...';
  static const String selectedDrugs = 'Selected Drugs';
  static const String interactionWarnings = 'Interaction Warnings';
  static const String noInteractions = 'No interactions detected — safe to proceed';
  static const String savePrescription = 'Save Prescription';
  static const String cancelPrescription = 'Cancel';

  // Alerts
  static const String acknowledge = 'Acknowledge';
  static const String batchAcknowledge = 'Batch Acknowledge';
  static const String filterByDate = 'Filter by Date';
  static const String filterBySeverity = 'Filter by Severity';

  // Empty states
  static const String noData = 'No data available';
  static const String noPrescriptions = 'No prescriptions found';
  static const String noAlerts = 'No alerts — everything looks safe!';
  static const String noPatients = 'No patients registered';
  static const String noDrugs = 'No drugs found';

  // Errors
  static const String errorGeneric = 'Something went wrong';
  static const String errorNetwork = 'Network error. Please check your connection.';
  static const String errorRetry = 'Retry';
}
