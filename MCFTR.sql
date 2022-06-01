create or replace function student00.st_get_inf_period(in_currcode varchar2,
                                             dt_begin    date,
                                             dt_end      date)
  return number as
  v_inf_period number;
begin
  if dt_begin > dt_end then
    raise_application_error(-20001, 'dt_begin > dt_end?!');
  elsif dt_begin < to_date('01.01.1991', 'dd.mm.yyyy') then
    raise_application_error(-20001, 'dt_begin < 01-01-1991?!');
  end if;
  with calendar as
   (select add_months(trunc(dt_begin, 'mon'), level - 1) dt
      from dual
    connect by level < months_between(dt_end, dt_begin) + 2),
  dat as
   (select calendar.dt, 1 + t.coeff / 100 coeff
      from calendar
      left join st_inflation t
        on calendar.dt = t.dt
       and t.currcode = in_currcode)
  select exp(sum(ln(case
                      when trunc(dt_begin, 'mon') = dt and
                           months_between(dt_end, dt) < 1 then
                       power(coeff, (dt_end - dt_begin) / (last_day(dt) - dt + 1))
                      when trunc(dt_begin, 'mon') = dt then
                       power(coeff,
                             (last_day(dt) - dt_begin + 1) / (last_day(dt) - dt + 1))
                      when months_between(dt_end, dt) < 1 then
                       power(coeff, (dt_end - dt) / (last_day(dt) - dt + 1))
                      else
                       coeff
                    end)))
    into v_inf_period
    from dat
   where dt >= trunc(dt_begin, 'mon')
     and dt < dt_end;
  return nvl(v_inf_period, 1);
end st_get_inf_period;

--Таблица по годам

with temp as(
select f3 ,min(f1) min_date, max(f1) max_date
from (select to_date(f1) as f1, extract(year from to_date(f1)) as f3, (f2)
from student00.mcftr)
group by f3
order by  max(f1) desc
)


select  min_date Начало,
 max_date Конец,
round(cast(replace(t3.f2, ' ', '')as float)/cast(replace(t2.f2, ' ', '')as float),2) kf,
round((cast(replace(t3.f2, ' ', '')as float)/cast(replace(t2.f2, ' ', '')as float))/(student00.st_get_inf_period('RUB',min_date, max_date)),2) kf_infl
from temp t1
left join student00.mcftr t2 on to_date(t2.f1) = t1.min_date
left join student00.mcftr t3 on to_date(t3.f1) = t1.max_date
order by min_date desc

--средняя с учетом и без учета инфляции
with temp as(
select f3 ,min(f1) min_date, max(f1) max_date
from (select to_date(f1) as f1, extract(year from to_date(f1)) as f3, (f2)
from student00.mcftr)
group by f3
order by  max(f1) desc
)
select  avg(kf), avg(kf_infl) 
from (select substr(min_date,1,10) min_date, substr(max_date,1,10) max_date,
round(cast(replace(t3.f2, ' ', '')as float)/cast(replace(t2.f2, ' ', '')as float),2) kf,
round((cast(replace(t3.f2, ' ', '')as float)/cast(replace(t2.f2, ' ', '')as float))/(student00.st_get_inf_period('RUB',min_date, max_date)),2) kf_infl
from temp t1
left join student00.mcftr t2 on to_date(t2.f1) = t1.min_date
left join student00.mcftr t3 on to_date(t3.f1) = t1.max_date)
where to_date(min_date) between (select max(min_date) from temp) - interval '10' year and (select max(min_date) from temp) - interval '1' year



select * from student00.mcftr


