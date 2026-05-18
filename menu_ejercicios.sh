#!/bin/bash

# Colores para la interfaz de la terminal
VERDE='\033[0;32m'
AZUL='\033[0;34m'
AMARILLO='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Función para limpiar pantalla y mostrar cabecera
cabecera() {
    clear
    echo -e "${AZUL}======================================================================${RESET}"
    echo -e "${VERDE}                         practicANDO                               ${RESET}"
    echo -e "${VERDE}              MF0223_3 — Ejercicios interactivos                      ${RESET}"
    echo -e "${VERDE}                          con su CLI                                 ${RESET}"
    echo -e "${VERDE}                  creada por entreunosyceros                        ${RESET}"
    echo -e "${AZUL}======================================================================${RESET}"
}

# Función de pausa
pausa() {
    echo -e "\n${AMARILLO}Pulsa [Enter] para continuar...${RESET}"
    read -r
}

# Ejercicios teóricos: enunciado + respuesta (+ comandos opcionales)
mostrar_teoria() {
    local enunciado=$1
    local respuesta=$2
    local comandos=$3
    local comando_ejec=${4:-$comandos}

    echo -e "\n${CYAN}[ENUNCIADO]${RESET}"
    echo -e "$enunciado"
    echo -e "\n${VERDE}[RESPUESTA]${RESET}"
    echo -e "$respuesta"

    if [[ -n "$comandos" ]]; then
        echo -e "\n${AZUL}[COMANDOS]${RESET}"
        echo -e "$comandos"
        preguntar_ejecucion "$comando_ejec"
    fi
}

# Ejercicios prácticos: enunciado + comandos + explicación + opción de ejecutar
mostrar_practica() {
    local enunciado=$1
    local comandos=$2
    local explicacion=$3
    local comando_ejec=${4:-$comandos}

    echo -e "\n${CYAN}[ENUNCIADO]${RESET}"
    echo -e "$enunciado"
    echo -e "\n${AZUL}[COMANDOS]${RESET}"
    echo -e "$comandos"
    echo -e "\n${VERDE}[EXPLICACIÓN]${RESET}"
    echo -e "$explicacion"
    preguntar_ejecucion "$comando_ejec"
}

# Pregunta si se desea ejecutar el bloque de comandos en la terminal
preguntar_ejecucion() {
    local comando_bloque=$1
    echo -e "\n${AMARILLO}¿Quieres ejecutar este comando en tu terminal para ver el resultado? (s/n):${RESET} "
    read -r respuesta_ejecutar
    if [[ "$respuesta_ejecutar" =~ ^[Ss]$ ]]; then
        echo -e "\n${VERDE}--- EJECUTANDO COMANDO EN VIVO ---${RESET}"
        if declare -f "$comando_bloque" &>/dev/null; then
            "$comando_bloque"
        else
            eval "$comando_bloque"
        fi
        echo -e "${VERDE}----------------------------------${RESET}"
    else
        echo -e "\nEjecución cancelada. También puedes copiar los comandos y ejecutarlos manualmente en otra terminal."
    fi
}

# Devuelve el nombre del primer dispositivo de partición (sdb1, nvme0n1p1, etc.)
ejercicio_27_primera_particion() {
    local disco=$1
    local hijo
    hijo=$(lsblk -ln -o NAME "$disco" 2>/dev/null | awk 'NR==2 {print; exit}')
    if [[ -n "$hijo" ]]; then
        echo "/dev/$hijo"
        return 0
    fi
    if [[ "$disco" == *nvme* ]]; then
        echo "${disco}p1"
    else
        echo "${disco}1"
    fi
}

# RAM: total del SO + cada banco DIMM (2×8 GB = 16 GB; no confundir una barra con el total)
mostrar_ram_instalada() {
    local mib total_free n_mod
    mib=$(awk '/MemTotal:/ {printf "%.1f", $2/1024/1024}' /proc/meminfo 2>/dev/null)
    total_free=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}')
    echo "  Total que usa Linux: ${mib} GiB (free -h: ${total_free:-?})"
    echo "  Bancos DIMM (sudo dmidecode -t 17):"
    if ! sudo dmidecode -t 17 2>/dev/null | grep -q '^[[:space:]]*Size: [0-9]'; then
        echo "  (Sin datos DMI. Usa: free -h)"
        return
    fi
    n_mod=$(sudo dmidecode -t 17 2>/dev/null | awk '/^[[:space:]]+Size:/ && $2 ~ /^[0-9]/ { c++ } END { print c+0 }')
    sudo dmidecode -t 17 2>/dev/null | awk '
        /^Memory Device$/ { n++; if (n > 1) print ""; printf "  [DIMM %d]\n", n }
        /^[[:space:]]+Size:/ && $2 ~ /^[0-9]/ { print }
        /^[[:space:]]+Locator:/ { print }
        /^[[:space:]]+Bank Locator:/ { print }
        /^[[:space:]]+Type:/ && $2 !~ /Detail/ { print }
    '
    if (( n_mod >= 2 )); then
        echo "  → ${n_mod} módulos instalados (p. ej. 2×8 GB = 16 GB; free -h muestra ~15 Gi por redondeo)."
    fi
}

