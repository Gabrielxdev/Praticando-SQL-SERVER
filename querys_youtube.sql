

-- 1. List all videos and their creator names
with cte as (
select
	c.creator_name as creator_name,
	v.*
from
	videos v
left join creators c on v.creator_id = c.creator_id
)

-- 2. Count total videos per creator
select
	creator_name,
	count(video_id) as total_videos
from
	cte
group by creator_name
order by creator_name
	
-- Get total comments for a given video

select 
	v.video_id,
	sum(co.comment_id) total_comments
from
	videos v 
inner join comments co on v.video_id = co.video_id
group by v.video_id
order by sum(co.comment_id) desc
	
-- List Videos published in the last 18 months
select
	* 
from
	videos
where publish_date >= DATEADD(MM, -18, getdate())


-- 5. Find videos longer than 20 minutes.
select
	* 
from
	videos 
where duration_seconds > 20*60

--6. Show top 10 videos by total views (aggregate daily_views).

select top 10
	video_id,
	sum(views) as total_views
from
	daily_views
group by video_id
order by sum(views) desc


-- 7. Show Unique categories.
select
	distinct category
from
	videos

-- 8 Count creators per country 
select
	country,
	count(*) as total_creators
from
	creators
group by country

-- 9 Get average views per video per creator.
select
	dv.video_id,
	c.creator_name,
	avg(dv.views) as avg_views
from
	daily_views dv
left join videos v on v.video_id = dv.video_id
	left join creators c on c.creator_id = v.creator_id
group by dv.video_id, c.creator_name


-- 10.Find videos with zero comments
select
	v.video_id,
	coalesce(c.commenter_name, 'no comments') as comments
from
	videos v
left join comments c on v.video_id = c.video_id
where coalesce(c.commenter_name, 'no comments') = 'no comments'


-- 11. total impressions and clicks per video
select
	v.title,
	sum(d.impressions) as total_impressions,
	sum(d.clicks) as total_clicks
from
	daily_views d
inner join videos v on v.video_id = d.video_id
group by v.title




-- 12. Compute CTR = clicks / impressions per day
select 
	view_date, 
	round(cast(sum(clicks) as float)/SUM(impressions),2)*100 as Total_Impressions
from
	daily_views
group by view_date
having SUM(impressions) > 0



-- 13. Average watch time per view (watch_time_seconds / views).

select
	video_id,
	watch_time_seconds/views as average_watch_time_pwe_view
from
	daily_views


-- 14. Daily views trend for a single video
select
	video_id,
	view_date,
	views
from
	daily_views
where video_id = 1147
order by view_date


-- 15. Views per category
select
	v.category,
	sum(vw.views) as views
from
	videos v
inner join daily_views vw on v.video_id = vw.video_id
group by v.category 

-- 16 Top 5 videos by watch_time_seconds
with cte as ( 
select
	video_id as video_id,
	sum(watch_time_seconds) as watch_time_seconds,
	ROW_NUMBER() over(order by sum(watch_time_seconds) desc) as rn 
from
	daily_views
group by video_id
)
select 
	video_id
from
	cte 
where rn <= 5


-- 17 Average likes/dislikes per video
select 
	v.title,
	ld.video_id,
	avg(ld.likes) as likes_avg,
	avg(ld.dislikes) as dislikes_avg
from
	likes_dislikes ld
left join videos v on v.video_id = ld.video_id
group by ld.video_id, v.title

-- 18. List videos with more dislikes than likes
select 
	v.title,
	ld.video_id,
	sum(ld.likes) as likes_total,
	sum(ld.dislikes) as dislikes_total
from
	likes_dislikes ld
left join videos v on v.video_id = ld.video_id
group by ld.video_id, v.title
having sum(ld.likes) < sum(ld.dislikes)


-- 19. List videos where avg_view_duration < 20% of duration 


select
	dv.video_id,
	AVG(dv.avg_view_duration_seconds) avg_view_duration_seconds,
	round(0.20*v.duration_seconds, 2) as duration_20
from
	daily_views dv
inner join videos v on v.video_id = dv.video_id
group by dv.video_id, v.duration_seconds
having AVG(avg_view_duration_seconds)< 0.2*duration_seconds

