# Documentación de Jardín Agrodiverso

Esta guía está dirigida a Nicolás y explica, paso a paso, cómo entender, abrir,
ejecutar y continuar el proyecto **Jardín Agrodiverso**.

El proyecto es un videojuego educativo desarrollado en Roblox. El jugador compra
semillas, las planta, espera a que crezcan, cosecha los cultivos y recibe Coins,
XP y, en algunos casos, nuevas semillas.

---

## 1. Introducción al proyecto

### ¿Qué es Jardín Agrodiverso?

Es un videojuego educativo en Roblox que representa un jardín con diferentes
cultivos. Su objetivo es enseñar y demostrar un ciclo sencillo de producción
agrícola:

```text
Comprar semillas
→ Plantar
→ Esperar el crecimiento
→ Cosechar
→ Recibir recompensas
→ Subir de nivel
```

### Funcionalidades que actualmente funcionan

El proyecto tiene un **vertical slice jugable**, es decir, un recorrido completo
del juego que se puede probar de principio a fin.

Actualmente funcionan:

- carga y guardado de datos del jugador;
- persistencia de Coins, XP e inventario mediante DataStore;
- autosave;
- session lock para evitar que dos servidores guarden al mismo jugador al mismo
  tiempo;
- salida y reentrada del mismo jugador;
- agricultura con Corn y Tomato;
- compra de semillas mediante el Banco de Semillas;
- consumo de semillas al plantar;
- crecimiento por etapas;
- cosecha;
- recompensas de Coins y XP;
- drops de semillas;
- progresión de niveles;
- HUD con información del jugador;
- migración y validación de datos persistentes;
- cierre coordinado mediante `PlayerRemoving`, `BindToClose` y `ClosingState`.

Estas funciones fueron probadas en Roblox Studio.

### Funcionalidades pendientes

Todavía no existen o necesitan revisión:

- revisión de `DEV_MODE` y de la configuración de desarrollo para la entrega;
- revisión y finalización de elementos del mapa;
- interfaz de tienda más completa;
- inventario visual avanzado;
- misiones;
- NPCs con lógica;
- venta de cultivos;
- economía adicional;
- detección dinámica de parcelas y prompts creados después del inicio;
- pruebas automatizadas.

---

## 2. Tecnologías utilizadas

### Roblox Studio

Es el programa donde se abre el mapa, se ejecuta el juego y se realizan las
pruebas. Allí se pueden revisar las parcelas, los prompts, los modelos
visuales y el `Workspace`.

### Luau

Es el lenguaje utilizado por Roblox. Los scripts del proyecto están escritos en
Luau y usan `--!strict` para detectar algunos errores de tipos mientras se
desarrolla.

### Visual Studio Code

Es el editor utilizado para leer y modificar los scripts y archivos del
proyecto. El código sincronizado por Rojo se trabaja principalmente desde VS
Code.

### Rojo

Rojo conecta los archivos del proyecto con Roblox Studio. Permite editar scripts
como archivos normales en VS Code y sincronizarlos con los servicios de Roblox,
por ejemplo `ServerScriptService` y `StarterPlayer`.

### Git y GitHub

Git guarda el historial de cambios del proyecto en el computador. GitHub guarda
una copia remota del repositorio y permite compartir el trabajo.

### DataStore de Roblox

DataStore es el sistema de Roblox para guardar datos persistentes entre
sesiones. En este proyecto se utiliza para guardar PlayerData, como Coins, XP e
inventario. Para usarlo en una experiencia de prueba, Roblox Studio debe tener
habilitado el acceso a servicios de API en la configuración correspondiente de
la experiencia.

---

## 3. Estructura del proyecto

La raíz del proyecto contiene los siguientes elementos importantes:

```text
Jardín Agrodiverso/
├── src/
├── JardinAgrodiverso/
├── JardinAgrodiverso_ADELANTO/
├── JardinAgrodiverso.rbxl
├── default.project.json
├── README.md
├── DOCUMENTACION.md
└── .gitignore
```