# Ejercicio 1: complemento en Linux para cada componente de placa base
ejercicio_01_comandos() {
    echo -e "[1) Procesador / zócalo]:"
    sudo dmidecode -t processor 2>/dev/null | grep -E "Socket|Version|Upgrade" | head -n 5

    echo -e "\n[2) Placa base y chipset]:"
    sudo dmidecode -t baseboard 2>/dev/null | grep -E "Manufacturer|Product Name|Version"
    lspci 2>/dev/null | grep -iE "LPC|chipset|ISA bridge" | head -n 3

    echo -e "\n[3) Memoria RAM / bancos DIMM]:"
    mostrar_ram_instalada

    echo -e "\n[4) SATA (controlador y discos)]:"
    sudo lspci 2>/dev/null | grep -iE "sata|ahci"
    lsblk -d -o NAME,SIZE,TRAN,MODEL 2>/dev/null | grep -v loop | head -n 8

    echo -e "\n[5) Ranuras PCIe]:"
    sudo dmidecode -t slot 2>/dev/null | grep -E "Designation|Type" | head -n 6

    echo -e "\n[6) Conector ATX]:"
    if sudo dmidecode -t 39 2>/dev/null | grep -E "Max Power|Status" | head -n 4 | grep -q .; then
        sudo dmidecode -t 39 2>/dev/null | grep -E "Max Power|Status" | head -n 4
    else
        echo "  No hay datos DMI de la fuente. Identifícalo en la placa: conector 24 pines ATX + 4/8 pines CPU."
    fi

    echo -e "\n[7) Panel trasero I/O]:"
    echo "  USB:"
    lsusb 2>/dev/null | head -n 6
    echo "  Red:"
    ip -br link show 2>/dev/null | grep -v "^lo" || true
    echo "  Vídeo / audio / red (lspci):"
    lspci 2>/dev/null | grep -iE "VGA|3D|Ethernet|Audio" | head -n 6
}

