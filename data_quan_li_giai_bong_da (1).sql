--
-- PostgreSQL database football tournament
--


---
--- drop tables
---

DROP TABLE IF EXISTS match_squad;
DROP TABLE IF EXISTS match_team;
DROP TABLE IF EXISTS referee_match;
DROP TABLE IF EXISTS goal;
DROP TABLE IF EXISTS ticket;
DROP TABLE IF EXISTS card;
DROP TABLE IF EXISTS match;
DROP TABLE IF EXISTS referee;
DROP TABLE IF EXISTS stand;
DROP TABLE IF EXISTS stadium;
DROP TABLE IF EXISTS member;
DROP TABLE IF EXISTS customer;
DROP TABLE IF EXISTS team;
DROP TABLE IF EXISTS coach;


--
-- Name: team; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE Team (
    TeamID char(10) NOT NULL,
    TeamName VARCHAR(50),
    CaptainID char(10) NOT NULL,
    CoachID char(10) NOT NULL,
    Groupteam char(10) NOT NULL
);

--
-- Name: coach; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE Coach (
    CoachID char(10) NOT NULL,
    CoachName VARCHAR(50),
    DOB DATE NOT NULL,
    Country varchar(50)
);

--
-- Name: member; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE Member (
    MemberID CHAR(10) NOT NULL,
    TeamID char(10) NOT NULL,
    MemberName VARCHAR(50),
    DOB DATE NOT NULL,
    YellowCard int,
    RedCard int,
    TotalGoal int
);

--
-- Name: stadium; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE stadium (
    stadiumid CHAR(10) NOT NULL,
    stadiumName VARCHAR(50),
    address varchar(100)
);

--
-- Name: match; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE match (
    MatchID CHAR(10) NOT NULL,
    time timestamp,
    stadiumid CHAR(10) NOT NULL,
    round varchar(50)
);

--
-- Name: card; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE Card (
    MemberID CHAR(10) NOT NULL,
    MatchID char(10) NOT NULL,
    Type VARCHAR(50) NOT NULL,
    Time timestamp
);

--
-- Name: goal; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE Goal (
    GoalID CHAR(10) NOT NULL,
    MatchID char(10) NOT NULL,
    MemberID CHAR(10) NOT NULL,
    Time timestamp
);

--
-- Name: stand; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE stand (
    standID CHAR(10) NOT NULL,
    amount int,
    price money,
    stadiumid CHAR(10) NOT NULL
);

--
-- Name: customer; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE customer (
    CustomerID CHAR(10) NOT NULL,
    CustomerName VARCHAR(50),
    DOB DATE NOT NULL
);

--
-- Name: ticket; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE Ticket (
    TicketID CHAR(20) NOT NULL,
    StandID char(10) NOT NULL,
    CustomerID CHAR(10) NOT NULL,
    MatchID CHAR(10) NOT NULL
);

--
-- Name: match_team; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE match_team (
    MatchID CHAR(10) NOT NULL,
    teamid_1 char(10) not null,
    teamid_2 char(10) not null,
    scoreteam_1 int,
    scoreteam_2 int,
    WinTeamID char(10)
);

--
-- Name: match_squad; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE match_squad (
    MatchID CHAR(10) NOT NULL,
    MemberID char(10) not null,
    position varchar(20)
);

--
-- Name: referee; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE referee (
    refereeid char(10) not null,
    RefereeName VARCHAR(50),
    DOB DATE NOT NULL,
    Country varchar(50)
);

--
-- Name: referee_match; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE referee_match (
    MatchID CHAR(10) NOT NULL,
    refereeid char(10) not null
);

------------------------------------------------------------------
--
--Triggers and fuctions
--
--after insert new card then yellow card or red card of member will be change
--TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION number_after_insert_card() RETURNS TRIGGER AS $$
BEGIN
    IF lower(NEW.type) = 'yellowcard' THEN
        UPDATE member
        SET YellowCard = YellowCard +1
        WHERE memberid = NEW.memberid;
    END IF;
    IF lower(NEW.type) = 'redcard' THEN
        UPDATE member
        SET RedCard = RedCard +1
        WHERE memberid = NEW.memberid;
    END IF;
    RETURN NEW;