-- 20. Videos that gained more than 1K views in a day 
select
	view_date,
	video_id
from
	daily_views 
where views > 1000


-- 21. For each creator, total revenue (ad + subsciption + other) 
select
	c.creator_id,
	c.creator_name,
	sum(r.ad_revenue + subscription_revenue + other_revenue) as total_revenue
from	
	creators c
inner join videos v on c.creator_id = v.creator_id
	inner join revenue r on v.video_id = r.video_id
group by c.creator_id,
	c.creator_name

-- 22 For Each video, last 7-day rolling average views.
select
	video_id,
	view_date, 
	views, 
	AVG(views) over (partition by video_id order by view_date rows between 6 preceding and current row) as avg_L7D_views
from
	daily_views
order by video_id,view_date

-- 23 Top performing video per creator by revenue
with cte as (
select 
	c.creator_name,
	r.video_id,
	row_number() over( partition by c.creator_name order by sum(r.ad_revenue + r.subscription_revenue + r.other_revenue)desc) as total_revenue_rn
from
	revenue r 
inner join videos v on r.video_id=v.video_id
	inner join creators c on c.creator_id = v.creator_id
group by c.creator_name, r.video_id
)

select * from cte where total_revenue_rn = 1

-- 24. Video comment sentiment breakdown (pos/neutral/neg). ? 

-- 25. Videos with 0 impressions but with more than 0 clicks (possible data issue).
select * from daily_views where impressions = 0

-- 26. List videos and their peak daily views date.

with cte as (
select
	*,
	ROW_NUMBER() over(partition by video_id order by views desc) as rn 
from
	daily_views
)

select * from cte where rn = 1

-- 27. Show creators who published > 10 videos.
select
	creator_name
from
	videos v 
inner join creators c on c.creator_id = v.creator_id
group by c.creator_name 
having count(v.video_id) > 10

-- 28. Videos with multiple high-spike days.
-- obs: 1K views in a day is a high spike day

select
	distinct video_id
from
	daily_views
where views > 1000
group by video_id
having count(*) > 1

-- 29. Find videos with payments revenue but zero views (data mismatch).
select
	distinct video_id 
from
	revenue
where video_id not in (select distinct video_id from daily_views)

-- 30 Creator-wise-average CTR
select
	creator_name,
	AVG(cast(clicks as float)/impressions) as CTR
from
	daily_views dv
inner join videos v on v.video_id=dv.video_id
	inner join creators c on c.creator_id = v.creator_id
where impressions > 0
group by c.creator_name


-- 31. Rank videos by total views within each category (RANK/DENSE_RANK).
select 
	dv.video_id,
	v.title,
	v.category,
	sum(dv.views) as views,
	ROW_NUMBER() over (partition by v.category order by sum(views) desc) as rn
from
	daily_views  dv
inner join videos v on v.video_id= dv.video_id
group by dv.video_id, v.category, v.title


-- 32. Running total of views per video (window).
select 
	sum(views) over(partition by video_id order by view_date) running_total,
	*
from
	daily_views

-- 33. Monthly growth rate of views for each video (lag)
with cte_lag as (
select
	video_id,
	month(view_date) as mnth, 
	sum(views) as views
from
	daily_views 
group by video_id, MONTH(view_date)
),


cte_final as (

select 
	*,
	lag(views, 1, 0) over (partition by video_id order by mnth) as Prev_Mnth_views,
	round(cast((views - lag(views) over (partition by video_id order by mnth)) as float) /
	nullif(lag(views) over (partition by video_id order by mnth), 0), 2) as growth_rate
from
	cte_lag

)

select *, growth_rate*100 from cte_final



-- 34. Top 3 videos per month (window + partition).
with cte as (
select
	*,
	ROW_NUMBER() over (partition by month(view_date) order by views desc) rn 
from
	daily_views
)

select * from cte where rn <= 3

-- 35. Percentile of views for each video (NTILE).
select
	dv.video_id,
	v.title,
	dv.view_date, 
	dv.views,
	NTILE(10) over (partition by dv.video_id order by dv.views) as view_percentile 