# Ejercicio 27: lista discos con lsblk y deja elegir cuál particionar y montar
ejercicio_27_seleccionar_disco() {
    local -a discos=()
    local nombre tam sel disco part montaje=/mnt/datos op_part conf fmt i

    echo -e "${AZUL}--- Discos detectados (lsblk) ---${RESET}"
    lsblk
    echo

    mapfile -t discos < <(lsblk -d -n -o NAME,SIZE,TYPE 2>/dev/null | awk '$3=="disk" && $1 !~ /^(sr|loop)/ {print $1 "|" $2}')

    if [[ ${#discos[@]} -eq 0 ]]; then
        echo -e "${AMARILLO}No se encontraron discos. Añade un disco en la VM y vuelve a intentarlo.${RESET}"
        return 1
    fi

    echo -e "${AMARILLO}Selecciona el disco (elige solo el disco nuevo, no el del sistema):${RESET}"
    for i in "${!discos[@]}"; do
        IFS='|' read -r nombre tam <<< "${discos[$i]}"
        echo -e "  $((i + 1))) /dev/${nombre}  (${tam})"
    done
    echo "  0) Cancelar"
    echo -n "Número de disco: "
    read -r sel

    if [[ "$sel" == "0" || -z "$sel" ]]; then
        echo "Operación cancelada."
        return 0
    fi
    if ! [[ "$sel" =~ ^[0-9]+$ ]] || (( sel < 1 || sel > ${#discos[@]} )); then
        echo "Opción no válida."
        return 1
    fi

    IFS='|' read -r nombre tam <<< "${discos[$((sel - 1))]}"
    disco="/dev/${nombre}"

    echo -e "\n${AZUL}Detalle de ${disco}:${RESET}"
    lsblk "$disco"
    echo

    part=$(ejercicio_27_primera_particion "$disco")
    if [[ -b "$part" ]] && lsblk -ln -o NAME "$disco" 2>/dev/null | awk 'NR>1' | grep -q .; then
        echo -e "${AMARILLO}Este disco ya tiene particiones.${RESET}"
        echo "1) Usar la primera partición: $part"
        echo "2) Crear partición nueva en todo el disco (reemplaza la tabla de particiones)"
        echo "0) Cancelar"
        echo -n "Opción: "
        read -r op_part
        case $op_part in
            1) ;;
            2)
                echo -e "${AMARILLO}ATENCIÓN: ten claro que se borrará la tabla de particiones de ${disco}.${RESET}"
                echo -n "¿Continuar? (s/n): "
                read -r conf
                [[ "$conf" =~ ^[Ss]$ ]] || { echo "Cancelado."; return 0; }
                sudo parted -s "$disco" mklabel msdos mkpart primary ext4 1MiB 100%
                sudo partprobe "$disco" 2>/dev/null
                sleep 2
                part=$(ejercicio_27_primera_particion "$disco")
                ;;
            *) echo "Cancelado."; return 0 ;;
        esac
    else
        echo -e "${AMARILLO}Se va a crear una partición primaria ext4 en ${disco} (${tam}).${RESET}"
        echo -n "¿Continuar? (s/n): "
        read -r conf
        [[ "$conf" =~ ^[Ss]$ ]] || { echo "Cancelado."; return 0; }
        sudo parted -s "$disco" mklabel msdos mkpart primary ext4 1MiB 100%
        sudo partprobe "$disco" 2>/dev/null
        sleep 2
        part=$(ejercicio_27_primera_particion "$disco")
    fi

    if [[ ! -b "$part" ]]; then
        echo -e "${AMARILLO}No se detectó la partición ${part}. Comprueba con: lsblk ${disco}${RESET}"
        return 1
    fi

    echo -n "¿Formatear ${part} como ext4? (esto borrará los datos existentes) (s/n): "
    read -r fmt
    if [[ "$fmt" =~ ^[Ss]$ ]]; then
        echo -e "${VERDE}Formateando ${part}...${RESET}"
        sudo mkfs.ext4 -F "$part"
    fi

    echo -e "${VERDE}Montando ${part} en ${montaje}...${RESET}"
    sudo mkdir -p "$montaje"
    if sudo mount "$part" "$montaje" 2>/dev/null; then
        echo -e "\n${VERDE}Montaje correcto:${RESET}"
        df -h "$montaje"
    else
        echo -e "${AMARILLO}No se pudo montar. Si la partición no está formateada, responde 's' al formateo.${RESET}"
        return 1
    fi
}

# --- SUBMENÚS POR BLOQUES ---

bloque1() {
    while true; do
        cabecera
        echo -e "${CYAN}--- BLOQUE 1: ARQUITECTURA DEL COMPUTADOR ---${RESET}"
        echo "1) Ejercicio 1: Componentes de placa base"
        echo "2) Ejercicio 2: Procesadores CISC y RISC"
        echo "3) Ejercicio 3: Partes del procesador"
        echo "4) Ejercicio 4: Instrucciones 8086"
        echo "5) Ejercicio 5: Memoria RAM y xPROM"
        echo "6) Ejercicio 6: Jerarquía de memoria"
        echo "7) Ejercicio 7: Interfaces de entrada/salida"
        echo "8) Ejercicio 8: Comparativa de discos"
        echo "0) Volver al menú principal"
        echo -n "Selecciona un ejercicio: "
        read -r opc

        case $opc in
            1)
                mostrar_teoria \
                    "A partir de una imagen o manual de placa base, identifica y nombra al menos: zócalo del procesador, bancos DIMM, chipset, puertos SATA, ranuras PCIe, conector ATX de alimentación y panel trasero." \
                    "• Zócalo del procesador (socket): donde se inserta la CPU (ej. LGA1700, AM5).\n• Bancos DIMM: ranuras para módulos de memoria RAM.\n• Chipset: circuitos que gestionan E/S, PCIe y comunicación CPU-periféricos.\n• Puertos SATA: conexión de discos ópticos/HDD/SSD internos.\n• Ranuras PCIe: expansión (gráfica, red, NVMe en algunas placas).\n• Conector ATX (24 pines + 4/8 pines CPU): alimentación desde la fuente.\n• Panel trasero (I/O shield): USB, audio, red, vídeo integrados hacia el exterior del chasis.\n\n${AMARILLO}Complemento opcional en Linux:${RESET} los comandos siguientes muestran datos que el SO detecta (dmidecode, lspci, lsblk, lsusb). No sustituyen identificar la placa en un manual o imagen; el conector ATX solo se reconoce a simple vista en la placa." \
                    "# 1) Procesador (zócalo / modelo)\nsudo dmidecode -t processor | grep -E \"Socket|Version|Upgrade\" | head -n 5\n\n# 2) Placa base y chipset\nsudo dmidecode -t baseboard | grep -E \"Manufacturer|Product Name|Version\"\nlspci | grep -iE \"LPC|chipset|ISA bridge\" | head -n 3\n\n# 3) Memoria RAM: total del SO + cada banco DIMM (sin líneas Volatile/Cache Size)\nfree -h\nsudo dmidecode -t 17 | awk '/^Memory Device$/{n++;if(n>1)print\"\";printf \"[DIMM %d]\\n\",n} /^[[:space:]]+Size:/&&$2~/^[0-9]/{print} /^[[:space:]]+Locator:/{print} /^[[:space:]]+Bank Locator:/{print} /^[[:space:]]+Type:/&&$2!~/Detail/{print}'\n\n# 4) Puertos SATA (controlador y discos)\nsudo lspci | grep -iE \"sata|ahci\"\nlsblk -d -o NAME,SIZE,TRAN,MODEL | grep -v loop\n\n# 5) Ranuras PCIe\nsudo dmidecode -t slot | grep -E \"Designation|Type\" | head -n 6\n\n# 6) Conector ATX (solo físico; DMI a veces muestra fuente)\nsudo dmidecode -t 39 2>/dev/null | grep -E \"Max Power|Status\" | head -n 4\n# Si no hay salida: localizar en la placa el conector 24 pines + 4/8 pines CPU\n\n# 7) Panel trasero I/O (periféricos que el SO ve)\nlsusb | head -n 6\nip -br link show | grep -v \"^lo\"\nlspci | grep -iE \"VGA|3D|Ethernet|Audio\" | head -n 6" \
                    'ejercicio_01_comandos'
                pausa ;;
            2)
                mostrar_teoria \
                    "Explica qué diferencia a una arquitectura CISC de una RISC. Pon dos ejemplos de procesadores o familias en cada caso." \
                    "CISC (Complex Instruction Set Computer): instrucciones complejas y variables; muchas operaciones en una sola instrucción; código más compacto. Ejemplos: Intel x86/x86-64, AMD Ryzen.\n\nRISC (Reduced Instruction Set Computer): conjunto reducido de instrucciones simples y de longitud fija; más registros; mayor eficiencia por ciclo en muchos escenarios. Ejemplos: ARM (Apple M-series, móviles), RISC-V."
                pausa ;;
            3)
                mostrar_teoria \
                    "Define brevemente: ALU, registros, contador de programa, unidad de control e interrupciones." \
                    "• ALU (Arithmetic Logic Unit): ejecuta operaciones aritméticas y lógicas.\n• Registros: almacenamiento interno ultrarrápido del procesador.\n• Contador de programa (PC): apunta a la dirección de la siguiente instrucción a ejecutar.\n• Unidad de control: decodifica instrucciones y coordina ALU, registros y buses.\n• Interrupciones: señales que pausan la ejecución normal para atender eventos prioritarios (E/S, temporizador, errores)."
                pausa ;;
            4)
                mostrar_teoria \
                    "Clasifica las instrucciones del 8086: MOV, ADD, CMP, JMP, INT, PUSH, LOOP, XOR." \
                    "• Transferencia de datos / pila: MOV, PUSH\n• Aritméticas y comparación: ADD, CMP\n• Lógicas: XOR\n• Salto y control de flujo: JMP, LOOP\n• Sistema: INT (llamada a interrupción/software)"
                pausa ;;
            5)
                mostrar_teoria \
                    "Diferencia RAM, ROM, PROM, EPROM, EEPROM y memoria Flash." \
                    "• RAM: volátil; lectura y escritura rápida; pierde datos sin alimentación.\n• ROM: no volátil; grabada de fábrica; solo lectura.\n• PROM: programable una sola vez por el usuario.\n• EPROM: borrable con luz UV antes de reprogramar.\n• EEPROM: borrado y escritura eléctricos, byte a byte (más lento).\n• Flash: tipo de EEPROM que borra por bloques; base de pendrives y SSD."
                pausa ;;
            6)
                mostrar_teoria \
                    "Ordena de mayor velocidad a menor: disco duro, caché L1, RAM, registros, caché L3, SSD." \
                    "1. Registros\n2. Caché L1\n3. Caché L3\n4. RAM\n5. SSD\n6. Disco duro (HDD)"
                pausa ;;
            7)
                mostrar_teoria \
                    "Relaciona cada interfaz con su uso principal: USB, SATA, PCIe, RJ-45, PS/2, eSATA." \
                    "• USB: periféricos generales (teclado, ratón, almacenamiento, impresoras).\n• SATA: discos internos HDD/SSD.\n• PCIe: tarjetas de expansión y SSD NVMe.\n• RJ-45: red Ethernet.\n• PS/2: teclado/ratón legacy.\n• eSATA: discos externos SATA de alta velocidad."
                pausa ;;
            8)
                mostrar_teoria \
                    "Compara HDD, SSD SATA y SSD NVMe en velocidad, precio por GB, ruido y resistencia." \
                    "• HDD: velocidad baja (100-200 MB/s), muy barato por GB, ruido mecánico, sensible a golpes.\n• SSD SATA: velocidad media (~500 MB/s), precio moderado, silencioso, resistente a golpes.\n• SSD NVMe (PCIe): muy alta velocidad (3000+ MB/s), más caro por GB, silencioso, resistente."
                pausa ;;
            0) break ;;
            *) echo "Opción no válida"; pausa ;;
        esac
    done
}

