# Jardín Agrodiverso

## 1. Descripción general

**Jardín Agrodiverso** es un videojuego educativo en Roblox que representa un jardín agrodiverso mediante mecánicas de cultivo, inventario, semillas, recompensas y progresión basada en XP.

El código de servidor está escrito en Luau con `--!strict` y se sincroniza mediante Rojo. El mapa, las parcelas, los modelos visuales y los objetos físicos se administran manualmente en Roblox Studio.

La autoridad de los datos del jugador permanece en `PlayerDataService`. Las reglas de agricultura permanecen en `FarmingService`, la configuración de cultivos en `CropCatalog` y la presentación visual en `CropVisualService`.

## 2. Arquitectura actual

```text
PlayerDataService
        ↓
    PlayerData
        ↓
InventoryService ← SeedService
        ↓
FarmingService → ProgressionService
        ↓
SeedShopService
        ↓
Player Attributes
        ↓
HUD.client.lua
```

La lógica principal de juego se ejecuta en `ServerScriptService`. El HUD se ejecuta en el cliente, pero solo lee Attributes replicados por el servidor. El cliente no modifica Coins, XP, Level ni inventario.

`default.project.json` sincroniza:

- `src/ReplicatedStorage` → `ReplicatedStorage`.
- `src/ServerScriptService` → `ServerScriptService`.
- `src/StarterPlayer` → `StarterPlayer.StarterPlayerScripts`.

`Workspace` no se sincroniza mediante Rojo.

## 3. Estructura real de carpetas y archivos

```text
Jardín Agrodiverso/
├── default.project.json
├── JardinAgrodiverso.rbxl
├── README.md
└── src/
    ├── ReplicatedStorage/
    ├── StarterPlayer/
    │   └── HUD.client.lua
    └── ServerScriptService/
        ├── Main.server.lua
        └── Systems/
            ├── PlayerData/
            │   └── PlayerDataService.lua
            ├── Inventory/
            │   └── InventoryService.lua
            ├── Seeds/
            │   ├── SeedService.lua
            │   ├── SeedShopService.lua
            │   └── SeedShopInteractionService.lua
            ├── Progression/
            │   ├── ProgressionService.lua
            │   └── ProgressionCatalog.lua
            └── Farming/
                ├── CropCatalog.lua
                ├── FarmingService.lua
                ├── PlotInteractionService.lua
                └── CropVisualService.lua
```

## 4. PlayerData actual

`PlayerDataService` crea y administra datos por jugador durante la sesión, y los integra con persistencia mediante `DataStoreRepository`:

```lua
{
    Coins = 100,
    Level = 1,
    XP = 0,
    Seeds = 0,
    Inventory = {},
}
```

Los datos se cargan y guardan mediante DataStore. La persistencia actual incluye migración, validación, reintentos, versionado, autosave y session lock.

### Persistencia y ciclo de sesión

`DataStoreRepository` utiliza los siguientes DataStores:

- `JardinAgrodiverso_PlayerData_v1` para PlayerData.
- `JardinAgrodiverso_SessionLocks_v1` para session locks.

El sistema mantiene un session lock por `UserId`, con ownership mediante token, heartbeat y una duración de 120 segundos. `PlayerDataService` guarda los datos durante `PlayerRemoving` y coordina los cierres de `PlayerRemoving` y `BindToClose`.

Las pruebas en Roblox Studio validaron:

- carga y guardado de PlayerData;
- persistencia de Coins, XP e inventario;
- adquisición y liberación del session lock;
- autosave;
- salida y reentrada inmediata del mismo jugador;
- ciclo de salida y reentrada del mismo jugador dentro del mismo servidor.

`ClosingState` coordina los cierres concurrentes por `UserId`. Después de un `Release()` exitoso, el estado de cierre se limpia para permitir un nuevo ciclo de sesión del mismo `UserId`. Esta corrección fue validada junto con la persistencia y el session lock.

