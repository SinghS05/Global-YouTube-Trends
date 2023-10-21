
USE YoutubeVideosDatabase;
-- 1. Create a report for overall distribution of trending videos by each country.
SELECT Video_ID, 
		Title,
		country,
		COUNT(DISTINCT Trending_Date) AS 'no_of_days_trended'
FROM yt_trending_videos
GROUP BY Video_ID, Title, Country;

-- 2. Create a report for overall distribution of duration of trending videos by each category
SELECT trending.Video_ID,
		trending.title,
		cat.Snippettitle AS category,
		COUNT(DISTINCT trending.Trending_Date) AS no_of_days_trended
FROM yt_trending_videos AS trending
	LEFT JOIN yt_category_map AS cat
	ON trending.Category_ID = cat.ID
GROUP BY Video_ID,
		title,
		Snippettitle;
/* 3.Create a report for the number of distinct videos trending from 
   each category on day of the week
   */
SELECT 
	DATENAME(WEEKDAY, Trending_Date) AS 'day',
	Snippettitle AS category,
	COUNT(DISTINCT video_id) AS no_of_videos
FROM yt_trending_videos AS trending
	LEFT JOIN yt_category_map AS cat
	ON trending.Category_ID = cat.ID
GROUP BY DATENAME(WEEKDAY, Trending_Date),
			Snippettitle;
/* 4.Create a summary report which contains country,
	category,total_views, total_likes and avg_trending_days
*/
SELECT 
	country,
	snippettitle AS category,
	SUM(CAST(total_views AS numeric)) AS total_views,
	SUM(CAST(total_likes AS numeric)) AS total_likes,
	AVG(CAST(no_of_days_trended AS decimal)) AS avg_trending_days
FROM (SELECT video_id,
			title,
			snippettitle,
			country,
			SUM(CAST(views AS numeric)) AS total_views,
			SUM(CAST(likes AS numeric)) AS total_likes,
			COUNT(trending_date) AS no_of_days_trended
		FROM yt_trending_videos AS trending
			LEFT JOIN yt_category_map AS cat
			ON trending.Category_ID = cat.ID
			GROUP BY Video_ID, title, Snippettitle, Country) A
GROUP BY Country,
		Snippettitle
ORDER BY Country,
		avg_trending_days DESC;

/* 5.Rank the videos based on views, likes within each country.*/
SELECT video_id,
		title,
		country,
		views,
		likes,
		DENSE_RANK()
			OVER(PARTITION BY country
				ORDER BY views DESC) AS Rank_Views,
		DENSE_RANK()
			OVER(PARTITION BY country
				ORDER BY likes DESC) AS Rank_Likes
FROM yt_trending_videos
ORDER BY country, Rank_Views ASC, Rank_Likes ASC;

/* 6.Generate a report at video level with video viewership rating within the category.
	Formula to assign rating : ((Views - min(views))*100)/(max(views)- min(views))
	Where max(views) and min(views) are the respective max and min viewed video in
	respective category. */
SELECT A.*,
		((views - min_views)*100)/(max_views - min_views) AS rating
FROM (SELECT video_id,
		title,
		snippettitle AS category_title,
		views,
		MAX(CAST(views AS bigint))
			OVER(PARTITION BY snippettitle) AS max_views,
		MIN(CAST(views AS bigint))
			OVER(PARTITION BY snippettitle) AS min_views
		FROM yt_trending_videos
			INNER JOIN yt_category_map
				ON yt_trending_videos.Category_ID = yt_category_map.ID) A;

/* 7..Generate a report at video level with video rating within the category.
	Formula to assign rating : ((Likes - min(Likes))*100)/(max(Likes)- min(Likes))
	Where max(Likes) and min(Likes) are the respective max and min liked video in
	respective category. */
SELECT A.*,
		((likes - min_likes)*100)/(max_likes - min_likes) AS rating
FROM (SELECT video_id,
		title,
		snippettitle AS category_title,
		likes,
		MAX(CAST(likes AS bigint))
			OVER(PARTITION BY snippettitle) AS max_likes,
		MIN(CAST(likes AS bigint))
			OVER(PARTITION BY snippettitle) AS min_likes
		FROM yt_trending_videos
			INNER JOIN yt_category_map
				ON yt_trending_videos.Category_ID = yt_category_map.ID) A;