bloque2() {
    while true; do
        cabecera
        echo -e "${CYAN}--- BLOQUE 2: SISTEMAS OPERATIVOS Y MEMORIA ---${RESET}"
        echo "9) Ejercicio 9: Funciones del sistema operativo"
        echo "10) Ejercicio 10: SO como interfaz y administrador"
        echo "11) Ejercicio 11: Reubicación, protección y compartición"
        echo "12) Ejercicio 12: Memoria virtual"
        echo "13) Ejercicio 13: Paginación"
        echo "14) Ejercicio 14: Paginación y rendimiento"
        echo "0) Volver al menú principal"
        echo -n "Selecciona un ejercicio: "
        read -r opc

        case $opc in
            9)
                mostrar_teoria \
                    "Indica al menos cinco funciones principales de un sistema operativo." \
                    "1. Gestión de procesos (creación, planificación, terminación).\n2. Gestión de memoria (asignación, virtual, protección).\n3. Gestión del sistema de archivos.\n4. Gestión de entrada/salida y dispositivos.\n5. Seguridad, usuarios y permisos.\n(Otras: interfaz de usuario, comunicación entre procesos, red.)"
                pausa ;;
            10)
                mostrar_teoria \
                    "Explica la diferencia entre el SO como interfaz usuario/computador y como administrador de recursos." \
                    "Como interfaz: abstrae el hardware y ofrece comandos, ventanas o APIs cómodas para el usuario o las aplicaciones.\nComo administrador de recursos: reparte CPU, memoria, disco y E/S entre procesos de forma ordenada y segura."
                pausa ;;
            11)
                mostrar_teoria \
                    "Define reubicación, protección y compartición en gestión de memoria." \
                    "• Reubicación: un proceso puede cargarse en distintas zonas físicas de RAM sin recompilar (direcciones lógicas vs físicas).\n• Protección: cada proceso solo accede a su espacio; el SO impide accesos ilegales.\n• Compartición: varios procesos pueden usar la misma zona de memoria (p. ej. librerías o código del SO)."
                pausa ;;
            12)
                mostrar_teoria \
                    "Explica qué es la memoria virtual y por qué se usa." \
                    "Técnica que combina RAM y disco (swap/partición de intercambio) para que cada proceso vea más memoria de la disponible físicamente. Permite ejecutar más programas, aislar espacios de direcciones y simplificar la gestión de memoria."
                pausa ;;
            13)
                mostrar_teoria \
                    "¿Qué es una página? ¿Qué es un marco? ¿Qué ocurre en un fallo de página?" \
                    "• Página: bloque fijo del espacio de direcciones virtual de un proceso.\n• Marco (frame): bloque equivalente en la memoria física RAM.\n• Fallo de página: la CPU accede a una página no presente en RAM; el SO la carga desde disco (o termina el proceso si el acceso es inválido) y reanuda la ejecución."
                pausa ;;
            14)
                mostrar_teoria \
                    "¿Por qué demasiados fallos de página degradan tanto el rendimiento?" \
                    "Cada fallo implica acceso al disco, órdenes de magnitud más lento que la RAM. Si el sistema pasa más tiempo cargando páginas que ejecutando trabajo útil, aparece hiperpaginación (thrashing) y el rendimiento cae drásticamente."
                pausa ;;
            0) break ;;
            *) echo "Opción no válida"; pausa ;;
        esac
    done
}

