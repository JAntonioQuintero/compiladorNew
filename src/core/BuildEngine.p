/*------------------------------------------------------------------------
    File        : src/core/BuildEngine.p
    Purpose     : Punto de entrada procedural y persistente para BuildEngine
    Author      : Refactorización Compilador OE 12.8
  ----------------------------------------------------------------------*/

{src/rules/RulesEngine.i}
{src/core/PropathManager.i}
{src/logging/BuildLogger.i}
{src/core/BuildEngine.i}

/* Si se ejecuta de forma no persistente sin parametros, mostrar ayuda */
IF NOT THIS-PROCEDURE:PERSISTENT THEN DO:
    MESSAGE "BuildEngine: Motor central de compilacion para OpenEdge 12.8." SKIP
            "Soporta compilacion aislada a staging y despliegue condicional atomico."
        VIEW-AS ALERT-BOX INFORMATION.
END.