### Coins

Moneda inicial: `100`.

Se incrementa al cosechar según la configuración del cultivo y se descuenta al comprar semillas.

### Level

Nivel inicial: `1`.

El nivel se calcula automáticamente a partir de la XP acumulada total.

### XP

Experiencia inicial: `0`.

La XP es acumulada total y no se reinicia al subir de nivel. Se incrementa al cosechar según la configuración del cultivo y `ProgressionService` calcula automáticamente el nivel correspondiente.

Umbrales actuales:

| Transición | XP acumulada requerida |
| --- | ---: |
| Nivel 1 → Nivel 2 | 10 |
| Nivel 2 → Nivel 3 | 25 |
| Nivel 3 → Nivel 4 | 50 |

La configuración está preparada para agregar niveles posteriores y permite subir varios niveles si una recompensa supera varios umbrales.

### Seeds

`Seeds` es el campo legado que almacena las semillas de Corn:

```text
PlayerData.Seeds
```

Se conserva para mantener compatibilidad con la agricultura y las APIs existentes.

### Inventory

Los demás objetos se almacenan por `itemId`:

```text
PlayerData.Inventory[itemId]
```

Con `DEV_MODE = true`, los jugadores nuevos reciben:

```text
PlayerData.Inventory["TomatoSeeds"] = 3
```

## 5. Player Attributes utilizados por el HUD

`PlayerDataService:SyncPlayerAttributes(player)` publica únicamente estos Attributes:

| Attribute | Fuente |
| --- | --- |
| `Coins` | `PlayerData.Coins` |
| `Level` | `PlayerData.Level` |
| `XP` | `PlayerData.XP` |
| `Seeds` | `PlayerData.Seeds` |
| `TomatoSeeds` | `PlayerData.Inventory["TomatoSeeds"]` |

Los Attributes son una proyección para visualización. No son la fuente de verdad.

## 6. InventoryService

Archivo: `src/ServerScriptService/Systems/Inventory/InventoryService.lua`.

Métodos:

| Método | Función |
| --- | --- |
| `GetItemCount(player, itemId)` | Obtiene la cantidad del objeto. |
| `AddItem(player, itemId, amount)` | Agrega unidades válidas. |
| `RemoveItem(player, itemId, amount)` | Elimina unidades si hay suficientes. |
| `HasItem(player, itemId, amount)` | Comprueba si hay suficientes unidades. |

Valida identificadores no vacíos y cantidades positivas, enteras y finitas. Después de `AddItem` y `RemoveItem` exitosos sincroniza los Attributes del jugador.

No existe un inventario global ni un almacenamiento separado de `PlayerData`.

## 7. SeedService

Archivo: `src/ServerScriptService/Systems/Seeds/SeedService.lua`.

Mantiene la API compatible:

- `GetSeedCount`
- `AddSeeds`
- `ConsumeSeed`

También soporta semillas por identificador:

- `GetSeedCountByItem`
- `AddSeedsByItem`
- `ConsumeSeedByItem`

Todas las operaciones delegan en `InventoryService`.

## 8. CropCatalog

Archivo: `src/ServerScriptService/Systems/Farming/CropCatalog.lua`.

`CropCatalog` contiene la configuración compartida de cada cultivo. Cada definición incluye:

- `SeedItemId`.
- `GrowthDuration`.
- `CoinsReward`.
- `XPReward`.
- `SeedDropChance`.
- `VisualModelName`.
- Etapas visuales durante `Growing`.
- Apariencia cuando está `Ready`.

No crea objetos de Workspace ni contiene estado de jugadores.

## 9. Cultivos actuales

### Corn

```text
CropType: Corn
SeedItemId: Seeds
GrowthDuration: 30 segundos
CoinsReward: 10
XPReward: 5
SeedDropChance: 0.15
VisualModelName: CornCrop
```

### Tomato

