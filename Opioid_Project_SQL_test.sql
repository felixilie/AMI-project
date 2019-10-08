--Part 1

libname analysis "D:\Opioid\analysis";
libname optx "D:\Opioid\treatment";
libname opdx "D:\Opioid\diagnoses";
libname elig "D:\Eligibility";
libname cw "D:\Cross Walks";

proc sql;
create table analysis.dx_hospital as
select a.*, b.OUDP
from analysis.dx_hospital as a
left join
    (select distinct dx_cd, dx_label, 1 as OUDP from opdx.dx_opioid (where /*= is a typo*/ =(dx_cd_type="icd10" and (OUD=1 or OPP=1)))) as b
    on a.dx_cd = b.dx_cd;
quit;

proc sql;
create table analysis.dx_hospital_unique as
select distinct new_tcn, patient_id, srv_dt_adj, trueadm, truedisch, prov_ID,
-- another typo trueadm should be trueadm
cos_final,
max(OUPD) as OUDP /* Typo OUPD vs OUDP */
from analysis.dx_hospital
group by new_tcn;

create table analysis.dx_hospital_unique as
select distinct a.*, b.prov_name
from analysis.dx_hospital_unique as a left join
cw.provider as b
on a.bill_prov_id = b.prov_id;
quit;

proc sql;
create table analysis.demo_dx as
select *
from
(
    select distinct patient_id, prov_name,
    max(OUDP) as OUDP
    from analysis.dx_hospital_unique
    group by patient_id, prov_name
) as a

left join
elig.eligibility
on a.patient_id = b.patient_id
;
quit;

proc sql;
create table analysis.dx_hospital_opioid as
select *
from analysis.dx_hospital_unique
where OUDP=1;
quit;

proc sql;
create table analysis.dx_hospital_opioid as
select distinct a.*,
sum(case when(tx_cd=1) then 1 else 0 end) as tx1_14,
(case when(tx_cd=1) then min(b.srv_dt_adj) end) as first_tx1_dt
format=mmddyys10.,
sum(case when(tx_cd=2) then 1 else 0 end) as tx1_14, --should be as tx2_14 etc.
(case when(tx_cd=2) then min(b.srv_dt_adj) end) as first_tx2_dt
format=mmddyys10.,
sum(case when(tx_cd=3) then 1 else 0 end) as tx1_14, --should be as tx3_14 etc.
(case when(tx_cd=3) then min(b.srv_dt_adj) end) as first_tx3_dt
format=mmddyys10.,
sum(case when(tx_cd=4) then 1 else 0 end) as tx1_14, --should be as tx4_14 etc.
(case when(tx_cd=4) then min(b.srv_dt_adj) end) as first_tx4_dt
format=mmddyys10. --was a comma here - typo

from
analysis.dx_hospital_opioid as a
left join
opdx.tx_opioid as b
on a.patient_id = b.patient_id
-- This is SAS syntax, checking the patient was at the hospital for less than 14 days
and 0 <= INTCK('DAY', b.srv_dt_adj, a.truedisch) <= 14
and b.new_tcn ^= ""
group by a.patient_id, a.truedisch
;
quit;

data analysis.dx_hospital_opioid;
set analysis.dx_hospital_opioid;
if tx1_14 > 0 then optx_14 = 1;
else if tx2_14 > 0 then optx_14 = 2;
else if tx3_14 > 0 then optx_14 = 3;
else if tx4_14 > 0 or rx_14>0 then optx_14 = 4;
else optx_14 = 5;
run;

data analysis.dx_hospital_opioid;
set analysis.dx_hospital_opioid;
format tx_start_dt mmddyys10.;
if first_tx1_dt ne . or first_tx2_dt ne . or first_tx3_dt ne . or
first_tx4_dt ne . then do;
tx_start_dt = min(of first_tx1_dt first_tx2_dt first_tx3_dt first_tx4_dt);
end;
run;

proc sql;
create table analysis.dx_hospital_opioid as
select distinct a.*,