bloque3() {
    while true; do
        cabecera
        echo -e "${CYAN}--- BLOQUE 3: SISTEMAS DE ARCHIVOS ---${RESET}"
        echo "15) Ejercicio 15: Comandos básicos de Linux"
        echo "16) Ejercicio 16: Rutas absolutas y relativas"
        echo "17) Ejercicio 17: Permisos en Linux"
        echo "18) Ejercicio 18: Sistemas de archivos con journaling"
        echo "19) Ejercicio 19: Comparación de sistemas de archivos"
        echo "0) Volver al menú principal"
        echo -n "Selecciona un ejercicio: "
        read -r opc

        case $opc in
            15)
                mostrar_practica \
                    "En Linux, crea una carpeta llamada uf1465, entra en ella, crea dos subcarpetas teoria y practica, muestra la ruta actual y lista el contenido." \
                    "mkdir uf1465\ncd uf1465\nmkdir teoria practica\npwd\nls" \
                    "mkdir crea directorios; cd cambia el directorio actual; pwd muestra la ruta absoluta; ls lista ficheros y carpetas." \
                    "(mkdir uf1465 && cd uf1465 && mkdir teoria practica && echo 'Ruta actual:' && pwd && echo 'Contenido:' && ls -F)"
                pausa ;;
            16)
                mostrar_teoria \
                    "Explica la diferencia entre ruta absoluta y relativa. Pon un ejemplo de cada una." \
                    "• Absoluta: empieza en la raíz / y no depende del directorio actual. Ejemplo: /home/alumno/uf1465/teoria\n• Relativa: se interpreta desde el directorio actual. Ejemplo: ./teoria o ../practica"
                pausa ;;
            17)
                mostrar_practica \
                    "Crea un fichero llamado permisos1.txt y asígnale permisos 764 usando notación octal. Explica qué significan." \
                    "touch permisos1.txt\nchmod 764 permisos1.txt\nls -l permisos1.txt" \
                    "764 en octal = rwx (7) propietario, rw- (6) grupo, r-- (4) otros.\n7=4+2+1 (lectura+escritura+ejecución), 6=4+2, 4=solo lectura." \
                    "touch permisos1.txt && chmod 764 permisos1.txt && ls -l permisos1.txt"
                pausa ;;
            18)
                mostrar_teoria \
                    "Explica qué aporta el journaling en un sistema de archivos y nombra uno que lo utilice." \
                    "El journaling registra cambios pendientes antes de aplicarlos al sistema de archivos. Tras un corte de energía, el SO puede recuperar la consistencia sin escanear todo el disco. Ejemplos: ext4, xfs, NTFS."
                pausa ;;
            19)
                mostrar_teoria \
                    "Completa la tabla con una característica típica de FAT32, NTFS y ext4." \
                    "• FAT32: alta compatibilidad entre SO; límite ~4 GB por fichero.\n• NTFS: nativo Windows; permisos, cuotas, journaling y cifrado (EFS).\n• ext4: nativo Linux; journaling, buen rendimiento y tamaños de volumen grandes."
                pausa ;;
            0) break ;;
            *) echo "Opción no válida"; pausa ;;
        esac
    done
}