END;
$$LANGUAGE plpgsql;
--CREARE TRIGGER
CREATE TRIGGER after_insert_card
AFTER INSERT ON card
FOR EACH ROW
WHEN (NEW.memberid IS NOT NULL)
EXECUTE PROCEDURE number_after_insert_card();

--
--  After insert new goal then total goal of member will be change
--
CREATE OR REPLACE FUNCTION number_after_insert_goal() RETURNS TRIGGER AS $$
BEGIN
    UPDATE member
    SET TotalGoal = TotalGoal +1
    WHERE memberid = NEW.memberid;
    RETURN NEW;
END;
$$LANGUAGE plpgsql;
--CREARE TRIGGER
CREATE TRIGGER after_insert_goal
AFTER INSERT ON goal
FOR EACH ROW
WHEN (NEW.goalid IS NOT NULL)
EXECUTE PROCEDURE number_after_insert_goal();

--
--  When the number of tickets in the stands is full, no more tickets can be purchased
--
--
CREATE OR REPLACE FUNCTION f_insert_ticket_limit() RETURNS TRIGGER AS
$$
DECLARE
    slv int := 0;
    slv_khan_dai int := 0;
BEGIN
    SELECT INTO slv COUNT(*) FROM ticket
    WHERE standID = NEW.standID and MatchID = NEW.MatchID;

    SELECT INTO slv_khan_dai amount
    FROM stand
    WHERE standid = NEW.standID;
    IF slv > slv_khan_dai  THEN
        RAISE 'Ve cua khan dai nay da ban het, Vui long chọn khan dai khac!'; --Dua ra thong bao
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;

END;
$$
LANGUAGE plpgsql;
--
CREATE TRIGGER insert_ticket_limit
BEFORE INSERT ON ticket
FOR EACH ROW
EXECUTE PROCEDURE f_insert_ticket_limit();
--
--  When have new match then yellow card and red car of all members will be = 0
--
-- FUNCTION
CREATE OR REPLACE FUNCTION f_after_update_match_team() RETURNS TRIGGER AS
$$
BEGIN
    
        UPDATE member
        SET yellowcard = 0, redcard = 0;
		RETURN NEW;
END;
$$
LANGUAGE plpgsql;
--TRIGGER 
--
CREATE TRIGGER after_update_match_team
AFTER INSERT OR UPDATE ON match_team
FOR EACH ROW
WHEN (NEW.WinTeamID IS NOT NULL)
EXECUTE PROCEDURE f_after_update_match_team();

--
--  The referee cannot choose a player for the next match if the previous match has 2 yellow cards or 1 red card
--
--TRIGGER FUNCTION
CREATE OR REPLACE FUNCTION f_after_referee_insert() RETURNS TRIGGER AS $$
DECLARE
    sl_cau_thu int := 0;
    the_vang int:= 0;
    the_do int:=0;
BEGIN
    SELECT INTO sl_cau_thu COUNT(*) FROM Match_squad
    WHERE MatchID = NEW.MatchID;
    SELECT INTO the_do redcard FROM member
    WHERE MemberID = NEW.MemberID;
    SELECT INTO the_vang yellowcard FROM member
    WHERE MemberID = NEW.MemberID;
    IF sl_cau_thu >= 23  THEN
        RAISE 'Ban chi duoc chon 22 cau thu de ra san!'; --Dua ra thong bao
        RETURN NULL;
    END IF;
    IF (the_vang >= 2) or (the_do >= 1) THEN
        RAISE 'Ban khong chon duoc cau thu nay vi tran dau truoc cau thu nay da nhan so the phat qua quy dinh!';
        RETURN NULL;
    ELSE
        RETURN NEW;
    END IF;
END;
$$
LANGUAGE plpgsql;
--Định nghĩa TRIGGER
CREATE TRIGGER after_referee_insert
AFTER INSERT ON Match_squad
FOR EACH ROW
WHEN (NEW.MatchID IS NOT NULL)
EXECUTE PROCEDURE f_after_referee_insert();

-----------------------------------------------------------------
--
-- Data for Name: coach; Type: TABLE DATA; Schema: public; Owner: 
--

