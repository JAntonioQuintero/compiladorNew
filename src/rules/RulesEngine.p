/*------------------------------------------------------------------------
    File        : src/rules/RulesEngine.p
    Purpose     : Punto de entrada procedural / persistente para RulesEngine
    Author      : Refactorización Compilador OE 12.8
  ----------------------------------------------------------------------*/

{src/rules/RulesEngine.i}

/* Si se ejecuta de forma no persistente sin parametros, mostrar ayuda */
IF NOT THIS-PROCEDURE:PERSISTENT THEN DO:
    MESSAGE "RulesEngine: Motor centralizado de reglas para OpenEdge 12.8." SKIP
            "Debe invocarse de forma persistente o mediante RUN <procedure> IN <handle>."
        VIEW-AS ALERT-BOX INFORMATION.
END.
