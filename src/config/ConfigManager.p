/*------------------------------------------------------------------------
    File        : src/config/ConfigManager.p
    Purpose     : Punto de entrada procedural / persistente para ConfigManager
    Author      : Refactorización Compilador OE 12.8
  ----------------------------------------------------------------------*/

{src/config/ConfigManager.i}

/* Si se ejecuta de forma no persistente sin parametros, mostrar ayuda */
IF NOT THIS-PROCEDURE:PERSISTENT THEN DO:
    MESSAGE "ConfigManager: Gestor de configuracion y catalogo para OpenEdge 12.8." SKIP
            "Sustituye BuscaSistema y Sinc-Estructura con soporte de respaldo automatico."
        VIEW-AS ALERT-BOX INFORMATION.
END.
