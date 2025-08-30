#!/bin/bash
# ThreatSim Lightweight v4.0
# Simulador avanzado de verificación de amenazas con simulaciones Red Team
# Basado en OWASP + ISO 27002 + NIST 800 + MITRE ATT&CK
# Incluye fases del SDLC y planes de remediación

REPORT_DIR="threatsim_reports"
REPORT="$REPORT_DIR/threatsim_report_$(date +%Y%m%d_%H%M%S).txt"
SCORE_FILE="$REPORT_DIR/security_score_$(date +%Y%m%d_%H%M%S).json"
REDTEAM_FILE="$REPORT_DIR/redteam_simulations_$(date +%Y%m%d_%H%M%S).txt"
REMEDIATION_FILE="$REPORT_DIR/remediation_plan_$(date +%Y%m%d_%H%M%S).txt"
mkdir -p $REPORT_DIR

# Colores
green="\e[32m"
red="\e[31m"
yellow="\e[33m"
blue="\e[34m"
magenta="\e[35m"
cyan="\e[36m"
end="\e[0m"
bold="\e[1m"

# Puntuación inicial
declare -A phase_scores
declare -A phase_max_scores
declare -A phase_items
total_score=0
max_total_score=0

# Inicializar puntuaciones
init_scores() {
    phase_scores["Requirements"]=0
    phase_scores["Design"]=0
    phase_scores["Implementation"]=0
    phase_scores["Testing"]=0
    phase_scores["Deployment"]=0
    phase_scores["Maintenance"]=0
    
    phase_max_scores["Requirements"]=0
    phase_max_scores["Design"]=0
    phase_max_scores["Implementation"]=0
    phase_max_scores["Testing"]=0
    phase_max_scores["Deployment"]=0
    phase_max_scores["Maintenance"]=0
}

# Cabecera mejorada
print_header() {
    clear
    echo -e "${blue}╔══════════════════════════════════════════════════════════════╗${end}"
    echo -e "${blue}║${bold}               ThreatSim Lightweight v4.0                 ${end}${blue}║"
    echo -e "${blue}║${bold}  Evaluación de Seguridad SDLC + Red Team + Remediation   ${end}${blue}║"
    echo -e "${blue}╚══════════════════════════════════════════════════════════════╝${end}"
    echo
}

# Pie de página
print_footer() {
    echo -e "${blue}╔══════════════════════════════════════════════════════════════╗${end}"
    echo -e "${blue}║${cyan}  Reporte guardado en: $REPORT                           ${end}${blue}║"
    echo -e "${blue}║${cyan}  Simulaciones Red Team: $REDTEAM_FILE                   ${end}${blue}║"
    echo -e "${blue}║${cyan}  Plan de remediación: $REMEDIATION_FILE                 ${end}${blue}║"
    echo -e "${blue}╚══════════════════════════════════════════════════════════════╝${end}"
    echo
}

# Función para mostrar progreso
show_progress() {
    phase=$1
    current=$2
    total=$3
    width=50
    percentage=$(echo "scale=2; $current * 100 / $total" | bc)
    filled=$(echo "scale=0; $width * $current / $total" | bc)
    empty=$((width - filled))
    
    printf "${yellow}%s: [${green}" "$phase"
    for i in $(seq 1 $filled); do
        printf "█"
    done
    printf "${yellow}"
    for i in $(seq 1 $empty); do
        printf "░"
    done
    printf "] ${cyan}%.2f%%${end}\n" "$percentage"
}

