-- Physical Medicine Implementation Mgmt Report Query

DECLARE @StartDate  AS DATETIME,
        @EndDate    AS DATETIME,
        @account    AS VARCHAR(255)

SET @StartDate = '03/19/2024'
SET @EndDate   = GETDATE()
SET @account   = 'All'

/**********************  START  **********************/

DECLARE @account2 AS VARCHAR(255)
SET @account2 = '%' + @account + '%'

SET ANSI_WARNINGS OFF
SET NOCOUNT ON

----------------------------------------------------------------------
-- Drop temp tables if they exist

IF OBJECT_ID('tempdb..#db_list') IS NOT NULL DROP TABLE #db_list
IF OBJECT_ID('tempdb..#result')  IS NOT NULL DROP TABLE #result

----------------------------------------------------------------------
-- Build list of target databases

SELECT DISTINCT
    name,
    ROW_NUMBER() OVER (ORDER BY name) AS RN
INTO #db_list
FROM sys.databases
WHERE name LIKE CASE @account WHEN 'All' THEN '%' ELSE @account2 END
  AND name <> 'centene'
  AND name <> 'centeneKY'
  AND (
        name LIKE '%Ae%'
     OR name LIKE 'Co%'
     OR name LIKE 'Ce%'
     OR name LIKE 'Ga%'
      )

/**********************  TABLE VARIABLES  **********************/

DECLARE @auths TABLE
(
    auth_id VARCHAR(20)
)

DECLARE @queues TABLE
(
    auth_id          VARCHAR(15),
    date_queued      DATETIME2(7),
    queue_code       CHAR(3),
    queue_routing_id INT,
    isfinal          TINYINT,
    report_translation CHAR(3),
    date_left_queue  DATETIME2(7)
)

DECLARE @cte_e TABLE
(
    auth_id           VARCHAR(15),
    max_offer_note_date DATETIME2(7)
)

DECLARE @cte_f TABLE
(
    auth_id         VARCHAR(15),
    note            VARCHAR(7800),
    offer_note_date DATETIME2(7)
)

DECLARE @g TABLE
(
    auth_id                    VARCHAR(15),
    tracking_number            VARCHAR(50),
    date_call_rcvd             DATETIME2(7),
    member_id                  VARCHAR(20),
    phys_id                    VARCHAR(20),
    fac_id                     VARCHAR(20),
    dos                        DATETIME,
    oon_flag                   VARCHAR(20),
    case_outcome               VARCHAR(20),
    provider_type              VARCHAR(20),
    cpt4_code                  VARCHAR(20),
    proc_desc                  VARCHAR(7800),
    auth_origin                VARCHAR(20),
    expedite_flag              VARCHAR(20),
    retro_flag                 VARCHAR(20),
    retro_type                 VARCHAR(20),
    icd10_code                 VARCHAR(20),
    icd10_descr                VARCHAR(7800),
    Apprv_by_Algo              VARCHAR(20),
    accept_or_decline_trmt_plan VARCHAR(20)
)

DECLARE @g2 TABLE
(
    auth_id                    VARCHAR(15),
    tracking_number            VARCHAR(50),
    date_call_rcvd             DATETIME2(7),
    member_id                  VARCHAR(20),
    phys_id                    VARCHAR(20),
    fac_id                     INTEGER,
    dos                        DATETIME,
    oon_flag                   VARCHAR(20),
    case_outcome               VARCHAR(20),
    provider_type              VARCHAR(20),
    cpt4_code                  VARCHAR(20),
    proc_desc                  VARCHAR(7800),
    auth_origin                VARCHAR(20),
    expedite_flag              VARCHAR(20),
    retro_flag                 VARCHAR(20),
    retro_type                 VARCHAR(20),
    icd10_code                 VARCHAR(20),
    icd10_descr                VARCHAR(7800),
    Apprv_by_Algo              VARCHAR(20),
    accept_or_decline_trmt_plan VARCHAR(20),
    determ_date                DATETIME2(7),
    auth_status                VARCHAR(50),
    status_desc                VARCHAR(255),
    auth_outcome               VARCHAR(255),
    UM_Outcome                 VARCHAR(255),
    client_member_id           VARCHAR(50),
    mbr_name                   VARCHAR(255),
    mbr_dob                    DATETIME2(7),
    plan_name                  VARCHAR(255),
    line_of_business           VARCHAR(255),
    car_id                     INT,
    car_name                   VARCHAR(255),
    phys_tax_id                VARCHAR(50),
    phys_npi                   VARCHAR(50),
    client_physician_id        VARCHAR(50),
    phys_name                  VARCHAR(255),
    visits_requested           INTEGER,
    visits_approved            INTEGER,
    visits_denied              INTEGER,
    initial_fax_date           DATETIME,
    has_1570                   VARCHAR(20)
)

