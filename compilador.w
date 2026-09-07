&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v9r12 GUI
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME C-Win
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS C-Win 
/*------------------------------------------------------------------------

  File: 

  Description: 

  Input Parameters:
      <none>

  Output Parameters:
      <none>

  Author: 

  Created: 

------------------------------------------------------------------------*/
/*          This .W file was created with the Progress AppBuilder.      */
/*----------------------------------------------------------------------*/

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */
/* Modulos Desacoplados de Compilacion para OpenEdge 12.8 */
{src/rules/RulesEngine.i}
{src/core/PropathManager.i}
{src/config/ConfigManager.i}
{src/logging/BuildLogger.i}
{src/core/BuildEngine.i}

DEF VAR vl-sn      AS LOG NO-UNDO.
DEF VAR vc-dirbc   AS CHAR NO-UNDO.
DEF VAR vc-logcomp AS CHAR NO-UNDO.
DEF VAR vc-dproy   AS CHAR NO-UNDO.
DEF VAR vi-sistema AS INT NO-UNDO.
DEF VAR vc-liserr  AS CHAR NO-UNDO
  INIT "SAMPLES,ADM2,ADECOMM,WEB,WEBUTIL,PROHELP,GUI,SUPPORT,CUSTOM,OBJECTS,ESPECIAL".

DEF VAR vl-colprog AS LOG INIT TRUE.
DEF VAR vl-colRuta AS LOG INIT TRUE.

DEF VAR vc-amb01 AS CHAR NO-UNDO.
DEF VAR vc-amb02 AS CHAR NO-UNDO.

DEF VAR vr-row01 AS ROWID NO-UNDO.
DEF VAR vr-row02 AS ROWID NO-UNDO.

DEF VAR vc-handle AS HANDLE NO-UNDO.
DEF VAR vl-vista  AS LOG INIT FALSE.

DEF TEMP-TABLE tt-workarea NO-UNDO
  FIELD numind AS INT
  FIELD nompry AS CHAR
  FIELD rut001 AS CHAR                 /* ruta fuentes */
  FIELD rut002 AS CHAR                 /* ruta archivo compilador.csv */
  FIELD rut003 AS CHAR                 /* alterno de compilados */
  INDEX key001 AS PRIMARY UNIQUE numind.

DEF TEMP-TABLE tt-temp NO-UNDO
  FIELD tx-linea AS CHAR.

DEF TEMP-TABLE tt-pcomp NO-UNDO
  FIELD nomprog AS CHAR
  FIELD tipoprg AS CHAR
  FIELD rutaprg AS CHAR
  INDEX key001 AS PRIMARY nomprog.

DEF TEMP-TABLE tt-pcmppry NO-UNDO
  FIELD nomprog AS CHAR
  FIELD tipoprg AS CHAR
  FIELD rutaprg AS CHAR
  INDEX key001 AS PRIMARY nomprog ASC rutaprg ASC.

DEF TEMP-TABLE tt-pfuentes NO-UNDO
  FIELD nomprog AS CHAR
  FIELD tipoprg AS CHAR
  FIELD rutaprg AS CHAR
  FIELD tamano  AS INT
  FIELD feccre  AS DATE
  FIELD fecmod  AS DATE
  INDEX key001 AS PRIMARY nomprog.

DEFINE TEMP-TABLE tt-progs NO-UNDO
    FIELD nomprog AS CHAR
    FIELD tipoprg AS CHAR
    FIELD rutaprg AS CHAR
    FIELD tamano  AS INT
    FIELD feccre  AS DATE
    FIELD fecmod  AS DATE
    FIELD progsel AS LOG
    FIELD sterror AS CHAR
    FIELD sinruta AS LOGICAL
    INDEX key001 AS PRIMARY nomprog.

DEF TEMP-TABLE tt-rutas NO-UNDO
  FIELD nomprog AS CHAR
  FIELD tipoprg AS CHAR
  FIELD rutades AS CHAR
  FIELD rutaalt AS CHAR
  FIELD automat AS LOG INIT TRUE
  INDEX key001 AS PRIMARY nomprog ASC rutades ASC.

DEF TEMP-TABLE tt-propath NO-UNDO
  FIELD rutapro AS CHAR
  INDEX key001 AS UNIQUE PRIMARY rutapro.

DEF TEMP-TABLE tt-compila NO-UNDO
  FIELD nomprog AS CHAR FORMAT "x(20)"
  FIELD tipoprg AS CHAR
  FIELD rutaprg AS CHAR FORMAT "x(70)"
  FIELD rutades AS CHAR FORMAT "x(70)"
  FIELD rutaalt AS CHAR FORMAT "x(70)"
  FIELD dispv6p AS LOG  INIT FALSE
  INDEX key001 AS PRIMARY nomprog ASC tipoprg ASC rutaprg ASC.

DEFINE VARIABLE lvl_Stop    AS LOGICAL    NO-UNDO.
DEFINE VARIABLE lvc_verDir  AS CHARACTER  NO-UNDO.
DEFINE VARIABLE lvc_DirBase AS CHARACTER  NO-UNDO.
DEFINE VARIABLE lvc_FileLog AS CHARACTER  NO-UNDO.
DEFINE VARIABLE lvc_Msg     AS CHARACTER  NO-UNDO.
DEFINE VARIABLE lvc_progs   AS CHARACTER  NO-UNDO.
DEFINE VARIABLE lvc_Sys     AS CHARACTER  NO-UNDO.
DEFINE VARIABLE lvl_Stat    AS LOGICAL    NO-UNDO.
DEFINE VARIABLE lvi_conta   AS INTEGER    NO-UNDO.
DEFINE VARIABLE lvl_SelTodo AS LOGICAL    NO-UNDO.
DEFINE VARIABLE lvl_SinRuta AS LOGICAL    NO-UNDO.
DEFINE VARIABLE lvi_SinRuta AS INTEGER    NO-UNDO.
DEFINE VARIABLE lvi_xComp   AS INTEGER    NO-UNDO.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE Window
&Scoped-define DB-AWARE no

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME fr-frm01
&Scoped-define BROWSE-NAME br-brow01

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-progs tt-rutas

/* Definitions for BROWSE br-brow01                                     */
&Scoped-define FIELDS-IN-QUERY-br-brow01 tt-progs.nomprog tt-progs.tipoprg tt-progs.rutaprg tt-progs.tamano tt-progs.sterror tt-progs.progsel   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-brow01   
&Scoped-define SELF-NAME br-brow01
&Scoped-define QUERY-STRING-br-brow01 FOR EACH tt-progs BY tt-progs.nomprog BY tt-progs.rutaprg
&Scoped-define OPEN-QUERY-br-brow01 OPEN QUERY {&SELF-NAME} FOR EACH tt-progs BY tt-progs.nomprog BY tt-progs.rutaprg.
&Scoped-define TABLES-IN-QUERY-br-brow01 tt-progs
&Scoped-define FIRST-TABLE-IN-QUERY-br-brow01 tt-progs


/* Definitions for BROWSE br-brow02                                     */
&Scoped-define FIELDS-IN-QUERY-br-brow02 tt-rutas.rutades tt-rutas.rutaalt   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-brow02   
&Scoped-define SELF-NAME br-brow02
&Scoped-define QUERY-STRING-br-brow02 FOR EACH tt-rutas WHERE tt-rutas.nomprog = tt-progs.nomprog
&Scoped-define OPEN-QUERY-br-brow02 OPEN QUERY {&SELF-NAME}   FOR EACH tt-rutas WHERE tt-rutas.nomprog = tt-progs.nomprog.
&Scoped-define TABLES-IN-QUERY-br-brow02 tt-rutas
&Scoped-define FIRST-TABLE-IN-QUERY-br-brow02 tt-rutas


/* Definitions for FRAME fr-frm01                                       */

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS RECT-3 RECT-4 RECT-6 RECT-7 vi-proy ~
bt-cargacomp bt-cargaftes vc-buscar br-brow01 bt-comtodos bt-crear ~
bt-editar bt-eliminar bt-crear-2 btnSelall btnQuitar Btn-Stop bt-verlog ~
FILL-Progs tg-dir-alt FILL-SinRuta br-brow02 FILL-xComp FILL-Errores ~
FILL-Compila bt-salir 
&Scoped-Define DISPLAYED-OBJECTS vi-proy vl-est vl-fte vc-buscar ~
CB-Repositorio CB-Progress FILL-Progs tg-dir-alt FILL-SinRuta FILL-xComp ~
FILL-Errores FILL-Compila vc-dirfte vc-dircom vc-diralt 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR C-Win AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-cargacomp 
     LABEL "Carga Estructura" 
     SIZE 22 BY 1 TOOLTIP "Carga y compara compilados y fuentes".

DEFINE BUTTON bt-cargaftes 
     LABEL "Carga Fuentes" 
     SIZE 22 BY 1 TOOLTIP "Carga y compara compilados y fuentes".

DEFINE BUTTON bt-comtodos 
     LABEL "Compilar" 
     SIZE 19.6 BY 1.14.

DEFINE BUTTON bt-crear 
     LABEL "Nueva Ruta" 
     SIZE 19.6 BY 1.14.

DEFINE BUTTON bt-crear-2 
     LABEL "Salva Rutas" 
     SIZE 19.6 BY 1.14.

DEFINE BUTTON bt-editar 
     LABEL "Modificar" 
     SIZE 19.6 BY 1.14.

DEFINE BUTTON bt-eliminar 
     LABEL "Borra Ruta" 
     SIZE 19.6 BY 1.14.

DEFINE BUTTON bt-salir DEFAULT 
     LABEL "Salir" 
     SIZE 19.6 BY 1.14
     BGCOLOR 8 .

DEFINE BUTTON bt-verlog 
     LABEL "Ver Log" 
     SIZE 19.6 BY 1.14.

DEFINE BUTTON Btn-Stop 
     LABEL "Detener" 
     SIZE 19.6 BY 1.14.

DEFINE BUTTON btnQuitar 
     LABEL "Quitar Todo" 
     SIZE 19.6 BY 1.14.

DEFINE BUTTON btnSelall 
     LABEL "Selec. Todo" 
     SIZE 19.6 BY 1.14.

DEFINE VARIABLE CB-Progress AS INTEGER FORMAT ">9":U INITIAL 0 
     LABEL "Progress" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "No Identificada",0,
                     "Versión 9",9,
                     "Versión 11",11,
                     "OpenEdge 12 (12.8)",12
     DROP-DOWN-LIST
     SIZE 23 BY 1 NO-UNDO.

DEFINE VARIABLE CB-Repositorio AS INTEGER FORMAT ">>9":U INITIAL 0 
     LABEL "Repositorio" 
     VIEW-AS COMBO-BOX INNER-LINES 5
     LIST-ITEM-PAIRS "Sin Identificar",0,
                     "Conauto",1,
                     "Sofom",2,
                     "Saadsa",3
     DROP-DOWN-LIST
     SIZE 22 BY 1 NO-UNDO.

DEFINE VARIABLE vi-proy AS INTEGER FORMAT "->,>>>,>>9":U INITIAL 0 
     LABEL "Proyecto" 
     VIEW-AS COMBO-BOX INNER-LINES 25
     LIST-ITEM-PAIRS "Src",0
     DROP-DOWN-LIST
     SIZE 44.8 BY 1 TOOLTIP "Selecciona el ambiente de trabajo" NO-UNDO.

DEFINE VARIABLE FILL-Compila AS INTEGER FORMAT "ZZ,ZZZ,ZZZ,ZZZ,ZZ9":UC19 INITIAL 0 
     VIEW-AS FILL-IN NATIVE 
     SIZE 19 BY 1
     BGCOLOR 10 FGCOLOR 0  NO-UNDO.

DEFINE VARIABLE FILL-Errores AS INTEGER FORMAT "ZZ,ZZZ,ZZZ,ZZZ,ZZ9":UC19 INITIAL 0 
     VIEW-AS FILL-IN NATIVE 
     SIZE 19 BY 1
     BGCOLOR 12  NO-UNDO.

DEFINE VARIABLE FILL-Progs AS INTEGER FORMAT "ZZ,ZZZ,ZZZ,ZZZ,ZZ9":UC19 INITIAL 0 
     VIEW-AS FILL-IN NATIVE 
     SIZE 19 BY 1
     BGCOLOR 1 FGCOLOR 15  NO-UNDO.

DEFINE VARIABLE FILL-SinRuta AS INTEGER FORMAT "ZZ,ZZZ,ZZZ,ZZZ,ZZ9":UC19 INITIAL 0 
     VIEW-AS FILL-IN NATIVE 
     SIZE 19 BY 1
     BGCOLOR 14  NO-UNDO.

DEFINE VARIABLE FILL-xComp AS INTEGER FORMAT "ZZ,ZZZ,ZZZ,ZZZ,ZZ9":UC19 INITIAL 0 
     VIEW-AS FILL-IN NATIVE 
     SIZE 19 BY 1
     BGCOLOR 11  NO-UNDO.

DEFINE VARIABLE vc-buscar AS CHARACTER FORMAT "X(256)":U 
     LABEL "Buscar" 
     VIEW-AS FILL-IN 
     SIZE 34 BY 1 NO-UNDO.

DEFINE VARIABLE vc-diralt AS CHARACTER FORMAT "X(256)":U 
     LABEL "Directorio Alterno" 
      VIEW-AS TEXT 
     SIZE 122 BY .62
     FGCOLOR 9  NO-UNDO.

DEFINE VARIABLE vc-dircom AS CHARACTER FORMAT "X(70)":U 
     LABEL "Directorio Compilados" 
      VIEW-AS TEXT 
     SIZE 123 BY .62
     FGCOLOR 9  NO-UNDO.

DEFINE VARIABLE vc-dirfte AS CHARACTER FORMAT "X(70)":U 
     LABEL "Directorio Fuentes" 
      VIEW-AS TEXT 
     SIZE 121 BY .62
     FGCOLOR 9  NO-UNDO.

DEFINE RECTANGLE RECT-3
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 172 BY 1.43.

DEFINE RECTANGLE RECT-4
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 22 BY 22.14.

DEFINE RECTANGLE RECT-6
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 172 BY 1.43.

DEFINE RECTANGLE RECT-7
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 22 BY 8.57.

DEFINE VARIABLE tg-dir-alt AS LOGICAL INITIAL no 
     LABEL "" 
     VIEW-AS TOGGLE-BOX
     SIZE 3 BY .81 NO-UNDO.