bloque4() {
    while true; do
        cabecera
        echo -e "${CYAN}--- BLOQUE 4: MULTIUSUARIO, MULTIPROCESO Y VIRTUALIZACIÓN ---${RESET}"
        echo "20) Ejercicio 20: Creación de usuarios y grupos en Linux"
        echo "21) Ejercicio 21: Identificación de UID y GID"
        echo "22) Ejercicio 22: Procesos y prioridad"
        echo "23) Ejercicio 23: Multiproceso y multiusuario"
        echo "24) Ejercicio 24: Virtualización"
        echo "0) Volver al menú principal"
        echo -n "Selecciona un ejercicio: "
        read -r opc

        case $opc in
            20)
                mostrar_practica \
                    "Crea tres grupos llamados ventas, administracion y gestion. Después crea un usuario carlos cuyo grupo principal sea gestion." \
                    "sudo groupadd ventas\nsudo groupadd administracion\nsudo groupadd gestion\nsudo useradd -m -g gestion carlos" \
                    "groupadd crea grupos; useradd -m crea el home; -g gestion asigna el grupo principal (GID primario). Requiere privilegios de root." \
                    "sudo groupadd -f ventas 2>/dev/null; sudo groupadd -f administracion 2>/dev/null; sudo groupadd -f gestion 2>/dev/null; if id carlos &>/dev/null; then echo 'El usuario carlos ya existe:'; id carlos; else sudo useradd -m -g gestion carlos && echo 'Usuario carlos creado:' && id carlos; fi"
                pausa ;;
            21)
                mostrar_teoria \
                    "Indica qué archivos en Linux permiten consultar la información de usuarios y contraseñas cifradas." \
                    "• /etc/passwd: nombres de usuario, UID, GID primario, shell, directorio home (legible).\n• /etc/shadow: contraseñas cifradas y políticas (solo root).\n• /etc/group: grupos y miembros (complemento para GID)."
                pausa ;;
            22)
                mostrar_practica \
                    "Ejecuta un proceso que consuma CPU, observa su consumo. Compara procesos con distinta prioridad." \
                    "dd if=/dev/zero of=/dev/null &\nps -p \$PID -o pid,ni,%cpu,cmd\nsudo renice -n 10 -p \$PID\nps -p \$PID -o pid,ni,%cpu,cmd" \
                    "1) dd if=/dev/zero of=/dev/null copia datos que se descartan: no escribe en disco, pero mantiene la CPU ocupada. El & lo lanza en segundo plano; \$! guarda su PID.\n\n2) ps -p PID muestra ese proceso: pid (identificador), ni (prioridad nice) y %cpu (uso de procesador).\n\n3) En Linux, nice va de -20 (más prioritario) a 19 (menos prioritario). Un número mayor significa menor prioridad.\n\n4) renice -n 10 sube el nice en 10 puntos: el proceso pasa a ser menos preferente y, si hay otros trabajos, suele bajar su %cpu.\n\n5) Vuelves a ejecutar ps para comparar ni y %cpu antes y después del cambio." \
                    "dd if=/dev/zero of=/dev/null & PID=\$!; echo \"Proceso lanzado PID: \$PID\"; ps -p \$PID -o pid,ni,%cpu,cmd; echo 'Aplicando renice +10 (menor prioridad)...'; sudo renice -n 10 -p \$PID 2>/dev/null || renice -n 10 -p \$PID; ps -p \$PID -o pid,ni,%cpu,cmd; kill \$PID 2>/dev/null"
                pausa ;;
            23)
                mostrar_teoria \
                    "Explica la diferencia entre sistema multiusuario y sistema multiproceso." \
                    "• Multiusuario: varios usuarios pueden identificarse y trabajar (local o remoto) con cuentas y permisos separados.\n• Multiproceso: el SO gestiona muchos procesos a la vez (planificación, concurrencia); no implica necesariamente varias CPUs, aunque el hardware multicore lo facilita."
                pausa ;;
            24)
                mostrar_practica \
                    "Crea una máquina virtual Ubuntu en VirtualBox con 2 GB de RAM y 100 GB de disco. Después crea un clon y una instantánea." \
                    "VBoxManage createvm --name UbuntuUF --register\nVBoxManage modifyvm UbuntuUF --memory 2048\nVBoxManage createhd --filename UbuntuUF.vdi --size 102400\nVBoxManage clonevm UbuntuUF --name UbuntuUF-clon --register\nVBoxManage snapshot UbuntuUF take InicioUF" \
                    "Se realiza en la GUI de VirtualBox o con VBoxManage (CLI). 2048 MB = 2 GB; --size 102400 ≈ 100 GB. El clon duplica la VM; la instantánea guarda el estado para restaurar." \
                    "if command -v VBoxManage &>/dev/null; then VBoxManage --version; echo 'Para crear la VM completa usa los comandos del bloque [COMANDOS] con VirtualBox instalado.'; else echo 'VirtualBox/VBoxManage no está instalado. Instálalo o usa la interfaz gráfica: Máquina > Nueva > Ubuntu, 2048 MB RAM, disco 100 GB; luego Clonar e Instantánea.'; fi"
                pausa ;;
            0) break ;;
            *) echo "Opción no válida"; pausa ;;
        esac
    done
}