sum(case when(tx_cd = 1) then 1 else 0 end) as tx1_30,
sum(case when(tx_cd = 2) then 1 else 0 end) as tx1_30, --shouldb be as tx2_30 etc.
sum(case when(tx_cd = 3) then 1 else 0 end) as tx1_30, --shouldb be as tx3_30 etc.
sum(case when(tx_cd = 4) then 1 else 0 end) as tx1_30, --shouldb be as tx4_30 etc.
--was a comma here in too - typo

from
analysis.dx_hospital_opioid as a
left join
opdx.tx_opioid as b
on a.patient_id = b.patient_id
and 0 < INTCK('DAY', b.srv_dt_adj, a.tx_start_dt) <= 30
and a.tx_start_dt ^= .
group by a.patient_id, a.tx_start_dt
;
quit;

data analysis.dx_hospital_opioid;
set analysis.dx_hospital_unique;
n_tx_30 = sum(of tx1_30 tx2_30 tx3_30, tx4_30);
if sum(of tx1_30 tx2_30 tx3_30, tx4_30) >= 2 then do;
    if tx1_30 > 0 then optx_30 = 1;
    else if tx2_30 > 0 then optx_30 = 2;
    else if tx3_30 > 0 then optx_30 = 3;
    else if tx4_30 > 0 then optx_30 = 4;
end;
else if optx_30 =. then optx_30 = 5;
run;


--Part 2
-- this part is just to print the tables we create on part 1 I assume

proc format;

picture pctfmt
low-high = "0009.1%";

value racef
    0 = '06 unknown'
    1 = '04 White'
    2 = '02 Black'
    3 = '01 Asian'
    4 = '05 Other'
    5 = '03 Hispanic'

value malef
    1 = 'male'
    0 = 'female'
    . = 'unknown'
    ;

run;

/*1*/
proc tabulate data=analysis.dx_hospital_unique missing;
class OUDP prov_name;
table
all
prov_name*n*f=comma12.0
,
all
OUDP
;
run;

/*2*/
proc tabulate data=analysis.demo_dx missing;
class OUDP/descending;
class
agecat7
male
dual
;
class race/ascending order=formatted;
var age;
format male malef. race racef.;
table

all*f=comma12.0
age*(mean)*f=10.1
agecat7*(pctn<agecat7>)*f=pctfmt.
male*(pctn<male>)*f=pctfmt.
race*(pctn<race>)*f=pctfmt.
,
all
*OUDP
;
run;

/*3*/
proc tabulate data=analysis.demo_dx missing;
class OUDP/descending;
class prov_name/ascending;
class
agecat7
male
dual
;
class race/ascending order=formatted;
var age;
format male malef. race racef.;
table

all*f=comma12.0
age*(mean)*f=10.1
agecat7*(pctn<agecat7>)*f=pctfmt.
male*(pctn<male>)*f=pctfmt.
race*(pctn<race>)*f=pctfmt.
,
all
*prov_name
;
run;

/*4*/
proc tabulate data=analysis.demo_dx missing;
where OUDP=1;
class OUDP/descending;
class prov_name/ascending;
class
agecat7
male
dual
;
class race/ascending order=formatted;
var age;
format male malef. race racef.;
table

all*f=comma12.0
age*(mean)*f=10.1
agecat7*(pctn<agecat7>)*f=pctfmt.
male*(pctn<male>)*f=pctfmt.
race*(pctn<race>)*f=pctfmt.
,
all
*prov_name
;
run;

/*5*/
proc tabulate data=analysis.dx_hospital_opioid missing;
class optx_14 prov_name/ascending;
table
all
optx_14*n*f=comma12.0
,
all
all*prov_name
;
run;

/*6*/
proc tabulate data=analysis.dx_hospital_opioid missing;
where tx_start_dt ^=.;
class optx_30 prov_name/ascending;
var tx_start_dt;
table
all
optx_30*n*f=comma12.0
,
all
all*prov_name
;
run;