DEFINE VARIABLE vl-est AS LOGICAL INITIAL no 
     LABEL "" 
     VIEW-AS TOGGLE-BOX
     SIZE 4 BY 1
     FGCOLOR 10 FONT 1 NO-UNDO.

DEFINE VARIABLE vl-fte AS LOGICAL INITIAL no 
     LABEL "" 
     VIEW-AS TOGGLE-BOX
     SIZE 4 BY 1
     FGCOLOR 10 FONT 1 NO-UNDO.

DEFINE BUTTON bt-aceptar-2 AUTO-GO DEFAULT 
     LABEL "Aceptar" 
     SIZE 15 BY 1.14
     BGCOLOR 8 .

DEFINE BUTTON bt-cancelar-2 AUTO-END-KEY DEFAULT 
     LABEL "Cancelar" 
     SIZE 15 BY 1.14
     BGCOLOR 8 .

DEFINE VARIABLE vc-archivo AS CHARACTER FORMAT "X(40)":U 
     VIEW-AS FILL-IN 
     SIZE 60 BY 1 NO-UNDO.

DEFINE BUTTON bt-aceptar-3 AUTO-GO DEFAULT 
     LABEL "Aceptar" 
     SIZE 15 BY 1.14
     BGCOLOR 8 .

DEFINE BUTTON bt-cancelar-3 AUTO-END-KEY DEFAULT 
     LABEL "Cancelar" 
     SIZE 15 BY 1.14
     BGCOLOR 8 .

DEFINE VARIABLE vc-newpat AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 78 BY 1 NO-UNDO.

DEFINE VARIABLE vc-nomprog AS CHARACTER FORMAT "X(256)":U 
     LABEL "Programa" 
     VIEW-AS FILL-IN 
     SIZE 34 BY 1
     BGCOLOR 15 FGCOLOR 9 FONT 1 NO-UNDO.

DEFINE RECTANGLE RECT-5
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 81 BY 3.1.

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-brow01 FOR 
      tt-progs SCROLLING.

DEFINE QUERY br-brow02 FOR 
      tt-rutas SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-brow01
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-brow01 C-Win _FREEFORM
  QUERY br-brow01 DISPLAY
      tt-progs.nomprog FORMAT "x(30)" COLUMN-LABEL "Programa" WIDTH 40
      tt-progs.tipoprg FORMAT "x(2)" COLUMN-LABEL "Tipo" WIDTH 5
      tt-progs.rutaprg FORMAT "x(60)" COLUMN-LABEL "Ruta" WIDTH 65
      tt-progs.tamano  FORMAT ">>>,>>9" COLUMN-LABEL "Tamaño" WIDTH 10
      tt-progs.sterror FORMAT "x(10)" COLUMN-LABEL "Estado"
      tt-progs.progsel FORMAT "S/N" COLUMN-LABEL "Compilar"
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH SEPARATORS SIZE 148 BY 10.81
         FONT 4
         TITLE "Programas".

DEFINE BROWSE br-brow02
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-brow02 C-Win _FREEFORM
  QUERY br-brow02 DISPLAY
      tt-rutas.rutades FORMAT "x(70)" COLUMN-LABEL "Directorio Pruebas"
      tt-rutas.rutaalt FORMAT "x(70)" COLUMN-LABEL "Directorio Versión."
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ROW-MARKERS SEPARATORS SIZE 148 BY 7.38
         FONT 4
         TITLE "Rutas Destino" ROW-HEIGHT-CHARS .52.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME fr-frm03
     vc-nomprog AT ROW 1.95 COL 46 COLON-ALIGNED
     vc-newpat AT ROW 3.14 COL 4 NO-LABEL
     bt-aceptar-3 AT ROW 4.81 COL 52
     bt-cancelar-3 AT ROW 4.81 COL 68
     RECT-5 AT ROW 1.48 COL 2
    WITH 1 DOWN KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 31.4 ROW 9.95 SCROLLABLE 
         TITLE "Nueva Estructura de Programa"
         DEFAULT-BUTTON bt-aceptar-3 CANCEL-BUTTON bt-cancelar-3.

DEFINE FRAME fr-frm02
     vc-archivo AT ROW 1.24 COL 2 NO-LABEL
     bt-aceptar-2 AT ROW 2.43 COL 32
     bt-cancelar-2 AT ROW 2.43 COL 47
    WITH 1 DOWN KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 41.8 ROW 11.14 SCROLLABLE 
         TITLE "Ruta Fuentes"
         DEFAULT-BUTTON bt-aceptar-2 CANCEL-BUTTON bt-cancelar-2.

DEFINE FRAME fr-frm01
     vi-proy AT ROW 1.48 COL 13.2 COLON-ALIGNED HELP
          "Selecciona el ambiente de trabajo"
     bt-cargacomp AT ROW 1.48 COL 67 HELP
          "Carga y compara compilados y fuentes"
     vl-est AT ROW 1.48 COL 90
     bt-cargaftes AT ROW 1.48 COL 96.8 HELP
          "Carga y compara compilados y fuentes"
     vl-fte AT ROW 1.48 COL 119.8
     vc-buscar AT ROW 1.48 COL 136 COLON-ALIGNED
     CB-Repositorio AT ROW 2.91 COL 23.4 COLON-ALIGNED
     CB-Progress AT ROW 2.91 COL 95 COLON-ALIGNED
     br-brow01 AT ROW 4.33 COL 2
     bt-comtodos AT ROW 4.52 COL 153
     bt-crear AT ROW 5.81 COL 153
     bt-editar AT ROW 7.1 COL 153
     bt-eliminar AT ROW 8.38 COL 153
     bt-crear-2 AT ROW 9.71 COL 153
     btnSelall AT ROW 11 COL 153
     btnQuitar AT ROW 12.33 COL 153
     Btn-Stop AT ROW 13.62 COL 153
     bt-verlog AT ROW 14.91 COL 153
     FILL-Progs AT ROW 17.19 COL 151.2 COLON-ALIGNED NO-LABEL
     tg-dir-alt AT ROW 17.81 COL 3
     FILL-SinRuta AT ROW 18.81 COL 151.2 COLON-ALIGNED NO-LABEL
     br-brow02 AT ROW 19.1 COL 2
     FILL-xComp AT ROW 20.38 COL 151.2 COLON-ALIGNED NO-LABEL
     FILL-Errores AT ROW 22 COL 151.2 COLON-ALIGNED NO-LABEL
     FILL-Compila AT ROW 23.62 COL 151.2 COLON-ALIGNED NO-LABEL
     bt-salir AT ROW 25.05 COL 153
     vc-dirfte AT ROW 15.52 COL 26 COLON-ALIGNED
     vc-dircom AT ROW 16.71 COL 26 COLON-ALIGNED
     vc-diralt AT ROW 17.91 COL 26 COLON-ALIGNED
     "Compilados:" VIEW-AS TEXT
          SIZE 18 BY .62 AT ROW 22.91 COL 153.4
     "Por Compilar" VIEW-AS TEXT
          SIZE 18 BY .62 AT ROW 19.71 COL 153.4
     "Programas:" VIEW-AS TEXT
          SIZE 18 BY .62 AT ROW 16.52 COL 153.4
     "Sin Ruta:" VIEW-AS TEXT
          SIZE 18 BY .62 AT ROW 18.1 COL 153.4
     "Errores:" VIEW-AS TEXT
          SIZE 18 BY .62 AT ROW 21.29 COL 153.4
     RECT-3 AT ROW 1.24 COL 1
     RECT-4 AT ROW 4.33 COL 152
     RECT-6 AT ROW 2.71 COL 2
     RECT-7 AT ROW 16.24 COL 152
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 174.8 BY 25.48
         FONT 6
         DEFAULT-BUTTON bt-salir.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: Window
   Allow: Basic,Browse,DB-Fields,Window,Query
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW C-Win ASSIGN
         HIDDEN             = YES
         TITLE              = "Compilador"
         HEIGHT             = 25.48
         WIDTH              = 174.8
         MAX-HEIGHT         = 28.57
         MAX-WIDTH          = 174.8
         VIRTUAL-HEIGHT     = 28.57
         VIRTUAL-WIDTH      = 174.8
         RESIZE             = yes
         SCROLL-BARS        = no
         STATUS-AREA        = yes
         BGCOLOR            = ?
         FGCOLOR            = ?
         KEEP-FRAME-Z-ORDER = yes
         THREE-D            = yes
         MESSAGE-AREA       = yes
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME



/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW C-Win
  NOT-VISIBLE,,RUN-PERSISTENT                                           */
/* SETTINGS FOR FRAME fr-frm01
   FRAME-NAME                                                           */
/* BROWSE-TAB br-brow01 CB-Progress fr-frm01 */
/* BROWSE-TAB br-brow02 FILL-SinRuta fr-frm01 */
ASSIGN 
       br-brow01:ALLOW-COLUMN-SEARCHING IN FRAME fr-frm01 = TRUE
       br-brow01:COLUMN-RESIZABLE IN FRAME fr-frm01       = TRUE.

/* SETTINGS FOR COMBO-BOX CB-Progress IN FRAME fr-frm01
   NO-ENABLE                                                            */
/* SETTINGS FOR COMBO-BOX CB-Repositorio IN FRAME fr-frm01
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN vc-diralt IN FRAME fr-frm01
   NO-ENABLE                                                            */
ASSIGN 
       vc-diralt:READ-ONLY IN FRAME fr-frm01        = TRUE.

/* SETTINGS FOR FILL-IN vc-dircom IN FRAME fr-frm01
   NO-ENABLE                                                            */
ASSIGN 
       vc-dircom:READ-ONLY IN FRAME fr-frm01        = TRUE.

/* SETTINGS FOR FILL-IN vc-dirfte IN FRAME fr-frm01
   NO-ENABLE                                                            */
ASSIGN 
       vc-dirfte:READ-ONLY IN FRAME fr-frm01        = TRUE.

/* SETTINGS FOR TOGGLE-BOX vl-est IN FRAME fr-frm01
   NO-ENABLE                                                            */
/* SETTINGS FOR TOGGLE-BOX vl-fte IN FRAME fr-frm01
   NO-ENABLE                                                            */
/* SETTINGS FOR FRAME fr-frm02
   NOT-VISIBLE Size-to-Fit                                              */
ASSIGN 
       FRAME fr-frm02:SCROLLABLE       = FALSE
       FRAME fr-frm02:HIDDEN           = TRUE.

/* SETTINGS FOR FILL-IN vc-archivo IN FRAME fr-frm02
   ALIGN-L                                                              */
/* SETTINGS FOR FRAME fr-frm03
   NOT-VISIBLE Size-to-Fit                                              */
ASSIGN 
       FRAME fr-frm03:SCROLLABLE       = FALSE
       FRAME fr-frm03:HIDDEN           = TRUE.

/* SETTINGS FOR FILL-IN vc-newpat IN FRAME fr-frm03
   ALIGN-L                                                              */
/* SETTINGS FOR FILL-IN vc-nomprog IN FRAME fr-frm03
   NO-ENABLE                                                            */
ASSIGN 
       vc-nomprog:READ-ONLY IN FRAME fr-frm03        = TRUE.

IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(C-Win)
THEN C-Win:HIDDEN = yes.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-brow01
/* Query rebuild information for BROWSE br-brow01
     _START_FREEFORM
OPEN QUERY {&SELF-NAME} FOR EACH tt-progs BY tt-progs.nomprog BY tt-progs.rutaprg.
     _END_FREEFORM
     _Query            is NOT OPENED
*/  /* BROWSE br-brow01 */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-brow02
/* Query rebuild information for BROWSE br-brow02
     _START_FREEFORM
OPEN QUERY {&SELF-NAME}
  FOR EACH tt-rutas WHERE tt-rutas.nomprog = tt-progs.nomprog
     _END_FREEFORM
     _Query            is NOT OPENED
*/  /* BROWSE br-brow02 */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK FRAME fr-frm02
/* Query rebuild information for FRAME fr-frm02
     _Query            is NOT OPENED
*/  /* FRAME fr-frm02 */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK FRAME fr-frm03
/* Query rebuild information for FRAME fr-frm03
     _Query            is NOT OPENED
*/  /* FRAME fr-frm03 */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME C-Win
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL C-Win C-Win
ON END-ERROR OF C-Win /* Compilador */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
    RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL C-Win C-Win