bloque5() {
    while true; do
        cabecera
        echo -e "${CYAN}--- BLOQUE 5: RENDIMIENTO Y AJUSTE DEL SISTEMA ---${RESET}"
        echo "25) Ejercicio 25: Versión del kernel"
        echo "26) Ejercicio 26: Análisis de procesos en ejecución"
        echo "27) Ejercicio 27: Añadir disco, particionar y montar"
        echo "28) Ejercicio 28: Herramientas de observación del sistema"
        echo "0) Volver al menú principal"
        echo -n "Selecciona un ejercicio: "
        read -r opc

        case $opc in
            25)
                mostrar_practica \
                    "Muestra la versión del kernel instalada en tu sistema Linux." \
                    "uname -r" \
                    "uname (-system name) con -r muestra solo la versión del kernel (release)." \
                    "uname -r && echo '--- Detalle ampliado ---' && uname -a"
                pausa ;;
            26)
                mostrar_practica \
                    "Muestra los procesos activos y localiza el PID de un proceso concreto llamado sleep." \
                    "sleep 300 &\nps aux | grep sleep\npgrep sleep" \
                    "sleep en segundo plano crea un proceso identificable; ps lista procesos; grep filtra por nombre; pgrep devuelve el PID directamente." \
                    "sleep 300 & PID_S=\$!; echo \"PID del sleep lanzado: \$PID_S\"; echo '--- ps aux (filtrado) ---'; ps aux | grep '[s]leep'; echo '--- pgrep ---'; pgrep -a sleep"
                pausa ;;
            27)
                mostrar_practica \
                    "Añade un disco virtual nuevo de 20 GB, crea una partición, formateala en ext4 y móntala en /mnt/datos." \
                    "lsblk                                    # detectar discos\nsudo fdisk /dev/sdX                      # crear partición (manual)\nsudo mkfs.ext4 /dev/sdX1                 # formatear ext4\nsudo mkdir -p /mnt/datos\nsudo mount /dev/sdX1 /mnt/datos\ndf -h /mnt/datos" \
                    "1) lsblk lista discos y particiones; identifica el disco nuevo (p. ej. sdb, no el del sistema).\n\n2) Al ejecutar en vivo, el script muestra los discos y tú eliges cuál usar.\n\n3) Si el disco está vacío, se crea una partición con parted; si ya tiene particiones, puedes reutilizar la primera o crear una nueva.\n\n4) mkfs.ext4 crea el sistema de archivos; mount enlaza la partición a /mnt/datos; df -h comprueba el espacio montado.\n\nEn la VM: añade el disco de 20 GB en el hipervisor antes de ejecutar el ejercicio." \
                    "ejercicio_27_seleccionar_disco"
                pausa ;;
            28)
                mostrar_practica \
                    "Indica qué utilidad usarías en Linux para observar CPU, memoria, disco y espacio disponible." \
                    "CPU y procesos: top, htop, ps\nMemoria: free, vmstat\nDisco y E/S: iostat, lsblk\nEspacio disponible: df -h" \
                    "top/htop monitorizan CPU en tiempo real; free muestra RAM y swap; lsblk lista bloques; df espacio en sistemas de archivos montados; iostat requiere paquete sysstat." \
                    "echo '--- CPU (cabecera top) ---'; top -bn1 | head -n 8; echo; echo '--- Memoria (free) ---'; free -h; echo; echo '--- Discos (lsblk) ---'; lsblk; echo; echo '--- Espacio (df) ---'; df -h"
                pausa ;;
            0) break ;;
            *) echo "Opción no válida"; pausa ;;
        esac
    done
}