# Checklist mejorado con puntuación
checklist() {
    phase=$1
    shift
    items=("$@")
    
    echo -e "\n${yellow}${bold}--- Fase de $phase ---${end}" | tee -a $REPORT
    echo -e "${cyan}Seleccione el nivel de implementación para cada item:${end}"
    echo -e "${magenta}0 = No implementado, 1 = Parcial, 2 = Implementado, 3 = Optimizado${end}"
    echo
    
    # Inicializar items de la fase
    phase_items["$phase"]=${#items[@]}
    phase_max_scores["$phase"]=$(( ${#items[@]} * 3 ))
    
    for i in "${!items[@]}"; do
        echo -e "${blue}[$((i+1))] ${items[$i]}${end}"
        echo -n "Nivel de implementación (0-3): "
        read score
        
        # Validar entrada
        while [[ ! $score =~ ^[0-3]$ ]]; do
            echo -e "${red}Error: Ingrese un valor entre 0 y 3${end}"
            echo -n "Nivel de implementación (0-3): "
            read score
        done
        
        # Guardar puntuación
        phase_scores["$phase"]=$(( ${phase_scores["$phase"]} + score ))
        
        # Guardar en reporte
        case $score in
            0) status="${red}[NO IMPLEMENTADO]${end}" ;;
            1) status="${yellow}[PARCIAL]${end}" ;;
            2) status="${green}[IMPLEMENTADO]${end}" ;;
            3) status="${cyan}[OPTIMIZADO]${end}" ;;
        esac
        
        echo -e "$status ${items[$i]}" | tee -a $REPORT
        
        # Opción para agregar comentarios
        echo -n "¿Agregar comentario? (s/n): "
        read add_comment
        if [[ $add_comment == "s" || $add_comment == "S" ]]; then
            echo -n "Comentario: "
            read comment
            echo -e "  Comentario: $comment" | tee -a $REPORT
        fi
        
        echo | tee -a $REPORT
        show_progress "$phase" "$((i+1))" "${#items[@]}"
    done
    
    # Mostrar resumen de la fase
    phase_score=${phase_scores["$phase"]}
    phase_max=${phase_max_scores["$phase"]}
    phase_percentage=$(echo "scale=2; $phase_score * 100 / $phase_max" | bc)
    
    echo -e "${yellow}${bold}Resumen de $phase:${end}" | tee -a $REPORT
    echo -e "  Puntuación: $phase_score/$phase_max ($phase_percentage%)" | tee -a $REPORT
    
    if (( $(echo "$phase_percentage >= 80" | bc -l) )); then
        echo -e "  Estado: ${green}EXCELENTE${end}" | tee -a $REPORT
    elif (( $(echo "$phase_percentage >= 60" | bc -l) )); then
        echo -e "  Estado: ${cyan}BUENO${end}" | tee -a $REPORT
    elif (( $(echo "$phase_percentage >= 40" | bc -l) )); then
        echo -e "  Estado: ${yellow}REGULAR${end}" | tee -a $REPORT
    else
        echo -e "  Estado: ${red}DEFICIENTE${end}" | tee -a $REPORT
    fi
    
    echo -e "\n═══════════════════════════════════════════════════════════════" | tee -a $REPORT
}

# Generar reporte de puntuación en JSON
generate_score_report() {
    echo "{" > $SCORE_FILE
    echo "  \"assessment_date\": \"$(date)\"," >> $SCORE_FILE
    echo "  \"phases\": {" >> $SCORE_FILE
    
    for phase in "Requirements" "Design" "Implementation" "Testing" "Deployment" "Maintenance"; do
        phase_score=${phase_scores["$phase"]}
        phase_max=${phase_max_scores["$phase"]}
        phase_percentage=$(echo "scale=2; $phase_score * 100 / $phase_max" | bc)
        
        echo "    \"$phase\": {" >> $SCORE_FILE
        echo "      \"score\": $phase_score," >> $SCORE_FILE
        echo "      \"max_score\": $phase_max," >> $SCORE_FILE
        echo "      \"percentage\": $phase_percentage" >> $SCORE_FILE
        if [ "$phase" != "Maintenance" ]; then
            echo "    }," >> $SCORE_FILE
        else
            echo "    }" >> $SCORE_FILE
        fi
    done
    
    echo "  }," >> $SCORE_FILE
    echo "  \"total_score\": $total_score," >> $SCORE_FILE
    echo "  \"max_total_score\": $max_total_score," >> $SCORE_FILE
    total_percentage=$(echo "scale=2; $total_score * 100 / $max_total_score" | bc)
    echo "  \"total_percentage\": $total_percentage" >> $SCORE_FILE
    echo "}" >> $SCORE_FILE
}