INSERT INTO coach VALUES ('NED00','Louis van Gaal','08/08/1951','Hà Lan');
INSERT INTO coach VALUES ('QAT00','Felix Sanchez','12/13/1975','Tây Ban Nha');
INSERT INTO coach VALUES ('POR00','Fernando Santos','10/10/1954','Bồ Đào Nha');
INSERT INTO coach VALUES ('USA00','Gregg Berhalter','08/01/1973','Mỹ');
INSERT INTO coach VALUES ('GER00','Hans-Dieter Flick','02/24/1965','Đức');
INSERT INTO coach VALUES ('BRA00','Tite','05/25/1961','Brazil');

--
-- Data for Name: team; Type: TABLE DATA; Schema: public; Owner: -
--
INSERT INTO Team VALUES ('GER', 'Đức', 'GER01','GER00','B');
INSERT INTO Team VALUES ('BRA', 'Brazil', 'BRA03','BRA00','B');
INSERT INTO Team VALUES ('NED', 'Hà Lan', 'NED04','NED00','A');
INSERT INTO Team VALUES ('QAT', 'Qatar', 'QAT10','QAT00','A');
INSERT INTO Team VALUES ('POR', 'Bồ Đào Nha', 'POR07','POR00','A');
INSERT INTO Team VALUES ('USA', 'Mỹ', 'USA10','USA00','B');

--
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO customer VALUES ('20204992', 'Nguyễn Duy Khánh', '07/14/2002');
INSERT INTO customer VALUES ('20200203', 'Mai Thu Hiền', '07/01/2002');
INSERT INTO customer VALUES ('20200364', 'Nguyễn Hoàng Long', '06/02/2002');
INSERT INTO customer VALUES ('20200310', 'Nguyễn Hữu Khải', '08/05/2002');
INSERT INTO customer VALUES ('20200042', 'Quách Đức Anh', '08/24/2002');
INSERT INTO customer VALUES ('20205090', 'Nguyễn Trung Kiên', '06/03/2002');
INSERT INTO customer VALUES ('20205100', 'Đào Xuân Minh', '10/20/2002');
INSERT INTO customer VALUES ('20205122', 'Trần Thị Như Quỳnh', '09/14/2002');
INSERT INTO customer VALUES ('20205036', 'Hồ Yến Trinh', '05/13/2002');
INSERT INTO customer VALUES ('20205019', 'Đào Duy Thái', '05/22/2002');

--
-- Data for Name: customer; Type: TABLE DATA; Schema: public; Owner: -
--
INSERT INTO member(TeamID, MemberID, memberName, DOB, TotalGoal, YellowCard, RedCard)
    VALUES ('GER','GER01', 'Manuel Neuer','03/27/1986','0','0', '0'),
('GER','GER22', 'Kevin Trapp','07/08/1990','0','0', '0'),
('GER','GER02', 'Antonio Rüdiger','03/03/1993','0','0', '0'),
('GER','GER04', 'Matthias Ginter','01/19/1994','0','0', '0'),
('GER','GER26', 'Christian Günter','02/28/1993','0','0', '0'),
('GER','GER15', 'Niklas Süle','09/03/1995','0','0', '0'),
('GER','GER08', 'Toni Kroos','01/04/1990','0','0', '0'),
('GER','GER21', 'İlkay Gündoğan','10/24/1990','0','0', '0'),
('GER','GER18', 'Leon Goretzka','02/06/1995','0','0', '0'),
('GER','GER19', 'Leroy Sané','01/11/1996','0','0', '0'),
('GER','GER07', 'Kai Havertz','06/11/1999','0','0', '0'),
('GER','GER09', 'Kevin Volland','07/30/1992','0','0', '0'),
('GER','GER11', 'Timo Werne','03/06/1996','0','0', '0'),
('GER','GER25', 'Thomas Müller','09/13/1989','0','0', '0'),
('BRA','BRA01', 'Alisson','10/02/1992','0','0', '0'),
('BRA','BRA12', 'Weverton','12/13/1987','0','0', '0'),
('BRA','BRA03', 'Thiago Silva','09/22/1984','0','0', '0'),
('BRA','BRA04', 'Marquinhos','05/14/1994','0','0', '0'),
('BRA','BRA16', 'Alex Telles','12/15/1992','0','0', '0'),
('BRA','BRA13', 'Dani Alves','05/06/1983','0','0', '0'),
('BRA','BRA07', 'Lucas Paquetá','08/27/1997','0','0', '0'),
('BRA','BRA05', 'Casemiro','02/23/1992','0','0', '0'),
('BRA','BRA14', 'Danilo','04/19/2001','0','0', '0'),
('BRA','BRA15', 'Fabinho','10/23/1993','0','0', '0'),
('BRA','BRA09', 'Richarlison','05/10/1997','0','0', '0'),
('BRA','BRA10', 'Neymar','02/05/1992','0','0', '0'),
('BRA','BRA19', 'Raphinha','12/14/1996','0','0', '0'),
('BRA','BRA21', 'Rodrygo','01/09/2001','0','0', '0');

