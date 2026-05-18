# practicANDO

Menú interactivo en Bash para repasar y practicar los ejercicios de la UF de administración de sistemas. Cada ejercicio muestra el enunciado, la respuesta o los comandos, y —en los prácticos— permite ejecutarlos en la terminal con confirmación.

## Requisitos

- Linux con Bash
- Para ejercicios con privilegios: `sudo` (usuarios/grupos, `dmidecode`, particionado, `renice`, etc.)
- Opcional: VirtualBox (`VBoxManage`) para el ejercicio 24... aun que es muy recomendable hacerlo en una máquina virtual

## Uso

Desde el directorio donde quieras dejar los ficheros creados por los ejercicios prácticos:

```bash
cd /ruta/donde/quieras/trabajar
bash /ruta/al/proyecto/menu_ejercicios.sh
```

O, si el script tiene permisos de ejecución:

```bash
chmod +x menu_ejercicios.sh
./menu_ejercicios.sh
```

Algunos ejercicios requieren root:

```bash
sudo ./menu_ejercicios.sh
```

Los archivos y carpetas de los ejercicios **15** y **17** se crean en el **directorio actual** (desde donde lanzas el script), no en `$HOME`.

## Contenido por bloques

| Bloque | Tema | Ejercicios |
|--------|------|------------|
| 1 | Arquitectura del computador | 1–8 |
| 2 | Sistemas operativos y memoria | 9–14 |
| 3 | Sistemas de archivos | 15–19 |
| 4 | Multiusuario, multiproceso y virtualización | 20–24 |
| 5 | Rendimiento y ajuste del sistema | 25–28 |
| 6 | Casos integradores | 29–30 |

## Tipos de ejercicio

- **Teóricos:** enunciado y respuesta. Algunos incluyen comandos opcionales de consulta (por ejemplo, `dmidecode` en el ejercicio 1).
- **Prácticos:** enunciado, comandos de referencia, explicación y opción de ejecutar en vivo.

## Notas importantes

| Ejercicio | Comportamiento |
|-----------|----------------|
| 15, 17 | Crean `uf1465/` o `permisos1.txt` en el directorio desde el que ejecutas el script |
| 20 | Requiere `sudo`; no borra el usuario si ya existe |
| 22 | Lanza `dd` en segundo plano y aplica `renice`; el proceso se detiene al finalizar la demo |
| 24 | Comprueba `VBoxManage`; no crea la VM completa automáticamente (evita cambios graves en el sistema) |
| 27 | Muestra `lsblk`, permite **elegir el disco** y guía partición, formateo ext4 y montaje en `/mnt/datos`. Usar solo el disco nuevo, no el del sistema |
| 30 | Integra varias tareas; el montaje de disco enlaza con el ejercicio 27 |

## Estructura del proyecto

```
practicANDO/
├── README.md
└── menu_ejercicios.sh
```

## Licencia

Material educativo creado por Juan
