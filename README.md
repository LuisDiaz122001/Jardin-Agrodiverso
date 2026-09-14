# Jardín Agrodiverso

## 1. Descripción general

**Jardín Agrodiverso** es un videojuego educativo en Roblox que representa un jardín agrodiverso mediante mecánicas de cultivo, inventario, semillas, recompensas y progresión futura.

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
FarmingService / SeedShopService
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
            └── Farming/
                ├── CropCatalog.lua
                ├── FarmingService.lua
                ├── PlotInteractionService.lua
                └── CropVisualService.lua
```

## 4. PlayerData actual

`PlayerDataService` crea datos en memoria por jugador:

```lua
{
    Coins = 100,
    Level = 1,
    XP = 0,
    Seeds = 0,
    Inventory = {},
}
```

Los datos se eliminan al salir el jugador. Actualmente no existe persistencia con DataStore.

### Coins

Moneda inicial: `100`.

Se incrementa al cosechar según la configuración del cultivo y se descuenta al comprar semillas.

### Level

Nivel inicial: `1`.

El valor se muestra y se replica, pero todavía no existe una fórmula ni una mecánica que lo incremente automáticamente.

### XP

Experiencia inicial: `0`.

Se incrementa al cosechar según la configuración del cultivo. Todavía no existe un sistema de progresión basado en XP.

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
3. Agrega XP según `XPReward`.
4. Evalúa `SeedDropChance`.
5. Si corresponde, agrega una semilla del mismo `SeedItemId`.
6. Sincroniza los Attributes.
7. Cambia `CropState` a `Empty`.
8. Cambia `VisualGrowthStage` a `0`.

### 10.5 Replantación

Al volver a `Empty`, el mismo prompt puede llamar nuevamente a `Plant` si el jugador tiene la semilla requerida.

## 11. Recompensas de Coins y XP

Las recompensas están configuradas en `CropCatalog`:

| Cultivo | Coins | XP |
| --- | ---: | ---: |
| Corn | +10 | +5 |
| Tomato | +15 | +8 |

No existe todavía un `CurrencyService` ni un `ExperienceService`. Las modificaciones se realizan directamente sobre `PlayerData` desde los servicios actuales.

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

### COMPLETADO

- Datos de jugador en memoria durante la sesión.
- Inventario base por jugador.
- Compatibilidad de `Seeds` con `PlayerData.Seeds`.
- `SeedService` para semillas por `itemId`.
- `CropCatalog` con Corn y Tomato.
- Plantación, crecimiento, estado `Ready` y cosecha.
- Flujo `Empty → Growing → Ready → Empty`.
- Recompensas de Coins y XP configuradas.
- Seed drops configurados.
- Visuales por etapas para modelos existentes.
- Interacción física con parcelas existentes.
- API del Banco de Semillas.
- Integración física del Banco de Semillas mediante prompts configurados.
- HUD básico de solo lectura.
- Sincronización de Attributes para el HUD.
- Inicialización de servicios en `Main.server.lua`.

### FUNCIONAL PERO INCOMPLETO

- `PlayerDataService`: funciona en memoria, pero no guarda datos.
- Coins: se obtienen y gastan, pero no existe una capa económica centralizada.
- XP: se obtiene y muestra, pero no produce progresión.
- Level: se muestra, pero permanece en el valor inicial.
- HUD: muestra valores, pero no tiene barras, notificaciones ni UI interactiva.
- Banco de Semillas: funciona mediante prompts, pero depende de objetos manuales y no tiene UI.
- Parcelas: funcionan si existen antes de inicializar el servidor.
- Visuales: funcionan si los modelos y piezas están correctamente configurados.

### PREPARADO PERO NO IMPLEMENTADO

- Inventario ampliado para otros tipos de objetos.
- Nuevos cultivos mediante entradas adicionales en `CropCatalog`.
- Networking para una futura UI interactiva.
- Progresión de XP y niveles usando los campos existentes.
- Economía adicional sobre la base de Coins e inventario.

### PENDIENTE

- Persistencia/DataStore.
- Progresión real de niveles.
- Misiones.
- Economía completa.
- Venta de cultivos.
- UI interactiva.
- NPCs con lógica.
- `RemoteEvents` y `RemoteFunctions`.
- Detección dinámica de parcelas y prompts.
- Pruebas automatizadas.

## Sistemas todavía pendientes

### Persistencia/DataStore

No existe carga, guardado, reintentos, migración ni versionado de datos.

### Progresión real de niveles

No existen umbrales de XP, fórmulas, subida automática de `Level` ni recompensas por nivel.

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

- Existen Corn y Tomato.
- Existe `SeedShopInteractionService.lua`.
- Existe `HUD.client.lua`.
- `Main.server.lua` inicializa cuatro servicios.
- El Banco de Semillas tiene integración física mediante prompts.
- `TomatoSeed` cuesta 8 Coins.
- Los Attributes del HUD son parte de la sincronización actual.

## Próximos pasos

El siguiente sistema previsto es implementar la **progresión real de XP y niveles**:

1. Definir umbrales de XP.
2. Procesar incrementos de nivel.
3. Mantener `Level` bajo la autoridad del servidor.
4. Actualizar los Attributes existentes para que el HUD refleje el nivel.
5. Probar la progresión sin modificar la lógica actual de cultivos.

Después se recomienda implementar, en este orden:

1. Economía adicional y venta de cultivos.
2. Misiones basadas en eventos de agricultura, inventario y progresión.
3. Persistencia/DataStore una vez estabilizado el esquema de datos y las recompensas.
4. UI interactiva y networking seguro.
5. Detección dinámica de parcelas y prompts.
6. Pruebas automatizadas.

No se debe presentar ninguna de estas etapas como implementada hasta que exista código probado para ellas.