INSERT INTO Member(TeamID, MemberID, memberName, DOB, YellowCard, RedCard, TotalGoal)
	VALUES ('POR','POR01','Rui Patricio','02/15/1988','0','0','0'),
('POR','POR12','Rui Silva','02/07/1994','0','0','0'),
('POR','POR02','Diogo Dalot', '03/18/1999','0','0','0'),
('POR','POR03','Pepe','02/26/1983','0','0','0'),
('POR','POR19','Nuno Mendes','06/19/2002','0','0','0'),
('POR','POR20','Joao Cancelo','05/27/1994','0','0','0'),
('POR','POR08','Bruno Fernandes','09/08/1994','0','0','0'),
('POR','POR10','Bernardo Silva','08/10/1994','0','0','0'),
('POR','POR14','William Carvalho','04/07/1992','0','0','0'),
('POR','POR18','Ruben Neves','03/13/1997','0','0','0'),
('POR','POR09','Andre Silva','11/06/1995','0','0','0'),
('POR','POR15','Rafael Leao','06/10/1999','0','0','0'),
('POR','POR21','Diogo Jota','12/04/1996','0','0','0'),
('POR','POR07','Cristiano Ronaldo','02/05/1985','0','0','0'),
('USA','USA01','Matt Turner','06/24/1994','0','0','0'),
('USA','USA12','Sean Johnson','05/31/1989','0','0','0'),
('USA','USA02','DeAndre Yedlin','07/09/1993','0','0','0'),
('USA','USA03','Erik Palmer-Brown','04/24/1997','0','0','1'),
('USA','USA05','Antonee Robinson','08/08/1997','0','0','0'),
('USA','USA15','Aaron Long','10/12/1992','0','0','0'),
('USA','USA04','Tyler Adams','02/14/1999','0','0','0'),
('USA','USA06','Yunus Musah','11/29/2002','0','0','0'),
('USA','USA08','Weston McKennie','08/28/1998','0','0','0'),
('USA','USA14','Luca de la Torre','05/23/1998','0','0','0'),
('USA','USA07','Paul Arriola','02/05/1995','0','0','0'),
('USA','USA09','Jesus Ferreira','12/24/2000','0','0','0'),
('USA','USA10','Christian Pulisic','09/18/1998','0','0','0'),
('USA','USA11','Brenden Aaronson','10/22/2000','0','0','0'),

('NED','NED01','Jasper Cillessen','04/22/1989','0','0','0'),
	('NED','NED13', 'Mark Flekken','06/13/1993','0','0','0'),
	('NED','NED02','Jordan Teze','09/30/1999','0','0','0'),
	('NED','NED03','Matthijs de Ligt','08/12/1999','0','0','0'),
	('NED','NED04','Virgil van Dijk','07/08/1991','0','0','0'),
	('NED','NED17','Daley Blind','03/09/1990','0','0','0'),
	('NED','NED08','Guus Til','12/22/1997','0','0','0'),
	('NED','NED11','Steven Berghuis','12/19/1991','0','0','0'),
	('NED','NED14','Davy Klaassen','02/21/1993','0','0','0'),
	('NED','NED21','Frankie de Jong','05/12/1997','0','0','0'),
	('NED','NED07','Steven Bergwijn','10/08/1997','0','0','0'),
	('NED','NED09','Cody Gakpo','05/07/1999','0','0','0'),
	('NED','NED10','Memphis Depay','02/13/1994','0','0','0'),
	('NED','NED16','Vincent Janssen','06/15/1994','0','0','0'),

	('QAT','QAT01','Saad Al Sheeb','02/19/1990','0','0','0'),
	('QAT','QAT21','Yousef Hassan','05/24/1996','0','0','0'),
	('QAT','QAT03','Abdelkarim Hassan','08/28/1993','0','0','0'),
	('QAT','QAT05','Tarek Salman','12/05/1997','0','0','0'),
	('QAT','QAT13','Musab Kheder','09/26/1993','0','0','0'),
	('QAT','QAT14','Homam Ahmed','08/25/1999','0','0','0'),
	('QAT','QAT06','Abdulaziz Hatem','10/28/1990','0','0','0'),
	('QAT','QAT04','Mohammed Waad','09/18/1999','0','0','0'),
	('QAT','QAT08','Ali Assadalla','01/19/1993','0','0','0'),
	('QAT','QAT12','Karim Boudiaf','09/16/1990','0','0','0'),
	('QAT','QAT11','Akram Afif','11/18/1996','0','0','0'),
	('QAT','QAT07','Ahmed Alaaeldin','01/31/1993','0','0','0'),
	('QAT','QAT10','Hassan Al-Haydos','12/11/1990','0','0','0'),
	('QAT','QAT19','Almoez Ali','08/19/1996','0','0','0');