from
	daily_views dv 
join videos v ON dv.video_id = v.video_id
order by dv.video_id, dv.view_date;

-- 36. Lead/Lag to calculate day-over-day % change.

with cte as (
select
	lag(views) over (partition by video_id order by view_date) as Prev_day_views, *
from
	daily_views
)

select 
	*, 
	round((cast(views-Prev_day_views as float)/Prev_day_views)*100, 2) as Growth_percentage 
from
	cte


-- 37. Cumulative watch time per creator 
select
	c.creator_id,
	dv.view_date,
	sum(dv.watch_time_seconds) over (partition by c.creator_id order by dv.view_date) as cumulative
from
	daily_views dv 
inner join videos v on v.video_id = dv.video_id
	inner join creators c on c.creator_id = v.creator_id

-- 38. Rank creators by average watch time per video.
select
	c.creator_name,
	ROW_NUMBER() over (partition by c.creator_name order by avg_view_duration_seconds) as rn , * 
from
	daily_views dv 
inner join videos v on v.video_id = dv.video_id
	inner join creators c on c.creator_id = v.creator_id
-- 39. Use ROW_NUMBER()  to duplicate and get latest daily_stats.
select
	video_id,
	view_date 
from
	daily_views
group by video_id, view_date
having count(*) > 1


-- 40. Compute engagement score = (likes + comments + clicks) / impressions.

with agg as (

select
	v.video_id,
	sum(ld.likes) as total_likes,
	sum(dv.clicks) as total_clicks,
	(select count(*) from comments c where c.video_id = v.video_id) as total_comments,
	sum(dv.impressions) as total_impressions
from
	videos v
left join likes_dislikes ld on ld.video_id = v.video_id 
	left join daily_views dv on dv.video_id = v.video_id 
group by v.video_id
)


select
	video_id,
	total_likes,
	total_comments,
	total_clicks, 
	total_impressions, 
	case 
		when total_impressions = 0 then null
		else cast(total_likes + total_comments + total_clicks as float) / total_impressions 
	end as engagement_score 
from
	agg 
order by engagement_score desc;

-- 41. Detect anomaly days using z-score on daily views

with stats as (

	select
		video_id,
		avg(views) as mean_views,
		STDEV(views) as stddev_views
	from
		daily_views 
	group by video_id

)

select
	dv.video_id,
	dv.view_date,
	dv.views,
	s.mean_views,
	case when s.stddev_views = 0 then 0 else (dv.views - s.mean_views) / s.stddev_views
	end as z_score
from
	daily_views dv 
join stats s on dv.video_id = s.video_id
order by dv.video_id, dv.view_date;


-- 42. Calculate creator retention: percent of videos still getting views after 90 days.
with last_views as (
select
	video_id,
	max(view_date) as last_view_date
from
	daily_views
group by video_id
),

video_age as (
select 
	v.video_id,
	v.creator_id,
	lv.last_view_date,
	DATEDIFF(day, v.publish_date, last_view_date) as days_active
from
	videos v 
join last_views lv on lv.video_id = v.video_id
)
select 
	c.creator_id,
	c.creator_name,
	count(case when days_active >= 90 then 1 end) * 1.0 / count(*) as retention_ratio
from
	video_age va 
join creators c on c.creator_id = va.creator_id
group by c.creator_id, c.creator_name
order by retention_ratio desc;

-- 43. Find drop-off ratio for videos (avg_view_duration/duration).


with agg as (
select
	v.video_id,
	v.title,
	v.duration_seconds,
	avg(dv.avg_view_duration_seconds) as avg_watch
from
	videos v
join daily_views dv on dv.video_id = v.video_id
group by v.video_id, v.title, v.duration_seconds
)
select 
	video_id,
	title,
	duration_seconds,
	avg_watch,
	avg_watch / nullif(duration_seconds,0) as drop_off_ratio
from
	agg 
order by drop_off_ratio asc;