### `src/`

Contiene el código que Rojo sincroniza con Roblox Studio.

Sus partes principales son:

```text
src/
├── ReplicatedStorage/
├── ServerScriptService/
│   ├── Main.server.lua
│   └── Systems/
└── StarterPlayer/
    └── HUD.client.lua
```

### `JardinAgrodiverso/`

Contiene principalmente referencias visuales y documentación auxiliar del
proyecto, incluyendo materiales de referencia del jardín, imágenes, videos,
modelos y documentos para consulta.

No es la carpeta principal donde se ejecutan los scripts del juego.

### `JardinAgrodiverso_ADELANTO/`

Es una carpeta de adelantos o material de trabajo adicional. Está excluida
mediante `.gitignore` y no forma parte del contenido normal que debe subirse al
repositorio.

No se debe usar como sustituto de `src/` ni como ubicación principal para los
scripts del juego.

### `JardinAgrodiverso.rbxl`

Es el archivo del lugar de Roblox. Contiene el mapa que se abre en Roblox
Studio, incluyendo el `Workspace`, las estaciones, las parcelas, los prompts y
los modelos visuales.

El archivo `.rbxl` no se reemplaza automáticamente con los archivos de `src/`.
Debe abrirse en Roblox Studio y conservarse junto con la configuración que el
código espera.

### `default.project.json`

Es la configuración de Rojo. Indica qué carpetas locales deben aparecer en qué
servicios de Roblox:

```text
src/ReplicatedStorage
    → ReplicatedStorage

src/ServerScriptService
    → ServerScriptService

src/StarterPlayer
    → StarterPlayer.StarterPlayerScripts
```

Actualmente `Workspace` no está incluido en este archivo.

### `README.md`

Es la documentación técnica resumida del proyecto. Describe la arquitectura,
los sistemas existentes, la agricultura, la persistencia y el estado actual.

### `.gitignore`

Indica a Git qué archivos o carpetas no debe incluir en el control de versiones.
En particular, `JardinAgrodiverso_ADELANTO/` está excluida porque contiene
material de adelanto o trabajo auxiliar que no forma parte de la entrega
principal.

### Estructura relevante dentro de `src/`

#### `ServerScriptService`

Contiene la lógica principal que se ejecuta en el servidor:

- `Main.server.lua`: inicia los servicios principales.
- `Systems/PlayerData`: datos, validación, migración y DataStore.
- `Systems/Inventory`: inventario.
- `Systems/Seeds`: semillas y Banco de Semillas.
- `Systems/Economy`: Coins.
- `Systems/Progression`: XP y niveles.
- `Systems/Farming`: parcelas, cultivos y visuales.

#### `StarterPlayer`

Contiene `HUD.client.lua`, que crea el HUD local del jugador y lee Attributes
replicados por el servidor.

#### `ReplicatedStorage`

Está preparado para contenido compartido, aunque los sistemas actuales no
dependen de RemoteEvents ni RemoteFunctions.

---

## 4. Cómo funciona Rojo

### ¿Qué es Rojo?

Rojo es una herramienta que sincroniza una carpeta de archivos con Roblox
Studio. Permite trabajar con scripts en VS Code sin tener que copiar y pegar
manualmente cada archivo dentro de Roblox Studio.

### Relación entre VS Code, Rojo y Roblox Studio

El flujo es:

```text
VS Code
  ↓ archivos locales
Rojo Server
  ↓ sincronización
Plugin de Rojo en Roblox Studio
  ↓
Servicios del juego
```

VS Code contiene la versión editable de los scripts. Rojo Server publica esos
archivos en una conexión local. El plugin de Rojo se conecta a esa publicación y
la muestra en Roblox Studio.

### Iniciar el Rojo Server

Abre una terminal en la raíz del proyecto, es decir, en la carpeta que contiene
`default.project.json`, y ejecuta:

```text
rojo serve default.project.json
```

Si el comando `rojo` no existe, primero hay que instalar Rojo o configurar su
ejecutable según el método utilizado en el equipo.

