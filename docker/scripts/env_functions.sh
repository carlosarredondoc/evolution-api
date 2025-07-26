export_env_vars() {
    if [ -f .env ]; then
        while IFS='=' read -r key value; do
            # Ignora comentarios y líneas vacías
            if [[ -z "$key" || "$key" =~ ^\s*# ]]; then
                continue
            fi

            # Limpia la clave de espacios
            key=$(echo "$key" | tr -d '[:space:]')
            
            # Revisa si la variable ya existe en el entorno y tiene un valor
            if [ -z "${!key}" ]; then
                # Si no existe, la procesa y la exporta
                value=$(echo "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e "s/^'//" -e "s/'$//" -e 's/^"//' -e 's/"$//')
                export "$key=$value"
            fi
        done < .env
    fi
}
