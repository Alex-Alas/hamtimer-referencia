/// Usuario con sesión iniciada.
///
/// Es la versión de la app de `firebase_auth.User`: solo los datos que las
/// pantallas necesitan, sin depender del paquete de Firebase.
class AppUser {
  const AppUser({required this.uid, required this.email, required this.displayName});

  final String uid;
  final String email;
  final String displayName;
}
