CREATE TABLE DX_hospital (
    DX_hospital_ID INT AUTO_INCREMENT PRIMARY KEY,
    New_Tcn INT,
    Patient_id INT,
    DX_CD VARCHAR(255) NOT NULL,
    Srv_dt_adj DATE,
    Truadm DATE,
    truedisch DATE,
    prov_id INT
);

CREATE TABLE DX_opioid (
    DX_opioid_ID INT AUTO_INCREMENT PRIMARY KEY,
    New_Tcn INT,
    Patient_id INT,
    DX_CD VARCHAR(255) NOT NULL,
    dx_label VARCHAR(255),
    Srv_dt_adj DATE,
    prov_id INT,
    OUD TINYINT,
    OPP TINYINT,
    OAE TINYINT,
    Cos_final VARCHAR(255)
);

CREATE TABLE tx_opioid (
    New_Tcn INT,
    Patient_id INT,
    TX_CD INT,
    Srv_dt_adj DATE,
    prov_id INT
);

CREATE TABLE eligibility (
    Patient_id INT PRIMARY KEY,
    Age INT,
    Race INT,
    Gender INT
);

CREATE TABLE provider (
    prov_id INT AUTO_INCREMENT PRIMARY KEY,
    prov_name VARCHAR(255) NOT NULL
);

INSERT INTO DX_hospital (New_Tcn, Patient_id, DX_CD, Srv_dt_adj, Truadm,truedisch,prov_id)
VALUES 
  (1, 129, 'Q22', '2016-5-20', '2018-5-23','2018-5-27',3),
  (1, 129, 'F11.21', '2016-5-20', '2018-5-23','2018-5-27',3),
  (2, 123, 'F11.22', '2018-10-20', '2018-10-23','2018-10-27',5),
  (2, 123, 'F11.21', '2018-10-20', '2018-10-23','2018-10-27',5),
  (2, 123, 'F11.20', '2018-10-20', '2018-10-23','2018-10-27',5),
  (2, 123, 'Q22', '2018-10-20', '2018-10-23','2018-10-27',5),
  (3, 124, 'F11.22', '2018-10-21', '2018-10-24','2018-10-28',4),
  (3, 124, 'F11.21', '2018-10-21', '2018-10-24','2018-10-28',4),
  (4, 125, 'F11.22', '2018-9-20', '2018-9-23','2018-9-27',5),
  (5, 126, 'Q22', '2017-9-20', '2017-9-23','2017-9-27',5),
  (6, 127, 'Q22', '2017-9-20', '2017-9-23','2017-9-27',5),
  (7, 128, 'F11.20', '2017-9-20', '2017-9-23','2017-9-27',2);
  
INSERT INTO dx_opioid (New_Tcn, Patient_id, DX_CD, dx_label, Srv_dt_adj, prov_id, OUD, OPP, OAE, Cos_final)
VALUES 
  (1, 129, 'F11.21', 'op a', '2016-5-20', 3, 1, 0, 0,'in'),
  (2, 123, 'F11.22', 'op b', '2018-10-20', 5, 0, 1, 0,'out'),
  (2, 123, 'F11.21', 'op a', '2018-10-20', 5, 1, 0, 0,'out'),
  (2, 123, 'F11.20', 'op c', '2018-10-20', 5, 0, 0, 1,'out'),
  (3, 124, 'F11.22', 'op b', '2018-10-21', 4, 0, 1, 0,'in'),
  (3, 124, 'F11.21', 'op a', '2018-10-21', 4, 1, 0, 0,'in'),
  (4, 125, 'F11.22', 'op b', '2018-9-20', 5, 0, 1, 0,'out'),
  (7, 128, 'F11.20', 'op c', '2017-9-20', 2, 0, 0, 1, 'in');
  
INSERT INTO provider (prov_name)
VALUES
  ('Rambam'),
  ('rockefeller'),
  ('Sloan'),
  ('NYU'),
  ('Mount Sinai');
  
INSERT INTO eligibility (Patient_id, Age, Race, Gender)
VALUES
  ('123', 33, 1, 1),
  ('124', 33, 1, 1),
  ('125', 33, 1, 1),
  ('126', 33, 1, 1),
  ('127', 33, 1, 1),
  ('128', 33, 1, 1),
  ('129', 33, 1, 1);
  
INSERT INTO tx_opioid (New_Tcn, Patient_id, TX_CD, Srv_dt_adj, prov_id)
VALUES
  (1, 129, 1, '2016-5-20', 3),
  (1, 129, 1, '2017-5-20', 3),
  (1, 129, 1, '2016-5-20', 3),
  (1, 129, 2, '2016-5-20', 3),
  (1, 129, 3, '2016-5-20', 3),
  (1, 129, 4, '2016-5-20', 3),
  (2, 123, 2, '2018-10-20', 5),
  (2, 123, 4, '2018-10-20', 5),
  (3, 124, 4, '2018-10-21', 4),
  (4, 125, 3, '2018-9-20', 5),
  (4, 125, 4, '2018-9-20', 5),
  (7, 128, 2, '2017-9-20', 2);


create table dx_hospital1 as
select a.*, b.OUDP
from dx_hospital as a
left join
    (select distinct dx_cd, dx_label, 1 as OUDP from dx_opioid where (OUD=1 or OPP=1)) as b
    on a.dx_cd = b.dx_cd;

create table dx_hospital_unique as
select distinct new_tcn, patient_id, srv_dt_adj, truadm, truedisch, prov_ID,
max(OUDP) as OUDP
from dx_hospital1
group by new_tcn;

create table dx_hospital_unique1 as
select distinct a.*, b.prov_name
from dx_hospital_unique as a left join
provider as b
on a.prov_id = b.prov_id;

create table dx_hospital_opioid as
select *
from dx_hospital_unique1
where OUDP=1;

create table dx_hospital_opioid1 as
select distinct a.*,
sum(case when(tx_cd=1) then 1 else 0 end) as tx1_14,
(case when(tx_cd=1) then min(b.srv_dt_adj) end) as first_tx1_dt,
sum(case when(tx_cd=2) then 1 else 0 end) as tx2_14,
(case when(tx_cd=2) then min(b.srv_dt_adj) end) as first_tx2_dt,
sum(case when(tx_cd=3) then 1 else 0 end) as tx3_14,
(case when(tx_cd=3) then min(b.srv_dt_adj) end) as first_tx3_dt,
sum(case when(tx_cd=4) then 1 else 0 end) as tx4_14,
(case when(tx_cd=4) then min(b.srv_dt_adj) end) as first_tx4_dt

from
dx_hospital_opioid as a
left join
tx_opioid as b
on a.patient_id = b.patient_id
group by a.patient_id, a.truedisch;

create table dx_hospital_opioid2 as
select distinct a.*,
sum(case when(tx_cd = 1) then 1 else 0 end) as tx1_30,
sum(case when(tx_cd = 2) then 1 else 0 end) as tx2_30,
sum(case when(tx_cd = 3) then 1 else 0 end) as tx3_30,
sum(case when(tx_cd = 4) then 1 else 0 end) as tx4_30

from
dx_hospital_opioid as a
left join
tx_opioid as b
on a.patient_id = b.patient_id
group by a.patient_id