DECLARE @g3 TABLE
(
    auth_id                    VARCHAR(15),
    tracking_number            VARCHAR(50),
    date_call_rcvd             DATETIME2(7),
    member_id                  VARCHAR(20),
    phys_id                    VARCHAR(20),
    fac_id                     INTEGER,
    dos                        DATETIME,
    oon_flag                   VARCHAR(20),
    case_outcome               VARCHAR(20),
    provider_type              VARCHAR(20),
    cpt4_code                  VARCHAR(20),
    proc_desc                  VARCHAR(7800),
    auth_origin                VARCHAR(20),
    expedite_flag              VARCHAR(20),
    retro_flag                 VARCHAR(20),
    retro_type                 VARCHAR(20),
    icd10_code                 VARCHAR(20),
    icd10_descr                VARCHAR(7800),
    Apprv_by_Algo              VARCHAR(20),
    accept_or_decline_trmt_plan VARCHAR(20),
    determ_date                DATETIME2(7),
    auth_status                VARCHAR(50),
    status_desc                VARCHAR(255),
    auth_outcome               VARCHAR(255),
    UM_Outcome                 VARCHAR(255),
    client_member_id           VARCHAR(50),
    mbr_name                   VARCHAR(255),
    mbr_dob                    DATETIME2(7),
    plan_name                  VARCHAR(255),
    line_of_business           VARCHAR(255),
    car_id                     INT,
    car_name                   VARCHAR(255),
    phys_tax_id                VARCHAR(50),
    phys_npi                   VARCHAR(50),
    client_physician_id        VARCHAR(50),
    phys_name                  VARCHAR(255),
    visits_requested           INTEGER,
    visits_approved            INTEGER,
    visits_denied              INTEGER,
    initial_fax_date           DATETIME,
    has_1570                   VARCHAR(20),
    Request_Date               DATETIME,
    Rendering_is_OON           VARCHAR(50),
    Rendering_fac_id           VARCHAR(50),
    Rendering_fac_name         VARCHAR(255),
    Rendering_tax_id           VARCHAR(50),
    Rendering_NPI              VARCHAR(50),
    Rendering_fac_street       VARCHAR(255),
    Rendering_fac_city         VARCHAR(255),
    Rendering_fac_state        VARCHAR(50),
    fac_zip                    VARCHAR(50),
    Rendering_MIS              VARCHAR(50),
    fac_phone                  VARCHAR(50),
    Rendering_fac_zip          VARCHAR(50),
    auth_validity_start        DATETIME,
    auth_validity_end          DATETIME,
    initial_or_subsequent      VARCHAR(50),
    hab_or_rehab               VARCHAR(255),
    eval_date                  VARCHAR(MAX)
)

