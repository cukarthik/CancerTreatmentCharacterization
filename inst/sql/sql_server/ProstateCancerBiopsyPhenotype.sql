CREATE TABLE #Codesets (
  codeset_id int NOT NULL,
  concept_id bigint NOT NULL
)
;

INSERT INTO #Codesets (codeset_id, concept_id)
SELECT 0 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (44502035,44502092,4161028,44499685,44500595,44499820,44503558,44501366,44500494,200970,44500839,4116087,44503133,44499712,44500341,44503145,40482030,44502350,4082919,37395835,44501968,44501544,4141960,36716186,44503555,44499864,4200890,4183913,4183745,4283614,4281018,4289246,4289249,4283740,4283741,4280897,4289096,4289379,4289380,4163261,4196262,44500734,44501528,44501350,4129902,201527,44502000,44501627,36716172,2618013,2618017,2618066,2618067,44499641,44499734,200962,37016740,4183923,4299337,4164339,4161553,4183347,4183925,4183753,4183924,2106844,192681,44500459,4288534,44502766,4164017,44499428,44500716,4263583,4241307,4241182,4241183,4241308,4241547,4241309,4240192,4241310,4240691,4110284,44499799,44501195)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (44502035,44502092,4161028,44499685,44500595,44499820,44503558,44501366,44500494,200970,44500839,4116087,44503133,44499712,44500341,44503145,40482030,44502350,4082919,37395835,44501968,44501544,4141960,36716186,44503555,44499864,4200890,4183913,4183745,4283614,4281018,4289246,4289249,4283740,4283741,4280897,4289096,4289379,4289380,4163261,4196262,44500734,44501528,44501350,4129902,201527,44502000,44501627,36716172,2618013,2618017,2618066,2618067,44499641,44499734,200962,37016740,4183923,4299337,4164339,4161553,4183347,4183925,4183753,4183924,2106844,192681,44500459,4288534,44502766,4164017,44499428,44500716,4263583,4241307,4241182,4241183,4241308,4241547,4241309,4240192,4241310,4240691,4110284,44499799,44501195)
  and c.invalid_reason is null

) I
LEFT JOIN
(
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4086709,4052054,197237,40488897,4304387,4264045,40488901,4115735,44500910,4283738,4289381,4217171,40486666,2618011,2618012,2618014,4205813,4263005,4286883,36712762,4314337,4240437,4240922)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (197237)
  and c.invalid_reason is null

) E ON I.concept_id = E.concept_id
WHERE E.concept_id is null
) C UNION ALL 
SELECT 1 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (44808725,45956527,44809585,2110044,4071665,2003982,40307096,4211496,44512376,45489212,45526577,45618103,4235738,37521400,40307090,45528521,45889834,2110032,2110034,2110033,2110031,2110037,45889683,2110039,2110038,4338373,4243467,4219099,37521402,40307095,2003969,4096783,45922194,45452309,4073007,4071666,45452310,4073695,45439070,4073008,45505682,4276520,4187904,4102465,37521403,4194172,44512374,40307094,2003968,45472552,46270921)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (44808725,45956527,44809585,2110044,4071665,2003982,40307096,4211496,44512376,45489212,45526577,45618103,4235738,37521400,40307090,45528521,45889834,2110032,2110034,2110033,2110031,2110037,45889683,2110039,2110038,4338373,4243467,4219099,37521402,40307095,2003969,4096783,45922194,45452309,4073007,4071666,45452310,4073695,45439070,4073008,45505682,4276520,4187904,4102465,37521403,4194172,44512374,40307094,2003968,45472552,46270921)
  and c.invalid_reason is null