La terminal debe permanecer abierta mientras se trabaja con la sincronización.

### Conectar Roblox Studio

1. Abre `JardinAgrodiverso.rbxl` en Roblox Studio.
2. Comprueba que el plugin de Rojo esté instalado.
3. Abre el plugin de Rojo.
4. Busca el servidor local publicado por `rojo serve`.
5. Pulsa **Connect** o el botón equivalente para conectarlo.

El puerto normal de Rojo es `34872`, pero se debe utilizar el servidor que el
plugin muestre disponible.

### Cómo saber si funciona

La conexión funciona cuando:

- el plugin indica que está conectado;
- `ServerScriptService` muestra `Main.server.lua` y la carpeta `Systems`;
- `StarterPlayerScripts` muestra `HUD.client.lua`;
- los cambios guardados en VS Code aparecen en Roblox Studio;
- no aparece un error de conexión en la terminal de Rojo.

Que una carpeta aparezca sincronizada significa que Rojo la está actualizando
desde los archivos locales. No significa que `Workspace` se cree o se
modifique automáticamente, porque `Workspace` no está incluido en
`default.project.json`.

---

## 5. Cómo abrir y ejecutar el proyecto

### Paso 1: abrir Roblox Studio

Abre Roblox Studio desde el computador.

### Paso 2: abrir el mapa

Abre el archivo:

```text
JardinAgrodiverso.rbxl
```

Es importante abrir el archivo correcto porque contiene el mapa manual y los
objetos de `Workspace` que necesitan los servicios.

### Paso 3: abrir el proyecto en VS Code

En VS Code, usa **File > Open Folder** y selecciona la carpeta raíz que contiene:

```text
src/
default.project.json
README.md
JardinAgrodiverso.rbxl
```

### Paso 4: iniciar Rojo

En una terminal ubicada en esa carpeta, ejecuta:

```text
rojo serve default.project.json
```

No cierres esa terminal mientras Roblox Studio esté conectado.

### Paso 5: conectar Roblox Studio

Usa el plugin de Rojo dentro de Roblox Studio y conecta el servidor local.

### Paso 6: ejecutar Play

En Roblox Studio, pulsa **Play**. El script principal debe imprimir mensajes
parecidos a:

```text
JARDÍN AGRODIVERSO
Sistema principal iniciado correctamente
```

Después, el jugador debería cargar sus datos y aparecer el HUD.

### Paso 7: comprobar el flujo principal

Comprueba lo siguiente:

1. El HUD muestra Coins, Level, XP y semillas.
2. El Banco de Semillas permite comprar.
3. Una parcela vacía permite plantar si hay semillas.
4. La parcela pasa por crecimiento.
5. La parcela llega a `Ready`.
6. La cosecha entrega Coins y XP.
7. El HUD se actualiza.
8. Al salir y volver a entrar, los datos se conservan.

### Si algo no funciona

Revisa:

- que Rojo Server siga ejecutándose;
- que el plugin esté conectado;
- que se abrió `JardinAgrodiverso.rbxl`;
- que `Workspace.Stations.Farm` exista;
- que `Workspace.Stations.SeedShop` exista;
- que los prompts tengan los Attributes correctos;
- que la ventana **Output** de Roblox Studio no muestre errores;
- que el acceso a DataStore esté habilitado para las pruebas;
- que los nombres de carpetas y objetos coincidan exactamente.

---

## 6. Cómo funciona actualmente el juego

El flujo principal es:

```text
Jugador
  ↓
PlayerDataService carga datos
  ↓
Inventory y Coins disponibles
  ↓
Compra de semillas
  ↓
Plantación
  ↓
Crecimiento visual
  ↓
Cosecha
  ↓
Coins, XP y posible drop de semilla
  ↓
Nuevo Level calculado desde XP
  ↓
HUD actualizado
  ↓
Save y Release al cerrar
```

Los cultivos actuales son:

