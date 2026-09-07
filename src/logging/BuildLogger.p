/*------------------------------------------------------------------------
    File        : src/logging/BuildLogger.p
    Purpose     : Punto de entrada procedural y persistente para BuildLogger
    Author      : Refactorización Compilador OE 12.8
  ----------------------------------------------------------------------*/

{src/logging/BuildLogger.i}

/* Si se ejecuta de forma no persistente sin parametros, mostrar ayuda */
IF NOT THIS-PROCEDURE:PERSISTENT THEN DO:
    MESSAGE "BuildLogger: Registrador estructurado de compilacion para OpenEdge 12.8." SKIP
            "Gestiona reportes detallados y comunicacion con la interfaz grafica."
        VIEW-AS ALERT-BOX INFORMATION.
END.