```text
CropType: Tomato
SeedItemId: TomatoSeeds
GrowthDuration: 45 segundos
CoinsReward: 15
XPReward: 8
SeedDropChance: 0.20
VisualModelName: TomatoCrop
```

Ambos cultivos utilizan el mismo `FarmingService`; no existen servicios duplicados.

## 10. Flujo de agricultura

El flujo actual es:

```text
Empty → Plant → Growing → Ready → Harvest → Empty
```

### 10.1 Plantación

`PlotInteractionService` detecta el `ProximityPrompt` de una parcela y consulta `CropState`.

Si la parcela está `Empty`, llama:

```lua
FarmingService:Plant(player, plot)
```

`FarmingService`:

1. Valida que el jugador esté activo.
2. Obtiene `PlayerData`.
3. Lee `CropType`.
4. Obtiene la definición desde `CropCatalog`.
5. Consume el `SeedItemId` configurado mediante `SeedService`.
6. Incrementa `FarmingCycle`.
7. Programa el crecimiento.
8. Cambia `CropState` a `Growing`.

Si no hay suficientes semillas, la plantación falla y no cambia el estado de la parcela.

### 10.2 Crecimiento por etapas

`FarmingService` programa las etapas mediante `task.delay`.

Corn:

- Etapa 1 inmediatamente.
- Etapa 2 al 50% de 30 segundos.
- Etapa 3 a los 30 segundos.

Tomato:

- Etapa 1 inmediatamente.
- Etapa 2 al 50% de 45 segundos.
- Etapa 3 a los 45 segundos.

`VisualGrowthStage` es un atributo de la parcela. No autoriza por sí mismo ninguna acción de gameplay.

### 10.3 Ready

Al terminar `GrowthDuration`, `FarmingService` verifica que el ciclo siga vigente, publica la etapa visual final y cambia:

```text
CropState = Ready
```

### 10.4 Cosecha

Cuando la parcela está `Ready`, `PlotInteractionService` llama:

```lua
FarmingService:Harvest(player, plot)
```

`FarmingService`:

1. Valida jugador, datos y estado.
2. Agrega Coins según `CoinsReward`.
3. Agrega XP mediante `ProgressionService:AddXP(player, cropDefinition.XPReward)`.
4. Evalúa `SeedDropChance`.
5. Si corresponde, agrega una semilla del mismo `SeedItemId`.
6. Cambia `CropState` a `Empty`.
7. Cambia `VisualGrowthStage` a `0`.

`ProgressionService` actualiza la XP acumulada, calcula `Level` y sincroniza los Attributes mediante `PlayerDataService`. `FarmingService` conserva su sincronización final para Coins, semillas y demás Attributes.

### 10.5 Replantación

Al volver a `Empty`, el mismo prompt puede llamar nuevamente a `Plant` si el jugador tiene la semilla requerida.

## 11. Recompensas de Coins y XP

Las recompensas están configuradas en `CropCatalog`:

| Cultivo | Coins | XP |
| --- | ---: | ---: |
| Corn | +10 | +5 |
| Tomato | +15 | +8 |

Coins se modifica mediante `CurrencyService`, que centraliza las operaciones de economía utilizadas por `FarmingService` y `SeedShopService`.

La progresión de XP está implementada en:

- `src/ServerScriptService/Systems/Progression/ProgressionService.lua`
- `src/ServerScriptService/Systems/Progression/ProgressionCatalog.lua`

`FarmingService` ya no modifica directamente `PlayerData.XP`; utiliza `ProgressionService:AddXP()`.

### 11.1 ProgressionService

`ProgressionService` es un servicio server-side que:

- Valida el jugador y las cantidades de XP.
- Requiere cantidades enteras, positivas y finitas.
- Añade XP acumulada total.
- Calcula automáticamente el nivel.
- Permite subir varios niveles en una sola operación.
- Mantiene la XP acumulada al subir de nivel.
- Mantiene el último nivel configurado cuando se supera el máximo actual.
- Sincroniza `XP` y `Level` mediante `PlayerDataService`.

