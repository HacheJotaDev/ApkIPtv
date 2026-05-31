# HacheJota IPTV

Aplicación de IPTV gratuita, sin anuncios y sin restricciones VIP.

## Características

- Canales de TV en vivo
- Películas y series (VOD)
- Soporte para Xtream Codes API
- Soporte para listas M3U/M3U8
- Sistema de favoritos
- Reproductor de video integrado
- Sin anuncios
- Sin VIP - todo desbloqueado

## Cómo compilar

### Con GitHub Actions (recomendado)

1. Haz push a la rama `main`
2. Ve a la pestaña "Actions" en GitHub
3. Espera a que termine el workflow "Build APK"
4. Descarga el APK desde los artefactos

### Compilación local

```bash
# Instalar Flutter SDK
# https://docs.flutter.dev/get-started/install

# Obtener dependencias
flutter pub get

# Compilar APK
flutter build apk --release
```

El APK se generará en `build/app/outputs/flutter-apk/`

## Configuración

1. Abre la app
2. Ve a "Conectar Servicio IPTV"
3. Ingresa tus credenciales de Xtream Codes o la URL de una lista M3U
4. ¡Disfruta!
