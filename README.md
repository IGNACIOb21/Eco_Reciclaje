# Eco Reciclaje

App móvil que identifica de qué material es un objeto a partir de una foto y muestra un mapa de puntos de reciclaje. Proyecto de título.

La app parte del diseño de Rebin (`rebin-main`, último commit `28a427d`), con el escáner y el modelo de Joaquín, conectada a la base **Proyecto_Eco_reciclaje** de Supabase.

## Estructura

```
/app                    App móvil Flutter (Android/iOS)
/backend/eco_reciclaje  SQL aplicado en Proyecto_Eco_reciclaje y config de Auth — ver su README
/backend                (resto) SQL antiguo de Rebin, solo referencia
/docs                   Documentación de la base anterior (desactualizada)
/design                 Mockups de las pantallas
```

## App móvil (`/app`)

Barra inferior: **Inicio** (el mapa, con el saldo y la meta del día) · **Comunidad** · **Escanear** (botón central) · **Servicios** · **Perfil**. Abre directo en el mapa con una sesión anónima; el registro con correo se hace desde Perfil. El tema por defecto es claro, en plomo casi blanco.

```bash
cd app
cp .env.example .env     # SUPABASE_URL, SUPABASE_ANON_KEY (publishable key) y MAPBOX_ACCESS_TOKEN (pk.)
flutter pub get
flutter run
```

Sin `.env` la app funciona como demo con repositorios mock. Cambiar `.env` exige recompilar.

- Escáner: `lib/escaneo/` (modelo TFLite de Joaquín en `assets/modelo_escaneo/`, 9 clases) y `lib/screens/escanear_screen.dart`. "Registrar reciclaje" suma Rebin Points con `app_registrar_reciclaje`.
- APK para un teléfono moderno (arm64): `flutter build apk --release --split-per-abi --target-platform android-arm64`.

Tests: `flutter test`.

## Base de datos

Ver [`backend/eco_reciclaje/README.md`](backend/eco_reciclaje/README.md): orden de los SQL, buckets de Storage, Auth y lo que falta (SMTP para el código de registro).

**No correr `supabase db push` desde `backend/`**: esas migraciones son del esquema antiguo de Rebin.

## Notas

- Nunca commitear `.env`, la secret key de Supabase ni `google-services.json`.
- La app usa solo la publishable key; la secret key es para el panel de administración.
