
--Member belongs to Germany
select membername from member where teamid = 'GER';
--Age < 22
select membername from member 
where date_part('year', current_date) - date_part('year', dob) < 22;
--Member who is banned
select * from member
where yellowcard >=2 or redcard >= 1;
--Average Age from each group
select teamid, avg(date_part('year', current_date) - date_part('year', dob)) as do_tuoi_trung_binh 
from member
group by (teamid);
--Defender who has >= 3 goals
select * from match_squad ms, member m
where m.memberid = ms.memberid and position = 'Defender'
and totalgoal > 3;
--Member below 23 years old who has highest goals
select * from member 
where date_part('year', current_date) - date_part('year', dob) < 23
and totalgoal = (select max(totalgoal) from member 
				 where date_part('year', current_date) - date_part('year', dob) < 23);
				 
--most expensive ticket and where it belong to
select  stadiumname, standid, price from stadium, stand
where stadium.stadiumid = stand.stadiumid
and price = (select max(price) from stand);
--member who has highest goal
select * from member 
where totalgoal = (select max(totalgoal) from member );

--goals from each group
select teamid, sum(totalgoal) as so_ban_thang from member
group by (teamid);

--customer's info (Mai Thu Hien)
select * from ticket t, customer c
where t.customerid = c.customerid
and customername = 'Mai Thu Hiền';

--Match starts at 2pm
select * from match
where (EXTRACT(HOUR FROM time) = '02') and (EXTRACT(MINUTE FROM time) = '00');

--total money per match
select match.matchid, sum(price)
from match join ticket on match.matchid = ticket.matchid
	join stand on stand.standid=ticket.standid
group by match.matchid;

--total goal each member
select memberid, membername, totalgoal as "So ban thang"
from member
order by totalgoal desc;

--result each matches of qatar
select * 
from match_team
where teamid_1 = (select teamid from team where lower(teamname) = 'qatar') or
teamid_2 = (select teamid from team where lower(teamname) = 'qatar');

--match which referee name's is Alexandre Boucaut
select *
from match join referee_match on match.matchid=referee_match.matchid
join referee on referee_match.refereeid=referee.refereeid
where refereename='Alexandre Boucaut';

--Match takes place on 2022-12-03
select match.matchid, (select teamname from team where teamid=match_team.teamid_1) as "Doi Bong 1", (select teamname from team where teamid=match_team.teamid_2) as "Doi Bong 2"
from match join match_team on match.matchid=match_team.matchid
where (EXTRACT(YEAR FROM match.time) = '2022') and (EXTRACT(MONTH FROM match.time) = '12') and (EXTRACT(DAY FROM match.time) = '03');

--Stadium from Doha, Qatar
select * from stadium
where address='Doha, Qatar';

--Group which has highest score
select teamid, sum(scoreteam)
from ((select teamid_1 as teamid, scoreteam_1 as scoreteam
from match_team)
union
(select teamid_2 as teamid, scoreteam_2 as scoreteam
from match_team)) as bang2
group by (teamid)
order by (sum)
limit 1
;
--Member who born in 1997
select * from member
where EXTRACT(year FROM dob) = '1997';

--Count number of red card last match
select teamid,sum(redcard)
from member
group by teamid;

--Stadium with a capacity of 40000 or more
select stadium.stadiumid, stadiumname, sum(amount)
from stand, stadium
where stand.stadiumid = stadium.stadiumid
group by (stadium.stadiumid)
having sum(amount) >= 40000;

--average number of spectators per match
select avg(count) as "So khan gia trung binh"
from (select  ticket.matchid, count(ticketid)
from ticket, match
where ticket.matchid=match.matchid
group by ticket.matchid) as bang1;