--
-- Data for Name: stadium; Type: TABLE DATA; Schema: public; Owner: -
--
INSERT INTO stadium VALUES 
    ('STD01','AI-Rayyan','Umm Al Afaei, Al Rayyan, Qatar'),
	('STD02','AI-Shamal','Madinat ash Shamal, Qatar'),
	('STD03','Doha Port','Ras Abu Aboud, Qatar'),
	('STD04','Sports City','Doha, Qatar'),
	('STD05','Al-Wakrah',' Al Wakrah, Qatar'),
	('STD06','Al-Gharafa',' Al Gharrafa district of Doha, Qatar'),
	('STD07','Umm Salal','Umm Salal Ali, Doha, Qatar');

--
-- Data for Name: stand; Type: TABLE DATA; Schema: public; Owner: -
--
INSERT INTO stand VALUES 
('STD0101','5000','950','STD01'),
('STD0102','5000','1005','STD01'),
('STD0103','5000','850','STD01'),
('STD0104','5000','865','STD01'),
('STD0105','5000','950','STD01'),
('STD0106','5000','645','STD01'),
('STD0107','5000','548','STD01'),
('STD0108','5000','440','STD01'),
('STD0109','5000','440','STD01'),
('STD0110','5000','645','STD01'),

('STD0201','4500','865','STD02'),
('STD0202','4500','986','STD02'),
('STD0203','4500','745','STD02'),
('STD0204','4500','689','STD02'),
('STD0205','4500','458','STD02'),
('STD0206','4500','985','STD02'),
('STD0207','4500','846','STD02'),
('STD0208','4500','376','STD02'),
('STD0209','4500','456','STD02'),
('STD0210','4500','475','STD02'),

('STD0301','4000','865','STD03'),
('STD0302','4000','765','STD03'),
('STD0303','4000','865','STD03'),
('STD0304','4000','865','STD03'),
('STD0305','4000','765','STD03'),
('STD0306','4000','689','STD03'),
('STD0307','4000','645','STD03'),
('STD0308','4000','628','STD03'),
('STD0309','4000','458','STD03'),
('STD0310','4000','458','STD03'),

('STD0401','4900','855','STD04'),
('STD0402','4900','1105','STD04'),
('STD0403','4900','1105','STD04'),
('STD0404','4900','1105','STD04'),
('STD0405','4900','958','STD04'),
('STD0406','4900','958','STD04'),
('STD0407','4900','689','STD04'),
('STD0408','4900','785','STD04'),
('STD0409','4900','785','STD04'),
('STD0410','4900','785','STD04'),

('STD0501','4000','865','STD05'),
('STD0502','4000','865','STD05'),
('STD0503','4000','865','STD05'),
('STD0504','4000','765','STD05'),
('STD0505','4000','765','STD05'),
('STD0506','4000','765','STD05'),
('STD0507','4000','765','STD05'),
('STD0508','4000','545','STD05'),
('STD0509','4000','545','STD05'),
('STD0510','4000','550','STD05'),

('STD0601','2500','650','STD06'),
('STD0602','2500','650','STD06'),
('STD0603','2500','500','STD06'),
('STD0604','2500','500','STD06'),
('STD0605','2500','500','STD06'),
('STD0606','2500','455','STD06'),
('STD0607','2500','455','STD06'),
('STD0608','2500','455','STD06'),
('STD0609','2500','255','STD06'),
('STD0610','2500','255','STD06'),