# Mostrar resumen final
show_final_summary() {
    echo -e "\n${yellow}${bold}════════════════ RESUMEN FINAL ════════════════${end}" | tee -a $REPORT
    
    total_score=0
    max_total_score=0
    
    for phase in "Requirements" "Design" "Implementation" "Testing" "Deployment" "Maintenance"; do
        phase_score=${phase_scores["$phase"]}
        phase_max=${phase_max_scores["$phase"]}
        total_score=$((total_score + phase_score))
        max_total_score=$((max_total_score + phase_max))
        phase_percentage=$(echo "scale=2; $phase_score * 100 / $phase_max" | bc)
        
        echo -e "${blue}$phase:${end} $phase_score/$phase_max (${cyan}$phase_percentage%${end})" | tee -a $REPORT
    done
    
    total_percentage=$(echo "scale=2; $total_score * 100 / $max_total_score" | bc)
    
    echo -e "${yellow}${bold}Puntuación total:${end} $total_score/$max_total_score (${cyan}$total_percentage%${end})" | tee -a $REPORT
    
    if (( $(echo "$total_percentage >= 80" | bc -l) )); then
        echo -e "${green}${bold}¡Excelente! La madurez de seguridad es alta.${end}" | tee -a $REPORT
    elif (( $(echo "$total_percentage >= 60" | bc -l) )); then
        echo -e "${cyan}${bold}Buena postura de seguridad, pero hay áreas de mejora.${end}" | tee -a $REPORT
    elif (( $(echo "$total_percentage >= 40" | bc -l) )); then
        echo -e "${yellow}${bold}Seguridad básica implementada, necesita mejoras significativas.${end}" | tee -a $REPORT
    else
        echo -e "${red}${bold}Advertencia: La postura de seguridad es deficiente.${end}" | tee -a $REPORT
    fi
    
    echo -e "\n${yellow}Reporte de puntuación guardado en: $SCORE_FILE${end}" | tee -a $REPORT
}

# Recomendaciones basadas en los resultados
generate_recommendations() {
    echo -e "\n${yellow}${bold}══════════ RECOMENDACIONES PRIORITARIAS ══════════${end}" | tee -a $REPORT
    
    for phase in "Requirements" "Design" "Implementation" "Testing" "Deployment" "Maintenance"; do
        phase_score=${phase_scores["$phase"]}
        phase_max=${phase_max_scores["$phase"]}
        phase_percentage=$(echo "scale=2; $phase_score * 100 / $phase_max" | bc)
        
        if (( $(echo "$phase_percentage < 60" | bc -l) )); then
            echo -e "${red}${bold}● $phase:${end}" | tee -a $REPORT
            
            case $phase in
                "Requirements")
                    echo -e "  - Establecer requisitos de seguridad formales" | tee -a $REPORT
                    echo -e "  - Implementar clasificación de datos" | tee -a $REPORT
                    echo -e "  - Realizar análisis de privacidad por diseño" | tee -a $REPORT
                    ;;
                "Design")
                    echo -e "  - Realizar modelado de amenazas formal" | tee -a $REPORT
                    echo -e "  - Implementar arquitectura de seguridad documentada" | tee -a $REPORT
                    echo -e "  - Establecer controles criptográficos" | tee -a $REPORT
                    ;;
                "Implementation")
                    echo -e "  - Implementar revisión de código seguro" | tee -a $REPORT
                    echo -e "  - Establecer control de dependencias" | tee -a $REPORT
                    echo -e "  - Realizar pruebas de seguridad estáticas (SAST)" | tee -a $REPORT
                    ;;
                "Testing")
                    echo -e "  - Implementar pruebas de seguridad dinámicas (DAST)" | tee -a $REPORT
                    echo -e "  - Realizar pruebas de penetración regulares" | tee -a $REPORT
                    echo -e "  - Validar controles de acceso y autenticación" | tee -a $REPORT
                    ;;
                "Deployment")
                    echo -e "  - Implementar hardening de sistemas" | tee -a $REPORT
                    echo -e "  - Establecer configuración segura de red" | tee -a $REPORT
                    echo -e "  - Configurar monitoreo de seguridad (SIEM)" | tee -a $REPORT
                    ;;
                "Maintenance")
                    echo -e "  - Establecer programa de parcheo regular" | tee -a $REPORT
                    echo -e "  - Implementar monitoreo continuo de seguridad" | tee -a $REPORT
                    echo -e "  - Realizar pruebas de recuperación ante desastres" | tee -a $REPORT
                    ;;
            esac
            echo | tee -a $REPORT
        fi
    done
}

