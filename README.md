# Onasor

Descargas de las herramientas de terminal de Onasor. Cada una se instala con un comando, sin cuenta de GitHub y sin permisos de administrador. onasor-ports también funciona en Linux.

## onasor-vps

Gestor de servidores SSH: lista tus servidores con su estado y abre sesiones ssh, sftp y túneles en pestañas. También ejecuta comandos remotos y administra claves.

```powershell
irm https://raw.githubusercontent.com/GonzaloRosano/onasor/main/vps.ps1 | iex
```

Requiere el cliente OpenSSH de Windows (Configuración › Sistema › Características opcionales › Cliente OpenSSH). `onasor-vps doctor` verifica que esté todo.

## onasor-cli

Gestión del PC desde la terminal: monitor del sistema, uso de disco, temporales y duplicados, programas, inicio y servicios, automatizaciones y un mapa con relojes del mundo.

```powershell
irm https://raw.githubusercontent.com/GonzaloRosano/onasor/main/cli.ps1 | iex
```

## onasor-ports

Puertos, procesos y firewall: qué escucha en cada puerto y si el firewall lo deja pasar. Permite terminar el proceso que ocupa un puerto y abrir o cerrar puertos en el Firewall de Windows, ufw o firewalld.

```powershell
irm https://raw.githubusercontent.com/GonzaloRosano/onasor/main/ports.ps1 | iex
```

En Linux (se instala en `/usr/local/bin` con sudo, o en `~/.local/bin`):

```sh
curl -fsSL https://raw.githubusercontent.com/GonzaloRosano/onasor/main/ports.sh | sh
```

## onasor-mc

Launcher de Minecraft para la terminal: instancias separadas, vanilla, Fabric, Forge y NeoForge, mods y modpacks de Modrinth, y el Java correcto para cada versión, bajado solo. Para entrar se usa la cuenta Microsoft.

```powershell
irm https://raw.githubusercontent.com/GonzaloRosano/onasor/main/mc.ps1 | iex
```

En Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/GonzaloRosano/onasor/main/mc.sh | sh
```

## Cómo funciona el instalador

- Descarga el `.exe` del último release de la herramienta, para tu arquitectura (x64 o ARM64).
- Verifica su SHA-256 contra `SHA256SUMS` del mismo release.
- Lo copia a `%LOCALAPPDATA%\Programs\<herramienta>` y agrega esa carpeta al PATH de tu usuario.
- Para actualizar, volvé a correr el mismo comando.

Para elegir la versión, la carpeta o no tocar el PATH:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/GonzaloRosano/onasor/main/vps.ps1))) -Version v1.4.0 -Dir C:\herramientas -NoPath
```

Las descargas manuales están en [Releases](https://github.com/GonzaloRosano/onasor/releases): los tags `vps-v*` son de onasor-vps, los `cli-v*` de onasor-cli los `ports-v*` de onasor-ports y los `mc-v*` de onasor-mc.

## Desinstalar

Borrá la carpeta `%LOCALAPPDATA%\Programs\<herramienta>` y sacala del PATH (Configuración › Sistema › Acerca de › Configuración avanzada del sistema › Variables de entorno).

## onasor-claude

Lanzador y panel de Claude Code: proyectos y sesiones para retomar con un click, cuota de 5 horas y 7 días, en qué se van los tokens, la memoria (auto-memoria y engram) y los ajustes (modelo, plugins, skills).

```powershell
irm https://raw.githubusercontent.com/GonzaloRosano/onasor/main/claude.ps1 | iex
```

En Linux:

```sh
curl -fsSL https://raw.githubusercontent.com/GonzaloRosano/onasor/main/claude.sh | sh
```