('STD0701','4500','200','STD07'),
('STD0702','4500','200','STD07'),
('STD0703','4500','200','STD07'),
('STD0704','4500','355','STD07'),
('STD0705','4500','355','STD07'),
('STD0706','4500','565','STD07'),
('STD0707','4500','565','STD07'),
('STD0708','4500','865','STD07'),
('STD0709','4500','865','STD07'),
('STD0710','4500','795','STD07');

--
-- Data for Name: referee; Type: TABLE DATA; Schema: public; Owner: -
--
INSERT INTO Referee VALUES 
    ('TT01', 'Andres Cunha', '09/08/1976', 'Uruguay'),
	('TT02', 'Alireza Faghani', '03/21/1978', 'Iran'),
	('TT03', 'Cuneyt Cakir', '11/23/1976', 'Thổ Nhĩ Kỳ'),
	('TT04', 'Alexandre Boucaut ', '04/08/1972', 'Bỉ'),
    ('TT05', 'Arnaldo Cézar Coelho', '05/23/1968', 'Brazil'),
    ('TT06', 'Héber Lopes', '11/08/1981', 'Brazil'),
    ('TT07', 'Marcelo de Lima Henrique', '06/21/1974', 'Brazil'),
    ('TT08', 'Phurpa Wangchuk', '04/23/1980', 'Bhutan'),
    ('TT09', 'Julia-Stefanie Baier', '03/17/1986', 'Áo'),
    ('TT10', 'Zaven Hovhannisyan', '02/28/1985', 'Mỹ'),
    ('TT11', 'Zaven Hovhannisyan', '02/03/1975', 'Mỹ'),
    ('TT12', 'Djamel Haimoudi ', '12/31/1970', 'Algérie');

--
-- Data for Name: match; Type: TABLE DATA; Schema: public; Owner: -
--
INSERT INTO match(MatchID, Time, StadiumID, Round) VALUES
    ('M01','2022-12-01 02:00:00','STD01','Group stage'),
	('M02','2022-12-02 02:20:00','STD02','Group stage'),
	('M03','2022-12-03 02:10:00','STD07','Group stage'),
	('M04','2022-12-04 01:30:00','STD04','Group stage'),
	('M05','2022-12-05 02:00:00','STD02','Group stage'),
	('M06','2022-12-06 02:00:00','STD05','Group stage'),
	('M07','2022-12-09 02:30:00','STD03','Semi_finals'),
	('M08','2022-12-10 18:00:00','STD06','Semi_finals'),
	('M09','2022-12-14 02:00:00','STD02','Final');

--
-- Data for Name: card; Type: TABLE DATA; Schema: public; Owner: -
--
INSERT INTO card VALUES
('GER18','M02','YellowCard','2022-12-02 02:41:00'),
('GER19','M02','YellowCard','2022-12-02 02:52:00'),
('BRA04','M03','YellowCard','2022-12-03 02:34:00'),
('BRA19','M03','RedCard','2022-12-03 03:12:00');

--
-- Data for Name: ticket; Type: TABLE DATA; Schema: public; Owner: -
--
INSERT INTO ticket VALUES
('000000000001','STD0203','20204992','M02'),
('000000000002','STD0201','20200364','M02'),
('000000000003','STD0205','20200203','M02'),
('000000000004','STD0209','20200310','M02'),
('000000000005','STD0601','20204992','M08'),
('000000000006','STD0603','20205036','M08'),
('000000000007','STD0605','20205019','M08'),
('000000000008','STD0607','20205090','M08');

--
-- Data for Name: goal; Type: TABLE DATA; Schema: public; Owner: -
--
INSERT INTO goal VALUES
('G0001','M02','GER09','2022-12-02 02:31:42'),
('G0002','M02','GER09','2022-12-02 02:42:42'),
('G0003','M02','POR07','2022-12-02 02:50:31'),
('G0004','M02','POR07','2022-12-02 02:25:10'),
('G0005','M03','BRA10','2022-12-03 02:20:22'),
('G0006','M03','BRA10','2022-12-03 02:45:56'),
('G0007','M03','USA08','2022-12-03 02:56:12'),
('G0008','M03','BRA19','2022-12-03 03:17:46');

