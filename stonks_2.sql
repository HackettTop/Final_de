--ср.рост за каждый из последних 15 лет по акциям, торговавшимся весь этот год
with const as
 (select num_years, add_months(end_dt, -12 * num_years) start_dt, end_dt
    from (select 15 num_years, to_date('01.01.2022', 'dd.mm.yyyy') end_dt
            from dual)),
pre as
 (select /*+ materialize*/
   stock_invest_results.stock_name, t.num_year, t.start_dt, t.end_dt,
   min(stock_invest_results.dt) min_dt,
   max(stock_invest_results.amt_minus_infl) keep(dense_rank first order by stock_invest_results.dt) start_amt_minus_infl,
   max(stock_invest_results.amt_minus_infl) keep(dense_rank last order by stock_invest_results.dt) end_amt_minus_infl
    from student00.stock_invest_results,
         (select level num_year, add_months(end_dt, -12 * level) start_dt, add_months(end_dt, -12 * (level - 1)) end_dt
            from const
          connect by level <= num_years) t
   where stock_invest_results.dt between t.start_dt and t.end_dt
   group by stock_invest_results.stock_name, t.num_year, t.start_dt, t.end_dt)
select num_year, start_dt, end_dt,
       count(1) num_stocks,
       round(avg(end_amt_minus_infl / start_amt_minus_infl), 6) avg_total_incr_over_infl
  from pre
 where min_dt = start_dt
 group by num_year, start_dt, end_dt
 order by num_year;
 
--полный анализ за num_years лет (хит-парад акций)
with const as (select num_years, add_months(end_dt, -12 * num_years) start_dt, end_dt
                 from (select 10 num_years, to_date('01.01.2022', 'dd.mm.yyyy') end_dt from dual)),
pre as (select /*+ materialize*/ stock_name, const.num_years, const.start_dt, const.end_dt,
               min(dt) min_dt,
               nvl(sum(div_amt), 0) sum_div_amt,
               max(stock_price) keep(dense_rank first order by dt) start_stock_price,
               max(stock_price) keep(dense_rank last order by dt) end_stock_price,
               max(num_stocks) keep(dense_rank first order by dt) start_num_stocks,
               max(num_stocks) keep(dense_rank last order by dt) end_num_stocks,
               max(amt_minus_infl) keep(dense_rank first order by dt) start_amt_minus_infl,
               max(amt_minus_infl) keep(dense_rank last order by dt) end_amt_minus_infl
          from student00.stock_invest_results, const
         where stock_invest_results.dt between const.start_dt and const.end_dt
         group by stock_name, const.num_years, const.start_dt, const.end_dt)
select stock_name, min_dt, end_dt, round(student00.st_get_inf_period('RUB', min_dt, end_dt), 6) infl_coeff,
       start_stock_price, end_stock_price, round(end_stock_price / start_stock_price, 6) stock_price_incr_wo_div,
       sum_div_amt,
       round(end_num_stocks / start_num_stocks, 6) num_stocks_incr_due2_reinvest,
       round(end_amt_minus_infl / start_amt_minus_infl, 6) total_incr_over_infl,
       round(power(end_amt_minus_infl / start_amt_minus_infl, 12 / months_between(end_dt, min_dt)), 6) yearly_avg_incr_over_infl
  from pre
 order by 11 desc;

--найти акцию, стабильно дающую доход выше недвижимости максимальное число раз по каждому из последних num_years годов 
 with const as
 (select num_years, add_months(end_dt, -12 * num_years) start_dt, end_dt, 1.045 year_profit_coeff
    from (select 15 num_years, to_date('01.01.2022', 'dd.mm.yyyy') end_dt
            from dual)),
pre as
 (select /*+ materialize*/
   stock_invest_results.stock_name, t.num_year, t.start_dt, t.end_dt,
   min(stock_invest_results.dt) min_dt,
   max(stock_invest_results.amt_minus_infl) keep(dense_rank first order by stock_invest_results.dt) start_amt_minus_infl,
   max(stock_invest_results.amt_minus_infl) keep(dense_rank last order by stock_invest_results.dt) end_amt_minus_infl
    from student00.stock_invest_results,
         (select level num_year, add_months(end_dt, -12 * level) start_dt, add_months(end_dt, -12 * (level - 1)) end_dt
            from const
          connect by level <= num_years) t
   where stock_invest_results.dt between t.start_dt and t.end_dt
   group by stock_invest_results.stock_name, t.num_year, t.start_dt, t.end_dt)
select stock_name,
       sum(ind_best_than_realty) num_years_best_than_realty,
       count(1) years_total,
       round(sum(ind_best_than_realty) / count(1), 4) win_realty_coeff,
       sum(case when num_year = 1 then avg_total_incr_over_infl end) c_1,       sum(case when num_year = 2 then avg_total_incr_over_infl end) c_2,
       sum(case when num_year = 3 then avg_total_incr_over_infl end) c_3,       sum(case when num_year = 4 then avg_total_incr_over_infl end) c_4,
       sum(case when num_year = 5 then avg_total_incr_over_infl end) c_5,       sum(case when num_year = 6 then avg_total_incr_over_infl end) c_6,
       sum(case when num_year = 7 then avg_total_incr_over_infl end) c_7,       sum(case when num_year = 8 then avg_total_incr_over_infl end) c_8,
       sum(case when num_year = 9 then avg_total_incr_over_infl end) c_9,       sum(case when num_year = 10 then avg_total_incr_over_infl end) c_10,
       sum(case when num_year = 11 then avg_total_incr_over_infl end) c_11,     sum(case when num_year = 12 then avg_total_incr_over_infl end) c_12,
       sum(case when num_year = 13 then avg_total_incr_over_infl end) c_13,     sum(case when num_year = 14 then avg_total_incr_over_infl end) c_14,
       sum(case when num_year = 15 then avg_total_incr_over_infl end) c_15
  from (select pre.stock_name, pre.num_year, pre.start_dt, pre.end_dt,
               round(pre.end_amt_minus_infl / pre.start_amt_minus_infl, 6) avg_total_incr_over_infl,
               case when pre.end_amt_minus_infl / pre.start_amt_minus_infl > const.year_profit_coeff then 1 else 0 end ind_best_than_realty
          from pre, const
         where pre.min_dt = pre.start_dt)
 group by stock_name
 order by 4 desc;