/*------------------------------------------------------------------------
    File        : src/core/PropathManager.p
    Purpose     : Punto de entrada procedural y persistente para PropathManager
    Author      : Refactorización Compilador OE 12.8
  ----------------------------------------------------------------------*/

{src/core/PropathManager.i}

/* Si se ejecuta de forma no persistente sin parametros, mostrar informacion */
IF NOT THIS-PROCEDURE:PERSISTENT THEN DO:
    MESSAGE "PropathManager: Gestor deterministico de PROPATH para OpenEdge 12.8." SKIP
            "Elimina duplicados, valida rutas y preserva precedencia."
        VIEW-AS ALERT-BOX INFORMATION.
END.