--
-- Data for Name: referee_match; Type: TABLE DATA; Schema: public; Owner: -
--
INSERT INTO referee_match VALUES
('M01','TT06'),
('M02','TT04'),
('M03','TT01'),
('M04','TT11'),
('M05','TT12'),
('M06','TT07'),
('M07','TT08'),
('M08','TT05'),
('M09','TT03');

--
-- Data for Name: match_team; Type: TABLE DATA; Schema: public; Owner: -
--
INSERT INTO match_team VALUES
    ('M01','QAT','NED'),
    ('M02','GER','POR'),
    ('M03','BRA','USA'),
	('M04','USA','GER'),
	('M05','NED','POR'),
	('M06','GER','BRA'),
	('M07','POR','QAT'),
	('M08','GER','USA'),
    ('M09','QAT','USA');

--
-- Data for Name: match_squad; Type: TABLE DATA; Schema: public; Owner: -
--
INSERT INTO match_squad VALUES
('M02','GER02','Goalkeeper'),
('M02','GER04','Defender'),
('M02','GER26','Defender'),
('M02','GER15','Defender'),
('M02','GER08','Midfielder'),
('M02','GER21','Midfielder'),
('M02','GER01','Midfielder'),
('M02','GER18','Forward'),
('M02','GER19','Forward'),
('M02','GER07','Forward'),
('M02','GER09','Forward'),
('M02','POR01','Goalkeeper'),
('M02','POR02','Defender'),
('M02','POR03','Defender'),
('M02','POR19','Defender'),
('M02','POR08','Midfielder'),
('M02','POR10','Midfielder'),
('M02','POR14','Midfielder'),
('M02','POR18','Midfielder'),
('M02','POR09','Forward'),
('M02','POR21','Forward'),
('M02','POR07','Forward'),

('M03','BRA01','Goalkeeper'),
('M03','BRA12','Midfielder'),
('M03','BRA03','Defender'),
('M03','BRA10','Forward'),
('M03','BRA16','Defender'),
('M03','BRA14','Midfielder'),
('M03','BRA15','Defender'),
('M03','BRA04','Forward'),
('M03','BRA09','Defender'),
('M03','BRA21','Midfielder'),
('M03','USA01','Goalkeeper'),
('M03','USA02','Defender'),
('M03','USA03','Defender'),
('M03','USA05','Defender'),
('M03','USA15','Defender'),
('M03','USA04','Midfielder'),
('M03','USA06','Midfielder'),
('M03','USA07','Forward'),
('M03','USA09','Forward'),
('M03','USA10','Forward'),
('M03','USA11','Forward');

--------------------------------------------------------------
--
-- Name: pk_team; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY team
    ADD CONSTRAINT pk_team PRIMARY KEY (TeamID);

--
-- Name: pk_coach; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY coach
    ADD CONSTRAINT pk_coach PRIMARY KEY (CoachID);

--
-- Name: pk_member; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--
ALTER TABLE ONLY member
    ADD CONSTRAINT pk_member PRIMARY KEY (MemberID);

--
-- Name: pk_stadium; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--
ALTER TABLE ONLY stadium
    ADD CONSTRAINT pk_stadium PRIMARY KEY (stadiumid);

--
-- Name: pk_match; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--
ALTER TABLE ONLY match
    ADD CONSTRAINT pk_match PRIMARY KEY (MatchID);

--
-- Name: pk_goal; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--
ALTER TABLE ONLY goal
    ADD CONSTRAINT pk_goal PRIMARY KEY (GoalID);

--
-- Name: pk_stand; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--
ALTER TABLE ONLY stand
    ADD CONSTRAINT pk_stand PRIMARY KEY (standID);

--
-- Name: pk_customer; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--
ALTER TABLE ONLY customer
    ADD CONSTRAINT pk_customer PRIMARY KEY (CustomerID);


--
-- Name: pk_ticket; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--
ALTER TABLE ONLY ticket
    ADD CONSTRAINT pk_ticket PRIMARY KEY (TicketID);

--
-- Name: pk_referee; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--
ALTER TABLE ONLY referee
    ADD CONSTRAINT pk_referee PRIMARY KEY (refereeid);

--
-- Name: fk_team_coachid; Type: Constraint; Schema: -; Owner: -
--

ALTER TABLE ONLY team
    ADD CONSTRAINT fk_team_coachid FOREIGN KEY (coachid) REFERENCES coach;

