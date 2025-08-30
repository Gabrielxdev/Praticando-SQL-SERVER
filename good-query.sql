


-- Find the latest salary for each employee
with cte as (
select 
	*,
	RANK() over(partition by employee_id order by change_date desc) as rn_desc,
	RANK() over(partition by employee_id order by change_date asc) as rn_asc,
	LEAD(salary,1) over(partition by employee_id order by change_date desc) as prev_salary,
	LEAD(change_date,1) over(partition by employee_id order by change_date desc) as prev_change_date
	
from
	salary_history
),

latest_salary_cte as (
select
	employee_id,
	salary as latest_salary
from
	cte
where rn_desc=1
),


salary_ratio_cte as (
select 
	employee_id,
	cast(max(case when rn_desc=1 then salary end) / max(case when rn_asc=1 then salary end) as decimal(4,2)) as salary_growth_ratio,
	min(change_date) as join_date
from
	cte
group by employee_id
), 


salary_growth_rank_cte as (
select
	employee_id,
	rank() over(order by salary_growth_ratio desc, join_date asc) as RankByGrowth
from
	salary_ratio_cte
)


select
	cte.employee_id,
	max(case when rn_desc=1 then salary end) as latest_salary,
	sum(case when promotion='Yes' then 1 else 0 end) as no_of_promotions,
	max(cast((salary-prev_salary)*100.0/prev_salary AS decimal(4, 2))) as max_salary_growth,
	case when max(case when salary < prev_salary then 1 else 0 end)=0 then 'Y' else 'N' end as NeverDecreased,
	avg(DATEDIFF(month, prev_change_date, change_date)) as avg_months_between_changes,
	rank() over(order by sr.salary_growth_ratio desc, sr.join_date asc) as RankByGrowth
from
	cte
left join salary_ratio_cte sr on cte.employee_id=sr.employee_id
group by cte.employee_id, sr.salary_growth_ratio, sr.join_date
order by cte.employee_id