ON WINDOW-CLOSE OF C-Win /* Compilador */
DO:
  /* This event will close the window and terminate the procedure.  */
    RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fr-frm02
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fr-frm02 C-Win
ON GO OF FRAME fr-frm02 /* Ruta Fuentes */
DO:
  DEF VAR vc-rut    AS CHAR NO-UNDO.
  DEF VAR vc-nomdir AS CHAR NO-UNDO.

  ASSIGN vc-archivo.

  IF vc-archivo = "" THEN DO:
    MESSAGE "Debe seleccionar un directorio"
      VIEW-AS ALERT-BOX ERROR BUTTONS OK TITLE "Error".
    RETURN NO-APPLY.
  END.

  /* Valida y corrige directorio de salida */
  IF NUM-ENTRIES(vc-archivo,"/") > 0 THEN DO:
    vc-archivo = REPLACE(vc-archivo,"/","\").
  END.

  ASSIGN vc-rut = TRIM(SUBSTITUTE("&1\&2",vc-archivo,"nul")).
  IF SEARCH(vc-rut) = ? THEN DO:
    MESSAGE SUBSTITUTE("No existe el directorio &1, verifique !!!",vc-archivo)
      VIEW-AS ALERT-BOX ERROR BUTTONS OK TITLE "Error".
    RETURN NO-APPLY.
  END.
  ASSIGN vc-nomdir = vc-archivo.

  ASSIGN vc-archivo:SCREEN-VALUE = vc-archivo.

  ASSIGN vl-sn = FALSE.
  MESSAGE 
    SUBSTITUTE("La ruta de exportacion &1 es correcta ???",vc-archivo)
    VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO TITLE "Pregunta"
    UPDATE vl-sn.
  IF vl-sn = FALSE THEN DO: 
    ASSIGN vc-archivo:SCREEN-VALUE = vc-nomdir.
    RETURN NO-APPLY.
  END.
  ASSIGN vc-archivo.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME fr-frm03
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL fr-frm03 C-Win
ON GO OF FRAME fr-frm03 /* Nueva Estructura de Programa */
DO:
  ASSIGN vc-newpat.
  IF vc-newpat = "" THEN DO:
    MESSAGE "Debes teclear la ruta destino"
      VIEW-AS ALERT-BOX ERROR BUTTONS OK TITLE "Error".
    RETURN NO-APPLY.
  END.
  IF vc-newpat BEGINS (vc-dirbc + "\") THEN DO:
  END.
  ELSE DO:
    MESSAGE 
      "La ruta debe iniciar con la estructura base que es:"
      SKIP
      vc-dirbc
      SKIP
      "Favor de Verificar "
      VIEW-AS ALERT-BOX ERROR BUTTONS OK TITLE "Error".
    RETURN NO-APPLY.
  END.

  /* Valida y corrige directorio de salida */
  IF NUM-ENTRIES(vc-newpat,"/") > 1 THEN DO:
    vc-newpat = REPLACE(vc-newpat,"/","\").
  END.

  IF SUBSTRING(vc-newpat,LENGTH(vc-newpat),1) <> "\" THEN DO:
    ASSIGN SUBSTRING(vc-newpat,(LENGTH(vc-newpat) + 1),1) = "\".
  END.

  ASSIGN vc-newpat:SCREEN-VALUE = vc-newpat.

  ASSIGN vl-sn = FALSE.
  MESSAGE "Es Correcta la ruta destino del programa !!"
    VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO TITLE "Pregunta"
    UPDATE vl-sn.
  IF vl-sn = FALSE THEN DO:
    RETURN NO-APPLY.
  END.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-brow01
&Scoped-define SELF-NAME br-brow01
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-brow01 C-Win
ON MOUSE-SELECT-DBLCLICK OF br-brow01 IN FRAME fr-frm01 /* Programas */
OR RETURN OF br-brow01 DO:
    IF AVAILABLE tt-progs THEN DO:

      /*
        IF lvl_SelTodo THEN DO:
            MESSAGE "¿Desea quitar la Selección Actual de Programas a Compilar?"
                VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO UPDATE vl-sn.
            IF vl-sn THEN DO:
                FOR EACH tt-progs WHERE tt-progs.progsel:
                    ASSIGN tt-progs.progsel = NO.
                END.
                ASSIGN lvi_xComp = 0.
            END.
        END.
      */
      
        IF tt-progs.progsel = FALSE THEN DO:
            FIND FIRST tt-rutas
                WHERE tt-rutas.nomprog = tt-progs.nomprog
                NO-LOCK NO-ERROR.
            IF NOT AVAILABLE tt-rutas THEN DO:
                MESSAGE "Imposible compilar programa, no tiene ruta destino"
                    VIEW-AS ALERT-BOX ERROR BUTTONS OK TITLE "Error".
                APPLY "CHOOSE":U TO bt-crear.
                RETURN NO-APPLY.
            END.
            ASSIGN 
                lvi_xComp = lvi_xComp + 1
                tt-progs.progsel = TRUE.
        END.
        ELSE DO:
            ASSIGN tt-progs.progsel = FALSE.
            IF lvi_xComp > 0 THEN
                ASSIGN lvi_xComp = lvi_xComp - 1.
        END.
        ASSIGN 
            Fill-xComp:SCREEN-VALUE = STRING(lvi_xComp)
            vl-sn = br-brow01:REFRESH().
    END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-brow01 C-Win
ON ROW-DISPLAY OF br-brow01 IN FRAME fr-frm01 /* Programas */
DO:
    IF AVAIL tt-progs THEN DO:
        IF tt-progs.sterror = "Error" THEN DO:
            ASSIGN
                tt-progs.nomprog:BGCOLOR IN BROWSE br-brow01 = 12
                tt-progs.tipoprg:BGCOLOR = 12
                tt-progs.rutaprg:BGCOLOR = 12
                tt-progs.tamano :BGCOLOR = 12
                tt-progs.sterror:BGCOLOR = 12
                tt-progs.progsel:BGCOLOR = 12.
        END.
        ELSE IF tt-progs.sinruta THEN DO:
            ASSIGN
                tt-progs.nomprog:BGCOLOR IN BROWSE br-brow01 = 14
                tt-progs.tipoprg:BGCOLOR = 14
                tt-progs.rutaprg:BGCOLOR = 14
                tt-progs.tamano :BGCOLOR = 14
                tt-progs.sterror:BGCOLOR = 14
                tt-progs.progsel:BGCOLOR = 14.
        END.
        ELSE DO:
            ASSIGN
                tt-progs.nomprog:BGCOLOR IN BROWSE br-brow01 = ?
                tt-progs.tipoprg:BGCOLOR = ?
                tt-progs.rutaprg:BGCOLOR = ?
                tt-progs.tamano :BGCOLOR = ?
                tt-progs.sterror:BGCOLOR = ?
                tt-progs.progsel:BGCOLOR = ?.
        END.
    END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-brow01 C-Win
ON START-SEARCH OF br-brow01 IN FRAME fr-frm01 /* Programas */
DO:
  DEF VAR vh-col AS WIDGET-HANDLE NO-UNDO.
  vh-col = BROWSE br-brow01:CURRENT-COLUMN.

  CASE vh-col:NAME:
    WHEN "NomProg" THEN DO:
      RUN SorteaQuery (vh-col,INPUT-OUTPUT vl-colprog).
    END.
    WHEN "RutaPrg" THEN DO:
      RUN SorteaQuery (vh-col,INPUT-OUTPUT vl-colruta).
    END.
    WHEN "sterror" THEN DO:
      RUN SorteaQuery (vh-col,INPUT-OUTPUT vl-colruta).
    END.
  END CASE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-brow01 C-Win
ON VALUE-CHANGED OF br-brow01 IN FRAME fr-frm01 /* Programas */
DO:
    ASSIGN vr-row01 = ?.
    CLOSE QUERY br-brow02.
    IF AVAILABLE tt-progs THEN DO:
        ASSIGN vr-row01 = ROWID(tt-progs).
        {&open-query-br-brow02}
        APPLY "home" TO br-brow02.
        APPLY "value-changed" TO br-brow02.
    END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-brow02
&Scoped-define SELF-NAME br-brow02
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-brow02 C-Win
ON VALUE-CHANGED OF br-brow02 IN FRAME fr-frm01 /* Rutas Destino */
DO:
  ASSIGN vr-row02 = ?.
  IF AVAILABLE tt-rutas THEN DO:
    ASSIGN vr-row02 = ROWID(tt-rutas).
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-cargacomp
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-cargacomp C-Win
ON CHOOSE OF bt-cargacomp IN FRAME fr-frm01 /* Carga Estructura */
DO:
  DEF VAR vi-err AS INT NO-UNDO.

  FIND tt-workarea
    WHERE tt-workarea.numind = vi-proy
    NO-LOCK NO-ERROR.
  IF NOT AVAILABLE tt-workarea THEN DO:
    MESSAGE "No tiene seleccionado un area de trabajo, seleccione !!!"
      VIEW-AS ALERT-BOX WARNING BUTTONS OK TITLE "Aviso".
    RETURN NO-APPLY.
  END.

  IF vi-sistema = 0 THEN DO:
    MESSAGE "Debe seleccionar un sistema"
      VIEW-AS ALERT-BOX WARNING BUTTONS OK TITLE "Aviso".
    RETURN NO-APPLY.
  END.

  RUN Limpia-Var.

  ASSIGN vl-sn = SESSION:SET-WAIT-STATE("general").
  ASSIGN vl-est = TRUE.
  RUN Limpia-Temporales.
  ASSIGN vl-fte = FALSE.
  CLOSE QUERY br-brow01.
  CLOSE QUERY br-brow02.
  RUN Carga-Compilados.
  ASSIGN vl-sn = SESSION:SET-WAIT-STATE("").
  ASSIGN vl-sn = c-win:MOVE-TO-TOP().
  APPLY "entry" TO SELF.
  DISPLAY 
    vl-est 
    vl-fte
    WITH FRAME fr-frm01.

  MESSAGE "Lista de carpetas cargada."
    VIEW-AS ALERT-BOX INFORMATION TITLE "Informe".

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-cargaftes
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-cargaftes C-Win
ON CHOOSE OF bt-cargaftes IN FRAME fr-frm01 /* Carga Fuentes */
DO:
  FIND tt-workarea
    WHERE tt-workarea.numind = vi-proy
    NO-LOCK NO-ERROR.
  IF NOT AVAILABLE tt-workarea THEN DO:
    MESSAGE "No tiene seleccionado un area de trabajo, seleccione !!!"
      VIEW-AS ALERT-BOX WARNING BUTTONS OK TITLE "Aviso".
    RETURN NO-APPLY.
  END.

  IF vi-sistema = 0 THEN DO:
    MESSAGE "Debe seleccionar un sistema"
      VIEW-AS ALERT-BOX WARNING BUTTONS OK TITLE "Aviso".
    RETURN NO-APPLY.
  END.

  IF NOT vl-est THEN DO:
    MESSAGE "Debes cargar la estructura de programas compilados"
      VIEW-AS ALERT-BOX ERROR BUTTONS OK TITLE "Error".
    RETURN NO-APPLY.
  END.

  ASSIGN vl-sn = SESSION:SET-WAIT-STATE("general").
  ASSIGN vl-fte = TRUE.
  RUN Carga-Fuentes.
  ASSIGN vl-sn = SESSION:SET-WAIT-STATE("").
  ASSIGN vl-sn = c-win:MOVE-TO-TOP().
  {&open-query-br-brow01}
  APPLY "home" TO br-brow01.
  APPLY "value-changed" TO br-brow01.
  DISPLAY vl-fte
    WITH FRAME fr-frm01.
  APPLY "entry" TO br-brow01.
  output to value(lvc_Progs).
      for each tt-Progs no-lock:
          EXPORT DELIMITER "," tt-Progs.
      end.
      PUT SKIP(2).
      FOR EACH tt-compila NO-LOCK:
          EXPORT DELIMITER "," tt-Compila.
      END.
  output close.
  
  MESSAGE "Carga Completada"
    VIEW-AS ALERT-BOX INFORMATION TITLE "Informe".
  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-comtodos
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-comtodos C-Win
ON CHOOSE OF bt-comtodos IN FRAME fr-frm01 /* Compilar */
DO:
    IF NUM-RESULTS("br-brow01") = 0 
        OR NUM-RESULTS("br-brow01") = ? THEN DO:
        MESSAGE "Debe cargar programas fuentes"
            VIEW-AS ALERT-BOX WARNING BUTTONS OK TITLE "Aviso".
        RETURN NO-APPLY.
    END.

    FIND FIRST tt-progs
        WHERE tt-progs.progsel = TRUE
        NO-LOCK NO-ERROR.
    IF NOT AVAILABLE tt-progs THEN DO:
        MESSAGE "Debe seleccionar al menos un programa fuente"
            VIEW-AS ALERT-BOX WARNING BUTTONS OK TITLE "Aviso".
        RETURN NO-APPLY.
    END.

    /* genera archivos a compilar */
    RUN Genera-Por-Compilar.

    /* compila programas fuentes */
    ASSIGN Fill-Compila:SCREEN-VALUE = "0".
    RUN Compila-Programas.

    /* prepara archivos wrx y los copia a com*/
    RUN Copia-wrx.

    /* Limpiar */
    FOR EACH tt-Progs WHERE tt-Progs.ProgSel:
        ASSIGN tt-Progs.ProgSel = NO.
    END.

    RUN Cifras.

    {&open-query-br-brow01}

    APPLY "home":U TO br-brow01.
    APPLY "VALUE-CHANGED":U TO br-brow01.

    MESSAGE "Finalizó el Proceso de Compilación"
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-crear
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-crear C-Win
ON CHOOSE OF bt-crear IN FRAME fr-frm01 /* Nueva Ruta */
DO:
  DEFINE VARIABLE vr-rowid AS ROWID NO-UNDO.
  ASSIGN vr-rowid = ?.
  FIND tt-progs
      WHERE ROWID(tt-progs) = vr-row01 EXCLUSIVE-LOCK NO-ERROR.
  IF NOT AVAILABLE tt-progs THEN DO:
      MESSAGE "Debe seleccionar un programa de la lista"
          VIEW-AS ALERT-BOX ERROR BUTTONS OK TITLE "Error".
      RETURN NO-APPLY.
  END.
  ASSIGN
      vc-nomprog = SUBSTITUTE("&1.&2",
                              TRIM(tt-progs.nomprog),
                              TRIM(tt-progs.tipoprg)).
  DO TRANSACTION WITH FRAME fr-frm03 VIEW-AS DIALOG-BOX.
      CLEAR ALL.
      ASSIGN vc-newpat = vc-dirbc.
      DISPLAY
          vc-nomprog
          vc-newpat.
      UPDATE
          vc-newpat
          bt-aceptar-3
          bt-cancelar-3.
  END.
  CREATE tt-rutas.
  ASSIGN
      tt-rutas.nomprog = tt-progs.nomprog
      tt-rutas.tipoprg = "r".
  ASSIGN
      tt-rutas.rutades = vc-newpat
      tt-rutas.rutaalt = REPLACE(vc-newpat,vc-dircom,vc-diralt)
      tt-rutas.automat = FALSE
      vr-rowid = ROWID(tt-rutas).

  ASSIGN 
      tt-progs.progsel = TRUE
      tt-progs.sterror = ""
      tt-progs.sinruta = NO
      lvl_stat = br-brow01:REFRESH().
  IF vr-rowid = ? THEN RETURN NO-APPLY.
  RUN Cifras.
  APPLY "VALUE-CHANGED" TO br-brow01.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-crear-2
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-crear-2 C-Win
ON CHOOSE OF bt-crear-2 IN FRAME fr-frm01 /* Salva Rutas */
DO:
    DEFINE VARIABLE vc-rutco  AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE vc-rutre  AS CHARACTER  NO-UNDO. 
    DEFINE VARIABLE vi-err    AS INTEGER    NO-UNDO.

    FIND tt-workarea
       WHERE tt-workarea.numind = vi-proy NO-LOCK NO-ERROR.

    RUN crea-directorio(INPUT tt-workarea.rut002, OUTPUT vi-err).

    ASSIGN 
        vc-rutco = SUBSTITUTE("&1\compilador.csv",tt-workarea.rut002)
        vc-rutre = SUBSTITUTE("&1\compilador-res.csv",tt-workarea.rut002).

    IF vi-proy = 0 THEN DO:
        FIND FIRST tt-rutas
            WHERE tt-rutas.automat = FALSE NO-LOCK NO-ERROR.
        IF NOT AVAILABLE tt-rutas THEN DO:
            MESSAGE "No hay nuevas rutas por adicionar, verifique !!!"
                VIEW-AS ALERT-BOX WARNING BUTTONS OK TITLE "Aviso".
            RETURN NO-APPLY.
        END.
    END.

    ASSIGN vl-sn = FALSE.
    MESSAGE "Esta seguro/a de querer respaldar nuevas rutas ??"
        VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO TITLE "Pregunta"
        UPDATE vl-sn.
    IF vl-sn = FALSE THEN RETURN NO-APPLY.
    
    OS-COPY VALUE(vc-rutco) VALUE(vc-rutre).

    OUTPUT TO VALUE(vc-rutco) APPEND.
    FOR EACH tt-rutas
        WHERE tt-rutas.automat = FALSE:
        EXPORT DELIMITER "|" 
            nomprog AT 1
            tipoprg
            rutades.
        ASSIGN tt-rutas.automat = TRUE.
    END.
    OUTPUT CLOSE.
    
    MESSAGE 
        "Se actualizaron las rutas del compilador," SKIP
        "el respaldo se llama (compilador_res.csv)"
        VIEW-AS ALERT-BOX INFORMATION BUTTONS OK TITLE "Aviso".
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-editar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-editar C-Win
ON CHOOSE OF bt-editar IN FRAME fr-frm01 /* Modificar */
DO:
  FIND tt-progs
    WHERE ROWID(tt-progs) = vr-row01
    NO-LOCK NO-ERROR.

  FIND {&FIRST-TABLE-IN-QUERY-BR-BROW02}
    WHERE ROWID({&FIRST-TABLE-IN-QUERY-BR-BROW02}) = VR-ROW02
    NO-LOCK NO-ERROR NO-WAIT.
  IF NOT AVAILABLE {&FIRST-TABLE-IN-QUERY-BR-BROW02} THEN DO:
    IF LOCKED({&FIRST-TABLE-IN-QUERY-BR-BROW02}) THEN DO:
      MESSAGE "El registro seleccionado se encuentra ocupado, intente mas tarde !!!"
        VIEW-AS ALERT-BOX ERROR BUTTONS OK TITLE "Error".
      RETURN NO-APPLY.
    END.
    MESSAGE "Debe seleccionar un registro de la lista"
      VIEW-AS ALERT-BOX ERROR BUTTONS OK TITLE "Error".
    RETURN NO-APPLY.
  END.

  IF vi-proy = 0 THEN DO:
    IF tt-rutas.automa = TRUE THEN DO:
      MESSAGE "No es posible modificar rutas automaticas"
        VIEW-AS ALERT-BOX WARNING BUTTONS OK TITLE "Aviso".
      RETURN NO-APPLY.
    END.
  END.

  DO TRANSACTION WITH FRAME FR-FRM03 VIEW-AS DIALOG-BOX:
    FIND CURRENT {&FIRST-TABLE-IN-QUERY-BR-BROW02}
      EXCLUSIVE-LOCK NO-ERROR NO-WAIT.
    ASSIGN
      vc-nomprog = SUBSTITUTE("&1.&2",
                              TRIM(tt-progs.nomprog),
                              TRIM(tt-progs.tipoprg))
      vc-newpat = tt-rutas.rutades.
    DISPLAY
      vc-nomprog
      vc-newpat.
    UPDATE
      vc-newpat
      bt-aceptar-3
      bt-cancelar-3.

    ASSIGN tt-rutas.rutades = vc-newpat.

    FIND CURRENT {&FIRST-TABLE-IN-QUERY-BR-BROW02}
      NO-LOCK NO-ERROR NO-WAIT.
  END.
  ASSIGN VL-SN = br-brow02:REFRESH().
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-eliminar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-eliminar C-Win
ON CHOOSE OF bt-eliminar IN FRAME fr-frm01 /* Borra Ruta */
DO:
    FIND tt-progs
        WHERE ROWID(tt-progs) = vr-row01 NO-LOCK NO-ERROR.
    FIND {&FIRST-TABLE-IN-QUERY-BR-BROW02}
        WHERE ROWID({&FIRST-TABLE-IN-QUERY-BR-BROW02}) = vr-row02
        NO-LOCK NO-ERROR NO-WAIT.
    IF NOT AVAILABLE {&FIRST-TABLE-IN-QUERY-BR-BROW02} THEN DO:
        IF LOCKED({&FIRST-TABLE-IN-QUERY-BR-BROW02}) THEN DO:
            MESSAGE 
                "El registro seleccionado se encuentra ocupado" SKIP
                "Intente mas tarde !!!"
                VIEW-AS ALERT-BOX ERROR BUTTONS OK TITLE "Error".
            RETURN NO-APPLY.
        END.
        MESSAGE "Debe seleccionar un registro de la lista"
            VIEW-AS ALERT-BOX ERROR BUTTONS OK TITLE "Error".
        RETURN NO-APPLY.
    END.

    IF vi-proy = 0 THEN DO:
        IF tt-rutas.automa = TRUE THEN DO:
            MESSAGE "No es posible ELIMINAR rutas Originales"
                VIEW-AS ALERT-BOX WARNING BUTTONS OK TITLE "Aviso".
            RETURN NO-APPLY.
        END.
    END.

    ASSIGN vl-sn = FALSE.
    MESSAGE "¿Esta seguro de querer eliminar el registro seleccionado?"
        VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO TITLE "Pregunta"
        UPDATE vl-sn.
    IF NOT vl-sn THEN RETURN NO-APPLY.

    DO TRANSACTION:
        FIND CURRENT {&FIRST-TABLE-IN-QUERY-BR-BROW02}
            EXCLUSIVE-LOCK NO-ERROR NO-WAIT.
        DELETE {&FIRST-TABLE-IN-QUERY-br-brow02}.
        FIND FIRST tt-rutas
          WHERE tt-rutas.nomprog = tt-progs.nomprog
          NO-LOCK NO-ERROR.
        IF NOT AVAILABLE tt-rutas THEN DO:
          FIND CURRENT tt-progs EXCLUSIVE-LOCK NO-ERROR.
          ASSIGN
            tt-progs.sinruta = TRUE
            tt-progs.sterror = "Sin Ruta".
        END.
    END.
    RUN Cifras.
    APPLY "value-changed" TO BR-BROW01.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-salir
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-salir C-Win
ON CHOOSE OF bt-salir IN FRAME fr-frm01 /* Salir */
DO: 
   APPLY 'CLOSE' TO THIS-PROCEDURE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-verlog
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-verlog C-Win
ON CHOOSE OF bt-verlog IN FRAME fr-frm01 /* Ver Log */
DO:
  RUN ChecaEstatus IN vc-handle (OUTPUT vl-vista).
  IF vl-vista = TRUE THEN DO:
    ASSIGN vl-vista = FALSE.
    RUN MuestraVentana IN vc-handle.
  END.
  ELSE DO:
    ASSIGN vl-vista = TRUE.
    RUN OcultaVentana IN vc-handle.
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME Btn-Stop
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL Btn-Stop C-Win
ON CHOOSE OF Btn-Stop IN FRAME fr-frm01 /* Detener */
DO:
    MESSAGE "¿Desea Cancelar la Compilación?"
        VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO 
        TITLE "¡ ATENCION !" UPDATE lvl_Stop.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btnQuitar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btnQuitar C-Win
ON CHOOSE OF btnQuitar IN FRAME fr-frm01 /* Quitar Todo */
DO:
  IF NUM-RESULTS("br-brow01") = 0
  OR NUM-RESULTS("br-brow01") = ?
  THEN DO:
    MESSAGE "No hay programas a compilar en la lista de programas"
      VIEW-AS ALERT-BOX ERROR BUTTONS OK.
    RETURN NO-APPLY.
  END.

  RUN Quita-Seleccion.
  
  APPLY "home" TO br-brow01.
  APPLY "value-changed" TO br-brow01.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME btnSelall
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL btnSelall C-Win
ON CHOOSE OF btnSelall IN FRAME fr-frm01 /* Selec. Todo */
DO:
  IF NUM-RESULTS("br-brow01") = 0
  OR NUM-RESULTS("br-brow01") = ?
  THEN DO:
    MESSAGE "No hay programas a compilar en la lista de programas"
      VIEW-AS ALERT-BOX ERROR BUTTONS OK.
    RETURN NO-APPLY.
  END.

  RUN Selecciona-Filtrados.
  
  FIND FIRST tt-progs
    WHERE tt-progs.sinruta = TRUE
    NO-LOCK NO-ERROR.
  IF AVAILABLE tt-progs THEN DO:
    MESSAGE "Existen: " lvi_SinRuta " Programas sin Ruta de Compilación"
    VIEW-AS ALERT-BOX WARNING BUTTONS OK.
  END.

  APPLY "home" TO br-brow01.
  APPLY "value-changed" TO br-brow01.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME tg-dir-alt
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL tg-dir-alt C-Win
ON VALUE-CHANGED OF tg-dir-alt IN FRAME fr-frm01
DO:
   ASSIGN {&SELF-NAME}.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME fr-frm02
&Scoped-define SELF-NAME vc-archivo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL vc-archivo C-Win
ON HELP OF vc-archivo IN FRAME fr-frm02
DO:
  DEF VAR vc-directorio AS CHAR NO-UNDO.
  DEF VAR vc-cancel     AS LOG  NO-UNDO.

  ASSIGN vc-directorio = "c:\_cnt".

  RUN util\pidedir.p ("Seleccione Directorio",
                  OUTPUT vc-directorio,
                  OUTPUT vc-cancel).
  
  IF vc-cancel = FALSE THEN DO:
    ASSIGN vc-archivo:SCREEN-VALUE = vc-directorio.
  END.
  ELSE DO:
    DISPLAY
      vc-archivo
      WITH FRAME fr-frm02.
  END.
  
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL vc-archivo C-Win
ON LEAVE OF vc-archivo IN FRAME fr-frm02
DO:
  ASSIGN vc-archivo.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME fr-frm01
&Scoped-define SELF-NAME vc-buscar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL vc-buscar C-Win
ON ANY-PRINTABLE OF vc-buscar IN FRAME fr-frm01 /* Buscar */
DO:
  APPLY "U1" TO vc-buscar.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL vc-buscar C-Win
ON BACKSPACE OF vc-buscar IN FRAME fr-frm01 /* Buscar */
DO:
  APPLY "U1" TO vc-buscar.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL vc-buscar C-Win
ON CURSOR-DOWN OF vc-buscar IN FRAME fr-frm01 /* Buscar */
DO:
    APPLY "ENTRY":U TO br-brow01 IN FRAME {&FRAME-NAME}.
    RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL vc-buscar C-Win
ON U1 OF vc-buscar IN FRAME fr-frm01 /* Buscar */
DO:
  DO WITH FRAME fr-frm01:
    APPLY LASTKEY.
    ASSIGN vc-buscar.
    OPEN QUERY br-brow01 FOR
      EACH tt-progs
      WHERE tt-progs.nomprog MATCHES SUBSTITUTE("*&1*",vc-buscar)
      NO-LOCK.
    APPLY "home" TO br-brow01.
    APPLY "value-changed" TO br-brow01.
  END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME vi-proy
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL vi-proy C-Win
ON VALUE-CHANGED OF vi-proy IN FRAME fr-frm01 /* Proyecto */
DO:
    FIND tt-workarea
        WHERE tt-workarea.numind = INPUT vi-proy NO-LOCK NO-ERROR.
    IF NOT AVAILABLE tt-workarea THEN DO:
        MESSAGE "No existe el proyecto, favor de verificar !!!"
            VIEW-AS ALERT-BOX ERROR BUTTONS OK TITLE "Error".
        RETURN NO-APPLY.
    END.

    ASSIGN 
        vc-dirfte = tt-workarea.rut001
        vc-dircom = vc-dirbc
        vc-diralt = tt-workarea.rut003.

    DISPLAY
        vc-dirfte
        vc-dircom
        vc-diralt
        WITH FRAME fr-frm01.

    IF vl-est = TRUE THEN DO:
        IF vi-proy <> INPUT vi-proy THEN DO:
            ASSIGN vl-sn = FALSE.
            MESSAGE "Ya tienes una estructura cargada, deseas re-cargarla ??"
                VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO TITLE "Pregunta"
                UPDATE vl-sn.
            IF vl-sn = FALSE THEN DO:
              DISPLAY
                vi-proy
                WITH FRAME fr-frm01.
                RETURN NO-APPLY.
            END.
        END.
    END.

    ASSIGN
        vl-est = FALSE
        vl-fte = FALSE.

    RUN Limpia-Temporales.

    CLOSE QUERY br-brow01.
    CLOSE QUERY br-brow02.

    ASSIGN vi-proy.

    RUN Limpia-Var.

    IF vl-sn THEN DO:
        APPLY "CHOOSE":U TO bt-cargacomp IN FRAME {&FRAME-NAME}.
    END.

    ASSIGN tg-dir-alt = IF vi-proy = 0 THEN NO ELSE YES.
    DISPLAY tg-dir-alt WITH FRAME {&FRAME-NAME}.

END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-brow01
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK C-Win 


/* ***************************  Main Block  *************************** */

/* Set CURRENT-WINDOW: this will parent dialog-boxes and frames.        */
ASSIGN CURRENT-WINDOW                = {&WINDOW-NAME} 
       THIS-PROCEDURE:CURRENT-WINDOW = {&WINDOW-NAME}.
ASSIGN {&WINDOW-NAME}:X = ((session:width-pixels  - {&WINDOW-NAME}:WIDTH-PIXELS)  / 2)
       {&WINDOW-NAME}:Y = ((session:height-pixels - {&WINDOW-NAME}:HEIGHT-PIXELS) / 2) - 25
       {&WINDOW-NAME}:hidden = false.

/* The CLOSE event can be used from inside or outside the procedure to  */
/* terminate it.                                                        */
ON CLOSE OF THIS-PROCEDURE DO:
  RUN CierraVentana IN vc-handle.
  RUN disable_UI.
END.

/* Best default for GUI applications is...                              */
PAUSE 0 BEFORE-HIDE.

/* Now enable the interface and wait for the exit condition.            */
/* (NOTE: handle ERROR and END-KEY so cleanup code will always fire.    */
MAIN-BLOCK:
DO ON ERROR   UNDO MAIN-BLOCK, LEAVE MAIN-BLOCK
   ON END-KEY UNDO MAIN-BLOCK, LEAVE MAIN-BLOCK:

  RUN util\compila02.w PERSISTEN SET vc-handle.
  RUN OcultaVentana IN vc-handle.
  ASSIGN vl-vista = FALSE.
  ASSIGN 
    vl-est = FALSE
    vl-fte = FALSE.

  RUN BuscaSistema (OUTPUT vi-sistema).
  RUN CargaProyectos.
  
  ASSIGN vi-proy = 0.
  RUN enable_UI.
  APPLY "value-changed" TO vi-proy.

  IF NOT THIS-PROCEDURE:PERSISTENT THEN
      WAIT-FOR CLOSE OF THIS-PROCEDURE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Bitacora C-Win 
PROCEDURE Bitacora :
/*-----------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
-----------------------------------------------------------------------------*/
    DEFINE INPUT  PARAMETER  ipc_Msg AS CHARACTER   NO-UNDO.

    OUTPUT TO VALUE(lvc_FileLog) APPEND.
        IF ipc_Msg <> "" THEN DO:
            PUT UNFORMATTED STRING(TODAY,'99/99/9999') + ' ' + 
                STRING(TIME,'HH:MM:SS ') + ipc_Msg SKIP. 
        END.
    OUTPUT CLOSE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE BuscaSistema C-Win 
PROCEDURE BuscaSistema :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEF OUTPUT PARAMETER pc-sistema AS INT NO-UNDO.

DEF VAR vc-ruta AS CHAR NO-UNDO.

ASSIGN pc-sistema = 0.
ASSIGN vc-ruta = SEARCH(".\nul").

FILE-INFO:FILE-NAME = vc-ruta.
vc-ruta = FILE-INFO:FULL-PATHNAME.

IF PROVERSION BEGINS "12" THEN ASSIGN lvc_verDir = "-v12".
ELSE IF PROVERSION BEGINS "11" THEN ASSIGN lvc_verDir = "-v11".
ELSE IF PROVERSION BEGINS "9" THEN ASSIGN lvc_verDir = "".
ELSE ASSIGN lvc_verDir = "-" + ENTRY(1, PROVERSION, ".").

ASSIGN 
    lvc_progs   = SESSION:TEMP-DIRECTORY + "ListaProgs_"  
    vc-logcomp  = SESSION:TEMP-DIRECTORY + "Compila_ERR_" 
    lvc_FileLog = SESSION:TEMP-DIRECTORY + "Compila"
    vc-ruta     = REPLACE(vc-ruta,"\nul","").

IF INDEX(vc-ruta,"c:\_cnt\conauto",1) = 1 THEN DO:
    ASSIGN 
        pc-sistema  = 1
        lvc_Progs   = lvc_Progs  + "Con" + ".txt"
        vc-LogComp  = vc-LogComp + "Con_"
        lvc_FileLog = lvc_FileLog + "Con" + lvc_verDir + "_" + 
        STRING(TODAY,"999999") + "_" + STRING(TIME) + ".log".

END.
ELSE IF INDEX(vc-ruta,"c:\_cnt\sofom",1) = 1 THEN DO:
    ASSIGN 
        pc-sistema  = 2
        lvc_Progs   = lvc_Progs  + "Sof" + ".txt"
        vc-LogComp  = vc-LogComp + "Sof_"
        lvc_FileLog = lvc_FileLog + "Sof" + lvc_verDir + "_" + 
        STRING(TODAY,"999999") + "_" + STRING(TIME) + ".log".
END.
ELSE IF INDEX(vc-ruta,"c:\_cnt\saadsa",1) = 1 THEN DO:
    ASSIGN 
        pc-sistema  = 3
        lvc_Progs   = lvc_Progs  + "Saa" + ".txt"
        vc-LogComp  = vc-LogComp + "Saa_"
        lvc_FileLog = lvc_FileLog + "Saa" + lvc_verDir + "_" + 
        STRING(TODAY,"999999") + "_" + STRING(TIME) + ".log".
END.
ELSE IF INDEX(vc-ruta,"c:\_cnt\Eventos-v11",1) = 1 THEN DO:
    ASSIGN 
        pc-sistema  = 4
        lvc_Progs   = lvc_Progs  + "Eve" + ".txt"
        vc-LogComp  = vc-LogComp + "Eve_"
        lvc_FileLog = lvc_FileLog + "Eve" + lvc_verDir + "_" + 
        STRING(TODAY,"999999") + "_" + STRING(TIME) + ".log".
END.

ASSIGN 
    vc-LogComp = vc-LogComp + 
    STRING(TODAY,"999999") + "-" + STRING(TIME) + ".log".
OUTPUT TO VALUE(lvc_FileLog).
OUTPUT CLOSE.

ASSIGN
    vl-est = FALSE
    vl-fte = FALSE.

EMPTY TEMP-TABLE tt-workarea NO-ERROR.

DO WITH FRAME {&FRAME-NAME}:
    IF PROVERSION BEGINS "12" THEN 
        ASSIGN 
            CB-Progress:SCREEN-VALUE = "12".
    ELSE IF PROVERSION BEGINS "11" THEN 
        ASSIGN 
            CB-Progress:SCREEN-VALUE = "11".
    ELSE IF PROVERSION BEGINS "9" THEN 
        ASSIGN 
            CB-Progress:SCREEN-VALUE = "9".
    ELSE ASSIGN 
            CB-Progress:SCREEN-VALUE = "0".
    ASSIGN 
        CB-Progress
        CB-Repositorio:SCREEN-VALUE = STRING(pc-sistema)
        CB-Repositorio
        .
END.

CASE pc-sistema:
    WHEN 1 THEN DO:
        ASSIGN 
            lvc_DirBase = "C:\_Cnt\_rt-conauto\com"
            vc-diralt   = "C:\_Cnt\conauto\com" + lvc_verDir
            vc-dirbc    = "C:\_Cnt\_rt-conauto" + lvc_verDir + "\com"
            vc-dproy    = "C:\_Cnt\conauto\pry".
        
        CREATE tt-workarea.
        ASSIGN
            tt-workarea.numind = 0   /* ruta raiz */
            tt-workarea.nompry = "Raiz"
            tt-workarea.rut001 = "C:\_Cnt\conauto\src"      /* dir fuentes */
            tt-workarea.rut002 = "C:\_Cnt\conauto\datcom"   /* dir compilador */
            tt-workarea.rut003 = vc-diralt.

        ASSIGN c-win:TITLE = "Compilador sistemas -- (CONAUTO)".
    END.
    WHEN 2 THEN DO:
        ASSIGN 
            lvc_DirBase = "C:\_Cnt\_rt-sofom\com"
            vc-diralt   = "C:\_Cnt\sofom\com" + lvc_verDir
            vc-dirbc    = "C:\_Cnt\_rt-sofom" + lvc_verDir + "\com"
            vc-dproy    = "C:\_Cnt\sofom\pry".
        
        CREATE tt-workarea.
        ASSIGN
            tt-workarea.numind = 0   /* ruta raiz */
            tt-workarea.nompry = "Raiz"
            tt-workarea.rut001 = "C:\_Cnt\sofom\src"      /* dir fuentes */
            tt-workarea.rut002 = "C:\_Cnt\sofom\datcom"   /* dir compilador */
            tt-workarea.rut003 = vc-diralt.

        ASSIGN c-win:TITLE = "Compilador sistemas -- (SOFOM)".
    END.
    WHEN 3 THEN DO:
        ASSIGN 
            lvc_DirBase = "C:\_Cnt\_rt-saadsa\com"
            vc-diralt   = "C:\_Cnt\saadsa\com" + lvc_verDir
            vc-dirbc    = "C:\_Cnt\_rt-saadsa" + lvc_verDir + "\com"
            vc-dproy    = "C:\_Cnt\saadsa\pry".
        
        CREATE tt-workarea.
        ASSIGN
            tt-workarea.numind = 0   /* ruta raiz */
            tt-workarea.nompry = "Raiz"
            tt-workarea.rut001 = "C:\_Cnt\saadsa\src"      /* dir fuentes */
            tt-workarea.rut002 = "C:\_Cnt\saadsa\datcom"   /* dir compilador */
            tt-workarea.rut003 = vc-diralt.

        ASSIGN c-win:TITLE = "Compilador sistemas -- (SAADSA)".
    END.
    WHEN 4 THEN DO:
        ASSIGN 
            lvc_DirBase = "C:\Eventos\Objects"                          /* "C:\_Cnt\_rt-saadsa\com" */
            vc-diralt   = "C:\_Cnt\Eventos-v11\Eventos\Object" + lvc_verDir
            vc-dirbc    = "C:\Eventos\Object"
            vc-dproy    = "C:\_Cnt\eventos-v11\pry".
        
        CREATE tt-workarea.
        ASSIGN
            tt-workarea.numind = 0   /* ruta raiz */
            tt-workarea.nompry = "Raiz"
            tt-workarea.rut001 = "C:\_Cnt\eventos-v11\src"      /* dir fuentes */
            tt-workarea.rut002 = "C:\_Cnt\eventos-v11\datcom"   /* dir compilador */
            tt-workarea.rut003 = vc-diralt.

        ASSIGN c-win:TITLE = "Compilador sistemas -- (Eventos)".
    END.
    OTHERWISE DO:
        /* Detección dinámica y desacoplada basada en configuración (OpenEdge 12.8) */
        ASSIGN 
            vc-dirbc    = "."
            vc-dproy    = "."
            vc-amb01    = ""
            vc-amb02    = ""
            lvc_DirBase = "compilados"
            vc-diralt   = "compilados".
        
        CREATE tt-workarea.
        ASSIGN
            tt-workarea.numind = 0   /* ruta raiz */
            tt-workarea.nompry = "Raiz"
            tt-workarea.rut001 = "src"          /* dir fuentes */
            tt-workarea.rut002 = "config"       /* dir catalogo */
            tt-workarea.rut003 = "compilados".  /* dir compilados */

        ASSIGN c-win:TITLE = "Compilador Progress OpenEdge 12.8 -- (Workspace)".
    END.
END CASE.

DISPLAY
    vl-est
    vl-fte
    WITH FRAME fr-frm01.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Carga-Compilados C-Win 
PROCEDURE Carga-Compilados :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE VARIABLE vc-rutco AS CHARACTER  NO-UNDO.
DEFINE VARIABLE vi-err   AS INTEGER    NO-UNDO.

FIND tt-workarea
    WHERE tt-workarea.numind = vi-proy NO-LOCK NO-ERROR.
RUN crea-directorio(tt-workarea.rut002 + "\", OUTPUT vi-err).

ASSIGN vc-rutco = SUBSTITUTE("&1\compilador.csv",tt-workarea.rut002).

IF SEARCH(vc-rutco) = ? THEN DO:
    /* Localiza el compilador.csv de Producción */
    FIND tt-workarea
        WHERE tt-workarea.numind = 0 NO-LOCK NO-ERROR.
    RUN crea-directorio(tt-workarea.rut002 + "\", OUTPUT vi-err).
    ASSIGN vc-rutco = SUBSTITUTE("&1\compilador.csv",tt-workarea.rut002).
END.

IF SEARCH(vc-rutco) = ? THEN DO:
    OUTPUT TO VALUE(vc-rutco).
    OUTPUT CLOSE.
END.
ELSE DO:
    EMPTY TEMP-TABLE tt-pcomp    NO-ERROR.

    INPUT FROM VALUE(vc-rutco).
    REPEAT:
        CREATE tt-pcomp.
        IMPORT DELIMITER "|"
            tt-pcomp.nomprog
            tt-pcomp.tipoprg
            tt-pcomp.rutaprg.
    END.
    INPUT CLOSE.
  
    FOR EACH tt-pcomp:
        ASSIGN 
            tt-pcomp.rutaprg = REPLACE(tt-pcomp.rutaprg,lvc_DirBase,vc-dirbc).
        IF tt-pcomp.nompro = "" THEN DO:
            DELETE tt-pcomp.
            NEXT.
        END.
        IF tt-pcomp.tipoprg <> "R" THEN DO:
            DELETE tt-pcomp.
            NEXT.
        END.
    END.
    FOR EACH tt-temp
        WHERE TRIM(tt-temp.tx-linea) = "":
        DELETE tt-temp.
    END.
END.

/* corrige rutas que no terminen con "\" y lo coloca al final */
FOR EACH tt-pcomp:
  IF SUBSTRING(tt-pcomp.rutaprg,LENGTH(tt-pcomp.rutaprg),1) <> "\" THEN DO:
    ASSIGN tt-pcomp.rutaprg = TRIM(tt-pcomp.rutaprg) + "\".
  END.
END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Carga-Fuentes C-Win 
PROCEDURE Carga-Fuentes :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEF VAR vi-to     AS INT  NO-UNDO.
DEF VAR vc-ruta   AS CHAR NO-UNDO.
DEF VAR vc-ruta01 AS CHAR NO-UNDO.
DEF VAR vc-ruta02 AS CHAR NO-UNDO.
DEF VAR vi-i      AS INT  NO-UNDO.
DEF VAR vc-ultima AS CHAR NO-UNDO.
DEF VAR vl-error  AS LOG  NO-UNDO.

FIND tt-workarea
  WHERE tt-workarea.numind = vi-proy
  NO-LOCK NO-ERROR.

ASSIGN vc-ruta = SUBSTITUTE("dir /b /s &1",tt-workarea.rut001).

INPUT THROUGH VALUE(vc-ruta).

EMPTY TEMP-TABLE tt-temp NO-ERROR.

REPEAT:
  CREATE tt-temp.
  IMPORT UNFORMATTED tt-temp.tx-linea.
END.
INPUT CLOSE.

FOR EACH tt-temp
  WHERE TRIM(tt-temp.tx-linea) = "":
  DELETE tt-temp.
END.

EMPTY TEMP-TABLE tt-pfuentes NO-ERROR.
FOR EACH tt-temp:

  file-info:FILE-NAME = trim(tt-temp.tx-linea).
    /* Reglas desacopladas (RulesEngine: exclusión estricta de util y filtro de extensiones .p, .w, .cls) */
    DEFINE VARIABLE vl-comp-src AS LOGICAL   NO-UNDO.
    DEFINE VARIABLE vc-rsn-src  AS CHARACTER NO-UNDO.

    IF tx-linea MATCHES "*.wrx" THEN DO:
        /* Permitir archivos de recursos gráficos wrx */
    END.
    ELSE DO:
        RUN isCompilable (TRIM(tt-temp.tx-linea), OUTPUT vl-comp-src, OUTPUT vc-rsn-src).
        IF NOT vl-comp-src THEN NEXT.
    END.

    CREATE tt-pfuentes.
    ASSIGN vi-to = R-INDEX(tt-temp.tx-linea,"\",LENGTH(tt-temp.tx-linea)).
    ASSIGN nomprog = TRIM(SUBSTRING(tx-linea,(vi-to + 1),LENGTH(tx-linea))).
    IF NUM-ENTRIES(nomprog,".") = 2 THEN DO:
      ASSIGN tipoprg = TRIM(ENTRY(2,nomprog,".")).
      ASSIGN nomprog = TRIM(ENTRY(1,nomprog,".")).
    END.
    ELSE DO:
    END.
    ASSIGN 
      rutaprg = trim(SUBSTRING(tx-linea,1,vi-to))
      tamano  = FILE-INFO:FILE-SIZE.
  END.
END.

FOR EACH tt-pfuentes
  NO-LOCK:

  ASSIGN vl-error = FALSE.
  IF vi-proy = 0 THEN DO:  /* solo si NO es proyecto valida */
    DO vi-i = 1 TO NUM-ENTRIES(vc-liserr,","):
      ASSIGN vc-ultima = ENTRY(vi-i,vc-liserr,",").
      IF tt-pfuentes.rutaprg MATCHES SUBSTITUTE("*&1*",vc-ultima) THEN DO:
        ASSIGN vl-error = TRUE.
        LEAVE.
      END.
    END.
    IF vl-error THEN DO:
      DELETE tt-pfuentes.
      NEXT.
    END.
  END.

  CASE tipoprg:
    WHEN "W" OR WHEN "P" OR WHEN "CLS" OR WHEN "wrx" THEN DO:
      NEXT.
    END.
    OTHERWISE DO:
      DELETE tt-pfuentes.
    END.
  END CASE.
END.

EMPTY TEMP-TABLE tt-propath NO-ERROR.

FOR EACH tt-pfuentes
  NO-LOCK:

  ASSIGN vc-ruta01 = ENTRY(1,tt-pfuentes.rutaprg,"\").
  DO vi-i = 2 TO NUM-ENTRIES(tt-pfuentes.rutaprg,"\") - 1:
    ASSIGN vc-ruta01 = SUBSTITUTE("&1\&2",vc-ruta01,ENTRY(vi-i,tt-pfuentes.rutaprg,"\")).
    FIND tt-propath
      WHERE tt-propath.rutapro = vc-ruta01
      NO-ERROR.
    IF NOT AVAILABLE tt-propath THEN DO:
      CREATE tt-propath.
      ASSIGN tt-propath.rutapro = vc-ruta01.
    END.
  END.
END.

RUN Carga-por-compilar.

/* carga estructura del proyecto */
RUN CargaEstPry.

/* sincroniza estructuras */
RUN Sinc-Estructura.

/* verifica rutas */
RUN Verifica-Ruta.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Carga-por-compilar C-Win 
PROCEDURE Carga-por-compilar :
/*-----------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
-----------------------------------------------------------------------------*/
DEFINE VARIABLE lvi_Progs AS INTEGER    NO-UNDO.
EMPTY TEMP-TABLE tt-progs NO-ERROR.

FOR EACH tt-pfuentes
    WHERE (tt-pfuentes.tipoprg = "W" OR tt-pfuentes.tipoprg = "P" OR tt-pfuentes.tipoprg = "CLS") NO-LOCK:
    CREATE tt-progs.
    BUFFER-COPY tt-pfuentes TO tt-progs.
    ASSIGN tt-progs.progsel = FALSE.
END.

EMPTY TEMP-TABLE tt-rutas NO-ERROR.

FOR EACH tt-progs NO-LOCK:
    ASSIGN 
        lvi_Progs = lvi_Progs + 1
        FILL-Progs:SCREEN-VALUE IN FRAME {&FRAME-NAME} = STRING(lvi_Progs).
    FOR EACH tt-pcomp WHERE tt-pcomp.nomprog = tt-progs.nomprog NO-LOCK:
        FIND FIRST tt-rutas
            WHERE tt-rutas.nomprog = tt-pcomp.nomprog
            AND   tt-rutas.tipoprg = tt-pcomp.tipoprg
            AND   tt-rutas.rutades = tt-pcomp.rutaprg
            NO-LOCK NO-ERROR.
        IF NOT AVAILABLE tt-rutas THEN DO:
            CREATE tt-rutas.
            ASSIGN
                tt-rutas.nomprog = tt-pcomp.nomprog
                tt-rutas.tipoprg = tt-pcomp.tipoprg
                tt-rutas.rutades = tt-pcomp.rutaprg.

            /* Producción */
            ASSIGN tt-rutas.rutaalt = REPLACE(tt-pcomp.rutaprg,vc-dircom,vc-diralt).

        END.
    END.
END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE CargaEstPry C-Win 
PROCEDURE CargaEstPry :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEFINE VARIABLE vc-rutco AS CHARACTER  NO-UNDO.
DEFINE VARIABLE vi-err   AS INTEGER    NO-UNDO.

FIND tt-workarea
    WHERE tt-workarea.numind = vi-proy NO-LOCK NO-ERROR.
RUN crea-directorio(tt-workarea.rut002 + "\", OUTPUT vi-err).

ASSIGN vc-rutco = SUBSTITUTE("&1\compilador.csv",tt-workarea.rut002).

IF SEARCH(vc-rutco) = ? THEN DO:
    RUN crea-directorio(tt-workarea.rut002 + "\", OUTPUT vi-err).
END.

IF SEARCH(vc-rutco) = ? THEN DO:
    OUTPUT TO VALUE(vc-rutco).
    OUTPUT CLOSE.
END.
ELSE DO:
    EMPTY TEMP-TABLE tt-pcmppry NO-ERROR.

    INPUT FROM VALUE(vc-rutco).
    REPEAT:
        CREATE tt-pcmppry.
        IMPORT DELIMITER "|"
            tt-pcmppry.nomprog
            tt-pcmppry.tipoprg
            tt-pcmppry.rutaprg.
    END.
    INPUT CLOSE.
  
    FOR EACH tt-pcmppry:
        ASSIGN 
            tt-pcmppry.rutaprg = REPLACE(tt-pcmppry.rutaprg,lvc_DirBase,vc-dirbc).
        IF tt-pcmppry.nompro = "" THEN DO:
            DELETE tt-pcmppry.
            NEXT.
        END.
        IF tt-pcmppry.tipoprg <> "R" THEN DO:
            DELETE tt-pcmppry.
            NEXT.
        END.
    END.
    FOR EACH tt-temp
        WHERE TRIM(tt-temp.tx-linea) = "":
        DELETE tt-temp.
    END.
END.

/* corrige rutas que no terminen con "\" y lo coloca al final */
FOR EACH tt-pcmppry:
  IF SUBSTRING(tt-pcmppry.rutaprg,LENGTH(tt-pcmppry.rutaprg),1) <> "\" THEN DO:
    ASSIGN tt-pcmppry.rutaprg = TRIM(tt-pcmppry.rutaprg) + "\".
  END.
END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE CargaProyectos C-Win 
PROCEDURE CargaProyectos :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEF VAR vc-linea AS CHAR NO-UNDO.
DEF VAR vc-lista AS CHAR NO-UNDO.
DEF VAR vc-cmd   AS CHAR NO-UNDO.
DEF VAR vi-ind   AS INT  NO-UNDO.

EMPTY TEMP-TABLE tt-temp NO-ERROR.

ASSIGN vc-cmd = SUBSTITUTE("CMD.EXE /C DIR &1 /A:D /B",vc-dproy).

INPUT THROUGH VALUE(vc-cmd) NO-ECHO.

REPEAT:
  CREATE tt-temp.
  IMPORT UNFORMATTED tt-temp.tx-linea.
END.

INPUT CLOSE.

ASSIGN 
  vc-lista = "Src,0"
  vi-ind   = 0.


FOR EACH tt-workarea:
  IF tt-workarea.numind <> 0 THEN DO:
    DELETE tt-workarea.
    NEXT.
  END.
END.

FOR EACH tt-temp:
  IF tt-temp.tx-linea = "" THEN DO:
    DELETE tt-temp.
    NEXT.
  END.
  ASSIGN vi-ind = vi-ind + 1.
  ASSIGN vc-lista = SUBSTITUTE("&1,&2,&3",vc-lista,TRIM(tx-linea),vi-ind).
  CREATE tt-workarea.
  ASSIGN
    tt-workarea.numind = vi-ind
    tt-workarea.nompry = TRIM(tx-linea)
    tt-workarea.rut001 = SUBSTITUTE("&1\&2\src",TRIM(vc-dproy),TRIM(tx-linea))
    tt-workarea.rut002 = SUBSTITUTE("&1\&2\datcom",TRIM(vc-dproy),TRIM(tx-linea))
    tt-workarea.rut003 = SUBSTITUTE("&1\&2\com",TRIM(vc-dproy),TRIM(tx-linea)).
END.

DO WITH FRAME fr-frm01:
  ASSIGN vi-proy:LIST-ITEM-PAIRS = vc-lista.
END.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Cifras C-Win 
PROCEDURE Cifras :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
ASSIGN
  fill-progs = 0
  lvi_xcomp = 0
  lvi_sinruta = 0.

FOR EACH tt-progs
  NO-LOCK:
  ASSIGN fill-progs = fill-progs + 1. 

  IF tt-progs.sinruta THEN DO:
    ASSIGN lvi_sinruta = lvi_sinruta + 1.
  END.

  IF tt-progs.progsel THEN DO:
    ASSIGN lvi_xcomp = lvi_xcomp + 1.
  END.
END.

DISPLAY
  fill-progs
WITH FRAME fr-frm01.

ASSIGN
  fill-xcomp:SCREEN-VALUE = STRING(lvi_xcomp)
  fill-sinruta:SCREEN-VALUE = STRING(lvi_sinruta).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Compila-Programas C-Win 
PROCEDURE Compila-Programas :
/*-----------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
-----------------------------------------------------------------------------*/
DEFINE VARIABLE vi-err      AS INTEGER    NO-UNDO.
DEFINE VARIABLE vl-error    AS LOGICAL    NO-UNDO.
DEFINE VARIABLE lvi_conta   AS INTEGER    NO-UNDO.
DEFINE VARIABLE lvi_Errores AS INTEGER    NO-UNDO.
DEFINE VARIABLE lvi_Compila AS INTEGER    NO-UNDO.

DEFINE VARIABLE lvi_Cont    AS INTEGER    NO-UNDO.
DEFINE VARIABLE lvi_Ptr     AS INTEGER    NO-UNDO.
DEFINE VARIABLE lvc_Ruta    AS CHARACTER  NO-UNDO.
DEFINE VARIABLE lvi_RowMax  AS INTEGER    NO-UNDO.
DEFINE VARIABLE lvi_RenBrow AS INTEGER    NO-UNDO.
DEFINE VARIABLE lvr_recid   AS RECID      NO-UNDO.
DEFINE VARIABLE lvr_rowid   AS ROWID      NO-UNDO.

DEFINE VARIABLE lvl_Compila AS LOGICAL    NO-UNDO.
DEFINE VARIABLE lvc_Paso    AS CHARACTER  NO-UNDO.
DEFINE VARIABLE lvl_Conecta AS LOGICAL    NO-UNDO.

/***** NUEVO PROCESO *****/
FOR EACH tt-Progs WHERE tt-Progs.ProgSel NO-LOCK:
    ASSIGN lvi_cont = lvi_cont + 1.
END.
APPLY "ENTRY":U TO Btn-Stop IN FRAME {&FRAME-NAME}.

ASSIGN 
    lvl_Stop     = FALSE
    lvi_RowMax   = br-brow01:DOWN IN FRAME {&FRAME-NAME}
    lvi_RenBrow  = 0
    /*BARRA:MAX    = lvi_cont*/
    lvi_Ptr      = 0.           

/* Inicializar BuildLogger y vincular compila02.w si está activo */
IF VALID-HANDLE(vc-handle) THEN
    RUN setLogListener (vc-handle).
RUN initBuildLogger ("", PROPATH, (IF AVAILABLE tt-workarea THEN tt-workarea.rut003 ELSE "compilados")).

OPEN QUERY br-brow01
  FOR EACH tt-progs
  WHERE tt-progs.progsel = TRUE
  NO-LOCK.
APPLY "home" TO br-brow01.
APPLY "value-changed" TO br-brow01.
ASSIGN vc-buscar = "".
DISPLAY vc-buscar WITH FRAME fr-frm01.

GET FIRST br-brow01 NO-LOCK.
Todo:
REPEAT: 
    IF NOT AVAILABLE tt-progs THEN LEAVE.
    IF tt-progs.progsel THEN DO:
        IF lvi_RenBrow >= lvi_RowMax THEN ASSIGN lvi_RenBrow = 1.
        ELSE ASSIGN lvi_RenBrow = lvi_RenBrow + 1. 

        ASSIGN lvr_recid = RECID(tt-progs).
        IF lvi_RenBrow  = 1 THEN 
            ASSIGN lvl_stat = br-brow01:SET-REPOSITIONED-ROW(lvi_RenBrow,"ALWAYS").
        ELSE ASSIGN lvl_stat = br-brow01:SET-REPOSITIONED-ROW(lvi_RenBrow,"CONDITIONAL").

        REPOSITION br-brow01 TO RECID lvr_recid NO-ERROR.
        ASSIGN 
            lvl_stat = br-brow01:SELECT-FOCUSED-ROW()
            lvi_Ptr = lvi_Ptr + 1.
        
        /* >>>>>>>>>> <<<<<<<<<<*/
        FOR EACH tt-Compila
            WHERE tt-Compila.NomProg = tt-Progs.NomProg
              AND tt-Compila.TipoPrg = tt-Progs.TipoPrg NO-LOCK:

            /*Crea carpeta en RT*/
            RUN crea-directorio(INPUT tt-compila.rutades, OUTPUT vi-err).
            IF vi-err <> 0 THEN DO:
                ASSIGN 
                    lvi_Errores = lvi_Errores + 1
                    Fill-Errores:SCREEN-VALUE IN FRAME {&FRAME-NAME} = 
                    STRING(lvi_Errores).
                GET NEXT br-brow01 NO-LOCK.
            END.

            /*Crea carpeta de ruta alterna*/
            RUN crea-directorio(INPUT tt-compila.rutaalt, OUTPUT vi-err).
            IF vi-err <> 0 THEN DO:
                ASSIGN 
                    lvi_Errores = lvi_Errores + 1
                    Fill-Errores:SCREEN-VALUE IN FRAME {&FRAME-NAME} = 
                    STRING(lvi_Errores).
                GET NEXT br-brow01 NO-LOCK.
            END.

        END. /*FOR EACH tt-Compila*/
    
        PROCESS EVENTS.
        IF KEYFUNCTION(LASTKEY) = "Q" OR KEYFUNCTION(LASTKEY) = "q" THEN DO:
            MESSAGE "¿Desea Cancelar la Compilación?"
                VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO 
                TITLE "¡ ATENCION !" UPDATE lvl_Stop .
        END.
        IF lvl_Stop THEN LEAVE Todo.
        ASSIGN lvi_conta = lvi_conta + 1.
        HIDE MESSAGE NO-PAUSE.

        FOR EACH tt-Compila 
            WHERE tt-Compila.NomProg = tt-Progs.NomProg
              AND tt-Compila.TipoPrg = tt-Progs.TipoPrg NO-LOCK:
            RUN Crea-Compilados (OUTPUT vl-error).
            MESSAGE TRIM(STRING(lvi_conta,">>,>>9")) + " " + 
                tt-compila.nomprog + "/" + tt-Compila.RutaDes.
        END.

        DO TRANSACTION:
            FIND CURRENT tt-progs EXCLUSIVE-LOCK NO-ERROR.
            IF vl-error THEN DO:
                IF AVAILABLE tt-progs THEN DO:
                    ASSIGN 
                        tt-progs.sterror = "Error"
                        lvi_Errores = lvi_Errores + 1
                        Fill-Errores:SCREEN-VALUE IN FRAME {&FRAME-NAME} = 
                        STRING(lvi_Errores).
                END.
                GET NEXT br-brow01 NO-LOCK.
            END.
            IF AVAILABLE tt-progs THEN DO:
                ASSIGN
                    lvi_Compila = lvi_Compila + 1
                    tt-progs.sterror = ""
                    Fill-Compila:SCREEN-VALUE IN FRAME {&FRAME-NAME} = 
                    STRING(lvi_Compila).
            END.
        END.
        ASSIGN lvl_stat = br-brow01:REFRESH().
        PROCESS EVENTS.
        IF lvl_Stop = TRUE THEN DO:
            MESSAGE "Esta Seguro de Detener el Proceso de Compilación?? "
                VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO UPDATE lvl_Stop.
            IF lvl_Stop = TRUE THEN LEAVE.
        END.                                       
    END.
    GET NEXT br-brow01 NO-LOCK.
END. /*DEL REPEAT*/

/* Generar reporte estructurado de compilación final */
DEFINE VARIABLE vc-report-build AS CHARACTER NO-UNDO.
ASSIGN vc-report-build = "build/logs/build_" + 
                         STRING(YEAR(TODAY), "9999") + 
                         STRING(MONTH(TODAY), "99") + 
                         STRING(DAY(TODAY), "99") + "_" + 
                         STRING(TIME, "99999") + ".log".
OS-CREATE-DIR "build/logs".
RUN writeBuildReport (vc-report-build).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Copia-Archivos C-Win 
PROCEDURE Copia-Archivos :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    DEFINE VARIABLE vc-arcori AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE vc-arcdes AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE vi-err    AS INTEGER    NO-UNDO.
    DEFINE VARIABLE lvc_cmd   AS CHARACTER  NO-UNDO.

    FOR EACH tt-compila WHERE tipoprg = "WRX" NO-LOCK:
        RUN crea-directorio(INPUT tt-compila.rutades, OUTPUT vi-err).
        IF vi-err <> 0 THEN DO:
            NEXT.
        END.
        ASSIGN 
            vc-arcori   = SUBSTITUTE("&1&2.&3",
                                   tt-compila.rutaprg,
                                   tt-compila.nomprog,
                                   tt-compila.tipoprg)
            vc-arcdes   = SUBSTITUTE("&1&2.&3",
                                   tt-compila.rutades,
                                   tt-compila.nomprog,
                                   tt-compila.tipoprg)
            lvc_msg     = "Copiando Archivo: " + vc-arcori + " EN " + 
            vc-arcdes.
        RUN Bitacora(INPUT lvc_msg).
        OS-COPY VALUE(vc-arcori) VALUE(vc-arcdes).
        IF OS-ERROR > 0 THEN DO:
            ASSIGN 
                lvc_msg = "ERROR al copiar archivo " + vc-arcori + " " +
                STRING(OS-ERROR).
        END.
        /* Copiar WRX a Ruta Alterna */
        ASSIGN 
            vc-arcdes = SUBSTITUTE("&1&2.&3",
                                   tt-compila.rutaalt,
                                   tt-compila.nomprog,
                                   tt-compila.tipoprg)
            lvc_msg   = "Copiando Archivo: " + vc-arcori + " EN " + 
            vc-arcdes.
        RUN Bitacora(INPUT lvc_msg).
        OS-COPY VALUE(vc-arcori) VALUE(vc-arcdes).
        IF OS-ERROR > 0 THEN DO:
            ASSIGN 
                lvc_msg = "ERROR al copiar archivo " + vc-arcori + " " +
                STRING(OS-ERROR).
        END.
END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Copia-wrx C-Win 
PROCEDURE Copia-wrx :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    EMPTY TEMP-TABLE tt-compila NO-ERROR.
    ASSIGN lvi_Conta = 0.
    FOR EACH tt-progs
        WHERE tt-progs.progsel = TRUE NO-LOCK:
        FIND tt-pfuentes 
            WHERE tt-pfuentes.nomprog = tt-progs.nomprog
              AND tt-pfuentes.tipoprg = "WRX" NO-LOCK NO-ERROR.
        IF NOT AVAILABLE tt-pfuentes THEN DO:
            NEXT.
        END.
        FOR EACH tt-rutas
            WHERE tt-rutas.nomprog = tt-progs.nomprog NO-LOCK:
            CREATE tt-compila.
            BUFFER-COPY tt-progs TO tt-compila
                ASSIGN tt-Compila.TipoPrg = tt-pFuentes.TipoPrg.
            ASSIGN 
                lvi_Conta = lvi_Conta + 1
                tt-compila.rutaalt = tt-rutas.rutaalt
                tt-compila.rutades = tt-rutas.rutades.
        END.
    END.
    RUN Copia-Archivos.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Crea-Compilados C-Win 
PROCEDURE Crea-Compilados :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEF OUTPUT PARAMETER pl-error AS LOG.

DEFINE VARIABLE vi-i       AS INTEGER     NO-UNDO.
DEFINE VARIABLE lvc_Linea  AS CHARACTER   NO-UNDO.
DEFINE VARIABLE v-sn       AS LOGICAL     NO-UNDO.
DEFINE VARIABLE v-programa AS CHARACTER   NO-UNDO.
DEFINE VARIABLE iError     AS INTEGER     NO-UNDO.
DEFINE VARIABLE vc-error   AS CHARACTER   NO-UNDO.
DEFINE VARIABLE vc-cmd     AS CHARACTER   NO-UNDO.
DEFINE VARIABLE vc-cmd1    AS CHARACTER   NO-UNDO.

FILE-INFO:FILE-NAME = ".".

ASSIGN V-PROGRAMA = SUBSTITUTE("&1&2.&3",
                               tt-compila.rutaprg,
                               tt-compila.nomprog,
                               tt-compila.tipoprg).

ASSIGN vc-cmd = SUBSTITUTE("copy &1&2.r &3",
                           tt-compila.rutades,
                           tt-compila.nomprog,
                           tt-compila.rutaalt).

/*Si es un proyecto, que lo deje en la ruta original del programa*/
ASSIGN vc-cmd1 = SUBSTITUTE("copy &1&2.r &3",
                            tt-compila.rutades,
                            tt-compila.nomprog,
                            tt-compila.rutaprg).

ASSIGN vc-error = "".
    /* SEPARACION DE BUILD Y DEPLOY MEDIANTE STAGING (OE 12.8) */
    DEFINE VARIABLE vc-stg-dir   AS CHARACTER NO-UNDO INITIAL "build/staging".
    DEFINE VARIABLE vl-build-ok  AS LOGICAL   NO-UNDO.
    DEFINE VARIABLE vc-build-msg AS CHARACTER NO-UNDO.

    IF tt-compila.rutades = "" OR tt-compila.rutades = ? THEN DO:
        RUN Bitacora(INPUT "NO COMPILA: Ruta destino no especificada para " + V-PROGRAMA).
        ASSIGN pl-error = TRUE.
        RETURN.
    END.

    /* Compila primero a staging y despliega a rutades unicamente si la compilacion es exitosa */
    RUN compileSingleFile (V-PROGRAMA, vc-stg-dir, tt-compila.rutades, OUTPUT vl-build-ok, OUTPUT vc-build-msg).

    IF NOT vl-build-ok THEN DO:
        ASSIGN pl-error = TRUE
               lvc_Linea = "Error de compilacion en: " + V-PROGRAMA + " - " + vc-build-msg.
        RUN Bitacora(INPUT lvc_Linea).
        IF VALID-HANDLE(vc-handle) THEN
            RUN CargaMensaje IN vc-handle (lvc_Linea).
        
        OUTPUT TO VALUE(vc-logcomp) APPEND.
        PUT UNFORMATTED lvc_Linea SKIP.
        OUTPUT CLOSE.
    END.
    ELSE DO:
        ASSIGN pl-error = FALSE.
        RUN Bitacora(INPUT "OK: " + V-PROGRAMA + " compilado en staging y desplegado en " + tt-compila.rutades).

        /* copia a ruta alterna solo si la compilacion tuvo exito */
        IF vc-dirfte <> vc-diralt AND tg-dir-alt THEN DO:
            ASSIGN lvc_Linea = vc-cmd.
            RUN Bitacora(INPUT lvc_Linea).
            OS-COMMAND SILENT VALUE(vc-cmd).
        END.

        /* Si es proyecto copia el compilado en la ruta original solo si tuvo exito */
        IF vi-proy <> 0 THEN DO:
           ASSIGN lvc_Linea = vc-cmd1.
           RUN Bitacora(INPUT lvc_Linea).
           OS-COMMAND SILENT VALUE(vc-cmd1).
        END.
    END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Crea-Directorio C-Win 
PROCEDURE Crea-Directorio :
/*-----------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
-----------------------------------------------------------------------------*/
    DEFINE INPUT  PARAMETER ipc_RutaDes AS CHARACTER  NO-UNDO.
    DEFINE OUTPUT PARAMETER opi_Error   AS INTEGER    NO-UNDO.
    
    DEFINE VARIABLE lvc_Ruta01  AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE lvc_Ruta02  AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE lvi_ptr       AS INTEGER    NO-UNDO.
    
    ASSIGN 
        FILE-INFO:FILE-NAME = ipc_RutaDes
        lvc_Ruta01 = ENTRY(1,ipc_RutaDes,"\")
        opi_Error = 0.
    
    IF FILE-INFO:FULL-PATHNAME <> ? THEN DO:
        RETURN.
    END.
    
    DO lvi_ptr = 2 TO NUM-ENTRIES(ipc_RutaDes,"\"):
        ASSIGN 
            lvc_Ruta01 = SUBSTITUTE("&1\&2",lvc_Ruta01,
                                   ENTRY(lvi_ptr,ipc_RutaDes,"\"))
            lvc_Ruta02 = SUBSTITUTE("&1\&2",lvc_Ruta01,"nul")
            FILE-INFO:FILE-NAME = lvc_Ruta01.
    
        IF FILE-INFO:FULL-PATHNAME EQ ? THEN DO:
            OS-CREATE-DIR VALUE(lvc_Ruta01).
            ASSIGN opi_Error = OS-ERROR.
            IF opi_Error NE 0 THEN DO:
                ASSIGN
                    lvc_Msg = "El directorio &1 no pudo ser creado. " + 
                              "Error de sistema numero # &2"
                    lvc_Msg = SUBSTITUTE(lvc_Msg, lvc_Ruta02, opi_Error).
                RUN Bitacora(INPUT lvc_Msg).
            END.
        END.
    END.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Crea-Propath C-Win 
PROCEDURE Crea-Propath :
/*------------------------------------------------------------------------------
  Purpose: Construcción determinística de PROPATH mediante PropathManager (OE 12.8)
  Parameters:  <none>
  Notes: Elimina duplicados, normaliza rutas y preserva precedencia.
------------------------------------------------------------------------------*/
DEFINE VARIABLE vc-candidate-pp AS CHARACTER NO-UNDO.
DEFINE VARIABLE vc-eff-pp       AS CHARACTER NO-UNDO.

ASSIGN vc-candidate-pp = PROPATH.

FOR EACH tt-propath NO-LOCK BY tt-propath.rutapro DESC:
    IF tt-propath.rutapro > "" THEN
        ASSIGN vc-candidate-pp = (IF vc-candidate-pp > "" THEN vc-candidate-pp + "," ELSE "") + tt-propath.rutapro.
END.

IF vc-amb01 > "" THEN
    ASSIGN vc-candidate-pp = (IF vc-candidate-pp > "" THEN vc-candidate-pp + "," ELSE "") + vc-amb01.

IF vc-amb02 > "" THEN
    ASSIGN vc-candidate-pp = (IF vc-candidate-pp > "" THEN vc-candidate-pp + "," ELSE "") + vc-amb02.

RUN getEffectivePropath (vc-candidate-pp, NO, OUTPUT vc-eff-pp).

IF vc-eff-pp > "" THEN
    ASSIGN PROPATH = vc-eff-pp.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI C-Win  _DEFAULT-DISABLE
PROCEDURE disable_UI :
/*------------------------------------------------------------------------------
  Purpose:     DISABLE the User Interface
  Parameters:  <none>
  Notes:       Here we clean-up the user-interface by deleting
               dynamic widgets we have created and/or hide 
               frames.  This procedure is usually called when
               we are ready to "clean-up" after running.
------------------------------------------------------------------------------*/
  /* Delete the WINDOW we created */
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(C-Win)
  THEN DELETE WIDGET C-Win.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI C-Win  _DEFAULT-ENABLE
PROCEDURE enable_UI :
/*------------------------------------------------------------------------------
  Purpose:     ENABLE the User Interface
  Parameters:  <none>
  Notes:       Here we display/view/enable the widgets in the
               user-interface.  In addition, OPEN all queries
               associated with each FRAME and BROWSE.
               These statements here are based on the "Other 
               Settings" section of the widget Property Sheets.
------------------------------------------------------------------------------*/
  DISPLAY vi-proy vl-est vl-fte vc-buscar CB-Repositorio CB-Progress FILL-Progs 
          tg-dir-alt FILL-SinRuta FILL-xComp FILL-Errores FILL-Compila vc-dirfte 
          vc-dircom vc-diralt 
      WITH FRAME fr-frm01 IN WINDOW C-Win.
  ENABLE RECT-3 RECT-4 RECT-6 RECT-7 vi-proy bt-cargacomp bt-cargaftes 
         vc-buscar br-brow01 bt-comtodos bt-crear bt-editar bt-eliminar 
         bt-crear-2 btnSelall btnQuitar Btn-Stop bt-verlog FILL-Progs 
         tg-dir-alt FILL-SinRuta br-brow02 FILL-xComp FILL-Errores FILL-Compila 
         bt-salir 
      WITH FRAME fr-frm01 IN WINDOW C-Win.
  {&OPEN-BROWSERS-IN-QUERY-fr-frm01}
  DISPLAY vc-nomprog vc-newpat 
      WITH FRAME fr-frm03 IN WINDOW C-Win.
  ENABLE RECT-5 vc-newpat bt-aceptar-3 bt-cancelar-3 
      WITH FRAME fr-frm03 IN WINDOW C-Win.
  {&OPEN-BROWSERS-IN-QUERY-fr-frm03}
  DISPLAY vc-archivo 
      WITH FRAME fr-frm02 IN WINDOW C-Win.
  ENABLE vc-archivo bt-aceptar-2 bt-cancelar-2 
      WITH FRAME fr-frm02 IN WINDOW C-Win.
  {&OPEN-BROWSERS-IN-QUERY-fr-frm02}
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Genera-Por-Compilar C-Win 
PROCEDURE Genera-Por-Compilar :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
EMPTY TEMP-TABLE tt-compila NO-ERROR.

DEFINE VARIABLE vl-v6frame AS LOGICAL     NO-UNDO.

FOR EACH tt-progs
    WHERE tt-progs.progsel = TRUE NO-LOCK:
    FOR EACH tt-rutas
        WHERE tt-rutas.nomprog = tt-progs.nomprog
        NO-LOCK:
        CREATE tt-compila.
        BUFFER-COPY tt-progs TO tt-compila.
        ASSIGN 
            tt-compila.rutades = tt-rutas.rutades
            tt-compila.rutaalt = tt-rutas.rutaalt.

        /* Validación de reglas desacoplada (OpenEdge 12.8, extensiones .p, .w, .cls y exclusión de util) */
        DEFINE VARIABLE vl-compilable AS LOGICAL   NO-UNDO.
        DEFINE VARIABLE vc-rule-rsn   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE vc-rule-opts  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE vc-rule-nts   AS CHARACTER NO-UNDO.

        RUN isCompilable (tt-progs.rutaprg + tt-progs.nomprog + '.' + tt-progs.tipoprg, 
                          OUTPUT vl-compilable, OUTPUT vc-rule-rsn).
        IF NOT vl-compilable THEN NEXT.

        ASSIGN vl-v6frame = NO.
        RUN getCompileOptions (tt-progs.rutaprg + tt-progs.nomprog + '.' + tt-progs.tipoprg, 
                               OUTPUT vc-rule-opts, OUTPUT vc-rule-nts).
        IF LOOKUP("V6FRAME", vc-rule-opts, " ") > 0 THEN
            ASSIGN vl-v6frame = YES.

        IF (INDEX(tt-compila.rutades,"Afin")  <> 0  OR 
            INDEX(tt-compila.rutades,"Admon") <> 0) AND 
            tt-progs.tipoprg = 'P' OR
            vl-v6frame THEN DO:

           ASSIGN tt-compila.dispv6p = TRUE.

        END.
    END.
END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Limpia-Temporales C-Win 
PROCEDURE Limpia-Temporales :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    EMPTY TEMP-TABLE tt-pfuentes NO-ERROR.
    EMPTY TEMP-TABLE tt-progs    NO-ERROR.
    EMPTY TEMP-TABLE tt-rutas    NO-ERROR.
    EMPTY TEMP-TABLE tt-propath  NO-ERROR.
    EMPTY TEMP-TABLE tt-compila  NO-ERROR.
    IF lvl_SelTodo THEN DO:
        ASSIGN 
            lvl_SelTodo = NO
            btnSelAll:LABEL IN FRAME {&FRAME-NAME} = "Selec. Todo".
    END.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Limpia-Var C-Win 
PROCEDURE Limpia-Var :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
ASSIGN
  vc-buscar = ""
  fill-progs = 0
  fill-xcomp = 0
  fill-sinruta = 0
  fill-errores = 0
  fill-compila = 0.

DISPLAY
    vl-est
    vl-fte
    vc-buscar
    fill-progs
    fill-xcomp
    fill-sinruta
    fill-errores
    fill-compila
WITH FRAME fr-frm01.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Quita-Seleccion C-Win 
PROCEDURE Quita-Seleccion :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEF VAR vi-i AS INT. 
DEF VAR vh-brow01 AS HANDLE NO-UNDO.

DO WITH FRAME fr-frm01:
END.

ASSIGN vh-brow01 = QUERY br-brow01:HANDLE IN FRAME fr-frm01.

vh-brow01:GET-FIRST(NO-LOCK) NO-ERROR.
DO WHILE (vh-brow01:QUERY-OFF-END = NO):
  ASSIGN tt-progs.progsel = FALSE.
  vh-brow01:GET-NEXT(NO-LOCK) NO-ERROR.
END.

RUN Cifras.

vl-sn = br-brow01:REFRESH().

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Selecciona-Filtrados C-Win 
PROCEDURE Selecciona-Filtrados :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEF VAR vi-i AS INT. 
DEF VAR vh-brow01 AS HANDLE NO-UNDO.

DO WITH FRAME fr-frm01:
END.

ASSIGN vh-brow01 = QUERY br-brow01:HANDLE IN FRAME fr-frm01.

vh-brow01:GET-FIRST(NO-LOCK) NO-ERROR.
DO WHILE (vh-brow01:QUERY-OFF-END = NO):

  FIND FIRST tt-rutas 
    WHERE tt-rutas.nomprog = tt-progs.nomprog 
    NO-LOCK NO-ERROR.
  IF AVAIL tt-rutas 
    THEN ASSIGN tt-progs.progsel = TRUE.
  ELSE DO:
    ASSIGN
      tt-progs.sinruta = TRUE
      tt-progs.sterror = "Sin Ruta".
  END.

  vh-brow01:GET-NEXT(NO-LOCK) NO-ERROR.
END.

RUN Cifras.

vl-sn = br-brow01:REFRESH().

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Selecciona-Todos C-Win 
PROCEDURE Selecciona-Todos :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  FIND FIRST tt-progs
    NO-LOCK NO-ERROR.
  IF NOT AVAILABLE tt-progs THEN DO:
    MESSAGE "No existen programas a seleccionar, verifique !!"
      VIEW-AS ALERT-BOX WARNING BUTTONS OK TITLE "Aviso".
    RETURN NO-APPLY.
  END.

  CLOSE QUERY br-brow01.
    ASSIGN lvi_SinRuta = 0 lvi_xComp = 0 lvl_SinRuta = NO.
    FOR EACH tt-progs EXCLUSIVE-LOCK:
        FIND FIRST tt-rutas 
            WHERE tt-rutas.nomprog = tt-progs.nomprog NO-LOCK NO-ERROR.
        IF AVAIL tt-rutas THEN 
            ASSIGN tt-progs.progsel = NOT(tt-progs.progsel).
        ELSE DO:
            ASSIGN 
                tt-progs.sinruta = TRUE
                tt-progs.sterror = "Sin Ruta"
                lvi_SinRuta      = lvi_SinRuta + 1
                Fill-SinRuta:SCREEN-VALUE IN FRAME {&FRAME-NAME} = 
                STRING(lvi_SinRuta).
        END.
        IF tt-progs.progsel THEN
            ASSIGN lvi_xComp = lvi_xComp + 1.
    END.
    OPEN QUERY br-brow01 FOR EACH tt-progs.
    IF btnSelAll:LABEL IN FRAME {&FRAME-NAME} = "Selec. Todo" THEN DO:
        ASSIGN 
            lvl_SelTodo     = YES
            btnSelAll:LABEL = "Quitar Selec.".
    END.
    ELSE DO:
        ASSIGN 
            lvl_SelTodo = NO
            btnSelAll:LABEL = "Selec. Todo".
    END.
    IF lvi_SinRuta > 0 THEN DO:
        ASSIGN lvl_SinRuta = TRUE.
        MESSAGE "Existen: " lvi_SinRuta " Programas sin Ruta de Compilación"
            VIEW-AS ALERT-BOX WARNING BUTTONS OK.
    END.
    ASSIGN
        Fill-xComp:SCREEN-VALUE = STRING(lvi_xComp).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Sinc-Estructura C-Win 
PROCEDURE Sinc-Estructura :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  FOR EACH tt-progs:

    FOR EACH tt-rutas:
      FIND FIRST tt-pcmppry
        WHERE tt-pcmppry.nomprog = tt-rutas.nomprog
        AND   tt-pcmppry.rutaprg = tt-rutas.rutades
        NO-LOCK NO-ERROR.
      IF NOT AVAILABLE tt-pcmppry THEN DO:
        CREATE tt-pcmppry.
        ASSIGN
          tt-pcmppry.nomprog = tt-rutas.nomprog
          tt-pcmppry.tipoprg = "R"
          tt-pcmppry.rutaprg = tt-rutas.rutades
          tt-rutas.automat = FALSE.
      END.
    END.

    FOR EACH tt-pcmppry
      WHERE tt-pcmppry.nomprog = tt-progs.nomprog
      NO-LOCK:

      FIND FIRST tt-rutas
        WHERE tt-rutas.nomprog = tt-pcmppry.nomprog
        AND   tt-rutas.rutades = tt-pcmppry.rutaprg
        NO-LOCK NO-ERROR.
      IF NOT AVAILABLE tt-rutas THEN DO:
        CREATE tt-rutas.
        ASSIGN 
          tt-rutas.rutades = tt-pcmppry.rutaprg
          tt-rutas.rutaalt = REPLACE(tt-pcmppry.rutaprg,vc-dircom,vc-diralt)
          tt-rutas.automat = FALSE.
      END.
    END.

    DEFINE VARIABLE vc-rutco  AS CHARACTER  NO-UNDO.
    DEFINE VARIABLE vc-rutre  AS CHARACTER  NO-UNDO. 
    DEFINE VARIABLE vi-err    AS INTEGER    NO-UNDO.

    FIND tt-workarea
       WHERE tt-workarea.numind = vi-proy NO-LOCK NO-ERROR.

    RUN crea-directorio(INPUT tt-workarea.rut002, OUTPUT vi-err).

    ASSIGN vc-rutco = SUBSTITUTE("&1\compilador.csv",tt-workarea.rut002).

    IF vi-proy = 0 THEN DO:
      RETURN.
    END.

    /* Respaldo automático preventivo antes de actualizar compilador.csv (OpenEdge 12.8) */
    FILE-INFO:FILE-NAME = vc-rutco.
    IF FILE-INFO:FULL-PATHNAME <> ? THEN DO:
        RUN backupCatalog (vc-rutco, OUTPUT vc-rutre, OUTPUT vl-sn, OUTPUT vc-logcomp) NO-ERROR.
        IF vl-sn THEN
            RUN Bitacora(INPUT "Respaldo de catalogo generado: " + vc-rutre).
    END.

    OUTPUT TO VALUE(vc-rutco) APPEND.
    FOR EACH tt-rutas
        WHERE tt-rutas.automat = FALSE:
        EXPORT DELIMITER "|" 
            tt-rutas.nomprog AT 1
            tt-rutas.tipoprg
            tt-rutas.rutades.
        ASSIGN tt-rutas.automat = TRUE.
    END.
    OUTPUT CLOSE.

  END.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE SorteaQuery C-Win 
PROCEDURE SorteaQuery :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
DEF INPUT PARAMETER ph-col AS WIDGET-HANDLE NO-UNDO.
DEF INPUT-OUTPUT PARAMETER pl-asc AS LOG    NO-UNDO.

DEF VAR vc-query AS CHAR NO-UNDO.

ASSIGN vc-query = 
  SUBSTITUTE("&1 &2 &3 &4 &5",
             "FOR EACH tt-progs",
             "NO-LOCK",
             SUBSTITUTE("BY &1 &2",ph-col:NAME,(IF pl-asc THEN "" ELSE "DESC"))).

ASSIGN vl-sn = SESSION:SET-WAIT-STATE("general").
ASSIGN vl-sn = QUERY br-brow01:QUERY-PREPARE(vc-query).
ASSIGN vl-sn = QUERY br-brow01:QUERY-OPEN().
ASSIGN vl-sn = SESSION:SET-WAIT-STATE("").

IF pl-asc = TRUE THEN pl-asc = FALSE.
ELSE pl-asc = TRUE.

DO WITH FRAME fr-frm01:
  APPLY "home" TO br-brow01.
  APPLY "value-changed" TO br-brow01.
END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE Verifica-Ruta C-Win 
PROCEDURE Verifica-Ruta :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  DO WITH FRAME fr-frm01:
    ASSIGN 
      lvi_SinRuta = 0 
      lvl_SinRuta = NO.

    FOR EACH tt-progs:

      FIND FIRST tt-rutas 
        WHERE tt-rutas.nomprog = tt-progs.nomprog 
        NO-LOCK NO-ERROR.
      IF NOT AVAILABLE tt-rutas THEN DO:
            ASSIGN 
                tt-progs.sinruta = TRUE
                tt-progs.sterror = "Sin Ruta"
                lvi_SinRuta      = lvi_SinRuta + 1
                Fill-SinRuta:SCREEN-VALUE IN FRAME {&FRAME-NAME} = 
                STRING(lvi_SinRuta).
      END.
    END.
  END.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

