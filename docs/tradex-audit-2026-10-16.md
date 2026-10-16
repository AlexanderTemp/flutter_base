# Auditoría integral de Tradex — 2026-10-16

## Qué hace este repositorio

Tradex es un cliente Flutter de calendario económico, noticias RSS, criptomonedas y USD/BOB, con preferencias locales y notificaciones Android. Carga esperada: una persona por instalación, con interfaz y servicio Android consultando fuentes públicas desde isolates distintos; varios amigos implican consultas independientes, no un servidor compartido.

Referencia: rama `feature/ff-watch`, HEAD `8c75d41`, más cambios locales pendientes de commit. Esta auditoría describe ese árbol de trabajo, no únicamente el último commit. Hallazgos por inspección; no equivalen a fallos reproducidos ejecutando la app.

## Corregir antes de considerarla estable

### 1. Las cotizaciones antiguas parecen actuales

- **Qué es:** La caché mantiene precios visibles cuando falla CoinGecko. Referencias: `lib/forex/crypto/crypto_client.dart:59-88,115-122`, `crypto_controller.dart:26-37,62-69` y `lib/forex/live/live_notification.dart:98-115`.
- **Problema:** Tras una descarga correcta y un fallo posterior, se devuelve el precio anterior sin fecha ni aviso. La notificación añade la hora de la consulta actual; USD/BOB tampoco transmite su vigencia a la notificación (`MarketSnapshot.toMap`, líneas 53-70). Una cifra guardada puede interpretarse como recién obtenida.
- **Arreglo mínimo:** Propagar la fecha de la última descarga correcta y el estado de recuperación de cada fuente. Mostrar «Guardado» con su fecha al reutilizarla, sin reemplazarla por la hora del intento; migrar la caché cripto conservando las selecciones.
- **Si se omite:** Los usuarios comparan o toman decisiones usando valores antiguos como si fueran actuales.

### 2. El panel Android no puede garantizar funcionamiento continuo

- **Qué es:** El panel usa un servicio `dataSync` y reinicio automático al arrancar el teléfono. Referencias: `android/app/src/main/AndroidManifest.xml:39-46` y `lib/forex/live/live_notification.dart:237-261`.
- **Problema:** En Android 15+ con target 35+, `dataSync` tiene un presupuesto de seis horas en 24 horas en segundo plano y restricciones de inicio desde el arranque. Al agotarlo se pierden las consultas y los recordatorios que dependen del servicio. El plugin 11.0.3 sí implementa `onTimeout` y detiene el servicio: no se ha demostrado un crash por falta de ese manejador.
- **Arreglo mínimo:** Desactivar el arranque automático incompatible y representar en la UI que el panel se detuvo, con reactivación explícita y explicación de su límite. Para prometer recordatorios con la app cerrada todo el día, programarlos mediante una API de planificación apropiada y verificar sus permisos/límites; cambiar solo el nombre del tipo de servicio no resuelve el problema.
- **Si se omite:** Un usuario deja el panel encendido y deja de recibir avisos sin que la configuración explique lo ocurrido.

Referencia de plataforma: https://developer.android.com/develop/background-work/services/fgs/timeout . No se ejecutaron pruebas de duración ni de reinicio del dispositivo.

### 3. El análisis confunde expectativa con sorpresa publicada

- **Qué es:** `lib/forex/analysis/impact_analysis.dart:93-121,126-143` compara forecast con previo y genera una explicación de reacción cripto.
- **Problema:** Si forecast y previo son iguales, muestra «Sin sorpresa, poca reacción esperada en cripto» aunque el feed no contiene el dato publicado. Por ejemplo, previo 3 %, forecast 3 % y un resultado real de 4 % siguen produciendo esa frase. Además, el clasificador genérico de `rate` trata una tasa no reconocida como una decisión de tipos (`:73-76`).
- **Arreglo mínimo:** Describir solo el cambio esperado frente al previo y expresar que la sorpresa requiere actual frente a forecast. Limitar la clasificación de tipos a nombres específicos. Añadir pruebas del analizador que realmente usa Análisis, `ImpactAnalyzer`; las existentes de `FfAnalyzer` no cubren este flujo.
- **Si se omite:** Se presenta como conclusión de mercado algo que la fuente no permite determinar.

