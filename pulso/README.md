# PULSO · Training Club

App responsive en español. Agenda por semana, filtros, reservas y cancelaciones, perfil con foto, turnos y administración de clases y socios.

## Conectar Supabase

1. Crear un proyecto en https://supabase.com/dashboard.
2. Ejecutar `supabase/schema.sql` en el SQL Editor (una sola vez en un proyecto nuevo).
3. Completar `dist/config.js` con la URL del proyecto y la clave pública publishable o anon. Nunca usar service_role.
4. Configurar Authentication → URL Configuration con la URL publicada y los redirects permitidos. Mantener la confirmación de email habilitada y configurar SMTP para los correos reales.
5. Publicar los archivos actualizados. Crear tu cuenta y confirmar el correo. Luego ejecutar en SQL Editor: `update public.profiles set role='admin' where email='TU_EMAIL';`.
6. Ingresar de nuevo y cargar clases desde Administración.

Sin configuración, funciona una demo local claramente identificada. No crea cuentas ni almacena datos en Supabase. Los datos demo permanecen en el navegador; no se copian a producción. La foto demo se almacena en localStorage. No usar datos sensibles en la demo.

## Seguridad

Supabase Auth gestiona contraseñas y sesiones. RLS limita perfiles y reservas a su titular; el rol de administración solo se cambia desde la base. Los cupos se consultan como agregados, sin exponer socios. La reserva usa una transacción PostgreSQL con bloqueo de fila, unicidad por socio/clase y validación de hora y capacidad. Las fotos son públicas, con límite de 2 MB y carpeta del usuario.

## Desarrollo

No requiere compilación. Servir `dist` con un servidor estático, por ejemplo `python -m http.server 4173 --directory dist`. La app usa Supabase JS v2 mediante CDN al configurar Supabase, Google Fonts y fotografías de Unsplash.

## Validación pendiente de conexión

Probar con dos cuentas de socio y una de dueño: confirmación de email, ingreso, persistencia de perfil/foto, intento de acceso administrativo desde socio, dos reservas simultáneas por el último lugar, cancelación, listado de inscriptos y eliminación de clase. La integración real requiere ejecutar el esquema y las claves de un proyecto.