API actual:

- `AddXP(player, amount)`.
- `GetLevel(player)`.
- `GetXP(player)`.
- `GetXPRequirement(level)`.

`ProgressionCatalog` contiene únicamente los requisitos de XP por nivel.

## 12. Seed drops

Cada cultivo tiene su propio `SeedDropChance`:

| Cultivo | Semilla devuelta | Probabilidad configurada |
| --- | --- | ---: |
| Corn | `Seeds` | 15% |
| Tomato | `TomatoSeeds` | 20% |

El drop se aplica durante `FarmingService:Harvest` mediante `SeedService` e `InventoryService`.

## 13. CropVisualService

Archivo: `src/ServerScriptService/Systems/Farming/CropVisualService.lua`.

Responsabilidades:

- Buscar parcelas con atributo `CropType`.
- Resolver la definición desde `CropCatalog`.
- Buscar el modelo indicado por `VisualModelName`.
- Ocultar el modelo cuando la parcela está `Empty`.
- Ajustar escala y transparencia.
- Reaccionar a `CropState` y `VisualGrowthStage`.

No crea, elimina ni modifica la estructura de modelos. Los modelos deben existir previamente en Roblox Studio.

## 14. PlotInteractionService

Archivo: `src/ServerScriptService/Systems/Farming/PlotInteractionService.lua`.

Busca `Workspace.Stations.Farm`, detecta `ProximityPrompt` descendientes y encuentra la parcela ascendiendo hasta un ancestro con atributo `CropType`.

Conecta:

- `Empty` → `FarmingService:Plant`.
- `Growing` → sin acción.
- `Ready` → `FarmingService:Harvest`.

Evita conexiones duplicadas, pero solo registra prompts existentes durante `Initialize`.

## 15. SeedShopService

Archivo: `src/ServerScriptService/Systems/Seeds/SeedShopService.lua`.

Es un servicio stateless que no mantiene datos de jugadores.

API:

- `GetSeedPrice(seedId)`.
- `CanAffordSeeds(player, seedId, amount)`.
- `BuySeeds(player, seedId, amount)`.

Catálogo actual:

| Semilla | ItemId | Precio |
| --- | --- | ---: |
| `CornSeed` | `Seeds` | 5 Coins |
| `TomatoSeed` | `TomatoSeeds` | 8 Coins |

La compra se valida en servidor, agrega la semilla mediante `SeedService`, descuenta Coins y sincroniza Attributes después de completarse.

## 16. SeedShopInteractionService

Archivo: `src/ServerScriptService/Systems/Seeds/SeedShopInteractionService.lua`.

Busca:

```text
Workspace.Stations.SeedShop
```

Detecta `ProximityPrompt` descendientes y lee estos Attributes:

- `SeedId`.
- `PurchaseAmount`.

Valida la configuración y llama desde servidor:

```lua
SeedShopService:BuySeeds(player, seedId, purchaseAmount)
```

Evita conexiones duplicadas.

La interacción física requiere que el objeto `SeedShop` y sus prompts sean creados manualmente en Roblox Studio. La depuración de compras está actualmente activa mediante:

```lua
local DEBUG_SEED_SHOP = true
```

## 17. HUD.client.lua

Archivo: `src/StarterPlayer/HUD.client.lua`.

Crea programáticamente:

```text
PlayerGui
└── JardinHUD
    └── Panel
        ├── CoinsLabel
        ├── LevelLabel
        ├── XPLabel
        ├── SeedsLabel
        └── TomatoSeedsLabel
```

Lee exclusivamente:

```lua
player:GetAttribute("Coins")
player:GetAttribute("Level")
player:GetAttribute("XP")
player:GetAttribute("Seeds")
player:GetAttribute("TomatoSeeds")
```

Usa `GetAttributeChangedSignal` para actualizar los textos.