| Cultivo | Semilla | Tiempo | Coins | XP | Drop |
| --- | --- | ---: | ---: | ---: | ---: |
| Corn | `Seeds` | 30 s | 10 | 5 | 15% |
| Tomato | `TomatoSeeds` | 45 s | 15 | 8 | 20% |

El sistema utiliza los estados:

```text
Empty → Growing → Ready → Empty
```

---

## 7. Persistencia de datos

### PlayerData

PlayerData es la información del jugador durante la sesión. Incluye:

```lua
{
    Coins = number,
    Level = number,
    XP = number,
    Seeds = number,
    Inventory = {
        [itemId] = number,
    },
}
```

`Level` se calcula a partir de XP. La representación persistente principal
guarda Coins, XP, Inventory y la versión de los datos. `Seeds` se mantiene para
compatibilidad con el código agrícola existente.

### DataStore

El proyecto utiliza:

```text
JardinAgrodiverso_PlayerData_v1
```

para PlayerData, y:

```text
JardinAgrodiverso_SessionLocks_v1
```

para los session locks.

### Autosave

El autosave guarda periódicamente los datos de los jugadores cargados. Esto
reduce el riesgo de perder cambios si el servidor se cierra de forma inesperada.

### Session lock

El session lock marca temporalmente que un servidor está usando los datos de un
jugador. Tiene un token de ownership, heartbeat y una duración de 120 segundos.
Su objetivo es evitar que dos servidores escriban simultáneamente los mismos
datos.

### Cuando el jugador entra

1. `PlayerDataService` recibe al jugador.
2. `DataStoreRepository` intenta adquirir el session lock.
3. Carga el PlayerData.
4. Migra y valida los datos.
5. Construye los datos runtime.
6. Publica Attributes para el HUD.
7. Permite jugar cuando el estado es `Loaded`.

Si los datos no se pueden cargar, el jugador no debe entrar al gameplay normal.

### Cuando el jugador sale

1. Se intenta guardar el PlayerData.
2. Se intenta liberar el session lock.
3. El estado local se limpia solamente después de confirmar el cierre correcto.

### `PlayerRemoving`

Roblox ejecuta este evento cuando un jugador sale. En este proyecto llama al
cierre de la sesión del jugador para guardar y liberar el lock.

### `BindToClose`

Roblox ejecuta este callback cuando el servidor está cerrándose. El proyecto
espera los cierres activos para intentar terminar los guardados y liberar los
locks antes de finalizar.

### `ClosingState`

`ClosingState` es un estado compartido por `UserId`. Sirve para que
`PlayerRemoving` y `BindToClose` no ejecuten dos veces el mismo `Save` y
`Release`.

Si un cierre ya está en progreso, el segundo flujo espera el mismo evento. Si el
cierre termina correctamente, el estado se limpia:

```text
Release exitoso
→ cierre completado
→ ClosingState eliminado
→ el mismo UserId puede iniciar otra sesión correctamente
```

Esta corrección permite el ciclo:

```text
Entrar
→ salir
→ volver a entrar al mismo servidor
→ volver a salir
```

sin reutilizar por error el estado de cierre de la sesión anterior.

---

## 8. Sistemas principales

Todos los archivos descritos a continuación están dentro de
`src/ServerScriptService/Systems`, salvo el HUD.

### `PlayerDataService`

Archivo:

```text
Systems/PlayerData/PlayerDataService.lua
```

Es la autoridad de los datos del jugador. Coordina:

- carga;
- migración;
- validación;
- PlayerData runtime;
- Attributes;
- autosave;
- `PlayerRemoving`;
- `BindToClose`;
- `ClosingState`.

### `DataStoreRepository`

Archivo:

```text
Systems/PlayerData/DataStoreRepository.lua
```

Es la única capa que accede directamente a DataStore. Maneja:

- `Load`;
- `Save`;
- `Release`;
- reintentos;
- session lock;
- heartbeat;
- sesiones activas.

### `DataContract`

Archivo:

```text
Systems/PlayerData/DataContract.lua
```

Define la forma esperada de los datos persistentes, la versión actual y los
límites principales.