# Generar simulaciones de Red Team basadas en los hallazgos
generate_redteam_simulations() {
    echo -e "${yellow}${bold}══════════ SIMULACIONES RED TEAM RECOMENDADAS ══════════${end}" | tee -a $REDTEAM_FILE
    
    echo -e "${blue}Basado en los hallazgos, se recomiendan las siguientes simulaciones:${end}" | tee -a $REDTEAM_FILE
    echo | tee -a $REDTEAM_FILE
    
    # Simulaciones genéricas para todas las fases
    echo -e "${magenta}${bold}Simulaciones Genéricas:${end}" | tee -a $REDTEAM_FILE
    echo -e "1. ${bold}Phishing Campaign:${end} Simular ataques de phishing para evaluar concienciación" | tee -a $REDTEAM_FILE
    echo -e "   - Técnicas MITRE: T1566 (Phishing)" | tee -a $REDTEAM_FILE
    echo -e "   - Objetivo: Evaluar susceptibilidad a ingeniería social" | tee -a $REDTEAM_FILE
    echo | tee -a $REDTEAM_FILE
    
    echo -e "2. ${bold}Privilege Escalation:${end} Intentar escalar privilegios desde cuenta estándar" | tee -a $REDTEAM_FILE
    echo -e "   - Técnicas MITRE: T1068 (Exploitation for Privilege Escalation)" | tee -a $REDTEAM_FILE
    echo -e "   - Objetivo: Evaluar controles de separación de privilegios" | tee -a $REDTEAM_FILE
    echo | tee -a $REDTEAM_FILE
    
    echo -e "3. ${bold}Lateral Movement:${end} Intentar moverse lateralmente en la red" | tee -a $REDTEAM_FILE
    echo -e "   - Técnicas MITRE: T1021 (Remote Services), T1077 (Windows Admin Shares)" | tee -a $REDTEAM_FILE
    echo -e "   - Objetivo: Evaluar segmentación de red y controles de acceso" | tee -a $REDTEAM_FILE
    echo | tee -a $REDTEAM_FILE
    
    # Simulaciones específicas por fase con baja puntuación
    for phase in "Requirements" "Design" "Implementation" "Testing" "Deployment" "Maintenance"; do
        phase_score=${phase_scores["$phase"]}
        phase_max=${phase_max_scores["$phase"]}
        phase_percentage=$(echo "scale=2; $phase_score * 100 / $phase_max" | bc)
        
        if (( $(echo "$phase_percentage < 60" | bc -l) )); then
            echo -e "${red}${bold}Simulaciones para deficiencias en $phase:${end}" | tee -a $REDTEAM_FILE
            
            case $phase in
                "Requirements")
                    echo -e "4. ${bold}Data Exfiltration Test:${end} Intentar extraer datos sensibles" | tee -a $REDTEAM_FILE
                    echo -e "   - Técnicas MITRE: T1041 (Exfiltration Over C2 Channel)" | tee -a $REDTEAM_FILE
                    echo -e "   - Objetivo: Evaluar controles de prevención de pérdida de datos" | tee -a $REDTEAM_FILE
                    echo | tee -a $REDTEAM_FILE
                    ;;
                "Design")
                    echo -e "5. ${bold}Architecture Bypass:${end} Intentar bypassear controles de seguridad" | tee -a $REDTEAM_FILE
                    echo -e "   - Técnicas MITRE: T1060 (Registry Run Keys / Startup Folder)" | tee -a $REDTEAM_FILE
                    echo -e "   - Objetivo: Evaluar efectividad de defensas en profundidad" | tee -a $REDTEAM_FILE
                    echo | tee -a $REDTEAM_FILE
                    ;;
                "Implementation")
                    echo -e "6. ${bold}Injection Attacks:${end} Probar vulnerabilidades de inyección" | tee -a $REDTEAM_FILE
                    echo -e "   - Técnicas MITRE: T1059 (Command and Scripting Interpreter)" | tee -a $REDTEAM_FILE
                    echo -e "   - Objetivo: Evaluar validación de entrada y sanitización" | tee -a $REDTEAM_FILE
                    echo | tee -a $REDTEAM_FILE
                    ;;
                "Testing")
                    echo -e "7. ${bold}Zero-Day Simulation:${end} Simular explotación de vulnerabilidad no parcheada" | tee -a $REDTEAM_FILE
                    echo -e "   - Técnicas MITRE: T1190 (Exploit Public-Facing Application)" | tee -a $REDTEAM_FILE
                    echo -e "   - Objetivo: Evaluar capacidades de detección y respuesta" | tee -a $REDTEAM_FILE
                    echo | tee -a $REDTEAM_FILE
                    ;;
                "Deployment")
                    echo -e "8. ${bold}Configuration Exploitation:${end} Explotar configuraciones inseguras" | tee -a $REDTEAM_FILE
                    echo -e "   - Técnicas MITRE: T1082 (System Information Discovery)" | tee -a $REDTEAM_FILE
                    echo -e "   - Objetivo: Evaluar hardening de sistemas y aplicaciones" | tee -a $REDTEAM_FILE
                    echo | tee -a $REDTEAM_FILE
                    ;;
                "Maintenance")
                    echo -e "9. ${bold}Persistence Establishment:${end} Intentar establecer persistencia" | tee -a $REDTEAM_FILE
                    echo -e "   - Técnicas MITRE: T1136 (Create Account), T1053 (Scheduled Task)" | tee -a $REDTEAM_FILE
                    echo -e "   - Objetivo: Evaluar detección de actividades persistentes" | tee -a $REDTEAM_FILE
                    echo | tee -a $REDTEAM_FILE
                    ;;
            esac
        fi
    done
    
    echo -e "${cyan}Nota: Todas las simulaciones deben realizarse en entornos controlados${end}" | tee -a $REDTEAM_FILE
    echo -e "${cyan}con autorización explícita por escrito y límites claramente definidos.${end}" | tee -a $REDTEAM_FILE
}