--
-- Name: fk_member_team; Type: Constraint; Schema: -; Owner: -
--

ALTER TABLE ONLY member
    ADD CONSTRAINT fk_member_team FOREIGN KEY (TeamID) REFERENCES team;

--
-- Name: fk_match_stadium; Type: Constraint; Schema: -; Owner: -
--

ALTER TABLE ONLY match
    ADD CONSTRAINT fk_match_stadium FOREIGN KEY (stadiumid) REFERENCES stadium;

--
-- Name: fk_card_member; Type: Constraint; Schema: -; Owner: -
--

ALTER TABLE ONLY card
    ADD CONSTRAINT fk_card_member FOREIGN KEY (MemberID) REFERENCES member;

--
-- Name: fk_card_match; Type: Constraint; Schema: -; Owner: -
--
ALTER TABLE ONLY card
    ADD CONSTRAINT fk_card_match FOREIGN KEY (matchid) REFERENCES match;


--
-- Name: fk_goal_match; Type: Constraint; Schema: -; Owner: -
--
ALTER TABLE ONLY goal
    ADD CONSTRAINT fk_goal_match FOREIGN KEY (MatchID) REFERENCES match;

--
-- Name: fk_goal_member; Type: Constraint; Schema: -; Owner: -
--
ALTER TABLE ONLY goal
    ADD CONSTRAINT fk_goal_member FOREIGN KEY (MemberID) REFERENCES member;

--
-- Name: fk_stand_stadium; Type: Constraint; Schema: -; Owner: -
--
ALTER TABLE ONLY stand
    ADD CONSTRAINT fk_stand_stadium FOREIGN KEY (stadiumid) REFERENCES stadium;

--
-- Name: fk_ticket_stand; Type: Constraint; Schema: -; Owner: -
--
ALTER TABLE ONLY ticket
    ADD CONSTRAINT fk_ticket_stand FOREIGN KEY (StandID) REFERENCES stand;

--
-- Name: fk_ticket_customer; Type: Constraint; Schema: -; Owner: -
--
ALTER TABLE ONLY ticket
    ADD  CONSTRAINT fk_ticket_customer FOREIGN KEY (CustomerID) REFERENCES customer;

--
-- Name: fk_ticket_match; Type: Constraint; Schema: -; Owner: -
--
ALTER TABLE ONLY ticket
    ADD  CONSTRAINT fk_ticket_match FOREIGN KEY (MatchID) REFERENCES match;

--
-- Name: fk_matchteam_match; Type: Constraint; Schema: -; Owner: -
--
ALTER TABLE ONLY match_team
    ADD  CONSTRAINT fk_matchteam_match FOREIGN KEY (MatchID) REFERENCES match;

--
-- Name: fk_matchteam_team1; Type: Constraint; Schema: -; Owner: -
--
ALTER TABLE ONLY match_team
    ADD  CONSTRAINT fk_matchteam_team1 FOREIGN KEY (teamid_1) REFERENCES team;

--
-- Name: fk_matchteam_team2; Type: Constraint; Schema: -; Owner: -
--
ALTER TABLE ONLY match_team
    ADD  CONSTRAINT fk_matchteam_team2 FOREIGN KEY (teamid_2) REFERENCES team;


--
-- Name: fk_matchsquad_match; Type: Constraint; Schema: -; Owner: -
--
ALTER TABLE ONLY match_squad
    ADD  CONSTRAINT fk_matchsquad_match FOREIGN KEY (MatchID) REFERENCES match;

--
-- Name: fk_matchsquad_member; Type: Constraint; Schema: -; Owner: -
--
ALTER TABLE ONLY match_squad
    ADD  CONSTRAINT fk_matchsquad_member FOREIGN KEY (MemberID) REFERENCES member;

--
-- Name: fk_refereematch_match; Type: Constraint; Schema: -; Owner: -
--
ALTER TABLE ONLY referee_match
    ADD  CONSTRAINT fk_refereematch_match FOREIGN KEY (MatchID) REFERENCES match;

--
-- Name: fk_refereematch_referee; Type: Constraint; Schema: -; Owner: -
--
ALTER TABLE ONLY referee_match
    ADD  CONSTRAINT fk_refereematch_referee FOREIGN KEY (refereeid) REFERENCES referee;

