*&---------------------------------------------------------------------*
*& Report Z119_ROUTINE
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z119_ROUTINE.
TYPE-POOLS: SLIS. " Predined Structures & Types

DATA: GT_ROUTINE   TYPE TABLE OF ZTABU_ROUTINE,
      GWA_ROUTINE  TYPE ZTABU_ROUTINE,
      GT_FIELDCAT  TYPE SLIS_T_FIELDCAT_ALV,
      GWA_FIELDCAT TYPE SLIS_FIELDCAT_ALV.

"Selection-screen
"user must enter both the input fields as it is obligatory
SELECTION-SCREEN BEGIN OF BLOCK B1 WITH FRAME TITLE TEXT-001.
PARAMETERS: P_DEPT TYPE ZDE_DEPTCODE1 OBLIGATORY,
            P_YEAR TYPE ZDE_ROUTINEYEAR OBLIGATORY.
SELECTION-SCREEN END OF BLOCK B1.

*AT SELECTION-SCREEN ON VALUE-REQUEST FOR P_DEPT.
* PERFORM F4_DEPT IN PROGRAM Z119_STUDENT_MODIF.

"it fetches the data from database and stores in internal table

START-OF-SELECTION.
  SELECT *  " need to use * only here as we didn't mention structure and also there is mandit in fields
    FROM ZTABU_ROUTINE
    INTO TABLE GT_ROUTINE
    WHERE DEPT_CODE = P_DEPT
  AND ROUINE_YEAR = P_YEAR.

  IF GT_ROUTINE IS INITIAL.
    MESSAGE 'Enter valid input' TYPE 'E'.
  ENDIF.


  PERFORM BUILD_FIELDCAT. "logic is inside subroutine

  DATA: LS_LAYOUT TYPE SLIS_LAYOUT_ALV.

  LS_LAYOUT-COLWIDTH_OPTIMIZE = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*     I_INTERFACE_CHECK        = ' '
*     I_BYPASSING_BUFFER       = ' '
*     I_BUFFER_ACTIVE          = ' '
      I_CALLBACK_PROGRAM       = SY-REPID "refers to instance report
      I_CALLBACK_PF_STATUS_SET = 'PF_STATUS'
      I_CALLBACK_USER_COMMAND  = 'USER_COMMAND'
*     I_CALLBACK_TOP_OF_PAGE   = ' '
*     I_CALLBACK_HTML_TOP_OF_PAGE       = ' '
*     I_CALLBACK_HTML_END_OF_LIST       = ' '
*     I_STRUCTURE_NAME         = 'ZTABU_ROUTINE'
*     I_BACKGROUND_ID          = ' '
*     I_GRID_TITLE             =
*     I_GRID_SETTINGS          =
      IS_LAYOUT                = LS_LAYOUT
      IT_FIELDCAT              = GT_FIELDCAT
*     IT_EXCLUDING             =
*     IT_SPECIAL_GROUPS        =
*     IT_SORT                  =
*     IT_FILTER                =
*     IS_SEL_HIDE              =
*     I_DEFAULT                = 'X'
      I_SAVE                   = 'A'
*     IS_VARIANT               =
*     IT_EVENTS                =
*     IT_EVENT_EXIT            =
*     IS_PRINT                 =
*     IS_REPREP_ID             =
*     I_SCREEN_START_COLUMN    = 0
*     I_SCREEN_START_LINE      = 0
*     I_SCREEN_END_COLUMN      = 0
*     I_SCREEN_END_LINE        = 0
*     I_HTML_HEIGHT_TOP        = 0
*     I_HTML_HEIGHT_END        = 0
*     IT_ALV_GRAPHICS          =
*     IT_HYPERLINK             =
*     IT_ADD_FIELDCAT          =
*     IT_EXCEPT_QINFO          =
*     IR_SALV_FULLSCREEN_ADAPTER        =
*   IMPORTING
*     E_EXIT_CAUSED_BY_CALLER  =
*     ES_EXIT_CAUSED_BY_USER   =
    TABLES
      T_OUTTAB                 = GT_ROUTINE
    EXCEPTIONS
      PROGRAM_ERROR            = 1
      OTHERS                   = 2.
  IF SY-SUBRC <> 0.
* Implement suitable error handling here
  ENDIF.