### `DataMigration`

Archivo:

```text
Systems/PlayerData/DataMigration.lua
```

Convierte datos antiguos al contrato actual. También permite migrar el campo
legacy `Seeds` hacia `Inventory["Seeds"]`.

### `DataValidator`

Archivo:

```text
Systems/PlayerData/DataValidator.lua
```

Comprueba y normaliza los datos para evitar cantidades inválidas, tipos
incorrectos o estructuras que el juego no pueda utilizar.

### `InventoryService`

Archivo:

```text
Systems/Inventory/InventoryService.lua
```

Administra objetos por jugador. Sus operaciones principales son:

- `GetItemCount`;
- `AddItem`;
- `RemoveItem`;
- `HasItem`.

No existe un inventario global. El inventario pertenece conceptualmente a
PlayerData.

### `CurrencyService`

Archivo:

```text
Systems/Economy/CurrencyService.lua
```

Centraliza la lectura, suma, resta y comprobación de Coins.

### `ProgressionService`

Archivo:

```text
Systems/Progression/ProgressionService.lua
```

Añade XP, obtiene XP y calcula el nivel actual mediante
`ProgressionCatalog`.

### `ProgressionCatalog`

Archivo:

```text
Systems/Progression/ProgressionCatalog.lua
```

Contiene los requisitos de XP de los niveles actuales:

- nivel 2: 10 XP;
- nivel 3: 25 XP;
- nivel 4: 50 XP.

### `SeedService`

Archivo:

```text
Systems/Seeds/SeedService.lua
```

Mantiene operaciones relacionadas con semillas, incluyendo lectura, adición y
consumo por `itemId`.

### `SeedShopService`

Archivo:

```text
Systems/Seeds/SeedShopService.lua
```

Contiene el catálogo y la lógica de compra:

- `CornSeed` agrega `Seeds` y cuesta 5 Coins;
- `TomatoSeed` agrega `TomatoSeeds` y cuesta 8 Coins.

### `SeedShopInteractionService`

Archivo:

```text
Systems/Seeds/SeedShopInteractionService.lua
```

Conecta los prompts del Banco de Semillas con `SeedShopService`.

### `FarmingService`

Archivo:

```text
Systems/Farming/FarmingService.lua
```

Implementa plantación, crecimiento, cosecha, consumo de semillas, Coins, XP y
seed drops.

### `CropCatalog`

Archivo:

```text
Systems/Farming/CropCatalog.lua
```

Es la configuración de los cultivos. Actualmente contiene Corn y Tomato, con
sus semillas, duración, recompensas, drops y nombres de modelos.

### `PlotInteractionService`

Archivo:

```text
Systems/Farming/PlotInteractionService.lua
```

Busca las parcelas y conecta sus `ProximityPrompt` con las acciones de plantar y
cosechar.

### `CropVisualService`

Archivo:

```text
Systems/Farming/CropVisualService.lua
```

Actualiza la apariencia de los cultivos según el estado y la etapa de
crecimiento. Usa modelos que ya deben existir en el mapa.

### `HUD.client.lua`

Archivo:

```text
src/StarterPlayer/HUD.client.lua
```

Crea el HUD del jugador y muestra Coins, Level, XP, Seeds y TomatoSeeds. Solo
lee Attributes replicados por el servidor; no modifica PlayerData.

---

## 9. Mapa y Roblox Studio

El mapa depende actualmente de:

```text
JardinAgrodiverso.rbxl
```

`Workspace` no está completamente sincronizado mediante Rojo. Por eso es
importante abrir el `.rbxl` correcto y no asumir que Rojo creará el mapa.

### Elementos que espera encontrar el código

```text
Workspace
└── Stations
    ├── Farm
    └── SeedShop
```

### `Stations.Farm`

Debe contener las parcelas agrícolas. Las parcelas necesitan:

- `ProximityPrompt`;
- Attribute `CropType` con valor `Corn` o `Tomato`;
- los modelos visuales que correspondan, como `CornCrop` o `TomatoCrop`.