### 4. Un fallo en el historial BOB descarta también la cotización actual

- **Qué es:** `lib/forex/bob/bob_client.dart:92-149` interpreta la cotización vigente y la tabla histórica como una sola respuesta válida o inválida.
- **Problema:** Una cotización actual válida con tabla ausente, vacía o una fila histórica incorrecta hace fallar toda la lectura. La app conserva el valor anterior o muestra que no existe cotización, aunque el BCB sí publicó una nueva.
- **Arreglo mínimo:** Validar el valor vigente por separado del historial y reflejar el fallo histórico sin inventar registros. Si se conserva el historial anterior, conservar también su fecha y estado independiente. Añadir una prueba con valor vigente válido y tabla rota.
- **Si se omite:** Un cambio menor en la tabla impide actualizar también la cinta y la notificación USD/BOB.

### 5. La distribución release usa la clave debug

- **Qué es:** `android/app/build.gradle.kts:19-21,34-39` mantiene el identificador de ejemplo y firma release con debug.
- **Problema:** Una APK compartida desde un equipo y una actualización firmada desde otro pueden tener claves distintas. Android rechazará actualizarla sobre la instalación existente; desinstalar para instalar de nuevo borra preferencias y cachés.
- **Arreglo mínimo:** Definir un identificador propio y una clave release estable antes de la primera distribución duradera. Guardar clave y credenciales fuera de Git y conservar una copia segura. Cambiar el identificador después crea otra aplicación.
- **Si se omite:** La distribución entre amigos funciona inicialmente, pero no hay una identidad de actualización estable.

## Conviene corregir

### 6. Guardar ajustes puede dejar una combinación parcial

- **Qué es:** `lib/forex/data/prefs.dart:22-36` escribe cuatro claves separadas con `Future.wait`.
- **Problema:** Si una escritura falla después de que otras se guarden, el método informa de fallo, pero ya cambió parte de la configuración. El caso concreto es un fallo de almacenamiento: pueden quedar alertas activadas con un adelanto diferente al elegido. La relectura en Ajustes muestra lo que quedó, pero no hace atómica la operación.
- **Arreglo mínimo:** Guardar las opciones relacionadas en una única entrada JSON, con lectura compatible de las claves anteriores y comprobación del resultado de escritura. Una sola clave reduce la mezcla parcial; no convierte SharedPreferences en una base transaccional.
- **Si se omite:** Un intento fallido puede alterar el comportamiento de los recordatorios.

### 7. El rango de fechas BOB queda fuera de los nuevos límites

- **Qué es:** `lib/forex/bob/bob_view.dart:21-32` conserva `_range` y lo pasa al selector junto a los límites del historial recién descargado.
- **Problema:** Si el usuario eligió una fecha que después desaparece de una serie histórica móvil, el rango inicial puede empezar antes de `firstDate`. Reabrir «Cambiar fechas» incumple las precondiciones del selector; en debug produce una aserción.
- **Arreglo mínimo:** Antes de abrir, recortar el rango a los límites actuales o pasarlo como nulo si ya no hay intersección. Añadir una prueba que cambie el historial después de elegir un rango.
- **Si se omite:** El selector puede fallar después de actualizar una fuente que recorta sus registros antiguos.

### 8. Los reintentos ignoran el límite temporal de la fuente

- **Qué es:** `lib/forex/ff_feed_client.dart:25-49`, `lib/forex/forex_controller.dart:21-22,216-220` y `lib/forex/crypto/crypto_client.dart:76-88` controlan consultas y respuestas HTTP.
- **Problema:** Tras un 429 no se guarda una próxima fecha permitida ni se respeta `Retry-After`. Si el proveedor pide diez minutos, la interfaz sigue intentando cada minuto, el servicio cada dos y el refresco manual puede añadir intentos. La caché estática no se comparte entre isolates.
- **Arreglo mínimo:** Guardar y respetar el próximo instante de reintento por fuente; interpretar `Retry-After` y usar una espera progresiva acotada cuando no exista. Probar que durante ese plazo no se envía otra petición.
- **Si se omite:** La recuperación puede demorarse por seguir consultando durante el bloqueo.

### 9. La configuración Gradle permite un uso de RAM alto para este equipo

