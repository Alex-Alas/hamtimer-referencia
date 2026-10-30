# Reglas de R8 para el build release.
# ML Kit trae clases opcionales que no se incluyen como dependencia: R8 no
# debe exigirlas (mismo arreglo que en VideoFeed).
-dontwarn com.google.mlkit.**