bloque6() {
    while true; do
        cabecera
        echo -e "${CYAN}--- BLOQUE 6: CASOS INTEGRADORES ---${RESET}"
        echo "29) Ejercicio 29: Caso práctico de montaje de equipo"
        echo "30) Ejercicio 30: Caso global de administración inicial"
        echo "0) Volver al menú principal"
        echo -n "Selecciona un ejercicio: "
        read -r opc

        case $opc in
            29)
                mostrar_teoria \
                    "Describe el proceso completo de ensamblado básico de un computador de aula orientado a bases de datos: CPU, RAM, disco, alimentación y verificación inicial." \
                    "1. Preparar mesa antiestática, revisar manual de placa y chasis.\n2. Montar la placa en el chasis (separadores, I/O shield).\n3. Instalar CPU en el zócalo y aplicar pasta térmica; colocar disipador.\n4. Insertar RAM en bancos indicados (dual channel si aplica).\n5. Instalar SSD/HDD (NVMe en M.2 o SATA) y conectar datos/alimentación.\n6. Conectar fuente ATX (24 pines placa + 4/8 pines CPU) y ventiladores.\n7. Cableado frontal (power, reset, USB, audio).\n8. Verificación POST en BIOS/UEFI: detectar CPU, RAM, disco; configurar arranque y guardar."
                pausa ;;
            30)
                mostrar_practica \
                    "Realiza estas tareas: crear usuario, crear carpeta de trabajo, comprobar kernel, crear un fichero con permisos 764 y montar un segundo disco ext4." \
                    "sudo useradd -m -g gestion alumno_uf\nmkdir -p ~/trabajo_uf\ntouch ~/trabajo_uf/nota.txt && chmod 764 ~/trabajo_uf/nota.txt\nuname -r\n# Disco: fdisk + mkfs.ext4 + mount /dev/sdX1 /mnt/datos" \
                    "Integra administración de usuarios, sistema de archivos, permisos, kernel y almacenamiento. El montaje del segundo disco requiere hardware o disco virtual añadido en la VM (ver ejercicio 27)." \
                    "echo '=== 1. Kernel ==='; uname -r; echo; echo '=== 2. Carpeta y fichero con permisos 764 ==='; mkdir -p \"\$HOME/trabajo_uf\" && touch \"\$HOME/trabajo_uf/nota.txt\" && chmod 764 \"\$HOME/trabajo_uf/nota.txt\" && ls -ld \"\$HOME/trabajo_uf\" && ls -l \"\$HOME/trabajo_uf/nota.txt\"; echo; echo '=== 3. Usuario (requiere root; se omite si no hay permisos) ==='; if sudo -n true 2>/dev/null; then sudo groupadd -f gestion 2>/dev/null; id alumno_uf &>/dev/null || sudo useradd -m -g gestion alumno_uf; id alumno_uf; else echo 'Ejecuta: sudo useradd -m -g gestion alumno_uf'; fi; echo; echo '=== 4. Segundo disco ext4 ==='; lsblk; echo 'Montaje: ver ejercicio 27 (fdisk, mkfs.ext4, mount /mnt/datos).'"
                pausa ;;
            0) break ;;
            *) echo "Opción no válida"; pausa ;;
        esac
    done
}

# --- MENÚ PRINCIPAL ---
while true; do
    cabecera
    echo -e "${AMARILLO}Selecciona el Bloque Temático que deseas revisar:${RESET}"
    echo "1) Bloque 1: Arquitectura del computador (Ej. 1-8)"
    echo "2) Bloque 2: Sistemas operativos y memoria (Ej. 9-14)"
    echo "3) Bloque 3: Sistemas de archivos (Ej. 15-19)"
    echo "4) Bloque 4: Multiusuario, multiproceso y virtualización (Ej. 20-24)"
    echo "5) Bloque 5: Rendimiento y ajuste del sistema (Ej. 25-28)"
    echo "6) Bloque 6: Casos integradores (Ej. 29-30)"
    echo "0) Salir del programa"
    echo -n "Opción: "
    read -r opcion_principal

    case $opcion_principal in
        1) bloque1 ;;
        2) bloque2 ;;
        3) bloque3 ;;
        4) bloque4 ;;
        5) bloque5 ;;
        6) bloque6 ;;
        0)
            if [[ -n "${CHULETARIO:-}" ]]; then
                echo -e "\n${VERDE}Volviendo a Chuletario...${RESET}"
            else
                echo -e "\n${VERDE}Saliendo de practicANDO. ¡Buen trabajo!${RESET}"
            fi
            exit 0
            ;;
        *)
            echo "Opción incorrecta."
            pausa
            ;;
    esac
done