# Generar plan de remediación para hallazgos comunes
generate_remediation_plan() {
    echo -e "${yellow}${bold}══════════ PLAN DE REMEDIACIÓN PARA HALLazGOS COMUNES ══════════${end}" | tee -a $REMEDIATION_FILE
    
    echo -e "${blue}Plan de acción recomendado para problemas de seguridad comunes:${end}" | tee -a $REMEDIATION_FILE
    echo | tee -a $REMEDIATION_FILE
    
    echo -e "${magenta}${bold}1. Problema: Falta de controles de acceso adecuados${end}" | tee -a $REMEDIATION_FILE
    echo -e "   ${bold}Remediación:${end}" | tee -a $REMEDIATION_FILE
    echo -e "   - Implementar principio de mínimo privilegio" | tee -a $REMEDIATION_FILE
    echo -e "   - Revisar y ajustar permisos regularmente" | tee -a $REMEDIATION_FILE
    echo -e "   - Implementar autenticación multifactor (MFA)" | tee -a $REMEDIATION_FILE
    echo -e "   - Establecer controles de acceso basados en roles (RBAC)" | tee -a $REMEDIATION_FILE
    echo | tee -a $REMEDIATION_FILE
    
    echo -e "${magenta}${bold}2. Problema: Configuraciones inseguras${end}" | tee -a $REMEDIATION_FILE
    echo -e "   ${bold}Remediación:${end}" | tee -a $REMEDIATION_FILE
    echo -e "   - Establecer estándares de hardening para sistemas y aplicaciones" | tee -a $REMEDIATION_FILE
    echo -e "   - Implementar revisión automatizada de configuraciones" | tee -a $REMEDIATION_FILE
    echo -e "   - Utilizar benchmarks de seguridad (CIS, NIST)" | tee -a $REMEDIATION_FILE
    echo -e "   - Automatizar despliegues con configuraciones seguras por defecto" | tee -a $REMEDIATION_FILE
    echo | tee -a $REMEDIATION_FILE
    
    echo -e "${magenta}${bold}3. Problema: Falta de monitoreo y logging${end}" | tee -a $REMEDIATION_FILE
    echo -e "   ${bold}Remediación:${end}" | tee -a $REMEDIATION_FILE
    echo -e "   - Implementar SIEM para correlación de eventos" | tee -a $REMEDIATION_FILE
    echo -e "   - Establecer alertas para actividades sospechosas" | tee -a $REMEDIATION_FILE
    echo -e "   - Asegurar retención adecuada de logs" | tee -a $REMEDIATION_FILE
    echo -e "   - Realizar revisiones periódicas de logs" | tee -a $REMEDIATION_FILE
    echo | tee -a $REMEDIATION_FILE
    
    echo -e "${magenta}${bold}4. Problema: Gestión deficiente de parches${end}" | tee -a $REMEDIATION_FILE
    echo -e "   ${bold}Remediación:${end}" | tee -a $REMEDIATION_FILE
    echo -e "   - Establecer programa formal de gestión de vulnerabilidades" | tee -a $REMEDIATION_FILE
    echo -e "   - Priorizar parches basados en criticidad" | tee -a $REMEDIATION_FILE
    echo -e "   - Automatizar despliegue de parches cuando sea posible" | tee -a $REMEDIATION_FILE
    echo -e "   - Realizar pruebas de compatibilidad antes de implementar" | tee -a $REMEDIATION_FILE
    echo | tee -a $REMEDIATION_FILE
    
    echo -e "${magenta}${bold}5. Problema: Falta de cifrado adecuado${end}" | tee -a $REMEDIATION_FILE
    echo -e "   ${bold}Remediación:${end}" | tee -a $REMEDIATION_FILE
    echo -e "   - Implementar cifrado para datos en tránsito (TLS 1.2+)" | tee -a $REMEDIATION_FILE
    echo -e "   - Implementar cifrado para datos en reposo" | tee -a $REMEDIATION_FILE
    echo -e "   - Gestionar adecuadamente las claves criptográficas" | tee -a $REMEDIATION_FILE
    echo -e "   - Establecer políticas de rotación de claves" | tee -a $REMEDIATION_FILE
    echo | tee -a $REMEDIATION_FILE
    
    echo -e "${magenta}${bold}6. Problema: Deficiencias en respuesta a incidentes${end}" | tee -a $REMEDIATION_FILE
    echo -e "   ${bold}Remediación:${end}" | tee -a $REMEDIATION_FILE
    echo -e "   - Desarrollar y mantener plan de respuesta a incidentes" | tee -a $REMEDIATION_FILE
    echo -e "   - Realizar simulacros de incidentes regularmente" | tee -a $REMEDIATION_FILE
    echo -e "   - Establecer procedimientos de comunicación durante incidentes" | tee -a $REMEDIATION_FILE
    echo -e "   - Designar equipo de respuesta con roles claros" | tee -a $REMEDIATION_FILE
    echo | tee -a $REMEDIATION_FILE
    
    echo -e "${cyan}Cronograma recomendado:${end}" | tee -a $REMEDIATION_FILE
    echo -e " - ${bold}Crítico:${end} Remediar en 72 horas" | tee -a $REMEDIATION_FILE
    echo -e " - ${bold}Alto:${end} Remediar en 1 semana" | tee -a $REMEDIATION_FILE
    echo -e " - ${bold}Medio:${end} Remediar en 1 mes" | tee -a $REMEDIATION_FILE
    echo -e " - ${bold}Bajo:${end} Remediar en 3 meses" | tee -a $REMEDIATION_FILE
}