DECLARE @g4 TABLE
(
    auth_id                    VARCHAR(15),
    tracking_number            VARCHAR(50),
    date_call_rcvd             DATETIME2(7),
    member_id                  VARCHAR(20),
    phys_id                    VARCHAR(20),
    fac_id                     INTEGER,
    dos                        DATETIME,
    oon_flag                   VARCHAR(20),
    case_outcome               VARCHAR(20),
    provider_type              VARCHAR(20),
    cpt4_code                  VARCHAR(20),
    proc_desc                  VARCHAR(7800),
    auth_origin                VARCHAR(20),
    expedite_flag              VARCHAR(20),
    retro_flag                 VARCHAR(20),
    retro_type                 VARCHAR(20),
    icd10_code                 VARCHAR(20),
    icd10_descr                VARCHAR(7800),
    Apprv_by_Algo              VARCHAR(20),
    accept_or_decline_trmt_plan VARCHAR(20),
    determ_date                DATETIME2(7),
    auth_status                VARCHAR(50),
    status_desc                VARCHAR(255),
    auth_outcome               VARCHAR(255),
    UM_Outcome                 VARCHAR(255),
    client_member_id           VARCHAR(50),
    mbr_name                   VARCHAR(255),
    mbr_dob                    DATETIME2(7),
    plan_name                  VARCHAR(255),
    line_of_business           VARCHAR(255),
    car_id                     INT,
    car_name                   VARCHAR(255),
    phys_tax_id                VARCHAR(50),
    phys_npi                   VARCHAR(50),
    client_physician_id        VARCHAR(50),
    phys_name                  VARCHAR(255),
    visits_requested           INTEGER,
    visits_approved            INTEGER,
    visits_denied              INTEGER,
    initial_fax_date           DATETIME,
    has_1570                   VARCHAR(20),
    Request_Date               DATETIME,
    Rendering_is_OON           VARCHAR(50),
    Rendering_fac_id           VARCHAR(50),
    Rendering_fac_name         VARCHAR(255),
    Rendering_tax_id           VARCHAR(50),
    Rendering_NPI              VARCHAR(50),
    Rendering_fac_street       VARCHAR(255),
    Rendering_fac_city         VARCHAR(255),
    Rendering_fac_state        VARCHAR(50),
    fac_zip                    VARCHAR(50),
    Rendering_MIS              VARCHAR(50),
    fac_phone                  VARCHAR(50),
    Rendering_fac_zip          VARCHAR(50),
    auth_validity_start        DATETIME,
    auth_validity_end          DATETIME,
    initial_or_subsequent      VARCHAR(50),
    hab_or_rehab               VARCHAR(255),
    eval_date                  VARCHAR(MAX),
    current_status             VARCHAR(255),
    current_queue              VARCHAR(255),
    current_queue_date         DATETIME,
    Has_Clinical_Pend_status   VARCHAR(20),
    Clinical_Pend_status_date  DATETIME,
    Sent_to_PM_ClinReview_Queue            VARCHAR(255),
    PM_ClinReview_queue_date               DATETIME,
    PhysMed_Clinical_Docu_Review_queue_date DATETIME,
    repl_for_validity_ext      INT,
    repl_for_addtl_visits      INT,
    repl_for_denied_visits     INT
)

/**********************  END OF TABLE VARIABLES  **********************/

DECLARE @Counter INT,
        @total   INT

SELECT @total = COUNT(*)
FROM (
    SELECT DISTINCT name
    FROM #db_list
) a

SET @Counter = 1

------------------------------------------------- LOOP THROUGH DBS -------------------------------------------------