- **Qué es:** `android/gradle.properties:1` permite 8 GiB de heap, 4 GiB de metaspace y 512 MiB de caché de código.
- **Problema:** Son máximos, no RAM reservada al iniciar, pero permiten que una compilación compita con Android Studio y los otros procesos hasta presionar la memoria. Esto contradice el objetivo de trabajar en un equipo con RAM compartida; no se midió el consumo de una compilación actual.
- **Arreglo mínimo:** Ajustar los máximos y el número de workers a la RAM disponible, y validar una compilación solo cuando el usuario lo autorice. No trasladar estos valores automáticamente como configuración universal de `main`.
- **Si se omite:** Una compilación iniciada por el usuario puede volver a afectar al resto del trabajo.

### 10. Seleccionar muchas monedas desplaza los eventos fuera del texto visible

- **Qué es:** `android/app/src/main/kotlin/com/example/flutter_workspace/TradexNotifications.kt:78-99` añade todas las cotizaciones antes de los eventos al texto expandido.
- **Problema:** Con 56 monedas, el contenido depende de cuánto texto muestre cada Android; el bloque de eventos al final puede quedar truncado. El evento del resumen contraído no garantiza que se vea el bloque completo al expandir.
- **Arreglo mínimo:** Mostrar una cantidad pequeña de cotizaciones, priorizar moneda destacada y eventos, y resumir el resto como «+N monedas · abrir app».
- **Si se omite:** Activar más monedas vuelve menos útil la sección de eventos del panel.

## Qué está bien y debe conservarse

- Temas y componentes AppFlowy locales, con correcciones semánticas de contraste sincronizadas entre Dart y los JSON de origen.
- Un único splash nativo; cargas independientes en las secciones y navegación conservada mediante `IndexedStack`.
- Filtros de una fila desplazable y avisos de recuperación compactos y desplegables.
- Calendario guardado con fecha original, recuperación explícita y reemplazo al volver la conexión.
- Fechas programadas diferenciadas de publicación RSS; no se inventa el dato actual de FairEconomy.
- Lectura RSS con zonas horarias numéricas y apertura de enlaces limitada a HTTP/HTTPS.
- Control de peticiones superpuestas y de resultados posteriores a `dispose`.
- Cotizaciones ausentes no convertidas a cero; BOB calculado en centavos enteros.
- Notificación Android nativa, con acción de actualizar y sin los RemoteViews que ocasionaron el crash anterior.
- Preferencias de contenido y moneda destacada; recordatorios opt-in con identidad persistida y reintento de entrega.
- Guía offline con búsqueda sin tildes/mayúsculas; `Text` en lugar del `SelectableText` que produjo la aserción reportada.
- Cinta con pausa táctil/manual y reducción de movimiento; ticker desactivado en la pestaña oculta.
- Fuente editable de iconos y script reproducible, licencias y atribuciones conservadas.

## Alcance de comprobación y veredicto

Se inspeccionaron arranque, navegación, puente visual, fuentes, controladores, preferencias, análisis, historial BOB, entrega de avisos, integración Android y pruebas relacionadas. Se comparó el árbol versionado con `main`: hay eliminaciones de la aplicación base y de sus pruebas. `git diff main` no incluye los archivos nuevos aún no añadidos; `git status` sí los muestra.

No se compiló, ejecutó ni instaló la app. No se ejecutaron pruebas ni análisis Flutter. Las pruebas escritas de recuperación, búsquedas, fechas, concurrencia y UI siguen pendientes de ejecución; los resultados de compilaciones y pruebas históricas del README no verifican esta entrega. No se auditó cada componente del paquete vendorizado AppFlowy ni se validaron visualmente todas las plataformas, accesibilidad con lector de pantalla, arranque del dispositivo o entrega real en segundo plano. No se hizo una auditoría externa de vulnerabilidades de dependencias ni una validación exhaustiva de fuentes en vivo.

**Veredicto:** hay una buena base reutilizable. Priorizar antigüedad de cotizaciones, límites Android, exactitud del texto de análisis y desacoplar cotización/historial BOB; preparar firma antes de una distribución estable. Un commit de respaldo puede conservar este estado con sus pendientes explícitos, sin presentarlo como release validada.
