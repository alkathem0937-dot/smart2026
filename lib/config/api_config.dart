/// API Configuration
class ApiConfig {
  // Base URL for Django backend
  // For Android Emulator: use 10.0.2.2 instead of localhost
  // For iOS Simulator: use localhost
  // For physical device: use your computer's IP address
  // Production URL (Render)
  static const String baseUrl = 'https://smartjudi.onrender.com';
  
  // Development URLs (uncomment to use):
  // static const String baseUrl = 'http://192.168.0.147:8000'; // Local Network
  // static const String baseUrl = 'http://10.0.2.2:8000'; // Android Emulator
  // static const String baseUrl = 'http://127.0.0.1:8000'; // iOS Simulator
  
  // API endpoints
  static const String loginEndpoint = '/api/token/';
  static const String refreshTokenEndpoint = '/api/token/refresh/';
  static const String profilesEndpoint = '/api/profiles/';
  static const String lawsuitsEndpoint = '/api/lawsuits/';
  static const String plaintiffsEndpoint = '/api/plaintiffs/';
  static const String defendantsEndpoint = '/api/defendants/';
  static const String attachmentsEndpoint = '/api/attachments/';
  static const String responsesEndpoint = '/api/responses/';
  static const String appealsEndpoint = '/api/appeals/';
  static const String hearingsEndpoint = '/api/hearings/';
  static const String judgmentsEndpoint = '/api/judgments/';
  static const String auditLogsEndpoint = '/api/audit-logs/';
  
  // Courts endpoints
  static const String governoratesEndpoint = '/api/governorates/';
  static const String districtsEndpoint = '/api/districts/';
  static const String courtTypesEndpoint = '/api/court-types/';
  static const String courtSpecializationsEndpoint = '/api/court-specializations/';
  static const String courtsEndpoint = '/api/courts/';
  
  // Laws endpoints
  static const String legalCategoriesEndpoint = '/api/legal-categories/';
  static const String lawsEndpoint = '/api/laws/';
  static const String lawChaptersEndpoint = '/api/law-chapters/';
  static const String lawSectionsEndpoint = '/api/law-sections/';
  static const String lawArticlesEndpoint = '/api/law-articles/';
  static const String caseLegalReferencesEndpoint = '/api/case-legal-references/';
  
  // Logs endpoints
  static const String userSessionsEndpoint = '/api/user-sessions/';
  static const String searchLogsEndpoint = '/api/search-logs/';
  static const String aiChatLogsEndpoint = '/api/ai-chat-logs/';
  
  // Payments endpoints
  static const String paymentOrdersEndpoint = '/api/payment-orders/';
  
  // Legal templates endpoints
  static const String legalTemplatesEndpoint = '/api/legal-templates/';
  static const String financialClaimsEndpoint = '/api/financial-claims/';
  
  // Timeout duration
  static const Duration timeout = Duration(seconds: 60);
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}