UNION
select distinct cr.concept_id_1 as concept_id
FROM
(
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (44808725,45956527,44809585,2110044,4071665,2003982,40307096,4211496,44512376,45489212,45526577,45618103,4235738,37521400,40307090,45528521,45889834,2110032,2110034,2110033,2110031,2110037,45889683,2110039,2110038,4338373,4243467,4219099,37521402,40307095,2003969,4096783,45922194,45452309,4073007,4071666,45452310,4073695,45439070,4073008,45505682,4276520,4187904,4102465,37521403,4194172,44512374,40307094,2003968,45472552,46270921)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (44808725,45956527,44809585,2110044,4071665,2003982,40307096,4211496,44512376,45489212,45526577,45618103,4235738,37521400,40307090,45528521,45889834,2110032,2110034,2110033,2110031,2110037,45889683,2110039,2110038,4338373,4243467,4219099,37521402,40307095,2003969,4096783,45922194,45452309,4073007,4071666,45452310,4073695,45439070,4073008,45505682,4276520,4187904,4102465,37521403,4194172,44512374,40307094,2003968,45472552,46270921)
  and c.invalid_reason is null

) C
join @vocabulary_database_schema.concept_relationship cr on C.concept_id = cr.concept_id_2 and cr.relationship_id = 'Maps to' and cr.invalid_reason IS NULL

) I
) C UNION ALL 
SELECT 2 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (37586708,37586709,37521400,37586707)

) I
) C UNION ALL 
SELECT 3 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (44785905,44785906,44785903,45043075,44785904,40168503,40168504,44941108,1351705,40144392,45347501,45315723,45127641,1351747,45860210,45866506,46249353,46251661,1351702,40144394,45142380,44923688,1351745,46251674,46248906,45868570,45860208,1351704,40144396,44855346,45108619,45349710,1351748,45862315,45862316,46249837,46255762,1351703,40144399,45108620,45264574,1351746,46255761,46251195,45860209,45870698,1351743,1351744,45283372,44974818,45027470,45112692,1351710,19129560,44974826,45095543,44925399,44889929,45253131,45304368,19127182,19127184,45299142,44874082,45060232,45010254,45104691,45111278,45163596,45197699,1351671,1351706,44940702,45213157,45232130,45309632,44861094,44907200,45145033,45112694,44980129,44991718,45010253,1351707,40240359,40240360,45094163,44993061,45372354,46331444,40240361,40240362,45300495,45167598,44855764,40240363,40240364,44912449,44849551,45116506,45111279,45213563,45253130,45282000,40240365,40240366,45270271,45299132,45317493,45327007,45338450,45133339,45099491,44908563,44855772,1351668,19127247,45111273,45180510,45334447,45300497,45232131,1351708,19129553,45247752,45095544,44993062,44957816,1351666,1351667,44980128,45150391,45196289,45264961,45300498,40240342,40240343,45338451,45184570,45111274,44946341,40240344,40240345,44963078,44878181,45321398,45361301,40240346,40240347,44872720,40240348,40240349,44855773,45048396,45196290,45116507,45338452,45334448,45264965,1343066,45230861,45213564,44976169,4304921,37521407,2004064,19088739,21603847,40203723,40480474,40480913,19058410,45610177,19058444,40165495,45208154,45378874,45378875,45410296,45963758,46084830,40481361,40210102,42863552,45699228,19058441,40165494,45187336,45364772,45327728,45705686,45105803,19133317,40165496,45187337,44969427,45364773,45242393,19058442,40165493,45208152,45190959,44952553,45411527,45963759,46084829,40479183,40210101,42863551,46274183,46274176,45957454,45718687,45727015,40155986,40165497,38002464,45071898,45626750,45208153,46244276,19032761,45686131,46315414,45417311,45888348,45678821,21603823,4333782,4318752,4054335,4031929,1366310,21603826,45618284,45906419,1366335,19079533,19080002,1366332,45214959,45261234,44976196,44874123,45411944,1366336,19079532,19077734,19007549,45249175,45300530,45351496,45346494,45207049,45413611,4211277,45726253,4161718,42857343,45214958,45796681,45897696,45715187,4186358,4344863,45351495,45895267,45797044,2718873,40047620,40047621,4032090,1366773,4129055,45611310,43534818,19114081,19114082,44900474,1366774,19114080,4267691,4267407,19123086,19123087,45411185,4291914,42799762,45263482,45212116,42799761,42799759,42799763,42799764,42799760,4337566,42865266,45853210,45853211,40128014,40129559,2718888,2718887,40055134,40663979,2718434,2718473,2718622,1351541,4326314,4293818,45611025,1351742,19048360,19097499,19022783,1351570,19119915,19048358,19028290,1351595,19048359,19066440,19095855,19021438,45412311,1351592,19118085,19127183,19031860,19027429,45417217,1351670,42902510,45409144,19085061,19118080,1351569,45214926,45284787,45290799,44841314,44958579,44935739,44883521,45180511,45146406,19031823,45040790,1351598,19100268,1351568,45236791,45127667,44896059,19071457,45410922,19084094,19078760,45224234,1351593,19118086,19048357,19031884,1351562,45409841,40143272,40143275,40143273,40143274,45631707,45941714,2718884,40193864,42856435,45689135,45666905,45675709,45703367,46315726,45715188,45717909,45710717,45712422,40240977,40240978,42903054,42903055,4130650,1351628,40144669,19032762,1351629,40126473,42903093,42902570,42858620,4347039,578431,45709809,19114808,19114809,40240980,40240979,1351600,19114810,42903072,42903385,45635517,45316953,42562295,42858621,1351625,19114817,40240981,1351626,19114818,42902462,42902405,45709718,45729041,45712644,45723439,45723442,45720644,1351623,19114815,40240982,1351624,19114816,42903066,42902758,4163473,4341757,42858622,45709719,45729252,45726254,1351662,40144670,19032764,40240983,1351663,40126477,42903384,42902427,42902861,4130649,45721647,45710106,4219279,1351601,19114819,19114811,1351622,45318913,45335949,45282815,45267983,44952368,44965404,45172961,45182172,45205952,45187040,45045878,45102745,44975620,45904930,46254852,45026093,45197698,44855771,45232613,45317494,19114812,1351627,19114820,4190048,1351630,40144671,40144672,19032763,19122007,40126487,42902937,42902518,4258091,4348128,42856438,45713399,45709898,45726347,579404,45712420,45717908,40240986,40116603,40116606,40240988,40240987,40116604,40116605,42903131,42902584,4188135,42562297,42856439,2718886,45080028,45178755,44872293,45332636,45281565,44872705,44872724,44924125,45196277,45008860,46367868,45008877,44991719,45111277,44941109,44872721,45316137,45818382,45845913,45845914,45845915,45845916,46247291,46247292,46247293,46247294,45410549,45410025,2718885,580240,580241,40052221,40052222,40052223,40052224,40052225,40052226,40052228,40116607,40141913,40144673,40144674,40144675,40144676,40155345,40141914,4211999,45912845,45677649,19048354,45637340,19027009,45701690,45621749,45625121,45415578,45417361,45415686,45410826,45410032,45413675,45412502,45696795,46320045,45410376,45411282,45408798,45410377,4170288,4297248,37586738,45613188,45937538,4145907,2109973,2004065,2004066,4242876,37521416,4003224,45700820,45413406,45617099,1343039,4213832,4211281,21603827,1343041,19120941,40149505,40174070,1343062,44967625,42903025,44967626,45342928,4261120,40174071,45035933,45155044,19126556,19010605,45206358,45342927,45415191,1343040,45155045,45418243,1343063,1343065,45347129,45308935,45121079,45923941,4212000,40088408,40088409,40088410,45710419,45833076,42861480,4186370,42861478,42570689,42861479,4346475,45716057,45716056,45833077,42861304,40232795,45712599,45729683,45833075,42626362,42850922,4340490,4186372,42850923,45833070,45833083,45833084,40149509,40149510,4299653,2004063,4073144,45683239,19100267,45627967,45681498,45667498,19079531,45654715,45688503,45980667,46112116,46036220,46175385,45987754,46120629,46041437,46181428,46034428,46173270,46034666,46173540,45987530,46120381,45980671,46112120,46017765,46154776,45987756,46120632,46034114,46172914,46031779,46170262,46034668,46173542,46020945,46158181,45987664,46120530)

) I
) C UNION ALL 
SELECT 4 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (40239056,1344381,4022105,19058410,42900250,1549080,1551673,1356461,1366310,1366773,1351541,1315286,1596779,1586808,1343039)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (40239056,1344381,4022105,19058410,42900250,1549080,1551673,1356461,1366310,1366773,1351541,1315286,1596779,1586808,1343039)
  and c.invalid_reason is null

) I
) C UNION ALL 
SELECT 5 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (2108678,2110046,2108724,2110044,2003971,4239543,4071665,2003983,2003970,2003982,4211496,4235738,2110036,2110035,2110037,2110039,4096783,2003969,4276520,4187904,2780477,4194172,2003968,4147673,4078386,2003967,4263480,4054558)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (2108678,2110046,2108724,2110044,2003971,4239543,4071665,2003983,2003970,2003982,4211496,4235738,2110036,2110035,2110037,2110039,4096783,2003969,4276520,4187904,2780477,4194172,2003968,4147673,4078386,2003967,4263480,4054558)
  and c.invalid_reason is null

) I
LEFT JOIN
(
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (2110026,2003947,4176312,2109833,2003966,4343105,2003965,2109825,4073700,4234536,2003964,4071791)

) E ON I.concept_id = E.concept_id
WHERE E.concept_id is null
) C UNION ALL 
SELECT 6 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (2004064,2103796,2109986,4145907,2109974,2109975,2109976,2109973,44512827,4314682,4021070,2004065,2004066,4242876,2004063)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (2004064,2103796,2109986,4145907,2109974,2109975,2109976,2109973,44512827,4314682,4021070,2004065,2004066,4242876,2004063)
  and c.invalid_reason is null

) I
LEFT JOIN
(
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (2101071)

) E ON I.concept_id = E.concept_id
WHERE E.concept_id is null
) C UNION ALL 
SELECT 7 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4278515)
UNION  select c.concept_id
  from @vocabulary_database_schema.CONCEPT c
  join @vocabulary_database_schema.CONCEPT_ANCESTOR ca on c.concept_id = ca.descendant_concept_id
  and ca.ancestor_concept_id in (4278515)
  and c.invalid_reason is null

) I
) C UNION ALL 
SELECT 8 as codeset_id, c.concept_id FROM (select distinct I.concept_id FROM
( 
  select concept_id from @vocabulary_database_schema.CONCEPT where concept_id in (4180749,44820371,45600358)

) I
) C
;