### `Stations.SeedShop`

Debe contener los prompts del Banco de Semillas. Cada prompt necesita Attributes
como:

```text
SeedId = CornSeed
PurchaseAmount = 1
```

o:

```text
SeedId = TomatoSeed
PurchaseAmount = 1
```

Los nombres y Attributes distinguen mayúsculas y minúsculas. Si se cambian en
Studio, también debe revisarse el código que los busca.

---

## 10. Git y control de versiones

### ¿Qué es Git?

Git guarda versiones del proyecto. Permite saber qué cambió, volver a una
versión anterior y trabajar con más seguridad.

### ¿Qué es GitHub?

GitHub es el sitio donde se guarda una copia remota del repositorio. Sirve como
respaldo y como lugar para compartir cambios.

### ¿Qué es un commit?

Un commit es una fotografía guardada del estado del proyecto en Git. Antes de un
cambio importante conviene crear un commit para poder comparar o regresar a la
versión anterior.

### ¿Qué es push?

`push` envía los commits locales a GitHub.

### Archivos importantes bajo control de versiones

Normalmente deben mantenerse versionados:

- `src/`;
- `default.project.json`;
- `README.md`;
- `DOCUMENTACION.md`;
- `JardinAgrodiverso.rbxl`, si forma parte de la entrega y el equipo decide
  versionarlo;
- `.gitignore`.

La carpeta `JardinAgrodiverso/` contiene referencias y documentación auxiliar;
debe conservarse según las necesidades del equipo y el tamaño de los archivos.

`JardinAgrodiverso_ADELANTO/` está excluida por `.gitignore`, por lo que Git no
la incluye normalmente.

### Comandos básicos

Desde una terminal ubicada en la raíz del proyecto:

```text
git status
```

Muestra qué archivos cambiaron.

```text
git add src README.md DOCUMENTACION.md
```

Prepara la carpeta `src/` y los dos archivos de documentación para un commit.
Antes de confirmar, revisa con `git status` exactamente qué quedó preparado.

```text
git commit -m "docs: actualiza documentación del proyecto"
```

Guarda los cambios preparados como un commit.

```text
git log --oneline -5
```

Muestra los últimos commits.

```text
git push origin main
```

Envía los commits a la rama `main` de GitHub. Antes de usarlo, hay que revisar
el estado, el contenido del commit y confirmar que se está trabajando en la
rama correcta.

---

## 11. Cómo continuar desarrollando

### Cambiar cultivos

Revisa:

```text
src/ServerScriptService/Systems/Farming/CropCatalog.lua
```

Ahí se configuran nombre del cultivo, semilla, duración, recompensas, drop y
modelo visual. Para agregar un cultivo también hay que preparar correctamente
sus modelos y parcelas en Roblox Studio.

### Cambiar recompensas

Las recompensas de Coins y XP de cada cultivo están en:

```text
CropCatalog.lua
```

La suma de Coins pasa por `CurrencyService` y la XP por
`ProgressionService`.

### Cambiar semillas

Revisa:

```text
src/ServerScriptService/Systems/Seeds/SeedShopService.lua
src/ServerScriptService/Systems/Seeds/SeedService.lua
```

También revisa `CropCatalog.lua`, porque cada cultivo indica qué `SeedItemId`
consume.

### Modificar la progresión

Revisa:

```text
src/ServerScriptService/Systems/Progression/ProgressionCatalog.lua
src/ServerScriptService/Systems/Progression/ProgressionService.lua
```

El nivel se calcula desde XP acumulada. No se debe convertir `Level` en una
segunda fuente independiente sin revisar el contrato de datos.

### Modificar el HUD

Revisa:

```text
src/StarterPlayer/HUD.client.lua
```

El HUD debe continuar leyendo Attributes. Las modificaciones de datos deben
realizarse en el servidor, no desde el cliente.

### Modificar los datos del jugador

Revisa primero:

```text
src/ServerScriptService/Systems/PlayerData/DataContract.lua
src/ServerScriptService/Systems/PlayerData/DataMigration.lua
src/ServerScriptService/Systems/PlayerData/DataValidator.lua
src/ServerScriptService/Systems/PlayerData/PlayerDataService.lua
src/ServerScriptService/Systems/PlayerData/DataStoreRepository.lua
```

Cambiar PlayerData es una tarea delicada porque puede afectar datos ya
guardados. Si se agrega un campo persistente, hay que pensar en defaults,
migración, validación, guardado y compatibilidad con datos anteriores.

---

## 12. Estado actual y próximos pasos

### Implementado y validado

- vertical slice jugable;
- compra de semillas;
- inventario base;
- plantación;
- crecimiento;
- cosecha;
- consumo de semillas;
- recompensas de Coins y XP;
- drops de semillas;
- progresión de niveles;
- HUD;
- persistencia;
- autosave;
- session lock;
- salida y reentrada;
- corrección de `ClosingState`;
- migración y validación de datos.

### Implementado, pero pendiente de revisión o ampliación

- `DEV_MODE` continúa siendo una configuración de desarrollo y debe revisarse
  antes de una entrega final;
- el mapa depende de objetos manuales en Roblox Studio;
- parcelas, prompts y modelos deben permanecer con los nombres y Attributes
  esperados;
- el Banco de Semillas no tiene todavía una UI completa;
- el HUD no tiene notificaciones ni barras;
- la progresión actual llega hasta los requisitos configurados para el nivel 4;
- los servicios detectan objetos del mapa durante la inicialización y no
  conectan automáticamente objetos agregados después.

### Todavía no implementado

- misiones;
- NPCs con diálogos o comportamiento;
- venta de cultivos;
- economía de mercado;
- inventario visual avanzado;
- herramientas y recursos adicionales;
- RemoteEvents o RemoteFunctions para una UI interactiva;
- pruebas automatizadas.

---

## 13. Reglas importantes para no romper el proyecto

1. Haz un backup o crea un commit antes de cambios importantes.
2. No modifiques DataStore, session lock, `Save` o `Release` sin entender todo
   el ciclo de carga y cierre.
3. No elimines carpetas dentro de `src/` que estén sincronizadas por Rojo.
4. No cambies `default.project.json` sin comprobar el efecto en Roblox Studio.
5. No modifiques el `.rbxl` sin revisar qué objetos necesita el código.
6. Mantén `Stations`, `Farm`, `SeedShop`, los prompts y sus Attributes con los
   nombres esperados.
7. Prueba los cambios en Roblox Studio antes de considerarlos terminados.
8. Revisa la ventana **Output** para detectar errores y advertencias.
9. No permitas que el cliente modifique directamente Coins, XP o inventario.
10. Si cambias el contrato de PlayerData, actualiza defaults, migración,
    validación y documentación.
11. Mantén el código y la documentación sincronizados.
12. Revisa `git status` antes de hacer commit o push.
13. No subas carpetas excluidas o archivos grandes sin confirmar que realmente
    deben formar parte de la entrega.

---

## Ruta rápida para empezar

1. Descarga o clona el repositorio.
2. Abre la carpeta raíz en VS Code.
3. Comprueba que existan `src/`, `default.project.json` y
   `JardinAgrodiverso.rbxl`.
4. Abre `JardinAgrodiverso.rbxl` en Roblox Studio.
5. Abre una terminal en la raíz del proyecto.
6. Ejecuta:

   ```text
   rojo serve default.project.json
   ```

7. Abre el plugin de Rojo en Roblox Studio y conéctalo al servidor local.
8. Confirma que `Main.server.lua` aparezca en `ServerScriptService` y que
   `HUD.client.lua` aparezca en `StarterPlayerScripts`.
9. Pulsa **Play**.
10. Revisa el HUD, compra semillas, planta y cosecha.
11. Observa la ventana **Output** si aparece algún problema.
12. Al terminar, detén Play y vuelve a entrar para comprobar que los datos
    persisten correctamente.