-- 44. Find total revenue per creator and per video.
with revenue_sum as (
select
	v.creator_id,
	sum(r.ad_revenue + r.subscription_revenue + r.other_revenue) as total_revenue
from
	videos v 
left join revenue r on r.video_id = v.video_id
group by v.creator_id
),
video_count as (
select
	creator_id,
	count(*) as num_videos
from
	videos
group by creator_id
)
select
	c.creator_id,
	c.creator_name,
	rs.total_revenue,
	vc.num_videos,
	rs.total_revenue / nullif(vc.num_videos, 0) as revenue_per_video
from
	revenue_sum rs
join video_count vc on vc.creator_id = rs.creator_id
	join creators c on c.creator_id = rs.creator_id
order by revenue_per_video desc;


-- 45. Segment videos into bins by length and analyse average CTR per bin.
-- Bins logic is as
-- WHEN duration_seconds < 300 then 'Short (<5 min)'
-- WHEN duration_seconds < 1200 then 'Medium (5-20 min)'
-- ELSE 'Long (>20 min)'


with len_bins as (
select 
	video_id,
	duration_seconds,
	case 
		when duration_seconds < 300 then 'Short (<5 min)'
		when duration_seconds > 300 and duration_seconds < 1200 then 'Medium (5-20 min)'
		else 'Long (>20 min)'
	end as length_bin 
from
	videos
),

ctr as (
select
	dv.video_id,
	sum(dv.clicks) as total_clicks,
	sum(dv.impressions) as total_impressions
from
	daily_views dv
group by dv.video_id
)

select
	lb.length_bin,
	avg(
		case 
			when c.total_impressions = 0 then null else c.total_clicks * 1.0 / c.total_impressions end
		) as avg_ctr
from
	len_bins lb 
join ctr c on c.video_id = lb.video_id
group by lb.length_bin
order by avg_ctr desc;


-- 46 Identify top comments contributors (who comments most).
select
	commenter_name,
	count(*) as total_comments
from
	comments
group by commenter_name
order by total_comments desc;

-- 47 Find out videos which had more than 20K impressions but no revenue
select
	dv.video_id,
	sum(dv.impressions) as total_impressions,
	sum(r.ad_revenue + r.subscription_revenue + r.other_revenue) as total_revenue
from
	daily_views dv
left join revenue r on r.video_id = dv.video_id
group by dv.video_id
having sum(dv.impressions) > 20000 and sum(r.ad_revenue + r.subscription_revenue + r.other_revenue) is null;

-- 48. Build a pivot: monthly revenue by category 

with monthly as (
select
	v.category,
	format(r.revenue_date, 'yyyy-MM') as year_month, 
	(r.ad_revenue + r.subscription_revenue + r.other_revenue) as revenue
from
	revenue r 
join videos v on v.video_id = r.video_id
)

select
	*
from
	monthly
pivot(
	sum(revenue) for year_month in (
								[2023-01], [2023-02], [2023-03], [2023-04], [2023-05], [2023-06], [2023-07],
								[2023-08], [2023-09], [2023-10], [2023-11], [2023-12], [2024-01], [2024-02],
								[2024-03], [2024-04], [2024-05], [2024-06], [2024-07], [2024-08])
) as p;


-- 49. Multi-day conversion funnel: impressions -> clicks -> views (aggregate rations).
select
	video_id,
	sum(impressions) as impressions,
	sum(clicks) as clicks, 
	sum(views) as views,
	sum(watch_time_seconds) as watch_time,
	case when sum(impressions) = 0 then null else sum(clicks) * 1.0 / sum(impressions) end as ctr,
	case when sum(clicks) = 0 then null else sum(views)*1.0/sum(clicks) end as click_to_view
from
	daily_views
group by video_id
order by video_id;

-- 50. Mark videos with inconsistent data 
-- (daily_views exists but no likes_dislikes for that day)

select
	dv.video_id,
	dv.view_date,
	dv.views,
	coalesce(ld.ld_id, null) as likes_record_missing_flag
from
	daily_views dv 
left join likes_dislikes ld on ld.video_id = dv.video_id and ld.record_date = dv.view_date
where ld.ld_id is null 
order by dv.video_id, dv.view_date;

select * from comments
select * from videos
select * from daily_views
select * from likes_dislikes
select * from revenue
select * from creators