with primary_events (event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id) as
(
-- Begin Primary Events
select P.ordinal as event_id, P.person_id, P.start_date, P.end_date, op_start_date, op_end_date, cast(P.visit_occurrence_id as bigint) as visit_occurrence_id
FROM
(
  select E.person_id, E.start_date, E.end_date,
         row_number() OVER (PARTITION BY E.person_id ORDER BY E.sort_date ASC) ordinal,
         OP.observation_period_start_date as op_start_date, OP.observation_period_end_date as op_end_date, cast(E.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM 
  (
  -- Begin Procedure Occurrence Criteria
select C.person_id, C.procedure_occurrence_id as event_id, C.procedure_date as start_date, DATEADD(d,1,C.procedure_date) as END_DATE,
       C.visit_occurrence_id, C.procedure_date as sort_date
from 
(
  select po.* 
  FROM @cdm_database_schema.PROCEDURE_OCCURRENCE po
JOIN #Codesets codesets on ((po.procedure_concept_id = codesets.concept_id and codesets.codeset_id = 7))
) C

WHERE C.procedure_date >= DATEFROMPARTS(2000, 1, 1)
-- End Procedure Occurrence Criteria

  ) E
	JOIN @cdm_database_schema.observation_period OP on E.person_id = OP.person_id and E.start_date >=  OP.observation_period_start_date and E.start_date <= op.observation_period_end_date
  WHERE DATEADD(day,90,OP.OBSERVATION_PERIOD_START_DATE) <= E.START_DATE AND DATEADD(day,0,E.START_DATE) <= OP.OBSERVATION_PERIOD_END_DATE
) P
WHERE P.ordinal = 1
-- End Primary Events

)
SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, visit_occurrence_id
INTO #qualified_events
FROM
(
  select pe.event_id, pe.person_id, pe.start_date, pe.end_date, pe.op_start_date, pe.op_end_date, row_number() over (partition by pe.person_id order by pe.start_date ASC) as ordinal, cast(pe.visit_occurrence_id as bigint) as visit_occurrence_id
  FROM primary_events pe

) QE

;

--- Inclusion Rule Inserts

select 0 as inclusion_rule_id, person_id, event_id
INTO #Inclusion_0
FROM
(
  select pe.person_id, pe.event_id
  FROM #qualified_events pe

JOIN (
-- Begin Criteria Group
select 0 as index_id, person_id, event_id
FROM
(
  select E.person_id, E.event_id
  FROM #qualified_events E
  INNER JOIN
  (
    -- Begin Demographic Criteria
SELECT 0 as index_id, e.person_id, e.event_id
FROM #qualified_events E
JOIN @cdm_database_schema.PERSON P ON P.PERSON_ID = E.PERSON_ID
WHERE (YEAR(E.start_date) - P.year_of_birth >= 40 and YEAR(E.start_date) - P.year_of_birth <= 80)
GROUP BY e.person_id, e.event_id
-- End Demographic Criteria

  ) CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
  GROUP BY E.person_id, E.event_id
  HAVING COUNT(index_id) = 1
) G
-- End Criteria Group
) AC on AC.person_id = pe.person_id AND AC.event_id = pe.event_id
) Results
;

select 1 as inclusion_rule_id, person_id, event_id
INTO #Inclusion_1
FROM
(
  select pe.person_id, pe.event_id
  FROM #qualified_events pe

JOIN (
-- Begin Criteria Group
select 0 as index_id, person_id, event_id
FROM
(
  select E.person_id, E.event_id
  FROM #qualified_events E
  INNER JOIN
  (
    -- Begin Demographic Criteria
SELECT 0 as index_id, e.person_id, e.event_id
FROM #qualified_events E
JOIN @cdm_database_schema.PERSON P ON P.PERSON_ID = E.PERSON_ID
WHERE P.gender_concept_id in (3195710,45766034,8507)
GROUP BY e.person_id, e.event_id
-- End Demographic Criteria

  ) CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
  GROUP BY E.person_id, E.event_id
  HAVING COUNT(index_id) = 1
) G
-- End Criteria Group
) AC on AC.person_id = pe.person_id AND AC.event_id = pe.event_id
) Results
;

select 2 as inclusion_rule_id, person_id, event_id
INTO #Inclusion_2
FROM
(
  select pe.person_id, pe.event_id
  FROM #qualified_events pe

JOIN (
-- Begin Criteria Group
select 0 as index_id, person_id, event_id
FROM
(
  select E.person_id, E.event_id
  FROM #qualified_events E
  INNER JOIN
  (
    -- Begin Correlated Criteria
select 0 as index_id, cc.person_id, cc.event_id
from (SELECT p.person_id, p.event_id
FROM #qualified_events P
JOIN (
  -- Begin Condition Occurrence Criteria
SELECT C.person_id, C.condition_occurrence_id as event_id, C.condition_start_date as start_date, COALESCE(C.condition_end_date, DATEADD(day,1,C.condition_start_date)) as end_date,
  C.visit_occurrence_id, C.condition_start_date as sort_date
FROM
(
  SELECT co.*
  FROM @cdm_database_schema.CONDITION_OCCURRENCE co
  JOIN #Codesets codesets on ((co.condition_concept_id = codesets.concept_id and codesets.codeset_id = 0))
) C


-- End Condition Occurrence Criteria

) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= DATEADD(day,0,P.START_DATE) AND A.START_DATE <= DATEADD(day,90,P.START_DATE) ) cc
GROUP BY cc.person_id, cc.event_id
HAVING COUNT(cc.event_id) >= 1
-- End Correlated Criteria

  ) CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
  GROUP BY E.person_id, E.event_id
  HAVING COUNT(index_id) = 1
) G
-- End Criteria Group
) AC on AC.person_id = pe.person_id AND AC.event_id = pe.event_id
) Results
;

select 3 as inclusion_rule_id, person_id, event_id
INTO #Inclusion_3
FROM
(
  select pe.person_id, pe.event_id
  FROM #qualified_events pe

JOIN (
-- Begin Criteria Group
select 0 as index_id, person_id, event_id
FROM
(
  select E.person_id, E.event_id
  FROM #qualified_events E
  INNER JOIN
  (
    -- Begin Correlated Criteria
select 0 as index_id, p.person_id, p.event_id
from #qualified_events p
LEFT JOIN (
SELECT p.person_id, p.event_id
FROM #qualified_events P
JOIN (
  -- Begin Observation Criteria
select C.person_id, C.observation_id as event_id, C.observation_date as start_date, DATEADD(d,1,C.observation_date) as END_DATE,
       C.visit_occurrence_id, C.observation_date as sort_date
from
(
  select o.*
  FROM @cdm_database_schema.OBSERVATION o
JOIN #Codesets codesets on ((o.observation_concept_id = codesets.concept_id and codesets.codeset_id = 8))
) C


-- End Observation Criteria

) A on A.person_id = P.person_id  AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= P.OP_END_DATE AND A.START_DATE >= P.OP_START_DATE AND A.START_DATE <= DATEADD(day,-30,P.START_DATE) ) cc on p.person_id = cc.person_id and p.event_id = cc.event_id
GROUP BY p.person_id, p.event_id
HAVING COUNT(cc.event_id) = 0
-- End Correlated Criteria

  ) CQ on E.person_id = CQ.person_id and E.event_id = CQ.event_id
  GROUP BY E.person_id, E.event_id
  HAVING COUNT(index_id) = 1
) G
-- End Criteria Group
) AC on AC.person_id = pe.person_id AND AC.event_id = pe.event_id
) Results
;

SELECT inclusion_rule_id, person_id, event_id
INTO #inclusion_events
FROM (select inclusion_rule_id, person_id, event_id from #Inclusion_0
UNION ALL
select inclusion_rule_id, person_id, event_id from #Inclusion_1
UNION ALL
select inclusion_rule_id, person_id, event_id from #Inclusion_2
UNION ALL
select inclusion_rule_id, person_id, event_id from #Inclusion_3) I;
TRUNCATE TABLE #Inclusion_0;
DROP TABLE #Inclusion_0;

TRUNCATE TABLE #Inclusion_1;
DROP TABLE #Inclusion_1;

TRUNCATE TABLE #Inclusion_2;
DROP TABLE #Inclusion_2;

TRUNCATE TABLE #Inclusion_3;
DROP TABLE #Inclusion_3;


with cteIncludedEvents(event_id, person_id, start_date, end_date, op_start_date, op_end_date, ordinal) as
(
  SELECT event_id, person_id, start_date, end_date, op_start_date, op_end_date, row_number() over (partition by person_id order by start_date ASC) as ordinal
  from
  (
    select Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date, SUM(coalesce(POWER(cast(2 as bigint), I.inclusion_rule_id), 0)) as inclusion_rule_mask
    from #qualified_events Q
    LEFT JOIN #inclusion_events I on I.person_id = Q.person_id and I.event_id = Q.event_id
    GROUP BY Q.event_id, Q.person_id, Q.start_date, Q.end_date, Q.op_start_date, Q.op_end_date
  ) MG -- matching groups

  -- the matching group with all bits set ( POWER(2,# of inclusion rules) - 1 = inclusion_rule_mask
  WHERE (MG.inclusion_rule_mask = POWER(cast(2 as bigint),4)-1)

)
select event_id, person_id, start_date, end_date, op_start_date, op_end_date
into #included_events
FROM cteIncludedEvents Results
WHERE Results.ordinal = 1
;



-- generate cohort periods into #final_cohort
with cohort_ends (event_id, person_id, end_date) as
(
	-- cohort exit dates
  -- By default, cohort exit at the event's op end date
select event_id, person_id, op_end_date as end_date from #included_events
),
first_ends (person_id, start_date, end_date) as
(
	select F.person_id, F.start_date, F.end_date
	FROM (
	  select I.event_id, I.person_id, I.start_date, E.end_date, row_number() over (partition by I.person_id, I.event_id order by E.end_date) as ordinal
	  from #included_events I
	  join cohort_ends E on I.event_id = E.event_id and I.person_id = E.person_id and E.end_date >= I.start_date
	) F
	WHERE F.ordinal = 1
)
select person_id, start_date, end_date
INTO #cohort_rows
from first_ends;

with cteEndDates (person_id, end_date) AS -- the magic
(
	SELECT
		person_id
		, DATEADD(day,-1 * 0, event_date)  as end_date
	FROM
	(
		SELECT
			person_id
			, event_date
			, event_type
			, MAX(start_ordinal) OVER (PARTITION BY person_id ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal
			, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY event_date, event_type) AS overall_ord
		FROM
		(
			SELECT
				person_id
				, start_date AS event_date
				, -1 AS event_type
				, ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY start_date) AS start_ordinal
			FROM #cohort_rows

			UNION ALL


			SELECT
				person_id
				, DATEADD(day,0,end_date) as end_date
				, 1 AS event_type
				, NULL
			FROM #cohort_rows
		) RAWDATA
	) e
	WHERE (2 * e.start_ordinal) - e.overall_ord = 0
),
cteEnds (person_id, start_date, end_date) AS
(
	SELECT
		 c.person_id
		, c.start_date
		, MIN(e.end_date) AS end_date
	FROM #cohort_rows c
	JOIN cteEndDates e ON c.person_id = e.person_id AND e.end_date >= c.start_date
	GROUP BY c.person_id, c.start_date
)
select person_id, min(start_date) as start_date, end_date
into #final_cohort
from cteEnds
group by person_id, end_date
;

DELETE FROM @target_database_schema.@target_cohort_table where cohort_definition_id = @target_cohort_id;
INSERT INTO @target_database_schema.@target_cohort_table (cohort_definition_id, subject_id, cohort_start_date, cohort_end_date)
select @target_cohort_id as cohort_definition_id, person_id, start_date, end_date
FROM #final_cohort CO
;






TRUNCATE TABLE #cohort_rows;
DROP TABLE #cohort_rows;

TRUNCATE TABLE #final_cohort;
DROP TABLE #final_cohort;

TRUNCATE TABLE #inclusion_events;
DROP TABLE #inclusion_events;

TRUNCATE TABLE #qualified_events;
DROP TABLE #qualified_events;

TRUNCATE TABLE #included_events;
DROP TABLE #included_events;

TRUNCATE TABLE #Codesets;
DROP TABLE #Codesets;