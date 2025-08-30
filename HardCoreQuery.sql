


-- Find the latest salary for each employee



with cte as (
select 
	*,
	RANK() over(partition by employee_id order by change_date desc) as rn_desc,
	RANK() over(partition by employee_id order by change_date asc) as rn_asc
	
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

promotions_cte as (
select
	employee_id,
	count(*) as no_of_promotions
from
	cte
where promotion='Yes'
group by employee_id
),

prev_salary_cte as (
select
	*,
	LEAD(salary,1) over(partition by employee_id order by change_date desc) as prev_salary,
	lead(change_date,1) over(partition by employee_id order by change_date desc) as prev_change_date
from
	cte 
),

salary_growth_cte as (
select
	employee_id,
	max(cast((salary-prev_salary)*100.0/prev_salary AS decimal(4, 2))) as max_salary_growth
from
	prev_salary_cte
group by employee_id
),


salary_decreased as (
select
	distinct employee_id, 'N' as never_decreased
from
	prev_salary_cte
where salary < prev_salary
),

avg_months_cte as (
select
	employee_id,
	avg(DATEDIFF(month, prev_change_date, change_date)) as avg_months_between_changes
from
	prev_salary_cte
group by employee_id
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
	e.employee_id,
	e.name,
	s.latest_salary,
	isnull(p.no_of_promotions, 0) as no_of_promotions,
	msg.max_salary_growth,
	isnull(sd.never_decreased, 'Y') as never_decreased,
	am.avg_months_between_changes,
	rbg.RankByGrowth
from	
	employees e
left join latest_salary_cte s on e.employee_id = s.employee_id
left join promotions_cte p on e.employee_id = p.employee_id
left join salary_growth_cte msg on e.employee_id=msg.employee_id
left join salary_decreased sd on e.employee_id=sd.employee_id
left join avg_months_cte am on e.employee_id=am.employee_id
left join salary_growth_rank_cte rbg on e.employee_id=rbg.employee_id