WHILE (@Counter <= @total)
BEGIN

    -- Drop per-iteration temp tables
    IF OBJECT_ID('tempdb..#auths')  IS NOT NULL DROP TABLE #auths
    IF OBJECT_ID('tempdb..#offer')  IS NOT NULL DROP TABLE #offer
    IF OBJECT_ID('tempdb..#queues') IS NOT NULL DROP TABLE #queues
    IF OBJECT_ID('tempdb..#cte_e')  IS NOT NULL DROP TABLE #cte_e

    DELETE FROM @auths
    DELETE FROM @queues
    DELETE FROM @cte_e
    DELETE FROM @cte_f
    DELETE FROM @g
    DELETE FROM @g2
    DELETE FROM @g3
    DELETE FROM @g4

    DECLARE @DBNAME VARCHAR(255)
    SELECT @DBNAME = name FROM #db_list WHERE rn = @Counter

    ------------------------------------------------------------------
    -- Get all Physical Medicine authorizations

    INSERT INTO @auths
    EXEC('
        SELECT a.auth_id
        FROM ' + @DBNAME + '.dbo.authorizations a WITH (NOLOCK)
        WHERE a.authorization_type_id = 16
          AND a.retro_flag <> ''c''
    ')

    SELECT * INTO #auths FROM @auths

    ------------------------------------------------------------------
    -- Combine queue history tables (current + archive)

    INSERT INTO @queues
    EXEC('
        SELECT
            aqh.auth_id,
            aqh.date_queued,
            aqh.queue_code,
            aqh.queue_routing_id,
            aqh.isfinal,
            aqh.report_translation,
            aqh.date_left_queue
        FROM ' + @DBNAME + '.DBO.auth_queue_history aqh WITH (NOLOCK)
            JOIN #auths x WITH (NOLOCK) ON aqh.auth_id = x.auth_id

        UNION ALL

        SELECT
            aqha.auth_id,
            aqha.date_queued,
            aqha.queue_code,
            aqha.queue_routing_id,
            aqha.isfinal,
            aqha.report_translation,
            aqha.date_left_queue
        FROM ' + @DBNAME + '.DBO.auth_queue_history_arch aqha WITH (NOLOCK)
            JOIN #auths x2 WITH (NOLOCK) ON aqha.auth_id = x2.auth_id
    ')

    SELECT * INTO #queues FROM @queues

    ------------------------------------------------------------------
    -- Get most-recent offer note date per auth

    INSERT INTO @cte_e
    EXEC('
        SELECT
            an.auth_id,
            max_offer_note_date = MAX(an.date_entered)
        FROM #auths a WITH (NOLOCK)
            JOIN ' + @DBNAME + '.DBO.auth_notes an WITH (NOLOCK) ON a.auth_id = an.auth_id
        WHERE an.note IN (
            ''Requester accepted offered treatment plan'',
            ''Requester declined offered treatment plan''
        )
        GROUP BY an.auth_id
    ')

    SELECT * INTO #cte_e FROM @cte_e

    ------------------------------------------------------------------
    -- Get the actual offer note text at the max date

    INSERT INTO @cte_f
    EXEC('
        SELECT
            an.auth_id,
            an.note,
            offer_note_date = an.date_entered
        FROM #cte_e e
            JOIN ' + @DBNAME + '.DBO.auth_notes an WITH (NOLOCK)
                ON  e.auth_id           = an.auth_id
                AND e.max_offer_note_date = an.date_entered
    ')

    SELECT * INTO #offer FROM @cte_f

    ------------------------------------------------------------------
    -- Build base authorization data set (@g)

    IF OBJECT_ID('tempdb..#g') IS NOT NULL DROP TABLE #g

    INSERT INTO @g
    EXEC('
        SELECT
            a.auth_id,
            a.tracking_number,
            a.date_call_rcvd,
            a.member_id,
            a.phys_id,
            a.fac_id,
            a.dos,
            oon_flag                    = CASE WHEN a.fac_id = 1 THEN ''Yes'' ELSE '''' END,
            a.case_outcome,
            provider_type               = ads.data,
            a.cpt4_code,
            a.proc_desc,
            auth_origin                 = CASE WHEN a.is_user_id = ''1998'' THEN ''RadMD'' ELSE ''CallCenter'' END,
            a.expedite_flag,
            a.retro_flag,
            retro_type                  = r.description,
            a.icd10_code,
            ic.icd10_descr,
            Apprv_by_Algo               = CASE WHEN a.case_outcome = ''Approve Physical Medicine request'' THEN ''Yes'' ELSE ''No'' END,
            accept_or_decline_trmt_plan = CASE
                                              WHEN f.note LIKE ''%accepted%'' THEN ''Accepted''
                                              WHEN f.note LIKE ''%declined%'' THEN ''Declined''
                                              ELSE ''''
                                          END
        FROM #auths a2 WITH (NOLOCK)
            JOIN ' + @DBNAME + '.DBO.authorizations a WITH (NOLOCK)
                ON a2.auth_id = a.auth_id
            LEFT JOIN ' + @DBNAME + '.DBO.authorization_data_supplemental ads WITH (NOLOCK)
                ON  a.auth_id      = ads.auth_id
                AND ads.data_type_id = 542  -- provider type
            JOIN niacore..auth_retro_flags r WITH (NOLOCK)
                ON a.retro_flag = r.retro_flag
            LEFT JOIN niacore..icd10_codes ic WITH (NOLOCK)
                ON a.icd10_code = ic.icd10_code
            LEFT JOIN #offer f WITH (NOLOCK)
                ON a.auth_id = f.auth_id
        WHERE a.date_call_rcvd >= ''' + @StartDate + '''
          AND a.date_call_rcvd <= ''' + @EndDate + '''
    ')

    SELECT * INTO #g FROM @g WHERE date_call_rcvd >= @StartDate

    ------------------------------------------------------------------
    -- Add determination and member/plan/provider detail (@g2)

    IF OBJECT_ID('tempdb..#g2') IS NOT NULL DROP TABLE #g2

    INSERT INTO @g2
    EXEC('
        SELECT
            g.*,
            determ_date      = aschg.date_changed,
            ascd.auth_status,
            ascd.status_desc,
            ascd.auth_outcome,
            UM_Outcome       = CASE
                                   WHEN cd.customer_group_determination_code IN (''1'',''5'') THEN ''Certified''
                                   WHEN cd.customer_group_determination_code IN (''2'',''6'') THEN ''Clinical Non-Certified''
                                   WHEN cd.customer_group_determination_code IN (''7'',''8'') THEN ''Partially Non-Certified''
                                   WHEN cd.customer_group_determination_code = ''3''          THEN ''Administrative Non-Certified''
                                   WHEN cd.customer_group_determination_code = ''4''          THEN ''Inactivated by Ordering Provider''
                               END,
            m.client_member_id,
            mbr_name         = m.lname + '', '' + m.fname,
            mbr_dob          = CONVERT(CHAR(10), m.dob, 101),
            hp.plan_name,
            line_of_business = lob.description,
            hc.car_id,
            hc.car_name,
            phys_tax_id      = p.tax_id,
            phys_npi         = p.npi,
            p.client_physician_id,
            phys_name        = p.lname + '', '' + p.fname,
            tp.visits_requested,
            tp.visits_approved,
            tp.visits_denied,
            initial_fax_date = (
                SELECT MIN(aal.date_action)
                FROM auth_action_log aal WITH (NOLOCK)
                WHERE aal.auth_id         = g.auth_id
                  AND aal.date_action     < g.date_call_rcvd
                  AND aal.auth_action_code = 1302  -- Date/Time fax received during auth entry
            ),
            has_1570 = CASE
                           WHEN EXISTS (
                               SELECT *
                               FROM auth_action_log aal2 WITH (NOLOCK)
                               WHERE g.auth_id          = aal2.auth_id
                                 AND aal2.auth_action_code = 1570  -- Physical Medicine - Subsequent request via phone
                           ) THEN 1
                           ELSE 0
                       END
        FROM #g g WITH (NOLOCK)
            JOIN ' + @DBNAME + '.DBO.members m WITH (NOLOCK)
                ON g.member_id = m.member_id
            JOIN ' + @DBNAME + '.DBO.physicians p WITH (NOLOCK)
                ON g.phys_id = p.phys_id
            JOIN niacore..health_plan hp WITH (NOLOCK)
                ON m.plan_id = hp.plan_id
            JOIN niacore..line_of_business lob WITH (NOLOCK)
                ON hp.line_of_business = lob.line_of_business
            JOIN niacore..health_carrier hc WITH (NOLOCK)
                ON hp.car_id = hc.car_id
            LEFT JOIN ' + @DBNAME + '.DBO.auth_status_change aschg WITH (NOLOCK)
                ON  g.auth_id         = aschg.auth_id
                AND aschg.date_changed = (
                    SELECT MAX(aschg2.date_changed)
                    FROM ' + @DBNAME + '.DBO.auth_status_change aschg2 WITH (NOLOCK)
                        JOIN niacore..auth_status_codes ascd2 WITH (NOLOCK)
                            ON aschg2.new_auth_status = ascd2.auth_status
                    WHERE aschg.auth_id         = aschg2.auth_id
                      AND ascd2.final_status_flag = 1
                )
            LEFT JOIN niacore..auth_status_codes ascd WITH (NOLOCK)
                ON aschg.new_auth_status = ascd.auth_status
            LEFT JOIN niacore..auth_outcomes aout WITH (NOLOCK)
                ON ascd.auth_outcome = aout.auth_outcome
            LEFT JOIN niacore..Customer_Determination_Codes cd WITH (NOLOCK)
                ON ascd.customer_determination_code = cd.customer_determination_code
            LEFT JOIN niacore..Customer_Group_Determination_Codes cgd WITH (NOLOCK)
                ON cd.customer_group_determination_code = cgd.customer_group_determination_code
            LEFT JOIN ' + @DBNAME + '.DBO.physical_medicine_therapy_plan tp WITH (NOLOCK)
                ON g.auth_id = tp.auth_id
    ')

    SELECT * INTO #g2 FROM @g2

    ------------------------------------------------------------------
    -- Add facility / rendering provider info (@g3)

    IF OBJECT_ID('tempdb..#g3') IS NOT NULL DROP TABLE #g3

    INSERT INTO @g3
    EXEC('
        SELECT
            a.*,
            Request_Date          = ISNULL(initial_fax_date, date_call_rcvd),
            Rendering_is_OON      = a.oon_flag,
            Rendering_fac_id      = CASE WHEN a.fac_id = 1 THEN afg.fac_id       ELSE a.fac_id        END,
            Rendering_fac_name    = CASE WHEN a.fac_id = 1 THEN afg.facility_name ELSE f.facility_name END,
            Rendering_tax_id      = CASE WHEN a.fac_id = 1 THEN afg.provider_tax_id ELSE f.provider_tax_id END,
            Rendering_NPI         = CASE WHEN a.fac_id = 1 THEN NULL             ELSE app.provider_npi  END,
            Rendering_fac_street  = CASE WHEN a.fac_id = 1 THEN afg.address1     ELSE f.address1        END,
            Rendering_fac_city    = CASE WHEN a.fac_id = 1 THEN afg.city         ELSE f.city            END,
            Rendering_fac_state   = CASE WHEN a.fac_id = 1 THEN afg.state        ELSE f.state           END,
            fac_zip               = CASE WHEN a.fac_id = 1 THEN afg.zip          ELSE f.zip             END,
            Rendering_MIS         = CASE WHEN a.fac_id = 1 THEN NULL             ELSE app.provider_mis  END,
            fac_phone             = CASE WHEN a.fac_id = 1
                                         THEN afg.contact_ac + ''-'' + afg.contact_phone
                                         ELSE f.ac           + ''-'' + f.phone
                                    END,
            Rendering_fac_zip     = CASE WHEN a.fac_id = 1 THEN afg.zip          ELSE f.zip             END,
            auth_validity_start   = avs.start_date,
            auth_validity_end     = avs.end_date,
            initial_or_subsequent = CASE
                                        WHEN RIGHT(RTRIM(a.auth_id), 1) IN (''0'',''1'',''2'',''3'',''4'',''5'',''6'',''7'',''8'',''9'')
                                            THEN ''Initial''
                                        WHEN RIGHT(RTRIM(a.auth_id), 1) IN (
                                            ''A'',''B'',''C'',''D'',''E'',''F'',''G'',''H'',''I'',''J'',''K'',
                                            ''L'',''M'',''N'',''O'',''P'',''Q'',''R'',''S'',''T'',''U'',''V'',''W'',''X'',''Y'',''Z''
                                        )
                                            THEN ''Subsequent''
                                        ELSE ''N/A''
                                    END,
            hab_or_rehab = ads.data,
            eval_date    = CASE
                               WHEN proc_desc = ''Therapy-PT'' THEN ads2.data
                               WHEN proc_desc = ''Therapy-ST'' THEN ads3.data
                               WHEN proc_desc = ''Therapy-OT'' THEN ads4.data
                               ELSE '' ''
                           END
        FROM #g2 a WITH (NOLOCK)
            JOIN nirad..facilities f WITH (NOLOCK)
                ON a.fac_id = f.fac_id
            LEFT JOIN nirad..applications app WITH (NOLOCK)
                ON  f.fac_id  = app.fac_id
                AND a.car_id  = app.car_id
            LEFT JOIN ' + @DBNAME + '.DBO.auth_facility_generic afg WITH (NOLOCK)
                ON  a.auth_id      = afg.auth_id
                AND afg.date_updated = (
                    SELECT MAX(afg2.date_updated)
                    FROM ' + @DBNAME + '.DBO.auth_facility_generic afg2 WITH (NOLOCK)
                    WHERE afg2.auth_id       = a.auth_id
                      AND afg2.facility_name NOT LIKE ''%cancel%''
                      AND afg2.facility_name NOT LIKE ''Other%''
                )
            LEFT JOIN ' + @DBNAME + '.DBO.auth_validity_spans avs WITH (NOLOCK)
                ON  a.auth_id     = avs.auth_id
                AND avs.sequence  = (
                    SELECT MAX(avs2.sequence)
                    FROM ' + @DBNAME + '.DBO.auth_validity_spans avs2 WITH (NOLOCK)
                    WHERE avs.auth_id = avs2.auth_id
                )
            LEFT JOIN ' + @DBNAME + '.DBO.authorization_data_supplemental ads WITH (NOLOCK)
                ON  a.auth_id        = ads.auth_id
                AND ads.data_type_id = 413
            LEFT JOIN ' + @DBNAME + '.DBO.authorization_data_supplemental ads2 WITH (NOLOCK)
                ON  a.auth_id        = ads2.auth_id
                AND ads2.data_type_id = 399  -- Physical Medicine - Physical Therapy Evaluation date
            LEFT JOIN ' + @DBNAME + '.DBO.authorization_data_supplemental ads3 WITH (NOLOCK)
                ON  a.auth_id        = ads3.auth_id
                AND ads3.data_type_id = 407  -- Physical Medicine - Speech Therapy evaluation date
            LEFT JOIN ' + @DBNAME + '.DBO.authorization_data_supplemental ads4 WITH (NOLOCK)
                ON  a.auth_id        = ads4.auth_id
                AND ads4.data_type_id = 396  -- Physical Medicine - Occupational Therapy evaluation date
    ')

    SELECT * INTO #g3 FROM @g3

    ------------------------------------------------------------------
    -- Add current queue / status and replication flags (@g4)
    -- Action codes:
    --   1555 = Physical Medicine - Replicated for validity date extension requiring clinical review
    --   1556 = Physical Medicine - Replicated for additional visits request
    --   1566 = Physical Medicine - Replicated for denied visits

    IF OBJECT_ID('tempdb..#g4') IS NOT NULL DROP TABLE #g4

    INSERT INTO @g4
    EXEC('
        SELECT
            a.*,
            current_status    = ascd.status_desc,
            current_queue     = i1.description,
            current_queue_date = z3.date_queued,
            Has_Clinical_Pend_status  = CASE WHEN y.date_changed IS NOT NULL THEN ''Yes'' ELSE ''No'' END,
            Clinical_Pend_status_date = CONVERT(VARCHAR(10), y.date_changed, 120),
            Sent_to_PM_ClinReview_Queue = CASE WHEN z1.date_queued IS NOT NULL THEN ''Yes'' ELSE ''No'' END,
            PM_ClinReview_queue_date    = CONVERT(VARCHAR(10), z1.date_queued, 120),
            PhysMed_Clinical_Docu_Review_queue_date = CONVERT(VARCHAR(10), z2.date_queued, 120),
            repl_for_validity_ext  = CASE
                                         WHEN EXISTS (
                                             SELECT aal.auth_id
                                             FROM auth_action_log aal WITH (NOLOCK)
                                             WHERE a.auth_id = aal.auth_id
                                               AND aal.auth_action_code = 1555
                                         ) THEN 1 ELSE 0
                                     END,
            repl_for_addtl_visits  = CASE
                                         WHEN EXISTS (
                                             SELECT aal.auth_id
                                             FROM auth_action_log aal WITH (NOLOCK)
                                             WHERE a.auth_id = aal.auth_id
                                               AND aal.auth_action_code = 1556
                                         ) THEN 1 ELSE 0
                                     END,
            repl_for_denied_visits = CASE
                                         WHEN EXISTS (
                                             SELECT aal.auth_id
                                             FROM auth_action_log aal WITH (NOLOCK)
                                             WHERE a.auth_id = aal.auth_id
                                               AND aal.auth_action_code = 1566
                                         ) THEN 1 ELSE 0
                                     END
        FROM #g3 a WITH (NOLOCK)
            LEFT JOIN #queues z1 WITH (NOLOCK)
                ON  a.auth_id    = z1.auth_id
                AND z1.queue_code = ''por''
                AND z1.date_queued = (
                    SELECT MIN(z1a.date_queued)
                    FROM #queues z1a WITH (NOLOCK)
                    WHERE z1.auth_id    = z1a.auth_id
                      AND z1a.queue_code = ''por''
                )
            LEFT JOIN #queues z2 WITH (NOLOCK)
                ON  a.auth_id    = z2.auth_id
                AND z2.queue_code = ''pmd''
                AND z2.date_queued = (
                    SELECT MIN(z2a.date_queued)
                    FROM #queues z2a WITH (NOLOCK)
                    WHERE z2.auth_id    = z2a.auth_id
                      AND z2a.queue_code = ''pmd''
                )
            LEFT JOIN #queues z3 WITH (NOLOCK)
                ON  a.auth_id = z3.auth_id
                AND z3.isfinal = 1
            LEFT JOIN ' + @DBNAME + '.DBO.auth_status_change y WITH (NOLOCK)
                ON  a.auth_id        = y.auth_id
                AND y.new_auth_status = ''cp''
                AND y.date_changed   = (
                    SELECT MIN(y2.date_changed)
                    FROM ' + @DBNAME + '.DBO.auth_status_change y2 WITH (NOLOCK)
                    WHERE y2.auth_id        = y.auth_id
                      AND y2.new_auth_status = ''cp''
                )
            LEFT JOIN niacore..informa_queues i1 WITH (NOLOCK)
                ON z3.queue_code = i1.queue_code
            LEFT JOIN ' + @DBNAME + '.DBO.auth_status_change aschg WITH (NOLOCK)
                ON  a.auth_id     = aschg.auth_id
                AND aschg.isfinal = 1
            LEFT JOIN niacore..auth_status_codes ascd WITH (NOLOCK)
                ON aschg.new_auth_status = ascd.auth_status
    ')

    IF OBJECT_ID('tempdb..#g_final') IS NOT NULL DROP TABLE #g_final

    SELECT * INTO #g_final FROM @g4

    ------------------------------------------------------------------
    -- Build final result set for this database

    IF OBJECT_ID('tempdb..#g_results') IS NOT NULL DROP TABLE #g_results

    SELECT
        car_id,
        car_name,
        auth_id,
        tracking_number,
        initial_or_subsequent,
        repl_for_validity_ext,
        repl_for_addtl_visits,
        Request_Date        = CONVERT(VARCHAR(10), Request_Date, 120),
        Date_of_Svc         = CONVERT(CHAR(20),   dos,          101),
        plan_name           = RTRIM(plan_name),
        line_of_business,
        expedite_flag,
        cpt4_code,
        proc_desc,
        icd10_code,
        icd10_descr,
        Apprv_by_Algo,
        accept_or_decline_trmt_plan,
        determ_date         = CONVERT(VARCHAR(10), determ_date, 120),
        final_outcome       = auth_outcome,
        final_determ        = status_desc,
        UM_Outcome,
        auth_origin,
        visits_requested,
        visits_approved,
        visits_denied,
        client_member_id,
        mbr_dob,
        mbr_name,
        client_physician_id,
        phys_tax_id,
        phys_npi,
        phys_name,
        Rendering_is_OON,
        Provider_Type,
        Rendering_fac_name,
        Rendering_MIS,
        Rendering_tax_id,
        Rendering_NPI,
        Rendering_fac_street,
        Rendering_fac_city,
        Rendering_fac_state,
        Rendering_fac_zip,
        current_status,
        current_queue,
        current_queue_date  = CONVERT(VARCHAR(10), current_queue_date, 120),
        auth_validity_start,
        auth_validity_end,
        Has_Clinical_Pend_status,
        Clinical_Pend_status_date,
        Sent_to_PM_ClinReview_Queue,
        PM_ClinReview_queue_date,
        PhysMed_Clinical_Docu_Review_queue_date,
        hab_or_rehab,
        eval_date
    INTO #g_results
    FROM #g_final g WITH (NOLOCK)

    ------------------------------------------------------------------
    -- Merge into cumulative result table

    IF @Counter = 1
        SELECT @DBNAME AS dbname, * INTO #result FROM #g_results
    ELSE
        INSERT INTO #result
        (
            dbname,
            car_id, car_name, auth_id, tracking_number,
            initial_or_subsequent, repl_for_validity_ext, repl_for_addtl_visits,
            Request_Date, Date_of_Svc, plan_name, line_of_business, expedite_flag,
            cpt4_code, proc_desc, icd10_code, icd10_descr,
            Apprv_by_Algo, accept_or_decline_trmt_plan,
            determ_date, final_outcome, final_determ, UM_Outcome, auth_origin,
            visits_requested, visits_approved, visits_denied,
            client_member_id, mbr_dob, mbr_name,
            client_physician_id, phys_tax_id, phys_npi, phys_name,
            Rendering_is_OON, Provider_Type,
            Rendering_fac_name, Rendering_MIS, Rendering_tax_id, Rendering_NPI,
            Rendering_fac_street, Rendering_fac_city, Rendering_fac_state, Rendering_fac_zip,
            current_status, current_queue, current_queue_date,
            auth_validity_start, auth_validity_end,
            Has_Clinical_Pend_status, Clinical_Pend_status_date,
            Sent_to_PM_ClinReview_Queue, PM_ClinReview_queue_date,
            PhysMed_Clinical_Docu_Review_queue_date,
            hab_or_rehab, eval_date
        )
        SELECT
            @DBNAME AS dbname,
            car_id, car_name, auth_id, tracking_number,
            initial_or_subsequent, repl_for_validity_ext, repl_for_addtl_visits,
            Request_Date, Date_of_Svc, plan_name, line_of_business, expedite_flag,
            cpt4_code, proc_desc, icd10_code, icd10_descr,
            Apprv_by_Algo, accept_or_decline_trmt_plan,
            determ_date, final_outcome, final_determ, UM_Outcome, auth_origin,
            visits_requested, visits_approved, visits_denied,
            client_member_id, mbr_dob, mbr_name,
            client_physician_id, phys_tax_id, phys_npi, phys_name,
            Rendering_is_OON, Provider_Type,
            Rendering_fac_name, Rendering_MIS, Rendering_tax_id, Rendering_NPI,
            Rendering_fac_street, Rendering_fac_city, Rendering_fac_state, Rendering_fac_zip,
            current_status, current_queue, current_queue_date,
            auth_validity_start, auth_validity_end,
            Has_Clinical_Pend_status, Clinical_Pend_status_date,
            Sent_to_PM_ClinReview_Queue, PM_ClinReview_queue_date,
            PhysMed_Clinical_Docu_Review_queue_date,
            hab_or_rehab, eval_date
        FROM #g_results
        ORDER BY determ_date

    SET @Counter = @Counter + 1

END  -- WHILE

------------------------------------------------------------------
-- Final output

SELECT 'result', *
FROM #result
ORDER BY determ_date
