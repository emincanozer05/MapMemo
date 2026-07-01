/// Optional override for the Google Sign-In *web* OAuth client id.
///
/// Leave this `null` if `android/app/google-services.json` already contains
/// a web OAuth client entry (the default when Google Sign-In is enabled via
/// the Firebase console) — Android will pick it up automatically and no
/// override is needed.
///
/// Set it explicitly only if you are not using `google-services.json`, or if
/// you hit a "serverClientId must be provided on Android" error. Get the
/// value from Firebase console → Authentication → Sign-in method → Google →
/// Web SDK configuration, or Google Cloud Console → Credentials → OAuth 2.0
/// Client IDs → the entry of type "Web application".
const String? googleSignInServerClientId = null;