El panel está arriba a la derecha con:

```lua
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -20, 0, 20)
```

El HUD no requiere `PlayerDataService`, no usa `RemoteEvents` y no puede modificar los datos del servidor.

## 18. Integración actual de Main.server.lua

Archivo: `src/ServerScriptService/Main.server.lua`.

Inicializa en este orden:

```text
PlayerDataService
SeedShopInteractionService
PlotInteractionService
CropVisualService
```

`InventoryService`, `SeedService` y `SeedShopService` no requieren inicialización porque funcionan como módulos sin estado global propio.

## 19. Estado actual del Banco de Semillas

El Banco de Semillas está implementado en dos capas:

- API de compra en `SeedShopService`.
- Integración física mediante `SeedShopInteractionService`.

Está funcional si existen manualmente en Workspace:

```text
Workspace
└── Stations
    └── SeedShop
        ├── Prompt con SeedId = "CornSeed"
        │   └── PurchaseAmount = 1
        └── Prompt con SeedId = "TomatoSeed"
            └── PurchaseAmount = 1
```

No existe todavía una UI de tienda, selección de cantidad ni catálogo visual.

## DEV_MODE

En `PlayerDataService`:

```lua
local DEV_MODE = true
local DEV_TOMATO_SEEDS = 3
```

Cuando está activo, cada jugador nuevo recibe tres `TomatoSeeds` dentro de `PlayerData.Inventory`.

Cuando se desactive:

```lua
local DEV_MODE = false
```

los jugadores nuevos no recibirán esas semillas gratuitas. No modifica la lógica de agricultura, precios ni recompensas.

## Estado actual del proyecto

### IMPLEMENTADO Y OPERATIVO

- Vertical slice jugable completo.
- PlayerData con persistencia mediante DataStore.
- Session lock validado.
- Autosave implementado y validado.
- Ciclo de salida y reentrada del mismo jugador validado.
- Coordinación de cierre mediante `ClosingState`, incluida la limpieza después de un `Release()` exitoso.
- Inventario base por jugador.
- Compatibilidad de `Seeds` con `PlayerData.Seeds`.
- `SeedService` para semillas por `itemId`.
- `CropCatalog` con Corn y Tomato.
- Compra de semillas mediante el Banco de Semillas.
- Plantación, crecimiento, estado `Ready` y cosecha.
- Flujo `Empty → Growing → Ready → Empty`.
- Consumo de semillas al plantar.
- Recompensas de Coins y XP configuradas.
- Progresión de XP acumulada y niveles hasta el nivel 4.
- Cálculo automático de nivel mediante `ProgressionService`.
- Sincronización de XP y Level mediante Player Attributes.
- Seed drops configurados.
- Visuales por etapas para modelos existentes.
- Interacción física con parcelas existentes.
- API del Banco de Semillas.
- Integración física del Banco de Semillas mediante prompts configurados.
- HUD básico de solo lectura.
- HUD mostrando los datos cargados y persistidos mediante Attributes.
- Inicialización de servicios en `Main.server.lua`.

### IMPLEMENTADO — EN FASE DE AMPLIACIÓN

- Progresión: funciona con requisitos hasta el nivel 4 y está preparada para añadir más niveles.
- HUD: muestra valores, pero no tiene barras, notificaciones ni UI interactiva.
- Banco de Semillas: funciona mediante prompts, pero depende de objetos manuales y no tiene UI.
- Parcelas: funcionan si existen antes de inicializar el servidor.
- Visuales: funcionan si los modelos y piezas están correctamente configurados.
- Persistencia: el flujo principal está validado; deben mantenerse las pruebas finales después de cualquier cambio en el esquema o en el ciclo de sesión.

### PLANIFICADO / ARQUITECTURA PREPARADA

- Inventario ampliado para otros tipos de objetos.
- Nuevos cultivos mediante entradas adicionales en `CropCatalog`.
- Networking para una futura UI interactiva.
- Economía adicional sobre la base de Coins e inventario.