FORM BUILD_FIELDCAT.
  CLEAR GWA_FIELDCAT.
  GWA_FIELDCAT-COL_POS = '1'.
  GWA_FIELDCAT-FIELDNAME = 'dept_code'.
  GWA_FIELDCAT-EDIT = ABAP_FALSE. "Editing not allowed
  GWA_FIELDCAT-SELTEXT_L = 'Department'.
  APPEND GWA_FIELDCAT TO GT_FIELDCAT.

  CLEAR GWA_FIELDCAT.
  GWA_FIELDCAT-COL_POS = '2'.
  GWA_FIELDCAT-FIELDNAME = 'ROUINE_YEAR'.
  GWA_FIELDCAT-EDIT = ABAP_FALSE.
  GWA_FIELDCAT-SELTEXT_L = 'Year'.
  APPEND GWA_FIELDCAT TO GT_FIELDCAT.

  CLEAR GWA_FIELDCAT.
  GWA_FIELDCAT-COL_POS = '3'.
  GWA_FIELDCAT-FIELDNAME = 'ROUTINE_DAY'.
  GWA_FIELDCAT-EDIT = ABAP_TRUE. "Editing allowed
  GWA_FIELDCAT-SELTEXT_L = 'DAY'.
  APPEND GWA_FIELDCAT TO GT_FIELDCAT.

  CLEAR GWA_FIELDCAT.
  GWA_FIELDCAT-COL_POS = '4'.
  GWA_FIELDCAT-FIELDNAME = 'FROM_TIME'.
  GWA_FIELDCAT-EDIT = ABAP_TRUE.
  GWA_FIELDCAT-SELTEXT_L = 'FROM TIME'.
  APPEND GWA_FIELDCAT TO GT_FIELDCAT.

  CLEAR GWA_FIELDCAT.
  GWA_FIELDCAT-COL_POS = '5'.
  GWA_FIELDCAT-FIELDNAME = 'TO_TIME'.
  GWA_FIELDCAT-EDIT = ABAP_TRUE.
  GWA_FIELDCAT-SELTEXT_L = 'TO TIME'.
  APPEND GWA_FIELDCAT TO GT_FIELDCAT.

  CLEAR GWA_FIELDCAT.
  GWA_FIELDCAT-COL_POS = '6'.
  GWA_FIELDCAT-FIELDNAME = 'TEACHER_ID'.
  GWA_FIELDCAT-EDIT = ABAP_TRUE.
  GWA_FIELDCAT-SELTEXT_L = 'TEACHER ID'.
  APPEND GWA_FIELDCAT TO GT_FIELDCAT.
ENDFORM.

FORM PF_STATUS USING RT_EXTAB TYPE SLIS_T_EXTAB.
  SET PF-STATUS 'ROUTINE'. "created to have save button
ENDFORM.

FORM USER_COMMAND USING R_UCOMM LIKE SY-UCOMM RS_SELFIELD TYPE SLIS_SELFIELD.
  "r_ucomm = user_action(save,back) and rs_selfield = contains which row or column is selected and flags like refresh
  DATA LO_GRID TYPE REF TO CL_GUI_ALV_GRID. "with lo_grid, we will get to know what user changes in grid
  CASE R_UCOMM.
    WHEN 'SAVE'.
      "this function retrieves the current alv object(the one displayed on screen)
      CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR' "get the alv grid objectalv_
        IMPORTING
          E_GRID = LO_GRID.

      IF LO_GRID IS BOUND. "lo_grid is a variable pointing to alv grid object(cl_gui_alv_grid)."bound is used to check
        CALL METHOD LO_GRID->CHECK_CHANGED_DATA. "this pushhes user edits from ALV screen into internal table
      ENDIF.

      MODIFY ZTABU_ROUTINE FROM TABLE GT_ROUTINE. "updates the db table with new values
      IF SY-SUBRC = 0.
        COMMIT WORK. "it will save the changes to database.
        MESSAGE 'Changes saved succesfully' TYPE 'S'.  "S->success message
      ELSE.
        ROLLBACK WORK.
        MESSAGE 'DB update failed' TYPE 'E'.
      ENDIF.
      RS_SELFIELD-REFRESH = 'X'. "tells alv to reload the grid with updated data.

    WHEN 'BACK'.
      LEAVE PROGRAM.
  ENDCASE.
ENDFORM.