# Menú principal mejorado
sdlc_menu() {
    init_scores
    
    while true; do
        print_header
        echo -e "${bold}Seleccione la fase del SDLC a revisar:${end}"
        echo -e "1) ${blue}Requirements${end}       (Definición de requisitos de seguridad)"
        echo -e "2) ${blue}Design${end}             (Diseño seguro y modelado de amenazas)"
        echo -e "3) ${blue}Implementation${end}     (Implementación de controles seguros)"
        echo -e "4) ${blue}Testing${end}            (Pruebas de seguridad y validación)"
        echo -e "5) ${blue}Deployment${end}         (Despliegue seguro y configuración)"
        echo -e "6) ${blue}Maintenance${end}        (Mantenimiento y operaciones de seguridad)"
        echo -e "7) ${cyan}Ver Reporte Final${end}        (Resumen y recomendaciones)"
        echo -e "8) ${green}Generar Reporte JSON${end}     (Resultados en formato estructurado)"
        echo -e "9) ${magenta}Generar Simulaciones Red Team${end} (Pruebas de seguridad ofensivas)"
        echo -e "10) ${yellow}Generar Plan de Remedio${end}     (Acciones correctivas)"
        echo -e "0) ${red}Salir${end}                    (Terminar la evaluación)"
        echo -n -e "${bold}> ${end}"
        read opt

        case $opt in
            1)
                checklist "Requirements" \
                    "Requerimientos de seguridad documentados (ISO 27002 A.14.1)" \
                    "Controles de acceso definidos (NIST AC-1, AC-2)" \
                    "Revisión de amenazas iniciales (OWASP Threat Modeling)" \
                    "Clasificación de datos y privacidad (ISO 27002 A.8)" \
                    "Identificación de regulaciones aplicables (GDPR, HIPAA, etc.)" \
                    "Requisitos de autenticación y autorización (OWASP A7)" \
                    "Requisitos de encriptación de datos (NIST SC-13)" \
                    "Requisitos de gestión de sesiones (OWASP A2)" \
                    "Requisitos de logging y auditoría (ISO 27002 A.12.4)" \
                    "Requisitos de recuperación ante desastres (ISO 27002 A.17)"
                ;;
            2)
                checklist "Design" \
                    "Modelo de amenazas realizado (OWASP top 10)" \
                    "Arquitectura de seguridad documentada (NIST SA-3)" \
                    "Validación de controles criptográficos (ISO 27002 A.10)" \
                    "Definición de logging/auditoría (ISO 27002 A.12.4)" \
                    "Diseño de pruebas de seguridad" \
                    "Patrones de diseño seguro aplicados (OWASP Secure Design)" \
                    "Arquitectura de defensa en profundidad" \
                    "Segmentación de red y controles de acceso" \
                    "Diseño de recuperación ante fallos" \
                    "Plan de respuesta a incidentes (ISO 27002 A.16)"
                ;;
            3)
                checklist "Implementation" \
                    "Validación de código seguro (OWASP ASVS)" \
                    "Uso de repositorios confiables (NIST SI-7)" \
                    "Control de cambios en código (ISO 27002 A.12.1)" \
                    "Hardening de librerías y dependencias" \
                    "Protección contra inyecciones (OWASP Top 10 A03)" \
                    "Validación de entrada de datos (OWASP A1)" \
                    "Manejo seguro de errores và excepciones" \
                    "Control de acceso basado en roles (OWASP A5)" \
                    "Protección de datos en reposo y tránsito" \
                    "Configuración segura por defecto (OWASP A6)"
                ;;
            4)
                checklist "Testing" \
                    "Revisión de código estática (SAST)" \
                    "Pruebas dinámicas de seguridad (DAST)" \
                    "Pentesting interno (NIST CA-8)" \
                    "Validación de roles y permisos (ISO 27002 A.9)" \
                    "Testing contra OWASP Top 10" \
                    "Pruebas de configuración de seguridad" \
                    "Pruebas de inyección (SQLi, XSS, etc.)" \
                    "Pruebas de autenticación y autorización" \
                    "Pruebas de gestión de sesiones" \
                    "Pruebas de encriptación"
                ;;
            5)
                checklist "Deployment" \
                    "Hardening del sistema operativo (NIST CM-6)" \
                    "Seguridad en la red (ISO 27002 A.13)" \
                    "Configuración de logs centralizados (SIEM)" \
                    "Control de acceso a producción (ISO 27002 A.9.2)" \
                    "Prueba de rollback de emergencia" \
                    "Configuración segura de servicios y puertos" \
                    "Protección de archivos de configuración" \
                    "Configuración de firewall y WAF" \
                    "Implementación de IDS/IPS" \
                    "Configuración de backup y recuperación"
                ;;
            6)
                checklist "Maintenance" \
                    "Gestión de parches (NIST SI-2)" \
                    "Monitoreo continuo de incidentes (ISO 27002 A.16)" \
                    "Pruebas de recuperación (BCP/DRP)" \
                    "Revisión periódica de roles y accesos" \
                    "Evaluación de nuevas amenazas (threat intel)" \
                    "Auditorías de seguridad periódicas" \
                    "Revisión de registros y detección de anomalías" \
                    "Actualización de controles de seguridad" \
                    "Respuesta a incidentes de seguridad" \
                    "Evaluación continua de vulnerabilidades"
                ;;
            7)
                show_final_summary
                generate_recommendations
                print_footer
                read -p "Presione Enter para continuar..."
                ;;
            8)
                generate_score_report
                echo -e "${green}Reporte JSON generado en: $SCORE_FILE${end}"
                read -p "Presione Enter para continuar..."
                ;;
            9)
                generate_redteam_simulations
                echo -e "${green}Simulaciones Red Team generadas en: $REDTEAM_FILE${end}"
                read -p "Presione Enter para continuar..."
                ;;
            10)
                generate_remediation_plan
                echo -e "${green}Plan de remediación generado en: $REMEDIATION_FILE${end}"
                read -p "Presione Enter para continuar..."
                ;;
            0)
                echo -e "${green}Saliendo... Reporte final guardado en: $REPORT${end}"
                exit 0
                ;;
            *)
                echo -e "${red}Opción inválida${end}"
                sleep 1
                ;;
        esac
    done
}

# Iniciar aplicación
echo -e "${blue}Iniciando ThreatSim Lightweight v4.0${end}"
sleep 2
sdlc_menu