### PRÓXIMAS FUNCIONALIDADES

- Revisión de `DEV_MODE` y de la configuración de desarrollo antes de la entrega final.
- Completar y revisar los elementos del mapa en Roblox Studio.
- Mejoras de UI e interacciones.
- Misiones.
- Economía completa.
- Venta de cultivos.
- UI interactiva.
- NPCs con lógica.
- Inventario avanzado para otros tipos de objetos.
- `RemoteEvents` y `RemoteFunctions`.
- Detección dinámica de parcelas y prompts.
- Pruebas automatizadas.

## Sistemas todavía pendientes

### Configuración de desarrollo y mapa

`DEV_MODE` continúa activo para facilitar las pruebas y entrega semillas iniciales de desarrollo a jugadores nuevos. Debe revisarse antes de la configuración final de la entrega.

El mapa, sus parcelas, prompts, modelos visuales y elementos del Banco de Semillas se administran manualmente en Roblox Studio y deben completarse o revisarse de acuerdo con los nombres y Attributes esperados por los servicios.

### Misiones

No existen definiciones, progreso, objetivos, recompensas ni UI de misiones.

### Economía completa

No existen mercado, venta de cultivos, herramientas, recursos económicos ni historial de transacciones.

### Venta de cultivos

La cosecha solo otorga Coins y XP según `CropCatalog`; no se almacenan cultivos cosechados ni se pueden vender.

### UI interactiva

El HUD actual solo muestra información. No existen menús, botones de compra, inventario visual ni notificaciones.

### NPCs con lógica

Aunque el mapa puede contener modelos NPC, no existen servicios de diálogo, interacción o comportamiento de NPC.

### RemoteEvents/RemoteFunctions

No existen remotos. El HUD no los necesita porque usa Attributes; serán necesarios para futuras acciones iniciadas desde UI.

### Detección dinámica de parcelas/prompts

Los servicios recorren objetos durante `Initialize`. No escuchan `DescendantAdded` para conectar objetos creados posteriormente.

### Pruebas automatizadas

La validación depende de pruebas manuales en Roblox Studio. No existe un runner automatizado.

## Discrepancias documentales corregidas en esta versión

Este README ahora refleja que:

- El vertical slice jugable está funcional.
- La persistencia con DataStore está implementada y validada.
- El session lock y el autosave están implementados y validados.
- La salida y reentrada del mismo jugador está validada.
- `ClosingState` se limpia después de un cierre exitoso para permitir un nuevo ciclo de sesión del mismo `UserId`.
- Existen Corn y Tomato.
- Existe `SeedShopInteractionService.lua`.
- Existe `HUD.client.lua`.
- Existe `CurrencyService.lua`.
- `Main.server.lua` inicializa cuatro servicios.
- El Banco de Semillas tiene integración física mediante prompts.
- `TomatoSeed` cuesta 8 Coins.
- Los Attributes del HUD son parte de la sincronización actual.
- La progresión de XP y niveles está implementada y operativa.
- `ProgressionService.lua` y `ProgressionCatalog.lua` forman parte de la estructura actual.

## Próximos pasos

La persistencia, el session lock, la agricultura, las recompensas, la progresión y el HUD están implementados y validados. El siguiente trabajo recomendado es:

1. Revisar `DEV_MODE` y la configuración de desarrollo.
2. Completar y revisar los elementos del mapa en Roblox Studio.
3. Mejorar la UI y las interacciones existentes.
4. Implementar misiones y NPCs con lógica.
5. Ampliar el inventario para otros tipos de objetos.
6. Implementar venta de cultivos y economía adicional.
7. Añadir networking para futuras interfaces interactivas.
8. Implementar detección dinámica de parcelas y prompts.
9. Añadir pruebas automatizadas.

No se debe presentar ninguna de estas etapas como implementada hasta que exista código probado para ellas.
